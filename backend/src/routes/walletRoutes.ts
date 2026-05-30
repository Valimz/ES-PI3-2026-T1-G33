import { Router, Request, Response, NextFunction } from 'express';
import { db, auth } from '../firebaseAdmin';
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
    (req as any).user = decoded; // injeta o usuário no request
    next();
  } catch (error) {
    res.status(401).json({ error: 'Unauthorized: Invalid token' });
  }
};

// Função utilitária básica para formatar Real igual no Flutter
export const formatCurrency = (val: number) => {
  let formated = val.toFixed(2).replace('.', ',');
  return `R$ ${formated}`;
};

export const parseCurrency = (val: string) => {
  const cleanString = val.replace(/[^0-9,]/g, '').replace(',', '.');
  const parsed = parseFloat(cleanString);
  return isNaN(parsed) ? 0.0 : parsed;
};

const removeUserPrivateQuestions = async (startupName: string, userId: string) => {
  const query = await db
    .collection('startups')
    .where('name', '==', startupName)
    .limit(1)
    .get();

  if (query.empty) return;
  const startupRef = query.docs[0]!.ref;

  await db.runTransaction(async (transaction) => {
    const snap = await transaction.get(startupRef);
    if (!snap.exists) return;
    const data = snap.data() || {};
    const faq = Array.isArray(data.faq) ? data.faq : [];
    const filtered = faq.filter((q: any) =>
      !(q && typeof q === 'object' && q.askerId === userId)
    );
    if (filtered.length === faq.length) return;
    transaction.update(startupRef, { faq: filtered });
  });
};

// Rota de Depositar
router.post('/addFunds', requireAuth, async (req: Request, res: Response) => {
  try {
    const user = (req as any).user;
    const { amount } = req.body;
    
    if (typeof amount !== 'number' || amount <= 0) {
      res.status(400).json({ error: 'Invalid amount' });
      return;
    }

    const walletRef = db.collection('users').doc(user.uid).collection('wallet').doc('main');

    await db.runTransaction(async (transaction) => {
      const walletDoc = await transaction.get(walletRef);
      
      let newBalanceNum = amount;
      if (!walletDoc.exists) {
        transaction.set(walletRef, {
          balance: formatCurrency(amount),
          appreciation: '+ 0,0%'
        });
      } else {
        const data = walletDoc.data()!;
        const currentBalance = parseCurrency(data.balance || 'R$ 0,00');
        newBalanceNum = currentBalance + amount;
        transaction.update(walletRef, {
          balance: formatCurrency(newBalanceNum)
        });
      }

      // Histórico
      const acqRef = db.collection('users').doc(user.uid).collection('acquisitions').doc();
      transaction.set(acqRef, {
        type: 'deposit',
        title: 'Depósito via TS Server',
        amount: formatCurrency(amount),
        date: new Date() // No admin SDK we use Date or FieldValue
      });
    });

    // Enviar notificação
    await sendNotification(user.uid, {
      title: 'Depósito realizado',
      body: `Você adicionou ${formatCurrency(amount)} à sua carteira.`,
      type: 'deposit',
      data: { amount: amount.toString() },
    });

    res.status(200).json({ message: 'Funds added successfully' });
  } catch (error: any) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// Rota para comprar ativo
router.post('/buy', requireAuth, async (req: Request, res: Response) => {
  try {
    const user = (req as any).user;
    const { startup, amountToBuy } = req.body;
    
    if (!startup || !startup.name || typeof amountToBuy !== 'number' || amountToBuy <= 0) {
      res.status(400).json({ error: 'Invalid input data' });
      return;
    }

    const walletRef = db.collection('users').doc(user.uid).collection('wallet').doc('main');
    const assetsCollection = db.collection('users').doc(user.uid).collection('assets');
    
    // Query FORA da transaction para encontrar o doc ref do ativo existente
    const existingAssetQuery = await assetsCollection.where('name', '==', startup.name).limit(1).get();
    const existingAssetRef = existingAssetQuery.empty ? null : existingAssetQuery.docs[0]!.ref;

    await db.runTransaction(async (transaction) => {
      const walletDoc = await transaction.get(walletRef);
      if (!walletDoc.exists) throw new Error("Carteira não encontrada");

      const assetDoc = existingAssetRef ? await transaction.get(existingAssetRef) : null;

      const walletData = walletDoc.data()!;
      const currentBalance = parseCurrency(walletData.balance || 'R$ 0,00');

      if (currentBalance < amountToBuy) {
        throw new Error("Saldo insuficiente");
      }

      const startupPrice = parseCurrency(startup.val || 'R$ 1,00');
      const quotasToBuy = amountToBuy / (startupPrice > 0 ? startupPrice : 1);
      const prefix = ` ${startup.name.substring(0, 2).toUpperCase()}`;

      const newBalance = currentBalance - amountToBuy;
      transaction.update(walletRef, {
        balance: formatCurrency(newBalance)
      });

      if (existingAssetRef && assetDoc) {
        const assetData = assetDoc.data()!;

        const currentAssetValue = parseCurrency(assetData.value || 'R$ 0,00');
        const quotasStr = assetData.amount?.toString().split(' ')[0] || '0';
        const currentQuotas = parseFloat(quotasStr.replace(',', '.')) || 0.0;

        const newQuotas = currentQuotas + quotasToBuy;
        const existingPrefix = assetData.amount?.toString().split(' ').length === 2 ? ` ${assetData.amount.toString().split(' ')[1]}` : ' Tokens';

        transaction.update(existingAssetRef, {
          value: formatCurrency(currentAssetValue + amountToBuy),
          amount: `${newQuotas.toFixed(1).replace('.', ',')}${existingPrefix}`
        });
      } else {
        const docRef = assetsCollection.doc();
        transaction.set(docRef, {
          name: startup.name,
          value: formatCurrency(amountToBuy),
          amount: `${quotasToBuy.toFixed(1).replace('.', ',')}${prefix}`
        });
      }

      // Salva o histórico da compra
      const acquisitionRef = db.collection('users').doc(user.uid).collection('acquisitions').doc();
      transaction.set(acquisitionRef, {
        type: 'buy',
        title: `Compra: ${startup.name}`,
        amount: formatCurrency(amountToBuy),
        quotas: `${quotasToBuy.toFixed(1).replace('.', ',')}${prefix}`,
        date: new Date()
      });
    });

    // Enviar notificação
    await sendNotification(user.uid, {
      title: 'Compra realizada',
      body: `Você investiu ${formatCurrency(amountToBuy)} em ${startup.name}.`,
      type: 'buy',
      data: { startupName: startup.name, amount: amountToBuy.toString() },
    });

    res.status(200).json({ message: 'Asset purchased successfully' });
  } catch (error: any) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// Rota para vender ativo inteiro
router.post('/sell', requireAuth, async (req: Request, res: Response) => {
  try {
    const user = (req as any).user;
    const { asset } = req.body;
    
    if (!asset || !asset.id) {
      res.status(400).json({ error: 'Invalid asset data' });
      return;
    }

    const walletRef = db.collection('users').doc(user.uid).collection('wallet').doc('main');
    const assetRef = db.collection('users').doc(user.uid).collection('assets').doc(asset.id);

    let soldAssetName = '';

    await db.runTransaction(async (transaction) => {
      const walletDoc = await transaction.get(walletRef);
      const assetDoc = await transaction.get(assetRef);

      if (!walletDoc.exists) throw new Error("Carteira não encontrada");
      if (!assetDoc.exists) throw new Error("Ativo não encontrado");

      const walletData = walletDoc.data()!;
      const currentBalance = parseCurrency(walletData.balance || 'R$ 0,00');

      const assetData = assetDoc.data()!;
      const currentAssetValue = parseCurrency(assetData.value || 'R$ 0,00');
      const quotasStr = assetData.amount?.toString() || '0 Tokens';
      soldAssetName = assetData.name?.toString() || '';

      const newBalance = currentBalance + currentAssetValue;
      transaction.update(walletRef, {
        balance: formatCurrency(newBalance)
      });

      transaction.delete(assetRef);

      const acquisitionRef = db.collection('users').doc(user.uid).collection('acquisitions').doc();
      transaction.set(acquisitionRef, {
        type: 'sell',
        title: `Venda: ${assetData.name}`,
        amount: formatCurrency(currentAssetValue),
        quotas: quotasStr,
        date: new Date()
      });
    });

    if (soldAssetName) {
      try {
        await removeUserPrivateQuestions(soldAssetName, user.uid);
      } catch (cleanupErr) {
        console.error('Falha ao limpar perguntas privadas após venda:', cleanupErr);
      }
    }

    await sendNotification(user.uid, {
      title: 'Venda realizada',
      body: `Você vendeu seus ativos de ${asset.name || 'startup'}.`,
      type: 'sell',
      data: { assetId: asset.id },
    });

    res.status(200).json({ message: 'Asset sold successfully' });
  } catch (error: any) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// Rota para retirar saldo
router.post('/withdraw', requireAuth, async (req: Request, res: Response) => {
  try {
    const user = (req as any).user;
    const { amount } = req.body;

    if (typeof amount !== 'number' || amount <= 0) {
      res.status(400).json({ error: 'Invalid amount' });
      return;
    }

    const walletRef = db.collection('users').doc(user.uid).collection('wallet').doc('main');

    await db.runTransaction(async (transaction) => {
      const walletDoc = await transaction.get(walletRef);
      if (!walletDoc.exists) throw new Error('Carteira não encontrada');

      const data = walletDoc.data()!;
      const currentBalance = parseCurrency(data.balance || 'R$ 0,00');

      if (currentBalance < amount) {
        throw new Error('Saldo insuficiente');
      }

      const newBalance = currentBalance - amount;
      transaction.update(walletRef, { balance: formatCurrency(newBalance) });

      const acqRef = db.collection('users').doc(user.uid).collection('acquisitions').doc();
      transaction.set(acqRef, {
        type: 'withdraw',
        title: 'Retirada via TS Server',
        amount: formatCurrency(amount),
        date: new Date()
      });
    });

    await sendNotification(user.uid, {
      title: 'Retirada realizada',
      body: `Você retirou ${formatCurrency(amount)} da sua carteira.`,
      type: 'deposit',
      data: { amount: amount.toString() },
    });

    res.status(200).json({ message: 'Funds withdrawn successfully' });
  } catch (error: any) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// Rota para vender parte de um ativo
router.post('/sellPartial', requireAuth, async (req: Request, res: Response) => {
  try {
    const user = (req as any).user;
    const { asset, quotasToSell } = req.body;

    if (!asset || !asset.id || typeof quotasToSell !== 'number' || quotasToSell <= 0) {
      res.status(400).json({ error: 'Invalid input data' });
      return;
    }

    const walletRef = db.collection('users').doc(user.uid).collection('wallet').doc('main');
    const assetRef = db.collection('users').doc(user.uid).collection('assets').doc(asset.id);

    let soldAssetName = '';
    let soldAll = false;
    let saleValue = 0;
    let prefix = '';
    let remainingQuotas = 0;

    await db.runTransaction(async (transaction) => {
      const walletDoc = await transaction.get(walletRef);
      const assetDoc = await transaction.get(assetRef);

      if (!walletDoc.exists) throw new Error('Carteira não encontrada');
      if (!assetDoc.exists) throw new Error('Ativo não encontrado');

      const walletData = walletDoc.data()!;
      const currentBalance = parseCurrency(walletData.balance || 'R$ 0,00');

      const assetData = assetDoc.data()!;
      const currentAssetValue = parseCurrency(assetData.value || 'R$ 0,00');
      const amountStr = assetData.amount?.toString() || '0 Tokens';
      const parts = amountStr.split(' ');
      const quotasStr = parts[0] || '0';
      prefix = parts.length === 2 ? ` ${parts[1]}` : ' Tokens';
      const currentQuotas = parseFloat(quotasStr.replace(',', '.')) || 0.0;
      soldAssetName = assetData.name?.toString() || '';

      if (currentQuotas <= 0) throw new Error('Ativo sem tokens disponíveis');
      if (quotasToSell > currentQuotas + 1e-9) {
        throw new Error('Quantidade maior do que os tokens disponíveis');
      }

      const ratio = quotasToSell / currentQuotas;
      saleValue = currentAssetValue * ratio;
      const newBalance = currentBalance + saleValue;
      transaction.update(walletRef, { balance: formatCurrency(newBalance) });

      remainingQuotas = currentQuotas - quotasToSell;
      if (remainingQuotas <= 1e-6) {
        transaction.delete(assetRef);
        soldAll = true;
      } else {
        const newValue = currentAssetValue - saleValue;
        transaction.update(assetRef, {
          value: formatCurrency(newValue > 0 ? newValue : 0),
          amount: `${remainingQuotas.toFixed(1).replace('.', ',')}${prefix}`,
        });
      }

      const acqRef = db.collection('users').doc(user.uid).collection('acquisitions').doc();
      transaction.set(acqRef, {
        type: 'sell',
        title: `Venda: ${assetData.name}`,
        amount: formatCurrency(saleValue),
        quotas: `${quotasToSell.toFixed(1).replace('.', ',')}${prefix}`,
        date: new Date(),
      });
    });

    if (soldAll && soldAssetName) {
      try {
        await removeUserPrivateQuestions(soldAssetName, user.uid);
      } catch (cleanupErr) {
        console.error('Falha ao limpar perguntas privadas após venda parcial:', cleanupErr);
      }
    }

    await sendNotification(user.uid, {
      title: 'Venda parcial realizada',
      body: `Você vendeu ${quotasToSell.toFixed(1).replace('.', ',')}${prefix} de ${asset.name || 'startup'} por ${formatCurrency(saleValue)}.`,
      type: 'sell',
      data: { assetId: asset.id, quotasSold: quotasToSell.toString() },
    });

    res.status(200).json({ message: 'Asset partially sold successfully', soldAll });
  } catch (error: any) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

export default router;
