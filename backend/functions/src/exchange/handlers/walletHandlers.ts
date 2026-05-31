import {onCall, HttpsError} from "firebase-functions/https";
import {FieldValue} from "firebase-admin/firestore";
import {db} from "../../startups/shared/firebase";
import {requireAuthenticatedUser} from "../../startups/shared/auth";
import {sendNotification} from "./notificationHandlers";

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

// Helper: remove perguntas privadas do usuário para uma startup
const removeUserPrivateQuestions = async (startupName: string, userId: string) => {
  const query = await db.collection("startups").where("name", "==", startupName).limit(1).get();
  if (query.empty) return;
  const startupRef = query.docs[0]!.ref;

  await db.runTransaction(async (transaction) => {
    const snap = await transaction.get(startupRef);
    if (!snap.exists) return;
    const data = snap.data() || {};
    const faq = Array.isArray(data.faq) ? data.faq : [];
    const filtered = faq.filter((q: any) => !(q && typeof q === 'object' && q.askerId === userId));
    if (filtered.length === faq.length) return;
    transaction.update(startupRef, { faq: filtered });
  });
};

// Helper: cancela ofertas P2P que excedem a posição restante
const cancelOverCommittedP2POffers = async (startupName: string, userId: string, remainingQuotas: number): Promise<number> => {
  if (!startupName) return 0;
  const offersSnap = await db.collection('p2p_offers')
    .where('sellerId', '==', userId)
    .where('startupName', '==', startupName)
    .where('status', '==', 'active')
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
      batch.update(doc.ref, { status: 'cancelled' });
      cancelled++;
    }
  }

  if (cancelled > 0) await batch.commit();
  return cancelled;
};

export const withdrawFunds = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);
  const amount = request.data?.amount;

  if (typeof amount !== 'number' || amount <= 0) {
    throw new HttpsError('invalid-argument', 'Informe um valor valido para saque.');
  }

  const walletRef = db.collection('users').doc(user.uid).collection('wallet').doc('main');

  await db.runTransaction(async (transaction) => {
    const walletDoc = await transaction.get(walletRef);
    if (!walletDoc.exists) {
      throw new HttpsError('not-found', 'Carteira nao encontrada.');
    }

    const currentBalance = parseCurrency(String(walletDoc.data()?.balance ?? 'R$ 0,00'));
    if (currentBalance < amount) {
      throw new HttpsError('failed-precondition', 'Saldo insuficiente');
    }

    transaction.update(walletRef, { balance: formatCurrency(currentBalance - amount) });

    const acqRef = db.collection('users').doc(user.uid).collection('acquisitions').doc();
    transaction.set(acqRef, {
      type: 'withdraw',
      title: 'Retirada via Firebase Functions',
      amount: formatCurrency(amount),
      date: FieldValue.serverTimestamp(),
    });
  });

  // Notificar
  try {
    await sendNotification(user.uid, {
      title: 'Retirada realizada',
      body: `Você retirou ${formatCurrency(amount)} da sua carteira.`,
      type: 'deposit',
      data: { amount: String(amount) },
    });
  } catch (e) {
    console.error('Erro ao notificar saque:', e);
  }

  return {data: {message: 'Funds withdrawn successfully'}};
});

export const sellPartialAsset = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);
  const asset = request.data?.asset;
  const quotasToSell = request.data?.quotasToSell;

  if (!asset || !asset.id || typeof quotasToSell !== 'number' || quotasToSell <= 0) {
    throw new HttpsError('invalid-argument', 'Dados invalidos para venda parcial.');
  }

  const walletRef = db.collection('users').doc(user.uid).collection('wallet').doc('main');
  const assetRef = db.collection('users').doc(user.uid).collection('assets').doc(asset.id);

  let soldAssetName = '';
  let soldAll = false;
  let saleValue = 0;
  let prefix = '';
  let remainingQuotas = 0;

  await db.runTransaction(async (transaction) => {
    const walletDoc = await transaction.get(walletRef);
    const assetDoc = await transaction.get(assetRef);

    if (!walletDoc.exists) throw new HttpsError('not-found', 'Carteira nao encontrada');
    if (!assetDoc.exists) throw new HttpsError('not-found', 'Ativo nao encontrado');

    const walletData = walletDoc.data()!;
    const currentBalance = parseCurrency(walletData.balance || 'R$ 0,00');

    const assetData = assetDoc.data()!;
    const currentAssetValue = parseCurrency(assetData.value || 'R$ 0,00');
    const amountStr = assetData.amount?.toString() || '0 Tokens';
    const parts = amountStr.split(' ');
    const quotasStr = parts[0] || '0';
    prefix = parts.length === 2 ? ` ${parts[1]}` : ' Tokens';
    const currentQuotas = parseFloat(quotasStr.replace(',', '.')) || 0.0;
    soldAssetName = assetData.name?.toString() || '';

    if (currentQuotas <= 0) throw new HttpsError('failed-precondition', 'Ativo sem tokens disponiveis');
    if (quotasToSell > currentQuotas + 1e-9) {
      throw new HttpsError('failed-precondition', 'Quantidade maior do que os tokens disponiveis');
    }

    const ratio = quotasToSell / currentQuotas;
    saleValue = currentAssetValue * ratio;
    const newBalance = currentBalance + saleValue;
    transaction.update(walletRef, { balance: formatCurrency(newBalance) });

    remainingQuotas = currentQuotas - quotasToSell;
    if (remainingQuotas <= 1e-6) {
      transaction.delete(assetRef);
      soldAll = true;
    } else {
      const newValue = currentAssetValue - saleValue;
      transaction.update(assetRef, {
        value: formatCurrency(newValue > 0 ? newValue : 0),
        amount: `${remainingQuotas.toFixed(1).replace('.', ',')}${prefix}`,
      });
    }

    const acqRef = db.collection('users').doc(user.uid).collection('acquisitions').doc();
    transaction.set(acqRef, {
      type: 'sell',
      title: `Venda: ${assetData.name}`,
      amount: formatCurrency(saleValue),
      quotas: `${quotasToSell.toFixed(1).replace('.', ',')}${prefix}`,
      date: FieldValue.serverTimestamp(),
    });
  });

  if (soldAll && soldAssetName) {
    try {
      await removeUserPrivateQuestions(soldAssetName, user.uid);
    } catch (cleanupErr) {
      console.error('Falha ao limpar perguntas privadas apos venda parcial:', cleanupErr);
    }
  }

  // Cancela ofertas P2P que excedem a posicao restante
  let cancelledOffers = 0;
  try {
    cancelledOffers = await cancelOverCommittedP2POffers(soldAssetName || asset.name, user.uid, soldAll ? 0 : remainingQuotas);
  } catch (offerErr) {
    console.error('Falha ao cancelar ofertas P2P apos venda parcial:', offerErr);
  }

  // Notificacoes
  try {
    await sendNotification(user.uid, {
      title: 'Venda parcial realizada',
      body: `Voce vendeu ${quotasToSell.toFixed(1).replace('.', ',')}${prefix} de ${asset.name || 'startup'} por ${formatCurrency(saleValue)}.`,
      type: 'sell',
      data: { assetId: asset.id, quotasSold: String(quotasToSell) },
    });
  } catch (e) {
    console.error('Erro ao notificar venda parcial:', e);
  }

  if (cancelledOffers > 0) {
    try {
      await sendNotification(user.uid, {
        title: 'Oferta P2P retirada',
        body: `Sua oferta de ${asset.name || 'startup'} foi retirada do mercado por falta de tokens disponiveis.`,
        type: 'p2p_offer',
        data: { startupName: asset.name || '' },
      });
    } catch (e) {
      console.error('Erro ao notificar cancelamento de ofertas:', e);
    }
  }

  return {data: {message: 'Asset partially sold successfully', soldAll}};
});
