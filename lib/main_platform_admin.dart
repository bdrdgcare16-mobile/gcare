// lib/main_platform_admin.dart
//
// Dedicated entry point for the SERV Platform Admin web application.
// This boots ONLY the platform admin portal — never the normal
// Employee/Admin SERV app.
//
// Local development (Firebase emulators):
//   flutter run -d chrome -t lib/main_platform_admin.dart \
//     --dart-define=SERV_API_HOST=127.0.0.1
//
// Production build (deployed to the serv-platform-admin Hosting site):
//   flutter build web -t lib/main_platform_admin.dart
//   (or use lib/main_platform_admin_prod.dart, which is pinned to PROD)
//
// Environment selection:
//   --dart-define=SERV_ENV=DEV|PROD wins when provided. Otherwise a
//   SERV_API_HOST override selects DEV (local emulators); a bare build
//   defaults to PROD so the deployed bundle talks to servappbackend.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';

import 'features/platform_admin/platform_admin_app.dart';
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_platform_admin_prod.dart' as prod;
import 'config/api_config.dart';

const String _kApiHost = String.fromEnvironment('SERV_API_HOST');
const String _kEnvOverride = String.fromEnvironment('SERV_ENV');

String _resolveEnvironment() {
  final env = _kEnvOverride.trim().toUpperCase();
  if (env == 'DEV' || env == 'PROD') return env;
  // A SERV_API_HOST override only makes sense against the local emulators.
  return _kApiHost.isNotEmpty ? 'DEV' : 'PROD';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final environment = _resolveEnvironment();
  final options = environment == 'DEV'
      ? dev.DefaultFirebaseOptions.currentPlatform
      : prod.DefaultFirebaseOptions.currentPlatform;

  // Pin the API base URL to the resolved environment even for debug runs
  // (kReleaseMode alone isn't enough).
  ApiConfig.environment = environment;

  try {
    final app = await Firebase.initializeApp(options: options);
    debugPrint(
      'PlatformAdmin Firebase [$environment]: ${app.options.projectId}',
    );
    debugPrint('PlatformAdmin API base: ${ApiConfig.baseUrl}');
  } catch (e) {
    debugPrint('PlatformAdmin Firebase init failed: $e');
  }

  if (environment == 'DEV') {
    try {
      final host = ApiConfig.emulatorHost;
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      debugPrint('PlatformAdmin FirebaseAuth emulator: $host:9099');
      debugPrint('PlatformAdmin Firestore emulator: $host:8080');
    } catch (e) {
      debugPrint('PlatformAdmin Auth emulator setup failed: $e');
    }
  }

  runApp(const PlatformAdminApp());
}
