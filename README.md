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
