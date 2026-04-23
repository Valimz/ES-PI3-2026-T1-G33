// Nome: Felipe Augusto dos Santos Silva
// RA: 25003353

import 'package:flutter/material.dart';
import 'package:mescla_invest/core/theme/app_theme.dart';
import 'package:mescla_invest/features/analise/presentation/pages/analise_graficos_page.dart';
import 'package:mescla_invest/features/portfolio/presentation/pages/portfolio_page.dart';
import 'package:mescla_invest/features/esqueci-senha/presentation/pages/esqueci_senha_page.dart';


// Widget raiz do app com configuração global de navegação e tema.
class MesclaInvestApp extends StatelessWidget {
  const MesclaInvestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mescla Invest',
      debugShowCheckedModeBanner: false,
      // Tema único compartilhado para todas as telas.
      theme: AppTheme.light(),
      home: const PortfolioPage(),


    );
  }
}
