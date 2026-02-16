import {
	bytesToHex,
	type CronPayload,
	cre,
  CronCapability,
	encodeCallMsg,
	getNetwork,
	hexToBase64,
	Runner,
  handler,
	type Runtime,
} from '@chainlink/cre-sdk';
import { encodeFunctionData, decodeFunctionResult, zeroAddress, encodeAbiParameters, parseAbiParameters, type Hex } from 'viem';
import { ICLAutomation } from '../contracts/abi/ICLAutomation';

type NetworkConfig = {
  chainName: string;
  mailboxAddress: string;
  automationAddresses: string[];
};

type Config = {
  schedule: string;
  evms: NetworkConfig[];
};

const processAutomation = (
  runtime: Runtime<Config>,
  evmClient: InstanceType<typeof cre.capabilities.EVMClient>,
  automationAddress: string,
  mailboxAddress: string,
  chainName: string
): string | null => {
  const callData = encodeFunctionData({
    abi: ICLAutomation,
    functionName: "checkUpkeep",
    args: ['0x']
  });

  const contractCall = evmClient
    .callContract(runtime, {
      call: encodeCallMsg({
        from: zeroAddress,
        to: automationAddress as Hex,
        data: callData,
      })
    })
    .result();

  const checkData = decodeFunctionResult({
    abi: ICLAutomation,
    functionName: "checkUpkeep",
    data: bytesToHex(contractCall.data),
  });

  runtime.log(`[${chainName}] checkUpkeep(${automationAddress}): ${checkData[0]}`);

  if (!checkData[0]) return null;

  const performData = encodeFunctionData({
    abi: ICLAutomation,
    functionName: "performUpkeep",
    args: [checkData[1]]
  });

  const encodedAutomationData = encodeAbiParameters(
    parseAbiParameters('address, bytes'),
    [automationAddress as Hex, performData]
  );

  const reportResponse = runtime
    .report({
      encodedPayload: hexToBase64(encodedAutomationData),
      encoderName: "evm",
      signingAlgo: "ecdsa",
      hashingAlgo: "keccak256",
    })
    .result();

  const writeReportResult = evmClient
    .writeReport(runtime, {
      receiver: mailboxAddress,
      report: reportResponse,
      gasConfig: { gasLimit: '500000' },
    })
    .result();

  const txHash = bytesToHex(writeReportResult.txHash || new Uint8Array(32));
  runtime.log(`[${chainName}] tx: ${txHash}`);
  return txHash;
};

const onCronTrigger = (runtime: Runtime<Config>): string => {
  runtime.log("Automation workflow triggered.");

  const results: string[] = [];

  for (const networkConfig of runtime.config.evms) {
    const network = getNetwork({
      chainFamily: 'evm',
      chainSelectorName: networkConfig.chainName,
      isTestnet: false,
    });

    if (!network) {
      runtime.log(`Network not found: ${networkConfig.chainName}`);
      continue;
    }

    const evmClient = new cre.capabilities.EVMClient(network.chainSelector.selector);

    for (const automationAddress of networkConfig.automationAddresses) {
      const txHash = processAutomation(
        runtime,
        evmClient,
        automationAddress,
        networkConfig.mailboxAddress,
        networkConfig.chainName
      );
      if (txHash) results.push(txHash);
    }
  }

  return results.length > 0 ? results.join(',') : "No upkeep needed";
};

const initWorkflow = (config: Config) => {
  const cron = new CronCapability();

  return [
    handler(
      cron.trigger({ schedule: config.schedule }),
      onCronTrigger
    )
  ];
};

export async function main() {
  const runner = await Runner.newRunner<Config>();
  await runner.run(initWorkflow);
}

main();
