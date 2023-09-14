export {};

declare global {
  namespace NodeJS {
    interface ProcessEnv {
      PRIVATE_KEY: `0x${string}`;
      MAINNET_ETHERSCAN_API_KEY: string;
      BNB_ETHERSCAN_API_KEY: string;
    }
  }
}
