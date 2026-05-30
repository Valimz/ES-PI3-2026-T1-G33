import 'package:flutter/foundation.dart';

/// Configurações globais do app, injetadas via `--dart-define` no build.
///
/// Exemplo:
/// flutter run --dart-define=API_BASE_URL=http://192.168.0.10:3000
class AppConfig {
  const AppConfig._();

  /// URL base da API REST do backend.
  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) {
      return override;
    }

    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000';
      default:
        return 'http://localhost:3000';
    }
  }
}
