import {onCall, HttpsError} from "firebase-functions/https";
import {onSchedule} from "firebase-functions/scheduler";
import {FieldValue} from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import {requireAuthenticatedUser} from "../shared/auth";
import {formatCurrency, parseCurrency} from "../repositories/walletRepository";
import {
  listActiveStartups,
  countInvestors,
  countRecentTrades,
  getLastPriceEntry,
  persistNewPrice,
  updateInvestorAppreciation,
  PriceHistoryEntry,
} from "../repositories/valuationRepository";

const MAX_VARIATION_PERCENT = 8;
const TRADE_WINDOW_DAYS = 30;

const STAGE_MULTIPLIERS: Record<string, number> = {
  "Nova": 0.85,
  "nova": 0.85,
  "Em operação": 1.0,
  "em_operacao": 1.0,
  "Em expansão": 1.15,
  "em_expansao": 1.15,
};

function extractCurrentPriceCents(data: Record<string, unknown>): number {
  if (typeof data.currentTokenPriceCents === "number") {
    return data.currentTokenPriceCents;
  }
  const raw = String(data.val ?? "R$ 1,00");
  return Math.round(parseCurrency(raw) * 100);
}

function calculateVariation(params: {
  recentTrades: number;
  investorCount: number;
  capitalPerToken: number;
  currentPriceReais: number;
  stage: string;
}): {
  variationPercent: number;
  factors: PriceHistoryEntry["factors"];
} {
  const {recentTrades, investorCount, capitalPerToken, currentPriceReais, stage} = params;

  // Demanda: 0 a +3% (cada trade recente vale +0.3%, teto 3%)
  const demandBonus = Math.min(recentTrades * 0.3, 3);

  // Investidores: 0 a +2% (cada 5 investidores vale +0.5%, teto 2%)
  const investorBonus = Math.min(Math.floor(investorCount / 5) * 0.5, 2);

  // Capital: -2% a +2%
  // Se capital/token > preço atual → subvalorizado → positivo
  // Se capital/token < preço atual → sobrevalorizado → negativo
  let capitalBonus = 0;
  if (currentPriceReais > 0 && capitalPerToken > 0) {
    const ratio = capitalPerToken / currentPriceReais;
    if (ratio > 1) {
      capitalBonus = Math.min((ratio - 1) * 2, 2);
    } else {
      capitalBonus = Math.max((ratio - 1) * 2, -2);
    }
  }

  // Ruído: -1% a +1% (aleatório)
  const noise = (Math.random() * 2 - 1);

  // Soma dos fatores
  const rawVariation = demandBonus + investorBonus + capitalBonus + noise;

  // Multiplicador de estágio
  const stageFactor = STAGE_MULTIPLIERS[stage] ?? 1.0;
  const adjusted = rawVariation * stageFactor;

  // Limita a ±8%
  const variationPercent = Math.max(-MAX_VARIATION_PERCENT, Math.min(MAX_VARIATION_PERCENT, adjusted));

  return {
    variationPercent,
    factors: {
      demandScore: Math.round(demandBonus * 100) / 100,
      capitalScore: Math.round(capitalBonus * 100) / 100,
      investorScore: Math.round(investorBonus * 100) / 100,
      stageFactor,
      noise: Math.round(noise * 100) / 100,
    },
  };
}

export const recalculateTokenPrice = onCall(async (request) => {
  requireAuthenticatedUser(request);

  const startupId = request.data?.startupId;

  if (typeof startupId !== "string" || startupId.trim().length === 0) {
    throw new HttpsError("invalid-argument", "Informe o startupId.");
  }

  const result = await processStartupValuation(startupId.trim());

  return {data: result};
});

export const recalculateAllTokenPrices = onCall(async (request) => {
  requireAuthenticatedUser(request);

  const results = await processAllStartups();

  return {
    data: {
      count: results.length,
      startups: results,
    },
  };
});

export const scheduledTokenValuation = onSchedule(
  {
    schedule: "0 0 * * *",
    timeZone: "America/Sao_Paulo",
    retryCount: 2,
  },
  async () => {
    logger.info("Iniciando valorização agendada de tokens...");

    const results = await processAllStartups();

    logger.info("Valorização agendada finalizada.", {
      total: results.length,
      startups: results.map((r) => ({
        id: r.startupId,
        variation: r.variationPercent,
        newPrice: r.newPriceFormatted,
      })),
    });
  }
);

export const getTokenPriceHistory = onCall(async (request) => {
  requireAuthenticatedUser(request);

  const startupId = request.data?.startupId;
  const limit = typeof request.data?.limit === "number" ?
    Math.min(Math.max(request.data.limit, 1), 365) :
    30;

  if (typeof startupId !== "string" || startupId.trim().length === 0) {
    throw new HttpsError("invalid-argument", "Informe o startupId.");
  }

  const {db: firestoreDb2} = await import("../../startups/shared/firebase.js");
  const snapshot = await firestoreDb2
    .collection("startups")
    .doc(startupId.trim())
    .collection("priceHistory")
    .orderBy("createdAt", "desc")
    .limit(limit)
    .get();

  const history = snapshot.docs
    .map((doc: FirebaseFirestore.QueryDocumentSnapshot) => {
      const d = doc.data();
      return {
        id: doc.id,
        priceCents: d.priceCents,
        priceFormatted: formatCurrency(d.priceCents / 100),
        previousPriceCents: d.previousPriceCents,
        variationPercent: Math.round(d.variationPercent * 100) / 100,
        factors: d.factors,
        createdAt: d.createdAt?.toDate?.()?.toISOString?.() ?? null,
      };
    })
    .reverse();

  return {
    data: {
      startupId: startupId.trim(),
      count: history.length,
      history,
    },
  };
});

async function processStartupValuation(startupId: string) {
  const {db: firestoreDb} = await import("../../startups/shared/firebase.js");

  const startupDoc = await firestoreDb
    .collection("startups")
    .doc(startupId)
    .get();

  if (!startupDoc.exists) {
    throw new HttpsError("not-found", "Startup nao encontrada.");
  }

  const startupData = startupDoc.data() as Record<string, unknown>;
  const startupName = String(startupData.name ?? "");
  const stage = String(startupData.stage ?? "nova");
  const capitalAportado = typeof startupData.capitalAportado === "number" ?
    startupData.capitalAportado :
    0;
  const tokensEmitidos = typeof startupData.tokensEmitidos === "number" ?
    startupData.tokensEmitidos :
    typeof startupData.totalTokensIssued === "number" ?
      startupData.totalTokensIssued :
      1;

  const currentPriceCents = extractCurrentPriceCents(startupData);

  const [recentTrades, investorCount, lastEntry] = await Promise.all([
    countRecentTrades(startupName, TRADE_WINDOW_DAYS),
    countInvestors(startupId),
    getLastPriceEntry(startupId),
  ]);

  const capitalPerToken = tokensEmitidos > 0 ?
    capitalAportado / tokensEmitidos :
    0;

  const basePriceCents = lastEntry?.priceCents ?? currentPriceCents;

  const {variationPercent, factors} = calculateVariation({
    recentTrades,
    investorCount,
    capitalPerToken,
    currentPriceReais: basePriceCents / 100,
    stage,
  });

  const rawNewPrice = basePriceCents * (1 + variationPercent / 100);
  const newPriceCents = Math.max(1, Math.round(rawNewPrice));
  const newPriceFormatted = formatCurrency(newPriceCents / 100);

  const entry: PriceHistoryEntry = {
    priceCents: newPriceCents,
    previousPriceCents: basePriceCents,
    variationPercent: Math.round(variationPercent * 100) / 100,
    factors,
    createdAt: FieldValue.serverTimestamp(),
  };

  await persistNewPrice(startupId, entry, newPriceFormatted);

  try {
    await updateInvestorAppreciation(startupId, newPriceCents);
  } catch (err) {
    logger.warn("Falha ao atualizar appreciation dos investidores.", {
      startupId,
      error: String(err),
    });
  }

  logger.info("Token valorizado.", {
    startupId,
    startupName,
    previousPrice: basePriceCents,
    newPrice: newPriceCents,
    variationPercent: Math.round(variationPercent * 100) / 100,
  });

  return {
    startupId,
    startupName,
    previousPrice: formatCurrency(basePriceCents / 100),
    newPrice: newPriceFormatted,
    newPriceCents,
    variationPercent: Math.round(variationPercent * 100) / 100,
    factors,
  };
}

async function processAllStartups() {
  const startups = await listActiveStartups();

  const results: Array<Record<string, unknown>> = [];

  for (const startup of startups) {
    try {
      const result = await processStartupValuation(startup.id);
      results.push(result);
    } catch (err) {
      logger.error("Erro ao valorizar startup.", {
        startupId: startup.id,
        error: String(err),
      });
      results.push({
        startupId: startup.id,
        error: String(err),
      });
    }
  }

  return results;
}
