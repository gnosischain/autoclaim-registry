// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IRegistry {
    struct Config {
        uint256 lastClaim;
        uint256 timeThreshold;
        uint256 amountThreshold;
        ConfigStatus status;
    }

    enum ConfigStatus {
        INACTIVE,
        ACTIVE
    }

    function getValidatorsLength() external view returns (uint256);
    function register(uint256 _timeThreshold, uint256 _amountThreshold) external;
    function updateConfig(uint256 _timeThreshold, uint256 _amountThreshold) external;
    function unregister() external;
    function getClaimableAddresses(uint256 offset, uint256 batchSize) external view returns (address[] memory, uint256 newOffset);
}
