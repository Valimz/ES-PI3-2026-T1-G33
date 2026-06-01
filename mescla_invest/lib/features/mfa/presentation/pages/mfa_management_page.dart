import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mescla_invest/core/theme/app_theme.dart';
import 'package:mescla_invest/services/backend_service.dart';

/// Tela de gerenciamento de MFA exibida quando o usuário já possui
/// um segundo fator cadastrado. Permite alterar o método ou desativar.
class MfaManagementPage extends StatefulWidget {
  const MfaManagementPage({super.key});

  @override
  State<MfaManagementPage> createState() => _MfaManagementPageState();
}

class _MfaManagementPageState extends State<MfaManagementPage> {
  bool _isLoading = true;
  String _currentMethod = 'Nenhum';
  bool _hasFirebaseMfa = false;
  List<MultiFactorInfo> _enrolledFactors = [];

  @override
  void initState() {
    super.initState();
    _loadMfaStatus();
  }

  Future<void> _loadMfaStatus() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser!;
      final factors = await refreshedUser.multiFactor.getEnrolledFactors();

      setState(() {
        _enrolledFactors = factors;
        _hasFirebaseMfa = factors.isNotEmpty;
      });

      // Check backend MFA status
      try {
        final status = await BackendService().checkMfaStatus();
        final method = status['mfaMethod'] as String?;
        setState(() {
          if (method == 'email') {
            _currentMethod = 'E-mail';
          } else if (method == 'sms') {
            _currentMethod = 'SMS';
          } else if (_hasFirebaseMfa) {
            final first = factors.first;
            if (first is TotpMultiFactorInfo) {
              _currentMethod = 'Aplicativo Autenticador (TOTP)';
            } else if (first is PhoneMultiFactorInfo) {
              _currentMethod = 'SMS';
            } else {
              _currentMethod = first.displayName ?? 'Desconhecido';
            }
          }
        });
      } catch (e) {
        // Fallback to Firebase only
        if (_hasFirebaseMfa) {
          final first = factors.first;
          if (first is TotpMultiFactorInfo) {
            _currentMethod = 'Aplicativo Autenticador (TOTP)';
          } else {
            _currentMethod = first.displayName ?? 'Desconhecido';
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar MFA: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _getMethodIcon() {
    if (_currentMethod.contains('TOTP') || _currentMethod.contains('Autenticador')) {
      return Icons.security_rounded;
    }
    if (_currentMethod.contains('SMS')) return Icons.sms_outlined;
    if (_currentMethod.contains('mail')) return Icons.email_outlined;
    return Icons.shield_outlined;
  }

  /// Desativa todo o MFA (Firebase + backend).
  Future<void> _disableMfa() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Desativar MFA'),
          ],
        ),
        content: const Text(
          'Tem certeza que deseja desativar a autenticação de dois fatores? '
          'Sua conta ficará menos segura.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.negative,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Remove Firebase MFA factors (TOTP)
      for (final factor in _enrolledFactors) {
        await user.multiFactor.unenroll(multiFactorInfo: factor);
      }

      // Disable backend MFA (email/sms)
      try {
        await BackendService().disableMfa();
      } catch (e) {
        debugPrint('Backend disable MFA: $e');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ MFA desativado com sucesso!'),
          backgroundColor: AppColors.positive,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Troca o método de MFA.
  Future<void> _switchMfaMethod(String method) async {
    final methodLabel = method == 'totp'
        ? 'Aplicativo Autenticador'
        : method == 'sms'
            ? 'SMS'
            : 'E-mail';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Alterar para $methodLabel?'),
        content: Text(
          'O método atual será removido e substituído por $methodLabel. '
          'Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Remove Firebase MFA factors
      for (final factor in _enrolledFactors) {
        await user.multiFactor.unenroll(multiFactorInfo: factor);
      }

      // Disable backend MFA
      try {
        await BackendService().disableMfa();
      } catch (e) {
        debugPrint('Backend disable: $e');
      }

      if (!mounted) return;

      // Navigate back and re-open MFA page for new enrollment
      Navigator.of(context).pop();
      Navigator.pushNamed(context, '/mfa');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar MFA'), centerTitle: true),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando...'),
                ],
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: 32),
                    const Text('Alterar Método de Verificação',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        )),
                    const SizedBox(height: 8),
                    Text(
                      'Escolha outro método para receber o código:',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textBody.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMethodOption(
                      icon: Icons.security_rounded,
                      title: 'Aplicativo Autenticador',
                      subtitle: 'Google Authenticator ou Authy',
                      isActive: _currentMethod.contains('TOTP') ||
                          _currentMethod.contains('Autenticador'),
                      onTap: () => _switchMfaMethod('totp'),
                    ),
                    const SizedBox(height: 12),
                    _buildMethodOption(
                      icon: Icons.email_outlined,
                      title: 'E-mail',
                      subtitle: 'Código enviado para seu e-mail',
                      isActive: _currentMethod.contains('mail'),
                      onTap: () => _switchMfaMethod('email'),
                    ),
                    const SizedBox(height: 12),
                    _buildMethodOption(
                      icon: Icons.sms_outlined,
                      title: 'SMS',
                      subtitle: 'Código enviado por mensagem de texto',
                      isActive: _currentMethod.contains('SMS'),
                      onTap: () => _switchMfaMethod('sms'),
                    ),
                    const SizedBox(height: 40),
                    OutlinedButton.icon(
                      onPressed: _disableMfa,
                      icon: const Icon(Icons.shield_outlined,
                          color: AppColors.negative),
                      label: const Text(
                        'Desativar Verificação em Duas Etapas',
                        style: TextStyle(
                          color: AppColors.negative,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.negative),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Atenção: desativar a verificação em duas etapas '
                      'reduz a segurança da sua conta.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textBody.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF2D2D4E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.verified_user_rounded,
                    color: AppColors.accent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MFA Ativo',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 4),
                    Text('Sua conta está protegida',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(_getMethodIcon(), color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('Método atual: ',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    )),
                Expanded(
                  child: Text(_currentMethod,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isActive ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accent.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.accent : Colors.grey.shade200,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: isActive ? AppColors.accent : AppColors.primary,
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.primary,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textBody.withValues(alpha: 0.6),
                      )),
                ],
              ),
            ),
            if (isActive)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Ativo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    )),
              )
            else
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
