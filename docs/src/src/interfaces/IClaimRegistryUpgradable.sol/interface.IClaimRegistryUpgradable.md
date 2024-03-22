# IClaimRegistryUpgradable
[Git Source](https://github.com/gnosischain/autoclaim-registry/blob/9f4bd743ef33bd85ac1cb17c48b5b330ace28ebf/src/interfaces/IClaimRegistryUpgradable.sol)


## Functions
### initialize


```solidity
function initialize(address _depositContract) external;
```

### getValidatorsLength


```solidity
function getValidatorsLength() external view returns (uint256);
```

### register


```solidity
function register(address _withdrawalAddress, uint256 _timeThreshold, uint256 _amountThreshold) external;
```

### claimBatch


```solidity
function claimBatch(address[] calldata withdrawalAddresses) external;
```

### claim


```solidity
function claim(address withdrawalAddress) external;
```

### updateConfig


```solidity
function updateConfig(address _withdrawalAddress, uint256 _timeThreshold, uint256 _amountThreshold) external;
```

### unregister


```solidity
function unregister(address _withdrawalAddress) external;
```

### isConfigActive


```solidity
function isConfigActive(address _withdrawalAddress) external view returns (bool);
```

### getClaimableAddresses


```solidity
function getClaimableAddresses() external view returns (address[] memory);
```

### resolve


```solidity
function resolve() external view returns (bool, bytes memory);
```

