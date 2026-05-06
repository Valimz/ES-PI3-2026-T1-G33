import 'package:flutter/material.dart';
import 'package:mescla_invest/features/mfa/presentation/widgets/form_mfa.dart';

class MfaPage extends StatelessWidget {
  const MfaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ativar código de segurança'),
        centerTitle: true,
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: FormMfa(),
        ),
      ),
    );
  }
}