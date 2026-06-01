import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:firebase_auth/firebase_auth.dart';

class BackendService {
  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;

  IO.Socket? _socket;
  final String _baseUrl = 'http://172.16.232.111:3000'; // Chrome Web

  // Controladores de Stream locais para repassar os eventos do Socket
  final _walletStreamController = StreamController<Map<String, dynamic>?>.broadcast();
  final _assetsStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();

  BackendService._internal();

  /// Inicializa o Socket autenticado
  Future<void> connectSocket() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await user.getIdToken();

    _socket = IO.io(_baseUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .setAuth({'token': token})
      .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      print('✅ Conectado ao servidor TS Socket.io');
    });

    _socket!.on('wallet_update', (data) {
      if (data == null) {
        _walletStreamController.add(null);
      } else {
        _walletStreamController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('assets_update', (data) {
      if (data != null && data is List) {
        final List<Map<String, dynamic>> assets = List<Map<String, dynamic>>.from(
          data.map((e) => Map<String, dynamic>.from(e))
        );
        _assetsStreamController.add(assets);
      }
    });

    _socket!.onDisconnect((_) => print('❌ Desconectado do servidor TS'));
  }

  void disconnectSocket() {
    _socket?.disconnect();
    _socket = null;
  }

  // ============== STREAMS (LIDOS DO SOCKET) ==============
  
  Stream<Map<String, dynamic>?> getWalletData() {
    return _walletStreamController.stream;
  }

  Stream<List<Map<String, dynamic>>> getUserAssets() {
    return _assetsStreamController.stream;
  }

  // ============== API REST (MUDANÇAS DE ESTADO) ==============

  Future<void> addFunds(double amountToAdd) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Usuário não logado");

    final token = await user.getIdToken();
    
    final response = await http.post(
      Uri.parse('$_baseUrl/api/wallet/addFunds'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'amount': amountToAdd}),
    );

    if (response.statusCode != 200) {
      final errorMap = jsonDecode(response.body);
      throw Exception(errorMap['error'] ?? "Erro no servidor");
    }
  }

  Future<void> negotiateAsset(Map<String, dynamic> startup, double amountToBuy) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Usuário não logado");

    final token = await user.getIdToken();
    
    final response = await http.post(
      Uri.parse('$_baseUrl/api/wallet/buy'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'startup': startup,
        'amountToBuy': amountToBuy,
      }),
    );

    if (response.statusCode != 200) {
      final errorMap = jsonDecode(response.body);
      throw Exception(errorMap['error'] ?? "Erro no servidor ao comprar");
    }
  }

  Future<void> sellAllAsset(Map<String, dynamic> asset) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Usuário não logado");

    final token = await user.getIdToken();
    
    final response = await http.post(
      Uri.parse('$_baseUrl/api/wallet/sell'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'asset': asset,
      }),
    );

    if (response.statusCode != 200) {
      final errorMap = jsonDecode(response.body);
      throw Exception(errorMap['error'] ?? "Erro no servidor ao vender");
    }
  }

  // --- P2P ---
  Future<void> createP2POffer(Map<String, dynamic> asset, double price) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Usuário não logado");

    final token = await user.getIdToken();
    
    final response = await http.post(
      Uri.parse('$_baseUrl/api/p2p/createOffer'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'asset': asset,
        'price': price,
      }),
    );

    if (response.statusCode != 200) {
      final errorMap = jsonDecode(response.body);
      throw Exception(errorMap['error'] ?? "Erro no servidor ao criar oferta");
    }
  }

  Future<void> makeCounterOffer(String offerId, double proposedPrice) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Usuário não logado");

    final token = await user.getIdToken();
    
    final response = await http.post(
      Uri.parse('$_baseUrl/api/p2p/makeCounterOffer'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'offerId': offerId,
        'proposedPrice': proposedPrice,
      }),
    );

    if (response.statusCode != 200) {
      final errorMap = jsonDecode(response.body);
      throw Exception(errorMap['error'] ?? "Erro no servidor ao contrapropor");
    }
  }

  Future<void> acceptP2POffer(String offerId, {double? acceptedPrice, String? buyerIdParam, String? negotiationId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Usuário não logado");

    final token = await user.getIdToken();
    
    final response = await http.post(
      Uri.parse('$_baseUrl/api/p2p/acceptOffer'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'offerId': offerId,
        'acceptedPrice': acceptedPrice,
        'buyerIdParam': buyerIdParam,
        'negotiationId': negotiationId,
      }),
    );

    if (response.statusCode != 200) {
      final errorMap = jsonDecode(response.body);
      throw Exception(errorMap['error'] ?? "Erro no servidor ao aceitar oferta");
    }
  }

  // --- Startups Questions ---
  Future<void> sendQuestion(String startupId, String text, String visibility, List<String>? options) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Usuário não logado");

    final token = await user.getIdToken();
    
    final response = await http.post(
      Uri.parse('$_baseUrl/api/questions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'startupId': startupId,
        'text': text,
        'visibility': visibility,
        'options': options,
      }),
    );

    if (response.statusCode != 201) {
      final errorMap = jsonDecode(response.body);
      throw Exception(errorMap['error'] ?? "Erro no servidor ao enviar pergunta");
    }
  }

  Future<List<dynamic>> getQuestions(String startupId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Usuário não logado");

    final token = await user.getIdToken();
    
    final response = await http.get(
      Uri.parse('$_baseUrl/api/questions/$startupId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final errorMap = jsonDecode(response.body);
      throw Exception(errorMap['error'] ?? "Erro no servidor ao buscar perguntas");
    }

    return jsonDecode(response.body);
  }
  // --- MFA ---

  /// Envia código MFA por email ou SMS
  Future<Map<String, dynamic>> sendMfaCode({required String method, String? phone}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Usuário não logado");

    final token = await user.getIdToken();

    final body = <String, dynamic>{'method': method};
    if (phone != null) body['phone'] = phone;

    final response = await http.post(
      Uri.parse('$_baseUrl/api/mfa/send-code'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    final responseBody = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(responseBody['error'] ?? 'Erro ao enviar código MFA');
    }
    return Map<String, dynamic>.from(responseBody);
  }

  /// Verifica o código MFA digitado pelo usuário
  Future<Map<String, dynamic>> verifyMfaCode(String code) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Usuário não logado");

    final token = await user.getIdToken();

    final response = await http.post(
      Uri.parse('$_baseUrl/api/mfa/verify-code'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'code': code}),
    );

    final responseBody = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(responseBody['error'] ?? 'Código inválido');
    }
    return Map<String, dynamic>.from(responseBody);
  }

  /// Verifica o status do MFA do usuário
  Future<Map<String, dynamic>> checkMfaStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Usuário não logado");

    final token = await user.getIdToken();

    final response = await http.get(
      Uri.parse('$_baseUrl/api/mfa/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final responseBody = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(responseBody['error'] ?? 'Erro ao verificar MFA');
    }
    return Map<String, dynamic>.from(responseBody);
  }

  /// Desativa o MFA customizado (email/sms)
  Future<void> disableMfa() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Usuário não logado");

    final token = await user.getIdToken();

    final response = await http.post(
      Uri.parse('$_baseUrl/api/mfa/disable'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final errorMap = jsonDecode(response.body);
      throw Exception(errorMap['error'] ?? "Erro ao desativar MFA");
    }
  }

}
