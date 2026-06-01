import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {db} from "../../startups/shared/firebase";

export type PriceHistoryEntry = {
  priceCents: number;
  previousPriceCents: number;
  variationPercent: number;
  factors: {
    demandScore: number;
    capitalScore: number;
    investorScore: number;
    stageFactor: number;
    noise: number;
  };
  createdAt: FieldValue;
};

export async function listActiveStartups() {
  const snapshot = await db
    .collection("startups")
    .where("status", "==", "ativa")
    .get();

  return snapshot.docs.map((doc) => ({id: doc.id, data: doc.data()}));
}

export async function countInvestors(startupId: string): Promise<number> {
  const snapshot = await db
    .collection("startups")
    .doc(startupId)
    .collection("investors")
    .count()
    .get();

  return snapshot.data().count;
}

export async function countRecentTrades(
  startupName: string,
  days: number
): Promise<number> {
  const cutoff = Timestamp.fromDate(
    new Date(Date.now() - days * 24 * 60 * 60 * 1000)
  );

  const snapshot = await db
    .collection("p2p_offers")
    .where("startupName", "==", startupName)
    .where("status", "==", "completed")
    .where("createdAt", ">=", cutoff)
    .get();

  return snapshot.size;
}

export async function getLastPriceEntry(
  startupId: string
): Promise<{priceCents: number; createdAt: Timestamp} | null> {
  const snapshot = await db
    .collection("startups")
    .doc(startupId)
    .collection("priceHistory")
    .orderBy("createdAt", "desc")
    .limit(1)
    .get();

  if (snapshot.empty) {
    return null;
  }

  const data = snapshot.docs[0]!.data();
  return {
    priceCents: data.priceCents as number,
    createdAt: data.createdAt as Timestamp,
  };
}

export async function persistNewPrice(
  startupId: string,
  entry: PriceHistoryEntry,
  formattedPrice: string
): Promise<void> {
  const batch = db.batch();

  const historyRef = db
    .collection("startups")
    .doc(startupId)
    .collection("priceHistory")
    .doc();

  batch.set(historyRef, entry);

  const startupRef = db.collection("startups").doc(startupId);
  batch.update(startupRef, {
    val: formattedPrice,
    updatedAt: FieldValue.serverTimestamp(),
  });

  await batch.commit();
}

export async function updateInvestorAppreciation(
  startupId: string,
  _newPriceCents: number
): Promise<void> {
  const investorsSnap = await db
    .collection("startups")
    .doc(startupId)
    .collection("investors")
    .get();

  for (const investorDoc of investorsSnap.docs) {
    const uid = investorDoc.id;
    const walletRef = db
      .collection("users")
      .doc(uid)
      .collection("wallet")
      .doc("main");

    const assetsSnap = await db
      .collection("users")
      .doc(uid)
      .collection("assets")
      .get();

    if (assetsSnap.empty) continue;

    const startupsSnap = await db.collection("startups").get();
    const startupsByName = new Map<string, Record<string, unknown>>();
    startupsSnap.docs.forEach((doc) => {
      startupsByName.set(doc.data().name as string, doc.data());
    });

    let totalInvested = 0;
    let totalCurrentValue = 0;

    for (const assetDoc of assetsSnap.docs) {
      const assetData = assetDoc.data();
      const investedRaw = String(assetData.value ?? "R$ 0,00");
      const investedVal = parseFloat(
        investedRaw.replace(/[^0-9,.-]/g, "").replace(",", ".")
      ) || 0;
      totalInvested += investedVal;

      const assetName = String(assetData.name ?? "");
      const startup = startupsByName.get(assetName);
      const currentPriceStr = String(
        (startup as Record<string, unknown>)?.val ?? investedRaw
      );
      const currentPrice = parseFloat(
        currentPriceStr.replace(/[^0-9,.-]/g, "").replace(",", ".")
      ) || 0;

      const amountStr = String(assetData.amount ?? "0");
      const quantity = parseFloat(
        amountStr.split(" ")[0]!.replace(",", ".")
      ) || 0;

      totalCurrentValue += quantity * currentPrice;
    }

    const variationPercent =
      totalInvested > 0 ?
        ((totalCurrentValue - totalInvested) / totalInvested) * 100 :
        0;

    const sign = variationPercent >= 0 ? "+" : "";
    const formatted = `${sign} ${variationPercent
      .toFixed(1)
      .replace(".", ",")}%`;

    await walletRef.set({appreciation: formatted}, {merge: true});
  }
}
