//Autor: Vinicius Valim de Vechi Cardoso
import { Router } from 'express';
import { registerUser, loginUser, recoverPassword, logoutUser } from '../controllers/authController';
import { getProfile, updateProfile } from '../controllers/profileController';
import { verifyToken } from '../middlewares/authMiddleware';

const router = Router();

// Rotas de Autenticação
router.post('/auth/cadastro', registerUser);
router.post('/auth/login', loginUser);
router.post('/auth/recuperar-senha', recoverPassword);
router.post('/auth/logout', logoutUser);

// Rota de Perfil (Protegida)
router.get('/perfil', verifyToken, getProfile);
router.put('/perfil', verifyToken, updateProfile);
export default router;