# ISBCDepositContract
[Git Source](https://github.com/gnosischain/autoclaim-registry/blob/9f4bd743ef33bd85ac1cb17c48b5b330ace28ebf/src/interfaces/ISBCDepositContract.sol)


## Functions
### get_deposit_root


```solidity
function get_deposit_root() external view returns (bytes32);
```

### get_deposit_count


```solidity
function get_deposit_count() external view returns (bytes memory);
```

### deposit


```solidity
function deposit(
    bytes memory pubkey,
    bytes memory withdrawal_credentials,
    bytes memory signature,
    bytes32 deposit_data_root,
    uint256 stake_amount
) external;
```

### batchDeposit


```solidity
function batchDeposit(
    bytes calldata pubkeys,
    bytes calldata withdrawal_credentials,
    bytes calldata signatures,
    bytes32[] calldata deposit_data_roots
) external;
```

### onTokenTransfer


```solidity
function onTokenTransfer(address from, uint256 stake_amount, bytes calldata data) external returns (bool);
```

### claimTokens


```solidity
function claimTokens(address _token, address _to) external;
```

### claimWithdrawal


```solidity
function claimWithdrawal(address _address) external;
```

### claimWithdrawals


```solidity
function claimWithdrawals(address[] calldata _addresses) external;
```

### executeSystemWithdrawals


```solidity
function executeSystemWithdrawals(uint256, uint64[] calldata _amounts, address[] calldata _addresses) external;
```

### executeSystemWithdrawals


```solidity
function executeSystemWithdrawals(uint64[] calldata _amounts, address[] calldata _addresses) external;
```

### unwrapTokens


```solidity
function unwrapTokens(address _unwrapper, address _token) external;
```

### withdrawableAmount


```solidity
function withdrawableAmount(address _address) external view returns (uint256);
```

### supportsInterface


```solidity
function supportsInterface(bytes4 interfaceId) external pure returns (bool);
```

## Events
### DepositEvent

```solidity
event DepositEvent(bytes pubkey, bytes withdrawal_credentials, bytes amount, bytes signature, bytes index);
```

