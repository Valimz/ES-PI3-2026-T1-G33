enum PeriodoAnalise {
  dia('1D'),
  semana('7D'),
  mes('1M'),
  semestre('6M'),
  ano('1A');

  const PeriodoAnalise(this.label);
  final String label;
}
