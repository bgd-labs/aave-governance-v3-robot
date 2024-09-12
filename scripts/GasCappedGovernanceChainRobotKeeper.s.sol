// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {console} from 'forge-std/console.sol';
import {GasCappedGovernanceChainRobotKeeper} from '../src/contracts/gasprice-capped-robots/GasCappedGovernanceChainRobotKeeper.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';

contract DeployMainnet is Script {
  GasCappedGovernanceChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new GasCappedGovernanceChainRobotKeeper(
      address(GovernanceV3Ethereum.GOVERNANCE), // governance
      0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C // chainlink fast gas feed
    );
    keeper.setMaxGasPrice(150 gwei);

    console.log('Gas Capped Governance chain ethereum keeper address', address(keeper));
    vm.stopBroadcast();
  }
}
