// Nome: Felipe Augusto dos Santos Silva
// RA: 25003353

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
// para rodar o teste, basta:
// flutter test --dart-define=RUN_FIREBASE_FUNCTIONS_TESTS=true
const _runCallableTests = bool.fromEnvironment(
 'RUN_FIREBASE_FUNCTIONS_TESTS',
);
const _projectId = String.fromEnvironment(
 'FIREBASE_PROJECT_ID',
 defaultValue: '<coloque-id-projeto-firebase-aqui>',
);
// Emulador de Functions Local
const _functionsOrigin = String.fromEnvironment(
 'FIREBASE_FUNCTIONS_ORIGIN',
 defaultValue: 'http://127.0.0.1:5001',
);
// Emulador de Auth local
const _authOrigin = String.fromEnvironment(
 'FIREBASE_AUTH_ORIGIN',
 defaultValue: 'http://127.0.0.1:9099',
);
// Usuário de teste
const _testAuthEmail = 'mateus@mateus.pro.br';
const _testAuthPassword = '123456qwerty';
void main() {
 group(
 'Firebase callable functions de startups',
 () {
 late String idToken;

 setUpAll(() async {
 idToken = await _createAuthUserForTests();
 await _callFunction('seedStartupCatalog');
 });

 test('seedStartupCatalog popula startups demonstrativas', () async {
 final result = await _callFunction('seedStartupCatalog');
 final data = result['data'] as Map<String, dynamic>;

 expect(data['count'], 5);
 expect(data['ids'], contains('ecotech'));
 expect(data['ids'], contains('finflow'));
 expect(data['ids'], contains('agrosmart'));
 expect(data['ids'], contains('healthvibe'));
 expect(data['ids'], contains('edunext'));
 });

 test('listStartups lista e filtra startups autenticadas', () async {
 final result = await _callFunction(
 'listStartups',
		idToken: idToken,
		data: {'stage': 'Nova', 'search': 'agro'},
 );

 final data = result['data'] as List<dynamic>;

 expect(result['count'], 1);
 expect(data.first['id'], 'agrosmart');
 expect(data.first['stage'], 'Nova');
 });

 test('getStartupDetails retorna detalhes da startup', () async {
 final result = await _callFunction(
 'getStartupDetails',
 idToken: idToken,
		data: {'id': 'agrosmart'},
 );

 final data = result['data'] as Map<String, dynamic>;
 final access = data['access'] as Map<String, dynamic>;

 expect(data['id'], 'agrosmart');
 expect(data['executiveSummary'], isNotEmpty);
 expect(data['founders'], isNotEmpty);
 expect(data['publicQuestions'], isA<List<dynamic>>());
 expect(access['isInvestor'], isFalse);
 });

 test('createStartupQuestion cria pergunta publica', () async {
 final result = await _callFunction(
 'createStartupQuestion',
 idToken: idToken,
 data: {
		'startupId': 'agrosmart',
 'text': 'Qual e o proximo marco do projeto?',
 'visibility': 'publica',
 },
 );

 final data = result['data'] as Map<String, dynamic>;

 expect(data['id'], isNotEmpty);
 expect(data['startupId'], 'agrosmart');
 expect(data['visibility'], 'publica');
 });
 },
 skip: _runCallableTests ? false : _callableTestsSkipMessage,
 );
}
const _callableTestsSkipMessage = 'Inicie os emuladores e rode com '
 '--dart-define=RUN_FIREBASE_FUNCTIONS_TESTS=true.';

Uri _functionUri(String functionName) {
 return Uri.parse(
 '$_functionsOrigin/$_projectId/southamerica-east1/$functionName',
 );
}
Uri _authSignUpUri() {
 return Uri.parse(
 '$_authOrigin/identitytoolkit.googleapis.com/v1/'
 'accounts:signUp?key=fake-api-key',
 );
}
Uri _authSignInUri() {
 return Uri.parse(
 '$_authOrigin/identitytoolkit.googleapis.com/v1/'
 'accounts:signInWithPassword?key=fake-api-key',
 );
}
Future<String> _createAuthUserForTests() async {
 final response = await http.post(
 _authSignUpUri(),
 headers: {'Content-Type': 'application/json'},
 body: jsonEncode({
 'email': _testAuthEmail,
 'password': _testAuthPassword,
 'returnSecureToken': true,
 }),
 );

 final payload = _decodeResponse(response);

 if (response.statusCode != 200 && _isEmailAlreadyInUse(payload)) {
 return _signInAuthUserForTests();
 }

 if (response.statusCode != 200) {
 fail('Falha ao criar usuario no Auth emulator: $payload');
 }

 return payload['idToken'] as String;
}
Future<String> _signInAuthUserForTests() async {
 final response = await http.post(
 _authSignInUri(),
 headers: {'Content-Type': 'application/json'},
 body: jsonEncode({
 'email': _testAuthEmail,
 'password': _testAuthPassword,
 'returnSecureToken': true,
 }),
 );

 final payload = _decodeResponse(response);

 if (response.statusCode != 200) {
 fail('Falha ao autenticar usuario no Auth emulator: $payload');
 }

 return payload['idToken'] as String;
}
bool _isEmailAlreadyInUse(Map<String, dynamic> payload) {
 final error = payload['error'];

 if (error is! Map<String, dynamic>) {
 return false;
 }

 return error['message'] == 'EMAIL_EXISTS';
}
Future<Map<String, dynamic>> _callFunction(
 String functionName, {
 Map<String, dynamic> data = const {},
 String? idToken,
}) async {
 final headers = <String, String>{
 'Content-Type': 'application/json',
 };

 if (idToken != null) {
 headers['Authorization'] = 'Bearer $idToken';
 }

 final response = await http.post(
 _functionUri(functionName),
 headers: headers,
 body: jsonEncode({'data': data}),
 );

 final payload = _decodeResponse(response);

 if (response.statusCode != 200) {
 fail('Callable $functionName falhou: $payload');
 }

 if (payload['error'] != null) {
 fail('Callable $functionName retornou erro: ${payload['error']}');
 }

 return payload['result'] as Map<String, dynamic>;
}
Map<String, dynamic> _decodeResponse(http.Response response) {
 final decoded = jsonDecode(response.body);

 if (decoded is Map<String, dynamic>) {
 return decoded;
 }

 fail('Resposta inesperada: ${response.body}');
}