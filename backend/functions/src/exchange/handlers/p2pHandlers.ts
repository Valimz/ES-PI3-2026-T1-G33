import {onCall, HttpsError} from "firebase-functions/https";
import {FieldValue} from "firebase-admin/firestore";
import {db} from "../../startups/shared/firebase";
import {requireAuthenticatedUser} from "../../startups/shared/auth";

const formatCurrency = (value: number) => `R$ ${value.toFixed(2).replace(".", ",")}`;

const parseCurrency = (value: string) => {
  const cleanValue = value.replace(/[^0-9,.-]/g, "").replace(",", ".");
  const parsed = Number.parseFloat(cleanValue);
  return Number.isNaN(parsed) ? 0 : parsed;
};

export const createP2POffer = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);
  const asset = request.data?.asset;
  const price = request.data?.price;

  if (!asset || !asset.name || typeof price !== "number" || price <= 0) {
    throw new HttpsError("invalid-argument", "Asset e price sao obrigatorios.");
  }

  const quotasStr = asset.amount?.toString().split(" ")[0] ?? "0";
  const quotas = Number.parseFloat(quotasStr.replace(",", ".")) || 0;

  if (quotas <= 0) {
    throw new HttpsError("failed-precondition", "Cotas insuficientes.");
  }

  await db.collection("p2p_offers").add({
    sellerId: user.uid,
    startupName: asset.name,
    quotas,
    price,
    status: "active",
    createdAt: FieldValue.serverTimestamp(),
  });

  return {data: {message: "Offer created successfully"}};
});

export const makeCounterOffer = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);
  const offerId = request.data?.offerId;
  const proposedPrice = request.data?.proposedPrice;

  if (!offerId || typeof proposedPrice !== "number" || proposedPrice <= 0) {
    throw new HttpsError("invalid-argument", "offerId e proposedPrice sao obrigatorios.");
  }

  await db.collection("p2p_offers").doc(String(offerId)).collection("negotiations").doc(user.uid).set({
    buyerId: user.uid,
    proposedPrice,
    status: "pending",
    createdAt: FieldValue.serverTimestamp(),
  });

  return {data: {message: "Counter offer made successfully"}};
});

export const acceptOffer = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);
  const offerId = request.data?.offerId;
  const acceptedPrice = request.data?.acceptedPrice;
  const buyerIdParam = request.data?.buyerIdParam;
  const negotiationId = request.data?.negotiationId;

  if (!offerId) {
    throw new HttpsError("invalid-argument", "offerId e obrigatorio.");
  }

  const offerRef = db.collection("p2p_offers").doc(String(offerId));

  await db.runTransaction(async (transaction) => {
    const offerDoc = await transaction.get(offerRef);
    if (!offerDoc.exists) {
      throw new HttpsError("not-found", "Oferta nao encontrada.");
    }

    const offerData = offerDoc.data() ?? {};
    if (offerData.status !== "active") {
      throw new HttpsError("failed-precondition", "Esta oferta nao esta mais ativa.");
    }

    const sellerId = offerData.sellerId;
    const buyerId = buyerIdParam || user.uid;

    if (sellerId === buyerId) {
      throw new HttpsError("failed-precondition", "Voce nao pode comprar sua propria oferta.");
    }

    const price = acceptedPrice || offerData.price;
    const assetName = offerData.startupName;
    const quotas = offerData.quotas;

    const buyerWalletRef = db.collection("users").doc(buyerId).collection("wallet").doc("main");
    const sellerWalletRef = db.collection("users").doc(sellerId).collection("wallet").doc("main");

    const buyerWalletDoc = await transaction.get(buyerWalletRef);
    const sellerWalletDoc = await transaction.get(sellerWalletRef);

    if (!buyerWalletDoc.exists) {
      throw new HttpsError("not-found", "Carteira do comprador nao encontrada.");
    }

    if (!sellerWalletDoc.exists) {
      throw new HttpsError("not-found", "Carteira do vendedor nao encontrada.");
    }

    const buyerBalance = parseCurrency(String(buyerWalletDoc.data()?.balance ?? "R$ 0,00"));
    const sellerBalance = parseCurrency(String(sellerWalletDoc.data()?.balance ?? "R$ 0,00"));

    if (buyerBalance < price) {
      throw new HttpsError("failed-precondition", "Saldo insuficiente do comprador.");
    }

    transaction.update(buyerWalletRef, {balance: formatCurrency(buyerBalance - price)});
    transaction.update(sellerWalletRef, {balance: formatCurrency(sellerBalance + price)});

    const sellerAssetsCollection = db.collection("users").doc(sellerId).collection("assets");
    const sellerAssetsQuery = await sellerAssetsCollection.where("name", "==", assetName).get();
    if (!sellerAssetsQuery.empty) {
      const sDoc = sellerAssetsQuery.docs[0];
      const sData = sDoc.data();
      const sQuotasStr = sData.amount?.toString().split(" ")[0] ?? "0";
      const sQuotas = Number.parseFloat(sQuotasStr.replace(",", ".")) || 0;

      if (sQuotas <= quotas) {
        transaction.delete(sDoc.ref);
      } else {
        const prefix = sData.amount?.toString().split(" ").length === 2 ? ` ${sData.amount.toString().split(" ")[1]}` : " Cotas";
        const sVal = parseCurrency(String(sData.value ?? "R$ 0,00"));
        const newVal = sVal - (sVal * (quotas / sQuotas));
        transaction.update(sDoc.ref, {
          amount: `${(sQuotas - quotas).toFixed(1).replace(".", ",")}${prefix}`,
          value: formatCurrency(newVal > 0 ? newVal : 0),
        });
      }
    }

    const buyerAssetsCollection = db.collection("users").doc(buyerId).collection("assets");
    const buyerAssetsQuery = await buyerAssetsCollection.where("name", "==", assetName).get();
    if (!buyerAssetsQuery.empty) {
      const bDoc = buyerAssetsQuery.docs[0];
      const bData = bDoc.data();
      const bQuotasStr = bData.amount?.toString().split(" ")[0] ?? "0";
      const bQuotas = Number.parseFloat(bQuotasStr.replace(",", ".")) || 0;
      const prefix = bData.amount?.toString().split(" ").length === 2 ? ` ${bData.amount.toString().split(" ")[1]}` : " Cotas";
      const bVal = parseCurrency(String(bData.value ?? "R$ 0,00"));

      transaction.update(bDoc.ref, {
        amount: `${(bQuotas + quotas).toFixed(1).replace(".", ",")}${prefix}`,
        value: formatCurrency(bVal + price),
      });
    } else {
      const prefix = ` ${String(assetName).substring(0, 2).toUpperCase()}`;
      const newAssetRef = buyerAssetsCollection.doc();
      transaction.set(newAssetRef, {
        name: assetName,
        value: formatCurrency(price),
        amount: `${quotas.toFixed(1).replace(".", ",")}${prefix}`,
      });
    }

    transaction.update(offerRef, {status: "completed"});

    if (negotiationId) {
      const negRef = db.collection("p2p_offers").doc(String(offerId)).collection("negotiations").doc(String(negotiationId));
      transaction.update(negRef, {status: "accepted"});
    }
  });

  return {data: {message: "Offer accepted successfully"}};
});
