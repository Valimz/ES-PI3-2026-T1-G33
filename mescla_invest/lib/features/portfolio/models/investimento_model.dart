// Nome: Felipe Augusto dos Santos Silva
// RA: 25003353

import 'package:mescla_invest/features/portfolio/models/posicao_model.dart';
import 'package:mescla_invest/features/portfolio/models/variacao_model.dart';

// Estágio de desenvolvimento da startup conforme documento de visão.
enum EstagioStartup {
  nova('Nova'),
  emOperacao('Em operação'),
  emExpansao('Em expansão');

  const EstagioStartup(this.label);
  final String label;
}

// Status operacional da startup.
enum StatusStartup {
  ativa('Ativa'),
  pausada('Pausada'),
  encerrada('Encerrada');

  const StatusStartup(this.label);
  final String label;
}

/// Representa um investimento em startup do Mescla.
/// Mantém dados institucionais da startup e a posição do investidor.
class InvestimentoModel {
  final String id;
  final String nome;
  final String descricao;
  final EstagioStartup estagio;
  final String setor;
  final double capitalAportado; // Em reais
  final int tokensEmitidos; // Total de tokens da startup
  final List<String> socios; // Nomes dos sócios
  final List<double> participacaoSocietaria; // Percentuais correspondentes
  final List<String> mentoresConselho; // Mentores/Conselheiros
  final String? videoDemo; // URL do vídeo (opcional)
  final StatusStartup status;

  // Dados da posição de investimento do usuário
  final PosicaoModel posicao;
  final VariacaoModel variacao;

  InvestimentoModel({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.estagio,
    required this.setor,
    required this.capitalAportado,
    required this.tokensEmitidos,
    required this.socios,
    required this.participacaoSocietaria,
    required this.mentoresConselho,
    required this.videoDemo,
    required this.status,
    required this.posicao,
    required this.variacao,
  });
}
