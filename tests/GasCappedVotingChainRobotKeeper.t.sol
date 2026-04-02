// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {GasCappedVotingChainRobotKeeper} from '../src/contracts/gasprice-capped-robots/GasCappedVotingChainRobotKeeper.sol';
import {RootsConsumer} from '../src/contracts/RootsConsumer.sol';
import {LinkTokenInterface} from 'chainlink/src/v0.8/ChainlinkClient.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {MockAggregator} from 'chainlink/src/v0.8/mocks/MockAggregator.sol';
import {IBaseReceiverPortal} from 'aave-address-book/governance-v3/IBaseReceiverPortal.sol';
import {IVotingPortal} from 'aave-address-book/governance-v3/IVotingPortal.sol';
import {VotingChainRobotKeeperTest, DataWarehouse, IDataWarehouse, VotingStrategy, VotingMachine, IVotingStrategy} from './VotingChainRobotKeeper.t.sol';

contract GasCappedVotingChainRobotKeeperTest is VotingChainRobotKeeperTest {
  address public constant DATA_WAREHOUSE = 0x1699FE9CaDC8a0b6c93E06B62Ab4592a0fFEcF61;
  address public constant VOTING_STRATEGY = 0x5642A5A5Ec284B4145563aBF319620204aCCA7f4;
  address public constant VOTING_MACHINE = 0x617332a777780F546261247F621051d0b98975Eb;
  address public constant L1_VOTING_PORTAL = 0xf23f7De3AC42F22eBDA17e64DC4f51FB66b8E21f;
  address public constant CHAINLINK_FAST_GAS_FEED = 0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C;

  MockAggregator public chainLinkFastGasFeed;

  event MaxGasPriceSet(uint256 indexed maxGasPrice);

  function setUp() public override {
    vm.createSelectFork('mainnet', 19609260); // Apr-8-2024

    rootsWarehouse = DataWarehouse(DATA_WAREHOUSE);
    votingStrategy = VotingStrategy(VOTING_STRATEGY);
    votingMachine = VotingMachine(VOTING_MACHINE);

    vm.startPrank(GUARDIAN);
    rootsConsumer = new RootsConsumer(
      LINK_TOKEN,
      address(12),
      address(5),
      'job id of the operator',
      0,
      address(123),
      ''
    );

    chainLinkFastGasFeed = MockAggregator(CHAINLINK_FAST_GAS_FEED);
    robotKeeper = new GasCappedVotingChainRobotKeeper(address(votingMachine), address(rootsConsumer), address(chainLinkFastGasFeed));
    GasCappedVotingChainRobotKeeper(address(robotKeeper)).setMaxGasPrice(
      uint256(chainLinkFastGasFeed.latestAnswer())
    );
    rootsConsumer.setRobotKeeper(address(robotKeeper));
    vm.stopPrank();
  }

  function test_setMaxGasPrice(uint256 newMaxGasPrice) public {
    vm.expectEmit();
    emit MaxGasPriceSet(newMaxGasPrice);

    vm.startPrank(GUARDIAN);
    GasCappedVotingChainRobotKeeper(address(robotKeeper)).setMaxGasPrice(newMaxGasPrice);
    vm.stopPrank();

    assertEq(
      GasCappedVotingChainRobotKeeper(address(robotKeeper)).getMaxGasPrice(),
      newMaxGasPrice
    );

    vm.expectRevert('Ownable: caller is not the owner');
    vm.startPrank(address(5));
    GasCappedVotingChainRobotKeeper(address(robotKeeper)).setMaxGasPrice(newMaxGasPrice);
    vm.stopPrank();
  }

  function test_isGasPriceInRange() public {
    assertEq(GasCappedVotingChainRobotKeeper(address(robotKeeper)).isGasPriceInRange(), true);

    vm.startPrank(GUARDIAN);
    GasCappedVotingChainRobotKeeper(address(robotKeeper)).setMaxGasPrice(
      uint256(chainLinkFastGasFeed.latestAnswer()) - 1
    );
    vm.stopPrank();

    assertEq(GasCappedVotingChainRobotKeeper(address(robotKeeper)).isGasPriceInRange(), false);
  }

  function test_robotExecutionOnlyWhenGasPriceInRange() public {
    uint256 proposalId = 105;
    uint24 votingDuration = uint24(62341);
    uint256 currentGasPrice = uint256(chainLinkFastGasFeed.latestAnswer());

    _readyProposalForCreateVote(proposalId, votingDuration, BLOCK_HASH);

    vm.startPrank(GUARDIAN);
    GasCappedVotingChainRobotKeeper(address(robotKeeper)).setMaxGasPrice(currentGasPrice - 1);
    vm.stopPrank();

    // configured gasPrice is less than the current gasPrice so robot does not run
    bool didRobotRun = _checkAndPerformUpKeep(robotKeeper);
    assertEq(didRobotRun, false);

    vm.startPrank(GUARDIAN);
    GasCappedVotingChainRobotKeeper(address(robotKeeper)).setMaxGasPrice(currentGasPrice);
    vm.stopPrank();

    didRobotRun = _checkAndPerformUpKeep(robotKeeper);
    assertEq(didRobotRun, true);
  }

  function _createVote(uint256 proposalId, uint24 votingDuration, bytes32 blockHash) internal override {
    vm.mockCall(
      address(votingStrategy),
      abi.encodeWithSelector(IVotingStrategy.hasRequiredRoots.selector, blockHash),
      abi.encode()
    );
    vm.mockCall(
      address(rootsWarehouse),
      abi.encodeWithSelector(IDataWarehouse.getStorageRoots.selector, GOVERNANCE, blockHash),
      abi.encode(keccak256(abi.encode('test')))
    );
    vm.startPrank(GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER);
    bytes memory message = abi.encode(proposalId, blockHash, votingDuration);

    IBaseReceiverPortal(address(votingMachine)).receiveCrossChainMessage(
      L1_VOTING_PORTAL,
      1,
      abi.encode(IVotingPortal.MessageType.Proposal, message)
    );
    vm.stopPrank();
    vm.clearMockedCalls();
  }

  function _readyProposalForRootsSubmit(uint256 proposalId, bytes32 blockHash) internal override {
    vm.startPrank(GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER);
    bytes memory message = abi.encode(proposalId, blockHash, 6000);

    IBaseReceiverPortal(address(votingMachine)).receiveCrossChainMessage(
      L1_VOTING_PORTAL,
      1,
      abi.encode(IVotingPortal.MessageType.Proposal, message)
    );
    vm.stopPrank();

    vm.mockCall(
      LINK_TOKEN,
      abi.encodeWithSelector(LinkTokenInterface.transferAndCall.selector),
      abi.encode(true)
    );
  }

  function _readyProposalForCreateVote(uint256 proposalId, uint24 votingDuration, bytes32 blockHash) internal override {
    vm.startPrank(GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER);
    bytes memory message = abi.encode(proposalId, blockHash, votingDuration);

    IBaseReceiverPortal(address(votingMachine)).receiveCrossChainMessage(
      L1_VOTING_PORTAL,
      1,
      abi.encode(IVotingPortal.MessageType.Proposal, message)
    );
    vm.stopPrank();

    vm.mockCall(
      address(votingStrategy),
      abi.encodeWithSelector(IVotingStrategy.hasRequiredRoots.selector, blockHash),
      abi.encode()
    );
    vm.mockCall(
      address(rootsWarehouse),
      abi.encodeWithSelector(IDataWarehouse.getStorageRoots.selector, GOVERNANCE, blockHash),
      abi.encode(keccak256(abi.encode('test')))
    );
  }
}
