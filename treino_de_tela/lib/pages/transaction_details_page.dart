import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:treino_de_tela/theme/app_colors.dart';

class TransactionDetailsPage extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailsPage({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isBuy = transaction['type'] == 'buy';
    final icon = isBuy ? Icons.arrow_outward : Icons.arrow_downward;
    final iconColor = isBuy ? Colors.orange : Colors.green;
    final title = transaction['title'] ?? 'Transação';
    final amount = transaction['amount'] ?? '';
    final quotas = transaction['quotas'];

    String dateFormatted = "Data Indisponível";
    String timeFormatted = "";
    if (transaction['date'] != null && transaction['date'] is Timestamp) {
      final DateTime date = (transaction['date'] as Timestamp).toDate();
      dateFormatted = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
      timeFormatted = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Detalhes da Transação",
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: iconColor.withValues(alpha: 0.1),
              child: Icon(icon, color: iconColor, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              amount,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: isBuy ? AppColors.primary : Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isBuy ? "Valor Investido" : "Valor Creditado",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            
            // Cartão de detalhes
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildDetailRow("Tipo", isBuy ? "Investimento" : "Transferência / Depósito"),
                  const Divider(height: 32),
                  _buildDetailRow("Descrição", title),
                  if (isBuy && quotas != null) ...[
                    const Divider(height: 32),
                    _buildDetailRow("Ativos (Cotas)", quotas),
                  ],
                  const Divider(height: 32),
                  _buildDetailRow("Data", dateFormatted),
                  const Divider(height: 32),
                  _buildDetailRow("Hora", timeFormatted),
                  const Divider(height: 32),
                  _buildDetailRow("Comprovante ID", transaction['id'] ?? '---'),
                ],
              ),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "Voltar",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
