// Nome: Felipe Augusto dos Santos Silva
// RA: 25003353

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// Card com visualização da série de valorização em gráfico de linha.
class ValorizacaoLineChartCard extends StatelessWidget {
  const ValorizacaoLineChartCard({
    super.key,
    required this.pontos,
    required this.isPositiva,
  });

  final List<double> pontos;
  final bool isPositiva;

  @override
  Widget build(BuildContext context) {
    // Cor do gráfico muda de acordo com tendência positiva/negativa.
    final corLinha = isPositiva
        ? const Color(0xFF059669)
        : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Valorização da moeda',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: LineChart(_lineChartData(pontos, corLinha)),
          ),
        ],
      ),
    );
  }

  LineChartData _lineChartData(List<double> valores, Color corLinha) {
    // Converte os valores da série para pontos (x, y) do gráfico.
    final spots = valores
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();

    // Ajusta limites verticais para dar respiro visual ao traçado.
    final minY = valores.reduce((a, b) => a < b ? a : b) - 0.05;
    final maxY = valores.reduce((a, b) => a > b ? a : b) + 0.05;

    return LineChartData(
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 0.05,
        verticalInterval: 1,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: Color(0xFFE2E8F0), strokeWidth: 1),
        getDrawingVerticalLine: (_) =>
            const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              if (value % 2 != 0) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                meta: meta,
                child: Text('P${value.toInt() + 1}'),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 52,
            interval: 0.1,
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(
                meta: meta,
                child: Text(value.toStringAsFixed(2)),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: corLinha,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                corLinha.withValues(alpha: 0.24),
                corLinha.withValues(alpha: 0.04),
              ],
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF0F172A),
          getTooltipItems: (touchedSpots) {
            return touchedSpots
                .map(
                  (spot) => LineTooltipItem(
                    'R\$ ${spot.y.toStringAsFixed(2)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                .toList();
          },
        ),
      ),
    );
  }
}
