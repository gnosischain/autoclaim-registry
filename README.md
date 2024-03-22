## Setup

### Environment

```shell
forge install
```


```shell
cp .env.example .env
```
*set your environment variables


### Deploy

```shell
forge script script/Deploy.s.sol:DeployClaimRegistryUpgradable --rpc-url $GNOSIS_RPC_URL --broadcast --etherscan-api-key $ETHERSCAN_API_KEY --verify --watch
```

### Docs

```shell
forge doc --serve --port 4000
```

## Deployed contracts

| Name  | Gnosis Mainnet |
| ------------- | ------------- |
| ERC1967 Proxy  | [0xB11796Aa856762DBa6B9d42EA71d2C8D7f85a3e1](https://gnosisscan.io/address/0xB11796Aa856762DBa6B9d42EA71d2C8D7f85a3e1#code)  |
| ClaimRegistryUpgradable  | [0xd08ef4080306d3222e6d6324095a0daa779c0e95](https://gnosisscan.io/address/0xd08ef4080306d3222e6d6324095a0daa779c0e95#code)  |


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




### Foundry Usage

#### Build

```shell
$ forge build
```

#### Test

```shell
$ forge test
```

#### Format

```shell
$ forge fmt
```

#### Gas Snapshots
```shell
$ forge snapshot
```

##### Anvil
```shell
$ anvil
```

#### Cast
```shell
$ cast <subcommand>
```

#### Help
```shell
$ forge --help
$ anvil --help
$ cast --help
```
