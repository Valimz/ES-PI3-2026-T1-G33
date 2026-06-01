import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import { db } from '../firebaseAdmin';

export const sendQuestion = async (req: AuthRequest, res: Response) => {
  try {
    const { startupId, text, visibility, options } = req.body;
    const userId = req.user;

    if (!startupId || !text || !visibility) {
      return res.status(400).json({ error: 'Parâmetros obrigatórios ausentes.' });
    }

    const questionData: any = {
      startupId,
      userId,
      text,
      visibility, // 'public' | 'private'
      status: 'pending', // 'pending' | 'answered'
      createdAt: new Date().toISOString(),
    };

    if (options && Array.isArray(options) && options.length > 0) {
      questionData.options = options;
    }

    const docRef = await db.collection('startup_questions').add(questionData);

    res.status(201).json({ message: 'Pergunta enviada com sucesso.', id: docRef.id });
  } catch (error) {
    console.error('Erro ao enviar pergunta:', error);
    res.status(500).json({ error: 'Erro ao enviar pergunta.' });
  }
};

export const getQuestions = async (req: AuthRequest, res: Response) => {
  try {
    const { startupId } = req.params;
    const userId = req.user;

    if (!startupId) {
      return res.status(400).json({ error: 'startupId não fornecido.' });
    }

    // Buscamos todas as perguntas daquela startup
    const snapshot = await db.collection('startup_questions')
      .where('startupId', '==', startupId)
      .get();

    const questions: any[] = [];

    snapshot.forEach(doc => {
      const data = doc.data();
      data.id = doc.id;
      
      // Se a pergunta for privada, só retorna se o usuário for o criador (ou se fosse a startup)
      // Como não temos login de startup por enquanto, consideramos apenas o dono da pergunta
      if (data.visibility === 'private') {
        if (data.userId === userId) {
          questions.push(data);
        }
      } else {
        // Perguntas públicas são visíveis para todos
        questions.push(data);
      }
    });

    // Ordenar em memória (mais recentes primeiro) para evitar erro de falta de índice no Firestore
    questions.sort((a, b) => {
      const dateA = new Date(a.createdAt || 0).getTime();
      const dateB = new Date(b.createdAt || 0).getTime();
      return dateB - dateA;
    });

    res.status(200).json(questions);
  } catch (error) {
    console.error('Erro ao buscar perguntas:', error);
    res.status(500).json({ error: 'Erro ao buscar perguntas.' });
  }
};
