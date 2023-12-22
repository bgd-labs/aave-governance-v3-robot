// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IExecutionChainRobotKeeper
 * @author BGD Labs
 * @notice Defines the interface for the contract to automate actions for the payloads controller on execution chain.
 **/
interface IExecutionChainRobotKeeper {
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
   * @notice method called by owner to disable/enabled automation on a specific payloadId.
   * @param payloadId payloadId for which we need to disable/enable automation.
   */
  function toggleDisableAutomationById(uint256 payloadId) external;

  /**
   * @notice method that is simulated by the gelato nodes to see if any work actually
   * needs to be performed.
   * @return upkeepNeeded boolean to indicate whether the gelato node should call
   * performUpkeep or not.
   * @return performData encoded bytes that the gelato node should call performUpkeep with, if
   * action is needed.
   */
  function checkUpkeep() external view returns (bool, bytes memory);

  /**
   * @notice method that is actually executed by the gelato nodes.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @param performData is the encoded data which was passed back from the checkUpkeep
   * call.
   */
  function performUpkeep(bytes calldata performData) external;

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
}
