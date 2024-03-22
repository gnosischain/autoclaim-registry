# ClaimRegistryUpgradable
[Git Source](https://github.com/gnosischain/autoclaim-registry/blob/9f4bd743ef33bd85ac1cb17c48b5b330ace28ebf/src/ClaimRegistryUpgradable.sol)

**Inherits:**
[IClaimRegistryUpgradable](/src/interfaces/IClaimRegistryUpgradable.sol/interface.IClaimRegistryUpgradable.md), UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable

*A contract for managing claim registrations and withdrawals with upgradability features.*


## State Variables
### depositContract

```solidity
ISBCDepositContract public depositContract;
```


### configs

```solidity
mapping(address => Config) public configs;
```


### validators

```solidity
address[] public validators;
```


## Functions
### nonZeroParams


```solidity
modifier nonZeroParams(uint256 _timeThreshold, uint256 _amountThreshold);
```

### ownerOrAdmin


```solidity
modifier ownerOrAdmin(address withdrawalAddress);
```

### configActive


```solidity
modifier configActive(address _withdrawalAddress);
```

### constructor

*Disable implementaton contract initializers*


```solidity
constructor();
```

### initialize

*Initializes the proxy contract, intended to be called only once.*


```solidity
function initialize(address _depositContract) public initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_depositContract`|`address`|Address of the deposit contract.|


### _authorizeUpgrade

*Ensures that only owner can upgrade the implementation.*


```solidity
function _authorizeUpgrade(address newImplementation) internal override onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newImplementation`|`address`|Address of the new implementation.|


### resolve

*Resolves the claimable addresses and returns flag and calldata.*


```solidity
function resolve() external view returns (bool flag, bytes memory cdata);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`flag`|`bool`|Boolean flag indicating whether claimable addresses exist.|
|`cdata`|`bytes`|ABI-encoded calldata for batch claiming.|


### getClaimableAddresses

TODO: Consider offset shifting option for huge validators set.

*Gets the claimable addresses based on configured thresholds.*


```solidity
function getClaimableAddresses() public view returns (address[] memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address[]`|claimableAddresses Array of claimable addresses.|


### getValidatorsLength

*Gets the length of the validators array.*


```solidity
function getValidatorsLength() public view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Length of the validators array.|


### isConfigActive

*Checks if a configuration is active for a withdrawal address.*


```solidity
function isConfigActive(address _withdrawalAddress) public view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_withdrawalAddress`|`address`|The withdrawal address to check.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|Boolean indicating whether the configuration is active.|


### register

*Registers a user with withdrawal credentials.*


```solidity
function register(address _withdrawalAddress, uint256 _timeThreshold, uint256 _amountThreshold)
    public
    nonZeroParams(_timeThreshold, _amountThreshold)
    ownerOrAdmin(_withdrawalAddress);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_withdrawalAddress`|`address`|The address to register for withdrawals.|
|`_timeThreshold`|`uint256`|Time threshold for withdrawal.|
|`_amountThreshold`|`uint256`|Amount threshold for withdrawal.|


### updateConfig

*Updates the configuration for a withdrawal address.*


```solidity
function updateConfig(address _withdrawalAddress, uint256 _timeThreshold, uint256 _amountThreshold)
    public
    nonZeroParams(_timeThreshold, _amountThreshold)
    ownerOrAdmin(_withdrawalAddress)
    configActive(_withdrawalAddress);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_withdrawalAddress`|`address`|The withdrawal address to update configuration for.|
|`_timeThreshold`|`uint256`|New time threshold for withdrawal.|
|`_amountThreshold`|`uint256`|New amount threshold for withdrawal.|


### unregister

*Unregisters a withdrawal address.*


```solidity
function unregister(address _withdrawalAddress)
    public
    ownerOrAdmin(_withdrawalAddress)
    configActive(_withdrawalAddress);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_withdrawalAddress`|`address`|The withdrawal address to unregister.|


### claimBatch

TODO: Consider offset shifting option for huge validators set to not get 'out of gas' error

*Allows batch claiming for multiple withdrawal addresses.*


```solidity
function claimBatch(address[] calldata withdrawalAddresses) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`withdrawalAddresses`|`address[]`|Array of withdrawal addresses.|


### claim

*Claims withdrawal for a specific address and updates last claim timestamp.*


```solidity
function claim(address withdrawalAddress) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`withdrawalAddress`|`address`|The withdrawal address to claim for.|


### _setConfig

*Sets the configuration for the caller.*


```solidity
function _setConfig(uint256 _timeThreshold, uint256 _amountThreshold) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_timeThreshold`|`uint256`|Time threshold for withdrawal.|
|`_amountThreshold`|`uint256`|Amount threshold for withdrawal.|


## Events
### Register

```solidity
event Register(address indexed user);
```

### Unregister

```solidity
event Unregister(address indexed user);
```

### UpdateConfig

```solidity
event UpdateConfig(address indexed user, uint256 oldTime, uint256 newTime, uint256 oldAmount, uint256 newAmount);
```

### ClaimBatch

```solidity
event ClaimBatch(address indexed caller, address[] withdrawalAddresses);
```

## Structs
### Config

```solidity
struct Config {
    uint256 lastClaim;
    uint256 timeThreshold;
    uint256 amountThreshold;
    ConfigStatus status;
}
```

## Enums
### ConfigStatus

```solidity
enum ConfigStatus {
    INACTIVE,
    ACTIVE
}
```

