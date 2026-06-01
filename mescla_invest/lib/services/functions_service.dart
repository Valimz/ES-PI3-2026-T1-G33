import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../firebase_options.dart';

class FunctionsService {
  static final FunctionsService _instance = FunctionsService._internal();
  factory FunctionsService() => _instance;

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'southamerica-east1');
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  Future<void> editP2POffer(String offerId, double price) =>
      _call('editP2POffer', {'offerId': offerId, 'price': price});

  Future<void> cancelP2POffer(String offerId) =>
      _call('cancelP2POffer', {'offerId': offerId});

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

  Future<bool> needsTwoFactor() async {
    final result = await _functions.httpsCallable('postLoginCheck').call();
    final payload = result.data;
    final data = payload is Map && payload['data'] is Map ? payload['data'] : payload;
    return data is Map && data['needs2FA'] == true;
  }

  Future<void> verifyTwoFactor(String token) =>
      _call('verify2FACall', {'token': token});

  Future<Map<String, dynamic>> requestSmsTwoFactorCode() async {
    final response = await _post2FAFunction('requestSms2FA', {});
    return response;
  }

  Future<Map<String, dynamic>> requestEmailTwoFactorCode() async {
    final response = await _post2FAFunction('requestEmail2FA', {});
    return response;
  }

  Future<Map<String, dynamic>> regenerateBackupCodes() async {
    final response = await _post2FAFunction('regenerateBackupCodes', {});
    return response;
  }

  Future<Map<String, dynamic>> startTwoFactorEnrollment() async {
    final response = await _post2FAFunction('enroll2FA', {});
    return response;
  }

  Future<void> confirmTwoFactorEnrollment(String token) async {
    await _post2FAFunction('confirm2FA', {'token': token});
  }

  Future<Map<String, dynamic>> getGraphSummary() => _callForData('getGraphSummary', {});

  Future<Map<String, dynamic>> getGraphHistory({String? startupName, String? type}) =>
      _callForData('getGraphHistory', {
        if (startupName != null) 'startupName': startupName,
        if (type != null) 'type': type,
      });

  Future<Map<String, dynamic>> getGraphAsset(String startupName) =>
      _callForData('getGraphAsset', {'startupName': startupName});

  Future<void> _call(String name, Map<String, dynamic> data) async {
    await _functions.httpsCallable(name).call(data);
  }

  Future<Map<String, dynamic>> _post2FAFunction(
    String name,
    Map<String, dynamic> body,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Usuário precisa estar autenticado para 2FA.');
    }

    final response = await http.post(
      Uri.parse(_twoFactorUrl(name)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
        'x-user-id': user.uid,
      },
      body: jsonEncode(body),
    );

    final decoded = jsonDecode(response.body);
    final payload = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'raw': decoded};

    if (response.statusCode >= 400) {
      throw Exception(payload['error']?.toString() ?? 'Erro ao executar 2FA.');
    }

    return payload;
  }

  Future<Map<String, dynamic>> _callForData(String name, Map<String, dynamic> data) async {
    final result = await _functions.httpsCallable(name).call(data);
    final payload = result.data;
    final inner = (payload is Map && payload['data'] is Map) ? payload['data'] : payload;
    return Map<String, dynamic>.from(inner as Map);
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
      return '127.0.0.1';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return '10.0.2.2';
      default:
        return '127.0.0.1';
    }
  }

  String _twoFactorUrl(String functionName) {
    final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
    if (kDebugMode) {
      final host = _firebaseEmulatorHost();
      return 'http://$host:5001/$projectId/southamerica-east1/$functionName';
    }

    return 'https://southamerica-east1-$projectId.cloudfunctions.net/$functionName';
  }
}
