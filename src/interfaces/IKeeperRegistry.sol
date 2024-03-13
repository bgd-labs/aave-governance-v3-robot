// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IKeeperRegistry {
  struct OnchainConfig {
    uint32 paymentPremiumPPB;
    uint32 flatFeeMicroLink;
    uint32 checkGasLimit;
    uint24 stalenessSeconds;
    uint16 gasCeilingMultiplier;
    uint96 minUpkeepSpend;
    uint32 maxPerformGas;
    uint32 maxCheckDataSize;
    uint32 maxPerformDataSize;
    uint32 maxRevertDataSize;
    uint256 fallbackGasPrice;
    uint256 fallbackLinkPrice;
    address transcoder;
    address[] registrars;
    address upkeepPrivilegeManager;
  }

  struct State {
    uint32 nonce;
    uint96 ownerLinkBalance;
    uint256 expectedLinkBalance;
    uint96 totalPremium;
    uint256 numUpkeeps;
    uint32 configCount;
    uint32 latestConfigBlockNumber;
    bytes32 latestConfigDigest;
    uint32 latestEpoch;
    bool paused;
  }

  struct UpkeepInfo {
    address target;
    uint32 performGas;
    bytes checkData;
    uint96 balance;
    address admin;
    uint64 maxValidBlocknumber;
    uint32 lastPerformedBlockNumber;
    uint96 amountSpent;
    bool paused;
    bytes offchainConfig;
  }

  function addFunds(uint256 id, uint96 amount) external;

  function cancelUpkeep(uint256 id) external;

  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    uint8 triggerType,
    bytes memory checkData,
    bytes memory triggerConfig,
    bytes memory offchainConfig
  ) external returns (uint256 id);

  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes memory checkData,
    bytes memory offchainConfig
  ) external returns (uint256 id);

  function setUpkeepTriggerConfig(uint256 id, bytes memory triggerConfig) external;

  function getBalance(uint256 id) external view returns (uint96 balance);

  function getForwarder(uint256 upkeepID) external view returns (address);

  function getLinkAddress() external view returns (address);

  function getState()
    external
    view
    returns (
      State memory state,
      OnchainConfig memory config,
      address[] memory signers,
      address[] memory transmitters,
      uint8 f
    );

  function getTriggerType(uint256 upkeepId) external pure returns (uint8);

  function getUpkeep(uint256 id) external view returns (UpkeepInfo memory upkeepInfo);

  function getUpkeepTriggerConfig(uint256 upkeepId) external view returns (bytes memory);

  function pauseUpkeep(uint256 id) external;

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

  function unpauseUpkeep(uint256 id) external;

  function upkeepVersion() external pure returns (uint8);

  function withdrawFunds(uint256 id, address to) external;

  function migrateUpkeeps(uint256[] calldata upkeepIDs, address destination) external;

  function transferUpkeepAdmin(uint256 id, address proposed) external;

  function acceptUpkeepAdmin(uint256 id) external;
}
