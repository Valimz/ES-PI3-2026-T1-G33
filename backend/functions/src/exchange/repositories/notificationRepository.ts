import {FieldValue} from "firebase-admin/firestore";
import {db} from "../../startups/shared/firebase";

export const notificationsCollectionFor = (uid: string) => db.collection("users").doc(uid).collection("notifications");
export const notificationTokensCollectionFor = (uid: string) => db.collection("users").doc(uid).collection("tokens");

export const buildNotificationPayload = (title: string, body: string, type: string, data?: Record<string, string>) => ({
  title,
  body,
  type,
  read: false,
  createdAt: FieldValue.serverTimestamp(),
  data: data || {},
});
