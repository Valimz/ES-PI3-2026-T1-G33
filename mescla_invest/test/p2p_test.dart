import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'projetointegrador-13b6e');
const _functionsOrigin = String.fromEnvironment('FIREBASE_FUNCTIONS_ORIGIN', defaultValue: 'http://127.0.0.1:5001');
const _authOrigin = String.fromEnvironment('FIREBASE_AUTH_ORIGIN', defaultValue: 'http://127.0.0.1:9099');

const _testEmail = 'p2p-test@local.test';
const _testPass = '123456qwerty';

Uri _functionUri(String name) => Uri.parse('$_functionsOrigin/$_projectId/us-central1/$name');
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

void main() {
  group('P2P Callables', () {
    late String idToken;

    setUpAll(() async {
      final auth = await _signup();
      idToken = auth['idToken'] as String;
    });

    test('createP2POffer', () async {
      // create an offer with fake asset metadata
      final offer = await _callFunction('createP2POffer', data: {
        'asset': {'name': 'TestStartup', 'amount': '10 Tokens'},
        'price': 5
      }, idToken: idToken);
      expect(offer['data']['message'], isNotNull);
    }, timeout: Timeout(Duration(seconds: 20)));
  });
}
