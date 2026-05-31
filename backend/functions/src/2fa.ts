/**
 * Autor: Felipe Augusto dos Santos Silva
 * RA: 25003353
 *
 * Exemplo de implementação de endpoints HTTP para enrolamento e verificação de 2FA (TOTP).
 * Este arquivo serve como referência e deve ser adaptado ao padrão do projeto.
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
const speakeasy: any = require('speakeasy');
const QRCode: any = require('qrcode');
const bcrypt: any = require('bcryptjs');

// Nota: `admin.initializeApp()` normalmente é chamado em outro arquivo (index.ts).
// Se não estiver inicializado, descomente a linha abaixo.
// admin.initializeApp();

const db = admin.firestore();

// Helper: gera backup codes e retorna versões em texto e hashes para armazenamento
async function generateBackupCodes(count = 8): Promise<{codes: string[]; hashes: string[]}> {
  const codes: string[] = [];
  const hashes: string[] = [];
  for (let i = 0; i < count; i++) {
    const code = Math.random().toString(36).slice(2, 12).toUpperCase();
    const hash = await bcrypt.hash(code, 10);
    codes.push(code);
    hashes.push(hash);
  }
  return {codes, hashes};
}

// Endpoint: iniciar enrolamento 2FA
export const enroll2FA = functions.https.onRequest(async (req, res) => {
  try {
    const uid = req.headers['x-user-id'] as string;
    if (!uid) {
      res.status(401).json({error: 'Usuário não autenticado'});
      return;
    }

    // Gerar secret TOTP
    const secret = speakeasy.generateSecret({length: 20});

    // Gerar QR code (otpauth URL) para exibir no frontend
    const otpauth = speakeasy.otpauthURL({
      secret: secret.base32,
      label: `ES-PI3:${uid}`,
      algorithm: 'sha1',
    });
    const qrDataUrl = await QRCode.toDataURL(otpauth);

    // Gerar backup codes (mostrar ao usuário apenas uma vez)
    const {codes, hashes} = await generateBackupCodes(8);

    // Armazenar secret cifrado (neste exemplo, armazenamos em claro na Firestore —
    // em produção cifrar antes de salvar)
    await db.collection('users').doc(uid).set({
      '2fa_temp_secret': secret.base32,
      backup_codes_hashes: hashes,
    }, {merge: true});

    // Retornar QR e códigos em texto (apenas para exibição/baixar)
    res.json({qrDataUrl, backupCodes: codes});
    return;
  } catch (err) {
    console.error(err);
    res.status(500).json({error: 'Erro no enrolamento 2FA'});
    return;
  }
});

// Endpoint: confirmar enrolamento (usuário fornece um código TOTP para ativar)
export const confirm2FA = functions.https.onRequest(async (req, res) => {
  try {
    const uid = req.headers['x-user-id'] as string;
    const token = req.body?.token as string;
    if (!uid) {
      res.status(401).json({error: 'Usuário não autenticado'});
      return;
    }
    if (!token) {
      res.status(400).json({error: 'Token TOTP necessário'});
      return;
    }

    const userDoc = await db.collection('users').doc(uid).get();
    const data = userDoc.data() || {};
    const tempSecret = data['2fa_temp_secret'];
    if (!tempSecret) {
      res.status(400).json({error: 'Não há enrolamento pendente'});
      return;
    }

    const verified = speakeasy.totp.verify({
      secret: tempSecret,
      encoding: 'base32',
      token,
      window: 1,
    });

    if (!verified) {
      res.status(400).json({error: 'Token inválido'});
      return;
    }

    // Ativar 2FA: mover temp_secret para secret definitivo e marcar `2fa_enabled`
    await db.collection('users').doc(uid).update({
      '2fa_secret': tempSecret,
      '2fa_enabled': true,
      '2fa_enabled_at': admin.firestore.FieldValue.serverTimestamp(),
    });

    res.json({success: true});
    return;
  } catch (err) {
    console.error(err);
    res.status(500).json({error: 'Erro ao confirmar 2FA'});
    return;
  }
});

// Endpoint: verificar token during login
export const verify2FA = functions.https.onRequest(async (req, res) => {
  try {
    const uid = req.headers['x-user-id'] as string;
    const token = req.body?.token as string;
    if (!uid) {
      res.status(401).json({error: 'Usuário não autenticado'});
      return;
    }
    if (!token) {
      res.status(400).json({error: 'Token necessário'});
      return;
    }

    const userDoc = await db.collection('users').doc(uid).get();
    const data = userDoc.data() || {};
    const secret = data['2fa_secret'];
    if (!secret) {
      res.status(400).json({error: '2FA não configurado'});
      return;
    }

    // Verifica TOTP
    const valid = speakeasy.totp.verify({
      secret,
      encoding: 'base32',
      token,
      window: 1,
    });

    if (valid) {
      res.json({success: true});
      return;
    }
    // Se não válido, podemos também checar codes de backup (hashes)

    // Verificar backup codes
    const backupHashes: string[] = data['backup_codes_hashes'] || [];
    for (let i = 0; i < backupHashes.length; i++) {
      const hash = backupHashes[i];
      if (await bcrypt.compare(token, hash)) {
        // Consumir esse código: remover do array
        backupHashes.splice(i, 1);
        await db.collection('users').doc(uid).update({backup_codes_hashes: backupHashes});
        res.json({success: true, usedBackupCode: true});
        return;
      }
    }

    res.status(400).json({error: 'Token inválido'});
    return;
  } catch (err) {
    console.error(err);
    res.status(500).json({error: 'Erro ao verificar 2FA'});
    return;
  }
});
