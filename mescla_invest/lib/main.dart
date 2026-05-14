import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:mescla_invest/core/app.dart';
import 'package:mescla_invest/services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Registrar handler de notificações em background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Inicializar serviço de notificações
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Log: Firebase precisa ser configurado no Console. $e');
  }
  runApp(const InvestApp());
}
