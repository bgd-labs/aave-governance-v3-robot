// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ExecutionChainRobotKeeper} from '../ExecutionChainRobotKeeper.sol';
import {AutomationCompatibleInterface} from 'chainlink/src/v0.8/interfaces/automation/AutomationCompatibleInterface.sol';
import {IGasPriceCappedRobot} from '../../interfaces/IGasPriceCappedRobot.sol';
import {AggregatorInterface} from 'aave-address-book/AaveV3.sol';

/**
 * @title GasCappedExecutionChainRobotKeeper
 * @author BGD Labs
 * @notice Contract to perform automation on payloads controller.
 *         The difference from ExecutionChainRobot Keeper is that automation is only
 *         performed when network gas price in within the maximum configured range.
 */
contract GasCappedExecutionChainRobotKeeper is ExecutionChainRobotKeeper, IGasPriceCappedRobot {
  /// @inheritdoc IGasPriceCappedRobot
  address public immutable GAS_PRICE_ORACLE;

  uint256 internal _maxGasPrice;

  /**
   * @param payloadsController address of the payloads controller contract.
   * @param gasPriceOracle address of the gas price oracle contract.
   */
  constructor(address payloadsController, address gasPriceOracle) ExecutionChainRobotKeeper(payloadsController) {
    GAS_PRICE_ORACLE = gasPriceOracle;
  }

  /**
   * @inheritdoc AutomationCompatibleInterface
   * @dev run off-chain, checks if payload should be executed
   *      also checks that the gas price of the network in within range to perform actions
   */
  function checkUpkeep(bytes memory) public view override returns (bool, bytes memory) {
    if (!isGasPriceInRange()) return (false, '');

    return super.checkUpkeep('');
  }

  /// @inheritdoc IGasPriceCappedRobot
  function setMaxGasPrice(uint256 maxGasPrice) external onlyOwner {
    _maxGasPrice = maxGasPrice;
  }

  /// @inheritdoc IGasPriceCappedRobot
  function getMaxGasPrice() external view returns (uint256) {
    return _maxGasPrice;
  }

  /// @inheritdoc IGasPriceCappedRobot
  function isGasPriceInRange() public view virtual returns (bool) {
    if (uint256(AggregatorInterface(GAS_PRICE_ORACLE).latestAnswer()) > _maxGasPrice) {
      return false;
    }
    return true;
  }
}
