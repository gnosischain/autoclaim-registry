// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./interfaces/ISBCDepositContract.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgreadable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol"
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";


contract ClaimRegistryUpgradable is UUPSUpgreadable, OwnableUpgradeable, PausableUpgradeable {
    //uint256 public threshold;
    ISBCDepositContract public depositContract;
    mapping(address => Config) public configs;
    address[] public validators;

    enum ConfigStatus {
        INACTIVE,
        ACTIVE
    }

    // Updated Config struct with an additional field for status
    struct Config {
        uint256 lastClaim;
        uint256 timeThreshold;
        uint256 amountThreshold;
        ConfigStatus status; // New field for the status
    }

    //event changedThreshold(uint256 indexed oldThreshold, uint256 indexed newThreshold);
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

    /// @custom:oz-upgrades-unsafe-allow constructor
    // slither-disable-next-line missing-calls
    constructor() initializer {}

    // TODO: recheck
    function initialize(address _depositContract) public initializer {
        __Ownable_init(msg.sender);
        __Pausable_init();
        __UUPSUpgradeable_init();

        depositContract = ISBCDepositContract(_depositContract);

    }

    function getValidatorsLength() public view returns (uint256) {
        return validators.length;
    }

    function register(address _withdrawalAddress, uint256 _timeThreshold, uint256 _amountThreshold)
        public
        nonZeroParams(_timeThreshold, _amountThreshold)
        ownerOrAdmin(_withdrawalAddress)
    {
        _setConfig(_timeThreshold, _amountThreshold);
        validators.push(msg.senger);
        emit Register(msg.sender);
    }

    // TODO: consider out of gas
    function claimBatch(address[] calldata withdrawalAddresses) public {
        depositContract.claimWithdrawals(users);
        for (uint256 i = 0; i < withdrawalAddresses.length; i++) {
            claim(withdrawalAddresses[i]);
        }
        emit ClaimBatch(msg.sender, withdrawalAddresses);
    }

    function claim(address calldata withdrawalAddress) public {
        depositContract.claimWithdrawal(withdrawalAddress);
        configs[validator].lastClaim = block.timestamp;
    }

    function updateConfig(uint256 _timeThreshold, uint256 _amountThreshold)
        public
        nonZeroParams(_timeThreshold, _amountThreshold)
    {
        require(configs[msg.sender].status == ConfigStatus.ACTIVE, "User is not registered");
        emit UpdateConfig(
            msg.sender,
            configs[msg.sender].timeThreshold,
            _timeThreshold,
            configs[msg.sender].amountThreshold,
            _amountThreshold
        );
        _setConfig(_timeThreshold, _amountThreshold);
    }

    function unregister() public {
        require(configs[msg.sender].status == ConfigStatus.ACTIVE, "User is not registered");
        delete configs[msg.sender];
        emit Unregister(msg.sender);
    }

    function _setConfig(uint256 _timeThreshold, uint256 _amountThreshold) internal {
        configs[msg.sender].timeThreshold = _timeThreshold;
        configs[msg.sender].amountThreshold = _amountThreshold;
        configs[msg.sender].status = ConfigStatus.ACTIVE;
    }

    // TODO: consider offset shifting option for huge validators set
    function getClaimableAddresses() public view returns (address[] memory) {
        address[] memory claimableAddresses = new address[](validators.length);
        uint256 counter = 0;

        for (uint256 i = 0; i < length; i++) {
            address val = validators[i];
            if (depositContract.withdrawableAmount(val) > configs[val].amountThreshold) {
                claimableAddresses[counter] = val;
                counter++;
            } else if (
                configs[val].timeThreshold > 0 && block.timestamp - configs[val].lastClaim > configs[val].timeThreshold
            ) {
                claimableAddresses[counter] = val;
                counter++;
            }
        }

        address trimmedClaimableAddresses = new address[](counter);
        for (uint256 i = 0; i < claimableAddresses.length; i++) {
            if (claimableAddresses[i] != address(0)) {
                trimmedClaimableAddresses[i] = claimableAddresses[i];
            }
        }
        return trimmedClaimableAddresses;
    }

    function resolve() public view returns (bool flag, bytes memory cdata) {
        address[] memory addresses = getClaimableAddresses(0, 10);

        return (true, abi.encodeWithSelector(this.cliamBatch.selector, addresses));
    }
}
