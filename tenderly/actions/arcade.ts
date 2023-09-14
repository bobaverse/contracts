import { ActionFn, Context, Event, GatewayNetwork, Network, TransactionEvent } from "@tenderly/actions";
import { ethers } from "ethers";
import { L2StandardBridgeABI__factory, BobaVerseArcade__factory } from "./types/ethers-contracts";

const L2_STANDARD_BRIDGE_ADDRESS = "0x4200000000000000000000000000000000000010";

const BOBA_ARCADE_ADDRESSES: Partial<Record<GatewayNetwork, string>> = {
  [Network.BOBA_ETHEREUM]: "0x8a64123e26E3AE48ed08Ee3dBA67B9a57982Fd17",
  [Network.BOBA_BINANCE]: "0x53d1B430C0bC7D808B635DAFE9520f18dcCf6E3a"
} as const;

export const addCredit: ActionFn = async (context: Context, event: Event) => {
  const transactionEvent = event as TransactionEvent;

  const bc = await getBridgeContract(context);
  const ac = await getArcadeContract(context);

  const depositFinalizedTopic = bc.interface.getEventTopic("DepositFinalized");
  const depositFinalizedEvent = transactionEvent.logs.find(log =>
    log.topics.find(topic => topic === depositFinalizedTopic) !== undefined
  );
  if (!depositFinalizedEvent) {
    throw new Error("No deposit finalized event found");
  }

  const [ l1Token, l2Token, /** from */, to, amount, /** data */ ] = bc.interface.decodeEventLog("AssetTeleported", depositFinalizedEvent.data, depositFinalizedEvent.topics);


  console.log(`Adding 1 Credit to ${to} on ${context.metadata.getNetwork()} for bridging ${amount} ${l1Token} (L2: ${l2Token})`);

  const tx = await ac.addCredits([to], [1]);
  await tx.wait();
  console.log(`Credit added successfully!`);
};

const getWallet = async (context: Context) => {
  const network = context.metadata.getNetwork() as GatewayNetwork;
  if (network === undefined) {
    throw new Error("No network found in metadata");
  }
  const gatewayUrl = context.gateways.getGateway(network);
  const provider = new ethers.providers.JsonRpcProvider(gatewayUrl);
  const pk = await context.secrets.get("arcadeCredits.addressPrivateKey");
  return new ethers.Wallet(pk, provider);
}

const getBridgeContract = async (context: Context) => {
  const wallet = await getWallet(context);
  return L2StandardBridgeABI__factory.connect(L2_STANDARD_BRIDGE_ADDRESS, wallet);
};

const getArcadeContract = async (context: Context) => {
  const network = context.metadata.getNetwork() as GatewayNetwork;
  const wallet = await getWallet(context);
  if (BOBA_ARCADE_ADDRESSES[network] === undefined) {
    throw new Error(`No arcade contract found for network ${network}`);
  }
  return BobaVerseArcade__factory.connect(BOBA_ARCADE_ADDRESSES[network]!, wallet);
};
