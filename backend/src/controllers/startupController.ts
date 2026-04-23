//Autor: Vinicius Valim de Vechi Cardoso
import { Request, Response } from 'express';
import { db } from '../config/firebase';

export const listarStartups = async (req: Request, res: Response) => {
  const { estagio, ordenar } = req.query;

  try {
    let query: FirebaseFirestore.Query = db.collection('startups');

    if (estagio) {
      query = query.where('estagio', '==', estagio);
    }

    if (ordenar === 'recentes') {
      query = query.orderBy('criadoEm', 'desc');
    } else if (ordenar === 'nome') {
      query = query.orderBy('nome', 'asc');
    }

    const snapshot = await query.get();

    if (snapshot.empty) {
      return res.status(200).json([]);
    }

    const startups = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        nome: data.nome,
        descricaoCurta: data.descricaoCurta,
        estagio: data.estagio,
        setor: data.setor,
        tokenSymbol: data.tokenSymbol,
        precoToken: data.precoToken,
        totalTokens: data.totalTokens,
        tokensDisponiveis: data.tokensDisponiveis,
        imagemUrl: data.imagemUrl ?? null,
        criadoEm: data.criadoEm,
      };
    });

    return res.status(200).json(startups);
  } catch (error) {
    return res.status(500).json({ error: 'Erro ao listar startups.' });
  }
};

export const buscarStartupPorId = async (req: Request<{ id: string }>, res: Response) => {
  const { id } = req.params;

  try {
    const docRef = db.collection('startups').doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Startup não encontrada.' });
    }

    const data = doc.data()!;

    const documentosSnapshot = await docRef.collection('documentos').get();
    const documentos = documentosSnapshot.docs.map((d) => ({
      id: d.id,
      ...d.data(),
    }));

    const startup = {
      id: doc.id,
      nome: data.nome,
      descricaoCurta: data.descricaoCurta,
      descricaoCompleta: data.descricaoCompleta,
      estagio: data.estagio,
      setor: data.setor,
      tokenSymbol: data.tokenSymbol,
      precoToken: data.precoToken,
      totalTokens: data.totalTokens,
      tokensDisponiveis: data.tokensDisponiveis,
      imagemUrl: data.imagemUrl ?? null,
      fundadores: data.fundadores ?? [],
      metricas: data.metricas ?? {},
      redesSociais: data.redesSociais ?? {},
      documentos,
      criadoEm: data.criadoEm,
      atualizadoEm: data.atualizadoEm ?? null,
    };

    return res.status(200).json(startup);
  } catch (error) {
    return res.status(500).json({ error: 'Erro ao buscar startup.' });
  }
};