# LazAI Network Smart Contracts

## Get Started

### Build

```shell
forge build
```

### Test

```shell
forge test
```

### Format

```shell
forge fmt
```

### Gas Snapshots

```shell
forge snapshot
```

### Deploy

```shell
forge script script/Deploy.s.sol:Deploy --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast --slow
```

For example, we can deploy it on the LazAI testnet

```shell
forge script script/Deploy.s.sol:Deploy --rpc-url https://lazai-testnet.metisdevops.link --private-key $PRIVATE_KEY --broadcast --slow
```
