// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {GasCappedGovernanceChainRobotKeeper} from '../src/contracts/gasprice-capped-robots/GasCappedGovernanceChainRobotKeeper.sol';
import {GovernanceChainRobotKeeperTest, IGovernancePowerStrategy} from './GovernanceChainRobotKeeper.t.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {MockAggregator} from 'chainlink/src/v0.8/mocks/MockAggregator.sol';
import {IGovernanceCore} from 'aave-governance-v3/tests/GovernanceCore.t.sol';

contract GasCappedGovernanceChainRobotKeeperTest is GovernanceChainRobotKeeperTest {
  address public constant VOTING_PORTAL_ETH_ETH = 0x9b24C168d6A76b5459B1d47071a54962a4df36c3;
  address public constant CHAINLINK_FAST_GAS_FEED = 0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C;

  MockAggregator public chainLinkFastGasFeed;

  event MaxGasPriceSet(uint256 indexed maxGasPrice);

  function setUp() public override {
    vm.createSelectFork('mainnet', 19609260); // Apr-8-2024

    CROSS_CHAIN_CONTROLLER = GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER;
    POWER_STRATEGY = address(GovernanceV3Ethereum.GOVERNANCE_POWER_STRATEGY);
    VOTING_PORTAL = VOTING_PORTAL_ETH_ETH;

    governance = IGovernanceCore(address(GovernanceV3Ethereum.GOVERNANCE));
    chainLinkFastGasFeed = MockAggregator(CHAINLINK_FAST_GAS_FEED);

    vm.startPrank(GUARDIAN);
    robotKeeper = new GasCappedGovernanceChainRobotKeeper(address(governance), address(chainLinkFastGasFeed));

    GasCappedGovernanceChainRobotKeeper(address(robotKeeper)).setMaxGasPrice(
      uint256(chainLinkFastGasFeed.latestAnswer())
    );
    vm.stopPrank();
  }

  function test_setMaxGasPrice(uint256 newMaxGasPrice) public {
    vm.expectEmit();
    emit MaxGasPriceSet(newMaxGasPrice);

    vm.startPrank(GUARDIAN);
    GasCappedGovernanceChainRobotKeeper(address(robotKeeper)).setMaxGasPrice(newMaxGasPrice);
    vm.stopPrank();

    assertEq(
      GasCappedGovernanceChainRobotKeeper(address(robotKeeper)).getMaxGasPrice(),
      newMaxGasPrice
    );

    vm.expectRevert('Ownable: caller is not the owner');
    vm.startPrank(address(5));
    GasCappedGovernanceChainRobotKeeper(address(robotKeeper)).setMaxGasPrice(newMaxGasPrice);
    vm.stopPrank();
  }

  function test_isGasPriceInRange() public {
    assertEq(GasCappedGovernanceChainRobotKeeper(address(robotKeeper)).isGasPriceInRange(), true);

    vm.startPrank(GUARDIAN);
    GasCappedGovernanceChainRobotKeeper(address(robotKeeper)).setMaxGasPrice(
      uint256(chainLinkFastGasFeed.latestAnswer()) - 1
    );
    vm.stopPrank();

    assertEq(GasCappedGovernanceChainRobotKeeper(address(robotKeeper)).isGasPriceInRange(), false);
  }

}
