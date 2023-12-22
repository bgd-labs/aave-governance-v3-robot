import type {VercelRequest, VercelResponse} from '@vercel/node';
import {WebClient, LogLevel} from '@slack/web-api';
import {ethers} from 'ethers';
import {keeperRegistryAbi} from '../abi/KeeperRegistry.json';
import {keeperRegistry_2_1_Abi} from '../abi/KeeperRegistry2_1.json';

const client = new WebClient(process.env.SLACK_TOKEN, {
  logLevel: LogLevel.DEBUG,
});
const channelId = process.env.CHANNEL_ID;

const config = {
  mainnet: {
    name: 'Execution Chain Keeper',
    id: '103962992988872542945147446194468190544109628047207929929141163121857186570465',
    registry: '0x02777053d6764996e594c3E88AF1D58D5363a2e6',
    registryVersion: 1,
  },
  polygon: {
    name: 'Execution Chain Keeper',
    id: '82990232394810788826748981965753730350133859818029683929136401112559915179430',
    registry: '0x02777053d6764996e594c3E88AF1D58D5363a2e6',
    registryVersion: 1,
  },
  arbitrum: {
    name: 'Execution Chain Keeper',
    id: '78329451080216164099529400539433108989111820950862041749656351555695961643082',
    registry: '0x75c0530885F385721fddA23C539AF3701d6183D4',
    registryVersion: 1,
  },
  optimism: {
    name: 'Execution Chain Keeper',
    id: '98991846084053478582099013231511635776224064505474556907242977329597039975307',
    registry: '0x75c0530885F385721fddA23C539AF3701d6183D4',
    registryVersion: 1,
  },
  avalanche: {
    name: 'Execution Chain Keeper',
    id: '42967470609923359998605990815360926273002411113492386351801017384824248835129',
    registry: '0x02777053d6764996e594c3E88AF1D58D5363a2e6',
    registryVersion: 1,
  },
  base: {
    name: 'Execution Chain Keeper',
    id: '110844910122831225835763727857179632339856792606450773885855748860468415334038',
    registry: '0xE226D5aCae908252CcA3F6CEFa577527650a9e1e',
    registryVersion: 2,
  },
};

export default async function handler(request: VercelRequest, response: VercelResponse) {
  try {
    console.log('Running Cron');

    for (const network in config) {
      await checkAndSendBalanceAlert(
        config[network].name,
        config[network].id,
        config[network].registry,
        network,
        config[network].registryVersion
      );
    }
    response.json({success: true});
  } catch (error) {
    console.error(error);
  }

  async function checkAndSendBalanceAlert(
    name: string,
    keeperId: string,
    keeperRegistry: string,
    network: string,
    registryVersion: number
  ) {
    const provider = new ethers.providers.JsonRpcProvider(getNetworkRpcUrl(network));
    const registryContract = new ethers.Contract(
      keeperRegistry,
      registryVersion == 1 ? keeperRegistryAbi : keeperRegistry_2_1_Abi,
      provider
    );

    const keeperInfo = await registryContract.getUpkeep(keeperId);
    const minimumBalance = await registryContract.getMinBalanceForUpkeep(keeperId);

    if (ethers.BigNumber.from(keeperInfo.balance).gt(ethers.BigNumber.from(minimumBalance))) {
      await client.chat.postMessage({
        channel: channelId,
        blocks: [
          {
            type: 'header',
            text: {
              type: 'plain_text',
              text: `${
                network.charAt(0).toUpperCase() + network.slice(1)
              } ${name} Underfunded :alert:`,
              emoji: true,
            },
          },
          {
            type: 'divider',
          },
          {
            type: 'section',
            fields: [
              {
                type: 'mrkdwn',
                text: `*Keeper Balance:*\n ${ethers.utils.formatEther(keeperInfo.balance)} LINK`,
              },
              {
                type: 'mrkdwn',
                text: `*Min Balance Required:*\n ${ethers.utils.formatEther(minimumBalance)} LINK`,
              },
              {
                type: 'mrkdwn',
                text: `*Gas Limit:*\n ${
                  registryVersion == 1 ? keeperInfo.executeGas : keeperInfo.performGas
                }`,
              },
              {
                type: 'mrkdwn',
                text: `*Amount Spent:*\n ${ethers.utils.formatEther(keeperInfo.amountSpent)} LINK`,
              },
              {
                type: 'mrkdwn',
                text: `*More Info:*\n https://automation.chain.link/${network}/${keeperId}`,
              },
            ],
          },
          {
            type: 'divider',
          },
        ],
      });
    }
  }

  function getNetworkRpcUrl(network: string) {
    switch (network) {
      case 'mainnet': {
        return process.env.RPC_MAINNET;
      }
      case 'polygon': {
        return process.env.RPC_POLYGON;
      }
      case 'optimism': {
        return process.env.RPC_OPTIMISM;
      }
      case 'avalanche': {
        return process.env.RPC_AVALANCHE;
      }
      case 'arbitrum': {
        return process.env.RPC_ARBITRUM;
      }
      case 'base': {
        return process.env.RPC_BASE;
      }
      default: {
        throw new Error('Invalid Network');
      }
    }
  }
}
