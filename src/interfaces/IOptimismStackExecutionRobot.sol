// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOvmGasPriceOracle} from '../interfaces/IOvmGasPriceOracle.sol';

interface IOptimismStackExecutionRobot {
  function setMaxWeightedGasPriceL1Execution(uint256 maxWeightedGasPriceL1Execution) external;

  function getMaxWeightedGasPriceL1Execution() external view returns (uint256);

  function OVM_GAS_PRICE_ORACLE() external view returns (IOvmGasPriceOracle);
}
