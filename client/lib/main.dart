import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Pages
import 'package:serv_app/Pagesusers/login_page.dart';
import 'package:serv_app/Pagesadmin/leave_page.dart';
import 'package:serv_app/Pagesadmin/leave_form_page.dart';
import 'package:serv_app/Pagesusers/landing_screen.dart';

// Background
import 'package:workmanager/workmanager.dart';
import 'package:serv_app/background/background_tasks.dart';

// ────────────────────────────────────────────────────────────────────────────
// ADDED: tiny helper to avoid repeating the platform check
bool get _isAndroid => !kIsWeb && Platform.isAndroid;
// ────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (!kIsWeb && Platform.isAndroid) {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );
    }
  } catch (_) {}

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      try {
        if (FirebaseAuth.instance.currentUser == null) {
          await FirebaseAuth.instance.signInAnonymously();
          print('[FirebaseAuth] Anonymous sign-in OK');
        }
      } catch (e) {
        print('Anonymous sign-in failed: $e');
      }
    }
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  // ──────────────────────────────────────────────────────────────────────
  // ADDED: Initialize your background systems on Android after first frame.
  // (This avoids debugger attach glitches and is a no-op on web/iOS.)
  if (_isAndroid) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await initializeBackgroundSystems();
      } catch (e) {
        debugPrint('initializeBackgroundSystems failed: $e');
      }
    });
  }
  // ──────────────────────────────────────────────────────────────────────

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  String _initialRouteForPlatform() {
    if (kIsWeb) return '/login';
    if (defaultTargetPlatform == TargetPlatform.android) return '/landing';
    return '/login';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData myTheme = ThemeData(
      fontFamily: 'Inter',
      scaffoldBackgroundColor: const Color(0xFFF8F6FF),
      cardColor: Colors.white,

      // App-wide icon defaults (consistent across devices)
      iconTheme: const IconThemeData(
        color: Color(0xFF0F3D3E),
        size: 24,
      ),

      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 14, color: Colors.black),
      ),

      // ✅ Normalized AppBar title/icon sizes across devices
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF8C6EAF),
        // Consistent title style (keeps accessibility reasonable)
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: Colors.white,
          fontSize: 20,            // normalized size
          fontWeight: FontWeight.w600,
          height: 1.20,            // line-height for stable vertical layout
          letterSpacing: 0.15,
        ),
        // Also apply to menus/actions in the AppBar
        toolbarTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.20,
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
          size: 24,
        ),
        actionsIconTheme: IconThemeData(
          color: Colors.white,
          size: 24,
        ),
        toolbarHeight: 56,
        elevation: 2,
        // ⬇️ Option A applied globally: left-align all AppBar titles
        centerTitle: false,
        titleSpacing: 0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF655193),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),

      useMaterial3: true,
    );

    return MaterialApp(
      title: 'SERV App',
      debugShowCheckedModeBanner: false,
      theme: myTheme,

      // ✅ Clamp text scaling very gently so OEM/device quirks don't overscale titles.
      // Keeps accessibility: users who set large text still see some scaling.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final current = media.textScaler.clamp(minScaleFactor: 0.90, maxScaleFactor: 1.15);
        return MediaQuery(
          data: media.copyWith(textScaler: current),
          child: child ?? const SizedBox.shrink(),
        );
      },

      initialRoute: _initialRouteForPlatform(),
      routes: {
        '/': (context) => const LoginPage(),
        '/login': (context) => const LoginPage(),
        '/leave': (context) => const LeavePage(),
        '/add-leave': (context) => const LeaveFormPage(),
        '/landing': (context) => const LandingScreen(),
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Wrappers for background tracking
// ────────────────────────────────────────────────────────────────────────────

/// Optional convenience if any file still references an `initBackgroundService()`.
Future<void> initBackgroundService() async {
  if (_isAndroid) {
    await initializeBackgroundSystems();
  }
}

/// Start the foreground tracking (and persist identity)
Future<void> startFgTracking({
  required String empid,
  required String token,
}) async {
  if (!_isAndroid) return;
  try {
    await setTrackingIdentity(empid: empid, token: token);
    await startForegroundTracking();
    // If you want WorkManager backup to also start right away, uncomment:
    // await scheduleBackgroundTracking(empid: empid, token: token);
  } catch (e) {
    debugPrint('startFgTracking error: $e');
  }
}

/// Stop the foreground tracking
Future<void> stopFgTracking() async {
  if (!_isAndroid) return;
  try {
    await stopForegroundTracking();
    // If you started WorkManager backup on start, you can also cancel it here
    // if you pass empid around.
  } catch (e) {
    debugPrint('stopFgTracking error: $e');
  }
}
