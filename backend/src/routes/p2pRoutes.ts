import { Router, Request, Response, NextFunction } from 'express';
import { db, auth } from '../firebaseAdmin';
import { parseCurrency, formatCurrency } from './walletRoutes';
import { sendNotification } from './notificationRoutes';

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

    // Notificar o vendedor que sua oferta foi criada
    await sendNotification(user.uid, {
      title: 'Oferta P2P criada',
      body: `Sua oferta de ${asset.name} por ${formatCurrency(price)} está ativa no mercado.`,
      type: 'p2p_offer',
      data: { startupName: asset.name, price: price.toString() },
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

    // Notificar o vendedor sobre a contraproposta
    const offerDoc = await db.collection('p2p_offers').doc(offerId).get();
    if (offerDoc.exists) {
      const offerData = offerDoc.data()!;
      await sendNotification(offerData.sellerId, {
        title: 'Nova contraproposta',
        body: `Recebeu uma contraproposta de ${formatCurrency(proposedPrice)} para ${offerData.startupName}.`,
        type: 'p2p_counter',
        data: { offerId, proposedPrice: proposedPrice.toString() },
      });
    }

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

    // Ler a oferta antes para obter sellerId/buyerId e poder fazer as queries de assets fora da transaction
    const preOfferDoc = await offerRef.get();
    if (!preOfferDoc.exists) {
      res.status(404).json({ error: 'Oferta não encontrada' });
      return;
    }
    const preOfferData = preOfferDoc.data()!;
    const sellerId = preOfferData.sellerId;
    const buyerId = buyerIdParam || user.uid;
    const assetName = preOfferData.startupName;

    // Queries de assets FORA da transaction para pegar os doc refs
    const sellerAssetsCollection = db.collection('users').doc(sellerId).collection('assets');
    const sellerAssetsQuery = await sellerAssetsCollection.where('name', '==', assetName).limit(1).get();
    const sellerAssetRef = sellerAssetsQuery.empty ? null : sellerAssetsQuery.docs[0]!.ref;

    const buyerAssetsCollection = db.collection('users').doc(buyerId).collection('assets');
    const buyerAssetsQuery = await buyerAssetsCollection.where('name', '==', assetName).limit(1).get();
    const buyerAssetRef = buyerAssetsQuery.empty ? null : buyerAssetsQuery.docs[0]!.ref;

    await db.runTransaction(async (transaction) => {
      const offerDoc = await transaction.get(offerRef);
      if (!offerDoc.exists) throw new Error("Oferta não encontrada");

      const offerData = offerDoc.data()!;
      if (offerData.status !== 'active') throw new Error("Esta oferta não está mais ativa.");

      if (sellerId === buyerId) throw new Error("Você não pode comprar sua própria oferta.");

      const price = acceptedPrice || offerData.price;
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

      // Remover/atualizar o ativo do vendedor
      if (sellerAssetRef) {
        const sDoc = await transaction.get(sellerAssetRef);
        if (sDoc.exists) {
          const sData = sDoc.data()!;
          const sQuotasStr = sData.amount?.toString().split(' ')[0] || '0';
          const sQuotas = parseFloat(sQuotasStr.replace(',', '.')) || 0.0;
          
          if (sQuotas <= quotas) { 
            transaction.delete(sellerAssetRef);
          } else {
            const prefix = sData.amount?.toString().split(' ').length === 2 ? ` ${sData.amount.toString().split(' ')[1]}` : ' Cotas';
            const sVal = parseCurrency(sData.value?.toString() || 'R$ 0,00');
            const newVal = sVal - (sVal * (quotas/sQuotas));
            transaction.update(sellerAssetRef, {
              amount: `${(sQuotas - quotas).toFixed(1).replace('.', ',')}${prefix}`,
              value: formatCurrency(newVal > 0 ? newVal : 0)
            });
          }
        }
      }

      // Adicionar/atualizar o ativo do comprador
      if (buyerAssetRef) {
        const bDoc = await transaction.get(buyerAssetRef);
        if (bDoc.exists) {
          const bData = bDoc.data()!;
          const bQuotasStr = bData.amount?.toString().split(' ')[0] || '0';
          const bQuotas = parseFloat(bQuotasStr.replace(',', '.')) || 0.0;
          const prefix = bData.amount?.toString().split(' ').length === 2 ? ` ${bData.amount.toString().split(' ')[1]}` : ' Cotas';
          const bVal = parseCurrency(bData.value?.toString() || 'R$ 0,00');

          transaction.update(buyerAssetRef, {
            amount: `${(bQuotas + quotas).toFixed(1).replace('.', ',')}${prefix}`,
            value: formatCurrency(bVal + price)
          });
        }
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

    const finalPrice = acceptedPrice || preOfferData.price || 0;

    // Notificar vendedor
    if (sellerId) {
      await sendNotification(sellerId, {
        title: 'Oferta P2P concluída',
        body: `Sua oferta de ${assetName} foi aceita por ${formatCurrency(finalPrice)}.`,
        type: 'p2p_accepted',
        data: { offerId, startupName: assetName },
      });
    }

    // Notificar comprador
    if (buyerId && buyerId !== sellerId) {
      await sendNotification(buyerId, {
        title: 'Compra P2P realizada',
        body: `Você adquiriu ${assetName} por ${formatCurrency(finalPrice)} no mercado P2P.`,
        type: 'p2p_accepted',
        data: { offerId, startupName: assetName },
      });
    }

    res.status(200).json({ message: 'Offer accepted successfully' });
  } catch (error: any) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

export default router;
