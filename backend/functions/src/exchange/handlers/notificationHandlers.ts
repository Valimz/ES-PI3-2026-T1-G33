import {onCall} from "firebase-functions/https";
import {FieldValue} from "firebase-admin/firestore";
import * as admin from "firebase-admin";
import {db} from "../../startups/shared/firebase";
import {requireAuthenticatedUser} from "../../startups/shared/auth";

export const registerNotificationToken = onCall(async (request) => {
  const user = requireAuthenticatedUser(request);
  const token = request.data?.token;

  if (!token || typeof token !== "string") {
    throw new Error("Token is required");
  }

  await db
    .collection("users")
    .doc(user.uid)
    .collection("tokens")
    .doc(token)
    .set({
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
    await db
      .collection("users")
      .doc(uid)
      .collection("notifications")
      .add({
        title: payload.title,
        body: payload.body,
        type: payload.type,
        read: false,
        createdAt: FieldValue.serverTimestamp(),
        data: payload.data || {},
      });

    const tokensSnapshot = await db
      .collection("users")
      .doc(uid)
      .collection("tokens")
      .get();

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
        await db.collection("users").doc(uid).collection("tokens").doc(invalidToken).delete();
      }
    }
  } catch (error) {
    console.error(`Erro ao enviar notificação para ${uid}:`, error);
  }
}
