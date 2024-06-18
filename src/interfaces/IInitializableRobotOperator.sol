// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IInitializableRobotOperator
 * @author BGD Labs
 * @notice Interface for the initialize function on AaveCLRobotOperator
 **/
interface IInitializableRobotOperator {
  /**
   * @dev Emitted when a AaveCLRobotOperator is initialized
   * @param keeperRegistry address of the chainlink registry.
   * @param keeperRegistrar address of the chainlink registrar.
   * @param linkWithdrawAddress withdrawal address of the operator contract.
   * @param operatorOwner owner of the operator contract.
   * @param operatorGuardian guardian of the operator contract.
   **/
  event Initialized(
    address keeperRegistry,
    address keeperRegistrar,
    address linkWithdrawAddress,
    address operatorOwner,
    address operatorGuardian
  );

  /**
   * @dev Initializes the AaveCLRobotOperator
   * @param keeperRegistry address of the chainlink registry.
   * @param keeperRegistrar address of the chainlink registrar.
   * @param linkWithdrawAddress withdrawal address to send the exccess link after cancelling the keeper.
   * @param operatorOwner address to set as the owner of the operator contract.
   * @param operatorGuardian address to set as the guardian of the operator contract.
   */
  function initialize(
    address keeperRegistry,
    address keeperRegistrar,
    address linkWithdrawAddress,
    address operatorOwner,
    address operatorGuardian
  ) external;
}
