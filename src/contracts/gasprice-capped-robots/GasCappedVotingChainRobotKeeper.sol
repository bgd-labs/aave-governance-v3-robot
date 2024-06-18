// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {VotingChainRobotKeeper} from '../VotingChainRobotKeeper.sol';
import {AutomationCompatibleInterface} from 'chainlink/src/v0.8/interfaces/automation/AutomationCompatibleInterface.sol';
import {GasCappedRobotBase} from './GasCappedRobotBase.sol';

/**
 * @title GasCappedVotingChainRobotKeeper
 * @author BGD Labs
 * @notice Contract to perform automation on voting machine and data warehouse contract for goveranance v3.
 *         The difference from VotingChainRobotKeeper is that automation is only
 *         performed when the network gas price in within the maximum configured range.
 */
contract GasCappedVotingChainRobotKeeper is GasCappedRobotBase, VotingChainRobotKeeper {
  /**
   * @param votingMachine address of the voting machine contract.
   * @param rootsConsumer address of the roots consumer contract to registers the roots.
   * @param gasPriceOracle address of the gas price oracle contract.
   */
  constructor(
    address votingMachine,
    address rootsConsumer,
    address gasPriceOracle
  ) VotingChainRobotKeeper(votingMachine, rootsConsumer) GasCappedRobotBase(gasPriceOracle) {}

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
