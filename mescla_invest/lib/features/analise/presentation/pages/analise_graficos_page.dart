import 'package:flutter/material.dart';
import 'package:mescla_invest/core/theme/app_theme.dart';
import 'package:mescla_invest/features/analise/data/serie_valorizacao_data.dart';
import 'package:mescla_invest/features/analise/models/periodo_analise.dart';
import 'package:mescla_invest/features/analise/presentation/widgets/resumo_valorizacao_card.dart';
import 'package:mescla_invest/features/analise/presentation/widgets/valorizacao_line_chart_card.dart';
import 'package:mescla_invest/features/portfolio/models/investimento_model.dart';
import 'package:mescla_invest/services/backend_service.dart';
import 'package:mescla_invest/services/firestore_service.dart';
import 'package:mescla_invest/services/functions_service.dart';

// Ponto da série histórica real retornado por getGraphAsset.
class _PontoSerie {
  const _PontoSerie({required this.data, required this.valor});

  final DateTime data;
  final double valor;
}

class AnaliseGraficosPage extends StatefulWidget {
  const AnaliseGraficosPage({super.key});

  @override
  State<AnaliseGraficosPage> createState() => _AnaliseGraficosPageState();
}

class _AnaliseGraficosPageState extends State<AnaliseGraficosPage> {
  PeriodoAnalise _periodoSelecionado = PeriodoAnalise.mes;
  InvestimentoModel? _startup;

  List<_PontoSerie> _serieReal = const [];
  bool _carregandoSerie = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startup == null) {
      _startup = ModalRoute.of(context)?.settings.arguments as InvestimentoModel?;
      if (_startup != null) {
        _carregarSerie();
      } else {
        _carregandoSerie = false;
      }
    }
  }

  // Busca a série histórica real da startup via Cloud Function getGraphAsset.
  Future<void> _carregarSerie() async {
    final nome = _startup?.nome;
    if (nome == null) return;
    setState(() => _carregandoSerie = true);
    try {
      final resposta = await FunctionsService().getGraphAsset(nome);
      final series = resposta['series'];
      final pontos = <_PontoSerie>[];
      if (series is List) {
        for (final item in series) {
          if (item is Map) {
            final dataStr = item['date']?.toString();
            final valor = item['value'];
            if (dataStr != null && valor is num) {
              final data = DateTime.tryParse(dataStr);
              if (data != null) {
                pontos.add(_PontoSerie(data: data, valor: valor.toDouble()));
              }
            }
          }
        }
      }
      pontos.sort((a, b) => a.data.compareTo(b.data));
      if (!mounted) return;
      setState(() {
        _serieReal = pontos;
        _carregandoSerie = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _serieReal = const [];
        _carregandoSerie = false;
      });
    }
  }

  // Pontos do período selecionado: usa a série real (filtrada por data) quando
  // disponível; caso contrário recorre à série simulada local (startup nova).
  List<double> _pontosDoPeriodo(InvestimentoModel startup) {
    if (_serieReal.isNotEmpty) {
      final inicio = _periodoSelecionado.inicioDoPeriodo();
      final filtrados = _serieReal
          .where((p) => !p.data.isBefore(inicio))
          .map((p) => p.valor)
          .toList();
      if (filtrados.length >= 2) {
        return filtrados;
      }
      if (_serieReal.length >= 2) {
        return _serieReal.map((p) => p.valor).toList();
      }
    }
    return SerieValorizacaoData.pontosPorPeriodo(
      periodo: _periodoSelecionado,
      startup: startup,
    );
  }

  @override
  Widget build(BuildContext context) {
    final startup = _startup;

    if (startup == null) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('Análise do Token'), centerTitle: true),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.show_chart, size: 48, color: Color(0xFF94A3B8)),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Selecione uma startup no portfólio para ver a análise.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/portfolio');
                  }
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar ao portfólio'),
              ),
            ],
          ),
        ),
      );
    }

    if (_carregandoSerie) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('Análise do Token'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final pontos = _pontosDoPeriodo(startup);
    final valorAtual = pontos.last;
    final valorInicial = pontos.first;
    final variacao = valorInicial != 0
        ? ((valorAtual - valorInicial) / valorInicial) * 100
        : 0.0;
    final isPositiva = variacao >= 0;

    return Scaffold(
      appBar: AppBar(
          title: const Text('Análise do Token'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Evolução da valorização',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                _serieReal.isNotEmpty
                    ? 'Dados baseados na série histórica real do token.'
                    : 'Dados baseados na série histórica simulada do token.',
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              _StartupResumoCard(startup: startup),
              const SizedBox(height: 16),
              ResumoValorizacaoCard(
                valorAtual: valorAtual,
                variacao: variacao,
                isPositiva: isPositiva,
              ),
              const SizedBox(height: 16),
              Text('Período da valorização',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PeriodoAnalise.values
                    .map((periodo) => ChoiceChip(
                          label: Text(periodo.label),
                          selected: _periodoSelecionado == periodo,
                          onSelected: (_) =>
                              setState(() => _periodoSelecionado = periodo),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              ValorizacaoLineChartCard(
                pontos: pontos,
                isPositiva: isPositiva,
                titulo: 'Valorização de ${startup.nome}',
              ),
              const SizedBox(height: 24),
              Text('Ações', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _comprarMais,
                  icon: const Icon(Icons.add),
                  label: const Text('Comprar mais'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _venderParte,
                      icon: const Icon(Icons.pie_chart_outline),
                      label: const Text('Vender parte'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _venderTudo,
                      icon: const Icon(Icons.sell_outlined),
                      label: const Text('Vender tudo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Busca o ativo do usuário (com o id do documento) pelo nome da startup.
  Future<Map<String, dynamic>?> _buscarAtivo() async {
    final assets = await FirestoreService().getUserAssets().first;
    for (final a in assets) {
      if (a['name'] == _startup?.nome) return a;
    }
    return null;
  }

  // Busca o documento da startup (para obter o preço atual 'val').
  Future<Map<String, dynamic>?> _buscarStartup() async {
    final startups = await FirestoreService().getStartups().first;
    for (final s in startups) {
      if (s['id'] == _startup?.id || s['name'] == _startup?.nome) return s;
    }
    return null;
  }

  Future<void> _venderTudo() async {
    final messenger = ScaffoldMessenger.of(context);
    final asset = await _buscarAtivo();
    if (!mounted) return;
    if (asset == null || asset['id'] == null) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Ativo não encontrado na carteira.')));
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Vender todos os tokens?'),
          content: Text(
              'Você venderá todos os tokens de ${asset['name']}. Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Vender'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;
    try {
      await BackendService().sellAllAsset(asset);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
          content: Text('Todos os tokens de ${asset['name']} vendidos!')));
      Navigator.pop(context);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erro ao vender: $e')));
    }
  }

  Future<void> _venderParte() async {
    final messenger = ScaffoldMessenger.of(context);
    final asset = await _buscarAtivo();
    if (!mounted) return;
    if (asset == null || asset['id'] == null) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Ativo não encontrado na carteira.')));
      return;
    }

    final amountStr = asset['amount']?.toString() ?? '0 Tokens';
    final parts = amountStr.split(' ');
    final totalQuotas =
        double.tryParse((parts.first).replaceAll(',', '.')) ?? 0.0;
    final unitLabel = parts.length > 1 ? parts.sublist(1).join(' ') : 'Tokens';

    if (totalQuotas <= 0) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Nenhum token disponível para venda.')));
      return;
    }

    final controller = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Vender parte de ${asset['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Você possui ${totalQuotas.toStringAsFixed(1).replaceAll('.', ',')} $unitLabel',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Tokens a vender',
                  prefixIcon: const Icon(Icons.pie_chart_outline),
                  helperText:
                      'Máximo: ${totalQuotas.toStringAsFixed(1).replaceAll('.', ',')}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final v =
                    double.tryParse(controller.text.replaceAll(',', '.'));
                if (v == null || v <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                          content: Text('Insira uma quantidade válida')));
                  return;
                }
                if (v > totalQuotas + 1e-9) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Quantidade maior do que o disponível')));
                  return;
                }
                Navigator.pop(dialogContext, v);
              },
              child: const Text('Vender'),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    try {
      await BackendService().sellPartialAsset(asset, result);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
          content: Text(
              'Venda de ${result.toStringAsFixed(1).replaceAll('.', ',')} $unitLabel de ${asset['name']} realizada!')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erro ao vender: $e')));
    }
  }

  Future<void> _comprarMais() async {
    final startupDoc = await _buscarStartup();
    if (!mounted) return;
    final startupMap = startupDoc ??
        {
          'name': _startup?.nome,
          'val':
              'R\$ ${_startup?.posicao.valorAtual.toStringAsFixed(2).replaceAll('.', ',')}',
        };
    final val = startupMap['val']?.toString() ?? '—';
    final controller = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Investir em ${startupMap['name']}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              Text('Token atual: $val',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textBody.withValues(alpha: 0.7))),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Valor a investir (R\$)',
                  prefixIcon: const Icon(Icons.monetization_on),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final value =
                        double.tryParse(controller.text.replaceAll(',', '.'));
                    if (value == null || value <= 0) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(
                              content: Text('Insira um valor válido')));
                      return;
                    }
                    try {
                      await BackendService().negotiateAsset(startupMap, value);
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Investimento realizado com sucesso!')));
                      }
                    } catch (e) {
                      if (sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                            SnackBar(content: Text('Erro: $e')));
                      }
                    }
                  },
                  child: const Text('Confirmar Investimento',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _StartupResumoCard extends StatelessWidget {
  const _StartupResumoCard({required this.startup});
  final InvestimentoModel startup;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Color(0x12000000),
              blurRadius: 14,
              offset: Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            startup.nome,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (startup.descricao.isNotEmpty)
            Text(startup.descricao,
                style: const TextStyle(color: Color(0xFF475569))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (startup.setor.isNotEmpty) _Tag(label: startup.setor),
              _Tag(label: startup.estagio.label),
              _Tag(label: startup.status.label),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Preço atual: R\$ ${startup.posicao.valorAtual.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (startup.posicao.quantidade > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Sua posição: ${startup.posicao.quantidade.toStringAsFixed(2)} tokens',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontWeight: FontWeight.w700, color: Color(0xFF334155)),
      ),
    );
  }
}
