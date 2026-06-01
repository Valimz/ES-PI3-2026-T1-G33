import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import { db, auth } from '../firebaseAdmin';
import { sendMfaEmail } from '../services/emailService';

export const sendMfaCode = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user;
    if (!userId) {
      return res.status(401).json({ error: 'Usuário não autenticado.' });
    }

    // Busca os dados do usuário para pegar o e-mail
    const userRecord = await auth.getUser(userId);
    const userEmail = userRecord.email;

    if (!userEmail) {
      return res.status(400).json({ error: 'Usuário não possui um e-mail cadastrado.' });
    }

    // Gera um código de 6 dígitos
    const code = Math.floor(100000 + Math.random() * 900000).toString();

    // Expiração em 5 minutos
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + 5);

    // Salva o código no documento do usuário
    await db.collection('usuarios').doc(userId).set({
      mfaCode: code,
      mfaCodeExpiresAt: expiresAt.toISOString(),
      mfaFailedAttempts: 0
    }, { merge: true });

    // Envia o e-mail
    await sendMfaEmail(userEmail, code);

    res.status(200).json({ message: 'Código MFA enviado com sucesso.' });
  } catch (error) {
    console.error('Erro ao enviar código MFA:', error);
    res.status(500).json({ error: 'Erro ao processar o envio do código.' });
  }
};

export const verifyMfaCode = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user;
    const { code } = req.body;

    if (!userId) {
      return res.status(401).json({ error: 'Usuário não autenticado.' });
    }

    if (!code) {
      return res.status(400).json({ error: 'Código não fornecido.' });
    }

    const userDoc = await db.collection('usuarios').doc(userId).get();
    if (!userDoc.exists) {
      return res.status(404).json({ error: 'Usuário não encontrado no banco de dados.' });
    }

    const userData = userDoc.data()!;
    const storedCode = userData.mfaCode;
    const expiresAtStr = userData.mfaCodeExpiresAt;
    const failedAttempts: number = userData.mfaFailedAttempts ?? 0;

    if (!storedCode || !expiresAtStr) {
      return res.status(400).json({ error: 'Nenhum código MFA pendente para este usuário.' });
    }

    // Verificar se excedeu tentativas (máx 5)
    if (failedAttempts >= 5) {
      await db.collection('usuarios').doc(userId).update({
        mfaCode: null,
        mfaCodeExpiresAt: null,
        mfaFailedAttempts: null
      });
      return res.status(429).json({ error: 'Muitas tentativas falhas. Solicite um novo código.' });
    }

    const expiresAt = new Date(expiresAtStr);
    if (new Date() > expiresAt) {
      // Expirou, limpar código
      await db.collection('usuarios').doc(userId).update({
        mfaCode: null,
        mfaCodeExpiresAt: null,
        mfaFailedAttempts: null
      });
      return res.status(400).json({ error: 'O código MFA expirou. Solicite um novo.' });
    }

    if (storedCode !== code) {
      // Incrementar tentativas falhas
      await db.collection('usuarios').doc(userId).update({
        mfaFailedAttempts: failedAttempts + 1
      });
      const remaining = 4 - failedAttempts;
      return res.status(400).json({
        error: remaining > 0
          ? `Código inválido. Você tem mais ${remaining} tentativa(s).`
          : 'Código inválido. Última tentativa antes do bloqueio.'
      });
    }

    // Código válido! Ativar MFA (se ainda não estiver) e limpar código
    await db.collection('usuarios').doc(userId).update({
      mfaEnabled: true,
      mfaCode: null,
      mfaCodeExpiresAt: null,
      mfaFailedAttempts: null
    });

    res.status(200).json({ message: 'MFA verificado com sucesso!' });
  } catch (error) {
    console.error('Erro ao verificar código MFA:', error);
    res.status(500).json({ error: 'Erro ao validar o código.' });
  }
};

export const checkMfaStatus = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user;
    if (!userId) {
      return res.status(401).json({ error: 'Usuário não autenticado.' });
    }

    const userDoc = await db.collection('usuarios').doc(userId).get();
    if (!userDoc.exists) {
      return res.status(200).json({ mfaEnabled: false });
    }

    const userData = userDoc.data()!;
    res.status(200).json({ mfaEnabled: userData.mfaEnabled === true });
  } catch (error) {
    console.error('Erro ao verificar status MFA:', error);
    res.status(500).json({ error: 'Erro ao verificar status do MFA.' });
  }
};

