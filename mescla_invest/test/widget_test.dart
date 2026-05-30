// Nome: Felipe Augusto dos Santos Silva
// RA: 25003353

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mescla_invest/core/theme/app_theme.dart';
import 'package:mescla_invest/features/auth/presentation/pages/login_page.dart';

void main() {
  // Valida que a LoginPage é a tela inicial e renderiza seus elementos principais.
  testWidgets('Renderiza LoginPage com campos de e-mail, senha e botao Entrar',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const LoginPage(),
      ),
    );

    expect(find.text('Bem-vindo de volta'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Criar Conta'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
