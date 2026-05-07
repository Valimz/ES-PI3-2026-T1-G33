import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mescla_invest/core/app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Log: Firebase precisa ser configurado no Console. $e');
  }
  runApp(const InvestApp());
}
