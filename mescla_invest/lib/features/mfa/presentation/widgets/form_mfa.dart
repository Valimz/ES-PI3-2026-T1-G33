import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mescla_invest/core/theme/app_theme.dart';
import 'package:mescla_invest/features/mfa/presentation/pages/mfa_management_page.dart';
import 'package:mescla_invest/services/backend_service.dart';

/// Formulário de ativação do MFA.
/// Exibe seleção de método (TOTP, E-mail, SMS),
/// depois prossegue com o enrollment do método escolhido.
class FormMfa extends StatefulWidget {
  const FormMfa({super.key});

  @override
  State<FormMfa> createState() => _FormMfaState();
}

enum MfaStep {
  loading,
  emailVerification,
  methodSelection,
  totpSetup,
  emailMfaSetup,
  smsMfaSetup,
  codeVerification,
}

class _FormMfaState extends State<FormMfa> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _phoneController = TextEditingController();

  MfaStep _currentStep = MfaStep.loading;
  bool _isSubmitting = false;
  bool _verificationEmailSent = false;
  String? _feedbackMessage;
  bool _feedbackIsError = false;
  String? _serverMessage; // message from server about where code was sent
  String _selectedMethod = ''; // 'totp', 'email', 'sms'

  TotpSecret? _totpSecret;
  String? _qrCodeUri;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _feedbackMessage = message;
      _feedbackIsError = isError;
    });
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _feedbackMessage == message) {
        setState(() => _feedbackMessage = null);
      }
    });
  }

  /// Verifica o estado do usuário e decide a tela inicial.
  Future<void> _initialize() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showFeedback('Usuário não logado. Faça login novamente.', isError: true);
      return;
    }

    await user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser!;

    // Verificar TOTP nativo do Firebase
    final enrolledFactors =
        await refreshedUser.multiFactor.getEnrolledFactors();

    // Verificar MFA customizado (email/sms) no backend
    try {
      final status = await BackendService().checkMfaStatus();
      if (status['mfaEnabled'] == true || enrolledFactors.isNotEmpty) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MfaManagementPage()),
        );
        return;
      }
    } catch (e) {
      // Se o backend falhar, ainda verificar TOTP do Firebase
      if (enrolledFactors.isNotEmpty) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MfaManagementPage()),
        );
        return;
      }
    }

    // Se e-mail não verificado, pedir verificação
    if (!refreshedUser.emailVerified) {
      setState(() => _currentStep = MfaStep.emailVerification);
      return;
    }

    setState(() => _currentStep = MfaStep.methodSelection);
  }

  // ── Email Verification ──

  Future<void> _sendVerificationEmail() async {
    setState(() => _isSubmitting = true);
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (!mounted) return;
      setState(() => _verificationEmailSent = true);
      _showFeedback('📧 E-mail de verificação enviado com sucesso!');
    } catch (e) {
      _showFeedback('Erro ao enviar e-mail: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _recheckEmail() async {
    setState(() => _isSubmitting = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        _showFeedback('✅ E-mail verificado com sucesso!');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            _currentStep = MfaStep.methodSelection;
            _verificationEmailSent = false;
          });
        }
      } else {
        _showFeedback('E-mail ainda não verificado.', isError: true);
      }
    } catch (e) {
      _showFeedback('Erro: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Method Selection ──

  Future<void> _onMethodSelected(String method) async {
    _selectedMethod = method;
    _codeController.clear();

    if (method == 'totp') {
      setState(() => _currentStep = MfaStep.loading);
      await _generateTotpSecret();
    } else if (method == 'email') {
      setState(() => _currentStep = MfaStep.emailMfaSetup);
    } else if (method == 'sms') {
      setState(() => _currentStep = MfaStep.smsMfaSetup);
    }
  }

  // ── TOTP Setup ──

  Future<void> _generateTotpSecret() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showFeedback('Usuário não logado.', isError: true);
        setState(() => _currentStep = MfaStep.methodSelection);
        return;
      }

      final session = await user.multiFactor.getSession();
      final totpSecret =
          await TotpMultiFactorGenerator.generateSecret(session);

      final accountName = user.email ?? 'MesclaInvest';
      const issuer = 'MesclaInvest';
      final uri = await totpSecret.generateQrCodeUrl(
        accountName: accountName,
        issuer: issuer,
      );

      setState(() {
        _totpSecret = totpSecret;
        _qrCodeUri = uri;
        _currentStep = MfaStep.totpSetup;
      });
    } catch (e) {
      debugPrint('❌ Erro TOTP: $e');
      if (!mounted) return;
      final errorStr = e.toString();
      if (errorStr.contains('maximum-second-factor-count-exceeded') ||
          errorStr.contains('Too many second factors')) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MfaManagementPage()),
        );
        return;
      }
      _showFeedback('Erro ao configurar autenticação. Tente novamente.',
          isError: true);
      setState(() => _currentStep = MfaStep.methodSelection);
    }
  }

  Future<void> _submitTotp() async {
    if (!_formKey.currentState!.validate() || _totpSecret == null) return;
    setState(() => _isSubmitting = true);
    try {
      final assertion =
          await TotpMultiFactorGenerator.getAssertionForEnrollment(
        _totpSecret!,
        _codeController.text.trim(),
      );
      await FirebaseAuth.instance.currentUser!.multiFactor
          .enroll(assertion, displayName: 'Autenticador TOTP');
      if (!mounted) return;
      _showSuccessAndPop('Aplicativo Autenticador');
    } on FirebaseAuthException catch (e) {
      _showFeedback(e.message ?? 'Código inválido.', isError: true);
    } catch (e) {
      _showFeedback('Erro: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Email MFA ──

  Future<void> _sendEmailMfaCode() async {
    setState(() => _isSubmitting = true);
    try {
      final result =
          await BackendService().sendMfaCode(method: 'email');
      if (!mounted) return;
      _serverMessage = result['message'] as String?;
      _showFeedback(_serverMessage ?? 'Código enviado para seu e-mail!');
      setState(() => _currentStep = MfaStep.codeVerification);
    } catch (e) {
      _showFeedback(
          e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── SMS MFA ──

  Future<void> _sendSmsMfaCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showFeedback('Informe um número de telefone.', isError: true);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final result = await BackendService()
          .sendMfaCode(method: 'sms', phone: phone);
      if (!mounted) return;
      _serverMessage = result['message'] as String?;
      _showFeedback(_serverMessage ?? 'Código enviado por SMS!');
      setState(() => _currentStep = MfaStep.codeVerification);
    } catch (e) {
      _showFeedback(
          e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Code Verification (shared for email/sms) ──

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await BackendService()
          .verifyMfaCode(_codeController.text.trim());
      if (!mounted) return;
      final label = _selectedMethod == 'email' ? 'E-mail' : 'SMS';
      _showSuccessAndPop(label);
    } catch (e) {
      _showFeedback(
          e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isSubmitting = true);
    try {
      final result = await BackendService().sendMfaCode(
        method: _selectedMethod,
        phone: _selectedMethod == 'sms'
            ? _phoneController.text.trim()
            : null,
      );
      if (!mounted) return;
      _showFeedback(result['message'] as String? ?? 'Novo código enviado!');
    } catch (e) {
      _showFeedback(
          e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Success dialog ──

  Future<void> _showSuccessAndPop(String methodLabel) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.positive, size: 28),
            SizedBox(width: 10),
            Expanded(child: Text('MFA Ativado! 🎉')),
          ],
        ),
        content: Text(
          'Verificação de dois fatores por $methodLabel ativada com sucesso!\n\n'
          'Sua conta agora está mais segura.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('OK, Entendi'),
          ),
        ],
      ),
    );
  }

  // ── Validators ──

  String? _validateCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o código de 6 dígitos';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'O código precisa ter exatamente 6 números';
    }
    return null;
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_feedbackMessage != null) _buildFeedbackBanner(),
        _buildCurrentStep(),
      ],
    );
  }

  Widget _buildFeedbackBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _feedbackIsError
            ? AppColors.negative.withValues(alpha: 0.1)
            : AppColors.positive.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _feedbackIsError
              ? AppColors.negative.withValues(alpha: 0.3)
              : AppColors.positive.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _feedbackIsError
                ? Icons.error_outline
                : Icons.check_circle_outline,
            color: _feedbackIsError ? AppColors.negative : AppColors.positive,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _feedbackMessage!,
              style: TextStyle(
                color:
                    _feedbackIsError ? AppColors.negative : AppColors.positive,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _feedbackMessage = null),
            child: Icon(Icons.close, size: 18,
                color: _feedbackIsError
                    ? AppColors.negative
                    : AppColors.positive),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case MfaStep.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Verificando conta...',
                    style: TextStyle(color: AppColors.textBody)),
              ],
            ),
          ),
        );
      case MfaStep.emailVerification:
        return _buildEmailVerification();
      case MfaStep.methodSelection:
        return _buildMethodSelection();
      case MfaStep.totpSetup:
        return _buildTotpSetup();
      case MfaStep.emailMfaSetup:
        return _buildEmailMfaSetup();
      case MfaStep.smsMfaSetup:
        return _buildSmsMfaSetup();
      case MfaStep.codeVerification:
        return _buildCodeVerification();
    }
  }

  // ═══════════════════════════════════════════════════
  // ── Step: Email Verification (account verification)
  // ═══════════════════════════════════════════════════
  Widget _buildEmailVerification() {
    return Center(
      child: Column(
        children: [
          _buildStepIcon(Icons.mark_email_unread_outlined),
          const SizedBox(height: 20),
          const Text('Verificação de E-mail Necessária',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Para ativar a autenticação de dois fatores, '
              'primeiro você precisa verificar seu e-mail.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
          ),
          const SizedBox(height: 28),
          if (!_verificationEmailSent)
            _buildPrimaryButton(
              icon: Icons.send,
              label: 'Enviar e-mail de verificação',
              onPressed: _isSubmitting ? null : _sendVerificationEmail,
              isLoading: _isSubmitting,
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '📧 E-mail enviado! Verifique sua caixa de entrada.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _isSubmitting ? null : _recheckEmail,
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

  // ═══════════════════════════════════════════════════
  // ── Step: Method Selection
  // ═══════════════════════════════════════════════════
  Widget _buildMethodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: _buildStepIcon(Icons.shield_outlined)),
        const SizedBox(height: 20),
        const Text('Ativar Verificação em\nDuas Etapas',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              height: 1.3,
            ),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text('Escolha como deseja receber o código de verificação:',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textBody.withValues(alpha: 0.7),
                height: 1.5)),
        const SizedBox(height: 28),
        _buildMethodCard(
          icon: Icons.security_rounded,
          title: 'Aplicativo Autenticador',
          subtitle: 'Google Authenticator ou Authy',
          recommended: true,
          onTap: () => _onMethodSelected('totp'),
        ),
        const SizedBox(height: 12),
        _buildMethodCard(
          icon: Icons.email_outlined,
          title: 'E-mail',
          subtitle: 'Código enviado para seu e-mail cadastrado',
          onTap: () => _onMethodSelected('email'),
        ),
        const SizedBox(height: 12),
        _buildMethodCard(
          icon: Icons.sms_outlined,
          title: 'SMS',
          subtitle: 'Código enviado por mensagem de texto',
          onTap: () => _onMethodSelected('sms'),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // ── Step: Email MFA Setup
  // ═══════════════════════════════════════════════════
  Widget _buildEmailMfaSetup() {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBackButton(),
        const SizedBox(height: 8),
        Center(child: _buildStepIcon(Icons.email_outlined)),
        const SizedBox(height: 16),
        const Text('MFA por E-mail',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          'Um código de 6 dígitos será enviado para:\n$email',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: AppColors.textBody.withValues(alpha: 0.7), height: 1.5),
        ),
        const SizedBox(height: 8),
        Text('O código expira em 5 minutos.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12,
                color: AppColors.textBody.withValues(alpha: 0.5))),
        const SizedBox(height: 28),
        _buildPrimaryButton(
          icon: Icons.send,
          label: 'Enviar Código por E-mail',
          onPressed: _isSubmitting ? null : _sendEmailMfaCode,
          isLoading: _isSubmitting,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // ── Step: SMS MFA Setup
  // ═══════════════════════════════════════════════════
  Widget _buildSmsMfaSetup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBackButton(),
        const SizedBox(height: 8),
        Center(child: _buildStepIcon(Icons.sms_outlined)),
        const SizedBox(height: 16),
        const Text('MFA por SMS',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          'Informe o número de telefone que receberá o código:',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: AppColors.textBody.withValues(alpha: 0.7), height: 1.5),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Número de telefone',
            hintText: '+55 11 99999-9999',
            prefixIcon: const Icon(Icons.phone_outlined),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        Text('O código expira em 5 minutos.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12,
                color: AppColors.textBody.withValues(alpha: 0.5))),
        const SizedBox(height: 24),
        _buildPrimaryButton(
          icon: Icons.send,
          label: 'Enviar Código por SMS',
          onPressed: _isSubmitting ? null : _sendSmsMfaCode,
          isLoading: _isSubmitting,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // ── Step: Code Verification (email/sms shared)
  // ═══════════════════════════════════════════════════
  Widget _buildCodeVerification() {
    final methodLabel = _selectedMethod == 'email' ? 'e-mail' : 'SMS';
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBackToMethod(),
          const SizedBox(height: 8),
          Center(
            child: _buildStepIcon(
              _selectedMethod == 'email'
                  ? Icons.mark_email_read_outlined
                  : Icons.sms_outlined,
            ),
          ),
          const SizedBox(height: 16),
          Text('Verificar Código',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            _serverMessage ??
                'Digite o código de 6 dígitos enviado por $methodLabel.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textBody.withValues(alpha: 0.7),
                height: 1.5),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              hintText: '000000',
              hintStyle: TextStyle(
                color: AppColors.textBody.withValues(alpha: 0.3),
                fontSize: 28,
                letterSpacing: 8,
              ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            validator: _validateCode,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _verifyCode,
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
                : const Text('Verificar e Ativar',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _isSubmitting ? null : _resendCode,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reenviar código'),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // ── Step: TOTP Setup
  // ═══════════════════════════════════════════════════
  Widget _buildTotpSetup() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBackButton(),
          const SizedBox(height: 8),
          const Icon(Icons.security_rounded,
              size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          Text('Configurar Autenticador',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Text(
            '1. Abra o Google Authenticator ou Authy\n'
            '2. Escaneie o QR Code abaixo\n'
            '3. Digite o código de 6 dígitos gerado',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 24),
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
          if (_totpSecret != null)
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(
                    ClipboardData(text: _totpSecret!.secretKey));
                _showFeedback('🔑 Chave copiada!');
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copiar chave manual'),
            ),
          const SizedBox(height: 16),
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
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            validator: _validateCode,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitTotp,
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

  // ═══════════════════════════════════════════════════
  // ── Shared UI components
  // ═══════════════════════════════════════════════════

  Widget _buildStepIcon(IconData icon) {
    return Container(
      height: 80,
      width: 80,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, size: 40, color: AppColors.primary),
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () {
          setState(() {
            _currentStep = MfaStep.methodSelection;
            _totpSecret = null;
            _qrCodeUri = null;
            _codeController.clear();
          });
        },
        icon: const Icon(Icons.arrow_back, size: 18),
        label: const Text('Voltar à seleção'),
      ),
    );
  }

  Widget _buildBackToMethod() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () {
          setState(() {
            _codeController.clear();
            _serverMessage = null;
            if (_selectedMethod == 'email') {
              _currentStep = MfaStep.emailMfaSetup;
            } else {
              _currentStep = MfaStep.smsMfaSetup;
            }
          });
        },
        icon: const Icon(Icons.arrow_back, size: 18),
        label: const Text('Voltar'),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool recommended = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: recommended
              ? AppColors.accent.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: recommended ? AppColors.accent : Colors.grey.shade200,
            width: recommended ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: recommended
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon,
                  color: recommended ? AppColors.accent : AppColors.primary,
                  size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.primary,
                          )),
                      if (recommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Recomendado',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textBody.withValues(alpha: 0.6),
                      )),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
