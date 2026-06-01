import { Router } from 'express';
import { sendQuestion, getQuestions } from '../controllers/questionController';
import { verifyToken } from '../middlewares/authMiddleware';

const router = Router();

router.post('/', verifyToken, sendQuestion);
router.get('/:startupId', verifyToken, getQuestions);

export default router;
