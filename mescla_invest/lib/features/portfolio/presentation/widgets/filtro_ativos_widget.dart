// Nome: Felipe Augusto dos Santos Silva
// RA: 25003353

import 'package:flutter/material.dart';

enum FiltroAtivo {
  todos('Todos'),
  acoes('Ações'),
  cripto('Cripto');

  const FiltroAtivo(this.label);

  final String label;
}

// Barra de filtros para alternar o tipo de ativo exibido na carteira.
class FiltroAtivosWidget extends StatelessWidget {
  const FiltroAtivosWidget({
    super.key,
    required this.selecionado,
    required this.onSelecionar,
  });

  final FiltroAtivo selecionado;
  final ValueChanged<FiltroAtivo> onSelecionar;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: FiltroAtivo.values
          .map(
            (filtro) => ChoiceChip(
              label: Text(filtro.label),
              selected: selecionado == filtro,
              onSelected: (_) => onSelecionar(filtro),
            ),
          )
          .toList(),
    );
  }
}
