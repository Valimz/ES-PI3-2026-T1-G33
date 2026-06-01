import {onCall, HttpsError} from "firebase-functions/https";
import {db} from "../../startups/shared/firebase";
import {requireAuthenticatedUser} from "../shared/auth";
import {assetsCollectionFor, acquisitionsCollectionFor, walletRefFor, formatCurrency, parseCurrency} from "../repositories/walletRepository";

// Usando `formatCurrency` e `parseCurrency` de `walletRepository` para centralizar a logica de formatação/parsing.

const parseQuantity = (value: unknown) => {
  const raw = value?.toString().split(" ")[0] ?? "0";
  return Number.parseFloat(raw.replace(",", ".")) || 0;
};

const toIsoDate = (value: unknown) => {
  if (!value) return new Date(0).toISOString();
  if (typeof value === "string") return value;
  if (value instanceof Date) return value.toISOString();

  if (typeof value === "object" && value !== null && "toDate" in value) {
    return (value as {toDate: () => Date}).toDate().toISOString();
  }

  return new Date(0).toISOString();
};

type GraphPoint = {
  date: string;
  value: number;
  invested: number;
  quantity: number;
};

const buildSeriesFromHistory = (history: Array<Record<string, any>>, currentPrice: number): GraphPoint[] => {
  const ordered = [...history].sort(
    (left, right) => new Date(toIsoDate(left.date)).getTime() - new Date(toIsoDate(right.date)).getTime()
  );

  let quantity = 0;
  let invested = 0;

  return ordered.map((entry) => {
    const amount = parseCurrency(entry.amount?.toString() ?? "R$ 0,00");
    const quotas = parseQuantity(entry.quotas);
    const type = entry.type?.toString();

    if (type === "buy" || type === "deposit") {
      invested += amount;
      quantity += quotas;
    } else if (type === "sell") {
      invested = Math.max(0, invested - amount);
      quantity = Math.max(0, quantity - quotas);
    }

    return {
      date: toIsoDate(entry.date),
      value: quantity > 0 ? quantity * currentPrice : invested,
      invested,
      quantity,
    };
  });
};

export const getGraphSummary = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);

  const [walletDoc, assetsSnapshot, acquisitionsSnapshot, startupsSnapshot] = await Promise.all([
    walletRefFor(user.uid).get(),
    assetsCollectionFor(user.uid).get(),
    acquisitionsCollectionFor(user.uid).get(),
    db.collection("startups").get(),
  ]);

  const startupsByName = new Map<string, Record<string, any>>();
  startupsSnapshot.docs.forEach((doc) => {
    startupsByName.set(doc.data().name, {id: doc.id, ...doc.data()});
  });

  const assets: Array<Record<string, any>> = assetsSnapshot.docs.map((doc) => ({id: doc.id, ...doc.data()}));
  const currentValue = assets.reduce((sum, asset) => {
    const startup = startupsByName.get(String(asset.name ?? ""));
    const currentPrice = parseCurrency(startup?.val?.toString() ?? asset.value?.toString() ?? "R$ 0,00");
    const quantity = parseFloat((asset.amount?.toString().split(" ")[0] ?? "0").replace(",", ".")) || 0;
    return sum + quantity * currentPrice;
  }, 0);

  const totalInvested = assets.reduce((sum, asset) => sum + parseCurrency(asset.value?.toString() ?? "R$ 0,00"), 0);
  const variationReais = currentValue - totalInvested;
  const variationPercentual = totalInvested > 0 ? (variationReais / totalInvested) * 100 : 0;
  const walletBalance = walletDoc.exists ? walletDoc.data()?.balance?.toString() ?? "R$ 0,00" : "R$ 0,00";

  return {
    data: {
      walletBalance,
      totalInvested: formatCurrency(totalInvested),
      currentValue: formatCurrency(currentValue),
      variationReais: formatCurrency(variationReais),
      variationPercentual: `${variationPercentual.toFixed(2)}%`,
      assetsCount: assets.length,
      transactionsCount: acquisitionsSnapshot.size,
    },
  };
});

export const getGraphHistory = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);
  const startupNameValue = request.data?.startupName;
  const typeValue = request.data?.type;

  const startupName = typeof startupNameValue === "string" ?
    startupNameValue.trim() :
    "";
  const type = typeof typeValue === "string" ? typeValue.trim() : undefined;
  const startupNameNormalized = startupName.toLowerCase();

  let query: FirebaseFirestore.Query = acquisitionsCollectionFor(user.uid).orderBy("date", "asc");

  if (type) {
    query = query.where("type", "==", type);
  }

  const snapshot = await query.get();
  const items = snapshot.docs
    .map((doc) => ({id: doc.id, ...doc.data()}))
    .filter((entry: any) => {
      if (!startupName) return true;
      const title = String(Array.isArray(entry.title) ? entry.title.join(" ") : entry.title ?? "");
      return title.toLowerCase().includes(startupNameNormalized);
    })
    .map((entry: any) => ({
      ...entry,
      date: toIsoDate(entry.date),
    }));

  return {data: {items, count: items.length}};
});

export const getGraphAsset = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);
  const startupName = request.data?.startupName;

  if (typeof startupName !== "string" || startupName.trim().length === 0) {
    throw new HttpsError("invalid-argument", "startupName e obrigatorio.");
  }

  const [assetSnapshot, acquisitionsSnapshot, startupSnapshot] = await Promise.all([
    assetsCollectionFor(user.uid).where("name", "==", startupName).get(),
    acquisitionsCollectionFor(user.uid).orderBy("date", "asc").get(),
    db.collection("startups").where("name", "==", startupName).limit(1).get(),
  ]);

  const startupDoc = startupSnapshot.docs[0];
  const currentPrice = parseCurrency(startupDoc?.data()?.val?.toString() ?? "R$ 0,00");
  const assetDoc = assetSnapshot.docs[0];
  const asset = assetDoc ? {id: assetDoc.id, ...assetDoc.data()} : null;
  const startupNameNormalized = String(startupName).toLowerCase();
  const history = acquisitionsSnapshot.docs
    .map((doc) => ({id: doc.id, ...doc.data()}))
    .filter((entry: any) => String(entry.title ?? "").toLowerCase().includes(startupNameNormalized));

  const series = buildSeriesFromHistory(history, currentPrice);
  const lastPoint = series[series.length - 1] ?? {value: 0, invested: 0, quantity: 0};
  const variationReais = lastPoint.value - lastPoint.invested;
  const variationPercentual = lastPoint.invested > 0 ? (variationReais / lastPoint.invested) * 100 : 0;

  return {
    data: {
      startupName,
      startup: startupDoc ? {id: startupDoc.id, ...startupDoc.data()} : null,
      asset,
      currentPrice: formatCurrency(currentPrice),
      summary: {
        totalInvested: formatCurrency(lastPoint.invested),
        currentValue: formatCurrency(lastPoint.value),
        variationReais: formatCurrency(variationReais),
        variationPercentual: `${variationPercentual.toFixed(2)}%`,
        quantity: lastPoint.quantity,
      },
      series,
      historyCount: history.length,
    },
  };
});
