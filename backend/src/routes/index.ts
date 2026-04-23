//Autor: Vinicius Valim de Vechi Cardoso
import { Router } from 'express';
import { registerUser, loginUser, recoverPassword, logoutUser } from '../controllers/authController';
import { getProfile, updateProfile } from '../controllers/profileController';
import { listarStartups, buscarStartupPorId } from '../controllers/startupController';
import { verifyToken } from '../middlewares/authMiddleware';

const router = Router();

router.post('/auth/cadastro', registerUser);
router.post('/auth/login', loginUser);
router.post('/auth/recuperar-senha', recoverPassword);
router.post('/auth/logout', logoutUser);

router.get('/perfil', verifyToken, getProfile);
router.put('/perfil', verifyToken, updateProfile);

router.get('/startups', verifyToken, listarStartups);
router.get('/startups/:id', verifyToken, buscarStartupPorId);

export default router;