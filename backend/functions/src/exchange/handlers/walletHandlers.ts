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

export const addFunds = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);
  const amount = request.data?.amount;

  if (typeof amount !== "number" || amount <= 0) {
    throw new HttpsError("invalid-argument", "Informe um valor valido para depositar.");
  }

  const walletRef = db.collection("users").doc(user.uid).collection("wallet").doc("main");

  await db.runTransaction(async (transaction) => {
    const walletDoc = await transaction.get(walletRef);
    const currentBalance = walletDoc.exists
      ? parseCurrency(String(walletDoc.data()?.balance ?? "R$ 0,00"))
      : 0;

    transaction.set(walletRef, {
      balance: formatCurrency(currentBalance + amount),
      appreciation: "+ 0,0%",
    }, {merge: true});

    const acquisitionRef = db.collection("users").doc(user.uid).collection("acquisitions").doc();
    transaction.set(acquisitionRef, {
      type: "deposit",
      title: "Depósito via Firebase Functions",
      amount: formatCurrency(amount),
      date: FieldValue.serverTimestamp(),
    });
  });

  return {data: {message: "Funds added successfully"}};
});

export const buyAsset = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);
  const startup = request.data?.startup;
  const amountToBuy = request.data?.amountToBuy;

  if (!startup || !startup.name || typeof amountToBuy !== "number" || amountToBuy <= 0) {
    throw new HttpsError("invalid-argument", "Startup e amountToBuy sao obrigatorios.");
  }

  const walletRef = db.collection("users").doc(user.uid).collection("wallet").doc("main");
  const assetsCollection = db.collection("users").doc(user.uid).collection("assets");

  await db.runTransaction(async (transaction) => {
    const walletDoc = await transaction.get(walletRef);

    if (!walletDoc.exists) {
      throw new HttpsError("not-found", "Carteira nao encontrada.");
    }

    const currentBalance = parseCurrency(String(walletDoc.data()?.balance ?? "R$ 0,00"));

    if (currentBalance < amountToBuy) {
      throw new HttpsError("failed-precondition", "Saldo insuficiente.");
    }

    const startupPrice = parseCurrency(String(startup.val ?? "R$ 1,00"));
    const quotasToBuy = amountToBuy / (startupPrice > 0 ? startupPrice : 1);
    const prefix = ` ${String(startup.name).substring(0, 2).toUpperCase()}`;

    transaction.update(walletRef, {
      balance: formatCurrency(currentBalance - amountToBuy),
    });

    const querySnapshot = await assetsCollection.where("name", "==", startup.name).get();

    if (!querySnapshot.empty) {
      const assetDoc = querySnapshot.docs[0];
      const assetData = assetDoc.data();
      const currentAssetValue = parseCurrency(String(assetData.value ?? "R$ 0,00"));
      const quotasStr = assetData.amount?.toString().split(" ")[0] ?? "0";
      const currentQuotas = Number.parseFloat(quotasStr.replace(",", ".")) || 0;
      const newQuotas = currentQuotas + quotasToBuy;
      const existingPrefix = assetData.amount?.toString().split(" ").length === 2 ? ` ${assetData.amount.toString().split(" ")[1]}` : " Cotas";

      transaction.update(assetDoc.ref, {
        value: formatCurrency(currentAssetValue + amountToBuy),
        amount: `${newQuotas.toFixed(1).replace(".", ",")}${existingPrefix}`,
      });
    } else {
      const assetRef = assetsCollection.doc();
      transaction.set(assetRef, {
        name: startup.name,
        value: formatCurrency(amountToBuy),
        amount: `${quotasToBuy.toFixed(1).replace(".", ",")}${prefix}`,
      });
    }

    const acquisitionRef = db.collection("users").doc(user.uid).collection("acquisitions").doc();
    transaction.set(acquisitionRef, {
      type: "buy",
      title: `Compra: ${startup.name}`,
      amount: formatCurrency(amountToBuy),
      quotas: `${quotasToBuy.toFixed(1).replace(".", ",")}${prefix}`,
      date: FieldValue.serverTimestamp(),
    });
  });

  return {data: {message: "Asset purchased successfully"}};
});

export const sellAsset = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);
  const asset = request.data?.asset;

  if (!asset || !asset.id) {
    throw new HttpsError("invalid-argument", "Informe o ativo a ser vendido.");
  }

  const walletRef = db.collection("users").doc(user.uid).collection("wallet").doc("main");
  const assetRef = db.collection("users").doc(user.uid).collection("assets").doc(asset.id);

  await db.runTransaction(async (transaction) => {
    const walletDoc = await transaction.get(walletRef);
    const assetDoc = await transaction.get(assetRef);

    if (!walletDoc.exists) {
      throw new HttpsError("not-found", "Carteira nao encontrada.");
    }

    if (!assetDoc.exists) {
      throw new HttpsError("not-found", "Ativo nao encontrado.");
    }

    const currentBalance = parseCurrency(String(walletDoc.data()?.balance ?? "R$ 0,00"));
    const assetData = assetDoc.data() ?? {};
    const currentAssetValue = parseCurrency(String(assetData.value ?? "R$ 0,00"));
    const quotasStr = assetData.amount?.toString() ?? "0 Cotas";

    transaction.update(walletRef, {
      balance: formatCurrency(currentBalance + currentAssetValue),
    });

    transaction.delete(assetRef);

    const acquisitionRef = db.collection("users").doc(user.uid).collection("acquisitions").doc();
    transaction.set(acquisitionRef, {
      type: "sell",
      title: `Venda: ${assetData.name}`,
      amount: formatCurrency(currentAssetValue),
      quotas: quotasStr,
      date: FieldValue.serverTimestamp(),
    });
  });

  return {data: {message: "Asset sold successfully"}};
});
