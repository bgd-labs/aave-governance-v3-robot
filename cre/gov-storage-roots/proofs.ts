import { toRlp, fromRlp, type Hex } from 'viem';

/**
 * Normalize a hex quantity for RLP encoding.
 * RLP represents zero as empty bytes '0x', not '0x0' or '0x00'.
 * Also strips unnecessary leading zeros from hex quantities.
 */
function normalizeQuantity(hex: string): Hex {
  if (!hex || hex === '0x' || hex === '0x0' || hex === '0x00') return '0x';
  // Strip leading zeros but keep at least one digit
  const stripped = hex.replace(/^0x0+/, '0x');
  return (stripped === '0x' ? '0x' : stripped) as Hex;
}

/**
 * Prepares block header RLP encoding from raw block data returned by eth_getBlockByHash.
 * Supports post-Pectra blocks (21 fields).
 */
export function prepareBlockRLP(rawBlock: Record<string, string>): Hex {
  const rawData: Hex[] = [
    rawBlock.parentHash as Hex,
    rawBlock.sha3Uncles as Hex,
    rawBlock.miner as Hex,
    rawBlock.stateRoot as Hex,
    rawBlock.transactionsRoot as Hex,
    rawBlock.receiptsRoot as Hex,
    rawBlock.logsBloom as Hex,
    '0x', // difficulty is 0 post-merge
    normalizeQuantity(rawBlock.number),
    normalizeQuantity(rawBlock.gasLimit),
    normalizeQuantity(rawBlock.gasUsed),
    normalizeQuantity(rawBlock.timestamp),
    rawBlock.extraData as Hex,
    rawBlock.mixHash as Hex,
    rawBlock.nonce as Hex,
  ];

  // Post-London (EIP-1559)
  if (rawBlock.baseFeePerGas) {
    rawData.push(normalizeQuantity(rawBlock.baseFeePerGas));
  }

  // Post-Shanghai (EIP-4895)
  if (rawBlock.withdrawalsRoot) {
    rawData.push(rawBlock.withdrawalsRoot as Hex);
  }

  // Post-Cancun (EIP-4844)
  if (rawBlock.blobGasUsed !== undefined) {
    rawData.push(normalizeQuantity(rawBlock.blobGasUsed));
    rawData.push(normalizeQuantity(rawBlock.excessBlobGas));
  }

  // Post-EIP-4788
  if (rawBlock.parentBeaconBlockRoot) {
    rawData.push(rawBlock.parentBeaconBlockRoot as Hex);
  }

  // Post-Pectra (EIP-7685)
  if (rawBlock.requestsHash) {
    rawData.push(rawBlock.requestsHash as Hex);
  }

  return toRlp(rawData);
}

/**
 * Re-encodes an array of RLP proof nodes into a single RLP-encoded value.
 * Each element in rawData is an individually RLP-encoded proof node from eth_getProof.
 * We decode each one and re-encode the whole array as a single RLP.
 */
export function formatToProofRLP(rawData: Hex[]): Hex {
  return toRlp(rawData.map((d) => fromRlp(d, 'hex')));
}
