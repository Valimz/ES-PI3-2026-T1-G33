import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mescla_invest/core/theme/app_theme.dart';
import 'package:mescla_invest/features/explore/presentation/widgets/faq_publico_widget.dart';
import 'package:mescla_invest/features/explore/presentation/widgets/socios_card.dart';
import 'package:mescla_invest/features/explore/presentation/widgets/sumario_executivo_card.dart';
import 'package:mescla_invest/features/explore/presentation/widgets/video_card.dart';
import 'package:mescla_invest/services/backend_service.dart';

class StartupDetailPage extends StatelessWidget {
  final Map<String, dynamic>? startup;

  const StartupDetailPage({super.key, this.startup});

  Map<String, dynamic> _resolveStartup(BuildContext context) {
    if (startup != null) return startup!;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) return args;
    if (args is Map) return Map<String, dynamic>.from(args);
    return const {};
  }

  @override
  Widget build(BuildContext context) {
    final data = _resolveStartup(context);
    final name = data['name']?.toString() ?? 'Startup';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderSection(data: data),
            const SizedBox(height: 16),
            SumarioExecutivoCard(
              description: data['description']?.toString(),
              sector: data['sector']?.toString(),
            ),
            const SizedBox(height: 16),
            SociosCard(
              socios: _parseListOfMaps(data['socios']),
              mentoresConselho: _parseListOfStrings(data['mentoresConselho']),
            ),
            const SizedBox(height: 16),
            _FinancialSection(data: data),
            const SizedBox(height: 16),
            VideoCard(videoUrl: data['videoUrl']?.toString()),
            if ((data['videoUrl']?.toString() ?? '').isNotEmpty)
              const SizedBox(height: 16),
            FaqPublicoWidget(faq: _parseListOfMaps(data['faq'])),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.trending_up),
              label: const Text(
                'Investir nesta startup',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _showInvestBottomSheet(context, data),
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _parseListOfMaps(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  List<String> _parseListOfStrings(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
  }
}

class _HeaderSection extends StatelessWidget {
  final Map<String, dynamic> data;
  const _HeaderSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['name']?.toString() ?? 'Startup';
    final stage = data['stage']?.toString() ?? '—';
    final val = data['val']?.toString() ?? 'R\$ 0,00';
    final initials = name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
    final stageColor = stageBadgeColor(stage);

    return _Card(
      child: Row(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: stageColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    stage,
                    style: TextStyle(
                      color: stageColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Cota',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textBody.withValues(alpha: 0.7),
                ),
              ),
              Text(
                val,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinancialSection extends StatelessWidget {
  final Map<String, dynamic> data;
  const _FinancialSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final capitalRaw = data['capitalAportado'];
    final capital = capitalRaw is num
        ? capitalRaw.toDouble()
        : double.tryParse(capitalRaw?.toString() ?? '') ?? 0.0;
    final tokensRaw = data['tokensEmitidos'];
    final tokens = tokensRaw is num
        ? tokensRaw.toInt()
        : int.tryParse(tokensRaw?.toString() ?? '') ?? 0;

    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final tokenFormat = NumberFormat.decimalPattern('pt_BR');

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.account_balance_outlined,
                  size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Dados financeiros',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _financialMetric(
                  icon: Icons.attach_money,
                  label: 'Capital aportado',
                  value: capital > 0
                      ? currencyFormat.format(capital)
                      : 'Não informado',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _financialMetric(
                  icon: Icons.token_outlined,
                  label: 'Tokens emitidos',
                  value: tokens > 0
                      ? tokenFormat.format(tokens)
                      : 'Não informado',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _financialMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.teal),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textBody.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

Color stageBadgeColor(String stage) {
  switch (stage.toLowerCase()) {
    case 'nova':
    case 'semente':
      return AppColors.teal;
    case 'em operação':
      return AppColors.positive;
    case 'em expansão':
      return const Color(0xFFD97706);
    default:
      return Colors.grey;
  }
}

void _showInvestBottomSheet(
    BuildContext context, Map<String, dynamic> startup) {
  final TextEditingController amountController = TextEditingController();
  final name = startup['name']?.toString() ?? 'Startup';
  final val = startup['val']?.toString() ?? '—';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Investir em $name',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cota atual: $val',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textBody.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Valor a investir (R\$)',
                prefixIcon: const Icon(Icons.monetization_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final value = double.tryParse(
                      amountController.text.replaceAll(',', '.'));
                  if (value == null || value <= 0) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      const SnackBar(
                          content: Text('Insira um valor válido')),
                    );
                    return;
                  }
                  try {
                    await BackendService().negotiateAsset(startup, value);
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Investimento realizado com sucesso!')),
                      );
                    }
                  } catch (e) {
                    if (sheetContext.mounted) {
                      ScaffoldMessenger.of(sheetContext)
                          .showSnackBar(SnackBar(content: Text('Erro: $e')));
                    }
                  }
                },
                child: const Text(
                  'Confirmar Investimento',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    },
  );
}
