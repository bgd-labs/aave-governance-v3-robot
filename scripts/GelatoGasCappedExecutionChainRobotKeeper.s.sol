// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {console} from 'forge-std/console.sol';
import {GelatoGasCappedExecutionChainRobotKeeper} from '../src/contracts/gelato/GelatoGasCappedExecutionChainRobotKeeper.sol';
import {GovernanceV3Metis} from 'aave-address-book/GovernanceV3Metis.sol';
import {GovernanceV3Gnosis} from 'aave-address-book/GovernanceV3Gnosis.sol';
import {GovernanceV3Linea} from 'aave-address-book/GovernanceV3Linea.sol';
import {GovernanceV3Sonic} from 'aave-address-book/GovernanceV3Sonic.sol';

contract DeployMetis is Script {
  GelatoGasCappedExecutionChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new GelatoGasCappedExecutionChainRobotKeeper(address(GovernanceV3Metis.PAYLOADS_CONTROLLER)); // payloads controller
    keeper.setMaxGasPrice(50 gwei);

    console.log('Gelato Gas Capped Execution chain metis keeper address', address(keeper));
    vm.stopBroadcast();
  }
}

contract DeployGnosis is Script {
  GelatoGasCappedExecutionChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new GelatoGasCappedExecutionChainRobotKeeper(address(GovernanceV3Gnosis.PAYLOADS_CONTROLLER)); // payloads controller
    keeper.setMaxGasPrice(50 gwei);

    console.log('Gelato Gas Capped Execution chain gnosis keeper address', address(keeper));
    vm.stopBroadcast();
  }
}

contract DeployLinea is Script {
  GelatoGasCappedExecutionChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new GelatoGasCappedExecutionChainRobotKeeper(address(GovernanceV3Linea.PAYLOADS_CONTROLLER)); // payloads controller
    keeper.setMaxGasPrice(50 gwei);

    console.log('Gelato Gas Capped Execution chain linea keeper address', address(keeper));
    vm.stopBroadcast();
  }
}

contract DeploySonic is Script {
  GelatoGasCappedExecutionChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new GelatoGasCappedExecutionChainRobotKeeper(address(GovernanceV3Sonic.PAYLOADS_CONTROLLER)); // payloads controller
    keeper.setMaxGasPrice(750 gwei);

    console.log('Gelato Gas Capped Execution chain sonic keeper address', address(keeper));
    vm.stopBroadcast();
  }
}
