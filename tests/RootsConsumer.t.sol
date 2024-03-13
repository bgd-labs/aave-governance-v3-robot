// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {RootsConsumer} from '../src/contracts/RootsConsumer.sol';
import {DataWarehouse} from 'aave-governance-v3/src/contracts/voting/DataWarehouse.sol';
import {LinkTokenInterface} from 'chainlink/src/v0.8/ChainlinkClient.sol';
import {MockLinkToken} from 'chainlink/test/v0.8/foundry/dev/special/MockLinkToken.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveSafetyModule} from 'aave-address-book/AaveSafetyModule.sol';
import 'forge-std/Test.sol';

contract RootsConsumerTest is Test {
  DataWarehouse dataWarehouse;
  MockLinkToken LINK_TOKEN;

  address constant CHAINLINK_OPERATOR = address(12);
  address constant WITHDRAWAL_ADDRESS = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;
  bytes32 constant BLOCKHASH = 0x3ea2216feb32bf585b48d93324579120ef2dd1c3d60d03ffb2e88f7e7238d281; // mainnet
  bytes32 constant STK_AAVE_SLOT =
    0x0000000000000000000000000000000000000000000000000000000000000051;

  event RootsRegisteredFulfilled(bytes32 indexed requestId, bytes32 indexed blockHash);
  event ChainlinkRequested(bytes32 indexed id);
  event OperatorSet(address indexed chainlinkOperator);

  RootsConsumer rootsConsumer;

  function setUp() public {
    LINK_TOKEN = new MockLinkToken();
    dataWarehouse = new DataWarehouse();
    rootsConsumer = new RootsConsumer(
      address(LINK_TOKEN),
      CHAINLINK_OPERATOR,
      address(5),
      '999f64aab86b48739da48db1d1de0ac5',
      0,
      address(dataWarehouse),
      'api url'
    );
  }

  function testRequestSubmitRoots() public {
    vm.expectEmit(false, false, false, false);
    emit ChainlinkRequested('120');

    vm.startPrank(rootsConsumer.getRobotKeeper());
    rootsConsumer.requestSubmitRoots('random block hash');
    vm.stopPrank();
  }

  function testFulfillRegisterRoots() public {
    bytes memory response = _getGeneratedBytes('./tests/utils/RegisterRootsApiResponse.txt');

    hoax(address(0));
    vm.expectEmit(true, true, false, false);
    emit RootsRegisteredFulfilled('120', BLOCKHASH);

    rootsConsumer.fulfillRegisterRoots('120', response);

    // check has required roots
    assertTrue(
      dataWarehouse.getStorageRoots(AaveV3EthereumAssets.AAVE_UNDERLYING, BLOCKHASH) != bytes32(0)
    );
    assertTrue(dataWarehouse.getStorageRoots(AaveSafetyModule.STK_AAVE, BLOCKHASH) != bytes32(0));
    assertTrue(
      dataWarehouse.getRegisteredSlot(BLOCKHASH, AaveSafetyModule.STK_AAVE, STK_AAVE_SLOT) > 0
    );
    assertTrue(
      dataWarehouse.getStorageRoots(AaveV3EthereumAssets.AAVE_A_TOKEN, BLOCKHASH) != bytes32(0)
    );
    assertTrue(
      dataWarehouse.getStorageRoots(address(GovernanceV3Ethereum.GOVERNANCE), BLOCKHASH) !=
        bytes32(0)
    );
  }

  function testSetFee(uint256 fee) public {
    assertEq(rootsConsumer.getFee(), 0);
    rootsConsumer.setFee(fee);
    assertEq(rootsConsumer.getFee(), fee);
  }

  function testSetJobId(bytes32 jobId) public {
    assertEq(rootsConsumer.getJobId(), '999f64aab86b48739da48db1d1de0ac5');
    rootsConsumer.setJobId(jobId);
    assertEq(rootsConsumer.getJobId(), jobId);
  }

  function testSetApiUrl(string memory apiUrl) public {
    assertEq(rootsConsumer.getApiUrl(), 'api url');
    rootsConsumer.setApiUrl(apiUrl);
    assertEq(rootsConsumer.getApiUrl(), apiUrl);
  }

  function testSetOperator(address operator) public {
    vm.expectEmit(true, false, false, false);
    emit OperatorSet(operator);

    rootsConsumer.setOperator(operator);
  }

  function testWithdrawLink(uint256 amount) public {
    vm.assume(amount < LINK_TOKEN.totalSupply());
    LINK_TOKEN.transfer(address(rootsConsumer), amount);
    uint256 ownerBalanceBefore = LINK_TOKEN.balanceOf(WITHDRAWAL_ADDRESS);

    rootsConsumer.emergencyTokenTransfer(address(LINK_TOKEN), WITHDRAWAL_ADDRESS, amount);
    uint256 ownerBalanceAfter = LINK_TOKEN.balanceOf(WITHDRAWAL_ADDRESS);

    assertEq(LINK_TOKEN.balanceOf(address(rootsConsumer)), 0);
    assertEq(ownerBalanceAfter - ownerBalanceBefore, amount);
  }

  function _getGeneratedBytes(string memory path) internal returns (bytes memory) {
    string[] memory catCmds = new string[](2);
    catCmds[0] = 'cat';
    catCmds[1] = path;

    bytes memory jsResult = vm.ffi(catCmds);
    return (jsResult);
  }
}
