import {
	bytesToHex,
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
  const checkUpkeepCalldata = encodeFunctionData({
    abi: ICLAutomation,
    functionName: 'checkUpkeep',
    args: ['0x']
  });

  const checkUpkeepCall = evmClient
    .callContract(runtime, {
      call: encodeCallMsg({
        from: zeroAddress,
        to: automationAddress as Hex,
        data: checkUpkeepCalldata,
      })
    })
    .result();

  const checkUpkeepResult = decodeFunctionResult({
    abi: ICLAutomation,
    functionName: 'checkUpkeep',
    data: bytesToHex(checkUpkeepCall.data),
  });

  runtime.log(`[${chainName}] checkUpkeep(${automationAddress}): ${checkUpkeepResult[0]}`);

  if (!checkUpkeepResult[0]) return null; // automation should not run as the checker returns false

  const performUpkeepCalldata = encodeFunctionData({
    abi: ICLAutomation,
    functionName: 'performUpkeep',
    args: [checkUpkeepResult[1]]
  });

  const mailboxReportData = encodeAbiParameters(
    parseAbiParameters('address, bytes'),
    [automationAddress as Hex, performUpkeepCalldata]
  );

  const reportResponse = runtime
    .report({
      encodedPayload: hexToBase64(mailboxReportData),
      encoderName: 'evm',
      signingAlgo: 'ecdsa',
      hashingAlgo: 'keccak256',
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

const createAutomationHandler = (
  chainName: string,
  mailboxAddress: string,
  automationAddress: string
) => {
  return (runtime: Runtime<Config>): string => {
    runtime.log(`[${chainName}] Handler triggered for ${automationAddress}`);

    const network = getNetwork({
      chainFamily: 'evm',
      chainSelectorName: chainName,
      isTestnet: false,
    });

    if (!network) {
      runtime.log(`Network not found: ${chainName}`);
      return 'Network not found';
    }

    const evmClient = new cre.capabilities.EVMClient(network.chainSelector.selector);

    const txHash = processAutomation(
      runtime,
      evmClient,
      automationAddress,
      mailboxAddress,
      chainName
    );

    return txHash ?? 'No upkeep needed';
  };
};

const initWorkflow = (config: Config) => {
  const cron = new CronCapability();
  const trigger = cron.trigger({ schedule: config.schedule });

  const handlers = config.evms
    .filter((network) => network.chainName && network.automationAddresses.length > 0)
    .flatMap((network) =>
      network.automationAddresses
        .filter((addr) => addr)
        .map((automationAddress) =>
          handler(
            trigger,
            createAutomationHandler(network.chainName, network.mailboxAddress, automationAddress)
          )
        )
    );

  return handlers;
};

export async function main() {
  const runner = await Runner.newRunner<Config>();
  await runner.run(initWorkflow);
}

main();
