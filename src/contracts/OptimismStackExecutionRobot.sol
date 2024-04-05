// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ExecutionChainRobot, IExecutionChainRobot} from './ExecutionChainRobot.sol';
import {IOvmGasPriceOracle} from '../interfaces/IOvmGasPriceOracle.sol';
import {AggregatorInterface} from 'aave-address-book/AaveV3.sol';
import {IOptimismStackExecutionRobot} from '../interfaces/IOptimismStackExecutionRobot.sol';

/**
 * @title OptimismStackExecutionRobot
 * @author BGD Labs
 */
contract OptimismStackExecutionRobot is ExecutionChainRobot, IOptimismStackExecutionRobot {
  /// @inheritdoc IOptimismStackExecutionRobot
  IOvmGasPriceOracle public immutable OVM_GAS_PRICE_ORACLE;

  uint256 internal _maxWeightedGasPriceL1Execution;

  /**
   * @param payloadsController address of the payloads controller contract.
   * @param chainlinkFastGasOracle address of the chainlink fast gas oracle contract.
   * @param ovmGasPriceOracle address of the ovm gas price contract.
   */
  constructor(
    address payloadsController,
    address chainlinkFastGasOracle,
    address ovmGasPriceOracle
  ) ExecutionChainRobot(payloadsController, chainlinkFastGasOracle) {
    OVM_GAS_PRICE_ORACLE = IOvmGasPriceOracle(ovmGasPriceOracle);
  }

  /// @inheritdoc IOptimismStackExecutionRobot
  function setMaxWeightedGasPriceL1Execution(uint256 maxWeightedGasPriceL1Execution) external onlyOwner {
    _maxWeightedGasPriceL1Execution = maxWeightedGasPriceL1Execution;
  }

  /// @inheritdoc IOptimismStackExecutionRobot
  function getMaxWeightedGasPriceL1Execution() external view returns (uint256) {
    return _maxWeightedGasPriceL1Execution;
  }

  /// @inheritdoc IExecutionChainRobot
  function isGasPriceInRange() public view override returns (bool) {
    // https://docs.optimism.io/stack/transactions/fees#ecotone
    // l1 gas price is calculated as: weighted_gas_price ~= (16 * base_fee_scalar * base_fee + blob_base_fee_scalar * blob_base_fee) / 10^scalar_decimal / 16
    // which can be also represented as: weighted_gas_price ~= getL1Fee(0x1) / getL1GasUsed(0x1)
    uint256 currentWeightedGasPriceL1Execution = OVM_GAS_PRICE_ORACLE.getL1Fee(new bytes(0x1)) / OVM_GAS_PRICE_ORACLE.getL1GasUsed(new bytes(0x1));

    if (uint256(CHAINLINK_FAST_GAS_ORACLE.latestAnswer()) > _maxGasPrice || currentWeightedGasPriceL1Execution > _maxWeightedGasPriceL1Execution) {
      return false;
    }
    return true;
  }
}
