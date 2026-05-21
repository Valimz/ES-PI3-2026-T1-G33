/// Configurações globais do app, injetadas via `--dart-define` no build.
///
/// Exemplo:
/// ```
/// flutter run --dart-define=API_BASE_URL=http://192.168.0.10:3000
/// ```
class AppConfig {
  const AppConfig._();

  /// URL base da API REST do backend.
  /// - Web/Desktop: `http://localhost:3000`
  /// - Android emulador: `http://10.0.2.2:3000`
  /// - Dispositivo físico: IP da máquina na rede local
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
}
