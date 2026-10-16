// lib/main_platform_admin_prod.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'features/platform_admin/platform_admin_app.dart';
import 'firebase_options_platform_admin_prod.dart';
import 'config/api_config.dart';

/// Production entry point for the browser Platform Admin portal.
/// Builds to the dedicated Hosting site serv-platform-admin (never the
/// default servappbackend site):
///
///   flutter build web --release \
///     -t lib/main_platform_admin_prod.dart \
///     --output build/platform_admin_web
///
/// This entry point always initializes Firebase against the production
/// servappbackend project and NEVER connects to any Firebase emulator —
/// there are no DEV fallbacks here by design. The API base URL resolves
/// to the production SERV backend via ApiConfig.baseUrl (release mode).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // This entry point is production-only by design — pin the API base
  // URL to prod even for debug runs (kReleaseMode alone isn't enough).
  ApiConfig.environment = 'PROD';

  try {
    final app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint(
      'PlatformAdmin Firebase initialized: ${app.options.projectId}',
    );
  } catch (e) {
    debugPrint('PlatformAdmin Firebase init failed: $e');
  }

  runApp(const PlatformAdminApp());
}
