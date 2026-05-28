import { Router, Request, Response, NextFunction } from 'express';
import { db, auth } from '../firebaseAdmin';

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

router.get('/', requireAuth, async (req: Request, res: Response) => {
  try {
    const { stage } = req.query;

    let query: FirebaseFirestore.Query = db.collection('startups');
    if (typeof stage === 'string' && stage.trim().length > 0) {
      query = query.where('stage', '==', stage);
    }

    const snapshot = await query.get();
    const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    res.status(200).json({ data });
  } catch (error: any) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

router.get('/:id', requireAuth, async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const doc = await db.collection('startups').doc(id).get();

    if (!doc.exists) {
      res.status(404).json({ error: 'Startup não encontrada' });
      return;
    }

    res.status(200).json({ data: { id: doc.id, ...doc.data() } });
  } catch (error: any) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

router.get('/:id/public-faq', requireAuth, async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const doc = await db.collection('startups').doc(id).get();

    if (!doc.exists) {
      res.status(404).json({ error: 'Startup não encontrada' });
      return;
    }

    const data = doc.data() || {};
    const faq = Array.isArray(data.faq) ? data.faq : [];
    const publicFaq = faq.filter((item: any) => item && item.publico === true);

    res.status(200).json({ data: publicFaq });
  } catch (error: any) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

router.get('/:id/investor-faq', requireAuth, async (req: Request, res: Response) => {
  try {
    const user = (req as any).user;
    const id = req.params.id as string;

    const assetsSnapshot = await db
      .collection('users')
      .doc(user.uid)
      .collection('assets')
      .where('name', '==', id)
      .limit(1)
      .get();

    if (assetsSnapshot.empty) {
      res.status(403).json({ error: 'Forbidden: usuário não possui ativo desta startup' });
      return;
    }

    const doc = await db.collection('startups').doc(id).get();
    if (!doc.exists) {
      res.status(404).json({ error: 'Startup não encontrada' });
      return;
    }

    const data = doc.data() || {};
    const faq = Array.isArray(data.faq) ? data.faq : [];

    res.status(200).json({ data: faq });
  } catch (error: any) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

export default router;
