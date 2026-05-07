// Nome: Felipe Augusto dos Santos Silva
// RA: 25003353

// Nome: Felipe Augusto dos Santos Silva
// RA: 25003353

import 'package:flutter/material.dart';
import 'package:mescla_invest/features/portfolio/models/investimento_model.dart';

// Card com os principais dados da startup e da posição do investidor.
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
    // Sócios e mentores são exibidos em texto curto para manter o card compacto.
    final sociosResumo = _formatarListaComPercentuais(
      ativo.socios,
      ativo.participacaoSocietaria,
    );
    final mentoresResumo = _formatarLista(ativo.mentoresConselho);

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
            ativo.descricao,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF475569)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
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
              _Tag(
                label: ativo.videoDemo == null || ativo.videoDemo!.isEmpty
                    ? 'Sem vídeo demo'
                    : 'Vídeo demo disponível',
                backgroundColor: const Color(0xFFFFF7ED),
                textColor: const Color(0xFF9A3412),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Capital aportado: ${_formatarMoeda(ativo.capitalAportado)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Tokens emitidos: ${_formatarInteiro(ativo.tokensEmitidos)}',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Text(
            'Sócios: $sociosResumo',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF475569)),
          ),
          const SizedBox(height: 6),
          Text(
            'Mentores: $mentoresResumo',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF475569)),
          ),
          const SizedBox(height: 6),
          Text(
            '${ativo.posicao.quantidade.toStringAsFixed(4)} tokens na sua posição',
            style: const TextStyle(color: Color(0xFF475569)),
          ),
          const SizedBox(height: 4),
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

  // Formata valores inteiros sem máscara monetária.
  String _formatarInteiro(int valor) {
    return valor.toString();
  }

  // Junta uma lista simples em um texto curto.
  String _formatarLista(List<String> valores) {
    if (valores.isEmpty) {
      return 'Não informado';
    }
    return valores.join(', ');
  }

  // Combina nomes e percentuais de participação em uma única linha.
  String _formatarListaComPercentuais(
    List<String> nomes,
    List<double> percentuais,
  ) {
    if (nomes.isEmpty) {
      return 'Não informado';
    }

    return List.generate(nomes.length, (index) {
      final nome = nomes[index];
      if (index >= percentuais.length) {
        return nome;
      }

      final percentual = percentuais[index].toStringAsFixed(0);
      return '$nome ($percentual%)';
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
    // Pequeno marcador visual reaproveitável para estágio, setor e status.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }
}
