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

  bytes32 constant BLOCK_HASH = 0x17fb51754007ba63313584d93eaf01a6c7b50fb6975c46c600489ed78dc5e8ff;
  address constant LINK_TOKEN = address(7979);
  address public constant GOVERNANCE = address(GovernanceV3Ethereum.GOVERNANCE);

  function setUp() public {
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

    robotKeeper = new VotingChainRobotKeeper(
      address(votingMachine),
      address(rootsConsumer)
    );
    rootsConsumer.setRobotKeeper(address(robotKeeper));
  }

  function testCreateVote() public {
    uint256 proposalId = 10;
    uint256[] memory proposalIds = new uint256[](1);
    proposalIds[0] = proposalId;

    uint24 votingDuration = uint24(62341);
    VotingMachine(address(votingMachine)).setProposalsVoteConfiguration(
      proposalId,
      BLOCK_HASH,
      votingDuration
    );
    VotingMachine(address(votingMachine)).setProposalsVoteConfigurationIds(proposalIds);

    vm.mockCall(
      address(votingStrategy),
      abi.encodeWithSelector(IVotingStrategy.hasRequiredRoots.selector, BLOCK_HASH),
      abi.encode('test')
    );
    vm.mockCall(
      address(rootsWarehouse),
      abi.encodeWithSelector(IDataWarehouse.getStorageRoots.selector, GOVERNANCE, BLOCK_HASH),
      abi.encode(keccak256(abi.encode('test')))
    );

    assertEq(
      uint256(votingMachine.getProposalState(proposalId)),
      uint256(IVotingMachineWithProofs.ProposalState.NotCreated)
    );

    _checkAndPerformUpKeep(robotKeeper);

    assertEq(
      uint256(votingMachine.getProposalState(proposalId)),
      uint256(IVotingMachineWithProofs.ProposalState.Active)
    );
    vm.clearMockedCalls();
  }

  function testCloseAndSendVote() public {
    uint256 proposalId = 5;
    uint24 votingDuration = 600;

    _createVote(proposalId, votingDuration);
    skip(votingDuration + 1);

    assertEq(
      uint8(votingMachine.getProposalState(proposalId)),
      uint8(IVotingMachineWithProofs.ProposalState.Finished)
    );

    _checkAndPerformUpKeep(robotKeeper);

    assertEq(
      uint8(votingMachine.getProposalState(proposalId)),
      uint8(IVotingMachineWithProofs.ProposalState.SentToGovernance)
    );
  }

  function testSubmitRoots() public {
    uint256 proposalId = 20;
    uint256[] memory proposalIds = new uint256[](1);
    proposalIds[0] = proposalId;
    VotingMachine(address(votingMachine)).setProposalsVoteConfiguration(
      proposalId,
      BLOCK_HASH,
      600
    );
    VotingMachine(address(votingMachine)).setProposalsVoteConfigurationIds(proposalIds);

    vm.mockCall(
      LINK_TOKEN,
      abi.encodeWithSelector(LinkTokenInterface.transferAndCall.selector),
      abi.encode(true)
    );
    _checkAndPerformUpKeep(robotKeeper);
  }

  function testMultipleActions() public {
    // Proposal for which roots can be submitted
    uint256 proposalId1 = 20;
    uint256[] memory proposalIds = new uint256[](2);
    proposalIds[0] = proposalId1;
    VotingMachine(address(votingMachine)).setProposalsVoteConfiguration(
      proposalId1,
      BLOCK_HASH,
      600
    );
    vm.mockCall(
      LINK_TOKEN,
      abi.encodeWithSelector(LinkTokenInterface.transferAndCall.selector),
      abi.encode(true)
    );

    // Proposal for which createVote action could be performed
    uint256 proposalId2 = 10;
    proposalIds[0] = proposalId2;

    uint24 votingDurationCreateVote = uint24(62341);
    VotingMachine(address(votingMachine)).setProposalsVoteConfiguration(
      proposalId2,
      BLOCK_HASH,
      votingDurationCreateVote
    );
    vm.mockCall(
      address(votingStrategy),
      abi.encodeWithSelector(IVotingStrategy.hasRequiredRoots.selector, BLOCK_HASH),
      abi.encode()
    );
    vm.mockCall(
      address(rootsWarehouse),
      abi.encodeWithSelector(IDataWarehouse.getStorageRoots.selector, GOVERNANCE, BLOCK_HASH),
      abi.encode(keccak256(abi.encode('test')))
    );

    VotingMachine(address(votingMachine)).setProposalsVoteConfigurationIds(proposalIds);

    assertEq(
      uint256(votingMachine.getProposalState(proposalId2)),
      uint256(IVotingMachineWithProofs.ProposalState.NotCreated)
    );

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

    _createVote(proposalId, votingDuration);
    skip(votingDuration + 1);

    assertEq(
      uint8(votingMachine.getProposalState(proposalId)),
      uint8(IVotingMachineWithProofs.ProposalState.Finished)
    );

    robotKeeper.toggleDisableAutomationById(5);

    (bool shouldRunKeeper, ) = robotKeeper.checkUpkeep('');
    assertEq(shouldRunKeeper, false);
  }

  function _checkAndPerformUpKeep(VotingChainRobotKeeper votingChainRobotKeeper) internal {
    (bool shouldRunKeeper, bytes memory performData) = votingChainRobotKeeper.checkUpkeep('');
    if (shouldRunKeeper) {
      votingChainRobotKeeper.performUpkeep(performData);
    }
  }

  function _createVote(uint256 proposalId, uint24 votingDuration) internal {
    uint256[] memory proposalIds = new uint256[](1);
    proposalIds[0] = proposalId;
    VotingMachine(address(votingMachine)).setProposalsVoteConfiguration(
      proposalId,
      BLOCK_HASH,
      votingDuration
    );
    VotingMachine(address(votingMachine)).setProposalsVoteConfigurationIds(proposalIds);

    vm.mockCall(
      address(votingStrategy),
      abi.encodeWithSelector(IVotingStrategy.hasRequiredRoots.selector, BLOCK_HASH),
      abi.encode()
    );
    vm.mockCall(
      address(rootsWarehouse),
      abi.encodeWithSelector(IDataWarehouse.getStorageRoots.selector, GOVERNANCE, BLOCK_HASH),
      abi.encode(keccak256(abi.encode('test')))
    );
    votingMachine.startProposalVote(proposalId);
    vm.clearMockedCalls();
  }
}
