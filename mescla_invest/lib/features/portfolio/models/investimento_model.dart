import 'package:mescla_invest/features/portfolio/models/posicao_model.dart';
import 'package:mescla_invest/features/portfolio/models/variacao_model.dart';

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
    this.faq = const [],
  });

  final List<Map<String, dynamic>> faq;

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

    final capitalAportadoFirestore =
        _parseNum(startupDoc['capitalAportado'])?.toDouble() ?? precoAtual;
    final tokensEmitidosFirestore =
        _parseNum(startupDoc['tokensEmitidos'])?.toInt() ?? 0;

    final sociosMap = _parseListOfMaps(startupDoc['socios']);
    final socios = <String>[];
    final participacao = <double>[];
    for (final s in sociosMap) {
      socios.add(s['nome']?.toString() ?? '');
      participacao.add(_parseNum(s['percentual'])?.toDouble() ?? 0.0);
    }

    final mentores = _parseListOfStrings(startupDoc['mentoresConselho']);

    final videoUrl = startupDoc['videoUrl']?.toString();
    final videoDemo =
        (videoUrl == null || videoUrl.isEmpty || videoUrl == 'null')
            ? null
            : videoUrl;

    final statusStr = startupDoc['status']?.toString().toLowerCase() ?? 'ativa';
    final status = statusStr.contains('pausad')
        ? StatusStartup.pausada
        : statusStr.contains('encerr')
            ? StatusStartup.encerrada
            : StatusStartup.ativa;

    return InvestimentoModel(
      id: startupDoc['id']?.toString() ?? startupDoc['name'] ?? '',
      nome: startupDoc['name']?.toString() ?? '',
      descricao: startupDoc['description']?.toString() ?? '',
      estagio: estagio,
      setor: startupDoc['sector']?.toString() ?? '',
      capitalAportado: capitalAportadoFirestore,
      tokensEmitidos: tokensEmitidosFirestore,
      socios: socios,
      participacaoSocietaria: participacao,
      mentoresConselho: mentores,
      videoDemo: videoDemo,
      status: status,
      faq: _parseListOfMaps(startupDoc['faq']),
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

  static num? _parseNum(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw;
    return num.tryParse(raw.toString().replaceAll(',', '.'));
  }

  static List<Map<String, dynamic>> _parseListOfMaps(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  static List<String> _parseListOfStrings(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
