import {db} from "../../startups/shared/firebase";

export const p2pOffersCollection = () => db.collection('p2p_offers');
export const p2pOfferRef = (offerId: string | number) => db.collection('p2p_offers').doc(String(offerId));
export const p2pNegotiationsCollection = (offerId: string | number) => db.collection('p2p_offers').doc(String(offerId)).collection('negotiations');
