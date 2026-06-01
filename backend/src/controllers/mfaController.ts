import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import { db, auth } from '../firebaseAdmin';
import { sendMfaEmail } from '../services/emailService';

/**
 * Envia um código MFA por e-mail ou SMS.
 * Body: { method?: 'email' | 'sms', phone?: string }
 */
export const sendMfaCode = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user;
    if (!userId) {
      return res.status(401).json({ error: 'Usuário não autenticado.' });
    }

    const method: string = req.body.method || 'email';

    // Busca os dados do usuário para pegar o e-mail
    const userRecord = await auth.getUser(userId);
    const userEmail = userRecord.email;

    // Gera um código de 6 dígitos
    const code = Math.floor(100000 + Math.random() * 900000).toString();

    // Expiração em 5 minutos
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + 5);

    // Salva o código no documento do usuário
    await db.collection('usuarios').doc(userId).set({
      mfaCode: code,
      mfaCodeExpiresAt: expiresAt.toISOString(),
      mfaFailedAttempts: 0,
      mfaPendingMethod: method,
    }, { merge: true });

    if (method === 'sms') {
      const phone = req.body.phone || userRecord.phoneNumber;
      if (!phone) {
        return res.status(400).json({ error: 'Número de telefone não fornecido.' });
      }

      // Salvar o telefone para referência
      await db.collection('usuarios').doc(userId).update({
        mfaPhone: phone,
      });

      // Para SMS, usamos o mesmo serviço de e-mail como fallback demonstrativo:
      // Em produção, usar Twilio, AWS SNS ou Firebase Phone Auth
      // Aqui enviamos o código por e-mail informando que é para o "SMS MFA"
      // e logamos o código no console para teste
      console.log(`\n======================================================`);
      console.log(`📱 [SMS MFA] Código para ${phone}: ${code}`);
      console.log(`======================================================\n`);

      // Também enviar por e-mail como backup (demonstração)
      if (userEmail) {
        await sendMfaEmail(userEmail,code);
      }

      return res.status(200).json({
        message: `Código MFA enviado por SMS para ${phone.substring(0, 4)}****${phone.substring(phone.length - 2)}.`,
      });
    } else {
      // Email MFA
      if (!userEmail) {
        return res.status(400).json({ error: 'Usuário não possui um e-mail cadastrado.' });
      }

      await sendMfaEmail(userEmail, code);

      return res.status(200).json({
        message: `Código MFA enviado para ${userEmail.substring(0, 3)}***@${userEmail.split('@')[1]}.`,
      });
    }
  } catch (error) {
    console.error('Erro ao enviar código MFA:', error);
    res.status(500).json({ error: 'Erro ao processar o envio do código.' });
  }
};

/**
 * Verifica o código MFA digitado pelo usuário.
 * Body: { code: string }
 */
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
    const pendingMethod: string = userData.mfaPendingMethod ?? 'email';

    if (!storedCode || !expiresAtStr) {
      return res.status(400).json({ error: 'Nenhum código MFA pendente para este usuário.' });
    }

    // Verificar se excedeu tentativas (máx 5)
    if (failedAttempts >= 5) {
      await db.collection('usuarios').doc(userId).update({
        mfaCode: null,
        mfaCodeExpiresAt: null,
        mfaFailedAttempts: null,
        mfaPendingMethod: null,
      });
      return res.status(429).json({ error: 'Muitas tentativas falhas. Solicite um novo código.' });
    }

    const expiresAt = new Date(expiresAtStr);
    if (new Date() > expiresAt) {
      await db.collection('usuarios').doc(userId).update({
        mfaCode: null,
        mfaCodeExpiresAt: null,
        mfaFailedAttempts: null,
        mfaPendingMethod: null,
      });
      return res.status(400).json({ error: 'O código MFA expirou. Solicite um novo.' });
    }

    if (storedCode !== code) {
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

    // Código válido! Ativar MFA e salvar o método
    await db.collection('usuarios').doc(userId).update({
      mfaEnabled: true,
      mfaMethod: pendingMethod,
      mfaCode: null,
      mfaCodeExpiresAt: null,
      mfaFailedAttempts: null,
      mfaPendingMethod: null,
    });

    res.status(200).json({
      message: 'MFA verificado e ativado com sucesso!',
      method: pendingMethod,
    });
  } catch (error) {
    console.error('Erro ao verificar código MFA:', error);
    res.status(500).json({ error: 'Erro ao validar o código.' });
  }
};

/**
 * Verifica o status atual do MFA do usuário.
 */
export const checkMfaStatus = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user;
    if (!userId) {
      return res.status(401).json({ error: 'Usuário não autenticado.' });
    }

    const userDoc = await db.collection('usuarios').doc(userId).get();
    if (!userDoc.exists) {
      return res.status(200).json({ mfaEnabled: false, mfaMethod: null });
    }

    const userData = userDoc.data()!;
    
    // Verificar também se tem TOTP no Firebase Auth
    const userRecord = await auth.getUser(userId);
    const hasFirebaseMfa = (userRecord.multiFactor?.enrolledFactors?.length ?? 0) > 0;
    
    let mfaMethod = userData.mfaMethod ?? null;
    if (hasFirebaseMfa && !mfaMethod) {
      mfaMethod = 'totp';
    }

    res.status(200).json({
      mfaEnabled: userData.mfaEnabled === true || hasFirebaseMfa,
      mfaMethod: mfaMethod,
    });
  } catch (error) {
    console.error('Erro ao verificar status MFA:', error);
    res.status(500).json({ error: 'Erro ao verificar status do MFA.' });
  }
};

/**
 * Desativa o MFA para o usuário.
 */
export const disableMfa = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user;
    if (!userId) {
      return res.status(401).json({ error: 'Usuário não autenticado.' });
    }

    // Limpar MFA customizado (email/sms) no Firestore
    await db.collection('usuarios').doc(userId).update({
      mfaEnabled: false,
      mfaMethod: null,
      mfaCode: null,
      mfaCodeExpiresAt: null,
      mfaFailedAttempts: null,
      mfaPendingMethod: null,
      mfaPhone: null,
    });

    res.status(200).json({ message: 'MFA desativado com sucesso.' });
  } catch (error) {
    console.error('Erro ao desativar MFA:', error);
    res.status(500).json({ error: 'Erro ao desativar o MFA.' });
  }
};
