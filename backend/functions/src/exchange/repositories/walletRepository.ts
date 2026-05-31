import {db} from "../../startups/shared/firebase";

export const walletRefFor = (uid: string) => db.collection("users").doc(uid).collection("wallet").doc("main");

export const assetsCollectionFor = (uid: string) => db.collection("users").doc(uid).collection("assets");

export const acquisitionsCollectionFor = (uid: string) => db.collection("users").doc(uid).collection("acquisitions");

export const formatCurrency = (value: number) => `R$ ${value.toFixed(2).replace('.', ',')}`;

export const parseCurrency = (value: string) => {
  const cleanValue = value.replace(/[^0-9,.-]/g, "").replace(',', '.');
  const parsed = Number.parseFloat(cleanValue);
  return Number.isNaN(parsed) ? 0 : parsed;
};
