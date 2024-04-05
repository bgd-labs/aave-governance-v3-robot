// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOvmGasPriceOracle {
  /**
   * Computes the L1 portion of the fee
   * based on the size of the RLP encoded tx
   * and the current l1BaseFee
   * @param data Unsigned RLP encoded tx, 6 elements
   * @return L1 fee that should be paid for the tx
   */
  function getL1Fee(bytes memory data) external view returns (uint256);

  /**
   * Computes the amount of L1 gas used for a transaction
   * The overhead represents the per batch gas overhead of
   * posting both transaction and state roots to L1 given larger
   * batch sizes.
   * 4 gas for 0 byte
   * https://github.com/ethereum/go-ethereum/blob/9ada4a2e2c415e6b0b51c50e901336872e028872/params/protocol_params.go#L33
   * 16 gas for non zero byte
   * https://github.com/ethereum/go-ethereum/blob/9ada4a2e2c415e6b0b51c50e901336872e028872/params/protocol_params.go#L87
   * This will need to be updated if calldata gas prices change
   * Account for the transaction being unsigned
   * Padding is added to account for lack of signature on transaction
   * 1 byte for RLP V prefix
   * 1 byte for V
   * 1 byte for RLP R prefix
   * 32 bytes for R
   * 1 byte for RLP S prefix
   * 32 bytes for S
   * Total: 68 bytes of padding
   * @param data Unsigned RLP encoded tx
   * @return Amount of L1 gas used for a transaction
   */
  function getL1GasUsed(bytes memory data) external view returns (uint256);
}
