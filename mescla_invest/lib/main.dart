import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mescla_invest/core/app.dart';
import 'package:mescla_invest/services/functions_service.dart';
import 'package:mescla_invest/services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await _configureLocalEmulators();

    // Registrar handler de notificações em background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Inicializar serviço de notificações
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Log: Firebase precisa ser configurado no Console. $e');
  }
  runApp(const InvestApp());
}

Future<void> _configureLocalEmulators() async {
  if (!kDebugMode) {
    return;
  }

  final emulatorHost = _firebaseEmulatorHost();
  FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
  FunctionsService().configureEmulator();
}

String _firebaseEmulatorHost() {
  const override = String.fromEnvironment('EMULATOR_HOST');
  if (override.isNotEmpty) {
    return override;
  }

  if (kIsWeb) {
    return 'localhost';
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return '10.0.2.2';
    default:
      return 'localhost';
  }
}
