// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {GasCappedExecutionChainRobotKeeper} from '../src/contracts/gasprice-capped-robots/GasCappedExecutionChainRobotKeeper.sol';
import {GovV3StorageHelpers, StorageHelpers, IPayloadsControllerCore as IPayloadsController, PayloadsControllerUtils as PayloadsUtils} from 'aave-helpers/GovV3Helpers.sol';
import {MockAggregator} from 'chainlink/src/v0.8/mocks/MockAggregator.sol';
import './ExecutionChainRobotKeeper.t.sol';

contract GasCappedExecutionChainRobotKeeperTest is ExecutionChainRobotKeeperTest {
  function setUp() override public {
    vm.createSelectFork('mainnet', 19609260); // Apr-8-2024

    proxyFactory = TransparentProxyFactory(MiscEthereum.TRANSPARENT_PROXY_FACTORY);
    shortExecutor = Executor(payable(GovernanceV3Ethereum.EXECUTOR_LVL_1));

    executor.executorConfig.executor = address(shortExecutor);

    payloadsController = PayloadsControllerMock(payable(address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER)));

    MockAggregator chainLinkFastGasFeed = MockAggregator(0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C);
    robotKeeper = new GasCappedExecutionChainRobotKeeper(address(payloadsController), address(chainLinkFastGasFeed));

    GasCappedExecutionChainRobotKeeper(address(robotKeeper)).setMaxGasPrice(uint256(chainLinkFastGasFeed.latestAnswer()));

    // to make sure all the current queued payloads expire
    vm.warp(block.timestamp + 100 days);
  }

  function _createPayloadAndQueue() internal override returns (uint40) {
    PayloadTest payload = new PayloadTest();

    IPayloadsController.ExecutionAction[]
      memory actions = new IPayloadsController.ExecutionAction[](1);

    actions[0].target = address(payload);
    actions[0].value = 0;
    actions[0].signature = 'execute()';
    actions[0].callData = bytes('');
    actions[0].withDelegateCall = true;
    actions[0].accessLevel = PayloadsUtils.AccessControl.Level_1;

    uint40 payloadId = GovV3StorageHelpers.injectPayload(vm, IPayloadsController(address(payloadsController)), actions);
    GovV3StorageHelpers.readyPayloadId(vm, IPayloadsController(address(payloadsController)), payloadId);

    return payloadId;
  }
}
