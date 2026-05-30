import 'package:flutter/material.dart';
import 'package:mescla_invest/core/theme/app_theme.dart';
import 'package:mescla_invest/services/firestore_service.dart';

class FaqPublicoWidget extends StatefulWidget {
  final String startupId;
  final String startupName;

  const FaqPublicoWidget({
    super.key,
    required this.startupId,
    required this.startupName,
  });

  @override
  State<FaqPublicoWidget> createState() => _FaqPublicoWidgetState();
}

class _FaqPublicoWidgetState extends State<FaqPublicoWidget> {
  final _service = FirestoreService();

  @override
  void initState() {
    super.initState();
    _service.ensureDefaultPublicQuestions(
        widget.startupId, widget.startupName);
  }

  void _abrirEnvioPergunta() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Enviar pergunta pública'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Escreva sua pergunta para a startup...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final texto = controller.text.trim();
                if (texto.isEmpty) return;
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(dialogContext);
                try {
                  await _service.addPublicQuestion(widget.startupId, texto);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Pergunta enviada!')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Erro: $e')),
                  );
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Perguntas públicas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed:
                    widget.startupId.isEmpty ? null : _abrirEnvioPergunta,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Enviar'),
                style: TextButton.styleFrom(foregroundColor: AppColors.teal),
              ),
            ],
          ),
          const SizedBox(height: 4),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: widget.startupId.isEmpty
                ? const Stream<List<Map<String, dynamic>>>.empty()
                : _service.getPublicQuestions(widget.startupId),
            builder: (context, snapshot) {
              final perguntas =
                  snapshot.data ?? const <Map<String, dynamic>>[];

              if (perguntas.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Nenhuma pergunta disponível.',
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
                itemCount: perguntas.length,
                separatorBuilder: (_, _) => Divider(
                    height: 1, color: Colors.grey.withValues(alpha: 0.15)),
                itemBuilder: (context, index) {
                  final item = perguntas[index];
                  final pergunta = item['pergunta']?.toString() ?? '';
                  final resposta = item['resposta']?.toString() ?? '';
                  final respondida = resposta.trim().isNotEmpty;
                  final deUsuario = item['askerId'] != null;

                  return Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 12),
                      title: Text(
                        pergunta,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      subtitle: deUsuario
                          ? Text(
                              'Pergunta enviada por um usuário',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textBody.withValues(alpha: 0.6),
                              ),
                            )
                          : null,
                      iconColor: AppColors.teal,
                      collapsedIconColor: AppColors.teal,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            respondida
                                ? resposta
                                : 'Aguardando resposta da startup.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              fontStyle: respondida
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                              color:
                                  AppColors.textBody.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
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
