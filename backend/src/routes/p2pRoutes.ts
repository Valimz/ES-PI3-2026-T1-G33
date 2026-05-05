import { Router, Request, Response, NextFunction } from 'express';
import { db, auth } from '../firebaseAdmin';
import { parseCurrency, formatCurrency } from './walletRoutes';

const router = Router();

// Middleware simplificado para REST API
const requireAuth = async (req: Request, res: Response, next: NextFunction) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
     res.status(401).json({ error: 'Unauthorized: Missing token' });
     return;
  }
  
  const token = authHeader.split('Bearer ')[1]!;
  try {
    const decoded = await auth.verifyIdToken(token);
    (req as any).user = decoded;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Unauthorized: Invalid token' });
  }
};

// Rota para criar oferta P2P
router.post('/createOffer', requireAuth, async (req: Request, res: Response) => {
  try {
    const user = (req as any).user;
    const { asset, price } = req.body;
    
    if (!asset || !asset.name || typeof price !== 'number' || price <= 0) {
      res.status(400).json({ error: 'Invalid input data' });
      return;
    }

    const quotasStr = asset.amount?.toString().split(' ')[0] || '0';
    const quotas = parseFloat(quotasStr.replace(',', '.')) || 0.0;
    if (quotas <= 0) throw new Error("Cotas insuficientes");

    await db.collection('p2p_offers').add({
      sellerId: user.uid,
      startupName: asset.name,
      quotas: quotas,
      price: price,
      status: 'active',
      createdAt: new Date()
    });

    res.status(200).json({ message: 'Offer created successfully' });
  } catch (error: any) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// Rota para fazer contraproposta
router.post('/makeCounterOffer', requireAuth, async (req: Request, res: Response) => {
  try {
    const user = (req as any).user;
    const { offerId, proposedPrice } = req.body;
    
    if (!offerId || typeof proposedPrice !== 'number' || proposedPrice <= 0) {
      res.status(400).json({ error: 'Invalid input data' });
      return;
    }

    await db.collection('p2p_offers').doc(offerId).collection('negotiations').doc(user.uid).set({
      buyerId: user.uid,
      proposedPrice: proposedPrice,
      status: 'pending',
      createdAt: new Date()
    });

    res.status(200).json({ message: 'Counter offer made successfully' });
  } catch (error: any) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// Rota para aceitar oferta P2P
router.post('/acceptOffer', requireAuth, async (req: Request, res: Response) => {
  try {
    const user = (req as any).user;
    const { offerId, acceptedPrice, buyerIdParam, negotiationId } = req.body;
    
    if (!offerId) {
      res.status(400).json({ error: 'Invalid offerId' });
      return;
    }

    const offerRef = db.collection('p2p_offers').doc(offerId);

    await db.runTransaction(async (transaction) => {
      const offerDoc = await transaction.get(offerRef);
      if (!offerDoc.exists) throw new Error("Oferta não encontrada");

      const offerData = offerDoc.data()!;
      if (offerData.status !== 'active') throw new Error("Esta oferta não está mais ativa.");

      const sellerId = offerData.sellerId;
      const buyerId = buyerIdParam || user.uid;

      if (sellerId === buyerId) throw new Error("Você não pode comprar sua própria oferta.");

      const price = acceptedPrice || offerData.price;
      const assetName = offerData.startupName;
      const quotas = offerData.quotas;

      const buyerWalletRef = db.collection('users').doc(buyerId).collection('wallet').doc('main');
      const sellerWalletRef = db.collection('users').doc(sellerId).collection('wallet').doc('main');
      
      const buyerWalletDoc = await transaction.get(buyerWalletRef);
      const sellerWalletDoc = await transaction.get(sellerWalletRef);

      if (!buyerWalletDoc.exists) throw new Error("Carteira do comprador não encontrada");
      if (!sellerWalletDoc.exists) throw new Error("Carteira do vendedor não encontrada");

      const buyerBalance = parseCurrency(buyerWalletDoc.data()!.balance || 'R$ 0,00');
      const sellerBalance = parseCurrency(sellerWalletDoc.data()!.balance || 'R$ 0,00');

      if (buyerBalance < price) throw new Error("Saldo insuficiente do comprador");

      // Transferência de dinheiro
      transaction.update(buyerWalletRef, { balance: formatCurrency(buyerBalance - price) });
      transaction.update(sellerWalletRef, { balance: formatCurrency(sellerBalance + price) });

      // Remover o ativo do vendedor
      const sellerAssetsCollection = db.collection('users').doc(sellerId).collection('assets');
      const sellerAssetsQuery = await sellerAssetsCollection.where('name', '==', assetName).get();
      if (!sellerAssetsQuery.empty) {
        const sDoc = sellerAssetsQuery.docs[0];
        const sData = sDoc.data();
        const sQuotasStr = sData.amount?.toString().split(' ')[0] || '0';
        const sQuotas = parseFloat(sQuotasStr.replace(',', '.')) || 0.0;
        
        if (sQuotas <= quotas) { 
          transaction.delete(sDoc.reference);
        } else {
          const prefix = sData.amount?.toString().split(' ').length === 2 ? ` ${sData.amount.toString().split(' ')[1]}` : ' Cotas';
          const sVal = parseCurrency(sData.value?.toString() || 'R$ 0,00');
          const newVal = sVal - (sVal * (quotas/sQuotas));
          transaction.update(sDoc.reference, {
            amount: `${(sQuotas - quotas).toFixed(1).replace('.', ',')}${prefix}`,
            value: formatCurrency(newVal > 0 ? newVal : 0)
          });
        }
      }

      // Adicionar o ativo ao comprador
      const buyerAssetsCollection = db.collection('users').doc(buyerId).collection('assets');
      const buyerAssetsQuery = await buyerAssetsCollection.where('name', '==', assetName).get();
      if (!buyerAssetsQuery.empty) {
        const bDoc = buyerAssetsQuery.docs[0];
        const bData = bDoc.data();
        const bQuotasStr = bData.amount?.toString().split(' ')[0] || '0';
        const bQuotas = parseFloat(bQuotasStr.replace(',', '.')) || 0.0;
        const prefix = bData.amount?.toString().split(' ').length === 2 ? ` ${bData.amount.toString().split(' ')[1]}` : ' Cotas';
        const bVal = parseCurrency(bData.value?.toString() || 'R$ 0,00');

        transaction.update(bDoc.reference, {
          amount: `${(bQuotas + quotas).toFixed(1).replace('.', ',')}${prefix}`,
          value: formatCurrency(bVal + price)
        });
      } else {
         const prefix = ` ${assetName.substring(0, 2).toUpperCase()}`;
         const newAssetRef = buyerAssetsCollection.doc();
         transaction.set(newAssetRef, {
           name: assetName,
           value: formatCurrency(price),
           amount: `${quotas.toFixed(1).replace('.', ',')}${prefix}`
         });
      }

      // Marcar oferta como concluída
      transaction.update(offerRef, { status: 'completed' });

      // Se foi uma contraproposta aceita, marcar negociação como aceita
      if (negotiationId) {
        const negRef = db.collection('p2p_offers').doc(offerId).collection('negotiations').doc(negotiationId);
        transaction.update(negRef, { status: 'accepted' });
      }
    });

    res.status(200).json({ message: 'Offer accepted successfully' });
  } catch (error: any) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

export default router;
