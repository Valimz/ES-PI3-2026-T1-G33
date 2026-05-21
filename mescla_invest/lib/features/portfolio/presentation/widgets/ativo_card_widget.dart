import 'package:flutter/material.dart';
import 'package:mescla_invest/core/theme/app_theme.dart';
import 'package:mescla_invest/features/portfolio/models/investimento_model.dart';

class AtivoCardWidget extends StatelessWidget {
  const AtivoCardWidget({super.key, required this.ativo, this.onTap});

  final InvestimentoModel ativo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final variacao = ativo.variacao.variacaoPercentual;
    final isPositiva = variacao >= 0;
    final corVariacao = isPositiva ? AppColors.positive : AppColors.negative;
    final icone = isPositiva ? Icons.trending_up : Icons.trending_down;
    final sinal = isPositiva ? '+' : '';
    final valorPosicao = ativo.posicao.quantidade * ativo.posicao.valorAtual;

    // Gera iniciais para o avatar
    final initials = ativo.nome.length >= 2
        ? ativo.nome.substring(0, 2).toUpperCase()
        : ativo.nome.toUpperCase();

    // Cor do badge de estágio (igual ao startup_details_dialog)
    Color stageBadgeColor;
    switch (ativo.estagio) {
      case EstagioStartup.nova:
        stageBadgeColor = AppColors.teal;
        break;
      case EstagioStartup.emOperacao:
        stageBadgeColor = AppColors.positive;
        break;
      case EstagioStartup.emExpansao:
        stageBadgeColor = const Color(0xFFD97706);
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: avatar + nome + variação
            Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ativo.nome,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: stageBadgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ativo.estagio.label,
                          style: TextStyle(
                            color: stageBadgeColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: corVariacao.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icone, color: corVariacao, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$sinal${variacao.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: corVariacao,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (ativo.descricao.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                ativo.descricao,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textBody,
                  fontSize: 13,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Info row
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInfoColumn(
                      'Preço atual',
                      _formatarMoeda(ativo.posicao.valorAtual),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: Colors.grey.shade300,
                  ),
                  Expanded(
                    child: _buildInfoColumn(
                      'Tokens',
                      ativo.posicao.quantidade.toStringAsFixed(4),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: Colors.grey.shade300,
                  ),
                  Expanded(
                    child: _buildInfoColumn(
                      'Posição',
                      _formatarMoeda(valorPosicao),
                    ),
                  ),
                ],
              ),
            ),

            if (ativo.setor.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.category_outlined,
                      size: 14, color: AppColors.teal),
                  const SizedBox(width: 6),
                  Text(
                    ativo.setor,
                    style: const TextStyle(
                      color: AppColors.textBody,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textBody.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  String _formatarMoeda(double valor) {
    final valorAbsoluto =
        valor.abs().toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $valorAbsoluto';
  }
}
