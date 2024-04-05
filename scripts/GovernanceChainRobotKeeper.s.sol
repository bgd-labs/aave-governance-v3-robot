// // SPDX-License-Identifier: BUSL-1.1
// pragma solidity ^0.8.0;

// import {Script} from 'forge-std/Script.sol';
// import {console} from 'forge-std/console.sol';
// import {GovernanceChainRobotKeeper} from '../src/contracts/GovernanceChainRobotKeeper.sol';
// import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';

// contract DeploySepolia is Script {
//   GovernanceChainRobotKeeper public keeper;

//   function run() external {
//     vm.startBroadcast();
//     keeper = new GovernanceChainRobotKeeper(0x84b3FE5eD74caC496BcB58d448A7c83c523F6E0E);

//     console.log('Governance chain sepolia keeper address', address(keeper));
//     vm.stopBroadcast();
//   }
// }

// contract DeployGoerli is Script {
//   GovernanceChainRobotKeeper public keeper;

//   function run() external {
//     vm.startBroadcast();
//     keeper = new GovernanceChainRobotKeeper(0x586207Df62c7D5D1c9dBb8F61EdF77cc30925C4F);

//     console.log('Governance chain goerli keeper address', address(keeper));
//     vm.stopBroadcast();
//   }
// }

// contract DeployMainnet is Script {
//   GovernanceChainRobotKeeper public keeper;

//   function run() external {
//     vm.startBroadcast();
//     keeper = new GovernanceChainRobotKeeper(address(GovernanceV3Ethereum.GOVERNANCE));

//     console.log('Governance chain mainnet keeper address', address(keeper));
//     vm.stopBroadcast();
//   }
// }
