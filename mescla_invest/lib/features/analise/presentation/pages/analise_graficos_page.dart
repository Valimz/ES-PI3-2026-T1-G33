// Nome: Felipe Augusto dos Santos Silva
// RA: 25003353

import 'package:flutter/material.dart';
import 'package:mescla_invest/features/analise/data/serie_valorizacao_data.dart';
import 'package:mescla_invest/features/analise/models/periodo_analise.dart';
import 'package:mescla_invest/features/analise/presentation/widgets/resumo_valorizacao_card.dart';
import 'package:mescla_invest/features/analise/presentation/widgets/valorizacao_line_chart_card.dart';
import 'package:mescla_invest/features/portfolio/data/portfolio_mock_data.dart';
import 'package:mescla_invest/features/portfolio/models/investimento_model.dart';

// Tela principal de análise com resumo, startup selecionada e gráfico filtrável por período.
class AnaliseGraficosPage extends StatefulWidget {
  const AnaliseGraficosPage({super.key});

  @override
  State<AnaliseGraficosPage> createState() => _AnaliseGraficosPageState();
}

class _AnaliseGraficosPageState extends State<AnaliseGraficosPage> {
  PeriodoAnalise _periodoSelecionado = PeriodoAnalise.mes;
  late InvestimentoModel _startupSelecionada;

  @override
  void initState() {
    super.initState();
    _startupSelecionada = mockPortfolio.first;
  }

  @override
  Widget build(BuildContext context) {
    // Calcula dados de resumo com base na startup e no período ativos.
    final pontos = SerieValorizacaoData.pontosPorPeriodo(
      periodo: _periodoSelecionado,
      startup: _startupSelecionada,
    );
    final valorAtual = pontos.last;
    final valorInicial = pontos.first;
    final variacao = ((valorAtual - valorInicial) / valorInicial) * 100;
    final isPositiva = variacao >= 0;
    final startupsDisponiveis = mockPortfolio;

    return Scaffold(
      appBar: AppBar(title: const Text('Análise do Token'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Evolução da valorização por startup',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Os dados abaixo usam mocks locais e servem para validar a experiência visual antes da integração com backend.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              _StartupResumoCard(startup: _startupSelecionada),
              const SizedBox(height: 16),
              Text(
                'Startup analisada',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                // Chips para trocar rapidamente a startup em análise.
                children: startupsDisponiveis
                    .map(
                      (startup) => ChoiceChip(
                        label: Text(startup.nome),
                        selected: _startupSelecionada.id == startup.id,
                        onSelected: (_) {
                          setState(() => _startupSelecionada = startup);
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              ResumoValorizacaoCard(
                valorAtual: valorAtual,
                variacao: variacao,
                isPositiva: isPositiva,
              ),
              const SizedBox(height: 16),
              Text(
                'Período da valorização',
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
              ValorizacaoLineChartCard(
                pontos: pontos,
                isPositiva: isPositiva,
                titulo: 'Valorização de ${_startupSelecionada.nome}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartupResumoCard extends StatelessWidget {
  const _StartupResumoCard({required this.startup});

  final InvestimentoModel startup;

  @override
  Widget build(BuildContext context) {
    // Mostra os dados institucionais da startup selecionada antes do gráfico.
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
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            startup.nome,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            startup.descricao,
            style: const TextStyle(color: Color(0xFF475569)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(label: startup.setor),
              _Tag(label: startup.estagio.label),
              _Tag(label: startup.status.label),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Capital aportado: R\$ ${startup.capitalAportado.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Tokens emitidos: ${startup.tokensEmitidos}',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
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
    // Pequena marca visual para setar setor, estágio e status.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF334155),
        ),
      ),
    );
  }
}
