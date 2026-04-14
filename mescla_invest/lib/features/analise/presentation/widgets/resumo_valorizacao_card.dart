// Nome: Felipe Augusto dos Santos Silva
// RA: 25003353

import 'package:flutter/material.dart';

// Exibe o valor atual e a variação percentual da cotação.
class ResumoValorizacaoCard extends StatelessWidget {
  const ResumoValorizacaoCard({
    super.key,
    required this.valorAtual,
    required this.variacao,
    required this.isPositiva,
  });

  final double valorAtual;
  final double variacao;
  final bool isPositiva;

  @override
  Widget build(BuildContext context) {
    // Define cor e ícone com base no sinal da variação.
    final corVariacao = isPositiva
        ? const Color(0xFF059669)
        : const Color(0xFFDC2626);
    final icone = isPositiva ? Icons.trending_up : Icons.trending_down;
    final sinal = isPositiva ? '+' : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
            'Cotação Atual',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            'R\$ ${valorAtual.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icone, size: 16, color: corVariacao),
                const SizedBox(width: 4),
                Text(
                  '$sinal${variacao.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: corVariacao,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
