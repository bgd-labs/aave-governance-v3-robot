// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {console} from 'forge-std/console.sol';
import {GelatoGasCappedExecutionChainRobotKeeper} from '../../src/contracts/gelato/GelatoGasCappedExecutionChainRobotKeeper.sol';
import {GovernanceV3ZkSync} from 'aave-address-book/GovernanceV3ZkSync.sol';

contract DeployZkSync is Script {
  GelatoGasCappedExecutionChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new GelatoGasCappedExecutionChainRobotKeeper(address(GovernanceV3ZkSync.PAYLOADS_CONTROLLER)); // payloads controller
    keeper.setMaxGasPrice(50 gwei);
    keeper.transferOwnership(0xe3FD707583932a99513a5c65c8463De769f5DAdF);

    console.log('Gelato Gas Capped Execution chain zkSync keeper address', address(keeper));
    vm.stopBroadcast();
  }
}
