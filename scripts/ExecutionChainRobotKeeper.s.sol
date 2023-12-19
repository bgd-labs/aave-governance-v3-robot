// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {console} from 'forge-std/console.sol';
import {ExecutionChainRobotKeeper} from '../src/contracts/ExecutionChainRobotKeeper.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {GovernanceV3Polygon} from 'aave-address-book/GovernanceV3Polygon.sol';
import {GovernanceV3Avalanche} from 'aave-address-book/GovernanceV3Avalanche.sol';
import {GovernanceV3Optimism} from 'aave-address-book/GovernanceV3Optimism.sol';
import {GovernanceV3Arbitrum} from 'aave-address-book/GovernanceV3Arbitrum.sol';
import {GovernanceV3BNB} from 'aave-address-book/GovernanceV3BNB.sol';

contract DeployFuji is Script {
  ExecutionChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new ExecutionChainRobotKeeper(0xf1842f9D6C3D9ec1153d7afCBb9cDBC537Ea5d15);

    console.log('Execution chain fuji keeper address', address(keeper));
    vm.stopBroadcast();
  }
}

contract DeployMumbai is Script {
  ExecutionChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new ExecutionChainRobotKeeper(0x92041C9904d1F0b8100D1d7e01B760d2cF1Fb426);

    console.log('Execution chain mumbai keeper address', address(keeper));
    vm.stopBroadcast();
  }
}

contract DeploySepolia is Script {
  ExecutionChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new ExecutionChainRobotKeeper(0x7Bb94b2a8d9fD3f37345Ec5A0b46c234164b4f90); // payloads controller

    console.log('Execution chain sepolia keeper address', address(keeper));
    vm.stopBroadcast();
  }
}

contract DeployBnbTestnet is Script {
  ExecutionChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new ExecutionChainRobotKeeper(0x3b7e598f1cA9bbB6E2b7eA974F4B1E99ac37F59A);

    console.log('Execution chain bnb testnet keeper address', address(keeper));
    vm.stopBroadcast();
  }
}

contract DeployGoerli is Script {
  ExecutionChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new ExecutionChainRobotKeeper(0x064361B3761CcDd17300146bf58a79d1E570382E); // payloads controller

    console.log('Execution chain goerli keeper address', address(keeper));
    vm.stopBroadcast();
  }
}

contract DeployMainnet is Script {
  ExecutionChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new ExecutionChainRobotKeeper(address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER)); // payloads controller

    console.log('Execution chain mainnet keeper address', address(keeper));
    vm.stopBroadcast();
  }
}

contract DeployPolygon is Script {
  ExecutionChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new ExecutionChainRobotKeeper(address(GovernanceV3Polygon.PAYLOADS_CONTROLLER)); // payloads controller

    console.log('Execution chain polygon keeper address', address(keeper));
    vm.stopBroadcast();
  }
}

contract DeployAvax is Script {
  ExecutionChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new ExecutionChainRobotKeeper(address(GovernanceV3Avalanche.PAYLOADS_CONTROLLER)); // payloads controller

    console.log('Execution chain avax keeper address', address(keeper));
    vm.stopBroadcast();
  }
}

contract DeployOptimism is Script {
  ExecutionChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new ExecutionChainRobotKeeper(address(GovernanceV3Optimism.PAYLOADS_CONTROLLER)); // payloads controller

    console.log('Execution chain optimism keeper address', address(keeper));
    vm.stopBroadcast();
  }
}

contract DeployArbitrum is Script {
  ExecutionChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new ExecutionChainRobotKeeper(address(GovernanceV3Arbitrum.PAYLOADS_CONTROLLER)); // payloads controller

    console.log('Execution chain arbitrum keeper address', address(keeper));
    vm.stopBroadcast();
  }
}

contract DeployBnb is Script {
  ExecutionChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new ExecutionChainRobotKeeper(address(GovernanceV3BNB.PAYLOADS_CONTROLLER));

    console.log('Execution chain bnb keeper address', address(keeper));
    vm.stopBroadcast();
  }
}
