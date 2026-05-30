import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mescla_invest/core/theme/app_theme.dart';
import 'package:mescla_invest/features/auth/presentation/pages/register_page.dart';
import 'package:mescla_invest/features/home/presentation/pages/home_page.dart';
import 'package:mescla_invest/services/firebase_auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureSenha = true;
  bool _authFailed = false;

  static const String _genericCredentialMsg =
      'Email e/ou senha inválidos, tente novamente.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Center(
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      color: AppColors.accent,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Bem-vindo de volta',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Acesse sua carteira e gerencie seus aportes.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textBody.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 40),

                _buildFieldLabel("E-mail"),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: "seu@email.com",
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty || _authFailed) {
                      return _genericCredentialMsg;
                    }
                    return null;
                  },
                  onChanged: (_) {
                    if (_authFailed) {
                      setState(() => _authFailed = false);
                    }
                  },
                ),

                const SizedBox(height: 20),

                _buildFieldLabel("Senha"),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscureSenha,
                  decoration: InputDecoration(
                    hintText: "Sua senha",
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureSenha
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textBody.withValues(alpha: 0.5),
                      ),
                      onPressed: () =>
                          setState(() => _obscureSenha = !_obscureSenha),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty || _authFailed) {
                      return _genericCredentialMsg;
                    }
                    return null;
                  },
                  onChanged: (_) {
                    if (_authFailed) {
                      setState(() => _authFailed = false);
                    }
                  },
                ),

                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/esqueci-senha'),
                    child: const Text(
                      'Esqueceu a senha?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: () async {
                    setState(() => _authFailed = false);
                    if (_formKey.currentState!.validate()) {
                      try {
                        final authService = FirebaseAuthService();
                        await authService.loginWithEmailAndPassword(
                          _emailController.text,
                          _passwordController.text,
                        );
                        if (!context.mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HomePage()),
                        );
                      } on FirebaseAuthException catch (e) {
                        if (!context.mounted) return;
                        switch (e.code) {
                          case 'wrong-password':
                          case 'user-not-found':
                          case 'invalid-email':
                          case 'invalid-credential':
                            // Credencial inválida: marca os dois campos.
                            setState(() => _authFailed = true);
                            _formKey.currentState!.validate();
                            break;
                          default:
                            // Erro de rede/servidor: mostra SnackBar.
                            _showErrorSnackBar(_messageForAuthCode(e));
                        }
                      } catch (e) {
                        // Erros não relacionados à autenticação (ex.: Firestore).
                        if (!context.mounted) return;
                        _showErrorSnackBar(
                            'Não foi possível entrar. Tente novamente.');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Entrar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 30),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Novo por aqui? ",
                        style: TextStyle(
                            color: AppColors.textBody.withValues(alpha: 0.7)),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const RegisterPage()),
                          );
                        },
                        child: const Text(
                          "Criar Conta",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _messageForAuthCode(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'Falha de conexão. Verifique sua internet e tente novamente.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      default:
        return 'Erro ao fazer login. Tente novamente.';
    }
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          fontSize: 14,
        ),
      ),
    );
  }
}
