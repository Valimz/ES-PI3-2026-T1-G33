export type P2POfferStatus = "active" | "completed" | "cancelled";

export type P2POfferDocument = {
  sellerId: string;
  startupName: string;
  quotas: number;
  price: number;
  status: P2POfferStatus;
  createdAt: unknown;
};

export type GraphPoint = {
  date: string;
  value: number;
  invested: number;
  quantity: number;
};

export {addFunds, buyAsset, sellAsset, withdrawFunds, sellPartialAsset} from "../handlers/walletHandlers";
export {createP2POffer, makeCounterOffer, acceptOffer, editP2POffer, cancelP2POffer} from "../handlers/p2pHandlers";
export {getGraphSummary, getGraphHistory, getGraphAsset} from "../handlers/graphHandlers";
export {registerNotificationToken, sendNotification} from "../handlers/notificationHandlers";
