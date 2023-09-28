// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {RootsConsumer} from '../src/contracts/RootsConsumer.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {GovernanceV3Polygon} from 'aave-address-book/GovernanceV3Polygon.sol';
import {GovernanceV3Avalanche} from 'aave-address-book/GovernanceV3Avalanche.sol';
import {AaveV3PolygonAssets} from 'aave-address-book/AaveV3Polygon.sol';

contract DeployFuji is Script {
  function run() external {
    vm.startBroadcast();
    new RootsConsumer(
      0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846, // chainlink token
      0x022EEA14A6010167ca026B32576D6686dD7e85d2, // chainlink node operator
      address(5), // guardian
      '7da2702f37fd48e5b1b9a5715e3509b6', // jobId
      0, // 0 fee
      0x3eB4c81Dcc35c0C643081204B00d7c754B26Cab5, // datawarehouse address
      'https://backend-hp-bgdlabscom.vercel.app/api/roots?blockhash=' // api url
    );
    vm.stopBroadcast();
  }
}

contract DeployMumbai is Script {
  function run() external {
    vm.startBroadcast();
    new RootsConsumer(
      0x326C977E6efc84E512bB9C30f76E30c160eD06FB, // chainlink token
      0x4eA56b3DA6d4D2E837fd664B2b5f602a3B07A646, // chainlink node operator
      address(5), // guardian
      '55657c6f9deb41c58305c60eed9d5fbc', // jobId
      0, // 0 fee
      0x1F780a6E860792E59F2160b1E9E503bFF8c58Cb1, // datawarehouse address
      'https://backend-hp-bgdlabscom.vercel.app/api/roots?blockhash=' // api url
    );
    vm.stopBroadcast();
  }
}

contract DeployBnbTestnet is Script {
  function run() external {
    vm.startBroadcast();
    new RootsConsumer(
      0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06, // chainlink token
      0x1db329cDE457D68B872766F4e12F9532BCA9149b, // chainlink node operator
      address(5), // guardian
      '67c9db0d6a724438b1036eda4b520b2c', // jobId
      0, // 0 fee
      0x6AF9623B157bd3B267D36A601184D0415364A9e2, // datawarehouse address
      'https://backend-hp-bgdlabscom.vercel.app/api/roots?blockhash=' // api url
    );
    vm.stopBroadcast();
  }
}

contract DeploySepolia is Script {
  function run() external {
    vm.startBroadcast();
    new RootsConsumer(
      0x779877A7B0D9E8603169DdbD7836e478b4624789, // chainlink token
      0x6c2e87340Ef6F3b7e21B2304D6C057091814f25E, // chainlink node operator
      address(5), // guardian
      '325e34fd94a54d7888a88cb784c0f7c8', // jobId
      0, // 0 fee
      0xdF6C1affD18Ecb318e4468d96b588bbbEac180E2, // new datawarehouse address
      'https://backend-hp-bgdlabscom.vercel.app/api/roots?blockhash=' // api url
    );
    vm.stopBroadcast();
  }
}

contract DeployGoerli is Script {
  function run() external {
    vm.startBroadcast();
    new RootsConsumer(
      0x326C977E6efc84E512bB9C30f76E30c160eD06FB, // chainlink token
      0x6c2e87340Ef6F3b7e21B2304D6C057091814f25E, // chainlink node operator
      address(5), // guardian
      '325e34fd94a54d7888a88cb784c0f7c8', // jobId
      0, // 0 fee
      0xC946cc6bb934bAf2A539BaB62c647aff09D2e2D8, // new datawarehouse address
      'https://backend-hp-bgdlabscom.vercel.app/api/roots?blockhash=' // api url
    );
    vm.stopBroadcast();
  }
}

contract DeployMainnet is Script {
  function run() external {
    vm.startBroadcast();
    new RootsConsumer(
      AaveV3EthereumAssets.LINK_UNDERLYING, // chainlink token
      0x1db329cDE457D68B872766F4e12F9532BCA9149b, // chainlink node operator
      0xff37939808EcF199A2D599ef91D699Fb13dab7F7, // guardian
      '861ba8ef5af045d89a9b5b3d737b068a', // jobId
      1400000000000000000, // 1.4 link fee
      address(GovernanceV3Ethereum.DATA_WAREHOUSE),
      'https://backend-hp-bgdlabscom.vercel.app/api/roots?blockhash=' // api url
    );
    vm.stopBroadcast();
  }
}

contract DeployPolygon is Script {
  function run() external {
    vm.startBroadcast();
    new RootsConsumer(
      0xb0897686c545045aFc77CF20eC7A532E3120E0F1, // chainlink token
      0xbac0638773782e9130DfeAF59a5b27bBc49a7007, // chainlink node operator
      0x4e8984D11A47Ff89CD67c7651eCaB6C00a74B4A9, // guardian
      'e3ed77aca747427c980d79d09e318032', // jobId
      150000000000000000, // 0.15 link fee
      address(GovernanceV3Polygon.DATA_WAREHOUSE),
      'https://backend-hp-bgdlabscom.vercel.app/api/roots?blockhash=' // api url
    );
    vm.stopBroadcast();
  }
}

contract DeployAvax is Script {
  function run() external {
    vm.startBroadcast();
    new RootsConsumer(
      0x5947BB275c521040051D82396192181b413227A3, // chainlink token
      0x6c2e87340Ef6F3b7e21B2304D6C057091814f25E, // chainlink node operator
      0xD68c00a1A4a33876C5EC71A2Bf7bBd8676d72BF6, // guardian
      'c21a58ea59d1403caa8640ce08293bda', // jobId
      150000000000000000, // 0.15 link fee
      address(GovernanceV3Avalanche.DATA_WAREHOUSE),
      'https://backend-hp-bgdlabscom.vercel.app/api/roots?blockhash=' // api url
    );
    vm.stopBroadcast();
  }
}
