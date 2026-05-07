import { Router, Request, Response, NextFunction } from 'express';
import { db, auth } from '../firebaseAdmin';
import * as admin from 'firebase-admin';

const router = Router();

// Middleware de autenticação
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

// ============== ROTA: REGISTRAR TOKEN FCM ==============
router.post('/register-token', requireAuth, async (req: Request, res: Response) => {
  try {
    const user = (req as any).user;
    const { token } = req.body;

    if (!token || typeof token !== 'string') {
      res.status(400).json({ error: 'Token is required' });
      return;
    }

    await db
      .collection('users')
      .doc(user.uid)
      .collection('tokens')
      .doc(token)
      .set({
        token,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        platform: 'android',
      });

    console.log(`🔔 Token FCM registrado para ${user.uid}`);
    res.status(200).json({ message: 'Token registered successfully' });
  } catch (error: any) {
    console.error('Erro ao registrar token:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============== HELPER: ENVIAR NOTIFICAÇÃO ==============

export interface NotificationPayload {
  title: string;
  body: string;
  type: 'deposit' | 'buy' | 'sell' | 'p2p_offer' | 'p2p_accepted' | 'p2p_counter' | 'system';
  data?: Record<string, string>;
}

/**
 * Envia uma notificação para um usuário:
 * 1. Salva no Firestore (para o sininho in-app)
 * 2. Envia push via FCM (para notificação do sistema)
 */
export async function sendNotification(uid: string, payload: NotificationPayload): Promise<void> {
  try {
    // 1. Salvar notificação no Firestore
    await db
      .collection('users')
      .doc(uid)
      .collection('notifications')
      .add({
        title: payload.title,
        body: payload.body,
        type: payload.type,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        data: payload.data || {},
      });

    console.log(`📝 Notificação in-app criada para ${uid}: ${payload.title}`);

    // 2. Buscar tokens FCM do usuário
    const tokensSnapshot = await db
      .collection('users')
      .doc(uid)
      .collection('tokens')
      .get();

    if (tokensSnapshot.empty) {
      console.log(`⚠️ Nenhum token FCM encontrado para ${uid}`);
      return;
    }

    const tokens = tokensSnapshot.docs.map(doc => doc.data().token as string);

    // 3. Enviar push notification via FCM
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
        priority: 'high',
        notification: {
          channelId: 'mescla_invest_channel',
          priority: 'high',
          defaultSound: true,
        },
      },
      tokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`📤 Push enviado para ${uid}: ${response.successCount} sucesso, ${response.failureCount} falha`);

    // Limpar tokens inválidos
    if (response.failureCount > 0) {
      const tokensToRemove: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const errorCode = resp.error?.code;
          if (
            errorCode === 'messaging/invalid-registration-token' ||
            errorCode === 'messaging/registration-token-not-registered'
          ) {
            tokensToRemove.push(tokens[idx]!);
          }
        }
      });

      // Remover tokens inválidos do Firestore
      for (const invalidToken of tokensToRemove) {
        await db
          .collection('users')
          .doc(uid)
          .collection('tokens')
          .doc(invalidToken)
          .delete();
        console.log(`🗑️ Token inválido removido: ${invalidToken.substring(0, 20)}...`);
      }
    }
  } catch (error) {
    console.error(`❌ Erro ao enviar notificação para ${uid}:`, error);
    // Não lançar erro para não bloquear a operação principal
  }
}

export default router;
