// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AutomationCompatibleInterface} from 'chainlink/src/v0.8/interfaces/automation/AutomationCompatibleInterface.sol';
import {AggregatorInterface} from 'aave-address-book/AaveV3.sol';

/**
 * @title IExecutionChainRobot
 * @author BGD Labs
 * @notice Defines the interface for the contract to automate actions for the payloads controller on execution chain.
 **/
interface IExecutionChainRobot is AutomationCompatibleInterface {
  /**
   * @notice Emitted when performUpkeep is called and an action is executed.
   * @param id payload id of successful action.
   */
  event ActionSucceeded(uint256 indexed id);

  /**
   * @notice method to check if a payloadId is disabled.
   * @param id - payloadId to check if disabled.
   * @return bool if payload is disabled or not.
   **/
  function isDisabled(uint40 id) external view returns (bool);

  /**
   * @notice method to check if the current gas prices is lesser than the configured maximum gas prices.
   * @return bool if the current network gasPrice is in range or not.
   **/
  function isGasPriceInRange() external view returns (bool);

  /**
   * @notice method called by the owner to set the maximum gas price beyond which actions won't be executed.
   * @param maxGasPrice the maximum gas price in wei of the current network to set.
   **/
  function setMaxGasPrice(uint256 maxGasPrice) external;

  /**
   * @notice method to get the maximum gas price configured beyond which actions won't be executed.
   * @return maxGasPrice the maximum gas price in wei of the current network.
   **/
  function getMaxGasPrice() external returns (uint256);

  /**
   * @notice method called by owner to disable/enabled automation on a specific payloadId.
   * @param payloadId payloadId for which we need to disable/enable automation.
   */
  function toggleDisableAutomationById(uint256 payloadId) external;

  /**
   * @notice method to get the address of the payloads controller contract.
   * @return payloads controller contract address.
   */
  function PAYLOADS_CONTROLLER() external view returns (address);

  /**
   * @notice method to get the maximum size of payloadIds list from which we shuffle from to select a single payload to execute.
   * @return max shuffle size.
   */
  function MAX_SHUFFLE_SIZE() external view returns (uint256);

  /**
   * @notice method to get maximum number of payloads to check before the latest proposal, if an action could be performed upon.
   * @return max number of skips.
   */
  function MAX_SKIP() external view returns (uint256);

  /**
   * @notice method to get the chainlink fast gas oracle contract.
   * @return chainlink fast gas oracle contract.
   */
  function CHAINLINK_FAST_GAS_ORACLE() external view returns (AggregatorInterface);
}
