// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IAaveCLRobotOperator} from '../interfaces/IAaveCLRobotOperator.sol';
import {IKeeperRegistrar} from '../interfaces/IKeeperRegistrar.sol';
import {IKeeperRegistry} from '../interfaces/IKeeperRegistry.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {OwnableWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';

/**
 * @title AaveCLRobotOperator
 * @author BGD Labs
 * @dev Operator contract to perform admin actions on the automation keepers.
 *      The contract can register keepers, cancel it, pause it, withdraw excess link,
 *      refill the keeper, configure the keeper.
 */
contract AaveCLRobotOperator is OwnableWithGuardian, IAaveCLRobotOperator {
  using SafeERC20 for IERC20;

  /// @inheritdoc IAaveCLRobotOperator
  address public immutable LINK_TOKEN;

  /// @inheritdoc IAaveCLRobotOperator
  address public immutable KEEPER_REGISTRY;

  /// @inheritdoc IAaveCLRobotOperator
  address public immutable KEEPER_REGISTRAR;

  address internal _linkWithdrawAddress;

  mapping(uint256 id => KeeperInfo) internal _keepers;

  /**
   * @param keeperRegistry address of the chainlink registry.
   * @param keeperRegistrar address of the chainlink registrar.
   * @param linkWithdrawAddress withdrawal address to send the exccess link after cancelling the keeper.
   * @param operatorOwner address to set as the owner of the operator contract.
   */
  constructor(
    address keeperRegistry,
    address keeperRegistrar,
    address linkWithdrawAddress,
    address operatorOwner
  ) {
    KEEPER_REGISTRY = keeperRegistry;
    KEEPER_REGISTRAR = keeperRegistrar;
    LINK_TOKEN = IKeeperRegistry(KEEPER_REGISTRY).getLinkAddress();
    _linkWithdrawAddress = linkWithdrawAddress;
    _transferOwnership(operatorOwner);
  }

  /// @notice In order to fund the keeper we need to approve the Link token amount to this contract
  /// @inheritdoc IAaveCLRobotOperator
  function register(
    string memory name,
    address upkeepContract,
    uint32 gasLimit,
    uint96 amountToFund,
    uint8 triggerType,
    bytes memory triggerConfig
  ) external onlyOwner returns (uint256) {
    IERC20(LINK_TOKEN).safeTransferFrom(msg.sender, address(this), amountToFund);

    IKeeperRegistrar.RegistrationParams memory params = IKeeperRegistrar.RegistrationParams({
      name: name, // name of the keeper to register
      encryptedEmail: '', // encryptedEmail to send alerts to, unused
      upkeepContract: upkeepContract, // address of the upkeep contract
      gasLimit: gasLimit, // max gasLimit which can be used for an performUpkeep action
      adminAddress: address(this), // admin of the keeper is set to this address of AaveCLRobotOperator
      triggerType: triggerType, // 0 for conditional type keeper, 1 for log type
      checkData: '', // checkData of the keeper which get passed to the checkUpkeep, unused
      triggerConfig: triggerConfig, // configuration for log type keeper, else unused
      offchainConfig: '', // unused
      amount: amountToFund // amount of link to fund the keeper with
    });

    IERC20(LINK_TOKEN).forceApprove(KEEPER_REGISTRAR, amountToFund);
    uint256 id = IKeeperRegistrar(KEEPER_REGISTRAR).registerUpkeep(params);

    if (id != 0) {
      _keepers[id].upkeep = upkeepContract;
      _keepers[id].name = name;
      emit KeeperRegistered(id, upkeepContract, amountToFund);

      return id;
    } else {
      revert('AUTO_APPROVE_DISABLED');
    }
  }

  /// @inheritdoc IAaveCLRobotOperator
  function cancel(uint256 id) external onlyOwner {
    IKeeperRegistry(KEEPER_REGISTRY).cancelUpkeep(id);
    emit KeeperCancelled(id, _keepers[id].upkeep);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function withdrawLink(uint256 id) external {
    IKeeperRegistry(KEEPER_REGISTRY).withdrawFunds(id, _linkWithdrawAddress);
    emit LinkWithdrawn(id, _keepers[id].upkeep, _linkWithdrawAddress);
  }

  /// @notice In order to refill the keeper we need to approve the Link token amount to this contract
  /// @inheritdoc IAaveCLRobotOperator
  function refillKeeper(uint256 id, uint96 amount) external {
    IERC20(LINK_TOKEN).safeTransferFrom(msg.sender, address(this), amount);
    IERC20(LINK_TOKEN).forceApprove(KEEPER_REGISTRY, amount);
    IKeeperRegistry(KEEPER_REGISTRY).addFunds(id, amount);
    emit KeeperRefilled(id, msg.sender, amount);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function pause(uint256 id) external onlyOwnerOrGuardian {
    IKeeperRegistry(KEEPER_REGISTRY).pauseUpkeep(id);
    emit KeeperPaused(id);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function unpause(uint256 id) external onlyOwnerOrGuardian {
    IKeeperRegistry(KEEPER_REGISTRY).unpauseUpkeep(id);
    emit KeeperUnpaused(id);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function setGasLimit(uint256 id, uint32 gasLimit) external onlyOwnerOrGuardian {
    IKeeperRegistry(KEEPER_REGISTRY).setUpkeepGasLimit(id, gasLimit);
    emit GasLimitSet(id, _keepers[id].upkeep, gasLimit);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function setTriggerConfig(uint256 id, bytes calldata triggerConfig) external onlyOwnerOrGuardian {
    IKeeperRegistry(KEEPER_REGISTRY).setUpkeepTriggerConfig(id, triggerConfig);
    emit TriggerConfigSet(id);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function setWithdrawAddress(address withdrawAddress) external onlyOwner {
    _linkWithdrawAddress = withdrawAddress;
    emit WithdrawAddressSet(withdrawAddress);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function getWithdrawAddress() external view returns (address) {
    return _linkWithdrawAddress;
  }

  /// @inheritdoc IAaveCLRobotOperator
  function getKeeperInfo(uint256 id) external view returns (KeeperInfo memory) {
    return _keepers[id];
  }

  /// @inheritdoc IAaveCLRobotOperator
  function isPaused(uint256 id) external view returns (bool) {
    return IKeeperRegistry(KEEPER_REGISTRY).getUpkeep(id).paused;
  }
}
