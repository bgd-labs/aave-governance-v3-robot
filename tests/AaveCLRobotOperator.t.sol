// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {AaveCLRobotOperator, IKeeperRegistrar, IAaveCLRobotOperator, IKeeperRegistry} from '../src/contracts/AaveCLRobotOperator.sol';
import {ExecutionChainRobotKeeper} from '../src/contracts/ExecutionChainRobotKeeper.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {GovernanceV3Optimism} from 'aave-address-book/GovernanceV3Optimism.sol';
import {MiscOptimism} from 'aave-address-book/MiscOptimism.sol';
import {DeployRobotOperator} from '../scripts/RobotOperator.s.sol';
import {stdStorage, StdStorage} from 'forge-std/Test.sol';

contract AaveCLRobotOperatorTest is Test {
  using stdStorage for StdStorage;

  AaveCLRobotOperator public aaveCLRobotOperator;

  IERC20 constant LINK_TOKEN = IERC20(0x350a791Bfc2C21F9Ed5d10980Dad2e2638ffa7f6);
  address constant WITHDRAW_ADDRESS = address(2);
  address constant REGISTRY = 0x696fB0d7D069cc0bb35a7c36115CE63E55cb9AA6;
  address constant REGISTRAR = 0xe601C5837307f07aB39DEB0f5516602f045BF14f;
  address constant GUARDIAN = 0x9867Ce43D2a574a152fE6b134F64c9578ce3cE03;

  address constant OLD_REGISTRY = 0x75c0530885F385721fddA23C539AF3701d6183D4;
  address constant OLD_REGISTRAR = 0x4F3AF332A30973106Fe146Af0B4220bBBeA748eC;

  event KeeperCancelled(uint256 indexed id, address indexed upkeep);
  event KeepersMigrated(
    uint256[] indexed ids,
    address indexed newKeeperRegistry,
    address indexed newKeeperRegistrar
  );

  function setUp() public {
    vm.createSelectFork(
      'optimism',
      132700949 // Mar-3-2025
    );
    aaveCLRobotOperator = AaveCLRobotOperator(
      DeployRobotOperator._deploy(
        MiscOptimism.TRANSPARENT_PROXY_FACTORY,
        GovernanceV3Optimism.EXECUTOR_LVL_1,
        REGISTRY,
        REGISTRAR,
        WITHDRAW_ADDRESS,
        GovernanceV3Optimism.EXECUTOR_LVL_1,
        GUARDIAN // guardian
      )
    );
  }

  function testRegister() public {
    (uint256 id, address upkeep) = _registerKeeper();
    IKeeperRegistry.UpkeepInfo memory upkeepInfo = IKeeperRegistry(REGISTRY).getUpkeep(id);

    uint256[] memory registeredKeepers = aaveCLRobotOperator.getKeepersList();

    assertEq(registeredKeepers.length, 1);
    assertEq(registeredKeepers[0], id);
    assertEq(upkeepInfo.target, upkeep);
    assertEq(upkeepInfo.performGas, 1000000);
    assertEq(upkeepInfo.checkData, abi.encode(address(1)));
    assertEq(upkeepInfo.balance, 100 ether);
    assertEq(upkeepInfo.admin, address(aaveCLRobotOperator));
    assertTrue(upkeepInfo.maxValidBlocknumber > block.number);
    assertFalse(upkeepInfo.paused);
  }

  function testRegister_EventTypeKeeper() public {
    vm.startPrank(0x1B06E76bDA9d3721422c5ae5b3Fb2Edc29298BE3); // REGISTRAR_OWNER
    IKeeperRegistrar(REGISTRAR).setAutoApproveAllowedSender(address(aaveCLRobotOperator), true);
    vm.stopPrank();

    deal(address(LINK_TOKEN), GovernanceV3Optimism.EXECUTOR_LVL_1, 100 ether);

    vm.startPrank(GovernanceV3Optimism.EXECUTOR_LVL_1);
    LINK_TOKEN.approve(address(aaveCLRobotOperator), 100 ether);
    ExecutionChainRobotKeeper ethRobotKeeper = new ExecutionChainRobotKeeper(
      address(GovernanceV3Optimism.PAYLOADS_CONTROLLER)
    );
    uint256 id = aaveCLRobotOperator.register(
      'testName',
      address(ethRobotKeeper),
      '',
      1_000_000,
      100 ether,
      1, // should be 1 for event type keeper 0 otherwise
      ''
    );
    vm.stopPrank();

    assertEq(IKeeperRegistry(REGISTRY).getTriggerType(id), 1);
  }

  function testRefill() public {
    (uint256 id, ) = _registerKeeper();
    IKeeperRegistry.UpkeepInfo memory initialUpkeepInfo = IKeeperRegistry(REGISTRY).getUpkeep(id);
    uint96 amountToFund = 10 ether;

    vm.startPrank(GovernanceV3Optimism.EXECUTOR_LVL_1);
    deal(address(LINK_TOKEN), GovernanceV3Optimism.EXECUTOR_LVL_1, amountToFund);
    LINK_TOKEN.approve(address(aaveCLRobotOperator), amountToFund);

    aaveCLRobotOperator.refillKeeper(id, amountToFund);
    vm.stopPrank();

    IKeeperRegistry.UpkeepInfo memory updatedUpkeepInfo = IKeeperRegistry(REGISTRY).getUpkeep(id);
    assertEq(updatedUpkeepInfo.balance, initialUpkeepInfo.balance + amountToFund);
  }

  function testCancelAndWithdraw() public {
    assertEq(LINK_TOKEN.balanceOf(WITHDRAW_ADDRESS), 0);
    (uint256 id, ) = _registerKeeper();

    vm.startPrank(aaveCLRobotOperator.owner());
    aaveCLRobotOperator.cancel(id);
    vm.stopPrank();

    vm.roll(block.number + 100);

    aaveCLRobotOperator.withdrawLink(id);
    IKeeperRegistry.UpkeepInfo memory upkeepInfo = IKeeperRegistry(REGISTRY).getUpkeep(id);

    assertEq(upkeepInfo.balance, 0);
    assertGt(LINK_TOKEN.balanceOf(WITHDRAW_ADDRESS), 0);
  }

  function testCancel() public {
    (uint256 id, ) = _registerKeeper();

    _registerKeeper();
    _registerKeeper();
    _registerKeeper();

    assertEq(aaveCLRobotOperator.getKeepersList().length, 4);

    vm.expectEmit();
    emit KeeperCancelled(id, aaveCLRobotOperator.getKeeperInfo(id).upkeep);

    vm.startPrank(aaveCLRobotOperator.owner());
    aaveCLRobotOperator.cancel(id);
    vm.stopPrank();

    uint256[] memory registeredKeepers = aaveCLRobotOperator.getKeepersList();
    for (uint256 index = 0; index < registeredKeepers.length; index++) {
      assertTrue(registeredKeepers[index] != id);
    }

    assertEq(aaveCLRobotOperator.getKeepersList().length, 3);
  }

  function testPause() public {
    (uint256 id, ) = _registerKeeper();

    vm.startPrank(aaveCLRobotOperator.owner());
    aaveCLRobotOperator.pause(id);

    assertEq(aaveCLRobotOperator.isPaused(id), true);

    aaveCLRobotOperator.unpause(id);
    vm.stopPrank();

    assertEq(aaveCLRobotOperator.isPaused(id), false);
  }

  function testChangeGasLimit(uint32 gasLimit) public {
    vm.assume(gasLimit >= 10_000 && gasLimit <= 5_000_000);
    (uint256 id, ) = _registerKeeper();

    vm.startPrank(aaveCLRobotOperator.guardian());
    aaveCLRobotOperator.setGasLimit(id, gasLimit);
    vm.stopPrank();

    vm.startPrank(address(6));
    vm.expectRevert(bytes('ONLY_BY_OWNER_OR_GUARDIAN'));
    aaveCLRobotOperator.setGasLimit(id, gasLimit);
    vm.stopPrank();

    IKeeperRegistry.UpkeepInfo memory upkeepInfo = IKeeperRegistry(REGISTRY).getUpkeep(id);
    assertEq(upkeepInfo.performGas, gasLimit);
  }

  function testSetTriggerConfig() public {
    (uint256 id, ) = _registerKeeper();

    vm.startPrank(aaveCLRobotOperator.owner());
    aaveCLRobotOperator.setTriggerConfig(
      id,
      'abi encoded trigger config for event log type keeper only'
    );

    assertEq(
      IKeeperRegistry(REGISTRY).getUpkeepTriggerConfig(id),
      'abi encoded trigger config for event log type keeper only'
    );
    vm.stopPrank();

    vm.startPrank(address(6));
    vm.expectRevert(bytes('ONLY_BY_OWNER_OR_GUARDIAN'));
    aaveCLRobotOperator.setTriggerConfig(id, '');
    vm.stopPrank();
  }

  function testSetWithdrawAddress(address newWithdrawAddress) public {
    vm.startPrank(aaveCLRobotOperator.owner());
    aaveCLRobotOperator.setWithdrawAddress(newWithdrawAddress);
    vm.stopPrank();

    vm.startPrank(address(10));
    vm.expectRevert(bytes('Ownable: caller is not the owner'));
    aaveCLRobotOperator.setWithdrawAddress(newWithdrawAddress);
    vm.stopPrank();

    assertEq(aaveCLRobotOperator.getWithdrawAddress(), newWithdrawAddress);
  }

  function testGetWithdrawAddress() public {
    assertEq(aaveCLRobotOperator.getWithdrawAddress(), WITHDRAW_ADDRESS);
  }

  function testGetKeeperInfo() public {
    (uint256 id, address upkeep) = _registerKeeper();
    AaveCLRobotOperator.KeeperInfo memory keeperInfo = aaveCLRobotOperator.getKeeperInfo(id);
    assertEq(keeperInfo.upkeep, upkeep);
    assertEq(keeperInfo.name, 'testName');
  }

  function _registerKeeper() internal returns (uint256, address) {
    // registers conditional type keeper
    deal(address(LINK_TOKEN), GovernanceV3Optimism.EXECUTOR_LVL_1, 100 ether);

    vm.startPrank(GovernanceV3Optimism.EXECUTOR_LVL_1);
    LINK_TOKEN.approve(address(aaveCLRobotOperator), 100 ether);
    ExecutionChainRobotKeeper ethRobotKeeper = new ExecutionChainRobotKeeper(
      address(GovernanceV3Optimism.PAYLOADS_CONTROLLER)
    );
    uint256 id = aaveCLRobotOperator.register(
      'testName',
      address(ethRobotKeeper),
      abi.encode(address(1)),
      1_000_000,
      100 ether,
      0,
      ''
    );
    vm.stopPrank();

    return (id, address(ethRobotKeeper));
  }

  function testMigrate() public {
    // mock the getLinkAddress method on the old registry, as it does not have this method
    vm.mockCall(
      OLD_REGISTRY,
      abi.encodeWithSelector(IKeeperRegistry.getLinkAddress.selector),
      abi.encode(aaveCLRobotOperator.getLinkToken())
    );

    // set to old registry so we can test migration to new registry
    vm.prank(GovernanceV3Optimism.EXECUTOR_LVL_1);
    aaveCLRobotOperator.setRegistry(OLD_REGISTRY);

    // modify and append keeperId on _keepers, this is mock an already registered keeper to be registered by
    // the robot operator contract in order to test migration it to new registry
    uint256 id = 38016904744371718141567798635089231439311935855515862823520872759101042183005;
    uint256 arrayLength = 1;
    uint256 keepersStorageSlot = 2;
    vm.store(address(aaveCLRobotOperator), bytes32(keepersStorageSlot), bytes32(arrayLength));
    vm.store(
      address(aaveCLRobotOperator),
      bytes32(_arrayLocation(keepersStorageSlot, 0)),
      bytes32(id)
    );

    // transfer ownership of a registered keeper to the robot operator contract
    vm.prank(0x7cbe7B1E715762F19308A29961dbe9E4bEeD5ba4);
    IKeeperRegistry(OLD_REGISTRY).transferUpkeepAdmin(id, address(aaveCLRobotOperator));

    vm.prank(address(aaveCLRobotOperator));
    IKeeperRegistry(OLD_REGISTRY).acceptUpkeepAdmin(id);

    uint256[] memory idsToMigrate = new uint256[](1);
    idsToMigrate[0] = id;

    vm.expectEmit();
    emit KeepersMigrated(idsToMigrate, REGISTRY, REGISTRAR);

    vm.prank(GovernanceV3Optimism.EXECUTOR_LVL_1);
    aaveCLRobotOperator.migrate(REGISTRY, REGISTRAR);
  }

  function _arrayLocation(uint256 slot, uint256 index) public pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(slot))) + (index);
  }
}
