import 'package:mescla_invest/features/portfolio/models/investimento_model.dart';
import 'package:mescla_invest/features/portfolio/models/posicao_model.dart';
import 'package:mescla_invest/features/portfolio/models/variacao_model.dart';

// Base de exemplo usada pela tela de portfólio enquanto não há integração com API.
final List<InvestimentoModel> mockPortfolio = [
  InvestimentoModel(
    id: '1',
    ticker: 'BTC',
    nome: 'Bitcoin',
    posicao: PosicaoModel(
      quantidade: 0.005,
      precoMedio: 250000,
      valorAtual: 320000,
    ),
    variacao: VariacaoModel(
      variacaoPercentual: 28.0,
      variacaoEmReais: 350.0,
    ),
  ),
  // Mistura de cripto e ação para exercitar o filtro da interface.
  InvestimentoModel(
    id: '2',
    ticker: 'VALE3',
    nome: 'Vale S.A.',
    posicao: PosicaoModel(
      quantidade: 50.0,
      precoMedio: 75.20,
      valorAtual: 68.40,
    ),
    variacao: VariacaoModel(
      variacaoPercentual: -8.97,
      variacaoEmReais: -337.50,
    ),
  ),
  InvestimentoModel(
    id: '3',
    ticker: 'ETH',
    nome: 'Ethereum',
    posicao: PosicaoModel(
      quantidade: 0.7524,
      precoMedio: 12500.00,
      valorAtual: 14200.50,
    ),
    variacao: VariacaoModel(
      variacaoPercentual: 13.60,
      variacaoEmReais: 1279.15,
    ),
  ),
];