import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'projetointegrador-13b6e');
const _functionsOrigin = String.fromEnvironment('FIREBASE_FUNCTIONS_ORIGIN', defaultValue: 'http://127.0.0.1:5001');
const _authOrigin = String.fromEnvironment('FIREBASE_AUTH_ORIGIN', defaultValue: 'http://127.0.0.1:9099');

const _testEmail = 'wallet-test@local.test';
const _testPass = '123456qwerty';

Uri _functionUri(String name) => Uri.parse('$_functionsOrigin/$_projectId/us-central1/$name'.replaceFirst('\u007f', ''));
Uri _authSignUp() => Uri.parse('$_authOrigin/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key');
Uri _authSignIn() => Uri.parse('$_authOrigin/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key');

Future<Map<String, dynamic>> _signup() async {
  final r = await http.post(_authSignUp(), headers: {'Content-Type': 'application/json'}, body: jsonEncode({
    'email': _testEmail,
    'password': _testPass,
    'returnSecureToken': true,
  }));
  final p = jsonDecode(r.body) as Map<String,dynamic>;
  if (r.statusCode != 200 && p['error'] != null && p['error']['message'] == 'EMAIL_EXISTS') {
    return await _signin();
  }
  if (r.statusCode != 200) fail('Auth signup failed: $p');
  return p;
}

Future<Map<String, dynamic>> _signin() async {
  final r = await http.post(_authSignIn(), headers: {'Content-Type': 'application/json'}, body: jsonEncode({
    'email': _testEmail,
    'password': _testPass,
    'returnSecureToken': true,
  }));
  final p = jsonDecode(r.body) as Map<String,dynamic>;
  if (r.statusCode != 200) fail('Auth signin failed: $p');
  return p;
}

Future<Map<String, dynamic>> _callFunction(String name, {Map<String,dynamic> data = const {}, String? idToken}) async {
  final uri = Uri.parse('$_functionsOrigin/$_projectId/us-central1/$name');
  final headers = {'Content-Type': 'application/json'};
  if (idToken != null) headers['Authorization'] = 'Bearer $idToken';
  final r = await http.post(uri, headers: headers, body: jsonEncode({'data': data}));
  final p = jsonDecode(r.body) as Map<String,dynamic>;
  if (r.statusCode != 200) fail('Callable $name failed: $p');
  if (p['error'] != null) fail('Callable $name returned error: ${p['error']}');
  return p['result'] as Map<String,dynamic>;
}

Future<List<Map<String,dynamic>>> _listAssets(String uid, {String? idToken}) async {
  final uri = Uri.parse('http://127.0.0.1:8080/v1/projects/$_projectId/databases/(default)/documents/users/$uid/assets');
  final headers = {'Content-Type': 'application/json'};
  if (idToken != null) headers['Authorization'] = 'Bearer $idToken';
  final r = await http.get(uri, headers: headers);
  if (r.statusCode != 200) return [];
  final p = jsonDecode(r.body) as Map<String,dynamic>;
  final docs = (p['documents'] as List<dynamic>?) ?? [];
  return docs.map((d) => d as Map<String,dynamic>).toList();
}

void main() {
  group('Wallet Callables', () {
    late String idToken;
    late String uid;

    setUpAll(() async {
      final auth = await _signup();
      idToken = auth['idToken'] as String;
      uid = auth['localId'] as String;
    });

    test('addFunds then buyAsset then sellPartialAsset then withdrawFunds', () async {
      // 1) deposit 100
      final add = await _callFunction('addFunds', data: {'amount': 100}, idToken: idToken);
      expect(add['data']['message'], isNotNull);

      // 2) buy asset AgroSmart with amountToBuy 80 (price R$2 => quotas 40)
      final buy = await _callFunction('buyAsset', data: {
        'startup': {'name': 'AgroSmart', 'val': 'R\$ 2,00'},
        'amountToBuy': 80
      }, idToken: idToken);
      expect(buy['data']['message'], isNotNull);

      // 3) list assets via Firestore REST to find the asset id
      final assets = await _listAssets(uid, idToken: idToken);
      expect(assets.length, greaterThanOrEqualTo(1));

      final first = assets.first;
      // document name is of format: projects/.../documents/users/{uid}/assets/{docId}
      final name = first['name'] as String;
      final parts = name.split('/');
      final assetId = parts.isNotEmpty ? parts.last : null;
      expect(assetId, isNotNull);

      // 4) sell partial (sell 10 quotas)
      final sellPartial = await _callFunction('sellPartialAsset', data: {'asset': {'id': assetId, 'name': 'AgroSmart'}, 'quotasToSell': 10}, idToken: idToken);
      expect(sellPartial['data']['message'], isNotNull);
      expect(sellPartial['data']['soldAll'], isNotNull);

      // 5) withdraw funds (small amount)
      final withdraw = await _callFunction('withdrawFunds', data: {'amount': 5}, idToken: idToken);
      expect(withdraw['data']['message'], isNotNull);
    }, timeout: Timeout(Duration(seconds: 60)));
  });
}
