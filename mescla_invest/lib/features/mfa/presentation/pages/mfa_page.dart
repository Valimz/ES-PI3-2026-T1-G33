import 'package:flutter/material.dart';

class MfaPage extends StatelessWidget {
  const MfaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autenticação em duas etapas'),
        centerTitle: true,
      ),
      body: const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'A tela de 2FA será integrada pelo time na próxima etapa.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
