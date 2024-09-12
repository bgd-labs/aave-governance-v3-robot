// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {console} from 'forge-std/console.sol';
import {GasCappedVotingChainRobotKeeper} from '../src/contracts/gasprice-capped-robots/GasCappedVotingChainRobotKeeper.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';

contract DeployMainnet is Script {
  GasCappedVotingChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new GasCappedVotingChainRobotKeeper(
      GovernanceV3Ethereum.VOTING_MACHINE,
      0x2fA6F0A65886123AFD24A575aE4554d0FCe8B577, // rootsConsumer
      0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C // chainlink fast gas feed
    );
    keeper.setMaxGasPrice(150 gwei);

    console.log('Gas Capped Voting chain ethereum keeper address', address(keeper));
    vm.stopBroadcast();
  }
}
