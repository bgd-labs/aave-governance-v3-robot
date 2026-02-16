// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IReceiver, IERC165} from '../interfaces/IReceiver.sol';
import {Address} from 'openzeppelin-contracts/contracts/utils/Address.sol';

contract MailboxCRE is IReceiver {
  using Address for address;

  function onReport(
    bytes calldata,
    bytes calldata report
  ) external {
    (address target, bytes memory encodedCalldata) = abi.decode(report, (address, bytes));
    target.functionCall(encodedCalldata);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override returns (bool) {
    return interfaceId == type(IReceiver).interfaceId || interfaceId == type(IERC165).interfaceId;
  }
}
