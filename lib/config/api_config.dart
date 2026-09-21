
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Physical device (same Wi-Fi as laptop). Also works for Android emulator
  // if you replace the host with 10.0.2.2 locally.
  static const String _physicalDevice =
      'http://192.168.1.47:5002/serv-dev-f2557/us-central1/api';

  // Web
  static const String _webLocal =
      'http://127.0.0.1:5002/serv-dev-f2557/us-central1/api';

  // Production
  static const String _prod =
      'https://api-zmj7dqloiq-uc.a.run.app/api';

  /// Returns the correct backend URL for the current build mode.
  /// Release/profile builds always use production. Debug builds use the
  /// local Firebase Functions emulator so onboarding and other features
  /// are not tested against production by accident.
  ///
  /// For local physical Android/iOS devices, the laptop's LAN IP is used.
  /// For the Android emulator, switch to [_androidEmulator] manually.
  static String get baseUrl {
    if (kReleaseMode) return _prod;
    if (kIsWeb) return _webLocal;
    return _physicalDevice;
  }

  static String get prodUrl => _prod;
}