import 'package:flutter/foundation.dart';
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

  double parseCurrency(String currencyStr) {
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
        // Criar carteira caso ela não exista
        transaction.set(walletRef, {
          'balance': _currencyFormat.format(amountToAdd),
          'appreciation': '+ 0,0%',
        });
      } else {
        final data = walletDoc.data()!;
        final balanceStr = data['balance'] ?? 'R\$ 0,00';
        final currentBalance = parseCurrency(balanceStr);
        
        final newBalance = currentBalance + amountToAdd;
        
        transaction.update(walletRef, {
          'balance': _currencyFormat.format(newBalance),
        });
      }

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
      final currentBalance = parseCurrency(walletData['balance'] ?? 'R\$ 0,00');
      
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
        
        final currentAssetValue = parseCurrency(assetData['value'] ?? 'R\$ 0,00');
        // Quotas é string, ex: "100 AD"
        final quotasStr = assetData['amount']?.toString().split(' ').first ?? '0';
        final currentQuotas = double.tryParse(quotasStr.replaceAll(',', '.')) ?? 0.0;
        
        // Simular preço por quota baseado no valor aportado da startup? 
        // A startup tem um campo `val` (ex: "R$ 12,00").
        final startupPrice = parseCurrency(startup['val'] ?? 'R\$ 1,00');
        final newQuotas = currentQuotas + (amountToBuy / (startupPrice > 0 ? startupPrice : 1));
        
        // Define o prefixo correto da quota
        String prefix = assetData['amount']?.toString().split(' ').length == 2 ? " ${assetData['amount']?.toString().split(' ').last}" : " Cotas";

        transaction.update(assetRef, {
          'value': _currencyFormat.format(currentAssetValue + amountToBuy),
          'amount': "${newQuotas.toStringAsFixed(1)}$prefix",
        });
      } else {
        // Cria novo ativo
        final startupPrice = parseCurrency(startup['val'] ?? 'R\$ 1,00');
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
      final startupPrice = parseCurrency(startup['val'] ?? 'R\$ 1,00');
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

  // Vender todos os ativos de uma empresa
  Future<void> sellAllAsset(Map<String, dynamic> asset) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não logado");

    final walletRef = _db.collection('users').doc(user.uid).collection('wallet').doc('main');
    final assetRef = _db.collection('users').doc(user.uid).collection('assets').doc(asset['id']);
    
    return _db.runTransaction((transaction) async {
      final walletDoc = await transaction.get(walletRef);
      final assetDoc = await transaction.get(assetRef);
      
      if (!walletDoc.exists) throw Exception("Carteira não encontrada");
      if (!assetDoc.exists) throw Exception("Ativo não encontrado");

      final walletData = walletDoc.data()!;
      final currentBalance = parseCurrency(walletData['balance'] ?? 'R\$ 0,00');
      
      final assetData = assetDoc.data()!;
      final currentAssetValue = parseCurrency(assetData['value'] ?? 'R\$ 0,00');
      final quotasStr = assetData['amount']?.toString() ?? '0 Cotas';
      
      // Adiciona o valor total do ativo de volta à carteira
      final newBalance = currentBalance + currentAssetValue;
      transaction.update(walletRef, {
        'balance': _currencyFormat.format(newBalance),
      });

      // Remove o ativo
      transaction.delete(assetRef);

      // Salva o histórico
      final acquisitionRef = _db.collection('users').doc(user.uid).collection('acquisitions').doc();
      transaction.set(acquisitionRef, {
        'type': 'sell',
        'title': 'Venda: ${assetData['name']}',
        'amount': _currencyFormat.format(currentAssetValue),
        'quotas': quotasStr,
        'date': FieldValue.serverTimestamp(),
      });
    });
  }
  // --- MÉTODOS P2P ---
  Future<void> createP2POffer(Map<String, dynamic> asset, double price) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não logado");

    final quotasStr = asset['amount']?.toString().split(' ').first ?? '0';
    final quotas = double.tryParse(quotasStr.replaceAll(',', '.')) ?? 0.0;
    if (quotas <= 0) throw Exception("Cotas insuficientes");

    await _db.collection('p2p_offers').add({
      'sellerId': user.uid,
      'startupName': asset['name'],
      'quotas': quotas,
      'price': price,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getP2POffers() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db.collection('p2p_offers')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            })
            // Opcional: filtrar no cliente se quiser esconder do próprio dono
            .where((offer) => offer['sellerId'] != user.uid)
            .toList());
  }

  Stream<List<Map<String, dynamic>>> getMyP2POffers() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db.collection('p2p_offers')
        .where('sellerId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> makeCounterOffer(String offerId, double proposedPrice) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não logado");

    await _db.collection('p2p_offers').doc(offerId).collection('negotiations').doc(user.uid).set({
      'buyerId': user.uid,
      'proposedPrice': proposedPrice,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getOfferNegotiations(String offerId) {
    return _db.collection('p2p_offers').doc(offerId).collection('negotiations')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> acceptP2POffer(String offerId, {double? acceptedPrice, String? buyerIdParam}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("Usuário não logado");

    final offerRef = _db.collection('p2p_offers').doc(offerId);

    return _db.runTransaction((transaction) async {
      final offerDoc = await transaction.get(offerRef);
      if (!offerDoc.exists) throw Exception("Oferta não encontrada");

      final offerData = offerDoc.data()!;
      if (offerData['status'] != 'active') throw Exception("Esta oferta não está mais ativa.");

      final sellerId = offerData['sellerId'];
      final buyerId = buyerIdParam ?? currentUser.uid;

      if (sellerId == buyerId) throw Exception("Você não pode comprar sua própria oferta.");

      final price = acceptedPrice ?? offerData['price'] as double;
      final assetName = offerData['startupName'] as String;
      final quotas = offerData['quotas'] as double;

      final buyerWalletRef = _db.collection('users').doc(buyerId).collection('wallet').doc('main');
      final sellerWalletRef = _db.collection('users').doc(sellerId).collection('wallet').doc('main');
      
      final buyerWalletDoc = await transaction.get(buyerWalletRef);
      final sellerWalletDoc = await transaction.get(sellerWalletRef);

      if (!buyerWalletDoc.exists) throw Exception("Carteira do comprador não encontrada");
      if (!sellerWalletDoc.exists) throw Exception("Carteira do vendedor não encontrada");

      final buyerBalance = parseCurrency(buyerWalletDoc.data()!['balance'] ?? 'R\$ 0,00');
      final sellerBalance = parseCurrency(sellerWalletDoc.data()!['balance'] ?? 'R\$ 0,00');

      if (buyerBalance < price) throw Exception("Saldo insuficiente do comprador");

      // Transferência de dinheiro
      transaction.update(buyerWalletRef, {'balance': _currencyFormat.format(buyerBalance - price)});
      transaction.update(sellerWalletRef, {'balance': _currencyFormat.format(sellerBalance + price)});

      // Remover o ativo do vendedor
      final sellerAssetsCollection = _db.collection('users').doc(sellerId).collection('assets');
      final sellerAssetsQuery = await sellerAssetsCollection.where('name', isEqualTo: assetName).get();
      if (sellerAssetsQuery.docs.isNotEmpty) {
        // Assume selling all quotas for simplicity or update if partially selling 
        // Our simplified model assumes the offer was for the whole asset or specific quotas
        final sDoc = sellerAssetsQuery.docs.first;
        final sData = sDoc.data();
        final sQuotasStr = sData['amount']?.toString().split(' ').first ?? '0';
        final sQuotas = double.tryParse(sQuotasStr.replaceAll(',', '.')) ?? 0.0;
        
        if (sQuotas <= quotas) { // Se vendeu tudo ou de alguma forma passou do total
          transaction.delete(sDoc.reference);
        } else {
          // Atualiza descontando as cotas. Prefix seria " AD" etc.
          String prefix = sData['amount']?.toString().split(' ').length == 2 ? " ${sData['amount']?.toString().split(' ').last}" : " Cotas";
          // We need an approximate value deduction proportional to quotas
          final sValStr = sData['value']?.toString() ?? 'R\$ 0,00';
          final sVal = parseCurrency(sValStr);
          final newVal = sVal - (sVal * (quotas/sQuotas));
          transaction.update(sDoc.reference, {
            'amount': "${(sQuotas - quotas).toStringAsFixed(1)}$prefix",
            'value': _currencyFormat.format(newVal > 0 ? newVal : 0),
          });
        }
      }

      // Adicionar o ativo ao comprador
      final buyerAssetsCollection = _db.collection('users').doc(buyerId).collection('assets');
      final buyerAssetsQuery = await buyerAssetsCollection.where('name', isEqualTo: assetName).get();
      if (buyerAssetsQuery.docs.isNotEmpty) {
        final bDoc = buyerAssetsQuery.docs.first;
        final bData = bDoc.data();
        final bQuotasStr = bData['amount']?.toString().split(' ').first ?? '0';
        final bQuotas = double.tryParse(bQuotasStr.replaceAll(',', '.')) ?? 0.0;
        String prefix = bData['amount']?.toString().split(' ').length == 2 ? " ${bData['amount']?.toString().split(' ').last}" : " Cotas";
        final bValStr = bData['value']?.toString() ?? 'R\$ 0,00';
        final bVal = parseCurrency(bValStr);

        transaction.update(bDoc.reference, {
          'amount': "${(bQuotas + quotas).toStringAsFixed(1)}$prefix",
          'value': _currencyFormat.format(bVal + price),
        });
      } else {
         String prefix = " ${assetName.substring(0, 2).toUpperCase()}";
         final newAssetRef = buyerAssetsCollection.doc();
         transaction.set(newAssetRef, {
           'name': assetName,
           'value': _currencyFormat.format(price),
           'amount': "${quotas.toStringAsFixed(1)}$prefix",
         });
      }

      // Marcar oferta como concluída
      transaction.update(offerRef, {'status': 'completed'});
    });
  }

  Future<void> acceptCounterOffer(String offerId, String negotiationId, double agreedPrice) async {
    // negotiationId é na verdade o buyerId pois usamos doc(user.uid)
    await acceptP2POffer(offerId, acceptedPrice: agreedPrice, buyerIdParam: negotiationId);
    
    // Marcar negociação como aceita
    await _db.collection('p2p_offers').doc(offerId).collection('negotiations').doc(negotiationId).update({
      'status': 'accepted',
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
        {"name": "Aura IA", "stage": "Nova", "val": "R\$ 21,30"},
        {"name": "CleanEnergy", "stage": "Semente", "val": "R\$ 2,50"},
        {"name": "SpaceT", "stage": "Em operação", "val": "R\$ 150,00"},
        {"name": "BioGenesis", "stage": "Em expansão", "val": "R\$ 55,20"},
      ];
      
      for (var startup in initialStartups) {
        await startupsCollection.add(startup);
      }
      debugPrint("Startups semeadas com sucesso!");
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
