import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mescla_invest/core/theme/app_theme.dart';
import 'package:mescla_invest/features/auth/presentation/pages/login_page.dart';
import 'package:mescla_invest/features/auth/presentation/pages/register_page.dart';
import 'package:mescla_invest/features/esqueci_senha/presentation/pages/esqueci_senha_page.dart';
import 'package:mescla_invest/features/explore/presentation/pages/explore_page.dart';
import 'package:mescla_invest/features/home/presentation/pages/home_page.dart';
import 'package:mescla_invest/features/mfa/presentation/pages/mfa_page.dart';
import 'package:mescla_invest/features/p2p/presentation/pages/p2p_page.dart';
import 'package:mescla_invest/features/analise/presentation/pages/analise_graficos_page.dart';
import 'package:mescla_invest/features/portfolio/presentation/pages/portfolio_page.dart';
<<<<<<< HEAD
import 'package:mescla_invest/features/milestones/presentation/pages/milestone_page.dart';
import 'package:mescla_invest/features/esqueci-senha/presentation/pages/esqueci_senha_page.dart';
=======
import 'package:mescla_invest/features/wallet/presentation/pages/wallet_page.dart';
import 'package:mescla_invest/features/notifications/presentation/pages/notifications_page.dart';
>>>>>>> 51f660bea61144c236b3188220058623356a0ddd

class InvestApp extends StatelessWidget {
  const InvestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'InvestApp',
      theme: AppTheme.light(),
<<<<<<< HEAD
      routes: {
        '/milestones': (_) => const MilestonePage(),
      },
      home: AnaliseGraficosPage(),
=======
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const HomePage();
          }
          return const LoginPage();
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/explore': (context) => const ExplorePage(),
        '/portfolio': (context) => const PortfolioPage(),
        '/wallet': (context) => const WalletPage(),
        '/p2p': (context) => const P2PPage(),
        '/esqueci-senha': (context) => const EsqueciSenhaPage(),
        '/mfa': (context) => const MfaPage(),
        '/analise': (context) => const AnaliseGraficosPage(),
        '/notifications': (context) => const NotificationsPage(),
      },
>>>>>>> 51f660bea61144c236b3188220058623356a0ddd
    );
  }
}
