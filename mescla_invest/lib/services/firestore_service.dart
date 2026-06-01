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
        }).toList()).asBroadcastStream();
  }

  // Stream para obter os dados cadastrais do usuário logado (users/{uid}).
  Stream<Map<String, dynamic>?> getUserProfile() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db.collection('users').doc(user.uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data();
      }
      return null;
    }).asBroadcastStream();
  }

  // Atualiza o telefone do usuário.
  Future<void> updateUserPhone(String telefone) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db
        .collection('users')
        .doc(user.uid)
        .set({'telefone': telefone}, SetOptions(merge: true));
  }

  // Ativa ou desativa o MFA no cadastro do usuário.
  Future<void> setMfaEnabled(bool enabled) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db
        .collection('users')
        .doc(user.uid)
        .set({'mfaEnabled': enabled}, SetOptions(merge: true));
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
    }).asBroadcastStream();
  }

  // Stream para listar os ativos comprados pelo usuário
  Stream<List<Map<String, dynamic>>> getUserAssets() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db.collection('users').doc(user.uid).collection('assets').snapshots().map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList()).asBroadcastStream();
  }

  // Stream para listar histórico de aquisições/transações
  /// [limit] restringe a quantidade de documentos retornados (melhora performance).
  Stream<List<Map<String, dynamic>>> getUserAcquisitions({int? limit}) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    Query<Map<String, dynamic>> query = _db
        .collection('users')
        .doc(user.uid)
        .collection('acquisitions')
        .orderBy('date', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList()).asBroadcastStream();
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
        String prefix = assetData['amount']?.toString().split(' ').length == 2 ? " ${assetData['amount']?.toString().split(' ').last}" : " Tokens";

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

      // Calcula os tokens para o histórico
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
      final quotasStr = assetData['amount']?.toString() ?? '0 Tokens';
      
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
  // --- MÉTODOS DE PERGUNTAS PRIVADAS (FAQ) ---
  Future<void> addPrivateQuestion(String startupId, String pergunta) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não logado");
    if (pergunta.trim().isEmpty) throw Exception("A pergunta não pode ser vazia");

    final startupRef = _db.collection('startups').doc(startupId);
    final newId = DateTime.now().microsecondsSinceEpoch.toString();
    await startupRef.update({
      'faq': FieldValue.arrayUnion([
        {
          'id': newId,
          'pergunta': pergunta.trim(),
          'resposta': '',
          'publico': false,
          'askerId': user.uid,
          'createdAt': DateTime.now().toIso8601String(),
        }
      ]),
    });
  }

  Stream<List<Map<String, dynamic>>> getMyPrivateQuestions(String startupId) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('startups')
        .doc(startupId)
        .snapshots()
        .map((snap) {
      final data = snap.data();
      if (data == null) return <Map<String, dynamic>>[];
      final faq = data['faq'];
      if (faq is! List) return <Map<String, dynamic>>[];
      return faq
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .where((q) => q['askerId'] == user.uid)
          .toList();
    }).asBroadcastStream();
  }

  Future<void> editPrivateQuestion(
      String startupId, Map<String, dynamic> original, String novaPergunta) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não logado");
    final novaTrim = novaPergunta.trim();
    if (novaTrim.isEmpty) throw Exception("A pergunta não pode ser vazia");
    if (original['askerId'] != user.uid) {
      throw Exception("Você só pode editar suas próprias perguntas");
    }

    final startupRef = _db.collection('startups').doc(startupId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(startupRef);
      if (!snap.exists) throw Exception("Startup não encontrada");

      final data = snap.data()!;
      final rawFaq = data['faq'];
      final List<dynamic> faq =
          rawFaq is List ? List<dynamic>.from(rawFaq) : <dynamic>[];

      bool encontrou = false;
      final List<Map<String, dynamic>> novoFaq = faq
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .map((q) {
        if (!encontrou && _matchesQuestion(q, original)) {
          encontrou = true;
          if (q['publico'] == true) {
            throw Exception(
                "Pergunta já publicada não pode ser editada");
          }
          return {
            ...q,
            'pergunta': novaTrim,
            'editedAt': DateTime.now().toIso8601String(),
          };
        }
        return q;
      }).toList();

      if (!encontrou) throw Exception("Pergunta não encontrada");

      transaction.update(startupRef, {'faq': novoFaq});
    });
  }

  Future<void> deletePrivateQuestion(
      String startupId, Map<String, dynamic> original) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não logado");
    if (original['askerId'] != user.uid) {
      throw Exception("Você só pode excluir suas próprias perguntas");
    }

    final startupRef = _db.collection('startups').doc(startupId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(startupRef);
      if (!snap.exists) throw Exception("Startup não encontrada");

      final data = snap.data()!;
      final rawFaq = data['faq'];
      final List<dynamic> faq =
          rawFaq is List ? List<dynamic>.from(rawFaq) : <dynamic>[];

      bool removeu = false;
      final List<Map<String, dynamic>> novoFaq = [];
      for (final item in faq) {
        if (item is! Map) continue;
        final q = Map<String, dynamic>.from(item);
        if (!removeu && _matchesQuestion(q, original)) {
          if (q['publico'] == true) {
            throw Exception(
                "Pergunta já publicada não pode ser excluída");
          }
          removeu = true;
          continue;
        }
        novoFaq.add(q);
      }

      if (!removeu) throw Exception("Pergunta não encontrada");

      transaction.update(startupRef, {'faq': novoFaq});
    });
  }

  bool _matchesQuestion(Map<String, dynamic> q, Map<String, dynamic> original) {
    final origId = original['id'];
    if (origId != null && q['id'] != null) {
      return q['id'] == origId;
    }
    return q['askerId'] == original['askerId'] &&
        q['pergunta'] == original['pergunta'] &&
        q['createdAt'] == original['createdAt'];
  }

  Future<void> addPublicQuestion(String startupId, String pergunta) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não logado");
    if (pergunta.trim().isEmpty) throw Exception("A pergunta não pode ser vazia");

    final startupRef = _db.collection('startups').doc(startupId);
    final newId = DateTime.now().microsecondsSinceEpoch.toString();
    await startupRef.update({
      'faq': FieldValue.arrayUnion([
        {
          'id': newId,
          'pergunta': pergunta.trim(),
          'resposta': '',
          'publico': true,
          'askerId': user.uid,
          'createdAt': DateTime.now().toIso8601String(),
        }
      ]),
    });
  }

  Future<void> ensureDefaultPublicQuestions(
      String startupId, String startupName) async {
    if (startupId.isEmpty) return;
    final defaults = _defaultPublicFaqByName[startupName];
    if (defaults == null || defaults.isEmpty) return;

    final ref = _db.collection('startups').doc(startupId);
    final snap = await ref.get();
    if (!snap.exists) return;

    final data = snap.data() ?? <String, dynamic>{};
    final rawFaq = data['faq'];
    final existing = rawFaq is List
        ? rawFaq
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList()
        : <Map<String, dynamic>>[];
    final existingIds = existing.map((q) => q['id']).toSet();
    final missing =
        defaults.where((q) => !existingIds.contains(q['id'])).toList();
    if (missing.isEmpty) return;

    await ref.update({'faq': FieldValue.arrayUnion(missing)});
  }

  Stream<List<Map<String, dynamic>>> getPublicQuestions(String startupId) {
    return _db.collection('startups').doc(startupId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return <Map<String, dynamic>>[];
      final faq = data['faq'];
      if (faq is! List) return <Map<String, dynamic>>[];
      final publicas = faq
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .where((q) => q['publico'] == true)
          .toList();
      publicas.sort((a, b) {
        final aOficial = a['askerId'] == null;
        final bOficial = b['askerId'] == null;
        if (aOficial != bOficial) return aOficial ? -1 : 1;
        return (a['createdAt']?.toString() ?? '')
            .compareTo(b['createdAt']?.toString() ?? '');
      });
      return publicas;
    }).asBroadcastStream();
  }

  // --- MÉTODOS P2P ---
  Future<void> createP2POffer(Map<String, dynamic> asset, double price) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não logado");

    final quotasStr = asset['amount']?.toString().split(' ').first ?? '0';
    final quotas = double.tryParse(quotasStr.replaceAll(',', '.')) ?? 0.0;
    if (quotas <= 0) throw Exception("Tokens insuficientes");

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
            .toList()).asBroadcastStream();
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
            }).toList()).asBroadcastStream();
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
            }).toList()).asBroadcastStream();
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
          // Atualiza descontando os tokens. Prefix seria " AD" etc.
          String prefix = sData['amount']?.toString().split(' ').length == 2 ? " ${sData['amount']?.toString().split(' ').last}" : " Tokens";
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
        String prefix = bData['amount']?.toString().split(' ').length == 2 ? " ${bData['amount']?.toString().split(' ').last}" : " Tokens";
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
      for (var startup in _initialStartupsSeed) {
        final withFaq = {
          ...startup,
          'faq': _defaultPublicFaqByName[startup['name']] ??
              const <Map<String, dynamic>>[],
        };
        await startupsCollection.add(withFaq);
      }
      debugPrint("Startups semeadas com sucesso!");
    } else {
      await migrateStartupsSchema();
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

  Future<void> migrateStartupsSchema() async {
    final startupsCollection = _db.collection('startups');
    final snapshot = await startupsCollection.get();

    int updated = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final defaults = _startupDefaultsByName(data['name']?.toString() ?? '');
      final Map<String, dynamic> patch = {};

      for (final entry in defaults.entries) {
        if (!data.containsKey(entry.key) || data[entry.key] == null) {
          patch[entry.key] = entry.value;
        }
      }

      final defaultFaq =
          _defaultPublicFaqByName[data['name']?.toString()] ??
              const <Map<String, dynamic>>[];
      if (defaultFaq.isNotEmpty) {
        final rawFaq = data['faq'];
        final existingFaq = rawFaq is List
            ? rawFaq
                .whereType<Map>()
                .map((m) => Map<String, dynamic>.from(m))
                .toList()
            : <Map<String, dynamic>>[];
        final existingIds = existingFaq.map((q) => q['id']).toSet();
        final missing = defaultFaq
            .where((q) => !existingIds.contains(q['id']))
            .toList();
        if (missing.isNotEmpty) {
          patch['faq'] = [...missing, ...existingFaq];
        }
      }

      if (patch.isNotEmpty) {
        await doc.reference.update(patch);
        updated++;
      }
    }
    debugPrint("Migração de schema das startups: $updated documentos atualizados.");
  }

  Map<String, dynamic> _startupDefaultsByName(String name) {
    final seeded = _initialStartupsSeed.firstWhere(
      (s) => s['name'] == name,
      orElse: () => const <String, dynamic>{},
    );
    return {
      'description': seeded['description'] ?? '',
      'sector': seeded['sector'] ?? '',
      'capitalAportado': seeded['capitalAportado'] ?? 0,
      'tokensEmitidos': seeded['tokensEmitidos'] ?? 0,
      'socios': seeded['socios'] ?? <Map<String, dynamic>>[],
      'mentoresConselho':
          seeded['mentoresConselho'] ?? <String>[],
      'videoUrl': seeded['videoUrl'],
      'status': seeded['status'] ?? 'ativa',
      'faq': seeded['faq'] ?? <Map<String, dynamic>>[],
    };
  }

  // Perguntas públicas predefinidas exibidas no FAQ de cada startup.
  static const Map<String, List<Map<String, dynamic>>> _defaultPublicFaqByName = {
    "EcoTech": [
      {
        "id": "default-ecotech-1",
        "pergunta": "Como a EcoTech gera receita?",
        "resposta":
            "Por meio de assinaturas mensais das empresas que utilizam a plataforma de monitoramento ambiental.",
        "publico": true,
      },
      {
        "id": "default-ecotech-2",
        "pergunta": "Qual é o principal diferencial da startup?",
        "resposta":
            "Sensores próprios integrados a um painel de analytics em tempo real para conformidade ambiental.",
        "publico": true,
      },
    ],
    "FinFlow": [
      {
        "id": "default-finflow-1",
        "pergunta": "Para quem é o produto da FinFlow?",
        "resposta":
            "Para MEIs e pequenos negócios que precisam de gestão simples e automatizada de fluxo de caixa.",
        "publico": true,
      },
      {
        "id": "default-finflow-2",
        "pergunta": "Como é feita a cobrança aos clientes?",
        "resposta":
            "Plano mensal por assinatura, com diferentes faixas conforme o volume de transações.",
        "publico": true,
      },
    ],
    "AgroSmart": [
      {
        "id": "default-agrosmart-1",
        "pergunta": "O que a solução da AgroSmart resolve?",
        "resposta":
            "Otimiza a irrigação no campo usando sensores IoT, reduzindo o desperdício de água e custos.",
        "publico": true,
      },
      {
        "id": "default-agrosmart-2",
        "pergunta": "Em que estágio a startup está?",
        "resposta":
            "Em fase inicial (Nova), validando a tecnologia com produtores parceiros.",
        "publico": true,
      },
    ],
    "HealthVibe": [
      {
        "id": "default-healthvibe-1",
        "pergunta": "Como a IA é utilizada na HealthVibe?",
        "resposta":
            "Para triagem inicial dos pacientes em atendimentos de telemedicina, agilizando o encaminhamento.",
        "publico": true,
      },
      {
        "id": "default-healthvibe-2",
        "pergunta": "A plataforma substitui o médico?",
        "resposta":
            "Não. A IA apoia a triagem, mas o atendimento e o diagnóstico são sempre realizados por profissionais.",
        "publico": true,
      },
    ],
    "EduNext": [
      {
        "id": "default-edunext-1",
        "pergunta": "O que torna os cursos da EduNext diferentes?",
        "resposta":
            "A gamificação do aprendizado, com trilhas, recompensas e acompanhamento de progresso.",
        "publico": true,
      },
      {
        "id": "default-edunext-2",
        "pergunta": "Qual é o modelo de negócio?",
        "resposta":
            "Assinaturas de acesso às trilhas de cursos, com planos para alunos e para empresas.",
        "publico": true,
      },
    ],
  };

  static const List<Map<String, dynamic>> _initialStartupsSeed = [
    {
      "name": "EcoTech",
      "stage": "Em operação",
      "val": "R\$ 3,00",
      "description": "Plataforma de monitoramento ambiental para empresas.",
      "sector": "Cleantech",
      "capitalAportado": 300000,
      "tokensEmitidos": 100000,
      "socios": [
        {"nome": "Ana Souza", "percentual": 60},
        {"nome": "Carlos Lima", "percentual": 40},
      ],
      "mentoresConselho": ["Mariana Prado"],
      "videoUrl": "https://exemplo.com/demo1",
      "status": "ativa",
      "faq": <Map<String, dynamic>>[],
    },
    {
      "name": "FinFlow",
      "stage": "Em expansão",
      "val": "R\$ 2,00",
      "description": "Gestão de fluxo de caixa para MEIs.",
      "sector": "Fintech",
      "capitalAportado": 500000,
      "tokensEmitidos": 250000,
      "socios": [
        {"nome": "Roberto Dias", "percentual": 50},
        {"nome": "Julia Mota", "percentual": 50},
      ],
      "mentoresConselho": ["Ricardo Santos"],
      "videoUrl": "https://exemplo.com/demo2",
      "status": "ativa",
      "faq": <Map<String, dynamic>>[],
    },
    {
      "name": "AgroSmart",
      "stage": "Nova",
      "val": "R\$ 2,00",
      "description": "IoT para otimização de irrigação.",
      "sector": "Agtech",
      "capitalAportado": 150000,
      "tokensEmitidos": 75000,
      "socios": [
        {"nome": "Marcos Vinicius", "percentual": 100},
      ],
      "mentoresConselho": ["Arnaldo Souza"],
      "videoUrl": "https://exemplo.com/demo3",
      "status": "ativa",
      "faq": <Map<String, dynamic>>[],
    },
    {
      "name": "HealthVibe",
      "stage": "Em operação",
      "val": "R\$ 2,00",
      "description": "Telemedicina com IA para triagem.",
      "sector": "Healthtech",
      "capitalAportado": 800000,
      "tokensEmitidos": 400000,
      "socios": [
        {"nome": "Beatriz Luz", "percentual": 70},
        {"nome": "Hugo Vaz", "percentual": 30},
      ],
      "mentoresConselho": ["Sandra Meireles"],
      "videoUrl": "https://exemplo.com/demo4",
      "status": "ativa",
      "faq": <Map<String, dynamic>>[],
    },
    {
      "name": "EduNext",
      "stage": "Em expansão",
      "val": "R\$ 2,25",
      "description": "Plataforma de cursos gamificados.",
      "sector": "Edutech",
      "capitalAportado": 450000,
      "tokensEmitidos": 200000,
      "socios": [
        {"nome": "Tiago André", "percentual": 100},
      ],
      "mentoresConselho": ["Fernando Silva"],
      "videoUrl": "https://exemplo.com/demo5",
      "status": "ativa",
      "faq": <Map<String, dynamic>>[],
    },
  ];

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
