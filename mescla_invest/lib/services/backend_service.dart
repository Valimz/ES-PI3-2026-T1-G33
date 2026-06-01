import 'package:mescla_invest/services/functions_service.dart';
import 'package:mescla_invest/services/firestore_service.dart';

class BackendService {
  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;

  final FirestoreService _firestoreService = FirestoreService();
  final FunctionsService _functionsService = FunctionsService();

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
    await _functionsService.addFunds(amountToAdd);
  }

  Future<void> negotiateAsset(Map<String, dynamic> startup, double amountToBuy) async {
    await _functionsService.negotiateAsset(startup, amountToBuy);
  }

  Future<void> sellAllAsset(Map<String, dynamic> asset) async {
    await _functionsService.sellAllAsset(asset);
  }

  Future<void> sellPartialAsset(
      Map<String, dynamic> asset, double quotasToSell) async {
    if (quotasToSell <= 0) {
      throw Exception('Quantidade inválida para venda');
    }
    await _functionsService.sellPartialAsset(asset, quotasToSell);
  }

  Future<void> withdrawFunds(double amountToWithdraw) async {
    if (amountToWithdraw <= 0) {
      throw Exception('Valor inválido para saque');
    }
    await _functionsService.withdrawFunds(amountToWithdraw);
  }

  Future<void> createP2POffer(Map<String, dynamic> asset, double price,
      {double? quotasToSell}) async {
    if (quotasToSell != null && quotasToSell <= 0) {
      throw Exception('Quantidade inválida para a oferta');
    }
    await _functionsService.createP2POffer(asset, price,
        quotasToSell: quotasToSell);
  }

  Future<void> makeCounterOffer(String offerId, double proposedPrice) async {
    await _functionsService.makeCounterOffer(offerId, proposedPrice);
  }

  Future<void> editP2POffer(String offerId, double price) async {
    await _functionsService.editP2POffer(offerId, price);
  }

  Future<void> cancelP2POffer(String offerId) async {
    await _functionsService.cancelP2POffer(offerId);
  }

  Future<void> acceptP2POffer(String offerId, {double? acceptedPrice, String? buyerIdParam, String? negotiationId}) async {
    if (negotiationId != null && acceptedPrice != null) {
      await _functionsService.acceptP2POffer(
        offerId,
        acceptedPrice: acceptedPrice,
        buyerIdParam: buyerIdParam ?? negotiationId,
        negotiationId: negotiationId,
      );
      return;
    }

    if (negotiationId != null && acceptedPrice == null) {
      await _functionsService.acceptP2POffer(
        offerId,
        buyerIdParam: buyerIdParam ?? negotiationId,
        negotiationId: negotiationId,
      );
      return;
    }

    await _functionsService.acceptP2POffer(
      offerId,
      acceptedPrice: acceptedPrice,
      buyerIdParam: buyerIdParam,
    );
  }
}
