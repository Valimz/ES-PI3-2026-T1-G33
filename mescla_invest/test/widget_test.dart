// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:mescla_invest/main.dart';

void main() {
  testWidgets('Renderiza tela de analise com filtros de periodo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MesclaInvestApp());

    expect(find.text('Análise e Gráficos'), findsOneWidget);
    expect(find.text('Valorização da moeda'), findsOneWidget);
    expect(find.text('1D'), findsOneWidget);
    expect(find.text('7D'), findsOneWidget);
    expect(find.text('1M'), findsOneWidget);
    expect(find.text('6M'), findsOneWidget);
    expect(find.text('1A'), findsOneWidget);
  });
}
