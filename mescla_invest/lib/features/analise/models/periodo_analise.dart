// Nome: Felipe Augusto dos Santos Silva
// RA: 25003353

// Define os períodos disponíveis para filtragem da análise.
enum PeriodoAnalise {
  dia('Diário'),
  semana('Semanal'),
  mes('Mensal'),
  semestre('Últimos 6M'),
  ytd('YTD');

  const PeriodoAnalise(this.label);
  final String label;
}
