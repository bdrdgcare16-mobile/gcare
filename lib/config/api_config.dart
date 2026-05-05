
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

  // TEMP: force production for release / production testing
  static String get baseUrl {
    return _prod;
  }

  static String get prodUrl => _prod;
}