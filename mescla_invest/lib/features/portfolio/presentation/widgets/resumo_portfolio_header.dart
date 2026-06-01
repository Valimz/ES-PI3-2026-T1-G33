import 'package:flutter/material.dart';
import 'package:mescla_invest/core/theme/app_theme.dart';

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
    final isPositiva = variacaoEmReais >= 0;
    final corVariacao = isPositiva ? AppColors.positive : AppColors.negative;
    final sinal = isPositiva ? '+' : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Carteira total',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatarMoeda(valorTotal),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositiva ? Icons.trending_up : Icons.trending_down,
                  color: AppColors.accent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '$sinal${_formatarMoeda(variacaoEmReais)} '
                  '($sinal${variacaoPercentual.toStringAsFixed(2)}%)',
                  style: TextStyle(
                    color: isPositiva ? AppColors.accent : const Color(0xFFFCA5A5),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatarMoeda(double valor) {
    final isNegativo = valor < 0;
    final valorAbsoluto =
        valor.abs().toStringAsFixed(2).replaceAll('.', ',');
    return '${isNegativo ? '-' : ''}R\$ $valorAbsoluto';
  }
}
