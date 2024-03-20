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



### Deployed contracts

| Name  | Gnosis Mainnet |
| ------------- | ------------- |
| ERC1967 Proxy  | [0xB11796Aa856762DBa6B9d42EA71d2C8D7f85a3e1](https://gnosisscan.io/address/0xB11796Aa856762DBa6B9d42EA71d2C8D7f85a3e1#code)  |
| ClaimRegistryUpgradable  | [0xd08ef4080306d3222e6d6324095a0daa779c0e95](https://gnosisscan.io/address/0xd08ef4080306d3222e6d6324095a0daa779c0e95#code)  |


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
