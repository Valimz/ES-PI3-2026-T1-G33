// Nome: Felipe Augusto dos Santos Silva
// RA: 25003353

import 'package:mescla_invest/features/portfolio/models/investimento_model.dart';
import 'package:mescla_invest/features/portfolio/models/posicao_model.dart';
import 'package:mescla_invest/features/portfolio/models/variacao_model.dart';

/// Base de exemplo com startups reais do Mescla extraído da planilha de cadastro.
/// Cada investimento contém dados completos da startup e posição do usuário.
final List<InvestimentoModel> mockPortfolio = [
  InvestimentoModel(
    id: '1',
    nome: 'EcoTech',
    descricao: 'Plataforma de monitoramento ambiental para empresas',
    estagio: EstagioStartup.emOperacao,
    setor: 'Cleantech',
    capitalAportado: 300000.0,
    tokensEmitidos: 100000,
    socios: ['Ana Souza', 'Carlos Lima'],
    participacaoSocietaria: [60.0, 40.0],
    mentoresConselho: ['Mariana Prado'],
    videoDemo: 'https://exemplo.com/demo1',
    status: StatusStartup.ativa,
    posicao: PosicaoModel(
      quantidade: 5000.0,
      precoMedio: 3.00,
      valorAtual: 3.50,
    ),
    variacao: VariacaoModel(variacaoPercentual: 16.67, variacaoEmReais: 2500.0),
  ),
  InvestimentoModel(
    id: '2',
    nome: 'FinFlow',
    descricao: 'Gestão de fluxo de caixa para MEIs',
    estagio: EstagioStartup.emExpansao,
    setor: 'Fintech',
    capitalAportado: 500000.0,
    tokensEmitidos: 250000,
    socios: ['Roberto Dias', 'Julia Mota'],
    participacaoSocietaria: [50.0, 50.0],
    mentoresConselho: ['Ricardo Santos'],
    videoDemo: 'https://exemplo.com/demo2',
    status: StatusStartup.ativa,
    posicao: PosicaoModel(
      quantidade: 8000.0,
      precoMedio: 2.00,
      valorAtual: 1.80,
    ),
    variacao: VariacaoModel(
      variacaoPercentual: -10.0,
      variacaoEmReais: -1600.0,
    ),
  ),
  InvestimentoModel(
    id: '3',
    nome: 'AgroSmart',
    descricao: 'IOT para otimização de irrigação',
    estagio: EstagioStartup.nova,
    setor: 'AgTech',
    capitalAportado: 150000.0,
    tokensEmitidos: 75000,
    socios: ['Marcos Vinicius'],
    participacaoSocietaria: [100.0],
    mentoresConselho: ['Arnaldo Souza'],
    videoDemo: 'https://exemplo.com/demo3',
    status: StatusStartup.ativa,
    posicao: PosicaoModel(
      quantidade: 3500.0,
      precoMedio: 2.00,
      valorAtual: 2.40,
    ),
    variacao: VariacaoModel(variacaoPercentual: 20.0, variacaoEmReais: 1400.0),
  ),
  InvestimentoModel(
    id: '4',
    nome: 'HealthVibe',
    descricao: 'Telemedicina com IA para triagem',
    estagio: EstagioStartup.emOperacao,
    setor: 'HealthTech',
    capitalAportado: 800000.0,
    tokensEmitidos: 400000,
    socios: ['Beatriz Luz', 'Hugo Vaz'],
    participacaoSocietaria: [70.0, 30.0],
    mentoresConselho: ['Sandra Meireles'],
    videoDemo: 'https://exemplo.com/demo4',
    status: StatusStartup.ativa,
    posicao: PosicaoModel(
      quantidade: 2000.0,
      precoMedio: 2.50,
      valorAtual: 2.75,
    ),
    variacao: VariacaoModel(variacaoPercentual: 10.0, variacaoEmReais: 500.0),
  ),
  InvestimentoModel(
    id: '5',
    nome: 'EduNext',
    descricao: 'Plataforma de cursos gamificados',
    estagio: EstagioStartup.nova,
    setor: 'EduTech',
    capitalAportado: 450000.0,
    tokensEmitidos: 200000,
    socios: ['Tiago André'],
    participacaoSocietaria: [100.0],
    mentoresConselho: ['Fernando Silva'],
    videoDemo: 'https://exemplo.com/demo5',
    status: StatusStartup.ativa,
    posicao: PosicaoModel(
      quantidade: 2500.0,
      precoMedio: 2.25,
      valorAtual: 2.50,
    ),
    variacao: VariacaoModel(variacaoPercentual: 11.11, variacaoEmReais: 625.0),
  ),
];
