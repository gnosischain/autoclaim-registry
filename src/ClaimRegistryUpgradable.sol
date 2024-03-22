// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./interfaces/ISBCDepositContract.sol";
import "./interfaces/IClaimRegistryUpgradable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

/**
 * @title ClaimRegistryUpgradable
 * @dev A contract for managing claim registrations and withdrawals with upgradability features.
 */
contract ClaimRegistryUpgradable is
    IClaimRegistryUpgradable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    // State variables

    // Public variables

    // Events

    // Modifiers

    //uint256 public threshold;
    ISBCDepositContract public depositContract;
    mapping(address => Config) public configs;
    address[] public validators;

    enum ConfigStatus {
        INACTIVE,
        ACTIVE
    }

    struct Config {
        uint256 lastClaim;
        uint256 timeThreshold;
        uint256 amountThreshold;
        ConfigStatus status;
    }

    event Register(address indexed user);
    event Unregister(address indexed user);
    event UpdateConfig(address indexed user, uint256 oldTime, uint256 newTime, uint256 oldAmount, uint256 newAmount);
    // TODO: decidew if we want many single Claim events or one ClaimBatch event
    event ClaimBatch(address indexed caller, address[] withdrawalAddresses);

    modifier nonZeroParams(uint256 _timeThreshold, uint256 _amountThreshold) {
        require(_timeThreshold > 0 || _amountThreshold > 0, "One of thresholds should be non-zero");
        _;
    }

    modifier ownerOrAdmin(address withdrawalAddress) {
        require(
            msg.sender == owner() || msg.sender == withdrawalAddress, "Caller is not an owner of withdrawal credentials"
        );
        _;
    }

    modifier configActive(address _withdrawalAddress) {
        require(isConfigActive(_withdrawalAddress), "Config is not active");
        _;
    }

    // Constructor

    /**
     * @dev Disable implementaton contract initializers
     */
    constructor() {
        _disableInitializers();
    }

    // Proxy initializing and upgrading

    /**
     * @dev Initializes the proxy contract, intended to be called only once.
     * @param _depositContract Address of the deposit contract.
     */
    function initialize(address _depositContract) public initializer {
        __Ownable_init(msg.sender);
        __Pausable_init();
        __UUPSUpgradeable_init();

        depositContract = ISBCDepositContract(_depositContract);
    }

    /**
     * @dev Ensures that only owner can upgrade the implementation.
     * @param newImplementation Address of the new implementation.
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}

    // External functions

    /**
     * @dev Resolves the claimable addresses and returns flag and calldata.
     * @return flag Boolean flag indicating whether claimable addresses exist.
     * @return cdata ABI-encoded calldata for batch claiming.
     */
    function resolve() external view returns (bool flag, bytes memory cdata) {
        address[] memory addresses = getClaimableAddresses();
        if (addresses.length == 0) {
            return (false, "");
        }
        return (true, abi.encodeWithSelector(this.claimBatch.selector, addresses));
    }

    /**
     * @dev Gets the claimable addresses based on configured thresholds.
     * @return claimableAddresses Array of claimable addresses.
     * @todo Consider offset shifting option for huge validators set.
     */
    function getClaimableAddresses() public view returns (address[] memory) {
        address[] memory claimableAddresses = new address[](validators.length);
        uint256 counter = 0;

        for (uint256 i = 0; i < validators.length; i++) {
            address val = validators[i];
            // skip for inactive configs and zero withdrawable amount
            uint256 withdrawableAmount = depositContract.withdrawableAmount(val);
            if (withdrawableAmount == 0 || configs[val].status == ConfigStatus.INACTIVE) {
                continue;
            }
            // add address to list if amount or time condition met
            if (withdrawableAmount > configs[val].amountThreshold) {
                claimableAddresses[counter] = val;
                counter++;
            } else if (
                configs[val].timeThreshold > 0 && block.timestamp - configs[val].lastClaim > configs[val].timeThreshold
            ) {
                claimableAddresses[counter] = val;
                counter++;
            }
        }

        if counter != validators.length {
            // as we used new address[](validators.length); we have to trim array to remove zero addresses
            // since we can't resize array in memory, we need to create new one where we will copy all non-zero addresses
            address[] memory trimmedClaimableAddresses = new address[](counter);
            for (uint256 i = 0; i < claimableAddresses.length; i++) {
                if (claimableAddresses[i] != address(0)) {
                    trimmedClaimableAddresses[i] = claimableAddresses[i];
                }
            }
            return trimmedClaimableAddresses;
        }
        return claimableAddresses;
    }

    // Public functions

    /**
     * @dev Gets the length of the validators array.
     * @return Length of the validators array.
     */
    function getValidatorsLength() public view returns (uint256) {
        return validators.length;
    }

    /**
     * @dev Checks if a configuration is active for a withdrawal address.
     * @param _withdrawalAddress The withdrawal address to check.
     * @return Boolean indicating whether the configuration is active.
     */
    function isConfigActive(address _withdrawalAddress) public view returns (bool) {
        return configs[_withdrawalAddress].status == ConfigStatus.ACTIVE;
    }

    /**
     * @dev Registers a user with withdrawal credentials.
     * @param _withdrawalAddress The address to register for withdrawals.
     * @param _timeThreshold Time threshold for withdrawal.
     * @param _amountThreshold Amount threshold for withdrawal.
     */
    function register(address _withdrawalAddress, uint256 _timeThreshold, uint256 _amountThreshold)
        public
        nonZeroParams(_timeThreshold, _amountThreshold)
        ownerOrAdmin(_withdrawalAddress)
    {
        _setConfig(_timeThreshold, _amountThreshold);
        validators.push(msg.sender);
        emit Register(msg.sender);
    }

    /**
     * @dev Updates the configuration for a withdrawal address.
     * @param _withdrawalAddress The withdrawal address to update configuration for.
     * @param _timeThreshold New time threshold for withdrawal.
     * @param _amountThreshold New amount threshold for withdrawal.
     */
    function updateConfig(address _withdrawalAddress, uint256 _timeThreshold, uint256 _amountThreshold)
        public
        nonZeroParams(_timeThreshold, _amountThreshold)
        ownerOrAdmin(_withdrawalAddress)
        configActive(_withdrawalAddress)
    {
        emit UpdateConfig(
            msg.sender,
            configs[msg.sender].timeThreshold,
            _timeThreshold,
            configs[msg.sender].amountThreshold,
            _amountThreshold
        );
        _setConfig(_timeThreshold, _amountThreshold);
    }

    /**
     * @dev Unregisters a withdrawal address.
     * @param _withdrawalAddress The withdrawal address to unregister.
     */
    function unregister(address _withdrawalAddress)
        public
        ownerOrAdmin(_withdrawalAddress)
        configActive(_withdrawalAddress)
    {
        delete configs[msg.sender];
        emit Unregister(msg.sender);
    }

    /**
     * @dev Allows batch claiming for multiple withdrawal addresses.
     * @param withdrawalAddresses Array of withdrawal addresses.
     * @todo Consider offset shifting option for huge validators set to not get 'out of gas' error
     */
    function claimBatch(address[] calldata withdrawalAddresses) public {
        for (uint256 i = 0; i < withdrawalAddresses.length; i++) {
            claim(withdrawalAddresses[i]);
        }
        emit ClaimBatch(msg.sender, withdrawalAddresses);
    }

    /**
     * @dev Claims withdrawal for a specific address and updates last claim timestamp.
     * @param withdrawalAddress The withdrawal address to claim for.
     */
    function claim(address withdrawalAddress) public {
        configs[withdrawalAddress].lastClaim = block.timestamp;
        depositContract.claimWithdrawal(withdrawalAddress);
    }

    // Internal functions

    /**
     * @dev Sets the configuration for the caller.
     * @param _timeThreshold Time threshold for withdrawal.
     * @param _amountThreshold Amount threshold for withdrawal.
     */
    function _setConfig(uint256 _timeThreshold, uint256 _amountThreshold) internal {
        configs[msg.sender].timeThreshold = _timeThreshold;
        configs[msg.sender].amountThreshold = _amountThreshold;
        configs[msg.sender].status = ConfigStatus.ACTIVE;
    }
}