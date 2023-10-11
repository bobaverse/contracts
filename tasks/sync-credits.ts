import { EventLog, JsonRpcApiProvider } from "ethers";
import { task, types } from "hardhat/config";
import L2StandardBridgeABI from "./task-abis/L2StandardBridgeABI.json";
import "@nomicfoundation/hardhat-ethers";

const L2_STANDARD_BRIDGE_ADDRESS = "0x4200000000000000000000000000000000000010";

task("sync-credits", "Sync credits for the Arcade")
  .addOptionalParam("startBlock", "First block to look for events", "0", types.string)
  .addOptionalParam("finishBlock", "last block to look for events", "latest", types.string)
  .addOptionalParam("batchSize", "Number of events to query at a time", 5000, types.int)
  .setAction(async ({ startBlock, finishBlock, batchSize }, hre) => {
    const { contract } = await hre.dcr.getContractAndData("BobaVerseArcade");
    if (hre.network.config.chainId === 56_288) {
      // @ts-ignore
      contract.runner["_gasLimit"] = BigInt(10_000_000);
    }
    const bridge = await hre.ethers.getContractAt(L2StandardBridgeABI.abi, L2_STANDARD_BRIDGE_ADDRESS);

    const provider = contract.runner?.provider as JsonRpcApiProvider;

    const fromBlock = parseInt(startBlock);
    const toBlock = finishBlock === "latest" ? await provider.getBlockNumber() : parseInt(finishBlock);

    const totalBlocks = toBlock - fromBlock;
    const totalBatches = Math.ceil(totalBlocks / batchSize);
    console.log(`Total blocks to query: ${totalBlocks}`);
    const logs: EventLog[] = [];
    if (totalBatches > 1) {
      console.log(`Batch size: ${batchSize}`);
      console.log(`Total batches: ${totalBatches}`);
      for (let i = 0; i < totalBatches; i++) {
        const start = fromBlock + i * batchSize;
        const end = Math.min(toBlock, start + batchSize);
        console.log(`Querying batch ${i + 1} of ${totalBatches} (blocks ${start} - ${end})`);
        const results = await bridge.queryFilter(bridge.filters.DepositFinalized(), start, end);
        if (results.length > 0) {
          console.log(`Found ${results.length} results in batch ${i + 1}. Total: ${logs.length + results.length}`);
          logs.push(...results as EventLog[]);
        }
      }
    } else {
      const results = await bridge.queryFilter(bridge.filters.DepositFinalized(), fromBlock, toBlock);
      if (results.length > 0) {
        console.log(`Found ${results.length} results.`);
        logs.push(...results as EventLog[]);

      }
    }
    console.log("Processing results...");
    const credits: Record<`0x${string}`, number> = {};

    for (const log of logs) {
      const [ l1Token, l2Token, /** from */, to, amount, /** data */ ] = log.args;
      console.log(`Adding 1 Credit to ${to} for bridging ${amount} ${l1Token} (L2: ${l2Token})`);
      credits[to] = (credits[to] ?? 0) + 1;
    }
    console.table(credits);

    console.log("Writing credits to chain...");
    const accounts = Object.keys(credits);
    const amounts = Object.values(credits);

    const tx = await contract.addCredits(accounts, amounts);
    await tx.wait();
    console.log("Done!");
  });
