import 'package:flutter/material.dart';
import 'main.dart'; // Para acessar AppColors

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('MesclaInvest', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          const CircleAvatar(
            backgroundColor: AppColors.accent,
            radius: 16,
            child: Icon(Icons.person, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderWallet(),
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
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/explore');
          }
          if (index == 2) {
            Navigator.pushNamed(context, '/wallet');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explorar'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Carteira'),
        ],
      ),
    );
  }

  // Cabeçalho com Saldo Simulado [cite: 169]
  Widget _buildHeaderWallet() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Saldo Simulado', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
          const SizedBox(height: 8),
          const Text('RS 15.250,00', 
            style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildQuickAction(Icons.add_circle_outline, "Adicionar", onTap: () {debugPrint("Adicionar");}),
              const SizedBox(width: 12),
              _buildQuickAction(Icons.swap_horiz, "Negociar", onTap: () {debugPrint("Negociar");}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(title, 
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
    );
  }

  // Card de Visualização de Valorização [cite: 176]
  Widget _buildPortfolioChart() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Valorização Total', style: TextStyle(color: Colors.grey)),
                const Text('+ 12,5%', style: TextStyle(color: AppColors.accent, fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Últimos 30 dias', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.show_chart, size: 80, color: AppColors.accent),
        ],
      ),
    );
  }

  // Catálogo Simulado de Startups [cite: 138, 140]
  Widget _buildStartupList() {
    final List<Map<String, String>> startups = [
      {"name": "EcoToken", "stage": "Em operação", "val": "RS 12,00"},
      {"name": "HealthTech", "stage": "Em expansão", "val": "RS 45,50"},
      {"name": "AgroData", "stage": "Nova", "val": "RS 5,00"},
    ];

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 24),
        itemCount: startups.length,
        itemBuilder: (context, index) {
          return Container(
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
                const CircleAvatar(backgroundColor: AppColors.background, child: Icon(Icons.business_center)),
                const Spacer(),
                Text(startups[index]['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(startups[index]['stage']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(startups[index]['val']!, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );
  }
}
