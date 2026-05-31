import {onCall} from "firebase-functions/https";
import {FieldValue} from "firebase-admin/firestore";
import * as admin from "firebase-admin";
import {requireAuthenticatedUser} from "../shared/auth";
import {buildNotificationPayload, notificationTokensCollectionFor, notificationsCollectionFor} from "../repositories/notificationRepository";

export const registerNotificationToken = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);
  const token = request.data?.token;

  if (!token || typeof token !== "string") {
    throw new Error("Token is required");
  }

  await notificationTokensCollectionFor(user.uid).doc(token).set({
    token,
    updatedAt: FieldValue.serverTimestamp(),
    platform: "android",
  });

  return {data: {message: "Token registered successfully"}};
});

export type NotificationPayload = {
  title: string;
  body: string;
  type: "deposit" | "buy" | "sell" | "p2p_offer" | "p2p_accepted" | "p2p_counter" | "system";
  data?: Record<string, string>;
};

export async function sendNotification(uid: string, payload: NotificationPayload): Promise<void> {
  try {
    await notificationsCollectionFor(uid).add(
      buildNotificationPayload(payload.title, payload.body, payload.type, payload.data)
    );

    const tokensSnapshot = await notificationTokensCollectionFor(uid).get();

    if (tokensSnapshot.empty) {
      return;
    }

    const tokens = tokensSnapshot.docs.map((doc) => doc.data().token as string);

    const message: admin.messaging.MulticastMessage = {
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: {
        type: payload.type,
        ...(payload.data || {}),
      },
      android: {
        priority: "high",
        notification: {
          channelId: "mescla_invest_channel",
          priority: "high",
          defaultSound: true,
        },
      },
      tokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);

    if (response.failureCount > 0) {
      const tokensToRemove: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const errorCode = resp.error?.code;
          if (
            errorCode === "messaging/invalid-registration-token" ||
            errorCode === "messaging/registration-token-not-registered"
          ) {
            tokensToRemove.push(tokens[idx]!);
          }
        }
      });

      for (const invalidToken of tokensToRemove) {
        await notificationTokensCollectionFor(uid).doc(invalidToken).delete();
      }
    }
  } catch (error) {
    console.error(`Erro ao enviar notificação para ${uid}:`, error);
  }
}
