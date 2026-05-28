import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mescla_invest/features/analise/models/periodo_analise.dart';
import 'package:mescla_invest/features/analise/presentation/widgets/resumo_valorizacao_card.dart';
import 'package:mescla_invest/features/analise/presentation/widgets/valorizacao_line_chart_card.dart';
import 'package:mescla_invest/features/portfolio/models/investimento_model.dart';
import 'package:mescla_invest/services/firestore_service.dart';

class AnaliseGraficosPage extends StatefulWidget {
  const AnaliseGraficosPage({super.key});

  @override
  State<AnaliseGraficosPage> createState() => _AnaliseGraficosPageState();
}

class _AnaliseGraficosPageState extends State<AnaliseGraficosPage> {
  PeriodoAnalise _periodoSelecionado = PeriodoAnalise.mes;
  InvestimentoModel? _startup;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startup ??=
        ModalRoute.of(context)?.settings.arguments as InvestimentoModel?;
  }

  @override
  Widget build(BuildContext context) {
    final startup = _startup;

    if (startup == null) {
      return const Scaffold(
        body: Center(child: Text('Selecione uma startup no portfólio.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Análise do Token'), centerTitle: true),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreService().getAcquisitionsByStartup(startup.nome),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Erro ao carregar histórico: ${snapshot.error}'),
              );
            }

            final transactions = snapshot.data ?? [];
            final pontos = _pontosPorTransacoes(
              transactions,
              startup,
              _periodoSelecionado,
            );
            final valorAtual = pontos.last;
            final valorInicial = pontos.first;
            final variacao = valorInicial != 0
                ? ((valorAtual - valorInicial) / valorInicial) * 100
                : 0.0;
            final isPositiva = variacao >= 0;

            return SingleChildScrollView(
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
                    transactions.isEmpty
                        ? 'Ainda não há histórico real. Exibindo preço inicial e atual.'
                        : 'Dados baseados nas transações registradas no sistema.',
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<double> _pontosPorTransacoes(
    List<Map<String, dynamic>> transactions,
    InvestimentoModel startup,
    PeriodoAnalise periodo,
  ) {
    final cutoff = _periodoInicio(periodo, DateTime.now());

    final pontos = transactions
        .where((tx) => tx['type'] == 'buy')
        .map((tx) {
          final date = _getTransactionDate(tx);
          if (date == null) return null;
          return _TransactionPoint(
            date: date,
            pricePerToken: _pricePerToken(tx),
          );
        })
        .where((point) => point != null && !point.date.isBefore(cutoff))
        .cast<_TransactionPoint>()
        .toList();

    pontos.sort((a, b) => a.date.compareTo(b.date));

    final valores = pontos.map((point) => point.pricePerToken).toList();

    if (valores.isEmpty) {
      return [startup.posicao.precoMedio, startup.posicao.valorAtual];
    }

    if (valores.last != startup.posicao.valorAtual) {
      valores.add(startup.posicao.valorAtual);
    }

    return valores;
  }

  DateTime _periodoInicio(PeriodoAnalise periodo, DateTime reference) {
    switch (periodo) {
      case PeriodoAnalise.dia:
        return reference.subtract(const Duration(days: 1));
      case PeriodoAnalise.semana:
        return reference.subtract(const Duration(days: 7));
      case PeriodoAnalise.mes:
        return reference.subtract(const Duration(days: 30));
      case PeriodoAnalise.semestre:
        return reference.subtract(const Duration(days: 180));
      case PeriodoAnalise.ytd:
        return DateTime(reference.year, 1, 1);
    }
  }

  double _pricePerToken(Map<String, dynamic> tx) {
    final amount = FirestoreService().parseCurrency(tx['amount']?.toString() ?? 'R\$ 0,00');
    final quotasStr = tx['quotas']?.toString().split(' ').first ?? '0';
    final quotas = double.tryParse(quotasStr.replaceAll(',', '.')) ?? 0.0;
    return quotas > 0 ? amount / quotas : 0.0;
  }

  DateTime? _getTransactionDate(Map<String, dynamic> tx) {
    final rawDate = tx['date'];
    if (rawDate is Timestamp) {
      return rawDate.toDate();
    }
    if (rawDate is DateTime) {
      return rawDate;
    }
    return null;
  }
}

class _TransactionPoint {
  const _TransactionPoint({
    required this.date,
    required this.pricePerToken,
  });

  final DateTime date;
  final double pricePerToken;
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
