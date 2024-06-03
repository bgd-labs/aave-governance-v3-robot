import type {VercelRequest, VercelResponse} from '@vercel/node';
import {WebClient, LogLevel} from '@slack/web-api';
import {ethers} from 'ethers';
import {keeperRegistryAbi} from '../abi/KeeperRegistry.json';
import {keeperRegistry_2_1_Abi} from '../abi/KeeperRegistry2_1.json';
import {keeperTargetAbi} from '../abi/KeeperTarget.json';

const client = new WebClient(process.env.SLACK_TOKEN, {
  logLevel: LogLevel.DEBUG,
});
const channelId = process.env.CHANNEL_ID;

const config = {
};

export default async function handler(request: VercelRequest, response: VercelResponse) {
  try {
    console.log('Running Cron');

    for (const keeper in config) {
      await checkAndSendBalanceAlert(
        config[keeper].name,
        config[keeper].id,
        config[keeper].registry,
        config[keeper].network,
        config[keeper].registryVersion
      );

      await checkAndSendMaxGasAlert(
        config[keeper].id,
        config[keeper].registry,
        config[keeper].network,
        config[keeper].registryVersion
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

    if (ethers.BigNumber.from(keeperInfo.balance).lt(ethers.BigNumber.from(minimumBalance))) {
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

  async function checkAndSendMaxGasAlert(
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
    const maxGasLimit = registryVersion == 1 ? keeperInfo.executeGas : keeperInfo.performGas;
    const keeperTarget = new ethers.Contract(
      keeperInfo.target,
      keeperTargetAbi,
      provider
    );

    const checkData = await keeperTarget.checkUpkeep('0x');
    if (checkData[0] == true && checkData[1]) {
      const gasEstimation = await keeperTarget.estimateGas.performUpkeep(`${checkData[1]}`);

      if (gasEstimation.gt(5_000_000)) {
        await client.chat.postMessage({
          channel: channelId,
          blocks: [
            {
              type: 'header',
              text: {
                type: 'plain_text',
                text: `${
                  network.charAt(0).toUpperCase() + network.slice(1)
                } Payload Execution Gas Limit Exceeded :alert:`,
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
                  text: `Execution exceeds max gas limit configured for the keeper, please execute the payload manually`,
                },
                {
                  type: 'mrkdwn',
                  text: `*Gas Limit:*\n ${maxGasLimit}`,
                }
              ],
            },
            {
              type: 'divider',
            },
          ],
        });
      }
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
