// lib/firebase_options_platform_admin_prod.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Production Firebase options for the browser Platform Admin portal
/// (lib/main_platform_admin_prod.dart) hosted on the dedicated site
/// serv-platform-admin.web.app.
///
/// Project: servappbackend (production). This file intentionally contains
/// NO serv-dev-f2557 project IDs and NO emulator endpoints — do not add
/// DEV configuration here. Uses the servappbackend web app config shared
/// with firebase_options_prod.dart; if a dedicated Firebase Web App is
/// registered for the portal in the console later, swap appId/apiKey here.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    // The portal is browser-only; other platforms are unsupported.
    throw UnsupportedError(
      'Platform Admin portal is only supported on Flutter Web.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCdlqOlxgqLHaeiT43_rWd2p2XWbPloBAI',
    appId: '1:227341863889:web:3fcef372ec7a14af7e6ef0',
    messagingSenderId: '227341863889',
    projectId: 'servappbackend',
    authDomain: 'servappbackend.firebaseapp.com',
    storageBucket: 'servappbackend.firebasestorage.app',
    measurementId: 'G-GY3NN1JZQ5',
  );
}
