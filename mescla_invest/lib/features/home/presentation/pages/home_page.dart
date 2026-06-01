import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mescla_invest/core/theme/app_theme.dart';
import 'package:mescla_invest/core/widgets/app_bottom_nav.dart';
import 'package:mescla_invest/services/firestore_service.dart';
import 'package:mescla_invest/services/functions_service.dart';
import 'package:mescla_invest/services/notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Stream<Map<String, dynamic>?> _walletStream;
  late final Stream<List<Map<String, dynamic>>> _assetsStream;
  late final Stream<List<Map<String, dynamic>>> _startupsStream;

  @override
  void initState() {
    super.initState();
    _walletStream = FirestoreService().getWalletData();
    _assetsStream = FirestoreService().getUserAssets();
    _startupsStream = FirestoreService().getStartups();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('MesclaInvest',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return IconButton(
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: const Color(0xFFDC2626),
                  child: const Icon(Icons.notifications_none, color: Colors.white),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications');
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            tooltip: 'Sair da Conta',
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Perfil',
            onPressed: () => Navigator.pushNamed(context, '/perfil'),
            icon: const CircleAvatar(
              backgroundColor: AppColors.accent,
              radius: 16,
              child: Icon(Icons.person, size: 20, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderWallet(context),
            const SizedBox(height: 24),
            _buildSectionTitle("Seu Portfólio"),
            _buildPortfolioChart(),
            const SizedBox(height: 24),
            _buildSectionTitle("Startups em Destaque"),
            _buildStartupList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget _buildHeaderWallet(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: StreamBuilder<Map<String, dynamic>?>(
        stream: _walletStream,
        builder: (context, snapshot) {
          final wallet = snapshot.data;
          final balance = wallet?['balance'] ?? 'R\$ 0,00';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Saldo',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
              const SizedBox(height: 8),
              Text(balance,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary)),
    );
  }

  Widget _buildPortfolioChart() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              Navigator.of(context).pushReplacementNamed('/portfolio'),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _assetsStream,
              builder: (context, assetsSnapshot) {
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _startupsStream,
                  builder: (context, startupsSnapshot) {
                    final assets = assetsSnapshot.data ?? [];
                    final startups = startupsSnapshot.data ?? [];

                    final hasActiveAssets = assets.any((asset) {
                      final amountStr =
                          asset['amount']?.toString().split(' ').first ?? '0';
                      final q = double.tryParse(
                              amountStr.replaceAll(',', '.')) ??
                          0.0;
                      return q > 0;
                    });

                    if (assetsSnapshot.hasData && !hasActiveAssets) {
                      return _buildPortfolioEmptyState();
                    }

                    String appreciationText = '+ 0,0%';
                    Color appreciationColor = AppColors.accent;

                    if (assetsSnapshot.hasData && startupsSnapshot.hasData) {
                      double totalInvested = 0.0;
                      double totalCurrent = 0.0;

                      for (var asset in assets) {
                        final investedValStr =
                            asset['value']?.toString() ?? 'R\$ 0,00';
                        final investedVal =
                            FirestoreService().parseCurrency(investedValStr);

                        final amountStr =
                            asset['amount']?.toString().split(' ').first ?? '0';
                        final currentQuotas = double.tryParse(
                                amountStr.replaceAll(',', '.')) ??
                            0.0;

                        if (currentQuotas > 0) {
                          totalInvested += investedVal;

                          final startupName = asset['name'];
                          final startup = startups.firstWhere(
                              (s) => s['name'] == startupName,
                              orElse: () => {});
                          final currentPriceStr =
                              startup['val']?.toString() ?? 'R\$ 0,00';
                          final currentPrice = FirestoreService()
                              .parseCurrency(currentPriceStr);

                          totalCurrent += (currentQuotas * currentPrice);
                        }
                      }

                      if (totalInvested > 0) {
                        double appreciationPercent =
                            ((totalCurrent / totalInvested) - 1) * 100;
                        appreciationText =
                            "${appreciationPercent >= 0 ? '+' : ''}${appreciationPercent.toStringAsFixed(2)}%";
                        appreciationText =
                            appreciationText.replaceAll('.', ',');

                        if (appreciationPercent < 0) {
                          appreciationColor = Colors.redAccent;
                        }
                      }
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Valorização Total',
                                  style: TextStyle(color: Colors.grey)),
                              Text(appreciationText,
                                  style: TextStyle(
                                      color: appreciationColor,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              Text('Toque para ver seu portfólio',
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(
                          appreciationText.startsWith('-')
                              ? Icons.trending_down
                              : Icons.trending_up,
                          size: 80,
                          color: appreciationColor.withValues(alpha: 0.3),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioEmptyState() {
    return Row(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.pie_chart_outline,
              color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Você ainda não possui ativos',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Explore startups e faça seu primeiro investimento.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: Colors.grey),
      ],
    );
  }

  // Semeia o catálogo via Cloud Function (IDs fixos) — fonte única no backend.
  Future<void> _seedCatalog() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FunctionsService().seedStartupCatalog();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Catálogo de startups criado!')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao criar catálogo: $e')),
      );
    }
  }

  Widget _buildStartupList() {
    return SizedBox(
      height: 180,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _startupsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child:
                    Text("Erro ao carregar startups: ${snapshot.error}"));
          }

          final startups = snapshot.data ?? [];
          if (startups.isEmpty) {
            return Center(
              child: ElevatedButton(
                onPressed: _seedCatalog,
                child: const Text("Criar Dados Iniciais no Firebase"),
              ),
            );
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 24),
            itemCount: startups.length,
            itemBuilder: (context, index) {
              final startup = startups[index];
              return GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  '/startup-detail',
                  arguments: startup,
                ),
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                          backgroundColor: AppColors.background,
                          child: Icon(Icons.business_center)),
                      const Spacer(),
                      Text(startup['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(startup['stage'] ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(startup['val'] ?? '',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

}
