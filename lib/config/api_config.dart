import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiConfig {
  // Physical device (same Wi-Fi as laptop)
  static const String _physicalDevice =
      'http://192.168.1.107:5002/serv-dev-f2557/us-central1/api';

  // Android emulator
  static const String _androidEmulator =
      'http://10.0.2.2:5002/serv-dev-f2557/us-central1/api';

  // Web
  static const String _webLocal =
      'http://127.0.0.1:5002/serv-dev-f2557/us-central1/api';

  // Production
  static const String _prod =
      'https://api-zmj7dqloiq-el.a.run.app/api';

  static String get baseUrl {
    if (kIsWeb) return _webLocal;

    try {
      if (Platform.isAndroid) {
        return _physicalDevice;
      }
      if (Platform.isIOS) {
        return _physicalDevice;
      }
    } catch (_) {}

    return _physicalDevice;
  }

  static String get prodUrl => _prod;
}