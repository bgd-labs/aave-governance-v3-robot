// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {AaveV3Metis} from 'aave-address-book/AaveV3Metis.sol';
import {MiscMetis} from 'aave-address-book/MiscMetis.sol';
import {GovernanceV3Metis} from 'aave-address-book/GovernanceV3Metis.sol';
import {GelatoGasCappedExecutionChainRobotKeeper} from '../src/contracts/gelato/GelatoGasCappedExecutionChainRobotKeeper.sol';
import {IGasPriceCappedRobot} from '../src/interfaces/IGasPriceCappedRobot.sol';
import './GasCappedExecutionChainRobotKeeper.t.sol';

contract GelatoGasCappedExecutionChainRobotKeeperTest is GasCappedExecutionChainRobotKeeperTest {
  uint256 public constant NETWORK_GAS_PRICE = 100;

  function setUp() virtual public override {
    vm.createSelectFork('metis', 16538593); // Apr-12-2024

    proxyFactory = TransparentProxyFactory(MiscMetis.TRANSPARENT_PROXY_FACTORY);
    shortExecutor = Executor(payable(GovernanceV3Metis.EXECUTOR_LVL_1));

    executor.executorConfig.executor = address(shortExecutor);

    payloadsController = PayloadsControllerMock(
      payable(address(GovernanceV3Metis.PAYLOADS_CONTROLLER))
    );

    vm.startPrank(GUARDIAN);
    robotKeeper = new GelatoGasCappedExecutionChainRobotKeeper(
      address(payloadsController)
    );

    GasCappedExecutionChainRobotKeeper(address(robotKeeper)).setMaxGasPrice(
      NETWORK_GAS_PRICE
    );
    vm.stopPrank();

    // set the gasPrice of the network, as the default is 0
    vm.txGasPrice(NETWORK_GAS_PRICE);

    // to make sure all the current queued payloads expire
    vm.warp(block.timestamp + 100 days);
  }

  function test_isGasPriceInRange() override public {
    assertEq(IGasPriceCappedRobot(address(robotKeeper)).isGasPriceInRange(), true);

    vm.startPrank(GUARDIAN);
    IGasPriceCappedRobot(address(robotKeeper)).setMaxGasPrice(
      NETWORK_GAS_PRICE - 1
    );
    vm.stopPrank();

    assertEq(IGasPriceCappedRobot(address(robotKeeper)).isGasPriceInRange(), false);
  }

  function test_robotExecutionOnlyWhenGasPriceInRange() override public {
    vm.startPrank(GUARDIAN);
    IGasPriceCappedRobot(address(robotKeeper)).setMaxGasPrice(
      NETWORK_GAS_PRICE - 1
    );
    vm.stopPrank();

    uint40 payloadId = _createPayloadAndQueue();

    IPayloadsControllerCore.Payload memory payload = payloadsController.getPayloadById(payloadId);

    uint256 extraTime = 10;
    uint256 skipTimeToTimelock = payload.queuedAt +
      payloadsController
        .getExecutorSettingsByAccessControl(PayloadsControllerUtils.AccessControl.Level_1)
        .delay +
      extraTime;
    vm.warp(skipTimeToTimelock);

    assertEq(uint256(payload.state), uint256(IPayloadsControllerCore.PayloadState.Queued));

    bool didRobotRun = _checkAndPerformUpKeep(robotKeeper);

    assertEq(didRobotRun, false);

    assertEq(
      uint256(payloadsController.getPayloadById(payloadId).state),
      uint256(IPayloadsControllerCore.PayloadState.Queued)
    );
  }

  function _checkAndPerformUpKeep(
    ExecutionChainRobotKeeper executionChainRobotKeeper
  ) internal override returns (bool) {
    (bool shouldRunKeeper, bytes memory encodedPerformData) = executionChainRobotKeeper.checkUpkeep('');
    if (shouldRunKeeper) {
      (bool status, ) = address(executionChainRobotKeeper).call(encodedPerformData);
      assertTrue(status, 'Perform Upkeep Failed');
    }
    return shouldRunKeeper;
  }
}
