// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {IAaveCLRobotOperator} from '../interfaces/IAaveCLRobotOperator.sol';
import {IInitializableRobotOperator} from '../interfaces/IInitializableRobotOperator.sol';
import {IKeeperRegistrar} from '../interfaces/IKeeperRegistrar.sol';
import {IKeeperRegistry} from '../interfaces/IKeeperRegistry.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {OwnableWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';
import {Initializable} from 'solidity-utils/contracts/transparent-proxy/Initializable.sol';

/**
 * @title AaveCLRobotOperator
 * @author BGD Labs
 * @dev Operator contract to perform admin actions on the automation keepers.
 *      The contract can register keepers, cancel it, pause it, withdraw excess link,
 *      refill the keeper, configure the keeper.
 */
contract AaveCLRobotOperator is OwnableWithGuardian, Initializable, IAaveCLRobotOperator {
  using SafeERC20 for IERC20;

  uint256[] internal _keepersList;
  mapping(uint256 id => KeeperInfo) internal _keepersInfo;

  address internal _keeperRegistry;
  address internal _keeperRegistrar;
  address internal _linkToken;
  address internal _linkWithdrawAddress;

  /// @inheritdoc IInitializableRobotOperator
  function initialize(
    address keeperRegistry,
    address keeperRegistrar,
    address linkWithdrawAddress,
    address operatorOwner
  ) external initializer {
    _keeperRegistry = keeperRegistry;
    _keeperRegistrar = keeperRegistrar;
    _linkWithdrawAddress = linkWithdrawAddress;
    _transferOwnership(operatorOwner);
    _linkToken = IKeeperRegistry(_keeperRegistry).getLinkAddress();
    emit Initialized(keeperRegistry, keeperRegistrar, linkWithdrawAddress, operatorOwner);
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
    IERC20(_linkToken).safeTransferFrom(msg.sender, address(this), amountToFund);

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

    IERC20(_linkToken).forceApprove(_keeperRegistrar, amountToFund);
    uint256 id = IKeeperRegistrar(_keeperRegistrar).registerUpkeep(params);

    if (id != 0) {
      _keepersInfo[id].upkeep = upkeepContract;
      _keepersInfo[id].name = name;
      _keepersList.push(id);

      emit KeeperRegistered(id, upkeepContract, amountToFund);

      return id;
    } else {
      revert('AUTO_APPROVE_DISABLED');
    }
  }

  /// @inheritdoc IAaveCLRobotOperator
  function cancel(uint256 id) external onlyOwner {
    IKeeperRegistry(_keeperRegistry).cancelUpkeep(id);

    // remove the keeper from the keepers list
    for (uint256 index = 0; index < _keepersList.length; index++) {
      if (_keepersList[index] == id) {
        _keepersList[index] = _keepersList[_keepersList.length - 1];
        _keepersList.pop();
        break;
      }
    }

    emit KeeperCancelled(id, _keepersInfo[id].upkeep);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function withdrawLink(uint256 id) external {
    IKeeperRegistry(_keeperRegistry).withdrawFunds(id, _linkWithdrawAddress);
    emit LinkWithdrawn(id, _keepersInfo[id].upkeep, _linkWithdrawAddress);
  }

  /// @notice In order to refill the keeper we need to approve the Link token amount to this contract
  /// @inheritdoc IAaveCLRobotOperator
  function refillKeeper(uint256 id, uint96 amount) external {
    IERC20(_linkToken).safeTransferFrom(msg.sender, address(this), amount);
    IERC20(_linkToken).forceApprove(_keeperRegistry, amount);
    IKeeperRegistry(_keeperRegistry).addFunds(id, amount);
    emit KeeperRefilled(id, msg.sender, amount);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function pause(uint256 id) external onlyOwnerOrGuardian {
    IKeeperRegistry(_keeperRegistry).pauseUpkeep(id);
    emit KeeperPaused(id);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function unpause(uint256 id) external onlyOwnerOrGuardian {
    IKeeperRegistry(_keeperRegistry).unpauseUpkeep(id);
    emit KeeperUnpaused(id);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function migrate(address newRegistry, address newRegistrar) external onlyOwner {
    IKeeperRegistry(_keeperRegistry).migrateUpkeeps(_keepersList, newRegistry);

    setRegistry(newRegistry);
    setRegistrar(newRegistrar);
    emit KeepersMigrated(_keepersList, newRegistry, newRegistrar);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function setGasLimit(uint256 id, uint32 gasLimit) external onlyOwnerOrGuardian {
    IKeeperRegistry(_keeperRegistry).setUpkeepGasLimit(id, gasLimit);
    emit GasLimitSet(id, _keepersInfo[id].upkeep, gasLimit);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function setTriggerConfig(uint256 id, bytes calldata triggerConfig) external onlyOwnerOrGuardian {
    IKeeperRegistry(_keeperRegistry).setUpkeepTriggerConfig(id, triggerConfig);
    emit TriggerConfigSet(id);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function setWithdrawAddress(address withdrawAddress) external onlyOwner {
    _linkWithdrawAddress = withdrawAddress;
    emit WithdrawAddressSet(withdrawAddress);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function setRegistry(address newRegistry) public onlyOwner {
    _keeperRegistry = newRegistry;
    emit KeeperRegistrySet(newRegistry);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function setRegistrar(address newRegistrar) public onlyOwner {
    _keeperRegistrar = newRegistrar;
    emit KeeperRegistrarSet(newRegistrar);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function getWithdrawAddress() external view returns (address) {
    return _linkWithdrawAddress;
  }

  /// @inheritdoc IAaveCLRobotOperator
  function getKeeperInfo(uint256 id) external view returns (KeeperInfo memory) {
    return _keepersInfo[id];
  }

  /// @inheritdoc IAaveCLRobotOperator
  function isPaused(uint256 id) external view returns (bool) {
    return IKeeperRegistry(_keeperRegistry).getUpkeep(id).paused;
  }

  /// @inheritdoc IAaveCLRobotOperator
  function getRegistry() public view returns (address) {
    return _keeperRegistry;
  }

  /// @inheritdoc IAaveCLRobotOperator
  function getRegistrar() public view returns (address) {
    return _keeperRegistrar;
  }

  /// @inheritdoc IAaveCLRobotOperator
  function getKeepersList() public view returns (uint256[] memory) {
    return _keepersList;
  }

  /// @inheritdoc IAaveCLRobotOperator
  function getLinkToken() external view returns (address) {
    return _linkToken;
  }
}
