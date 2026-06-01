import 'package:flutter/material.dart';
import 'package:mescla_invest/core/theme/app_theme.dart';

enum FiltroStartup {
  todos('Todos'),
  nova('Nova'),
  emOperacao('Em operação'),
  emExpansao('Em expansão');

  const FiltroStartup(this.label);
  final String label;
}

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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: FiltroStartup.values
          .map((filtro) {
            final isSelected = selecionado == filtro;
            return GestureDetector(
              onTap: () => onSelecionar(filtro),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  filtro.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textBody,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          })
          .toList(),
    );
  }
}
