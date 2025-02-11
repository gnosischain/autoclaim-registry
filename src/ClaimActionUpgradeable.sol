// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/IClaimActionUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ClaimActionUpgradeable is
    IClaimActionUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    address private gnoTokenAddress =
        0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb;
    address private wxdaiTokenAddress =
        0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d;
    address private eureTokenAddress =
        0xcB444e90D8198415266c6a2724b7900fb12FC56E;
    address public claimRegistryAddress;

    mapping(address => address) forwardingAddresses;
    address public curvePool;

    bool public balancerSandwichPrevention = true; // enable/disable sandich prevention for the balancer step
    uint256 public curveMaxDiff = 990; // = 0.990 =1 % difference between oracle price and received: Sandwich Prevention.

    event ClaimSwapAndForwarded(
        uint256 gnoAmountIn,
        uint256 wxDaiAmountOut,
        address claimAddress,
        address forwardingAddress
    );

    // Modifiers
    modifier onlyClaimRegistry() {
        require(
            msg.sender == claimRegistryAddress,
            "Caller is not the claim registry contract"
        );
        _;
    }

    // Proxy initializing and upgrading

    /**
     * @dev Initializes the proxy contract, intended to be called only once.
     * @param _claimRegistryAddress Address of the claim registry contract.
     */
    function initialize(address _claimRegistryAddress) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        claimRegistryAddress = _claimRegistryAddress;
    }

    /**
     * @dev Ensures that only owner can upgrade the implementation.
     * @param newImplementation Address of the new implementation.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @dev Compliments the ERC1967 pattern make implementation address retrievable.
     * @return address of implementation contract.
     */
    function implementation() public view returns (address) {
        return ERC1967Utils.getImplementation();
    }

    constructor() {
        _disableInitializers();
    }

    function executePostClaimAction(
        address _withdrawalAddress,
        uint256 _amount
    ) external onlyClaimRegistry {
        swapAndForward(_withdrawalAddress, _amount);
    }

    /// @notice This is the main functionality. Which does everything (claim, swap and forward).
    /// @param claimAddress address for which to claim .
    function swapAndForward(address claimAddress, uint256 amount) private {
        uint256 allowanceAmount = IERC20(gnoTokenAddress).allowance(
            claimAddress,
            address(this)
        );
        require(
            forwardingAddresses[claimAddress] != address(0),
            "No forwarding Address set for the claimAddress. Cannot forward the swapped funds."
        );
        require(amount > 0, "No Gno to claim. Revert.");
        require(
            allowanceAmount >= amount,
            "Approval amount too low, cannot transfer GNO to contract to do the swap."
        );

        IERC20(gnoTokenAddress).transferFrom(
            claimAddress,
            address(this),
            amount
        );
        balancerSwapGnoToWxdai(amount);

        uint256 wxdaiAmount = IERC20(wxdaiTokenAddress).balanceOf(
            address(this)
        );
        curveSwapWxdaiEure(wxdaiAmount);
        transferAllEureToDestination(forwardingAddresses[claimAddress]);
        emit ClaimSwapAndForwarded(
            amount,
            wxdaiAmount,
            claimAddress,
            forwardingAddresses[claimAddress]
        );
    }

    /// @notice First swap step from GNO to wxDAI using balancer.
    /// @param gnoAmount amount of GNO to swap.
    function balancerSwapGnoToWxdai(uint256 gnoAmount) private {
        address vaultAddress = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
        Balancer vaultContract = Balancer(vaultAddress);
        bytes32 poolId = 0x8189c4c96826d016a99986394103dfa9ae41e7ee0002000000000000000000aa;

        // Poor mans in-block sandwich prevention. If the pool has been touched in the same block, revert.
        // There is about 1 balancer transaction per 100 blocks, so it has a 1% chance to give a false positive.
        if (balancerSandwichPrevention) {
            (, , uint256 lastChangeBlock, ) = vaultContract.getPoolTokenInfo(
                poolId,
                IERC20(gnoTokenAddress)
            );

            require(
                lastChangeBlock < block.number,
                "Balancer pool has been used in this block already. Revert to prevent in-block sandwiching attacks."
            );
        }

        Balancer.SwapKind kind = Balancer.SwapKind.GIVEN_IN;

        Balancer.SingleSwap memory singleSwapStruct = Balancer.SingleSwap({
            poolId: poolId,
            kind: kind,
            assetIn: IAsset(address(gnoTokenAddress)),
            assetOut: IAsset(address(wxdaiTokenAddress)),
            amount: gnoAmount,
            userData: ""
        });

        Balancer.FundManagement memory fundsManagementStruct = Balancer
            .FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            });

        // Set allowance for balancer contract
        IERC20(gnoTokenAddress).approve(vaultAddress, gnoAmount);

        uint256 minReceive = 0;
        vaultContract.swap(
            singleSwapStruct,
            fundsManagementStruct,
            minReceive,
            block.timestamp
        );
    }

    /// @notice Second swap step from wxDAI to EURe using curve.
    /// @param wxdaiAmount amount of wxDAI to swap.
    function curveSwapWxdaiEure(uint256 wxdaiAmount) private {
        address curveAddress = 0xE3FFF29d4DC930EBb787FeCd49Ee5963DADf60b6;
        Curve curveContract = Curve(curveAddress);
        uint256 oraclePrice = curveContract.price_oracle(); // wxDAI you get for 1 EURe multiplied by 1e18

        uint256 minReceive = 0; // TODO: Can be sandwiched to oblivion.
        IERC20(wxdaiTokenAddress).approve(curveAddress, wxdaiAmount);
        // Pool tokens 0=EURe, 1=wxDAI, 2=USDC,3=USDT
        uint inTokenIndex = 1; // wxDAI
        uint outTokenIndex = 0; // EURe
        curveContract.exchange_underlying(
            inTokenIndex,
            outTokenIndex,
            wxdaiAmount,
            minReceive
        );
        uint256 eureReceived = IERC20(eureTokenAddress).balanceOf(
            address(this)
        );
        uint256 minimallyAcceptedEure = (wxdaiAmount / (oraclePrice / 1e15)) *
            curveMaxDiff;

        require(
            eureReceived > minimallyAcceptedEure,
            "EURe amount received lower than expected from the oracle price. Revert to prevent sandwiching attacks."
        );
    }

    /// @notice Transfer all the EURe in this contract to the destination address.
    function transferAllEureToDestination(address forwardingAddress) private {
        uint256 amount = IERC20(eureTokenAddress).balanceOf(address(this));
        IERC20(eureTokenAddress).transfer(forwardingAddress, amount);
    }
}
