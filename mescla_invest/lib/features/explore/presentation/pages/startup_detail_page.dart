import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mescla_invest/core/theme/app_theme.dart';
import 'package:mescla_invest/features/explore/presentation/widgets/faq_publico_widget.dart';
import 'package:mescla_invest/features/explore/presentation/widgets/socios_card.dart';
import 'package:mescla_invest/features/explore/presentation/widgets/sumario_executivo_card.dart';
import 'package:mescla_invest/features/explore/presentation/widgets/video_card.dart';
import 'package:mescla_invest/services/backend_service.dart';
import 'package:mescla_invest/services/firestore_service.dart';

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
    final startupId = data['id']?.toString() ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getUserAssets(),
        builder: (context, snapshot) {
          final assets = snapshot.data ?? const <Map<String, dynamic>>[];
          Map<String, dynamic>? userAsset;
          double userQuotas = 0.0;
          for (final asset in assets) {
            if (asset['name']?.toString() != name) continue;
            final amountStr =
                asset['amount']?.toString().split(' ').first ?? '0';
            final quotas =
                double.tryParse(amountStr.replaceAll(',', '.')) ?? 0.0;
            if (quotas > 0) {
              userAsset = asset;
              userQuotas = quotas;
              break;
            }
          }
          final isInvestor = userAsset != null;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeaderSection(data: data),
                const SizedBox(height: 16),
                if (isInvestor) ...[
                  const _InvestorBadge(),
                  const SizedBox(height: 12),
                  _UserPositionCard(
                    quotas: userQuotas,
                    valorAplicado: userAsset['value']?.toString() ?? 'R\$ 0,00',
                  ),
                  const SizedBox(height: 16),
                ],
                SumarioExecutivoCard(
                  description: data['description']?.toString(),
                  sector: data['sector']?.toString(),
                ),
                const SizedBox(height: 16),
                SociosCard(
                  socios: _parseListOfMaps(data['socios']),
                  mentoresConselho:
                      _parseListOfStrings(data['mentoresConselho']),
                ),
                const SizedBox(height: 16),
                _FinancialSection(data: data),
                const SizedBox(height: 16),
                VideoCard(videoUrl: data['videoUrl']?.toString()),
                if ((data['videoUrl']?.toString() ?? '').isNotEmpty)
                  const SizedBox(height: 16),
                FaqPublicoWidget(faq: _parseListOfMaps(data['faq'])),
                if (isInvestor && startupId.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _PrivateQuestionForm(startupId: startupId),
                  const SizedBox(height: 16),
                  _MyPrivateQuestionsList(startupId: startupId),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreService().getUserAssets(),
            builder: (context, snapshot) {
              final assets = snapshot.data ?? const <Map<String, dynamic>>[];
              Map<String, dynamic>? userAsset;
              for (final asset in assets) {
                if (asset['name']?.toString() != name) continue;
                final amountStr =
                    asset['amount']?.toString().split(' ').first ?? '0';
                final q =
                    double.tryParse(amountStr.replaceAll(',', '.')) ?? 0.0;
                if (q > 0) {
                  userAsset = asset;
                  break;
                }
              }

              if (userAsset == null) {
                return SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.trending_up),
                    label: const Text(
                      'Investir nesta startup',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                );
              }

              final ownedAsset = userAsset;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'Comprar mais',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.call_split),
                            label: const Text('Vender parte'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () =>
                                _showPartialSellSheet(context, ownedAsset),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.sell_outlined),
                            label: const Text('Vender tudo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () =>
                                _confirmAndSellAll(context, ownedAsset),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
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
                'Token',
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

class _InvestorBadge extends StatelessWidget {
  const _InvestorBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.positive.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.positive.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: AppColors.positive),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Você é investidor desta startup',
              style: TextStyle(
                color: AppColors.positive,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivateQuestionForm extends StatefulWidget {
  final String startupId;
  const _PrivateQuestionForm({required this.startupId});

  @override
  State<_PrivateQuestionForm> createState() => _PrivateQuestionFormState();
}

class _PrivateQuestionFormState extends State<_PrivateQuestionForm> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite uma pergunta antes de enviar')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await FirestoreService().addPrivateQuestion(widget.startupId, text);
      if (!mounted) return;
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pergunta privada enviada com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar pergunta: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.lock_outline, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Pergunta privada à startup',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Apenas a startup verá sua pergunta. A resposta poderá ser publicada no FAQ público pela equipe.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textBody.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            minLines: 2,
            maxLines: 4,
            enabled: !_submitting,
            decoration: InputDecoration(
              hintText: 'Escreva sua pergunta...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_submitting ? 'Enviando...' : 'Enviar Pergunta Privada'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _submitting ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserPositionCard extends StatelessWidget {
  final double quotas;
  final String valorAplicado;
  const _UserPositionCard({required this.quotas, required this.valorAplicado});

  String _formatQuotas(double q) {
    if (q == q.truncateToDouble()) return q.toStringAsFixed(0);
    return q.toStringAsFixed(2).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final tokensStr = _formatQuotas(quotas);
    final tokensLabel = quotas == 1.0 ? 'token' : 'tokens';

    return _Card(
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.pie_chart_outline,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sua posição',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textBody.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$tokensStr $tokensLabel',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Aplicado',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textBody.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valorAplicado,
                style: const TextStyle(
                  fontSize: 16,
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

class _MyPrivateQuestionsList extends StatelessWidget {
  final String startupId;
  const _MyPrivateQuestionsList({required this.startupId});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.history_edu_outlined,
                  size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Minhas perguntas privadas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreService().getMyPrivateQuestions(startupId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              final questions = snapshot.data ?? const [];
              if (questions.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'Você ainda não enviou nenhuma pergunta.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textBody.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: questions.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: Colors.grey.withValues(alpha: 0.15),
                ),
                itemBuilder: (context, index) {
                  final q = questions[index];
                  return _PrivateQuestionItem(
                    startupId: startupId,
                    question: q,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PrivateQuestionItem extends StatelessWidget {
  final String startupId;
  final Map<String, dynamic> question;
  const _PrivateQuestionItem({
    required this.startupId,
    required this.question,
  });

  bool get _respondida {
    final r = question['resposta']?.toString() ?? '';
    return r.trim().isNotEmpty;
  }

  bool get _publica => question['publico'] == true;

  @override
  Widget build(BuildContext context) {
    final pergunta = question['pergunta']?.toString() ?? '';
    final resposta = question['resposta']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pergunta,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (_publica)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.positive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Publicada',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.positive,
                    ),
                  ),
                ),
            ],
          ),
          if (_respondida) ...[
            const SizedBox(height: 6),
            Text(
              resposta,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textBody.withValues(alpha: 0.9),
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              'Aguardando resposta da startup.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textBody.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (!_publica) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _onEdit(context),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => _onDelete(context),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Excluir'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _onEdit(BuildContext context) async {
    final controller =
        TextEditingController(text: question['pergunta']?.toString() ?? '');
    final messenger = ScaffoldMessenger.of(context);

    final novoTexto = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Editar pergunta'),
          content: TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Reescreva sua pergunta...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (novoTexto == null) return;
    final trimmed = novoTexto.trim();
    if (trimmed.isEmpty || trimmed == question['pergunta']) return;

    try {
      await FirestoreService()
          .editPrivateQuestion(startupId, question, trimmed);
      messenger.showSnackBar(
        const SnackBar(content: Text('Pergunta atualizada.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao editar: $e')),
      );
    }
  }

  Future<void> _onDelete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir pergunta'),
          content: const Text(
              'Tem certeza que deseja excluir esta pergunta? Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await FirestoreService().deletePrivateQuestion(startupId, question);
      messenger.showSnackBar(
        const SnackBar(content: Text('Pergunta excluída.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao excluir: $e')),
      );
    }
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

Future<void> _confirmAndSellAll(
    BuildContext context, Map<String, dynamic> asset) async {
  final messenger = ScaffoldMessenger.of(context);
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Vender todos os tokens?'),
        content: Text(
            'Você venderá todos os tokens de ${asset['name']}. Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Vender'),
          ),
        ],
      );
    },
  );

  if (confirmar != true) return;
  try {
    await BackendService().sellAllAsset(asset);
    messenger.showSnackBar(
      SnackBar(
          content: Text('Todos os tokens de ${asset['name']} vendidos!')),
    );
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Erro ao vender: $e')));
  }
}

Future<void> _showPartialSellSheet(
    BuildContext context, Map<String, dynamic> asset) async {
  final amountStr = asset['amount']?.toString() ?? '0 Tokens';
  final parts = amountStr.split(' ');
  final totalQuotas =
      double.tryParse((parts.first).replaceAll(',', '.')) ?? 0.0;
  final unitLabel = parts.length > 1 ? parts.sublist(1).join(' ') : 'Tokens';
  final controller = TextEditingController();
  final messenger = ScaffoldMessenger.of(context);

  if (totalQuotas <= 0) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Nenhum token disponível para venda.')),
    );
    return;
  }

  final result = await showDialog<double>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Vender parte de ${asset['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Você possui ${totalQuotas.toStringAsFixed(1).replaceAll('.', ',')} $unitLabel',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Tokens a vender',
                prefixIcon: const Icon(Icons.pie_chart_outline),
                helperText:
                    'Máximo: ${totalQuotas.toStringAsFixed(1).replaceAll('.', ',')}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(controller.text.replaceAll(',', '.'));
              if (v == null || v <= 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                      content: Text('Insira uma quantidade válida')),
                );
                return;
              }
              if (v > totalQuotas + 1e-9) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                      content: Text('Quantidade maior do que o disponível')),
                );
                return;
              }
              Navigator.pop(dialogContext, v);
            },
            child: const Text('Vender'),
          ),
        ],
      );
    },
  );

  if (result == null) return;
  try {
    await BackendService().sellPartialAsset(asset, result);
    messenger.showSnackBar(
      SnackBar(
          content: Text(
              'Venda de ${result.toStringAsFixed(1).replaceAll('.', ',')} $unitLabel de ${asset['name']} realizada!')),
    );
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Erro ao vender: $e')));
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
              'Token atual: $val',
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
