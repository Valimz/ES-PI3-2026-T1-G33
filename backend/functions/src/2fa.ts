/**
 * Autor: Felipe Augusto dos Santos Silva
 * RA: 25003353
 *
 * Exemplo de implementação de endpoints HTTP para enrolamento e verificação de 2FA (TOTP).
 * Este arquivo serve como referência e deve ser adaptado ao padrão do projeto.
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
const speakeasy: any = require('speakeasy');
const QRCode: any = require('qrcode');
const bcrypt: any = require('bcryptjs');

// Chave de cifragem AES-256-GCM (base64). Deve ser definida em variáveis de ambiente
const ENC_KEY_BASE64 = process.env.TOTP_ENC_KEY || '';
const ENC_KEY = ENC_KEY_BASE64 ? Buffer.from(ENC_KEY_BASE64, 'base64') : null;

function ensureKey() {
  if (!ENC_KEY) throw new Error('TOTP_ENC_KEY não definida (base64, 32 bytes)');
  if (ENC_KEY.length !== 32) throw new Error('TOTP_ENC_KEY deve ser 32 bytes quando decodificada (base64)');
}

function encryptSecret(plain: string): string {
  ensureKey();
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', ENC_KEY as Buffer, iv);
  const encrypted = Buffer.concat([cipher.update(plain, 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  // formato: iv(12) | tag(16) | ciphertext
  return Buffer.concat([iv, tag, encrypted]).toString('base64');
}

function decryptSecret(enc: string): string {
  ensureKey();
  const data = Buffer.from(enc, 'base64');
  const iv = data.slice(0, 12);
  const tag = data.slice(12, 28);
  const encrypted = data.slice(28);
  const decipher = crypto.createDecipheriv('aes-256-gcm', ENC_KEY as Buffer, iv);
  decipher.setAuthTag(tag);
  const decrypted = Buffer.concat([decipher.update(encrypted), decipher.final()]);
  return decrypted.toString('utf8');
}

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

    // Gerar secret TOTP (base32)
    const secret = speakeasy.generateSecret({length: 20});

    // Gerar QR code (otpauth URL) para exibir no frontend (usa valor plain para o otpauth)
    const otpauth = speakeasy.otpauthURL({
      secret: secret.base32,
      label: `ES-PI3:${uid}`,
      algorithm: 'sha1',
    });
    const qrDataUrl = await QRCode.toDataURL(otpauth);

    // Gerar backup codes (mostrar ao usuário apenas uma vez)
    const {codes, hashes} = await generateBackupCodes(8);

    // Cifrar secret antes de persistir
    let secretEnc: string;
    try {
      secretEnc = encryptSecret(secret.base32);
    } catch (e: any) {
      console.error('Erro ao cifrar secret:', e?.message || e);
      res.status(500).json({error: 'Configuração de cifragem ausente'});
      return;
    }

    // Armazenar secret cifrado e backup codes (hashes)
    await db.collection('users').doc(uid).set({
      '2fa_temp_secret_enc': secretEnc,
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
    const tempSecretEnc = data['2fa_temp_secret_enc'];
    if (!tempSecretEnc) {
      res.status(400).json({error: 'Não há enrolamento pendente'});
      return;
    }

    // Decifrar secret temporário
    let tempSecret: string;
    try {
      tempSecret = decryptSecret(tempSecretEnc);
    } catch (e: any) {
      console.error('Erro ao decifrar temp secret:', e?.message || e);
      res.status(500).json({error: 'Erro ao processar secret'});
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
    // Armazenar secret cifrado definitivo e remover temp
    await db.collection('users').doc(uid).update({
      '2fa_secret_enc': tempSecretEnc,
      '2fa_enabled': true,
      '2fa_enabled_at': admin.firestore.FieldValue.serverTimestamp(),
      '2fa_temp_secret_enc': admin.firestore.FieldValue.delete(),
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
    const secretEnc = data['2fa_secret_enc'];
    if (!secretEnc) {
      res.status(400).json({error: '2FA não configurado'});
      return;
    }

    // Decifrar secret e verificar
    let secret: string;
    try {
      secret = decryptSecret(secretEnc);
    } catch (e: any) {
      console.error('Erro ao decifrar secret:', e?.message || e);
      res.status(500).json({error: 'Erro ao processar secret'});
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
