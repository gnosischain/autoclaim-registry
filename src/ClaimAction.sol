// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/IClaimAction.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/interfaces/AggregatorV3Interface.sol";

contract ClaimAction is IClaimAction {
    AggregatorV3Interface internal gnoUsdFeed;
    AggregatorV3Interface internal eurUsdFeed;

    address public gnoTokenAddress;
    address private wxdaiTokenAddress =
        0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d;
    address private eureTokenAddress =
        0xcB444e90D8198415266c6a2724b7900fb12FC56E;
    address public claimRegistryAddress;

    mapping(address => address) forwardingAddresses;
    address public curvePool;

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

    constructor(address _claimRegistryAddress, address _gnoTokenAddress) {
        claimRegistryAddress = _claimRegistryAddress;
        gnoTokenAddress = _gnoTokenAddress;

        gnoUsdFeed = AggregatorV3Interface(
            0x22441d81416430A54336aB28765abd31a792Ad37
        );

        eurUsdFeed = AggregatorV3Interface(
            0xc91D87E81faB8f93699ECf7Ee9B44D11e1D53F0F
        );
    }

    /// @notice Generic function, all action contract should implement it. Can be called only by the claim registry contract.
    /// @param _withdrawalAddress Address for which to execute action.
    /// @param _amount Amount claimed in registry contract.
    function executePostClaimAction(
        address _withdrawalAddress,
        uint256 _amount
    ) external onlyClaimRegistry {
        swapAndForward(_withdrawalAddress, _amount);
    }

    /// @notice This is the main functionality. Which does everything (swap and forward).
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
        uint256 eureAmount = IERC20(eureTokenAddress).balanceOf(address(this));
        uint256 chainlinkPrice = chainlinkGnoEurPrice();
        uint256 expectedEure = (amount * 1e18) / chainlinkPrice;
        require(
            eureAmount * 100 >= expectedEure * 99,
            "Slippage is more than 1%"
        );
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
    }

    /// @notice Transfer all the EURe in this contract to the destination address.
    function transferAllEureToDestination(address forwardingAddress) private {
        uint256 amount = IERC20(eureTokenAddress).balanceOf(address(this));
        IERC20(eureTokenAddress).transfer(forwardingAddress, amount);
    }

    /// @notice Set and change the forwarding address.
    /// @param forwardingAddress address to which to forward the funds to.
    function setForwardingAddress(address forwardingAddress) public {
        forwardingAddresses[msg.sender] = forwardingAddress;
    }

    function chainlinkGnoEurPrice() public view returns (uint256) {
        uint256 gnoUsd = uint256(getChainlinkGnoUsdDataFeedLatestAnswer());
        uint256 eurUsd = uint256(getChainlinkEurUsdDataFeedLatestAnswer());
        require(eurUsd > 0, "EUR/USD feed is 0");
        return (gnoUsd * 1e18) / eurUsd;
    }

    function getChainlinkGnoUsdDataFeedLatestAnswer()
        public
        view
        returns (int)
    {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = gnoUsdFeed.latestRoundData();
        return answer;
    }

    function getChainlinkEurUsdDataFeedLatestAnswer()
        public
        view
        returns (int)
    {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = eurUsdFeed.latestRoundData();
        return answer;
    }
}
