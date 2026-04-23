//Autor: Vinicius Valim de Vechi Cardoso
import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import { db } from '../config/firebase';

export const getProfile = async (req: AuthRequest, res: Response) => {
  try {
    const userDoc = await db.collection('usuarios').doc(req.user!).get();
    if (!userDoc.exists) return res.status(404).json({ error: 'Perfil não encontrado.' });
    
    const userData = userDoc.data();
    delete userData?.senha;
    res.status(200).json(userData);
  } catch (error) {
    res.status(500).json({ error: 'Erro ao buscar perfil.' });
  }
};

export const updateProfile = async (req: AuthRequest, res: Response) => {
  const { nome, cpf } = req.body; 
  try {
    await db.collection('usuarios').doc(req.user!).update({
      nome,
      cpf,
      atualizadoEm: new Date().toISOString()
    });
    res.status(200).json({ message: 'Perfil atualizado com sucesso.' });
  } catch (error) {
    res.status(500).json({ error: 'Erro ao atualizar o perfil.' });
  }
};