import 'package:mescla_invest/features/portfolio/models/posicao_model.dart';
import 'package:mescla_invest/features/portfolio/models/variacao_model.dart';

// Representa um ativo do portfólio com seus dados de posição e variação.
class InvestimentoModel {
  final String id;
  final String ticker;
  final String nome;
  final PosicaoModel posicao;
  final VariacaoModel variacao;

  InvestimentoModel({
    required this.id,
    required this.ticker,
    required this.nome,
    required this.posicao,
    required this.variacao,
    });
}