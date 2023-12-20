// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {console} from 'forge-std/console.sol';
import {AaveCLRobotOperator} from 'src/contracts/AaveCLRobotOperator.sol';
import {AaveV3Base} from 'aave-address-book/AaveV3Base.sol';
import {GovernanceV3Base} from 'aave-address-book/GovernanceV3Base.sol';

contract DeployBase is Script {
  AaveCLRobotOperator public robotOperator;

  address constant CHAINLINK_REGISTRY = 0xE226D5aCae908252CcA3F6CEFa577527650a9e1e;
  address constant CHAINLINK_REGISTRAR = 0xD8983a340A96b9C2Bb6855E46847aE134Db71fB1;

  function run() external {
    vm.startBroadcast();
    robotOperator = new AaveCLRobotOperator(
      CHAINLINK_REGISTRY,
      CHAINLINK_REGISTRAR,
      address(AaveV3Base.COLLECTOR),
      0xe3FD707583932a99513a5c65c8463De769f5DAdF
    );

    console.log('Base robot operator contract', address(robotOperator));
    vm.stopBroadcast();
  }
}
