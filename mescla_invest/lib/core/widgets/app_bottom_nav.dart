import 'package:flutter/material.dart';
import 'package:mescla_invest/core/theme/app_theme.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({super.key, required this.currentIndex});

  static const List<String> _routes = [
    '/home',
    '/explore',
    '/portfolio',
    '/wallet',
    '/p2p',
  ];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == currentIndex) return;
        Navigator.of(context).pushReplacementNamed(_routes[index]);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explorar'),
        BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart), label: 'Portfólio'),
        BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet), label: 'Carteira'),
        BottomNavigationBarItem(
            icon: Icon(Icons.storefront), label: 'Mercado P2P'),
      ],
    );
  }
}
