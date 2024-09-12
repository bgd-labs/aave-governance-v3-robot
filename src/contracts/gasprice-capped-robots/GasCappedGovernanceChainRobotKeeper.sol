// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {GovernanceChainRobotKeeper} from '../GovernanceChainRobotKeeper.sol';
import {AutomationCompatibleInterface} from 'chainlink/src/v0.8/interfaces/automation/AutomationCompatibleInterface.sol';
import {GasCappedRobotBase} from './GasCappedRobotBase.sol';

/**
 * @title GasCappedGovernanceChainRobotKeeper
 * @author BGD Labs
 * @notice Contract to perform automation on governance contract for goveranance v3.
 *         The difference from GovernanceChainRobotKeeper is that automation is only
 *         performed when the network gas price in within the maximum configured range.
 */
contract GasCappedGovernanceChainRobotKeeper is GasCappedRobotBase, GovernanceChainRobotKeeper {
  /**
   * @param governance address of the governance contract.
   * @param gasPriceOracle address of the gas price oracle contract.
   */
  constructor(
    address governance,
    address gasPriceOracle
  ) GovernanceChainRobotKeeper(governance) GasCappedRobotBase(gasPriceOracle) {}

  /**
   * @inheritdoc AutomationCompatibleInterface
   * @dev run off-chain, checks if payload should be executed
   *      also checks that the gas price of the network in within range to perform actions
   */
  function checkUpkeep(bytes memory) public view override returns (bool, bytes memory) {
    if (!isGasPriceInRange()) return (false, '');

    return super.checkUpkeep('');
  }
}
