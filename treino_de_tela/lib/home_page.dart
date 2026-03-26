import 'package:flutter/material.dart';
import 'main.dart'; // Para acessar AppColors
import 'package:treino_de_tela/services/firestore_service.dart';

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
  Widget _buildHeaderWallet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: StreamBuilder<Map<String, dynamic>?>(
        stream: FirestoreService().getWalletData(),
        builder: (context, snapshot) {
          final wallet = snapshot.data;
          final balance = wallet?['balance'] ?? 'R\$ 0,00';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Saldo', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
              const SizedBox(height: 8),
              Text(balance,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildQuickAction(Icons.add_circle_outline, "Adicionar", onTap: () => _showAddFundsBottomSheet(context)),
                  const SizedBox(width: 12),
                  _buildQuickAction(Icons.swap_horiz, "Negociar", onTap: () => _showNegotiateBottomSheet(context)),
                ],
              ),
            ],
          );
        }
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

  // Card de Visualização de Valorização
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
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getUserAssets(),
        builder: (context, assetsSnapshot) {
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreService().getStartups(),
            builder: (context, startupsSnapshot) {
              String appreciationText = '+ 0,0%';
              Color appreciationColor = AppColors.accent;

              if (assetsSnapshot.hasData && startupsSnapshot.hasData) {
                final assets = assetsSnapshot.data ?? [];
                final startups = startupsSnapshot.data ?? [];

                double totalInvested = 0.0;
                double totalCurrent = 0.0;

                for (var asset in assets) {
                  final investedValStr = asset['value']?.toString() ?? 'R\$ 0,00';
                  final investedVal = FirestoreService().parseCurrency(investedValStr);
                  
                  final amountStr = asset['amount']?.toString().split(' ').first ?? '0';
                  final currentQuotas = double.tryParse(amountStr.replaceAll(',', '.')) ?? 0.0;
                  
                  if (currentQuotas > 0) {
                    totalInvested += investedVal;
                    
                    final startupName = asset['name'];
                    final startup = startups.firstWhere((s) => s['name'] == startupName, orElse: () => {});
                    final currentPriceStr = startup['val']?.toString() ?? 'R\$ 0,00';
                    final currentPrice = FirestoreService().parseCurrency(currentPriceStr);
                    
                    totalCurrent += (currentQuotas * currentPrice);
                  }
                }

                if (totalInvested > 0) {
                  double appreciationPercent = ((totalCurrent / totalInvested) - 1) * 100;
                  appreciationText = "${appreciationPercent >= 0 ? '+' : ''}${appreciationPercent.toStringAsFixed(2)}%";
                  appreciationText = appreciationText.replaceAll('.', ',');
                  
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
                        const Text('Valorização Total', style: TextStyle(color: Colors.grey)),
                        Text(appreciationText, style: TextStyle(color: appreciationColor, fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('Baseado nos ativos atuais', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(
                    appreciationText.startsWith('-') ? Icons.trending_down : Icons.trending_up, 
                    size: 80, 
                    color: appreciationColor.withValues(alpha: 0.3)
                  ),
                ],
              );
            }
          );
        }
      ),
    );
  }

  // Catálogo Simulado de Startups [cite: 138, 140]
  Widget _buildStartupList() {
    return SizedBox(
      height: 180,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getStartups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Erro ao carregar startups."));
          }
          
          final startups = snapshot.data ?? [];
          if (startups.isEmpty) {
            // Se empty, vamos mostrar um botão p/ popular dados do firebase
            return Center(
              child: ElevatedButton(
                onPressed: () => FirestoreService().seedInitialData(),
                child: const Text("Criar Dados Iniciais no Firebase"),
              ),
            );
          }

          return ListView.builder(
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
                    Text(startups[index]['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(startups[index]['stage'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(startups[index]['val'] ?? '', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          );
        }
      ),
    );
  }

  void _showAddFundsBottomSheet(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Adicionar Fundos", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Valor (R\$)",
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final value = double.tryParse(amountController.text.replaceAll(',', '.'));
                    if (value != null && value > 0) {
                      try {
                        await FirestoreService().addFunds(value);
                        if(context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fundos adicionados com sucesso!")));
                        }
                      } catch (e) {
                         if(context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
                        }
                      }
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Insira um valor válido")));
                    }
                  },
                  child: const Text("Confirmar", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showNegotiateBottomSheet(BuildContext context) {
    String? selectedStartupId;
    Map<String, dynamic>? selectedStartupDetails;
    final TextEditingController amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Negociar Startups", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 16),
                  
                  // Dropdown para Startups
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: FirestoreService().getStartups(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final startups = snapshot.data!;
                      
                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Selecione a Startup',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        value: selectedStartupId,
                        items: startups.map((startup) {
                          final id = startup['id']?.toString() ?? startup['name'] as String;
                          return DropdownMenuItem<String>(
                            value: id,
                            child: Text("${startup['name']} (${startup['val']})"),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStartupId = value;
                            if (value != null) {
                              selectedStartupDetails = startups.firstWhere(
                                (s) => (s['id']?.toString() ?? s['name']) == value,
                              );
                            }
                          });
                        },
                      );
                    }
                  ),

                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "Valor a investir (R\$)",
                      prefixIcon: const Icon(Icons.monetization_on),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final value = double.tryParse(amountController.text.replaceAll(',', '.'));
                        if (selectedStartupDetails != null && value != null && value > 0) {
                          try {
                            await FirestoreService().negotiateAsset(selectedStartupDetails!, value);
                            if(context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Investimento realizado com sucesso!")));
                            }
                          } catch (e) {
                             if(context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
                            }
                          }
                        } else {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecione uma startup e insira um valor válido")));
                        }
                      },
                      child: const Text("Confirmar Investimento", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      },
    );
  }
}
