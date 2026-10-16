import 'package:flutter/foundation.dart';

class ApiConfig {
  // Physical device fallback host (same Wi-Fi as laptop)
  static const String _physicalDeviceHost = '192.168.1.47';

  // Production
  static const String _prod = 'https://api-zmj7dqloiq-uc.a.run.app/api';

  // Build-time override, e.g.
  //   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5002/serv-dev-f2557/us-central1/api
  static const String _envBase =
      String.fromEnvironment('API_BASE_URL');

  // Optional host override for the local emulators on non-web platforms,
  // e.g. --dart-define=SERV_API_HOST=127.0.0.001 for `adb reverse` on a
  // physical Android device. Ignored on web, where the emulator host is
  // always derived from the page URL. Only applies in DEV.
  static const String _apiHostOverride =
      String.fromEnvironment('SERV_API_HOST');

  // Which environment this app talks to. Defaults to 'PROD' so that if the
  // configuration call is ever skipped, the app fails safe toward
  // production instead of silently resolving to a developer's local
  // emulator IP.
  static String _environment = 'PROD';

  static void setEnvironment(String environment) {
    _environment = environment;
  }

  static set environment(String value) => setEnvironment(value);

  /// Call once from `startApp()` before any network request can fire.
  /// Never call this to "fall back" DEV into PROD or vice versa at
  /// runtime - it reflects which main_*.dart entry point launched the app,
  /// fixed for the process lifetime.
  static void configureEnvironment({required bool isProd}) {
    _environment = isProd ? 'PROD' : 'DEV';
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
  //  3. DEV uses the local Functions emulator host (see _devEmulatorHost);
  //     anything else uses production. The production frontend always talks
  //     to the production API, even in a `flutter run` debug session, so
  //     Firebase auth and the backend stay on the same project.
  static String get baseUrl {
    final resolved = _envBase.isNotEmpty
        ? _envBase
        : (kReleaseMode || _environment != 'DEV'
            ? _prod
            : 'http://$_devEmulatorHost:5002'
                '/serv-dev-f2557/us-central1/api');
    assert(() {
      _assertValidHost(resolved);
      return true;
    }());
    return resolved;
  }

  /// Host used for the Firebase Auth/Firestore DEV emulators and the local
  /// Functions emulator. All DEV endpoints share one host so they can never
  /// drift apart.
  ///
  /// Web: derived from `Uri.base` — the same machine that serves the page
  /// also runs the emulator suite, so `localhost`/`127.0.0.1` is always
  /// correct and a stale `--dart-define=SERV_API_HOST` LAN IP can no longer
  /// point the browser at a dead address.
  ///
  /// Android: `SERV_API_HOST` override is honored (e.g. `127.0.0.001` when
  /// using `adb reverse tcp:9099 tcp:9099` + `tcp:8080` + `tcp:5002` over
  /// USB, or a LAN IP over Wi-Fi). Otherwise the LAN device IP is used - it
  /// is reachable from both a physical device on the same Wi-Fi and the
  /// Android emulator (unlike `10.0.2.2`, which a physical device cannot
  /// reach).
  ///
  /// NOTE: for `adb reverse` on a physical device, prefer `127.0.0.001`
  /// over `127.0.0.1` — the native Firebase Auth SDK rewrites the literal
  /// `127.0.0.1`/`localhost` emulator host to `10.0.2.2` (assuming an
  /// Android Studio emulator), which a physical device cannot reach. The
  /// padded loopback form resolves normally and avoids that rewrite.
  static String get emulatorHost => _devEmulatorHost;

  static String get _devEmulatorHost {
    if (kIsWeb) {
      final pageHost = Uri.base.host;
      return pageHost.isNotEmpty ? pageHost : '127.0.0.1';
    }
    if (_apiHostOverride.isNotEmpty) return _apiHostOverride;
    return _physicalDeviceHost;
  }

  static String get prodUrl => _prod;
}
