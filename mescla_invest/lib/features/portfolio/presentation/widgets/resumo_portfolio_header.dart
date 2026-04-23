// Nome: Felipe Augusto dos Santos Silva
// RA: 25003353

import 'package:flutter/material.dart';

// Exibe o valor total da carteira e a variação consolidada.
class ResumoPortfolioHeader extends StatelessWidget {
  const ResumoPortfolioHeader({
    super.key,
    required this.valorTotal,
    required this.variacaoEmReais,
    required this.variacaoPercentual,
  });

  final double valorTotal;
  final double variacaoEmReais;
  final double variacaoPercentual;

  @override
  Widget build(BuildContext context) {
    // Define a cor do destaque de acordo com o resultado consolidado da carteira.
    final isPositiva = variacaoEmReais >= 0;
    final corVariacao = isPositiva
        ? const Color(0xFF166534)
        : const Color(0xFF991B1B);
    final sinal = isPositiva ? '+' : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E7490), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Carteira total',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            _formatarMoeda(valorTotal),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Text(
              '$sinal${_formatarMoeda(variacaoEmReais)} '
              '($sinal${variacaoPercentual.toStringAsFixed(2)}%)',
              style: TextStyle(color: corVariacao, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  String _formatarMoeda(double valor) {
    // Formata com padrão brasileiro sem depender de pacote extra.
    final valorAbsoluto = valor.abs().toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $valorAbsoluto';
  }
}
