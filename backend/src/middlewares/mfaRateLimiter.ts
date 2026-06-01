import rateLimit from 'express-rate-limit';

const isTest = process.env.NODE_ENV === 'test';

/**
 * Rate limiter para o envio de código MFA.
 * Limita a 3 solicitações por janela de 15 minutos por IP.
 * Em ambiente de teste, usa limites muito altos para não interferir nos testes.
 */
export const sendCodeLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: isTest ? 10000 : 3,
  message: { error: 'Muitas solicitações de código. Tente novamente em 15 minutos.' },
  standardHeaders: true,
  legacyHeaders: false,
  validate: { limit: !isTest },
});

/**
 * Rate limiter para a verificação de código MFA.
 * Limita a 5 tentativas por janela de 15 minutos por IP.
 * Em ambiente de teste, usa limites muito altos para não interferir nos testes.
 */
export const verifyCodeLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: isTest ? 10000 : 5,
  message: { error: 'Muitas tentativas de verificação. Tente novamente em 15 minutos.' },
  standardHeaders: true,
  legacyHeaders: false,
  validate: { limit: !isTest },
});
