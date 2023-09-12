import '@nomicfoundation/hardhat-verify';
import '@openzeppelin/hardhat-upgrades';
import "@dirtycajunrice/hardhat-tasks";
import "dotenv/config";
import "./tasks";

import { HardhatUserConfig, NetworksUserConfig } from "hardhat/types";

const networkData = [
  {
    name: 'mainnet',
    chainId: 288,
    urls: {
      rpc: 'https://mainnet.boba.network',
      api: "https://api.bobascan.com/api",
      browser: "https://bobascan.com/",
    }
  },
  {
    name: 'bnb',
    chainId: 56_288,
    urls: {
      rpc: 'https://bnb.boba.network',
      api: "https://blockexplorer.bnb.boba.network/api",
      browser: "https://blockexplorer.bnb.boba.network",
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
      }
    }))
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
  }
};

export default config;
