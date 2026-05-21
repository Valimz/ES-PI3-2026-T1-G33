import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mescla_invest/core/theme/app_theme.dart';

/// Formulário de ativação do MFA via TOTP (Google Authenticator / Authy).
/// Gera um segredo TOTP, exibe o QR Code para o usuário escanear,
/// e confirma o enrollment com o código de 6 dígitos.
class FormMfa extends StatefulWidget {
  const FormMfa({super.key});

  @override
  State<FormMfa> createState() => _FormMfaState();
}

class _FormMfaState extends State<FormMfa> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _needsEmailVerification = false;
  bool _verificationEmailSent = false;
  String? _errorMessage;

  TotpSecret? _totpSecret;
  String? _qrCodeUri;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkEmailAndGenerate();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Verifica se o e-mail está verificado antes de gerar TOTP.
  Future<void> _checkEmailAndGenerate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'Usuário não logado.';
        _isLoading = false;
      });
      return;
    }

    // Recarregar dados do usuário para ter o status atualizado
    await user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser!;

    if (!refreshedUser.emailVerified) {
      setState(() {
        _needsEmailVerification = true;
        _isLoading = false;
      });
      return;
    }

    // E-mail verificado: prosseguir com TOTP
    await _generateTotpSecret();
  }

  /// Envia e-mail de verificação.
  Future<void> _sendVerificationEmail() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (!mounted) return;
      setState(() => _verificationEmailSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail de verificação enviado!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar e-mail: $e')),
      );
    }
  }

  /// Gera o segredo TOTP via Firebase Auth e monta a URI do QR Code.
  Future<void> _generateTotpSecret() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Usuário não logado.';
          _isLoading = false;
        });
        return;
      }

      final session = await user.multiFactor.getSession();
      final totpSecret =
          await TotpMultiFactorGenerator.generateSecret(session);

      // Gerar URI otpauth:// para o QR Code
      final accountName = user.email ?? 'MesclaInvest';
      final issuer = 'MesclaInvest';
      final uri = await totpSecret.generateQrCodeUrl(
        accountName: accountName,
        issuer: issuer,
      );

      setState(() {
        _totpSecret = totpSecret;
        _qrCodeUri = uri;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erro ao gerar segredo TOTP: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro ao configurar autenticação:\n\n$e';
        _isLoading = false;
      });
    }
  }

  String? _validateCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o código de 6 dígitos';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'O código precisa ter exatamente 6 números';
    }
    return null;
  }

  /// Finaliza o enrollment verificando o código digitado pelo usuário.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _totpSecret == null) return;

    setState(() => _isSubmitting = true);
    try {
      final assertion = await TotpMultiFactorGenerator.getAssertionForEnrollment(
        _totpSecret!,
        _codeController.text.trim(),
      );
      await FirebaseAuth.instance.currentUser!.multiFactor
          .enroll(assertion, displayName: 'Autenticador TOTP');

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('MFA Ativado! 🎉'),
          content: const Text(
            'Sua conta agora possui Verificação de Dois Fatores ativa!\n\n'
            'A partir de agora, você precisará do seu app autenticador '
            'para fazer login.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // fecha dialog
                Navigator.of(context).pop(); // fecha tela de MFA
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.message ?? 'Código inválido. Tente novamente.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Verificando conta...'),
          ],
        ),
      );
    }

    if (_needsEmailVerification) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread_outlined,
                size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Verificação de E-mail Necessária',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Para ativar a autenticação de dois fatores, '
                'primeiro você precisa verificar seu e-mail.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            if (!_verificationEmailSent)
              ElevatedButton.icon(
                onPressed: _sendVerificationEmail,
                icon: const Icon(Icons.send),
                label: const Text('Enviar e-mail de verificação'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  '📧 E-mail enviado! Verifique sua caixa de entrada '
                  '(e o spam) e clique no link de verificação.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _needsEmailVerification = false;
                  _verificationEmailSent = false;
                });
                _checkEmailAndGenerate();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Já verifiquei, continuar'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _generateTotpSecret();
              },
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.security_rounded, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Configurar Autenticador',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            '1. Abra o Google Authenticator ou Authy\n'
            '2. Escaneie o QR Code abaixo\n'
            '3. Digite o código de 6 dígitos gerado',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 24),

          // QR Code
          if (_qrCodeUri != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: QrImageView(
                  data: _qrCodeUri!,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Chave manual (caso o usuário não consiga escanear)
          if (_totpSecret != null)
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(
                    ClipboardData(text: _totpSecret!.secretKey));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chave copiada!')),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copiar chave manual'),
            ),

          const SizedBox(height: 16),

          // Campo de código
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 6,
            ),
            decoration: InputDecoration(
              labelText: 'Código do Autenticador',
              hintText: '000000',
              prefixIcon: const Icon(Icons.pin_outlined),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: _validateCode,
          ),
          const SizedBox(height: 20),

          // Botão de confirmar
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Ativar MFA',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
