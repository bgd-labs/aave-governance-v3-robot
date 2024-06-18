// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IGasPriceCappedRobot} from '../../interfaces/IGasPriceCappedRobot.sol';
import {AggregatorInterface} from 'aave-address-book/AaveV3.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';

/**
 * @title GasCappedRobotBase
 * @author BGD Labs
 * @notice Abstract contract to be inherited by robots to limit actions by configured gasPrice.
 */
abstract contract GasCappedRobotBase is Ownable, IGasPriceCappedRobot {
  /// @inheritdoc IGasPriceCappedRobot
  address public immutable GAS_PRICE_ORACLE;

  uint256 internal _maxGasPrice;

  /**
   * @param gasPriceOracle address of the gas price oracle contract.
   */
  constructor(address gasPriceOracle) {
    GAS_PRICE_ORACLE = gasPriceOracle;
  }

  /// @inheritdoc IGasPriceCappedRobot
  function setMaxGasPrice(uint256 maxGasPrice) external onlyOwner {
    _maxGasPrice = maxGasPrice;
    emit MaxGasPriceSet(maxGasPrice);
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
