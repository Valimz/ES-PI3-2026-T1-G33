import 'package:mescla_invest/features/portfolio/models/investimento_model.dart';
import 'package:mescla_invest/features/portfolio/models/posicao_model.dart';
import 'package:mescla_invest/features/portfolio/models/variacao_model.dart';

// Base de exemplo com startups do Mescla. Tokens representam participação em projetos.
// Conforme documento de visão: o portfólio deve mostrar investimentos em startups vinculadas ao ecossistema.
final List<InvestimentoModel> mockPortfolio = [
  InvestimentoModel(
    id: '1',
    ticker: 'AGRITECH',
    nome: 'AgroSmart - Plataforma de Gestão Agrícola',
    estagio: EstagioStartup.emExpansao,
    posicao: PosicaoModel(
      quantidade: 5000.0,
      precoMedio: 2.50,
      valorAtual: 3.20,
    ),
    variacao: VariacaoModel(
      variacaoPercentual: 28.0,
      variacaoEmReais: 3500.0,
    ),
  ),
  // Startup em operação - rentabilidade moderada
  InvestimentoModel(
    id: '2',
    ticker: 'EDTECH',
    nome: 'CodePlay - Plataforma de Educação em Programação',
    estagio: EstagioStartup.emOperacao,
    posicao: PosicaoModel(
      quantidade: 8000.0,
      precoMedio: 1.20,
      valorAtual: 1.09,
    ),
    variacao: VariacaoModel(
      variacaoPercentual: -9.17,
      variacaoEmReais: -880.0,
    ),
  ),
  // Startup nova com potencial de crescimento
  InvestimentoModel(
    id: '3',
    ticker: 'HEALTHTECH',
    nome: 'MediConnect - Telemedicina e Consultoria Digital',
    estagio: EstagioStartup.nova,
    posicao: PosicaoModel(
      quantidade: 3500.0,
      precoMedio: 3.80,
      valorAtual: 4.32,
    ),
    variacao: VariacaoModel(
      variacaoPercentual: 13.68,
      variacaoEmReais: 1820.0,
    ),
  ),
  // Startup em expansão
  InvestimentoModel(
    id: '4',
    ticker: 'FINTECH',
    nome: 'PayLocal - Solução de Pagamento P2P Descentralizada',
    estagio: EstagioStartup.emExpansao,
    posicao: PosicaoModel(
      quantidade: 2000.0,
      precoMedio: 5.00,
      valorAtual: 5.50,
    ),
    variacao: VariacaoModel(
      variacaoPercentual: 10.0,
      variacaoEmReais: 1000.0,
    ),
  ),
];