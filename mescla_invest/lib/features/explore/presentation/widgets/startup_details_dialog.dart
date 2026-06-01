import 'package:flutter/material.dart';
import 'package:mescla_invest/core/theme/app_theme.dart';
import 'package:mescla_invest/services/backend_service.dart';
import 'package:mescla_invest/features/explore/presentation/pages/startup_questions_page.dart' as mescla_startup_questions;

/// Exibe um pop-up com detalhes de uma startup.
/// [startup] deve conter pelo menos as chaves: name, stage, val.
void showStartupDetailsDialog(
    BuildContext context, Map<String, dynamic> startup) {
  showDialog(
    context: context,
    builder: (context) {
      return _StartupDetailsDialog(startup: startup);
    },
  );
}

class _StartupDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> startup;

  const _StartupDetailsDialog({required this.startup});

  @override
  State<_StartupDetailsDialog> createState() => _StartupDetailsDialogState();
}

class _StartupDetailsDialogState extends State<_StartupDetailsDialog> {
  bool _showInvestForm = false;
  bool _isLoading = false;
  final TextEditingController _amountController = TextEditingController();

  late final String name;
  late final String stage;
  late final String val;
  late final String initials;
  late final Color stageBadgeColor;

  @override
  void initState() {
    super.initState();
    name = widget.startup['name']?.toString() ?? 'Startup';
    stage = widget.startup['stage']?.toString() ?? '—';
    val = widget.startup['val']?.toString() ?? 'R\$ 0,00';

    initials = name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();

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
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleInvest() async {
    final value =
        double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insira um valor válido')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await BackendService().negotiateAsset(widget.startup, value);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Investimento realizado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
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
                        Icons.monetization_on_outlined, 'Valor do Token', val),
                    const Divider(height: 20),
                    _buildInfoRow(Icons.flag_outlined, 'Estágio', stage),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Formulário de investimento (aparece ao clicar em Investir) ---
              if (_showInvestForm) ...[
                TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Valor a investir (R\$)',
                    prefixIcon: const Icon(Icons.monetization_on),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleInvest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Confirmar Investimento',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => _showInvestForm = false),
                  child: const Text(
                    'Voltar',
                    style: TextStyle(
                      color: AppColors.textBody,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ] else ...[
                // --- Botão investir ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _showInvestForm = true);
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
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // --- Botão Perguntas (Q&A) ---
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => mescla_startup_questions.StartupQuestionsPage(startup: widget.startup),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Perguntas (Q&A)',
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
            ],
          ),
        ),
      ),
      ),
    );
  }
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
