// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ExecutionChainRobotKeeper} from '../ExecutionChainRobotKeeper.sol';
import {AutomationCompatibleInterface} from 'chainlink/src/v0.8/interfaces/automation/AutomationCompatibleInterface.sol';
import {GasCappedRobotBase} from './GasCappedRobotBase.sol';

/**
 * @title GasCappedExecutionChainRobotKeeper
 * @author BGD Labs
 * @notice Contract to perform automation on payloads controller.
 *         The difference from ExecutionChainRobotKeeper is that automation is only
 *         performed when the network gas price in within the maximum configured range.
 */
contract GasCappedExecutionChainRobotKeeper is GasCappedRobotBase, ExecutionChainRobotKeeper {
  /**
   * @param payloadsController address of the payloads controller contract.
   * @param gasPriceOracle address of the gas price oracle contract.
   */
  constructor(
    address payloadsController,
    address gasPriceOracle
  ) ExecutionChainRobotKeeper(payloadsController) GasCappedRobotBase(gasPriceOracle) {}

  /**
   * @inheritdoc AutomationCompatibleInterface
   * @dev run off-chain, checks if payload should be executed
   *      also checks that the gas price of the network in within range to perform actions
   */
  function checkUpkeep(bytes memory) public view virtual override returns (bool, bytes memory) {
    if (!isGasPriceInRange()) return (false, '');

    return super.checkUpkeep('');
  }
}