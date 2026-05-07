//Autor: Vinicius Valim de Vechi Cardoso
import { Request, Response } from 'express';
import { db } from '../config/firebase';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'chave_super_secreta';

export const registerUser = async (req: Request, res: Response) => {
  const { nome, email, cpf, senha } = req.body;
  try {
    if (!nome || !email || !cpf || !senha) {
      return res.status(400).json({ error: 'Todos os campos são obrigatórios.' });
    }
    const senhaHash = await bcrypt.hash(senha, 10);
    const newUserRef = db.collection('usuarios').doc();
    await newUserRef.set({
      uid: newUserRef.id,
      nome, email, cpf, senha: senhaHash,
      criadoEm: new Date().toISOString()
    });
    res.status(201).json({ message: 'Usuário cadastrado com sucesso!', uid: newUserRef.id });
  } catch (error) {
    res.status(500).json({ error: 'Erro ao cadastrar usuário.' });
  }
};

export const loginUser = async (req: Request, res: Response) => {
  const { email, senha } = req.body;
  try {
    const usersRef = db.collection('usuarios');
    const snapshot = await usersRef.where('email', '==', email).get();

    if (snapshot.empty) return res.status(404).json({ error: 'Usuário não encontrado.' });
    
    const userData = snapshot.docs[0].data();
    const validPassword = await bcrypt.compare(senha, userData.senha);
    
    if (!validPassword) return res.status(401).json({ error: 'Senha incorreta.' });

    const token = jwt.sign({ uid: userData.uid }, JWT_SECRET, { expiresIn: '24h' });
    res.status(200).json({ message: 'Login bem-sucedido', token });
  } catch (error) {
    res.status(500).json({ error: 'Erro ao realizar login.' });
  }
};

export const recoverPassword = async (req: Request, res: Response) => {
  res.status(200).json({ message: `Instruções enviadas para ${req.body.email}` });
};

export const logoutUser = (req: Request, res: Response) => {
  res.status(200).json({ message: 'Logout solicitado com sucesso. Remova o token no aplicativo.' });
};