import {BigNumber, BytesLike, ethers} from 'ethers';
import {defaultAbiCoder, hexStripZeros, hexZeroPad, keccak256} from 'ethers/lib/utils.js';

export const getProof = async (
  provider: ethers.providers.JsonRpcProvider,
  address: string,
  storageKeys: string[],
  blockNumber: number
) => {
  return provider.send('eth_getProof', [address, storageKeys, ethers.utils.hexValue(blockNumber)]);
};

export const getBlockNumberByHash = async (
  provider: ethers.providers.JsonRpcProvider,
  blockHash: string
): Promise<number> => {
  const block = await provider.send('eth_getBlockByHash', [
    blockHash,
    false,
  ]);
  return block.number;
};

export const getExtendedBlock = async (
  provider: ethers.providers.JsonRpcProvider,
  blockNumber: number
) => {
  return provider.send('eth_getBlockByNumber', [ethers.utils.hexValue(blockNumber), false]);
};

export function formatToProofRLP(rawData: string[]): string {
  return ethers.utils.RLP.encode(rawData.map((d) => ethers.utils.RLP.decode(d)));
}

// IMPORTANT valid only for post-London blocks, as it includes `baseFeePerGas`
export function prepareBlockRLP(rawBlock: any) {
  const rawData = [
    rawBlock.parentHash,
    rawBlock.sha3Uncles,
    rawBlock.miner,
    rawBlock.stateRoot,
    rawBlock.transactionsRoot,
    rawBlock.receiptsRoot,
    rawBlock.logsBloom,
    '0x', // BigNumber.from(rawBlock.difficulty).toHexString(),
    BigNumber.from(rawBlock.number).toHexString(),
    BigNumber.from(rawBlock.gasLimit).toHexString(),
    BigNumber.from(rawBlock.gasUsed).isZero()
      ? '0x'
      : BigNumber.from(rawBlock.gasUsed).toHexString(),
    BigNumber.from(rawBlock.timestamp).toHexString(),
    rawBlock.extraData,
    rawBlock.mixHash,
    rawBlock.nonce,
    BigNumber.from(rawBlock.baseFeePerGas).toHexString(),
    rawBlock.withdrawalsRoot,
  ];
  return ethers.utils.RLP.encode(rawData);
}

export function getSolidityStorageSlotBytes(mappingSlot: BytesLike, key: string) {
  const slot = hexZeroPad(mappingSlot, 32);
  return hexStripZeros(keccak256(defaultAbiCoder.encode(['address', 'uint256'], [key, slot])));
}
