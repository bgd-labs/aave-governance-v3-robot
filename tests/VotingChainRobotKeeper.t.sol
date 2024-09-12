// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {VotingChainRobotKeeper} from '../src/contracts/VotingChainRobotKeeper.sol';
import {RootsConsumer, IRootsConsumer} from '../src/contracts/RootsConsumer.sol';
import {LinkTokenInterface} from 'chainlink/src/v0.8/ChainlinkClient.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import 'aave-governance-v3/tests/voting/votingMachineWithProofs.t.sol';

contract VotingChainRobotKeeperTest is Test {
  VotingChainRobotKeeper robotKeeper;
  IRootsConsumer rootsConsumer;

  IDataWarehouse rootsWarehouse;
  IVotingStrategy votingStrategy;
  IVotingMachineWithProofs votingMachine;

  bytes32 public constant BLOCK_HASH = 0x17fb51754007ba63313584d93eaf01a6c7b50fb6975c46c600489ed78dc5e8ff;
  address public constant GUARDIAN = address(1);
  address public constant LINK_TOKEN = address(7979);
  address public constant GOVERNANCE = address(GovernanceV3Ethereum.GOVERNANCE);

  event ActionSucceeded(uint256 indexed id, ProposalAction indexed action);

  enum ProposalAction {
    PerformSubmitRoots,
    PerformCreateVote,
    PerformCloseAndSendVote
  }

  function setUp() public virtual {
    rootsWarehouse = new DataWarehouse();
    votingStrategy = new VotingStrategy(address(rootsWarehouse));
    votingMachine = new VotingMachine(votingStrategy, GOVERNANCE);

    rootsConsumer = new RootsConsumer(
      LINK_TOKEN,
      address(12),
      address(5),
      'job id of the operator',
      0,
      address(123),
      ''
    );
    vm.prank(GUARDIAN);
    robotKeeper = new VotingChainRobotKeeper(address(votingMachine), address(rootsConsumer));

    rootsConsumer.setRobotKeeper(address(robotKeeper));
  }

  function testCreateVote() public {
    uint256 proposalId = 10;
    uint24 votingDuration = uint24(62341);
    _readyProposalForCreateVote(proposalId, votingDuration, BLOCK_HASH);

    assertEq(
      uint256(votingMachine.getProposalState(proposalId)),
      uint256(IVotingMachineWithProofs.ProposalState.NotCreated)
    );

    vm.expectEmit();
    emit ActionSucceeded(proposalId, ProposalAction.PerformCreateVote);

    _checkAndPerformUpKeep(robotKeeper);

    assertEq(
      uint256(votingMachine.getProposalState(proposalId)),
      uint256(IVotingMachineWithProofs.ProposalState.Active)
    );
  }

  function testCloseAndSendVote() public {
    uint256 proposalId = 5;
    uint24 votingDuration = 600;

    _createVote(proposalId, votingDuration, BLOCK_HASH);
    skip(votingDuration + 1);

    assertEq(
      uint8(votingMachine.getProposalState(proposalId)),
      uint8(IVotingMachineWithProofs.ProposalState.Finished)
    );

    vm.expectEmit();
    emit ActionSucceeded(proposalId, ProposalAction.PerformCloseAndSendVote);

    _checkAndPerformUpKeep(robotKeeper);

    assertEq(
      uint8(votingMachine.getProposalState(proposalId)),
      uint8(IVotingMachineWithProofs.ProposalState.SentToGovernance)
    );
  }

  function testSubmitRoots() public {
    uint256 proposalId = 20;
    _readyProposalForRootsSubmit(20, BLOCK_HASH);

    vm.expectEmit();
    emit ActionSucceeded(proposalId, ProposalAction.PerformSubmitRoots);

    _checkAndPerformUpKeep(robotKeeper);
  }

  function testMultipleActions() public {
    // Proposal for which roots can be submitted
    uint256 proposalId1 = 20;
    bytes32 blockHash = 0x12fb44224007ba63313584d93eaf01a6c7b50fb6975c22c500489ed78dc4e800;
    _readyProposalForRootsSubmit(proposalId1, blockHash);

    // Proposal for which createVote action could be performed
    uint256 proposalId2 = 10;
    _readyProposalForCreateVote(proposalId2, 500, BLOCK_HASH);

    assertEq(
      uint256(votingMachine.getProposalState(proposalId1)),
      uint256(IVotingMachineWithProofs.ProposalState.NotCreated)
    );
    assertEq(
      uint256(votingMachine.getProposalState(proposalId2)),
      uint256(IVotingMachineWithProofs.ProposalState.NotCreated)
    );

    vm.expectEmit();
    emit ActionSucceeded(proposalId1, ProposalAction.PerformSubmitRoots);

    vm.expectEmit();
    emit ActionSucceeded(proposalId2, ProposalAction.PerformCreateVote);

    _checkAndPerformUpKeep(robotKeeper);

    assertEq(
      uint256(votingMachine.getProposalState(proposalId2)),
      uint256(IVotingMachineWithProofs.ProposalState.Active)
    );
  }

  function testDisableAutomation() public {
    // create proposal which for which close and send vote action can be performed
    uint256 proposalId = 5;
    uint24 votingDuration = 600;

    _createVote(proposalId, votingDuration, BLOCK_HASH);
    skip(votingDuration + 1);

    assertEq(
      uint8(votingMachine.getProposalState(proposalId)),
      uint8(IVotingMachineWithProofs.ProposalState.Finished)
    );

    vm.prank(GUARDIAN);
    robotKeeper.toggleDisableAutomationById(5);

    (bool shouldRunKeeper, ) = robotKeeper.checkUpkeep('');
    assertEq(shouldRunKeeper, false);

    vm.prank(GUARDIAN);
    robotKeeper.toggleDisableAutomationById(5);

    (shouldRunKeeper, ) = robotKeeper.checkUpkeep('');
    assertEq(shouldRunKeeper, true);
  }

  function _checkAndPerformUpKeep(VotingChainRobotKeeper votingChainRobotKeeper) internal returns (bool) {
    (bool shouldRunKeeper, bytes memory performData) = votingChainRobotKeeper.checkUpkeep('');
    if (shouldRunKeeper) {
      votingChainRobotKeeper.performUpkeep(performData);
    }
    return shouldRunKeeper;
  }

  function _createVote(uint256 proposalId, uint24 votingDuration, bytes32 blockHash) internal virtual {
    _readyProposalForCreateVote(proposalId, votingDuration, blockHash);

    votingMachine.startProposalVote(proposalId);
    vm.clearMockedCalls();
  }

  function _readyProposalForRootsSubmit(uint256 proposalId, bytes32 blockHash) internal virtual {
    uint256[] memory proposalIds = new uint256[](1);
    proposalIds[0] = proposalId;

    VotingMachine(address(votingMachine)).setProposalsVoteConfiguration(
      proposalId,
      blockHash,
      600
    );
    VotingMachine(address(votingMachine)).setProposalsVoteConfigurationIds(proposalIds);
    vm.mockCall(
      LINK_TOKEN,
      abi.encodeWithSelector(LinkTokenInterface.transferAndCall.selector),
      abi.encode(true)
    );
  }

  function _readyProposalForCreateVote(uint256 proposalId, uint24 votingDuration, bytes32 blockHash) internal virtual {
    uint256[] memory oldProposalIds = VotingMachine(address(votingMachine)).getProposalsVoteConfigurationIds(0, 100);
    uint256[] memory proposalIds = new uint256[](oldProposalIds.length + 1);

    for (uint i = 0; i < oldProposalIds.length; i++) proposalIds[i] = oldProposalIds[i];
    proposalIds[oldProposalIds.length] = proposalId;

    VotingMachine(address(votingMachine)).setProposalsVoteConfiguration(
      proposalId,
      blockHash,
      votingDuration
    );

    VotingMachine(address(votingMachine)).setProposalsVoteConfigurationIds(proposalIds);

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
