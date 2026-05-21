import 'package:flutter/material.dart';
import 'package:mescla_invest/core/theme/app_theme.dart';
import 'package:mescla_invest/services/backend_service.dart';

class StartupQuestionsPage extends StatefulWidget {
  final Map<String, dynamic> startup;

  const StartupQuestionsPage({super.key, required this.startup});

  @override
  State<StartupQuestionsPage> createState() => _StartupQuestionsPageState();
}

class _StartupQuestionsPageState extends State<StartupQuestionsPage> {
  bool _isLoading = true;
  List<dynamic> _questions = [];

  // Form
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _optionsController = TextEditingController();
  String _visibility = 'public'; // 'public' ou 'private'

  late String startupId;

  @override
  void initState() {
    super.initState();
    startupId = widget.startup['id'] ?? widget.startup['name'] ?? ''; // Adaptar se a startup tiver ID específico
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    setState(() => _isLoading = true);
    try {
      final data = await BackendService().getQuestions(startupId);
      setState(() {
        _questions = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar perguntas: $e')),
        );
      }
    }
  }

  Future<void> _sendQuestion() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite sua pergunta.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    List<String>? optionsList;
    if (_visibility == 'private') {
      final opts = _optionsController.text.trim();
      if (opts.isNotEmpty) {
        optionsList = opts.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    }

    try {
      await BackendService().sendQuestion(startupId, text, _visibility, optionsList);
      _textController.clear();
      _optionsController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pergunta enviada com sucesso!')),
        );
        _fetchQuestions();
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

  void _showNewQuestionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nova Pergunta',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _visibility,
                    decoration: InputDecoration(
                      labelText: 'Tipo de Pergunta',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'public', child: Text('Aberta (Pública)')),
                      DropdownMenuItem(value: 'private', child: Text('Fechada (Privada)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => _visibility = val);
                        setState(() => _visibility = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _textController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Sua Pergunta',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (_visibility == 'private') ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _optionsController,
                      decoration: InputDecoration(
                        labelText: 'Opções (separadas por vírgula) - Opcional',
                        hintText: 'Ex: Sim, Não, Talvez',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Deixe em branco se quiser apenas que a startup responda por texto.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _sendQuestion();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Enviar Pergunta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final startupName = widget.startup['name'] ?? 'Startup';

    return Scaffold(
      appBar: AppBar(
        title: Text('Q&A: $startupName', style: const TextStyle(color: AppColors.primary)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _questions.isEmpty
              ? const Center(child: Text('Nenhuma pergunta ainda. Seja o primeiro!', style: TextStyle(color: AppColors.textBody)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    final q = _questions[index];
                    final isPrivate = q['visibility'] == 'private';
                    final options = q['options'] as List<dynamic>?;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isPrivate ? Icons.lock : Icons.public,
                                  size: 16,
                                  color: isPrivate ? Colors.red : AppColors.teal,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isPrivate ? 'Privada (Fechada)' : 'Pública (Aberta)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isPrivate ? Colors.red : AppColors.teal,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: q['status'] == 'answered' ? AppColors.positive.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    q['status'] == 'answered' ? 'Respondida' : 'Pendente',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: q['status'] == 'answered' ? AppColors.positive : Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              q['text'] ?? '',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                            if (options != null && options.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text('Opções fornecidas:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                children: options.map((opt) => Chip(
                                  label: Text(opt.toString()),
                                  backgroundColor: Colors.grey.shade200,
                                  labelStyle: const TextStyle(fontSize: 12),
                                )).toList(),
                              ),
                            ],
                            if (q['status'] == 'answered' && q['answer'] != null) ...[
                              const Divider(height: 24),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.subdirectory_arrow_right, size: 20, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Resposta de $startupName',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          q['answer'] ?? '',
                                          style: const TextStyle(fontSize: 14, color: AppColors.textBody),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewQuestionModal,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nova Pergunta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
