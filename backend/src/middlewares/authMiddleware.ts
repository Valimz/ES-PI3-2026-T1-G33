//Autor: Vinicius Valim de Vechi Cardoso
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'chave_super_secreta';

export interface AuthRequest extends Request {
  user?: string;
}

export const verifyToken = (req: AuthRequest, res: Response, next: NextFunction) => {
  const token = req.headers.authorization?.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Acesso negado. Token não fornecido.' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET) as { uid: string };
    req.user = decoded.uid;
    next();
  } catch (error) {
    return res.status(403).json({ error: 'Token inválido ou expirado.' });
  }
};