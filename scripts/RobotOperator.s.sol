// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {console} from 'forge-std/console.sol';
import {AaveCLRobotOperator} from 'src/contracts/AaveCLRobotOperator.sol';
import {AaveV3Ethereum, MiscEthereum, GovernanceV3Ethereum, AaveV3Polygon, MiscPolygon, GovernanceV3Polygon, AaveV3Optimism, MiscOptimism, GovernanceV3Optimism, AaveV3Arbitrum, MiscArbitrum, GovernanceV3Arbitrum, AaveV3Avalanche, MiscAvalanche, GovernanceV3Avalanche, AaveV3Base, MiscBase, GovernanceV3Base, AaveV3BNB, MiscBNB, GovernanceV3BNB} from 'aave-address-book/AaveAddressBook.sol';
import {ITransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/interfaces/ITransparentProxyFactory.sol';

library DeployRobotOperator {
  function _deploy(
    address proxyFactory,
    address proxyAdmin,
    address chainlinkRegistry,
    address chainlinkRegistrar,
    address withdrawAddress,
    address owner,
    address guardian
  ) internal returns (address) {
    address robotOperatorImpl = address(new AaveCLRobotOperator());
    AaveCLRobotOperator robotOperator = AaveCLRobotOperator(
      ITransparentProxyFactory(proxyFactory).createDeterministic(
        robotOperatorImpl,
        proxyAdmin,
        abi.encodeWithSelector(
          AaveCLRobotOperator.initialize.selector,
          chainlinkRegistry,
          chainlinkRegistrar,
          withdrawAddress,
          owner,
          guardian
        ),
        'v1'
      )
    );

    return address(robotOperator);
  }
}

contract DeployMainnet is Script {
  function run() external {
    vm.startBroadcast();
    address robotOperator = DeployRobotOperator._deploy(
      MiscEthereum.TRANSPARENT_PROXY_FACTORY,
      MiscEthereum.PROXY_ADMIN,
      0x6593c7De001fC8542bB1703532EE1E5aA0D458fD, // registry
      0x6B0B234fB2f380309D47A7E9391E29E9a179395a, // registrar
      address(AaveV3Ethereum.COLLECTOR),
      GovernanceV3Ethereum.EXECUTOR_LVL_1,
      0xff37939808EcF199A2D599ef91D699Fb13dab7F7 // guardian
    );

    console.log('Ethereum robot operator contract', address(robotOperator));
    vm.stopBroadcast();
  }
}

contract DeployPolygon is Script {
  function run() external {
    vm.startBroadcast();
    address robotOperator = DeployRobotOperator._deploy(
      MiscPolygon.TRANSPARENT_PROXY_FACTORY,
      MiscPolygon.PROXY_ADMIN,
      0x08a8eea76D2395807Ce7D1FC942382515469cCA1, // registry
      0x0Bc5EDC7219D272d9dEDd919CE2b4726129AC02B, // registrar
      address(AaveV3Polygon.COLLECTOR),
      GovernanceV3Polygon.EXECUTOR_LVL_1,
      0x7683177b05a92e8B169D833718BDF9d0ce809aA9 // guardian
    );

    console.log('Polygon robot operator contract', address(robotOperator));
    vm.stopBroadcast();
  }
}

contract DeployOptimism is Script {
  function run() external {
    vm.startBroadcast();
    address robotOperator = DeployRobotOperator._deploy(
      MiscOptimism.TRANSPARENT_PROXY_FACTORY,
      MiscOptimism.PROXY_ADMIN,
      0x696fB0d7D069cc0bb35a7c36115CE63E55cb9AA6, // registry
      0xe601C5837307f07aB39DEB0f5516602f045BF14f, // registrar
      address(AaveV3Optimism.COLLECTOR),
      GovernanceV3Optimism.EXECUTOR_LVL_1,
      0x9867Ce43D2a574a152fE6b134F64c9578ce3cE03 // guardian
    );

    console.log('Optimism robot operator contract', address(robotOperator));
    vm.stopBroadcast();
  }
}

contract DeployArbitrum is Script {
  function run() external {
    vm.startBroadcast();
    address robotOperator = DeployRobotOperator._deploy(
      MiscArbitrum.TRANSPARENT_PROXY_FACTORY,
      MiscArbitrum.PROXY_ADMIN,
      0x37D9dC70bfcd8BC77Ec2858836B923c560E891D1, // registry
      0x86EFBD0b6736Bed994962f9797049422A3A8E8Ad, // registrar
      address(AaveV3Arbitrum.COLLECTOR),
      GovernanceV3Arbitrum.EXECUTOR_LVL_1,
      0x87dFb794364f2B117C8dbaE29EA622938b3Ce465 // guardian
    );

    console.log('Arbitrum robot operator contract', address(robotOperator));
    vm.stopBroadcast();
  }
}

contract DeployAvalanche is Script {
  function run() external {
    vm.startBroadcast();
    address robotOperator = DeployRobotOperator._deploy(
      MiscAvalanche.TRANSPARENT_PROXY_FACTORY,
      MiscAvalanche.PROXY_ADMIN,
      0x7f00a3Cd4590009C349192510D51F8e6312E08CB, // registry
      0x5Cb7B29e621810Ce9a04Bee137F8427935795d00, // registrar
      address(AaveV3Avalanche.COLLECTOR),
      GovernanceV3Avalanche.EXECUTOR_LVL_1,
      0xD68c00a1A4a33876C5EC71A2Bf7bBd8676d72BF6 // guardian
    );

    console.log('Avalanche robot operator contract', address(robotOperator));
    vm.stopBroadcast();
  }
}

contract DeployBNB is Script {
  function run() external {
    vm.startBroadcast();
    address robotOperator = DeployRobotOperator._deploy(
      MiscBNB.TRANSPARENT_PROXY_FACTORY,
      MiscBNB.PROXY_ADMIN,
      0xDc21E279934fF6721CaDfDD112DAfb3261f09A2C, // registry
      0xf671F60bCC964B309D22424886FF202807381B32, // registrar
      address(AaveV3BNB.COLLECTOR),
      GovernanceV3BNB.EXECUTOR_LVL_1,
      0xB5ABc2BcB050bE70EF53338E547d87d06F7c877d // guardian
    );

    console.log('BNB robot operator contract', address(robotOperator));
    vm.stopBroadcast();
  }
}

contract DeployBase is Script {
  function run() external {
    vm.startBroadcast();
    address robotOperator = DeployRobotOperator._deploy(
      MiscBase.TRANSPARENT_PROXY_FACTORY,
      MiscBase.PROXY_ADMIN,
      0xE226D5aCae908252CcA3F6CEFa577527650a9e1e, // registry
      0xD8983a340A96b9C2Bb6855E46847aE134Db71fB1, // registrar
      address(AaveV3Base.COLLECTOR),
      GovernanceV3Base.EXECUTOR_LVL_1,
      0x1B7e7b282Dff5661704E32838CAE4677FEB4C1F2 // guardian
    );

    console.log('Base robot operator contract', address(robotOperator));
    vm.stopBroadcast();
  }
}
