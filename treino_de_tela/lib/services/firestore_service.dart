import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream para listar todas as startups
  Stream<List<Map<String, dynamic>>> getStartups() {
    return _db.collection('startups').snapshots().map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList());
  }

  // Stream para obter os dados da carteira do usuário logado
  Stream<Map<String, dynamic>?> getWalletData() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db.collection('users').doc(user.uid).collection('wallet').doc('main').snapshots().map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data();
      }
      return null;
    });
  }

  // Stream para listar os ativos comprados pelo usuário
  Stream<List<Map<String, dynamic>>> getUserAssets() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db.collection('users').doc(user.uid).collection('assets').snapshots().map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList());
  }

  // Stream para listar histórico de aquisições/transações
  Stream<List<Map<String, dynamic>>> getUserAcquisitions() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db.collection('users').doc(user.uid).collection('acquisitions')
        .orderBy('date', descending: true)
        .snapshots().map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList());
  }

  // --- MÉTODOS DE NEGOCIAÇÃO E CARTEIRA ---
  
  // Utilitário para formatar/desformatar moeda (BRL)
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  double _parseCurrency(String currencyStr) {
    try {
      // Remove tudo que não for número ou vírgula, e converte vírgula pra ponto
      String cleanString = currencyStr.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.');
      return double.tryParse(cleanString) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Adicionar fundos à carteira
  Future<void> addFunds(double amountToAdd) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não logado");

    final walletRef = _db.collection('users').doc(user.uid).collection('wallet').doc('main');
    
    return _db.runTransaction((transaction) async {
      final walletDoc = await transaction.get(walletRef);
      if (!walletDoc.exists) {
        throw Exception("Carteira não encontrada");
      }

      final data = walletDoc.data()!;
      final balanceStr = data['balance'] ?? 'R\$ 0,00';
      final currentBalance = _parseCurrency(balanceStr);
      
      final newBalance = currentBalance + amountToAdd;
      
      transaction.update(walletRef, {
        'balance': _currencyFormat.format(newBalance),
      });

      // Salva o histórico de depósito
      final acquisitionRef = _db.collection('users').doc(user.uid).collection('acquisitions').doc();
      transaction.set(acquisitionRef, {
        'type': 'deposit',
        'title': 'Depósito',
        'amount': _currencyFormat.format(amountToAdd),
        'date': FieldValue.serverTimestamp(),
      });
    });
  }

  // Comprar ou aportar mais numa startup
  Future<void> negotiateAsset(Map<String, dynamic> startup, double amountToBuy) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não logado");

    final walletRef = _db.collection('users').doc(user.uid).collection('wallet').doc('main');
    final assetsCollection = _db.collection('users').doc(user.uid).collection('assets');
    
    return _db.runTransaction((transaction) async {
      final walletDoc = await transaction.get(walletRef);
      if (!walletDoc.exists) throw Exception("Carteira não encontrada");

      final walletData = walletDoc.data()!;
      final currentBalance = _parseCurrency(walletData['balance'] ?? 'R\$ 0,00');
      
      if (currentBalance < amountToBuy) {
        throw Exception("Saldo insuficiente");
      }

      // Deduza o valor
      final newBalance = currentBalance - amountToBuy;
      transaction.update(walletRef, {
        'balance': _currencyFormat.format(newBalance),
      });

      // Checar se o ativo já existe
      final querySnapshot = await assetsCollection.where('name', isEqualTo: startup['name']).get();
      
      if (querySnapshot.docs.isNotEmpty) {
        // Atualiza ativo existente
        final assetDoc = querySnapshot.docs.first;
        final assetRef = assetDoc.reference;
        final assetData = assetDoc.data();
        
        final currentAssetValue = _parseCurrency(assetData['value'] ?? 'R\$ 0,00');
        // Quotas é string, ex: "100 AD"
        final quotasStr = assetData['amount']?.toString().split(' ').first ?? '0';
        final currentQuotas = double.tryParse(quotasStr.replaceAll(',', '.')) ?? 0.0;
        
        // Simular preço por quota baseado no valor aportado da startup? 
        // A startup tem um campo `val` (ex: "R$ 12,00").
        final startupPrice = _parseCurrency(startup['val'] ?? 'R\$ 1,00');
        final newQuotas = currentQuotas + (amountToBuy / (startupPrice > 0 ? startupPrice : 1));
        
        // Define o prefixo correto da quota
        String prefix = assetData['amount']?.toString().split(' ').length == 2 ? " ${assetData['amount']?.toString().split(' ').last}" : " Cotas";

        transaction.update(assetRef, {
          'value': _currencyFormat.format(currentAssetValue + amountToBuy),
          'amount': "${newQuotas.toStringAsFixed(1)}$prefix",
        });
      } else {
        // Cria novo ativo
        final startupPrice = _parseCurrency(startup['val'] ?? 'R\$ 1,00');
        final quotas = amountToBuy / (startupPrice > 0 ? startupPrice : 1);
        String prefix = " ${startup['name'].toString().substring(0, 2).toUpperCase()}";
        
        final docRef = assetsCollection.doc();
        transaction.set(docRef, {
          'name': startup['name'],
          'value': _currencyFormat.format(amountToBuy),
          'amount': "${quotas.toStringAsFixed(1)}$prefix",
        });
      }

      // Calcula as cotas para o histórico
      final startupPrice = _parseCurrency(startup['val'] ?? 'R\$ 1,00');
      final boughtQuotas = amountToBuy / (startupPrice > 0 ? startupPrice : 1);
      final quotasPrefix = " ${startup['name'].toString().substring(0, 2).toUpperCase()}";

      // Salva o histórico da compra
      final acquisitionRef = _db.collection('users').doc(user.uid).collection('acquisitions').doc();
      transaction.set(acquisitionRef, {
        'type': 'buy',
        'title': 'Compra: ${startup['name']}',
        'amount': _currencyFormat.format(amountToBuy),
        'quotas': "${boughtQuotas.toStringAsFixed(1)}$quotasPrefix",
        'date': FieldValue.serverTimestamp(),
      });
    });
  }

  // --- MÉTODOS DE SEED ---
  // Cria dados iniciais para testar o App conectando-se no BancoPI3
  Future<void> seedInitialData() async {
    // Populando as startups
    final startupsCollection = _db.collection('startups');
    final query = await startupsCollection.limit(1).get();
    
    if (query.docs.isEmpty) {
      final List<Map<String, dynamic>> initialStartups = [
        {"name": "EcoToken", "stage": "Em operação", "val": "R\$ 12,00"},
        {"name": "HealthTech", "stage": "Em expansão", "val": "R\$ 45,50"},
        {"name": "AgroData", "stage": "Nova", "val": "R\$ 5,00"},
        {"name": "FinSol", "stage": "Em operação", "val": "R\$ 28,75"},
        {"name": "Educa+", "stage": "Nova", "val": "R\$ 7,50"},
        {"name": "Mobility Z", "stage": "Em expansão", "val": "R\$ 98,00"},
      ];
      
      for (var startup in initialStartups) {
        await startupsCollection.add(startup);
      }
      print("Startups semeadas com sucesso!");
    }

    // Populando carteira do usuário atual (se logado)
    final user = _auth.currentUser;
    if (user != null) {
      final walletRef = _db.collection('users').doc(user.uid).collection('wallet').doc('main');
      final walletDoc = await walletRef.get();
      
      if (!walletDoc.exists) {
        await walletRef.set({
          "balance": "R\$ 15.250,00",
          "appreciation": "+ 0,0%"
        });
        print("Carteira do \$user.email criada com sucesso!");
      }
    }
  }

  // --- MÉTODOS DE LIMPEZA ---
  Future<void> removePlaceholderAssets() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final assetsCollection = _db.collection('users').doc(user.uid).collection('assets');
    final acquisitionsCollection = _db.collection('users').doc(user.uid).collection('acquisitions');

    // Identifica quais empresas o usuário de fato comprou (que têm histórico gerado)
    final acquisitionsQuery = await acquisitionsCollection.where('type', isEqualTo: 'buy').get();
    final realPurchasedStartupNames = acquisitionsQuery.docs
        .map((doc) => doc.data()['title']?.toString().replaceAll('Compra: ', '') ?? '')
        .toSet();

    final assetsQuery = await assetsCollection.get();
    for (var doc in assetsQuery.docs) {
      final assetName = doc.data()['name'] ?? '';
      // Se não houver histórico de compra dessa empresa, foi inject de placeholder
      if (!realPurchasedStartupNames.contains(assetName)) {
        await doc.reference.delete();
      }
    }
  }
}
