// Nome: Felipe Augusto dos Santos Silva
// RA: 25003353

import 'package:flutter/material.dart';

// Centraliza os estilos globais para facilitar manutenção futura.
class AppTheme {
  const AppTheme._();

  // Tema claro padrão da aplicação.
  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E7490)),
      scaffoldBackgroundColor: const Color(0xFFF4F7FB),
      useMaterial3: true,
    );
  }
}
