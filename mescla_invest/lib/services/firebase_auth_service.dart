import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Registro com Email, Senha, Nome, CPF e Telefone (opcional)
  Future<User?> registerWithEmailAndPassword(String name, String email, String password, String cpf, {String? telefone}) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Atualiza o nome de exibição (Display Name) no Auth
      await credential.user?.updateDisplayName(name);
      
      // Criar o documento do usuário no Firestore
      final user = credential.user;
      if (user != null) {
        final FirebaseFirestore db = FirebaseFirestore.instance;
        final docRef = db.collection('users').doc(user.uid);
        
        await docRef.set({
          'nome': name,
          'email': email,
          'cpf': cpf,
          if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Inicializar a carteira (wallet)
        await docRef.collection('wallet').doc('main').set({
          'balance': 'R\$ 0,00',
          'appreciation': '+ 0,0%',
        });
      }
      
      return user;
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
