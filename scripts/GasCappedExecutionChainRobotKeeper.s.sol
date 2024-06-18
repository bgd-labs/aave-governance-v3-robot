// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {console} from 'forge-std/console.sol';
import {GasCappedExecutionChainRobotKeeper} from '../src/contracts/gasprice-capped-robots/GasCappedExecutionChainRobotKeeper.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';

contract DeployMainnet is Script {
  GasCappedExecutionChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new GasCappedExecutionChainRobotKeeper(
      address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER), // payloads controller
      0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C // chainlink fast gas feed
    );
    keeper.setMaxGasPrice(150 gwei);

    console.log('Gas Capped Execution chain ethereum keeper address', address(keeper));
    vm.stopBroadcast();
  }
}
