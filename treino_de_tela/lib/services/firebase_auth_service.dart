import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obter o usuário atual
  User? get currentUser => _auth.currentUser;

  // Stream para ouvir mudanças de estado de autenticação
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login com Email e Senha
  Future<User?> loginWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        throw Exception('Email ou senha inválidos.');
      } else {
        throw Exception('Erro ao fazer login: \${e.message}');
      }
    }
  }

  // Registro com Email, Senha e Nome
  Future<User?> registerWithEmailAndPassword(String name, String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Atualiza o nome de exibição (Display Name)
      await credential.user?.updateDisplayName(name);
      
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('A senha fornecida é muito fraca.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('A conta já existe para este email.');
      } else {
        throw Exception('Erro ao registrar: \${e.message}');
      }
    }
  }

  // Sair
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
