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
./scripts/deploy.sh local
```

## Deploying to network

```
forge script DeployScript --fork-url <RPC_URL> --broadcast -i 1

forge script EnableScript --sig "run(address)" --fork-url <RPC_URL> --broadcast -i 1 <AMPLIFI_ADDRESS>
```