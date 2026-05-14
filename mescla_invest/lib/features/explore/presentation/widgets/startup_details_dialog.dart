import 'package:flutter/material.dart';
import 'package:mescla_invest/core/theme/app_theme.dart';

/// Exibe um pop-up com detalhes de uma startup.
/// [startup] deve conter pelo menos as chaves: name, stage, val.
void showStartupDetailsDialog(
    BuildContext context, Map<String, dynamic> startup) {
  final name = startup['name']?.toString() ?? 'Startup';
  final stage = startup['stage']?.toString() ?? '—';
  final val = startup['val']?.toString() ?? 'R\$ 0,00';

  // Gera duas letras para o avatar baseado no nome
  final initials =
      name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();

  // Cor do badge de estágio
  Color stageBadgeColor;
  switch (stage.toLowerCase()) {
    case 'nova':
    case 'semente':
      stageBadgeColor = AppColors.teal;
      break;
    case 'em operação':
      stageBadgeColor = AppColors.positive;
      break;
    case 'em expansão':
      stageBadgeColor = const Color(0xFFD97706);
      break;
    default:
      stageBadgeColor = Colors.grey;
  }

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Ícone / Avatar ---
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Nome ---
              Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),

              // --- Badge de estágio ---
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: stageBadgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  stage,
                  style: TextStyle(
                    color: stageBadgeColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Dados ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                        Icons.monetization_on_outlined, 'Valor da Cota', val),
                    const Divider(height: 20),
                    _buildInfoRow(Icons.flag_outlined, 'Estágio', stage),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Botão investir ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // fecha o dialog
                    // Navega para a tela de negociação ou explore
                    Navigator.pushNamed(context, '/explore');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Investir',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // --- Botão fechar ---
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Fechar',
                  style: TextStyle(
                    color: AppColors.textBody,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildInfoRow(IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(icon, size: 20, color: AppColors.teal),
      const SizedBox(width: 12),
      Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textBody.withValues(alpha: 0.7),
        ),
      ),
      const Spacer(),
      Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    ],
  );
}
