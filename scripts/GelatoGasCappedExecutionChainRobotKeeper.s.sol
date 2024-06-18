// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {console} from 'forge-std/console.sol';
import {GelatoGasCappedExecutionChainRobotKeeper} from '../src/contracts/gelato/GelatoGasCappedExecutionChainRobotKeeper.sol';
import {GovernanceV3Metis} from 'aave-address-book/GovernanceV3Metis.sol';
import {GovernanceV3Gnosis} from 'aave-address-book/GovernanceV3Gnosis.sol';

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
