import * as tenderly from "@tenderly/hardhat-tenderly";
import '@nomicfoundation/hardhat-verify';
import '@openzeppelin/hardhat-upgrades';
import "@dirtycajunrice/hardhat-tasks/internal/type-extensions"
import "@dirtycajunrice/hardhat-tasks";
import "dotenv/config";
import "./tasks";

tenderly.setup({ automaticVerifications: false });

import { HardhatUserConfig, NetworksUserConfig } from "hardhat/types";

const networkData = [
  {
    name: 'mainnet',
    chainId: 288,
    urls: {
      rpc: 'https://mainnet.boba.network',
      api: "https://api.routescan.io/v2/network/mainnet/evm/288/etherscan",
      browser: "https://eth.bobascan.com",
    }
  },
  {
    name: 'bnb',
    chainId: 56_288,
    urls: {
      rpc: 'https://bnb.boba.network',
      api: "https://api.routescan.io/v2/network/mainnet/evm/56288/etherscan",
      browser: "https://bnb.bobascan.com",
    }
  }
]

const config: HardhatUserConfig = {
  defaultNetwork: 'mainnet',
  solidity: {
    compilers: [ "0.8.20",  "0.8.9", "0.8.2", "0.6.0" ].map(version => ({
      version,
      settings: {
        ...(version.replace('0.8.', '') === '20' ? {evmVersion: 'london' } : {}),
        optimizer: { enabled: true, runs: 200 },
        outputSelection: { '*': { '*': [ 'storageLayout' ] } },
      },
    })),
    overrides: {
      "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol": {
        version: "0.8.9",
        settings: { optimizer: { enabled: true, runs: 200 } },
      },
      "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol": {
        version: "0.8.9",
        settings: { optimizer: { enabled: true, runs: 200 } },
      },
      "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol": {
        version: "0.8.9",
        settings: { optimizer: { enabled: true, runs: 200 } },
      },
      "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol": {
        version: "0.8.9",
        settings: { optimizer: { enabled: true, runs: 200 } },
      },
      "contracts/proxy.sol": {
        version: "0.8.9",
        settings: { optimizer: { enabled: true, runs: 200 } },
      },
    },
  },
  networks: networkData.reduce((o, network) => {
    o[network.name] = { url: network.urls.rpc, chainId: network.chainId, accounts: [ process.env.PRIVATE_KEY ] }
    return o;
  }, {} as NetworksUserConfig),
  etherscan: {
    apiKey: networkData.reduce((o, network) => {
      o[network.name] = process.env[`${network.name.toUpperCase()}_ETHERSCAN_API_KEY`] || 'not-needed';
      return o;
    }, {} as Record<string, string>),
    customChains: networkData.map(network => ({
      network: network.name,
      chainId: network.chainId,
      urls: { apiURL: network.urls.api, browserURL: network.urls.browser },
    }))
  },
  tenderly: {
    project: 'bobaverse',
    username: 'DirtyCajunRice',
  }
};

export default config;
