import 'package:flutter/material.dart';
import 'package:mescla_invest/core/theme/app_theme.dart';

class FaqPublicoWidget extends StatelessWidget {
  final List<Map<String, dynamic>> faq;

  const FaqPublicoWidget({super.key, required this.faq});

  @override
  Widget build(BuildContext context) {
    final publicas = faq.where((item) => item['publico'] == true).toList();

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
            children: const [
              Icon(Icons.help_outline, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Perguntas frequentes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (publicas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nenhuma pergunta disponível.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textBody.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: publicas.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
              itemBuilder: (context, index) {
                final item = publicas[index];
                final pergunta = item['pergunta']?.toString() ?? '';
                final resposta = item['resposta']?.toString() ?? '';
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
                    iconColor: AppColors.teal,
                    collapsedIconColor: AppColors.teal,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          resposta,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color:
                                AppColors.textBody.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
