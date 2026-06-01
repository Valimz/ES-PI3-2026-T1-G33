import { auth } from '../firebaseAdmin';
export const verifyToken = async (req, res, next) => {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) {
        res.status(401).json({ error: 'Acesso negado. Token não fornecido.' });
        return;
    }
    try {
        const decoded = await auth.verifyIdToken(token);
        req.user = decoded.uid;
        next();
    }
    catch (error) {
        res.status(403).json({ error: 'Token inválido ou expirado.' });
        return;
    }
};
