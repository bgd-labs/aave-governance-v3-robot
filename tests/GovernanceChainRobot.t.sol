// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {GovernanceChainRobot} from '../src/contracts/GovernanceChainRobot.sol';
import {MockAggregator} from 'chainlink/src/v0.8/mocks/MockAggregator.sol';
import 'aave-governance-v3/tests/GovernanceCore.t.sol';

contract GovernanceChainRobotTest is Test {
  address public constant CROSS_CHAIN_CONTROLLER = address(123456);
  address public constant VOTING_STRATEGY = address(123456789);
  address public constant VOTING_PORTAL = address(1230123);
  uint256 public constant EXECUTION_GAS_LIMIT = 400000;
  uint256 public constant COOLDOWN_PERIOD = 1 days;
  uint256 public constant CANCELLATION_FEE = 0.05 ether;
  address public constant CANCELLATION_FEE_COLLECTOR = address(123404321);

  IGovernanceCore public governance;
  TransparentProxyFactory public proxyFactory;
  GovernanceChainRobot public robotKeeper;

  IGovernanceCore.SetVotingConfigInput public votingConfigLvl1 =
    IGovernanceCore.SetVotingConfigInput({
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      coolDownBeforeVotingStart: uint24(1 days),
      votingDuration: uint24(7 days),
      yesThreshold: 320_000 ether,
      yesNoDifferential: 100_000 ether,
      minPropositionPower: 50_000 ether
    });

  IGovernanceCore.SetVotingConfigInput public votingConfigLvl2 =
    IGovernanceCore.SetVotingConfigInput({
      accessLevel: PayloadsControllerUtils.AccessControl.Level_2,
      votingDuration: uint24(7 days),
      coolDownBeforeVotingStart: uint24(1 days),
      yesThreshold: votingConfigLvl1.yesThreshold + 320_000 ether,
      yesNoDifferential: votingConfigLvl1.yesNoDifferential + 100_000 ether,
      minPropositionPower: votingConfigLvl1.minPropositionPower + 50_000 ether
    });

  function setUp() public {
    IGovernanceCore.SetVotingConfigInput[]
      memory votingConfigsInput = new IGovernanceCore.SetVotingConfigInput[](2);
    votingConfigsInput[0] = votingConfigLvl1;
    votingConfigsInput[1] = votingConfigLvl2;

    address[] memory votingPortals = new address[](1);
    votingPortals[0] = VOTING_PORTAL;
    proxyFactory = new TransparentProxyFactory();

    IGovernanceCore governanceImpl = new Governance(
      CROSS_CHAIN_CONTROLLER,
      COOLDOWN_PERIOD,
      CANCELLATION_FEE_COLLECTOR
    );

    address[] memory powerTokens = new address[](1);
    powerTokens[0] = address(1239746519);
    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(IBaseVotingStrategy.getVotingAssetList.selector),
      abi.encode(powerTokens)
    );
    governance = IGovernanceCore(
      proxyFactory.createDeterministic(
        address(governanceImpl),
        address(12345), // admin
        abi.encodeWithSelector(
          IGovernance.initialize.selector,
          address(123),
          address(1234), // guardian
          VOTING_STRATEGY,
          votingConfigsInput,
          votingPortals,
          EXECUTION_GAS_LIMIT,
          CANCELLATION_FEE
        ),
        keccak256('governance core salt')
      )
    );

    MockAggregator chainLinkFastGasFeed = new MockAggregator();
    robotKeeper = new GovernanceChainRobot(address(governance), address(chainLinkFastGasFeed));
  }

  function testCancel() public {
    uint256 proposalId = _createProposal();
    _activateVote(proposalId);
    IGovernanceCore.Proposal memory proposal = governance.getProposal(proposalId);

    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(0 ether)
    );

    assertEq(
      uint256(governance.getProposal(proposalId).state),
      uint256(IGovernanceCore.State.Active)
    );

    checkAndPerformUpKeep(robotKeeper);
    vm.clearMockedCalls();

    proposal = governance.getProposal(proposalId);

    assertEq(
      uint256(governance.getProposal(proposalId).state),
      uint256(IGovernanceCore.State.Cancelled)
    );
  }

  function testActivateVoting() public {
    uint256 proposalId = _createProposal();
    IGovernanceCore.Proposal memory proposal = governance.getProposal(proposalId);
    IGovernanceCore.VotingConfig memory config = governance.getVotingConfig(
      proposal.payloads[0].accessLevel
    );

    skip(config.coolDownBeforeVotingStart + 1);
    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(10000000 ether)
    );
    vm.mockCall(
      VOTING_PORTAL,
      abi.encodeWithSelector(IVotingPortal.forwardStartVotingMessage.selector),
      abi.encode()
    );

    assertEq(
      uint256(governance.getProposal(proposalId).state),
      uint256(IGovernanceCore.State.Created)
    );

    checkAndPerformUpKeep(robotKeeper);
    vm.clearMockedCalls();

    assertEq(
      uint256(governance.getProposal(proposalId).state),
      uint256(IGovernanceCore.State.Active)
    );
  }

  function testExecute() public {
    uint256 proposalId = _createProposal();
    _activateVote(proposalId);
    _queueProposal(proposalId);

    IGovernanceCore.Proposal memory proposal = governance.getProposal(proposalId);

    vm.warp(proposal.queuingTime + governance.COOLDOWN_PERIOD());
    vm.mockCall(
      CROSS_CHAIN_CONTROLLER,
      abi.encodeWithSelector(
        ICrossChainForwarder.forwardMessage.selector,
        proposal.payloads[0].chain,
        proposal.payloads[0].payloadsController,
        EXECUTION_GAS_LIMIT,
        abi.encode(
          proposal.payloads[0].payloadId,
          proposal.payloads[0].accessLevel,
          proposal.votingActivationTime
        )
      ),
      abi.encode(bytes32(0), bytes32(0))
    );
    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(100000000 ether)
    );

    assertEq(
      uint256(governance.getProposal(proposalId).state),
      uint256(IGovernanceCore.State.Queued)
    );

    checkAndPerformUpKeep(robotKeeper);
    vm.clearMockedCalls();

    assertEq(
      uint256(governance.getProposal(proposalId).state),
      uint256(IGovernanceCore.State.Executed)
    );
  }

  function testMultipleActions() public {
    // Create Proposal for which voting could be activated
    uint256 proposalId1 = _createProposal();

    IGovernanceCore.Proposal memory proposal1 = governance.getProposal(proposalId1);
    IGovernanceCore.VotingConfig memory config = governance.getVotingConfig(
      proposal1.payloads[0].accessLevel
    );

    skip(config.coolDownBeforeVotingStart + 1);
    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(10000000 ether)
    );
    vm.mockCall(
      VOTING_PORTAL,
      abi.encodeWithSelector(IVotingPortal.forwardStartVotingMessage.selector),
      abi.encode()
    );

    // Create Proposal for which payload could be executed
    uint256 proposalId2 = _createProposal();
    _activateVote(proposalId2);
    _queueProposal(proposalId2);

    IGovernanceCore.Proposal memory proposal2 = governance.getProposal(proposalId2);

    vm.warp(proposal2.queuingTime + governance.COOLDOWN_PERIOD());

    vm.mockCall(
      CROSS_CHAIN_CONTROLLER,
      abi.encodeWithSelector(
        ICrossChainForwarder.forwardMessage.selector,
        proposal2.payloads[0].chain,
        proposal2.payloads[0].payloadsController,
        EXECUTION_GAS_LIMIT,
        abi.encode(
          proposal2.payloads[0].payloadId,
          proposal2.payloads[0].accessLevel,
          proposal2.votingActivationTime
        )
      ),
      abi.encode(bytes32(0), bytes32(0))
    );

    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(10000000 ether)
    );

    assertEq(
      uint256(governance.getProposal(proposalId1).state),
      uint256(IGovernanceCore.State.Created)
    );
    assertEq(
      uint256(governance.getProposal(proposalId2).state),
      uint256(IGovernanceCore.State.Queued)
    );

    checkAndPerformUpKeep(robotKeeper);

    assertEq(
      uint256(governance.getProposal(proposalId1).state),
      uint256(IGovernanceCore.State.Active)
    );
    assertEq(
      uint256(governance.getProposal(proposalId2).state),
      uint256(IGovernanceCore.State.Executed)
    );
  }

  function testDisableAutomation() public {
    // create proposal which for which cancel action can be performed
    uint256 proposalId = _createProposal();
    _activateVote(proposalId);

    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(0 ether)
    );
    assertEq(
      uint256(governance.getProposal(proposalId).state),
      uint256(IGovernanceCore.State.Active)
    );

    robotKeeper.toggleDisableAutomationById(proposalId);

    (bool shouldRunKeeper, ) = robotKeeper.checkUpkeep('');
    assertEq(shouldRunKeeper, false);
  }

  function checkAndPerformUpKeep(GovernanceChainRobot governanceChainRobotKeeper) private {
    (bool shouldRunKeeper, bytes memory performData) = governanceChainRobotKeeper.checkUpkeep('');
    if (shouldRunKeeper) {
      governanceChainRobotKeeper.performUpkeep(performData);
    }
  }

  function _createProposal() internal returns (uint256) {
    PayloadsControllerUtils.AccessControl accessLevel = PayloadsControllerUtils
      .AccessControl
      .Level_1;
    PayloadsControllerUtils.Payload[] memory payloads = new PayloadsControllerUtils.Payload[](1);
    PayloadsControllerUtils.Payload memory payload = _createPayload(accessLevel);
    payloads[0] = payload;

    bytes32 ipfsHash = keccak256(bytes('some ipfs hash'));
    bytes32 blockHash = blockhash(block.number - 1);

    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(10000000 ether)
    );
    vm.mockCall(
      VOTING_PORTAL,
      abi.encodeWithSelector(
        IVotingPortal.forwardStartVotingMessage.selector,
        0,
        blockHash,
        votingConfigLvl1.votingDuration
      ),
      abi.encode()
    );

    uint256 proposalId = governance.createProposal{value: CANCELLATION_FEE}(
      payloads,
      VOTING_PORTAL,
      ipfsHash
    );

    vm.clearMockedCalls();
    return proposalId;
  }

  function _createPayload(
    PayloadsControllerUtils.AccessControl level
  ) internal pure returns (PayloadsControllerUtils.Payload memory) {
    PayloadsControllerUtils.Payload memory payload = PayloadsControllerUtils.Payload({
      chain: ChainIds.POLYGON,
      accessLevel: level,
      payloadsController: address(123012491456),
      payloadId: uint40(0)
    });
    return payload;
  }

  function _activateVote(uint256 proposalId) internal {
    IGovernanceCore.Proposal memory proposal = governance.getProposal(proposalId);
    IGovernanceCore.VotingConfig memory config = governance.getVotingConfig(
      proposal.payloads[0].accessLevel
    );
    skip(config.coolDownBeforeVotingStart + 1);

    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(1000000 ether)
    );
    governance.activateVoting(proposalId);
  }

  function _queueProposal(uint256 proposalId) internal {
    IGovernanceCore.Proposal memory proposal = governance.getProposal(proposalId);

    uint128 forVotes = 1000000 ether;
    uint128 againstVotes = 1 ether;

    skip(proposal.votingDuration + proposal.votingActivationTime + 1);

    vm.mockCall(
      VOTING_STRATEGY,
      abi.encodeWithSelector(
        IGovernancePowerStrategy.getFullPropositionPower.selector,
        address(this)
      ),
      abi.encode(10000000 ether)
    );
    hoax(VOTING_PORTAL);
    governance.queueProposal(proposalId, forVotes, againstVotes);

    vm.clearMockedCalls();
  }
}
