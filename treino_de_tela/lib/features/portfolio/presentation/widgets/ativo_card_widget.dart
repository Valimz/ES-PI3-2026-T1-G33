import 'package:flutter/material.dart';
import 'package:treino_de_tela/features/portfolio/models/investimento_model.dart';

class AtivoCardWidget extends StatelessWidget {
  const AtivoCardWidget({super.key, required this.ativo, this.onTap});

  final InvestimentoModel ativo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final variacao = ativo.variacao.variacaoPercentual;
    final isPositiva = variacao >= 0;
    final corVariacao =
        isPositiva ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final icone = isPositiva ? Icons.trending_up : Icons.trending_down;
    final sinal = isPositiva ? '+' : '';
    final valorPosicao = ativo.posicao.quantidade * ativo.posicao.valorAtual;
    final sociosResumo = _formatarListaComPercentuais(
        ativo.socios, ativo.participacaoSocietaria);
    final mentoresResumo = _formatarLista(ativo.mentoresConselho);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
                color: Color(0x12000000),
                blurRadius: 14,
                offset: Offset(0, 8))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Tag(
                  label: ativo.estagio.label,
                  backgroundColor: const Color(0xFFE0F2FE),
                  textColor: const Color(0xFF0C4A6E),
                ),
                const Spacer(),
                Icon(icone, color: corVariacao, size: 18),
                const SizedBox(width: 4),
                Text(
                  '$sinal${variacao.toStringAsFixed(2)}%',
                  style: TextStyle(
                      color: corVariacao, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              ativo.nome,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (ativo.descricao.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                ativo.descricao,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF475569)),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (ativo.setor.isNotEmpty)
                  _Tag(
                    label: ativo.setor,
                    backgroundColor: const Color(0xFFF1F5F9),
                    textColor: const Color(0xFF334155),
                  ),
                _Tag(
                  label: ativo.status.label,
                  backgroundColor: const Color(0xFFE2E8F0),
                  textColor: const Color(0xFF334155),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Preço atual: ${_formatarMoeda(ativo.posicao.valorAtual)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${ativo.posicao.quantidade.toStringAsFixed(4)} tokens na posição',
              style: const TextStyle(color: Color(0xFF475569)),
            ),
            const SizedBox(height: 4),
            Text(
              'Posição: ${_formatarMoeda(valorPosicao)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (sociosResumo != 'Não informado') ...[
              const SizedBox(height: 4),
              Text(
                'Sócios: $sociosResumo',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF475569)),
              ),
            ],
            if (mentoresResumo != 'Não informado') ...[
              const SizedBox(height: 4),
              Text(
                'Mentores: $mentoresResumo',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF475569)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatarMoeda(double valor) {
    final valorAbsoluto =
        valor.abs().toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $valorAbsoluto';
  }

  String _formatarLista(List<String> valores) {
    if (valores.isEmpty) return 'Não informado';
    return valores.join(', ');
  }

  String _formatarListaComPercentuais(
      List<String> nomes, List<double> percentuais) {
    if (nomes.isEmpty) return 'Não informado';
    return List.generate(nomes.length, (index) {
      final nome = nomes[index];
      if (index >= percentuais.length) return nome;
      return '$nome (${percentuais[index].toStringAsFixed(0)}%)';
    }).join(', ');
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
    );
  }
}
