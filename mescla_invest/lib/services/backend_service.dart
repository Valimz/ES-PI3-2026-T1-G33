import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mescla_invest/services/firestore_service.dart';

class BackendService {
  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;

  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  BackendService._internal();

  Future<void> connectSocket() async {
    return;
  }

  void disconnectSocket() {
    return;
  }

  Stream<Map<String, dynamic>?> getWalletData() {
    return _firestoreService.getWalletData();
  }

  Stream<List<Map<String, dynamic>>> getUserAssets() {
    return _firestoreService.getUserAssets();
  }

  Future<void> addFunds(double amountToAdd) async {
    await _firestoreService.addFunds(amountToAdd);
  }

  Future<void> negotiateAsset(Map<String, dynamic> startup, double amountToBuy) async {
    await _firestoreService.negotiateAsset(startup, amountToBuy);
  }

  Future<void> sellAllAsset(Map<String, dynamic> asset) async {
    await _firestoreService.sellAllAsset(asset);
  }

  Future<void> sellPartialAsset(
      Map<String, dynamic> asset, double quotasToSell) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não logado');

    if (quotasToSell <= 0) {
      throw Exception('Quantidade inválida para venda');
    }

    final walletRef = _db.collection('users').doc(user.uid).collection('wallet').doc('main');
    final assetRef = _db.collection('users').doc(user.uid).collection('assets').doc(asset['id']);

    await _db.runTransaction((transaction) async {
      final walletDoc = await transaction.get(walletRef);
      final assetDoc = await transaction.get(assetRef);

      if (!walletDoc.exists) throw Exception('Carteira não encontrada');
      if (!assetDoc.exists) throw Exception('Ativo não encontrado');

      final walletData = walletDoc.data()!;
      final currentBalance = _firestoreService.parseCurrency(walletData['balance'] ?? 'R\$ 0,00');

      final assetData = assetDoc.data()!;
      final currentAssetValue = _firestoreService.parseCurrency(assetData['value'] ?? 'R\$ 0,00');
      final quotasStr = assetData['amount']?.toString().split(' ').first ?? '0';
      final currentQuotas = double.tryParse(quotasStr.replaceAll(',', '.')) ?? 0.0;

      if (currentQuotas <= 0) throw Exception('Quantidade de tokens inválida');
      if (quotasToSell > currentQuotas) throw Exception('Quantidade insuficiente de tokens');

      final sellRatio = quotasToSell / currentQuotas;
      final sellValue = currentAssetValue * sellRatio;
      final remainingQuotas = currentQuotas - quotasToSell;
      final remainingValue = currentAssetValue - sellValue;
      final suffixParts = assetData['amount']?.toString().split(' ') ?? <String>[];
      final suffix = suffixParts.length >= 2 ? ' ${suffixParts.sublist(1).join(' ')}' : ' Tokens';

      transaction.update(walletRef, {
        'balance': _currencyFormat.format(currentBalance + sellValue),
      });

      if (remainingQuotas <= 0.0001) {
        transaction.delete(assetRef);
      } else {
        transaction.update(assetRef, {
          'amount': '${remainingQuotas.toStringAsFixed(1)}$suffix',
          'value': _currencyFormat.format(remainingValue > 0 ? remainingValue : 0),
        });
      }

      final acquisitionRef = _db.collection('users').doc(user.uid).collection('acquisitions').doc();
      transaction.set(acquisitionRef, {
        'type': 'sell',
        'title': 'Venda parcial: ${assetData['name']}',
        'amount': _currencyFormat.format(sellValue),
        'quotas': '${quotasToSell.toStringAsFixed(1)}$suffix',
        'date': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> withdrawFunds(double amountToWithdraw) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não logado');

    if (amountToWithdraw <= 0) {
      throw Exception('Valor inválido para saque');
    }

    final walletRef = _db.collection('users').doc(user.uid).collection('wallet').doc('main');

    await _db.runTransaction((transaction) async {
      final walletDoc = await transaction.get(walletRef);
      if (!walletDoc.exists) throw Exception('Carteira não encontrada');

      final walletData = walletDoc.data()!;
      final currentBalance = _firestoreService.parseCurrency(walletData['balance'] ?? 'R\$ 0,00');
      if (currentBalance < amountToWithdraw) {
        throw Exception('Saldo insuficiente');
      }

      transaction.update(walletRef, {
        'balance': _currencyFormat.format(currentBalance - amountToWithdraw),
      });

      final acquisitionRef = _db.collection('users').doc(user.uid).collection('acquisitions').doc();
      transaction.set(acquisitionRef, {
        'type': 'withdraw',
        'title': 'Saque',
        'amount': _currencyFormat.format(amountToWithdraw),
        'date': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> createP2POffer(Map<String, dynamic> asset, double price) async {
    await _firestoreService.createP2POffer(asset, price);
  }

  Future<void> makeCounterOffer(String offerId, double proposedPrice) async {
    await _firestoreService.makeCounterOffer(offerId, proposedPrice);
  }

  Future<void> editP2POffer(String offerId, double price) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não logado');

    final offerRef = _db.collection('p2p_offers').doc(offerId);
    final offerDoc = await offerRef.get();
    if (!offerDoc.exists) throw Exception('Oferta não encontrada');

    final offerData = offerDoc.data()!;
    if (offerData['sellerId'] != user.uid) {
      throw Exception('Você só pode editar suas próprias ofertas');
    }

    await offerRef.update({
      'price': price,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelP2POffer(String offerId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não logado');

    final offerRef = _db.collection('p2p_offers').doc(offerId);
    final offerDoc = await offerRef.get();
    if (!offerDoc.exists) throw Exception('Oferta não encontrada');

    final offerData = offerDoc.data()!;
    if (offerData['sellerId'] != user.uid) {
      throw Exception('Você só pode cancelar suas próprias ofertas');
    }

    await offerRef.update({
      'status': 'canceled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptP2POffer(String offerId, {double? acceptedPrice, String? buyerIdParam, String? negotiationId}) async {
    if (negotiationId != null && acceptedPrice != null) {
      await _firestoreService.acceptCounterOffer(offerId, negotiationId, acceptedPrice);
      return;
    }

    if (negotiationId != null && acceptedPrice == null) {
      final negotiationDoc = await _db
          .collection('p2p_offers')
          .doc(offerId)
          .collection('negotiations')
          .doc(negotiationId)
          .get();
      final negotiationData = negotiationDoc.data();
      final negotiatedPrice = negotiationData?['proposedPrice'];
      if (negotiatedPrice is num) {
        await _firestoreService.acceptCounterOffer(
          offerId,
          negotiationId,
          negotiatedPrice.toDouble(),
        );
        return;
      }
    }

    await _firestoreService.acceptP2POffer(
      offerId,
      acceptedPrice: acceptedPrice,
      buyerIdParam: buyerIdParam,
    );
  }
}
