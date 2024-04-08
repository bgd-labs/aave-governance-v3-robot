// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {AaveV3Optimism} from 'aave-address-book/AaveV3Optimism.sol';
import {MiscOptimism} from 'aave-address-book/MiscOptimism.sol';
import {GovernanceV3Optimism} from 'aave-address-book/GovernanceV3Optimism.sol';
import {OptimismStackExecutionRobot} from '../src/contracts/OptimismStackExecutionRobot.sol';
import {GovV3StorageHelpers, StorageHelpers, IPayloadsControllerCore as IPayloadsController, PayloadsControllerUtils as PayloadsUtils} from 'aave-helpers/GovV3Helpers.sol';
import './ExecutionChainRobot.t.sol';

contract OptimismStackExecutionRobotTest is ExecutionChainRobotTest {
  function setUp() override public {
    vm.createSelectFork('optimism', 118443650); // Apr-7-2024

    proxyFactory = TransparentProxyFactory(MiscOptimism.TRANSPARENT_PROXY_FACTORY);
    shortExecutor = Executor(payable(GovernanceV3Optimism.EXECUTOR_LVL_1));

    executor.executorConfig.executor = address(shortExecutor);

    payloadsController = PayloadsControllerMock(payable(address(GovernanceV3Optimism.PAYLOADS_CONTROLLER)));

    MockAggregator chainLinkFastGasFeed = MockAggregator(0xe9B80c60A2333dCA98c483a8a1efAFaf17C5d4Ac);
    address optimismOvmGasOracle = 0x420000000000000000000000000000000000000F;
    robotKeeper = new OptimismStackExecutionRobot(address(payloadsController), address(chainLinkFastGasFeed), optimismOvmGasOracle);
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
