import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FormMfa extends StatefulWidget {
  const FormMfa({super.key});

  @override
  State<FormMfa> createState() => _FormMfaState();
}

class _FormMfaState extends State<FormMfa> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isSubmitting = false;
  bool _isResending = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Código validado'),
          content: const Text(
              'O MFA foi ativado com sucesso no modo de demonstração.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resendCode() async {
    if (_isResending) return;

    setState(() => _isResending = true);
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Novo código enviado para o dispositivo cadastrado.')),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.security_rounded, size: 96, color: Colors.blue),
          const SizedBox(height: 20),
          Text(
            'Ativação do código de segurança',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Digite o código de 6 dígitos enviado por e-mail ou aplicativo autenticador.\n\n'
            'Nesta etapa a validação está em modo de demonstração, sem dependência do backend.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Código MFA',
              hintText: '000000',
              prefixIcon: Icon(Icons.pin_outlined),
              border: OutlineInputBorder(),
            ),
            validator: _validateCode,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Ativar MFA'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isResending ? null : _resendCode,
            child: _isResending
                ? const Text('Reenviando...')
                : const Text('Reenviar código'),
          ),
        ],
      ),
    );
  }
}
