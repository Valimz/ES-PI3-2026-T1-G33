import 'package:treino_de_tela/features/portfolio/models/posicao_model.dart';
import 'package:treino_de_tela/features/portfolio/models/variacao_model.dart';

enum EstagioStartup {
  nova('Nova'),
  emOperacao('Em operação'),
  emExpansao('Em expansão');

  const EstagioStartup(this.label);
  final String label;
}

enum StatusStartup {
  ativa('Ativa'),
  pausada('Pausada'),
  encerrada('Encerrada');

  const StatusStartup(this.label);
  final String label;
}

class InvestimentoModel {
  final String id;
  final String nome;
  final String descricao;
  final EstagioStartup estagio;
  final String setor;
  final double capitalAportado;
  final int tokensEmitidos;
  final List<String> socios;
  final List<double> participacaoSocietaria;
  final List<String> mentoresConselho;
  final String? videoDemo;
  final StatusStartup status;
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

  // Constrói um InvestimentoModel a partir de docs do Firestore.
  // startupDoc: documento da coleção 'startups'
  // assetDoc: documento de 'users/{uid}/assets' (pode ser null se usuário não tem posição)
  factory InvestimentoModel.fromFirestore(
    Map<String, dynamic> startupDoc, {
    Map<String, dynamic>? assetDoc,
  }) {
    final precoAtualStr = startupDoc['val']?.toString() ?? 'R\$ 0,00';
    final precoAtual = _parseCurrency(precoAtualStr);

    double quantidade = 0.0;
    double precoMedio = 0.0;
    double valorInvestido = 0.0;

    if (assetDoc != null) {
      final amountStr = assetDoc['amount']?.toString().split(' ').first ?? '0';
      quantidade = double.tryParse(amountStr.replaceAll(',', '.')) ?? 0.0;
      valorInvestido = _parseCurrency(assetDoc['value']?.toString() ?? 'R\$ 0,00');
      precoMedio = quantidade > 0 ? valorInvestido / quantidade : 0.0;
    }

    final valorAtualPosicao = quantidade * precoAtual;
    final variacaoReais = valorAtualPosicao - valorInvestido;
    final variacaoPercentual =
        valorInvestido > 0 ? (variacaoReais / valorInvestido) * 100 : 0.0;

    final stageStr = startupDoc['stage']?.toString().toLowerCase() ?? '';
    final estagio = stageStr.contains('expans')
        ? EstagioStartup.emExpansao
        : stageStr.contains('opera')
            ? EstagioStartup.emOperacao
            : EstagioStartup.nova;

    return InvestimentoModel(
      id: startupDoc['id']?.toString() ?? startupDoc['name'] ?? '',
      nome: startupDoc['name']?.toString() ?? '',
      descricao: startupDoc['description']?.toString() ?? '',
      estagio: estagio,
      setor: startupDoc['sector']?.toString() ?? '',
      capitalAportado: precoAtual,
      tokensEmitidos: 0,
      socios: [],
      participacaoSocietaria: [],
      mentoresConselho: [],
      videoDemo: null,
      status: StatusStartup.ativa,
      posicao: PosicaoModel(
        quantidade: quantidade,
        precoMedio: precoMedio,
        valorAtual: precoAtual,
      ),
      variacao: VariacaoModel(
        variacaoPercentual: variacaoPercentual,
        variacaoEmReais: variacaoReais,
      ),
    );
  }

  static double _parseCurrency(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^\d,.]'), '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }
}
