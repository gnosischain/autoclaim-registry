# Implementation Details
## Claim automation flow
PowerPools is a decentralized network of keepers for automatic transaction execution.

<img width="1292" alt="image" src="https://github.com/gnosischain/autoclaim-registry/assets/59182467/cd04b7e7-4448-4a9e-a719-e0dd2075de53">

#### Steps:
1. Assigned keeper calls `resolve()` view function
```solidity
    function resolve() public view returns (bool flag, bytes memory cdata) {
        address[] memory addresses = getClaimableAddresses();
        if (addresses.length == 0) {
            return (false, "");
        }
        return (true, abi.encodeWithSelector(this.claimBatch.selector, addresses));
    }
```

1. Registry contract returns list of addresses that meet certain conditions(time/amount threshold exceeded) to withdraw in a form `(true, calldata)`, otherwise (if there are no such addresses) returns `(false, " ")`

2. If `(true, calldata)` returned, assigned keeper execute `claimBatch(calldata)` call

3. Registry updates `lastClaim` time for addresses and calls deposit contract `claim()` function
```solidity
    function claimBatch(address[] calldata withdrawalAddresses) public {
        for (uint256 i = 0; i < withdrawalAddresses.length; i++) {
            claim(withdrawalAddresses[i]);
        }
        emit ClaimBatch(msg.sender, withdrawalAddresses);
    }

    function claim(address withdrawalAddress) public {
        configs[withdrawalAddress].lastClaim = block.timestamp;
        depositContract.claimWithdrawal(withdrawalAddress);
    }
```

## User flow

This smart contract is designed for managing withdrawal addresses, each associated with specific time and amount thresholds.
Address become eligable for claim if one of thresholds reached.

### Functions

```solidity
function register(address _withdrawalAddress, uint256 _timeThreshold, uint256 _amountThreshold)
```

- **Parameters**:
  - `_withdrawalAddress`: Ethereum address designated for withdrawals.
  - `_timeThreshold`: Time threshold for withdrawal, in timestamp units.
  - `_amountThreshold`: Minimum amount threshold for withdrawal.
- **Access Control**: Accessible by the owner of the address or  the admin of the contract.
- **Conditions**: `_timeThreshold` and `_amountThreshold` must be non-zero.
- **Functionality**: Sets the withdrawal configurations for the address, adds it to the validators' list, and emits a `Register` event.

```solidity
function updateConfig(address _withdrawalAddress, uint256 _timeThreshold, uint256 _amountThreshold)
```

- **Parameters**:
  - `_withdrawalAddress`: Ethereum address for which configuration is being updated.
  - `_timeThreshold`: New time threshold for withdrawal, in timestamp units.
  - `_amountThreshold`: New minimum amount threshold for withdrawal.
- **Access Control**: Accessible by the owner of the address or  the admin of the contract.
- **Conditions**: Both `_timeThreshold` and `_amountThreshold` must be non-zero, and configuration for `_withdrawalAddress` must be active.
- **Functionality**: Updates the time and amount thresholds for the given address and emits an `UpdateConfig` event.


```solidity
function unregister(address _withdrawalAddress)
```

- **Parameters**:
  - `_withdrawalAddress`: Ethereum address to be unregistered.
- **Access Control**: Accessible by the owner of the address or  the admin of the contract.
- **Conditions**: Configuration for `_withdrawalAddress` must be active.
- **Functionality**: Removes the configuration for the given address and emits an `Unregister` event.

## Notes

- Time thresholds are set in timestamp units for precise control over withdrawal timings (`1 == 1sec`).
- The contract ensures non-zero time and amount thresholds for valid configurations.

