// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorInterface} from 'aave-address-book/AaveV3.sol';

/**
 * @title IGasPriceCappedRobot
 * @author BGD Labs
 * @notice Defines the interface for the gas price capped robot.
 **/
interface IGasPriceCappedRobot {
  /**
   * @notice Emitted when maxGasPrice has been set by the owner.
   * @param maxGasPrice new maximum gas price of the network set by the owner.
   */
  event MaxGasPriceSet(uint256 indexed maxGasPrice);

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
   * @notice method to get the network gas price oracle contract.
   * @return address of the network gas price oracle.
   */
  function GAS_PRICE_ORACLE() external view returns (address);
}
