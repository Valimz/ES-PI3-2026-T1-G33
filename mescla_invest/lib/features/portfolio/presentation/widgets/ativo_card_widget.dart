// Nome: Felipe Augusto dos Santos Silva
// RA: 25003353

import 'package:flutter/material.dart';
import 'package:mescla_invest/features/portfolio/models/investimento_model.dart';

// Card com os principais dados de posição e variação de um ativo.
class AtivoCardWidget extends StatelessWidget {
  const AtivoCardWidget({super.key, required this.ativo});

  final InvestimentoModel ativo;

  @override
  Widget build(BuildContext context) {
    // A direção da variação controla ícone e cor de destaque do card.
    final variacao = ativo.variacao.variacaoPercentual;
    final isPositiva = variacao >= 0;
    final corVariacao = isPositiva
        ? const Color(0xFF059669)
        : const Color(0xFFDC2626);
    final icone = isPositiva ? Icons.trending_up : Icons.trending_down;
    final sinal = isPositiva ? '+' : '';
    final valorPosicao = ativo.posicao.quantidade * ativo.posicao.valorAtual;

    return Container(
      padding: const EdgeInsets.all(14),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ativo.ticker,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0C4A6E),
                  ),
                ),
              ),
              const Spacer(),
              Icon(icone, color: corVariacao, size: 18),
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
          const SizedBox(height: 10),
          Text(
            ativo.nome,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '${ativo.posicao.quantidade.toStringAsFixed(4)} unidades',
            style: const TextStyle(color: Color(0xFF475569)),
          ),
          const SizedBox(height: 6),
          Text(
            'Posição: ${_formatarMoeda(valorPosicao)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Preço atual: ${_formatarMoeda(ativo.posicao.valorAtual)}',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  String _formatarMoeda(double valor) {
    // Mantém o mesmo padrão visual de moeda usado no restante da tela.
    final valorAbsoluto = valor.abs().toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $valorAbsoluto';
  }
}
