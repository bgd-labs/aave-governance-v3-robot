# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
update:; forge update

# Build & test
build  :; forge build --sizes
test   :; forge test -vvv --ffi

# Utilities
download :; cast etherscan-source --chain ${chain} -d src/etherscan/${chain}_${address} ${address}
git-diff :
	@mkdir -p diffs
	@printf '%s\n%s\n%s\n' "\`\`\`diff" "$$(git diff --no-index --diff-algorithm=patience --ignore-space-at-eol ${before} ${after})" "\`\`\`" > diffs/${out}.md

# Mainnet deployments
deploy-mainnet-gov-keeper :; forge script ./scripts/GovernanceChainRobotKeeper.s.sol:DeployMainnet --rpc-url mainnet --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER}  --etherscan-api-key ${ETHERSCAN_API_KEY_MAINNET} --gas-estimate-multiplier 175 --verify -vvvv
deploy-mainnet-execution-keeper :; forge script ./scripts/ExecutionChainRobotKeeper.s.sol:DeployMainnet --rpc-url mainnet --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER}  --etherscan-api-key ${ETHERSCAN_API_KEY_MAINNET} --gas-estimate-multiplier 175 --verify -vvvv
deploy-mainnet-consumer :; forge script ./scripts/RootsConsumer.s.sol:DeployMainnet --rpc-url mainnet --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER}  --etherscan-api-key ${ETHERSCAN_API_KEY_MAINNET} --gas-estimate-multiplier 175 --verify -vvvv
deploy-mainnet-voting-keeper :; forge script ./scripts/VotingChainRobotKeeper.s.sol:DeployMainnet --rpc-url mainnet --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER}  --etherscan-api-key ${ETHERSCAN_API_KEY_MAINNET} --gas-estimate-multiplier 175 --verify -vvvv

# Polygon deployments
deploy-polygon-execution-keeper :; forge script ./scripts/ExecutionChainRobotKeeper.s.sol:DeployPolygon --rpc-url polygon --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER}  --etherscan-api-key ${ETHERSCAN_API_KEY_POLYGON} --gas-estimate-multiplier 175 --verify -vvvv
deploy-polygon-consumer :; forge script ./scripts/RootsConsumer.s.sol:DeployPolygon --rpc-url polygon --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER}  --etherscan-api-key ${ETHERSCAN_API_KEY_POLYGON} --gas-estimate-multiplier 175 --verify -vvvv
deploy-polygon-voting-keeper :; forge script ./scripts/VotingChainRobotKeeper.s.sol:DeployPolygon --rpc-url polygon --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER}  --etherscan-api-key ${ETHERSCAN_API_KEY_POLYGON} --gas-estimate-multiplier 175 --verify -vvvv

# Avalanche deployments
deploy-avax-execution-keeper :; forge script ./scripts/ExecutionChainRobotKeeper.s.sol:DeployAvax --rpc-url avalanche --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER}  --etherscan-api-key ${ETHERSCAN_API_KEY_AVALANCHE} --gas-estimate-multiplier 175 --verify -vvvv
deploy-avax-consumer :; forge script ./scripts/RootsConsumer.s.sol:DeployAvax --rpc-url avalanche --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER}  --etherscan-api-key ${ETHERSCAN_API_KEY_AVALANCHE} --gas-estimate-multiplier 175 --verify -vvvv
deploy-avax-voting-keeper :; forge script ./scripts/VotingChainRobotKeeper.s.sol:DeployAvax --rpc-url avalanche --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER}  --etherscan-api-key ${ETHERSCAN_API_KEY_AVALANCHE} --gas-estimate-multiplier 175 --verify -vvvv

# Optimism deployments
deploy-optimism-execution-keeper :; forge script ./scripts/ExecutionChainRobotKeeper.s.sol:DeployOptimism --rpc-url optimism --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER}  --etherscan-api-key ${ETHERSCAN_API_KEY_OPTIMISM} --gas-estimate-multiplier 175 --verify -vvvv

# Arbitrum deployments
deploy-arbitrum-execution-keeper :; forge script ./scripts/ExecutionChainRobotKeeper.s.sol:DeployArbitrum --rpc-url arbitrum --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER}  --etherscan-api-key ${ETHERSCAN_API_KEY_ARBITRUM} --gas-estimate-multiplier 175 --verify -vvvv

# Bnb deployments
deploy-bnb-execution-keeper :; forge script ./scripts/ExecutionChainRobotKeeper.s.sol:DeployBnb --rpc-url bnb --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER}  --etherscan-api-key ${ETHERSCAN_API_KEY_ARBITRUM} --gas-estimate-multiplier 175 --verify -vvvv

# Base deployments
deploy-base-operator :; forge script ./scripts/RobotOperator.s.sol:DeployBase --rpc-url base --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER}  --etherscan-api-key ${ETHERSCAN_API_KEY_BASE} --gas-estimate-multiplier 175 --verify -vvvv
deploy-base-execution-keeper :; forge script ./scripts/ExecutionChainRobotKeeper.s.sol:DeployBase --rpc-url base --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER}  --etherscan-api-key ${ETHERSCAN_API_KEY_BASE} --gas-estimate-multiplier 175 --verify -vvvv

# Gnosis deployments
deploy-gnosis-execution-keeper :; forge script ./scripts/ExecutionChainRobotKeeper.s.sol:DeployGnosis --rpc-url gnosis --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER}  --etherscan-api-key ${ETHERSCAN_API_KEY_GNOSIS} --gas-estimate-multiplier 175 --verify -vvvv

# Scroll deployments
deploy-scroll-execution-keeper :; forge script ./scripts/ExecutionChainRobotKeeper.s.sol:DeployScroll --rpc-url scroll --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER}  --etherscan-api-key ${ETHERSCAN_API_KEY_SCROLL} --gas-estimate-multiplier 175 --verify -vvvv
