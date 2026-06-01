// Nome: Felipe Augusto dos Santos Silva
// RA: 25003353

// Define os períodos disponíveis para filtragem da análise.
enum PeriodoAnalise {
  dia('1D'),
  semana('7D'),
  mes('1M'),
  semestre('6M'),
  ytd('YTD');

  const PeriodoAnalise(this.label);
  final String label;

  // Retorna a data inicial do período a partir de [referencia] (padrão: agora).
  // YTD é variável: do dia 1 de janeiro do ano corrente até hoje.
  DateTime inicioDoPeriodo([DateTime? referencia]) {
    final agora = referencia ?? DateTime.now();
    switch (this) {
      case PeriodoAnalise.dia:
        return agora.subtract(const Duration(days: 1));
      case PeriodoAnalise.semana:
        return agora.subtract(const Duration(days: 7));
      case PeriodoAnalise.mes:
        return agora.subtract(const Duration(days: 30));
      case PeriodoAnalise.semestre:
        return agora.subtract(const Duration(days: 182));
      case PeriodoAnalise.ytd:
        return DateTime(agora.year, 1, 1);
    }
  }
}
