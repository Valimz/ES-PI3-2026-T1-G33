import {HttpsError, onCall} from "firebase-functions/https";
import {allowedStages} from "../shared/constants";
import {requireAuthenticatedUser} from "../shared/auth";
import {normalizeString} from "../shared/validation";
import {listStartupItems} from "../repositories/startupRepository";

const normalizeStage = (value: string) => {
  const raw = value.trim().toLowerCase();

  if (raw === "nova") return "nova";
  if (raw === "em_operacao" || raw === "em operação") return "em_operacao";
  if (raw === "em_expansao" || raw === "em expansão") return "em_expansao";

  return raw;
};
/**
 * Lista as startups cadastradas no catálogo do MesclaInvest.
 *
 * Esta Function é callable porque será consumida diretamente pelo app mobile.
 * O app pode enviar, em `data`, os campos:
 *
 * - `stage`: filtro opcional por estágio.
 * - `search`: texto opcional para buscar no catálogo.
 *
 * A função exige usuário autenticado e retorna um objeto com:
 *
 * - `count`: quantidade de startups retornadas.
 * - `filters`: filtros aplicados e estágios disponíveis.
 * - `data`: lista resumida de startups para uso em telas de catálogo.
*/
export const listStartups = onCall(async (request) => {
  requireAuthenticatedUser(request);

  const stage = normalizeString(request.data?.stage);
  const normalizedStage = stage ? normalizeStage(stage) : undefined;

  const search = normalizeString(request.data?.search)
    ?.toLocaleLowerCase("pt-BR");

  if (normalizedStage && !allowedStages.includes(normalizedStage as any)) {
    throw new HttpsError(
      "invalid-argument",
      "Filtro stage invalido. Use nova, em_operacao ou em_expansao."
    );
  }

  const startups = (await listStartupItems())
    .filter((startup) => !normalizedStage || normalizeStage(String(startup.stage)) === normalizedStage)
    .filter((startup) => {
      if (!search) {
        return true;
      }

      const searchable = [
        startup.name,
        startup.shortDescription,
        startup.stage,
        ...startup.tags,
      ].join(" ").toLocaleLowerCase("pt-BR");

      return searchable.includes(search);
    })
    .sort((left, right) => left.name.localeCompare(right.name, "pt-BR"));

  return {
    count: startups.length,
    filters: {
      availableStages: allowedStages,
      stage: stage ?? null,
      search: search ?? null,
    },
    data: startups,
  };
});
