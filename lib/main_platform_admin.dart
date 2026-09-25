// lib/main_platform_admin.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';

import 'features/platform_admin/platform_admin_app.dart';
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_prod.dart' as prod;

/// Separate browser entry point for the Platform Admin portal
/// (Milestone 3D-B). This app is NOT part of the employee/mobile app —
/// run it standalone:
///
///   flutter run -d chrome -t lib/main_platform_admin.dart
///
///   Release build for the dedicated Hosting site (serv-platform-admin):
///   flutter build web -t lib/main_platform_admin.dart -o build/platform_admin_web
///
/// DEV/debug builds connect to the serv-dev-f2557 emulators (Auth on
/// 127.0.0.1:9099). Release builds use production Firebase options; the
/// portal is not deployed yet, so production remains untouched.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final options = kReleaseMode
      ? prod.DefaultFirebaseOptions.currentPlatform
      : dev.DefaultFirebaseOptions.currentPlatform;

  try {
    final app = await Firebase.initializeApp(options: options);
    debugPrint(
      'PlatformAdmin Firebase initialized: ${app.options.projectId}',
    );

    // DEV only — connect Firebase Auth to the emulator. The Flutter Web
    // portal always runs in a browser, so the emulator host is localhost.
    if (!kReleaseMode && kIsWeb) {
      await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
      debugPrint('PlatformAdmin: Auth emulator connected (127.0.0.1:9099)');
    }
  } catch (e) {
    debugPrint('PlatformAdmin Firebase init failed: $e');
  }

  runApp(const PlatformAdminApp());
}
