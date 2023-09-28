# Aave Governance v3 Robot Setup instructions

## General setup

This repo has forge dependencies. You will need to install foundry and run:

```
npm i // install package dependencies
forge install // install dependency libraries
```

To be able to run the tests, you will need to fill a `.env` file with your keys:

To run the tests:

```
forge test
```

## Env Configuration

An `.env.example` in included in the repository, that can be used as template to fill all the required configurations

```shell
cp .env.example .env
```

## Scripts

All the deployment scripts can be found [here](../scripts).

The scripts consist on:

- [scripts/ExecutionChainRobotKeeper.s.sol](../scripts/ExecutionChainRobotKeeper.s.sol): script to deploy Execution Chain Robot on all the execution chain networks.
- [scripts/GovernanceChainKeeper.s.sol](../scripts/GovernanceChainKeeper.s.sol): script to deploy Governance Chain Robot on the core network (ethereum).
- [scripts/RootsConsumer.s.sol](../scripts/RootsConsumer.s.sol): script to deploy the Roots Consumer on all the voting chain networks.
- [scripts/VotingChainRobotKeeper.s.sol](../scripts/VotingChainRobotKeeper.s.sol): script to deploy the Voting Chain Robot on all the voting chain networks.
