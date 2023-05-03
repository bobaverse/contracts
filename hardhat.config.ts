import "@nomicfoundation/hardhat-toolbox";
import '@openzeppelin/hardhat-upgrades';
import "@dirtycajunrice/hardhat-tasks";
import { HardhatUserConfig } from "hardhat/config";
import { NetworkBase } from "@dirtycajunrice/hardhat-tasks";

import "dotenv/config";
import "./tasks";

const settings = {
  optimizer: {
    enabled: true,
    runs: 200
  },
  outputSelection: {
    '*': {
      '*': ['storageLayout'],
    },
  },
}

const compilers = [
  "0.8.18", "0.8.17", "0.8.16", "0.8.9", "0.8.2", "0.6.0"
].map(version => ({ version, settings }));


const networkBase: { [name: string]: NetworkBase } = {
  bobaEth: {
    name: 'bobaEth',
    chainId: 288,
    urls: {
      rpc: 'https://mainnet.boba.network',
      api: "https://api.bobascan.com/api",
      browser: "https://bobascan.com/",
    }
  },
  bobaOpera: {
    name: 'bobaOpera',
    chainId: 301,
    urls: {
      rpc: 'https://bobaopera.boba.network',
      api: "https://blockexplorer.bobaopera.boba.network/api",
      browser: "https://blockexplorer.bobaopera.boba.network",
    }
  },
  bobaBeam: {
    name: 'bobaBeam',
    chainId: 1_294,
    urls: {
      rpc: 'https://bobabeam.boba.network',
      api: "https://blockexplorer.bobabeam.boba.network/api",
      browser: "https://blockexplorer.bobabeam.boba.network",
    }
  },
  bobaAvax: {
    name: 'bobaAvax',
    chainId: 43_288,
    urls: {
      rpc: 'https://avax.boba.network',
      api: "https://blockexplorer.avax.boba.network/api",
      browser: "https://blockexplorer.avax.boba.network",
    }
  },
  bobaBnb: {
    name: 'bobaBnb',
    chainId: 56_288,
    urls: {
      rpc: 'https://bnb.boba.network',
      api: "https://blockexplorer.bnb.boba.network/api",
      browser: "https://blockexplorer.bnb.boba.network",
    }
  }
}

export const GetNetworks = (accounts: string[]) => {
  return Object.entries(networkBase).reduce((o, [, network]) => {
    o[network.name] = {
      url: network.urls.rpc,
      chainId: network.chainId,
      accounts: accounts
    }
    return o;
  }, {} as any)
}

export const GetEtherscanCustomChains = () => {
  return Object.entries(networkBase).reduce((o, [, network]) => {
    if (network.urls.api && network.urls.browser) {
      o.push({
        network: network.name,
        chainId: network.chainId,
        urls: {
          apiURL: network.urls.api,
          browserURL: network.urls.browser,
        },
      })
    }
    return o;
  }, [] as any)
}

const networks = GetNetworks([process.env.PRIVATE_KEY])

const config: HardhatUserConfig = {
  solidity: { compilers },
  networks,
  etherscan: {
    apiKey: {
      bobaEth: process.env.BOBASCAN_API_KEY || '',
      bobaOpera: 'not-needed',
      bobaBeam: 'not-needed',
      bobaAvax: 'not-needed',
      bobaBnb: 'not-needed',
    },
    customChains: GetEtherscanCustomChains()
  }
};

export default config;