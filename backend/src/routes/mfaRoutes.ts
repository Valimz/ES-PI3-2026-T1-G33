import { Router } from 'express';
import { sendMfaCode, verifyMfaCode, checkMfaStatus, disableMfa } from '../controllers/mfaController';
import { verifyToken } from '../middlewares/authMiddleware';
import { sendCodeLimiter, verifyCodeLimiter } from '../middlewares/mfaRateLimiter';

const router = Router();

router.post('/send-code', sendCodeLimiter, verifyToken, sendMfaCode);
router.post('/verify-code', verifyCodeLimiter, verifyToken, verifyMfaCode);
router.get('/status', verifyToken, checkMfaStatus);
router.post('/disable', verifyToken, disableMfa);

export default router;
