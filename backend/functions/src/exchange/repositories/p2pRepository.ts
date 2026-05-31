import {db} from "../../startups/shared/firebase";

export const p2pOffersCollection = () => db.collection("p2p_offers");
export const p2pOfferRef = (offerId: string | number) => db.collection("p2p_offers").doc(String(offerId));
export const p2pNegotiationsCollection = (offerId: string | number) => db.collection("p2p_offers").doc(String(offerId)).collection("negotiations");

export const removeUserPrivateQuestions = async (startupName: string, userId: string): Promise<void> => {
  const query = await db.collection("startups").where("name", "==", startupName).limit(1).get();
  if (query.empty) return;
  const startupRef = query.docs[0]!.ref;

  await db.runTransaction(async (transaction) => {
    const snap = await transaction.get(startupRef);
    if (!snap.exists) return;
    const data = snap.data() || {};
    const faq = Array.isArray(data.faq) ? data.faq : [];
    const filtered = faq.filter((q: any) => !(q && typeof q === "object" && q.askerId === userId));
    if (filtered.length === faq.length) return;
    transaction.update(startupRef, {faq: filtered});
  });
};

export const cancelOverCommittedP2POffers = async (
  startupName: string,
  userId: string,
  remainingQuotas: number
): Promise<number> => {
  if (!startupName) return 0;
  const offersSnap = await db.collection("p2p_offers")
    .where("sellerId", "==", userId)
    .where("startupName", "==", startupName)
    .where("status", "==", "active")
    .get();

  if (offersSnap.empty) return 0;

  const sorted = offersSnap.docs.sort((a, b) => {
    const ta = a.data().createdAt?.toMillis?.() ?? 0;
    const tb = b.data().createdAt?.toMillis?.() ?? 0;
    return ta - tb;
  });

  let budget = remainingQuotas;
  const batch = db.batch();
  let cancelled = 0;

  for (const doc of sorted) {
    const offered = Number(doc.data().quotas) || 0;
    if (offered <= budget + 1e-6) {
      budget -= offered;
    } else {
      batch.update(doc.ref, {status: "cancelled"});
      cancelled++;
    }
  }

  if (cancelled > 0) await batch.commit();
  return cancelled;
};
