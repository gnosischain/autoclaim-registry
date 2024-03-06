// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./interfaces/ISBCDepositContract.sol";

contract Registry {

    //uint256 public threshold;
    ISBCDepositContract public depositContract;
    mapping(address=>Config) public configs;
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
    event Register (address indexed user);
    event Unregister(address indexed user);
    event UpdateConfig(address indexed user, uint256 oldTime, uint256 newTime, uint256 oldAmount, uint256 newAmount);

    modifier nonZeroParams(uint256 _timeThreshold, uint256 _amountThreshold) {
        require(_timeThreshold > 0 || _amountThreshold > 0, "One of thresholds should be non-zero");
        _;
    }

    function getValidatorsLength() public view returns (uint256) {
    return validators.length;
}

    // TODO:
    // constructor (address _claimTarget) {
    //     //threshold = _threshold;
    //     claimTarget = IGVC(_claimTarget);
    // }

    function register(uint256 _timeThreshold, uint256 _amountThreshold) public nonZeroParams(_timeThreshold, _amountThreshold) {
        _setConfig(_timeThreshold, _amountThreshold);
        validators.push(tx.origin);
        emit Register(tx.origin);
    }

    function updateConfig(uint256 _timeThreshold, uint256 _amountThreshold) public nonZeroParams(_timeThreshold, _amountThreshold) {
        require(configs[tx.origin].status == ConfigStatus.ACTIVE, "User is not registered");
        emit UpdateConfig(tx.origin, configs[tx.origin].timeThreshold, _timeThreshold, configs[tx.origin].amountThreshold, _amountThreshold);
        _setConfig(_timeThreshold, _amountThreshold);

    }

    function unregister() public {
        require(configs[tx.origin].status == ConfigStatus.ACTIVE, "User is not registered")
        delete validators[tx.origin];
        emit Unregister(tx.origin);
    }

    function _setConfig(uint256 _timeThreshold, uint256 _amountThreshold) internal {
        configs[tx.origin].timeThreshold = _timeThreshold;
        configs[tx.origin].amountThreshold = _amountThreshold;
        configs[tx.origin].status = ConfigStatus.ACTIVE;
    }

    function getClaimableAddresses(uint256 offset, uint256 batchSize) public view returns (address[] memory) {
        address[] memory claimableAddresses;
        for (uint256 i = offset; i < offset+batchSize; i++) {
            address val = validators[i];
            if (depositContract.withdrawableAmount(val) >= configs[val].amountThreshold) || (configs[val].timeThreshold > 0 && block.timestamp - configs[val].lastClaim >= configs[val].timeThreshold) {
                claimableAddresses.push(validators[i]);
            }
        }
        return claimableAddresses;
    }

    // function resolve() public view returns (bool flag, bytes memory cdata) {
    //     address claimer;
    //     address[] memory toPass = new address[](registeredValidators.length);
    //     flag = false;
    //     for (uint256 i=0; i<registeredValidators.length; i++){
    //         claimer = registeredValidators[i];
    //         if (claimTarget.withdrawableAmount(claimer) >= resolveThresholds[claimer]){
    //             flag = true;
    //             toPass[i] = claimer;
    //         }
    //     }
    //     cdata = abi.encodeWithSelector(claimTarget.claimWithdrawals.selector, toPass);
    // }

    // function lazyResolver() public view returns (bool flag, bytes memory cdata) {
    //     address claimer;
    //     flag = false;
    //     for (uint256 i=0; i<registeredValidators.length; i++){
    //         claimer = registeredValidators[i];
    //         if (claimTarget.withdrawableAmount(claimer) >= resolveThresholds[claimer]){
    //             flag = true;
    //             cdata = abi.encodeWithSelector(claimTarget.claimWithdrawals.selector, registeredValidators);
    //             break;
    //         }
    //     }
    // }

}