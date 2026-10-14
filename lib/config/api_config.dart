
class ApiConfig {
  // Physical device (same Wi-Fi as laptop)
  static const String _physicalDevice =
      'http://192.168.1.47:5002/serv-dev-f2557/us-central1/api';

  // Android emulator
  static const String _androidEmulator =
      'http://10.0.2.2:5002/serv-dev-f2557/us-central1/api';

  // Web
  static const String _webLocal =
      'http://127.0.0.1:5002/serv-dev-f2557/us-central1/api';

  // Production
  static const String _prod =
      'https://api-zmj7dqloiq-uc.a.run.app/api';

  // Compile-time override for local/emulator testing only.
  // Usage: flutter run -d chrome -t lib/main_dev.dart \
  //   --dart-define=API_BASE_URL=http://127.0.0.1:5002/serv-dev-f2557/us-central1/api
  // Production/release builds never set this define, so they always get _prod.
  static const String _override =
      String.fromEnvironment('API_BASE_URL');

  // TEMP: force production for release / production testing
  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    return _prod;
  }

  static String get prodUrl => _prod;
}