# Staking Rewards Claim Automation On Gnosis Chain

The implementation of staking rewards withdrawals on the [Gnosis Chain differs from Ethereum](https://github.com/gnosischain/specs/blob/master/execution/withdrawals.md), and rewards aren't distributed automatically. Consequently, automating rewards distribution through an application layer protocol becomes essential. This project is motivated by Gnosis validators' desire for automated staking rewards distribution and maintains the opt-in/opt-out approach [proposed by the community](https://forum.gnosis.io/t/stop-autoclaim-for-gc-validators/7168). The repository includes a claim registry contract enabling validators to set claim thresholds and frequencies. For claim execution, the [PowerPool](https://powerpool-finance.ipns.dweb.link/) keepers network is chosen as the most Web3.0 idiomatic approach.


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
| ERC1967 Proxy  | [0x8cb7C925d231f3355560F6D4D880c132B61C4083](https://gnosisscan.io/address/0x8cb7c925d231f3355560f6d4d880c132b61c4083#code)  |
| ClaimRegistryUpgradable (implementation) | [0x89ab85199492d2bb8100fbb5f7055f5e03c83680](https://gnosisscan.io/address/0x89ab85199492d2bb8100fbb5f7055f5e03c83680#code)  |


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
