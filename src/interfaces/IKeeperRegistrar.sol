// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKeeperRegistrar {
  struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    uint8 triggerType;
    bytes checkData;
    bytes triggerConfig;
    bytes offchainConfig;
    uint96 amount;
  }

  /**
   * DISABLED: No auto approvals, all new upkeeps should be approved manually.
   * ENABLED_SENDER_ALLOWLIST: Auto approvals for allowed senders subject to max allowed. Manual for rest.
   * ENABLED_ALL: Auto approvals for all new upkeeps subject to max allowed.
   */
  enum AutoApproveType {
    DISABLED,
    ENABLED_SENDER_ALLOWLIST,
    ENABLED_ALL
  }

  function setTriggerConfig(
    uint8 triggerType,
    AutoApproveType autoApproveType,
    uint32 autoApproveMaxAllowed
  ) external;

  function setAutoApproveAllowedSender(address senderAddress, bool allowed) external;

  function registerUpkeep(RegistrationParams calldata requestParams) external returns (uint256);
}
