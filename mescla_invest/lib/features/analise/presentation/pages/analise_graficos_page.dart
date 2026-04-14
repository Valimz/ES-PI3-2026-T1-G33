// Nome: Felipe Augusto dos Santos Silva
// RA: 25003353

import 'package:flutter/material.dart';
import 'package:mescla_invest/features/analise/data/serie_valorizacao_data.dart';
import 'package:mescla_invest/features/analise/models/periodo_analise.dart';
import 'package:mescla_invest/features/analise/presentation/widgets/resumo_valorizacao_card.dart';
import 'package:mescla_invest/features/analise/presentation/widgets/valorizacao_line_chart_card.dart';

// Tela principal de análise com resumo e gráfico filtrável por período.
class AnaliseGraficosPage extends StatefulWidget {
  const AnaliseGraficosPage({super.key});

  @override
  State<AnaliseGraficosPage> createState() => _AnaliseGraficosPageState();
}

class _AnaliseGraficosPageState extends State<AnaliseGraficosPage> {
  PeriodoAnalise _periodoSelecionado = PeriodoAnalise.mes;

  @override
  Widget build(BuildContext context) {
    // Calcula dados de resumo com base no período ativo.
    final pontos = SerieValorizacaoData.pontosPorPeriodo(_periodoSelecionado);
    final valorAtual = pontos.last;
    final valorInicial = pontos.first;
    final variacao = ((valorAtual - valorInicial) / valorInicial) * 100;
    final isPositiva = variacao >= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise e Gráficos'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResumoValorizacaoCard(
                valorAtual: valorAtual,
                variacao: variacao,
                isPositiva: isPositiva,
              ),
              const SizedBox(height: 16),
              Text(
                'Período da análise',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                // Chips para troca rápida do período analisado.
                children: PeriodoAnalise.values
                    .map(
                      (periodo) => ChoiceChip(
                        label: Text(periodo.label),
                        selected: _periodoSelecionado == periodo,
                        onSelected: (_) {
                          setState(() => _periodoSelecionado = periodo);
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              ValorizacaoLineChartCard(pontos: pontos, isPositiva: isPositiva),
            ],
          ),
        ),
      ),
    );
  }
}
