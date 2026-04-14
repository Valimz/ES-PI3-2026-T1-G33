// Nome: Felipe Augusto dos Santos Silva
// RA: 25003353

import 'package:mescla_invest/features/analise/models/periodo_analise.dart';

// Repositório local temporário com séries históricas simuladas.
class SerieValorizacaoData {
  const SerieValorizacaoData._();

  static const Map<PeriodoAnalise, List<double>> _series = {
    PeriodoAnalise.dia: [5.12, 5.14, 5.11, 5.15, 5.18, 5.17, 5.19, 5.21],
    PeriodoAnalise.semana: [5.02, 5.08, 5.04, 5.10, 5.12, 5.11, 5.15],
    PeriodoAnalise.mes: [4.95, 4.98, 5.01, 4.99, 5.05, 5.08, 5.12, 5.18],
    PeriodoAnalise.semestre: [4.62, 4.71, 4.76, 4.84, 4.93, 5.02, 5.11],
    PeriodoAnalise.ano: [4.49, 4.58, 4.61, 4.70, 4.81, 4.94, 5.03, 5.19],
  };

  // Retorna a série do período selecionado de forma imutável.
  static List<double> pontosPorPeriodo(PeriodoAnalise periodo) {
    return List<double>.unmodifiable(_series[periodo]!);
  }
}
