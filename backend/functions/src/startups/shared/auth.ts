import {CallableRequest, HttpsError} from "firebase-functions/https";
import {AuthenticatedUser} from "../types";
import {db} from "./firebase";

export function requireAuthenticatedUser(
  request: CallableRequest
): AuthenticatedUser {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Usuario precisa estar autenticado para acessar esta funcao."
    );
  }

  return {
    uid: request.auth.uid,
    email: request.auth.token.email as string | undefined,
  };
}

/**
 * Similar to `requireAuthenticatedUser` but também exige que o usuário tenha
 * completado a verificação em duas etapas recentemente (se estiver habilitado).
 *
 * Lança `HttpsError('permission-denied')` quando 2FA estiver habilitado e não
 * houver evidência de uma passagem recente (`2fa_last_passed_at`).
 */
export async function requireAuthenticatedUserWith2FA(
  request: CallableRequest
): Promise<AuthenticatedUser> {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Usuario precisa estar autenticado.");
  }
  const uid = request.auth.uid;
  const email = request.auth.token.email as string | undefined;

  // Buscar dados do usuário no Firestore para checar 2FA
  const userDoc = await db.collection('users').doc(uid).get();
  const u = userDoc.data() || {};
  const enabled = u['2fa_enabled'] === true;
  if (!enabled) return {uid, email};

  const lastPassed = u['2fa_last_passed_at'];
  const windowMinutes = (process.env.TOTP_PASS_WINDOW_MINUTES ? parseInt(process.env.TOTP_PASS_WINDOW_MINUTES, 10) : 10);
  if (lastPassed && typeof lastPassed.toDate === 'function') {
    const passedDate: Date = lastPassed.toDate();
    const diff = (Date.now() - passedDate.getTime()) / 1000 / 60; // minutes
    if (diff <= windowMinutes) return {uid, email};
  }

  throw new HttpsError('permission-denied', '2FA requerida para acessar este recurso.');
}
