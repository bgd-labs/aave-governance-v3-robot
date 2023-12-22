import type {VercelRequest, VercelResponse} from '@vercel/node';
import * as Sentry from '@sentry/node';
import {ethers} from 'ethers';
import {hexZeroPad} from 'ethers/lib/utils';
import {
  formatToProofRLP,
  getBlockNumberByHash,
  getExtendedBlock,
  getProof,
  getSolidityStorageSlotBytes,
  prepareBlockRLP,
} from '../libs/ProofsHelper';
import {
  AaveSafetyModule,
  AaveV3Ethereum,
  GovernanceV3Ethereum,
  AaveMisc,
} from '@bgd-labs/aave-address-book';

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  tracesSampleRate: 1.0,
});

export default async function StorageRoots(request: VercelRequest, response: VercelResponse) {
  try {
    const {blockhash} = request.query;
    const provider = new ethers.providers.JsonRpcProvider(process.env.RPC_MAINNET);

    const aAaveActiveAddress = '0x329c54289Ff5D6B7b7daE13592C6B1EDA1543eD4';
    const aaveActiveAddress = AaveMisc.AAVE_ECOSYSTEM_RESERVE_CONTROLLER;
    const aaveAddress = AaveV3Ethereum.ASSETS.AAVE.UNDERLYING;
    const stkAaveAddress = AaveSafetyModule.STK_AAVE;
    const aAaveAddress = AaveV3Ethereum.ASSETS.AAVE.A_TOKEN;
    const governanceAddress = GovernanceV3Ethereum.GOVERNANCE;

    const blockNumber = await getBlockNumberByHash(provider, (blockhash as string).toLowerCase());

    const blockData = await getExtendedBlock(provider, blockNumber);
    const blockHeaderRLP = prepareBlockRLP(blockData);

    const slot = getSolidityStorageSlotBytes('0x0', aaveActiveAddress);
    const aAaveSlot = getSolidityStorageSlotBytes('0x34', aAaveActiveAddress);
    const exchangeRateSlot = hexZeroPad('0x51', 32);
    const delegatedStateSlot = hexZeroPad('0x40', 32);
    const governanceSlot = hexZeroPad('0x9', 32);
    const abiCoder = new ethers.utils.AbiCoder();

    // Aave
    const rawAccountProofDataAave = getProof(provider, aaveAddress, [slot], blockNumber);

    // aAave
    const rawAccountProofDataAAave = getProof(
      provider,
      aAaveAddress,
      [aAaveSlot, delegatedStateSlot],
      blockNumber
    );

    // governance
    const rawAccountProofDataGovernance = getProof(
      provider,
      governanceAddress,
      [governanceSlot],
      blockNumber
    );

    // stkAave
    const rawAccountProofDataStkAave = getProof(
      provider,
      stkAaveAddress,
      [slot, exchangeRateSlot],
      blockNumber
    );

    // stkAave slot
    const slotProof = getProof(provider, stkAaveAddress, [exchangeRateSlot], blockNumber);

    const proofResultArray = await Promise.all([
      rawAccountProofDataAave,
      rawAccountProofDataAAave,
      rawAccountProofDataGovernance,
      rawAccountProofDataStkAave,
      slotProof,
    ]);

    const accountStateProofRLP_Aave = formatToProofRLP(proofResultArray[0].accountProof);
    const accountStateProofRLP_aAave = formatToProofRLP(proofResultArray[1].accountProof);
    const accountStateProofRLP_governance = formatToProofRLP(proofResultArray[2].accountProof);
    const accountStateProofRLP_stkAave = formatToProofRLP(proofResultArray[3].accountProof);
    const slotProofRLP = formatToProofRLP(proofResultArray[4].storageProof[0].proof);

    const encodedParams = abiCoder.encode(
      ['bytes32', 'bytes', 'bytes', 'bytes', 'bytes', 'bytes', 'bytes32', 'bytes'],
      [
        blockData.hash,
        blockHeaderRLP,
        accountStateProofRLP_Aave,
        accountStateProofRLP_aAave,
        accountStateProofRLP_stkAave,
        accountStateProofRLP_governance,
        exchangeRateSlot,
        slotProofRLP,
      ]
    );
    response.status(200).send({
      data: encodedParams,
    });
  } catch (error) {
    Sentry.captureException(error);
    await Sentry.flush(2000);

    response.status(500).json({
      error: true,
      message: error.message,
    });
  }
}
