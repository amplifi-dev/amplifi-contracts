# Amplifi Contracts

## Getting Started

Clone, setup your .env and:
```
forge install

forge test
```

## Deploying locally
```
# In one terminal
./scripts/node.sh

# In another terminal
./scripts/local.sh
```

## Deploying to network

```
forge script DeployScript --fork-url <RPC_URL> --broadcast

# Update .env AMPLIFI variable with the deployed address

forge script EnableScript --fork-url <RPC_URL> --broadcast
# ProcessFeesScript must be run with --slow
forge script ProcessFeesScript --fork-url <RPC_URL> --broadcast --slow
```

### [Deployed Addresses 🔗](https://docs.perpetualyield.io/engineering/deployed-contract-addresses)
