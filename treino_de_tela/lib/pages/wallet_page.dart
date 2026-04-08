import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:treino_de_tela/theme/app_colors.dart';
import 'package:treino_de_tela/services/firestore_service.dart';
import 'package:treino_de_tela/pages/transaction_details_page.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Carteira',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services, color: AppColors.primary),
            tooltip: "Limpar ativos placeholders (teste)",
            onPressed: () async {
              await FirestoreService().removePlaceholderAssets();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ativos fictícios (sem histórico real) foram limpos!")),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildBalanceCard(),
          const SizedBox(height: 24),
          _buildSectionTitle("Meus Ativos"),
          _buildAssetList(),
          const SizedBox(height: 24),
          _buildSectionTitle("Histórico de Transações"),
          _buildAcquisitionsList(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: StreamBuilder<Map<String, dynamic>?>(
        stream: FirestoreService().getWalletData(),
        builder: (context, snapshot) {
          final wallet = snapshot.data;
          final balance = wallet?['balance'] ?? 'R\$ 0,00';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saldo Total Disponível',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                balance,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildActionButton(Icons.arrow_downward, "Depositar")),
                  const SizedBox(width: 12),
                  Expanded(child: _buildActionButton(Icons.arrow_upward, "Retirar")),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildAssetList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getUserAssets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Erro ao carregar ativos."));
        }

        final rawAssets = snapshot.data ?? [];
        final assets = rawAssets.where((asset) {
          final amountStr = asset['amount']?.toString().split(' ').first ?? '0';
          final currentQuotas = double.tryParse(amountStr.replaceAll(',', '.')) ?? 0.0;
          return currentQuotas > 0;
        }).toList();

        if (assets.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Você ainda não possui ativos."),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: assets.length,
          itemBuilder: (context, index) {
            final asset = assets[index];
            return InkWell(
              onTap: () => _showAssetDetails(context, asset),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.background,
                      child: Icon(
                        Icons.business_center,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            asset['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            asset['amount'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      asset['value'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAssetDetails(BuildContext context, Map<String, dynamic> asset) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.background,
                    child: Icon(Icons.business_center, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      asset['name'] ?? 'Empresa',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tokens Possuídos:', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  Text(
                    asset['amount'] ?? '0',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Valor Total:', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  Text(
                    asset['value'] ?? 'R\$ 0,00',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accent),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context); // close bottom sheet
                        try {
                          await FirestoreService().sellAllAsset(asset);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Todos os tokens de ${asset['name']} vendidos com sucesso!")),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Erro ao vender: $e")),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.primary),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Vender Tudo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // close bottom sheet
                        // Navigate to explore to buy more
                        Navigator.pushNamed(context, '/explore');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Comprar Mais', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAcquisitionsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getUserAcquisitions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Erro ao carregar histórico."));
        }

        final acquisitions = snapshot.data ?? [];
        if (acquisitions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Nenhuma transação encontrada."),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: acquisitions.length,
          itemBuilder: (context, index) {
            final acq = acquisitions[index];
            final isBuy = acq['type'] == 'buy';
            final icon = isBuy ? Icons.arrow_outward : Icons.arrow_downward;
            final iconColor = isBuy ? Colors.orange : Colors.green;
            
            // Formatando data
            String dateFormatted = "";
            if (acq['date'] != null && acq['date'] is Timestamp) {
              final DateTime date = (acq['date'] as Timestamp).toDate();
              dateFormatted = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
            }

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransactionDetailsPage(transaction: acq),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: iconColor.withValues(alpha: 0.1),
                    child: Icon(icon, color: iconColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          acq['title'] ?? 'Transação',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isBuy && acq['quotas'] != null)
                          Text(
                            acq['quotas'],
                            style: const TextStyle(fontSize: 14, color: AppColors.primary),
                          ),
                        Text(
                          dateFormatted,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    acq['amount'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isBuy ? AppColors.primary : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        );
      },
    );
  }
}
