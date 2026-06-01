import request from 'supertest';
import app from '../src/app';
import { db, auth } from '../src/firebaseAdmin';

// Mock do emailService para não enviar e-mails reais nos testes
jest.mock('../src/services/emailService', () => ({
  sendMfaEmail: jest.fn().mockResolvedValue(undefined),
}));

describe('MFA Routes', () => {
  // ===================== SEND CODE =====================
  describe('POST /api/mfa/send-code', () => {
    it('deve retornar 401 se não enviar token', async () => {
      const res = await request(app).post('/api/mfa/send-code');
      expect(res.statusCode).toEqual(401);
    });

    it('deve enviar código MFA com sucesso', async () => {
      // Mock do auth.getUser para retornar um e-mail
      (auth as any).getUser = jest.fn().mockResolvedValue({
        email: 'test@example.com',
      });

      const res = await request(app)
        .post('/api/mfa/send-code')
        .set('Authorization', 'Bearer MOCK_TOKEN');

      expect(res.statusCode).toEqual(200);
      expect(res.body.message).toBe('Código MFA enviado com sucesso.');
    });

    it('deve retornar 400 se o usuário não tiver e-mail', async () => {
      (auth as any).getUser = jest.fn().mockResolvedValue({
        email: null,
      });

      const res = await request(app)
        .post('/api/mfa/send-code')
        .set('Authorization', 'Bearer MOCK_TOKEN');

      expect(res.statusCode).toEqual(400);
      expect(res.body.error).toBe('Usuário não possui um e-mail cadastrado.');
    });
  });

  // ===================== VERIFY CODE =====================
  describe('POST /api/mfa/verify-code', () => {
    it('deve retornar 401 se não enviar token', async () => {
      const res = await request(app)
        .post('/api/mfa/verify-code')
        .send({ code: '123456' });
      expect(res.statusCode).toEqual(401);
    });

    it('deve retornar 400 se não enviar código', async () => {
      const res = await request(app)
        .post('/api/mfa/verify-code')
        .set('Authorization', 'Bearer MOCK_TOKEN')
        .send({});

      expect(res.statusCode).toEqual(400);
      expect(res.body.error).toBe('Código não fornecido.');
    });

    it('deve verificar código MFA com sucesso', async () => {
      const futureDate = new Date();
      futureDate.setMinutes(futureDate.getMinutes() + 5);

      (db.collection('usuarios' as any).doc as jest.Mock).mockReturnValue({
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({
            mfaCode: '123456',
            mfaCodeExpiresAt: futureDate.toISOString(),
            mfaFailedAttempts: 0,
          }),
        }),
        update: jest.fn().mockResolvedValue(true),
      });

      const res = await request(app)
        .post('/api/mfa/verify-code')
        .set('Authorization', 'Bearer MOCK_TOKEN')
        .send({ code: '123456' });

      expect(res.statusCode).toEqual(200);
      expect(res.body.message).toBe('MFA verificado com sucesso!');
    });

    it('deve retornar erro para código inválido', async () => {
      const futureDate = new Date();
      futureDate.setMinutes(futureDate.getMinutes() + 5);

      (db.collection('usuarios' as any).doc as jest.Mock).mockReturnValue({
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({
            mfaCode: '123456',
            mfaCodeExpiresAt: futureDate.toISOString(),
            mfaFailedAttempts: 0,
          }),
        }),
        update: jest.fn().mockResolvedValue(true),
      });

      const res = await request(app)
        .post('/api/mfa/verify-code')
        .set('Authorization', 'Bearer MOCK_TOKEN')
        .send({ code: '000000' });

      expect(res.statusCode).toEqual(400);
      expect(res.body.error).toContain('Código inválido');
    });

    it('deve retornar erro para código expirado', async () => {
      const pastDate = new Date();
      pastDate.setMinutes(pastDate.getMinutes() - 10);

      (db.collection('usuarios' as any).doc as jest.Mock).mockReturnValue({
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({
            mfaCode: '123456',
            mfaCodeExpiresAt: pastDate.toISOString(),
            mfaFailedAttempts: 0,
          }),
        }),
        update: jest.fn().mockResolvedValue(true),
      });

      const res = await request(app)
        .post('/api/mfa/verify-code')
        .set('Authorization', 'Bearer MOCK_TOKEN')
        .send({ code: '123456' });

      expect(res.statusCode).toEqual(400);
      expect(res.body.error).toBe('O código MFA expirou. Solicite um novo.');
    });

    it('deve bloquear após 5 tentativas falhas', async () => {
      const futureDate = new Date();
      futureDate.setMinutes(futureDate.getMinutes() + 5);

      (db.collection('usuarios' as any).doc as jest.Mock).mockReturnValue({
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({
            mfaCode: '123456',
            mfaCodeExpiresAt: futureDate.toISOString(),
            mfaFailedAttempts: 5,
          }),
        }),
        update: jest.fn().mockResolvedValue(true),
      });

      const res = await request(app)
        .post('/api/mfa/verify-code')
        .set('Authorization', 'Bearer MOCK_TOKEN')
        .send({ code: '999999' });

      expect(res.statusCode).toEqual(429);
      expect(res.body.error).toBe('Muitas tentativas falhas. Solicite um novo código.');
    });

    it('deve retornar 400 se não houver código pendente', async () => {
      (db.collection('usuarios' as any).doc as jest.Mock).mockReturnValue({
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({
            mfaCode: null,
            mfaCodeExpiresAt: null,
          }),
        }),
        update: jest.fn().mockResolvedValue(true),
      });

      const res = await request(app)
        .post('/api/mfa/verify-code')
        .set('Authorization', 'Bearer MOCK_TOKEN')
        .send({ code: '123456' });

      expect(res.statusCode).toEqual(400);
      expect(res.body.error).toBe('Nenhum código MFA pendente para este usuário.');
    });

    it('deve retornar 404 se o usuário não existir no Firestore', async () => {
      (db.collection('usuarios' as any).doc as jest.Mock).mockReturnValue({
        get: jest.fn().mockResolvedValue({
          exists: false,
        }),
        update: jest.fn().mockResolvedValue(true),
      });

      const res = await request(app)
        .post('/api/mfa/verify-code')
        .set('Authorization', 'Bearer MOCK_TOKEN')
        .send({ code: '123456' });

      expect(res.statusCode).toEqual(404);
      expect(res.body.error).toBe('Usuário não encontrado no banco de dados.');
    });
  });

  // ===================== CHECK STATUS =====================
  describe('GET /api/mfa/status', () => {
    it('deve retornar 401 se não enviar token', async () => {
      const res = await request(app).get('/api/mfa/status');
      expect(res.statusCode).toEqual(401);
    });

    it('deve retornar mfaEnabled true quando MFA está ativo', async () => {
      (db.collection('usuarios' as any).doc as jest.Mock).mockReturnValue({
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({
            mfaEnabled: true,
          }),
        }),
      });

      const res = await request(app)
        .get('/api/mfa/status')
        .set('Authorization', 'Bearer MOCK_TOKEN');

      expect(res.statusCode).toEqual(200);
      expect(res.body.mfaEnabled).toBe(true);
    });

    it('deve retornar mfaEnabled false quando MFA não está ativo', async () => {
      (db.collection('usuarios' as any).doc as jest.Mock).mockReturnValue({
        get: jest.fn().mockResolvedValue({
          exists: true,
          data: () => ({
            mfaEnabled: false,
          }),
        }),
      });

      const res = await request(app)
        .get('/api/mfa/status')
        .set('Authorization', 'Bearer MOCK_TOKEN');

      expect(res.statusCode).toEqual(200);
      expect(res.body.mfaEnabled).toBe(false);
    });

    it('deve retornar mfaEnabled false quando o usuário não existe no Firestore', async () => {
      (db.collection('usuarios' as any).doc as jest.Mock).mockReturnValue({
        get: jest.fn().mockResolvedValue({
          exists: false,
        }),
      });

      const res = await request(app)
        .get('/api/mfa/status')
        .set('Authorization', 'Bearer MOCK_TOKEN');

      expect(res.statusCode).toEqual(200);
      expect(res.body.mfaEnabled).toBe(false);
    });
  });
});
