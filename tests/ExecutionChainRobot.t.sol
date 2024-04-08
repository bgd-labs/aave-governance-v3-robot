// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ExecutionChainRobot} from '../src/contracts/ExecutionChainRobot.sol';
import {MockAggregator} from 'chainlink/src/v0.8/mocks/MockAggregator.sol';
import 'aave-governance-v3/tests/payloads/PayloadsControllerCore.t.sol';

contract ExecutionChainRobotTest is Test {
  address public constant PAYLOAD_PORTAL = address(987312);

  ExecutionChainRobot robotKeeper;

  TransparentProxyFactory proxyFactory;

  // payloads controllers
  PayloadsControllerMock payloadsControllerImpl;
  PayloadsControllerMock payloadsController;

  // executors
  IExecutor shortExecutor;
  IPayloadsControllerCore.UpdateExecutorInput executor =
    IPayloadsControllerCore.UpdateExecutorInput({
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      executorConfig: IPayloadsControllerCore.ExecutorConfig({
        delay: uint40(86400),
        executor: address(shortExecutor)
      })
    });

  function setUp() virtual public {
    proxyFactory = new TransparentProxyFactory();
    payloadsControllerImpl = new PayloadsControllerMock();
    shortExecutor = new Executor();

    executor.executorConfig.executor = address(shortExecutor);

    IPayloadsControllerCore.UpdateExecutorInput[]
      memory executors = new IPayloadsControllerCore.UpdateExecutorInput[](1);
    executors[0] = executor;

    address payable payloadsControllerProxy = payable(
      proxyFactory.create(
        address(payloadsControllerImpl),
        address(123),
        abi.encodeWithSelector(
          payloadsControllerImpl.initialize.selector,
          address(this),
          address(1234),
          executors
        )
      )
    );

    // give ownership of executors to PayloadsController
    Ownable ownableShort = Ownable(address(shortExecutor));
    ownableShort.transferOwnership(payloadsControllerProxy);
    payloadsController = PayloadsControllerMock(payloadsControllerProxy);

    MockAggregator chainLinkFastGasFeed = new MockAggregator();
    robotKeeper = new ExecutionChainRobot(address(payloadsController), address(chainLinkFastGasFeed));
  }

  function testExecutePayloadX() public {
    uint40 payloadId = _createPayloadAndQueue();

    IPayloadsControllerCore.Payload memory payload = payloadsController.getPayloadById(payloadId);

    uint256 extraTime = 10;
    uint256 skipTimeToTimelock = payload.queuedAt +
      payloadsController
        .getExecutorSettingsByAccessControl(PayloadsControllerUtils.AccessControl.Level_1)
        .delay +
      extraTime;
    skip(skipTimeToTimelock);

    assertEq(uint256(payload.state), uint256(IPayloadsControllerCore.PayloadState.Queued));

    // _checkAndPerformUpKeep(robotKeeper);

    // assertEq(
    //   uint256(payloadsController.getPayloadById(payloadId).state),
    //   uint256(IPayloadsControllerCore.PayloadState.Executed)
    // );
  }

  function testOnlyOneExecuteAtATime() public {
    uint40[] memory payloadIds = new uint40[](5);
    for (uint i = 0; i < 5; i++) {
      payloadIds[i] = _createPayloadAndQueue();
    }
    IPayloadsControllerCore.Payload memory payload = payloadsController.getPayloadById(
      payloadIds[0]
    );

    uint256 extraTime = 10;
    uint256 skipTimeToTimelock = payload.queuedAt +
      payloadsController
        .getExecutorSettingsByAccessControl(PayloadsControllerUtils.AccessControl.Level_1)
        .delay +
      extraTime;
    skip(skipTimeToTimelock);

    for (uint i = 0; i < 5; i++) {
      assertEq(
        uint256(payloadsController.getPayloadById(payloadIds[i]).state),
        uint256(IPayloadsControllerCore.PayloadState.Queued)
      );
    }

    _checkAndPerformUpKeep(robotKeeper);

    uint256 payloadsInQueuedStateCount = 0;
    uint256 payloadsInExecutedStateCount = 0;

    for (uint i = 0; i < 5; i++) {
      IPayloadsControllerCore.PayloadState payloadState = (
        payloadsController.getPayloadById(payloadIds[i]).state
      );
      if (payloadState == IPayloadsControllerCore.PayloadState.Queued) {
        payloadsInQueuedStateCount++;
      } else if (payloadState == IPayloadsControllerCore.PayloadState.Executed) {
        payloadsInExecutedStateCount++;
      }
    }
    assertEq(payloadsInExecutedStateCount, 1);
    assertEq(payloadsInQueuedStateCount, 4);
  }

  function testMultipleExecute() public {
    uint40[] memory payloadIds = new uint40[](5);
    for (uint i = 0; i < 5; i++) {
      payloadIds[i] = _createPayloadAndQueue();
    }
    IPayloadsControllerCore.Payload memory payload = payloadsController.getPayloadById(
      payloadIds[0]
    );

    uint256 extraTime = 10;
    uint256 skipTimeToTimelock = payload.queuedAt +
      payloadsController
        .getExecutorSettingsByAccessControl(PayloadsControllerUtils.AccessControl.Level_1)
        .delay +
      extraTime;
    skip(skipTimeToTimelock);

    for (uint i = 0; i < 5; i++) {
      assertEq(
        uint256(payloadsController.getPayloadById(payloadIds[i]).state),
        uint256(IPayloadsControllerCore.PayloadState.Queued)
      );
    }

    for (uint i = 0; i < 5; i++) {
      _checkAndPerformUpKeep(robotKeeper);
    }

    for (uint i = 0; i < 5; i++) {
      uint40 payloadId = uint40(payloadsController.getPayloadById(payloadIds[i]).state);
      assertEq(
        uint256(payloadsController.getPayloadById(payloadId).state),
        uint256(IPayloadsControllerCore.PayloadState.Executed)
      );
    }
  }

  function _checkAndPerformUpKeep(ExecutionChainRobot executionChainRobotKeeper) internal {
    (bool shouldRunKeeper, bytes memory performData) = executionChainRobotKeeper.checkUpkeep('');
    if (shouldRunKeeper) {
      executionChainRobotKeeper.performUpkeep(performData);
    }
  }

  function _createPayloadAndQueue() internal virtual returns (uint40) {
    PayloadTest payload = new PayloadTest();

    IPayloadsControllerCore.ExecutionAction[]
      memory actions = new IPayloadsControllerCore.ExecutionAction[](1);
    actions[0].target = address(payload);
    actions[0].value = 0;
    actions[0].signature = 'execute()';
    actions[0].callData = bytes('');
    actions[0].withDelegateCall = true;
    actions[0].accessLevel = PayloadsControllerUtils.AccessControl.Level_1;

    uint40 payloadId = payloadsController.createPayload(actions);
    _queuePayloadWithId(
      payloadId,
      payloadsController.getPayloadById(payloadId).maximumAccessLevelRequired,
      uint40(block.timestamp + 10)
    );

    return payloadId;
  }

  function _queuePayloadWithId(
    uint40 payloadId,
    PayloadsControllerUtils.AccessControl accessLevel,
    uint40 proposalVoteActivationTimestamp
  ) internal virtual {
    hoax(PAYLOAD_PORTAL);
    payloadsController.queue(payloadId, accessLevel, proposalVoteActivationTimestamp);
  }
}
//
