import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class FunctionsService {
  static final FunctionsService _instance = FunctionsService._internal();
  factory FunctionsService() => _instance;

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _emulatorConfigured = false;

  FunctionsService._internal();

  void configureEmulator() {
    if (!kDebugMode || _emulatorConfigured) return;
    _functions.useFunctionsEmulator(_firebaseEmulatorHost(), 5001);
    _emulatorConfigured = true;
  }

  Future<void> addFunds(double amountToAdd) => _call('addFunds', {'amount': amountToAdd});

  Future<void> negotiateAsset(Map<String, dynamic> startup, double amountToBuy) =>
      _call('buyAsset', {'startup': startup, 'amountToBuy': amountToBuy});

  Future<void> sellAllAsset(Map<String, dynamic> asset) => _call('sellAsset', {'asset': asset});

  Future<void> sellPartialAsset(Map<String, dynamic> asset, double quotasToSell) =>
      _call('sellPartialAsset', {'asset': asset, 'quotasToSell': quotasToSell});

  Future<void> withdrawFunds(double amountToWithdraw) =>
      _call('withdrawFunds', {'amount': amountToWithdraw});

  Future<void> createP2POffer(Map<String, dynamic> asset, double price) =>
      _call('createP2POffer', {'asset': asset, 'price': price});

  Future<void> makeCounterOffer(String offerId, double proposedPrice) =>
      _call('makeCounterOffer', {'offerId': offerId, 'proposedPrice': proposedPrice});

  Future<void> acceptP2POffer(
    String offerId, {
    double? acceptedPrice,
    String? buyerIdParam,
    String? negotiationId,
  }) async {
    final resolvedBuyerId = buyerIdParam ?? negotiationId;
    final resolvedAcceptedPrice = acceptedPrice ?? await _negotiationPrice(offerId, negotiationId);

    await _call('acceptOffer', {
      'offerId': offerId,
      if (resolvedAcceptedPrice != null) 'acceptedPrice': resolvedAcceptedPrice,
      if (resolvedBuyerId != null) 'buyerIdParam': resolvedBuyerId,
      if (negotiationId != null) 'negotiationId': negotiationId,
    });
  }

  Future<void> registerNotificationToken(String token) =>
      _call('registerNotificationToken', {'token': token});

  Future<void> _call(String name, Map<String, dynamic> data) async {
    await _functions.httpsCallable(name).call(data);
  }

  Future<double?> _negotiationPrice(String offerId, String? negotiationId) async {
    if (negotiationId == null) return null;

    final snapshot = await _db
        .collection('p2p_offers')
        .doc(offerId)
        .collection('negotiations')
        .doc(negotiationId)
        .get();

    final data = snapshot.data();
    final proposedPrice = data?['proposedPrice'];
    return proposedPrice is num ? proposedPrice.toDouble() : null;
  }

  String _firebaseEmulatorHost() {
    if (kIsWeb) {
      return 'localhost';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return '10.0.2.2';
      default:
        return 'localhost';
    }
  }
}
