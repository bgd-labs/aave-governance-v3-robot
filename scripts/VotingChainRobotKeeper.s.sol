// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {console} from 'forge-std/console.sol';
import '../src/contracts/VotingChainRobotKeeper.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {GovernanceV3Polygon} from 'aave-address-book/GovernanceV3Polygon.sol';
import {GovernanceV3Avalanche} from 'aave-address-book/GovernanceV3Avalanche.sol';

contract DeployFuji is Script {
  VotingChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new VotingChainRobotKeeper(
      0x319a17bb9Bf10743bf630b78D866CD0d3BbAD532, // votingMachine
      0x5F21c2CEb1577487862FC2Bf990da8629C5db101 // rootsConsumer
    );

    console.log('Voting chain fuji keeper address', address(keeper));
    vm.stopBroadcast();
  }
}

contract DeployMumbai is Script {
  VotingChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new VotingChainRobotKeeper(
      0x05D0215cFC8D4B726085ADDb1ce43bC5C70f9D8f, // votingMachine
      0x78B11b5e8C7e48e53d835cd0A1b58AB187C43087 // rootsConsumer
    );

    console.log('Voting chain mumbai keeper address', address(keeper));
    vm.stopBroadcast();
  }
}

contract DeployBnbTestnet is Script {
  VotingChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new VotingChainRobotKeeper(
      0x60Df733B241c2DD47829b40222E7e7Fc9989e580, // votingMachine
      0x3dB5d1b04efED3c48D22113F967c426524A7e1f4 // rootsConsumer
    );

    console.log('Voting chain bnb testnet keeper address', address(keeper));
    vm.stopBroadcast();
  }
}

contract DeploySepolia is Script {
  VotingChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new VotingChainRobotKeeper(
      0xB379f8a3E62Ff807E827F853B36688d1d7aD692f, // votingMachine
      0xe8237a48aFA5A716812B0231e2bfc8348bd143cd // rootsConsumer
    );

    console.log('Voting chain sepolia testnet keeper address', address(keeper));
    vm.stopBroadcast();
  }
}

contract DeployGoerli is Script {
  VotingChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new VotingChainRobotKeeper(
      0xE8AD5ab6295c16D04257BC6Cd6D447ff4018FF89, // votingMachine
      0x420B9331a13BfcFf701d36490492f53B63cA1579 // rootsConsumer
    );

    console.log('Voting chain goerli testnet keeper address', address(keeper));
    vm.stopBroadcast();
  }
}

contract DeployMainnet is Script {
  VotingChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new VotingChainRobotKeeper(
      GovernanceV3Ethereum.VOTING_MACHINE,
      0x2fA6F0A65886123AFD24A575aE4554d0FCe8B577 // rootsConsumer
    );

    console.log('Voting chain mainnet keeper address', address(keeper));
    vm.stopBroadcast();
  }
}

contract DeployPolygon is Script {
  VotingChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new VotingChainRobotKeeper(
      GovernanceV3Polygon.VOTING_MACHINE,
      0xE77aF99210AC55939e1ba0bFC6A9a20E1Da73b25 // rootsConsumer
    );

    console.log('Voting chain polygon keeper address', address(keeper));
    vm.stopBroadcast();
  }
}

contract DeployAvax is Script {
  VotingChainRobotKeeper public keeper;

  function run() external {
    vm.startBroadcast();
    keeper = new VotingChainRobotKeeper(
      GovernanceV3Avalanche.VOTING_MACHINE,
      0x6264E51782D739caf515a1Bd4F9ae6881B58621b // rootsConsumer
    );

    console.log('Voting chain avax keeper address', address(keeper));
    vm.stopBroadcast();
  }
}
