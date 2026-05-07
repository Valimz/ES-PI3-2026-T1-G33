// Nome: Felipe Augusto dos Santos Silva
// RA: 25003353

import 'package:flutter/material.dart';
import 'package:mescla_invest/features/esqueci-senha/presentation/widgets/form_esqueci_senha.dart';

class EsqueciSenhaPage extends StatelessWidget {
	const EsqueciSenhaPage({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Recuperar Senha'),
				centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
			),
			body: SafeArea(
				child: SingleChildScrollView(
					padding: const EdgeInsets.all(24.0),
					child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Icon(
                Icons.lock_reset_rounded,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 40),

              Text(
                'Esqueceu sua senha?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const FormEsqueciSenha(),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Voltar para o Login'),
              )
            ],
          ),
				),
			),
		);
	}
}