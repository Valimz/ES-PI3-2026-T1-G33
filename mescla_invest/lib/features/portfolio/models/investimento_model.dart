import 'package:mescla_invest/features/portfolio/models/posicao_model.dart';
import 'package:mescla_invest/features/portfolio/models/variacao_model.dart';

// Estágio de desenvolvimento da startup conforme documento de visão
enum EstagioStartup {
  nova('Nova'),
  emOperacao('Em operação'),
  emExpansao('Em expansão');

  const EstagioStartup(this.label);
  final String label;
}

// Representa um investimento em startup do Mescla com seus dados de posição e variação.
class InvestimentoModel {
  final String id;
  final String ticker;
  final String nome;
  final EstagioStartup estagio;
  final PosicaoModel posicao;
  final VariacaoModel variacao;

  InvestimentoModel({
    required this.id,
    required this.ticker,
    required this.nome,
    required this.estagio,
    required this.posicao,
    required this.variacao,
    });
}