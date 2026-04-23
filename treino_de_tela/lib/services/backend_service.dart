import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:firebase_auth/firebase_auth.dart';

class BackendService {
  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;

  IO.Socket? _socket;
  final String _baseUrl = 'http://10.0.2.2:3000'; // Emulador Android

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

  // --- FUTUROS MÉTODOS A SEREM MIGRADOS P2P, NEGOTIATE, ETC ---
}
