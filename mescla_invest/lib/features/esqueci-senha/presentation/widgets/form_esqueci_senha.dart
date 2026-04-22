// Nome: Felipe Augusto dos Santos Silva
// RA: 25003353

import 'package:flutter/material.dart';
import 'package:mescla_invest/features/esqueci-senha/presentation/widgets/sucesso_envio_dialog.dart';

class FormEsqueciSenha extends StatefulWidget{
  const FormEsqueciSenha({super.key});

  @override
  State<FormEsqueciSenha> createState() => _FormEsqueciSenhaState();
}

class _FormEsqueciSenhaState extends State<FormEsqueciSenha> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: chamar repository aqui
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) {
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const SucessoEnvioDialog(),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Digite seu e-mail para recuperar senha',
            style: TextStyle(fontSize: 16,color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if(value == null || value.isEmpty) {
                return 'Por favor, insira seu e-mail';
              }
              if (!value.contains('@') || (!value.contains('.'))) {
                return 'Insira um e-mail válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null: _submit, 
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
            ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
            : const Text('Enviar Instruções'),
          ),
        ],
      ),
    );
  }
}

