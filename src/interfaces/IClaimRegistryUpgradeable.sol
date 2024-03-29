// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IClaimRegistryUpgradeable {
    function initialize(address _depositContract, uint256 _batchSizeMax) external;

    function getValidatorsLength() external view returns (uint256);

    function register(address _withdrawalAddress, uint256 _timeThreshold, uint256 _amountThreshold) external;

    function claimBatch(address[] calldata withdrawalAddresses) external;

    function claim(address withdrawalAddress) external;

    function updateConfig(address _withdrawalAddress, uint256 _timeThreshold, uint256 _amountThreshold) external;

    function unregister(address _withdrawalAddress) external;

    function isConfigActive(address _withdrawalAddress) external view returns (bool);

    function getClaimableAddresses() external view returns (address[] memory);

    function resolve() external view returns (bool, bytes memory);

    function implementation() external view returns (address);
}
