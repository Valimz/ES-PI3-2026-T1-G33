import { Router, Request, Response, NextFunction } from 'express';
import { db, auth } from '../firebaseAdmin';
import * as admin from 'firebase-admin';

const router = Router();

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

const isInvestor = async (uid: string, startupId: string): Promise<boolean> => {
  const snapshot = await db
    .collection('users')
    .doc(uid)
    .collection('assets')
    .where('name', '==', startupId)
    .limit(1)
    .get();
  return !snapshot.empty;
};

router.get('/:startupId/public', requireAuth, async (req: Request, res: Response) => {
  try {
    const { startupId } = req.params;

    const snapshot = await db
      .collection('questions')
      .where('startupId', '==', startupId)
      .where('isPublica', '==', true)
      .orderBy('criadoEm', 'desc')
      .get();

    const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    res.status(200).json({ data });
  } catch (error: any) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

router.get('/:startupId/all', requireAuth, async (req: Request, res: Response) => {
  try {
    const user = (req as any).user;
    const startupId = req.params.startupId as string;

    const investor = await isInvestor(user.uid, startupId);
    if (!investor) {
      res.status(403).json({ error: 'Forbidden: usuário não é investidor desta startup' });
      return;
    }

    const snapshot = await db
      .collection('questions')
      .where('startupId', '==', startupId)
      .orderBy('criadoEm', 'desc')
      .get();

    const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    res.status(200).json({ data });
  } catch (error: any) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

router.post('/', requireAuth, async (req: Request, res: Response) => {
  try {
    const user = (req as any).user;
    const { startupId, texto, isPublica } = req.body;

    if (typeof startupId !== 'string' || startupId.trim().length === 0) {
      res.status(400).json({ error: 'startupId é obrigatório' });
      return;
    }
    if (typeof texto !== 'string' || texto.trim().length === 0) {
      res.status(400).json({ error: 'texto é obrigatório' });
      return;
    }

    const autorNome = user.name || user.displayName || user.email || 'Usuário';

    const docRef = await db.collection('questions').add({
      startupId,
      autorId: user.uid,
      autorNome,
      texto,
      isPublica: isPublica === true,
      criadoEm: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.status(201).json({ data: { id: docRef.id } });
  } catch (error: any) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

router.put('/:id/answer', requireAuth, async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const { resposta, respondidoPor } = req.body;

    if (typeof resposta !== 'string' || resposta.trim().length === 0) {
      res.status(400).json({ error: 'resposta é obrigatória' });
      return;
    }

    const docRef = db.collection('questions').doc(id);
    const doc = await docRef.get();
    if (!doc.exists) {
      res.status(404).json({ error: 'Pergunta não encontrada' });
      return;
    }

    await docRef.update({
      resposta,
      respondidoPor: typeof respondidoPor === 'string' && respondidoPor.trim().length > 0
        ? respondidoPor
        : 'Empreendedor',
      respondidoEm: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.status(200).json({ data: { id: docRef.id } });
  } catch (error: any) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

export default router;
