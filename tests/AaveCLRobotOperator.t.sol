// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {AaveCLRobotOperator, IKeeperRegistrar} from '../src/contracts/AaveCLRobotOperator.sol';
import {ExecutionChainRobotKeeper} from '../src/contracts/ExecutionChainRobotKeeper.sol';
import {IKeeperRegistry} from '../src/interfaces/IKeeperRegistry.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';

contract AaveCLRobotOperatorTest is Test {
  AaveCLRobotOperator public aaveCLRobotOperator;
  address constant LINK_WHALE = 0x6CFb6d2Ce675fA03B2E629771c37c8869d7CA2f8;
  IERC20 constant LINK_TOKEN = IERC20(0x88Fb150BDc53A65fe94Dea0c9BA0a6dAf8C6e196);
  address constant WITHDRAW_ADDRESS = address(2);
  address constant REGISTRY = 0xE226D5aCae908252CcA3F6CEFa577527650a9e1e;
  address constant REGISTRAR = 0xD8983a340A96b9C2Bb6855E46847aE134Db71fB1;

  function setUp() public {
    vm.createSelectFork(
      'base',
      8143141 // Dec-19-2023
    );
    aaveCLRobotOperator = new AaveCLRobotOperator(
      REGISTRY,
      REGISTRAR,
      WITHDRAW_ADDRESS,
      GovernanceV3Ethereum.EXECUTOR_LVL_1
    );
  }

  function testRegister() public {
    (uint256 id, address upkeep) = _registerKeeper();
    IKeeperRegistry.UpkeepInfo memory upkeepInfo = IKeeperRegistry(REGISTRY).getUpkeep(id);

    assertEq(upkeepInfo.target, upkeep);
    assertEq(upkeepInfo.performGas, 1000000);
    assertEq(upkeepInfo.checkData, '');
    assertEq(upkeepInfo.balance, 100 ether);
    assertEq(upkeepInfo.admin, address(aaveCLRobotOperator));
    assertTrue(upkeepInfo.maxValidBlocknumber > block.number);
    assertFalse(upkeepInfo.paused);
  }

  function testRegister_EventTypeKeeper() public {
    vm.startPrank(0x8fA510072009E71CfD447169AB5A84cAc394f58A); // REGISTRAR_OWNER
    IKeeperRegistrar(REGISTRAR).setAutoApproveAllowedSender(address(aaveCLRobotOperator), true);
    vm.stopPrank();

    // register event type keeper robot
    vm.startPrank(LINK_WHALE);
    LINK_TOKEN.transfer(GovernanceV3Ethereum.EXECUTOR_LVL_1, 100 ether);
    vm.stopPrank();

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    LINK_TOKEN.approve(address(aaveCLRobotOperator), 100 ether);
    ExecutionChainRobotKeeper ethRobotKeeper = new ExecutionChainRobotKeeper(
      address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER)
    );
    uint256 id = aaveCLRobotOperator.register(
      'testName',
      address(ethRobotKeeper),
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

    vm.startPrank(LINK_WHALE);
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

    vm.startPrank(aaveCLRobotOperator.owner());
    aaveCLRobotOperator.cancel(id);
    vm.stopPrank();
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
    vm.startPrank(LINK_WHALE);
    LINK_TOKEN.transfer(GovernanceV3Ethereum.EXECUTOR_LVL_1, 100 ether);
    vm.stopPrank();

    vm.startPrank(GovernanceV3Ethereum.EXECUTOR_LVL_1);
    LINK_TOKEN.approve(address(aaveCLRobotOperator), 100 ether);
    ExecutionChainRobotKeeper ethRobotKeeper = new ExecutionChainRobotKeeper(
      address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER)
    );
    uint256 id = aaveCLRobotOperator.register(
      'testName',
      address(ethRobotKeeper),
      1_000_000,
      100 ether,
      0,
      ''
    );
    vm.stopPrank();

    return (id, address(ethRobotKeeper));
  }
}
