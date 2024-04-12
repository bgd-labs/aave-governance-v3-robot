// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {GasCappedExecutionChainRobotKeeper} from '../gasprice-capped-robots/GasCappedExecutionChainRobotKeeper.sol';
import {IGasPriceCappedRobot} from '../../interfaces/IGasPriceCappedRobot.sol';

/**
 * @title GelatoGasCappedExecutionChainRobotKeeper
 * @author BGD Labs
 * @notice Contract to perform automation on payloads controller.
 *         The difference from GasCappedExecutionChainRobotKeeper is that we use tx.gasprice
 *         instead of gas price oracle in order to limit the execution of the robot.
 */
contract GelatoGasCappedExecutionChainRobotKeeper is GasCappedExecutionChainRobotKeeper {
  /**
   * @param payloadsController address of the payloads controller contract.
   */
  constructor(
    address payloadsController
  ) GasCappedExecutionChainRobotKeeper(payloadsController, address(0)) {}

  /// @inheritdoc IGasPriceCappedRobot
  function isGasPriceInRange() public view virtual override returns (bool) {
    if (tx.gasprice > _maxGasPrice) {
      return false;
    }
    return true;
  }
}
