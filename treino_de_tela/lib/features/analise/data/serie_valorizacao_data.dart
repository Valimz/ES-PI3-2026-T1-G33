import 'package:treino_de_tela/features/analise/models/periodo_analise.dart';
import 'package:treino_de_tela/features/portfolio/models/investimento_model.dart';

class SerieValorizacaoData {
  const SerieValorizacaoData._();

  static const Map<PeriodoAnalise, List<double>> _series = {
    PeriodoAnalise.dia: [5.12, 5.14, 5.11, 5.15, 5.18, 5.17, 5.19, 5.21],
    PeriodoAnalise.semana: [5.02, 5.08, 5.04, 5.10, 5.12, 5.11, 5.15],
    PeriodoAnalise.mes: [4.95, 4.98, 5.01, 4.99, 5.05, 5.08, 5.12, 5.18],
    PeriodoAnalise.semestre: [4.62, 4.71, 4.76, 4.84, 4.93, 5.02, 5.11],
    PeriodoAnalise.ano: [4.49, 4.58, 4.61, 4.70, 4.81, 4.94, 5.03, 5.19],
  };

  static List<double> pontosPorPeriodo({
    required PeriodoAnalise periodo,
    required InvestimentoModel startup,
  }) {
    final base = _series[periodo]!;
    final valorInicial = startup.posicao.precoMedio > 0
        ? startup.posicao.precoMedio
        : startup.posicao.valorAtual;
    final valorFinal = startup.posicao.valorAtual;
    final baseInicial = base.first;
    final baseFinal = base.last;
    final variacaoBase = baseFinal - baseInicial;

    final pontos = base.map((ponto) {
      if (variacaoBase == 0) return valorInicial;
      final progresso = (ponto - baseInicial) / variacaoBase;
      return valorInicial + ((valorFinal - valorInicial) * progresso);
    }).toList();

    return List<double>.unmodifiable(pontos);
  }
}
