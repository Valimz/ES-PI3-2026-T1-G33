// Nome: Felipe Augusto dos Santos Silva
// RA: 25003353

import 'package:flutter/material.dart';

enum FiltroStartup {
  todos('Todos'),
  nova('Nova'),
  emOperacao('Em operação'),
  emExpansao('Em expansão');

  const FiltroStartup(this.label);

  final String label;
}

// Barra de filtros para alternar o estágio de desenvolvimento das startups no portfólio.
class FiltroAtivosWidget extends StatelessWidget {
  const FiltroAtivosWidget({
    super.key,
    required this.selecionado,
    required this.onSelecionar,
  });

  final FiltroStartup selecionado;
  final ValueChanged<FiltroStartup> onSelecionar;

  @override
  Widget build(BuildContext context) {
    // Renderiza os filtros de forma compacta para caber em telas menores.
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: FiltroStartup.values
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
