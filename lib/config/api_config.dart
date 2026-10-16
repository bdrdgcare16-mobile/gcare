import 'package:flutter/foundation.dart';

class ApiConfig {
  // Physical device (same Wi-Fi as laptop) - DEV functions emulator
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

  // Build-time override, e.g.
  //   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5002/serv-dev-f2557/us-central1/api
  static const String _envBase =
      String.fromEnvironment('API_BASE_URL');

  // Which Firebase project main_common.startApp() initialized (main.dart /
  // main_prod.dart = true, main_dev.dart = false). This - not Dart's debug
  // vs release build mode - decides DEV vs PROD routing: the production
  // frontend must always talk to the production API, even in a `flutter
  // run` debug session, so that Firebase auth and the backend are always
  // the same project. Defaults to true (PROD) so that if `configureEnvironment`
  // is ever skipped, the app fails safe toward production instead of
  // silently resolving to a developer's local emulator IP.
  static bool _isProdEnvironment = true;

  /// Call once from `startApp()` before any network request can fire.
  /// Never call this to "fall back" DEV into PROD or vice versa at
  /// runtime - it reflects which main_*.dart entry point launched the app,
  /// fixed for the process lifetime.
  static void configureEnvironment({required bool isProd}) {
    _isProdEnvironment = isProd;
  }

  // Rejects a malformed IPv4 host before it ever reaches DNS/socket code.
  // A typo like `127.0.0.001` (leading zero in an octet) is not a valid
  // literal: Dart's Uri keeps it as a literal hostname, which then fails
  // `InternetAddress.lookup` with "Failed host lookup" for every single
  // request - surfacing as unrelated-looking errors across every page
  // instead of one clear startup failure. Fail fast in debug/profile only;
  // assert() is a no-op in release builds.
  static final RegExp _malformedIPv4Octet = RegExp(r'(^|\.)0+\d(\.|$)');

  static void _assertValidHost(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    assert(
      host.isEmpty || !_malformedIPv4Octet.hasMatch(host),
      'ApiConfig: "$host" has a leading-zero IPv4 octet (e.g. 127.0.0.001 '
      'instead of 127.0.0.1). This is not a valid address and every API '
      'request will fail host lookup. Fix API_BASE_URL / the host literal.',
    );
  }

  // Routing, in priority order:
  //  1. API_BASE_URL dart-define - explicit opt-in override for any mode
  //     (e.g. pointing a DEV debug run at a different emulator host).
  //  2. Release builds always use production, regardless of entry point -
  //     a release build must never ship pointing at a local emulator.
  //  3. Otherwise follow the environment the chosen main_*.dart entry point
  //     configured via configureEnvironment(): main.dart/main_prod.dart ->
  //     PROD, main_dev.dart -> the local DEV functions emulator. This keeps
  //     Firebase auth and the API on the same project in every build mode,
  //     including a plain `flutter run` debug session against production.
  static String get baseUrl {
    final resolved = _envBase.isNotEmpty
        ? _envBase
        : (kReleaseMode || _isProdEnvironment ? _prod : _physicalDevice);
    assert(() {
      _assertValidHost(resolved);
      return true;
    }());
    return resolved;
  }

  static String get prodUrl => _prod;
}
