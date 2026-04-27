import 'package:flutter/material.dart';
import 'package:treino_de_tela/theme/app_colors.dart';
import 'package:treino_de_tela/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class P2PPage extends StatefulWidget {
  const P2PPage({super.key});

  @override
  State<P2PPage> createState() => _P2PPageState();
}

class _P2PPageState extends State<P2PPage> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          title: const Text('Mercado P2P', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            indicatorColor: AppColors.accent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Ofertas"),
              Tab(text: "Minhas Ofertas"),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const TabBarView(
          children: [
            _MarketTab(),
            _MyOffersTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateOfferBottomSheet(context),
          backgroundColor: AppColors.accent,
          icon: const Icon(Icons.add, color: AppColors.primary),
          label: const Text('Anunciar', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _showCreateOfferBottomSheet(BuildContext context) {
    String? selectedAssetId;
    Map<String, dynamic>? selectedAssetDetails;
    final TextEditingController priceController = TextEditingController();

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
                  const Text("Criar Oferta P2P", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 16),
                  
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: FirestoreService().getUserAssets(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final rawAssets = snapshot.data!;
                      final assets = rawAssets.where((asset) {
                        final amountStr = asset['amount']?.toString().split(' ').first ?? '0';
                        final currentQuotas = double.tryParse(amountStr.replaceAll(',', '.')) ?? 0.0;
                        return currentQuotas > 0;
                      }).toList();

                       if (assets.isEmpty) {
                        return const Text("Você não tem ativos para vender.", style: TextStyle(color: Colors.red));
                      }
                      
                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Selecione o Ativo',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        initialValue: selectedAssetId,
                        items: assets.map((asset) {
                          final id = asset['id']?.toString() ?? asset['name'] as String;
                          return DropdownMenuItem<String>(
                            value: id,
                            child: Text("${asset['name']} (${asset['amount']})"),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedAssetId = value;
                            if (value != null) {
                              selectedAssetDetails = assets.firstWhere(
                                (a) => (a['id']?.toString() ?? a['name']) == value,
                              );
                            }
                          });
                        },
                      );
                    }
                  ),

                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "Preço desejado (R\$)",
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
                        final price = double.tryParse(priceController.text.replaceAll(',', '.'));
                        if (selectedAssetDetails != null && price != null && price > 0) {
                          try {
                            await FirestoreService().createP2POffer(selectedAssetDetails!, price);
                            if(context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Oferta criada com sucesso!")));
                            }
                          } catch (e) {
                             if(context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
                            }
                          }
                        } else {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecione um ativo e insira um preço válido")));
                        }
                      },
                      child: const Text("Publicar Oferta", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
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

class _MarketTab extends StatelessWidget {
  const _MarketTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getP2POffers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Erro ao carregar mercado."));
        }

        final offers = snapshot.data ?? [];
        if (offers.isEmpty) {
          return const Center(child: Text("Nenhuma oferta disponível no momento."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: offers.length,
          itemBuilder: (context, index) {
            final offer = offers[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.background,
                          child: Icon(Icons.storefront, color: AppColors.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(offer['startupName'] ?? 'Ativo', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                              Text('${offer['quotas']} Cotas', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Text('R\$ ${offer['price']?.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontSize: 18, color: AppColors.accent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showMakeCounterOfferDialog(context, offer),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Negociar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _acceptOffer(context, offer),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Comprar', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
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

  void _showMakeCounterOfferDialog(BuildContext context, Map<String, dynamic> offer) {
    final TextEditingController priceController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Fazer Contraproposta'),
          content: TextField(
            controller: priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Novo Preço (R\$)'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final price = double.tryParse(priceController.text.replaceAll(',', '.'));
                if (price != null && price > 0) {
                  try {
                    await FirestoreService().makeCounterOffer(offer['id'], price);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraproposta enviada!')));
                    }
                  } catch (e) {
                     if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
                     }
                  }
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  void _acceptOffer(BuildContext context, Map<String, dynamic> offer) async {
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      await FirestoreService().acceptP2POffer(offer['id']);
      if (context.mounted) {
        Navigator.pop(context); // Tira o dialog
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compra realizada com sucesso!')));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }
}

class _MyOffersTab extends StatelessWidget {
  const _MyOffersTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getMyP2POffers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Erro ao carregar suas ofertas."));
        }

        final offers = snapshot.data ?? [];
        if (offers.isEmpty) {
          return const Center(child: Text("Você não possui ofertas ativas."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: offers.length,
          itemBuilder: (context, index) {
            final offer = offers[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${offer['startupName']} - ${offer['quotas']} Cotas", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('R\$ ${offer['price']?.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    const Text("Negociações (Contrapropostas):", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: FirestoreService().getOfferNegotiations(offer['id']),
                      builder: (context, negSnapshot) {
                        if (!negSnapshot.hasData) return const SizedBox.shrink();
                        final negotiations = negSnapshot.data!;
                        if (negotiations.isEmpty) {
                          return const Text("Nenhuma proposta no momento.", style: TextStyle(fontSize: 12));
                        }
                        
                        return Column(
                          children: negotiations.map((n) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text("Proposta de R\$ ${n['proposedPrice']?.toStringAsFixed(2).replaceAll('.', ',')}"),
                              trailing: ElevatedButton(
                                onPressed: () async {
                                   try {
                                      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                                      await FirestoreService().acceptCounterOffer(offer['id'], n['id'], n['proposedPrice'] as double);
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proposta aceita com sucesso!')));
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
                                      }
                                    }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                                child: const Text("Aceitar", style: TextStyle(color: AppColors.primary)),
                              ),
                            );
                          }).toList(),
                        );
                      }
                    )
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
