import {
  bytesToHex,
  cre,
  encodeCallMsg,
  prepareReportRequest,
  type Runtime,
  type EVMLog,
} from '@chainlink/cre-sdk';
import {
  encodeFunctionData,
  decodeFunctionResult,
  encodeAbiParameters,
  parseAbiParameters,
  zeroAddress,
  type Hex,
} from 'viem';
import { type Config, type VotingNetworkConfig } from './types';
import { IGovernanceCore } from '../contracts/abi/IGovernanceCore';
import { IDataWarehouse } from '../contracts/abi/IDataWarehouse';
import { IMailboxCRE } from '../contracts/abi/IMailboxCRE';
import { prepareBlockRLP, formatToProofRLP } from './proofs';
import { getBlockByHash, getProof } from './rpc';

/** stkAAVE exchange rate storage slot */
const STK_AAVE_EXCHANGE_RATE_SLOT: Hex =
  '0x0000000000000000000000000000000000000000000000000000000000000051';

const ETH_RPC_SECRET_ID = 'ETH_RPC_URL';

/**
 * Reads the proposal from the governance contract and returns the voting portal address.
 */
function getVotingPortal(
  runtime: Runtime<Config>,
  ethEvmClient: InstanceType<typeof cre.capabilities.EVMClient>,
  proposalId: bigint
): Hex {
  const calldata = encodeFunctionData({
    abi: IGovernanceCore,
    functionName: 'getProposal',
    args: [proposalId],
  });

  const result = ethEvmClient
    .callContract(runtime, {
      call: encodeCallMsg({
        from: zeroAddress,
        to: runtime.config.governanceAddress as Hex,
        data: calldata,
      }),
    })
    .result();

  const data = bytesToHex(result.data);
  const proposal = decodeFunctionResult({
    abi: IGovernanceCore,
    functionName: 'getProposal',
    data: data,
  });

  return proposal.votingPortal as Hex;
}

/**
 * Resolves the voting network configuration from the voting portal address.
 */
function resolveVotingNetwork(
  config: Config,
  votingPortal: Hex
): VotingNetworkConfig {
  const network = config.votingNetworks.find(
    (n) => n.votingPortalAddress.toLowerCase() === votingPortal.toLowerCase()
  );
  if (!network) {
    throw new Error(`Unknown voting portal: ${votingPortal}`);
  }
  return network;
}

/**
 * Sends a transaction to the DataWarehouse via the mailbox contract using writeReport.
 */
function sendViaMailbox(
  runtime: Runtime<Config>,
  votingEvmClient: InstanceType<typeof cre.capabilities.EVMClient>,
  mailboxAddress: string,
  dataWarehouseAddress: string,
  functionCalldata: Hex,
  chainName: string,
  label: string
): Hex {
  // Encode as (address target, bytes data) for the mailbox
  const mailboxReportData = encodeAbiParameters(
    parseAbiParameters('address, bytes'),
    [dataWarehouseAddress as Hex, functionCalldata]
  );

  // Estimate gas first
  const onReportCalldata = encodeFunctionData({
    abi: IMailboxCRE,
    functionName: 'onReport',
    args: ['0x', mailboxReportData],
  });

  try {
    const gasEstimate = votingEvmClient
      .estimateGas(runtime, {
        msg: encodeCallMsg({
          from: zeroAddress,
          to: mailboxAddress as Hex,
          data: onReportCalldata,
        }),
      })
      .result();
    runtime.log(
      `[${chainName}] Gas estimate for ${label}: ${gasEstimate.gas.toString()}`
    );
  } catch (e) {
    runtime.log(
      `[${chainName}] Gas estimation failed for ${label}: ${e}`
    );
    throw e;
  }

  // Sign and send via mailbox
  const reportResponse = runtime
    .report(prepareReportRequest(mailboxReportData))
    .result();

  const writeResult = votingEvmClient
    .writeReport(runtime, {
      receiver: mailboxAddress,
      report: reportResponse,
    })
    .result();

  if (!writeResult.txHash) {
    throw new Error(`[${chainName}] writeReport returned invalid txHash for ${label}`);
  }

  const txHash = bytesToHex(writeResult.txHash);
  runtime.log(`[${chainName}] ${label} tx: ${txHash}`);
  return txHash;
}

/**
 * Main processing function: fetches proofs from Ethereum and submits storage roots
 * to the DataWarehouse on the voting chain.
 */
export function processStorageRoots(
  runtime: Runtime<Config>,
  event: EVMLog
): string {
  const config = runtime.config;

  // 1. Decode event data
  const proposalId = BigInt(bytesToHex(event.topics[1]));
  const snapshotBlockHash = bytesToHex(event.topics[2]) as Hex;
  runtime.log(
    `VotingActivated: proposalId=${proposalId}, snapshotBlockHash=${snapshotBlockHash}`
  );

  // 2. Get the voting portal from the proposal
  const ethChainSelector =
    cre.capabilities.EVMClient.SUPPORTED_CHAIN_SELECTORS[
      config.ethereumChainSelectorName as keyof typeof cre.capabilities.EVMClient.SUPPORTED_CHAIN_SELECTORS
    ];
  const ethEvmClient = new cre.capabilities.EVMClient(ethChainSelector);

  const votingPortal = getVotingPortal(runtime, ethEvmClient, proposalId);
  runtime.log(`Voting portal: ${votingPortal}`);

  // 3. Resolve the voting network
  const votingNetwork = resolveVotingNetwork(config, votingPortal);
  runtime.log(
    `Voting network: ${votingNetwork.chainSelectorName}, DataWarehouse: ${votingNetwork.dataWarehouseAddress}`
  );

  // 4. Get Ethereum RPC URL from secrets
  const ethRpcUrl = runtime.getSecret({ id: ETH_RPC_SECRET_ID, namespace: 'main' }).result().value;

  // 5. Create ConfidentialHTTPClient and get block data from Ethereum RPC
  const confClient = new cre.capabilities.ConfidentialHTTPClient();
  const blockData = getBlockByHash(
    confClient,
    runtime,
    ethRpcUrl,
    snapshotBlockHash
  );
  const blockNumber = blockData.number as Hex;
  runtime.log(`Snapshot block number: ${blockNumber}`);

  // 6. Prepare block header RLP
  const blockHeaderRLP = prepareBlockRLP(blockData);

  // 7. Fetch account proofs for all tokens
  const aaveProof = getProof(
    confClient,
    runtime,
    ethRpcUrl,
    config.tokens.aave as Hex,
    [],
    blockNumber
  );

  const aAaveProof = getProof(
    confClient,
    runtime,
    ethRpcUrl,
    config.tokens.aAave as Hex,
    [],
    blockNumber
  );

  const stkAaveProof = getProof(
    confClient,
    runtime,
    ethRpcUrl,
    config.tokens.stkAave as Hex,
    [STK_AAVE_EXCHANGE_RATE_SLOT],
    blockNumber
  );

  const governanceProof = getProof(
    confClient,
    runtime,
    ethRpcUrl,
    config.governanceAddress as Hex,
    [],
    blockNumber
  );

  // 8. Format proofs as RLP
  const accountProofRLP_Aave = formatToProofRLP(aaveProof.accountProof);
  const accountProofRLP_aAave = formatToProofRLP(aAaveProof.accountProof);
  const accountProofRLP_stkAave = formatToProofRLP(stkAaveProof.accountProof);
  const accountProofRLP_governance = formatToProofRLP(
    governanceProof.accountProof
  );
  const slotProofRLP_stkAave = formatToProofRLP(
    stkAaveProof.storageProof[0].proof
  );

  runtime.log('All proofs fetched and formatted');

  // 9. Create EVMClient for the voting chain and submit storage roots
  const votingChainSelector =
    cre.capabilities.EVMClient.SUPPORTED_CHAIN_SELECTORS[
      votingNetwork.chainSelectorName as keyof typeof cre.capabilities.EVMClient.SUPPORTED_CHAIN_SELECTORS
    ];
  const votingEvmClient = new cre.capabilities.EVMClient(votingChainSelector);
  const chainName = votingNetwork.chainSelectorName;

  // processStorageRoot for AAVE
  sendViaMailbox(
    runtime,
    votingEvmClient,
    votingNetwork.mailboxAddress,
    votingNetwork.dataWarehouseAddress,
    encodeFunctionData({
      abi: IDataWarehouse,
      functionName: 'processStorageRoot',
      args: [
        config.tokens.aave as Hex,
        snapshotBlockHash,
        blockHeaderRLP,
        accountProofRLP_Aave,
      ],
    }),
    chainName,
    `processStorageRoot(AAVE)`
  );

  // processStorageRoot for aAAVE
  sendViaMailbox(
    runtime,
    votingEvmClient,
    votingNetwork.mailboxAddress,
    votingNetwork.dataWarehouseAddress,
    encodeFunctionData({
      abi: IDataWarehouse,
      functionName: 'processStorageRoot',
      args: [
        config.tokens.aAave as Hex,
        snapshotBlockHash,
        blockHeaderRLP,
        accountProofRLP_aAave,
      ],
    }),
    chainName,
    `processStorageRoot(aAAVE)`
  );

  // processStorageRoot for stkAAVE
  sendViaMailbox(
    runtime,
    votingEvmClient,
    votingNetwork.mailboxAddress,
    votingNetwork.dataWarehouseAddress,
    encodeFunctionData({
      abi: IDataWarehouse,
      functionName: 'processStorageRoot',
      args: [
        config.tokens.stkAave as Hex,
        snapshotBlockHash,
        blockHeaderRLP,
        accountProofRLP_stkAave,
      ],
    }),
    chainName,
    `processStorageRoot(stkAAVE)`
  );

  // processStorageRoot for Governance
  sendViaMailbox(
    runtime,
    votingEvmClient,
    votingNetwork.mailboxAddress,
    votingNetwork.dataWarehouseAddress,
    encodeFunctionData({
      abi: IDataWarehouse,
      functionName: 'processStorageRoot',
      args: [
        config.governanceAddress as Hex,
        snapshotBlockHash,
        blockHeaderRLP,
        accountProofRLP_governance,
      ],
    }),
    chainName,
    `processStorageRoot(Governance)`
  );

  // processStorageSlot for stkAAVE exchange rate
  sendViaMailbox(
    runtime,
    votingEvmClient,
    votingNetwork.mailboxAddress,
    votingNetwork.dataWarehouseAddress,
    encodeFunctionData({
      abi: IDataWarehouse,
      functionName: 'processStorageSlot',
      args: [
        config.tokens.stkAave as Hex,
        snapshotBlockHash,
        STK_AAVE_EXCHANGE_RATE_SLOT,
        slotProofRLP_stkAave,
      ],
    }),
    chainName,
    `processStorageSlot(stkAAVE exchangeRate)`
  );

  runtime.log(
    `All storage roots submitted for proposal ${proposalId} on ${chainName}`
  );
  return `Storage roots submitted for proposal ${proposalId}`;
}
