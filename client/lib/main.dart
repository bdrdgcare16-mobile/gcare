// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

// // Firebase
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/services.dart' show SystemUiOverlayStyle;
// import 'firebase_options.dart';
// import 'core/app_messenger.dart'; // <-- add import
// // Pages
// import 'package:serv_app/Pagesusers/login_page.dart';
// import 'package:serv_app/Pagesadmin/leave_page.dart';
// import 'package:serv_app/Pagesadmin/leave_form_page.dart';
// import 'package:serv_app/Pagesusers/landing_screen.dart';

// // Background
// import 'package:workmanager/workmanager.dart';
// import 'package:serv_app/background/background_tasks.dart';

// // ────────────────────────────────────────────────────────────────────────────
// // ADDED: connectivity gate (imports only)
// import 'package:serv_app/services/connectivity_service.dart';
// import 'package:serv_app/widgets/network_gate.dart';
// // ────────────────────────────────────────────────────────────────────────────

// // ────────────────────────────────────────────────────────────────────────────
// // ADDED: tiny helper to avoid repeating the platform check
// bool get _isAndroid => !kIsWeb && Platform.isAndroid;
// // ────────────────────────────────────────────────────────────────────────────

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   try {
//     if (!kIsWeb && Platform.isAndroid) {
//       await Workmanager().initialize(
//         callbackDispatcher,
//         isInDebugMode: false,
//       );
//     }
//   } catch (_) {}

//   try {
//     if (Firebase.apps.isEmpty) {
//       await Firebase.initializeApp(
//         options: DefaultFirebaseOptions.currentPlatform,
//       );
//       try {
//         if (FirebaseAuth.instance.currentUser == null) {
//           await FirebaseAuth.instance.signInAnonymously();
//           print('[FirebaseAuth] Anonymous sign-in OK');
//         }
//       } catch (e) {
//         print('Anonymous sign-in failed: $e');
//       }
//     }
//   } catch (e) {
//     print('Firebase initialization error: $e');
//   }

//   // ──────────────────────────────────────────────────────────────────────
//   // ADDED: Initialize your background systems on Android after first frame.
//   // (This avoids debugger attach glitches and is a no-op on web/iOS.)
//   if (_isAndroid) {
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       try {
//         await initializeBackgroundSystems();
//       } catch (e) {
//         debugPrint('initializeBackgroundSystems failed: $e');
//       }
//     });
//   }
//   // ──────────────────────────────────────────────────────────────────────

//   // ──────────────────────────────────────────────────────────────────────
//   // ADDED: start connectivity watcher once for the whole app
//   ConnectivityService.I.start();
//   // ──────────────────────────────────────────────────────────────────────

//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   String _initialRouteForPlatform() {
//     if (kIsWeb) return '/login';
//     if (defaultTargetPlatform == TargetPlatform.android) return '/landing';
//     return '/login';
//   }

//   @override
//   Widget build(BuildContext context) {
//     final ThemeData myTheme = ThemeData(
//       fontFamily: 'Inter',
//       scaffoldBackgroundColor: const Color(0xFFF8F6FF),
//       cardColor: Colors.white,

//       // App-wide icon defaults (consistent across devices)
//       iconTheme: const IconThemeData(
//         color: Color(0xFF0F3D3E),
//         size: 24,
//       ),

//       textTheme: const TextTheme(
//         bodyMedium: TextStyle(fontSize: 14, color: Colors.black),
//       ),

//       // ✅ Normalized AppBar title/icon sizes across devices
//       appBarTheme: const AppBarTheme(
//         backgroundColor: Color(0xFF8C6EAF),
//         // Consistent title style (keeps accessibility reasonable)
//         titleTextStyle: TextStyle(
//           fontFamily: 'Inter',
//           color: Colors.white,
//           fontSize: 20,            // normalized size
//           fontWeight: FontWeight.w600,
//           height: 1.20,            // line-height for stable vertical layout
//           letterSpacing: 0.15,
//         ),
//         // Also apply to menus/actions in the AppBar
//         toolbarTextStyle: TextStyle(
//           fontFamily: 'Inter',
//           color: Colors.white,
//           fontSize: 16,
//           fontWeight: FontWeight.w500,
//           height: 1.20,
//         ),
//         iconTheme: IconThemeData(
//           color: Colors.white,
//           size: 24,
//         ),
//         actionsIconTheme: IconThemeData(
//           color: Colors.white,
//           size: 24,
//         ),
//         // 🔧 CHANGED: make height consistent & a bit taller like your first screenshot
//         toolbarHeight: 64,
//         elevation: 2,
//         // ⬇️ Keep titles left-aligned globally
//         centerTitle: false,
//         // give a little left padding like the screenshot
//         titleSpacing: 16,
//         // ensure status bar icons are light and bar color matches
//         systemOverlayStyle: SystemUiOverlayStyle(
//           statusBarColor: Color(0xFF8C6EAF),
//           statusBarIconBrightness: Brightness.light, // Android
//           statusBarBrightness: Brightness.dark,      // iOS
//         ),
//       ),

//       elevatedButtonTheme: ElevatedButtonThemeData(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: const Color(0xFF655193),
//           foregroundColor: Colors.white,
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//           textStyle: const TextStyle(fontSize: 16),
//         ),
//       ),

//       useMaterial3: true,
//     );

//     return MaterialApp(
//       title: 'SERV App',
//       debugShowCheckedModeBanner: false,
//       theme: myTheme,
//       scaffoldMessengerKey: AppMessenger.key, // <-- keep

//       // ✅ Clamp text scaling + wrap with global NetworkGate (ADDED)
//       builder: (context, child) {
//         final media = MediaQuery.of(context);
//         final current = media.textScaler.clamp(
//           minScaleFactor: 0.90,
//           maxScaleFactor: 1.15,
//         );

//         // ADDED: wrap the (possibly null) child with NetworkGate
//         final wrapped = NetworkGate(
//           child: (child ?? const SizedBox.shrink()),
//         );

//         return MediaQuery(
//           data: media.copyWith(textScaler: current),
//           child: wrapped,
//         );
//       },

//       initialRoute: _initialRouteForPlatform(),
//       routes: {
//         '/': (context) => const LoginPage(),
//         '/login': (context) => const LoginPage(),
//         '/leave': (context) => const LeavePage(),
//         '/add-leave': (context) => const LeaveFormPage(),
//         '/landing': (context) => const LandingScreen(),
//       },
//     );
//   }
// }

// // ────────────────────────────────────────────────────────────────────────────
// // Wrappers for background tracking
// // ────────────────────────────────────────────────────────────────────────────

// /// Optional convenience if any file still references an `initBackgroundService()`.
// Future<void> initBackgroundService() async {
//   if (_isAndroid) {
//     await initializeBackgroundSystems();
//   }
// }

// /// Start the foreground tracking (and persist identity)
// Future<void> startFgTracking({
//   required String empid,
//   required String token,
// }) async {
//   if (!_isAndroid) return;
//   try {
//     await setTrackingIdentity(empid: empid, token: token);
//     await startForegroundTracking();
//     // If you want WorkManager backup to also start right away, uncomment:
//     // await scheduleBackgroundTracking(empid: empid, token: token);
//   } catch (e) {
//     debugPrint('startFgTracking error: $e');
//   }
// }

// /// Stop the foreground tracking
// Future<void> stopFgTracking() async {
//   if (!_isAndroid) return;
//   try {
//     await stopForegroundTracking();
//     // If you started WorkManager backup on start, you can also cancel it here
//     // if you pass empid around.
//   } catch (e) {
//     debugPrint('stopFgTracking error: $e');
//   }
// }
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'firebase_options.dart';

// ✅ Start app at AuthGuard (routes to login/admin/employee based on token/role)
import 'auth/auth_guard.dart';

// Core messenger for global SnackBars/Toasts
import 'core/app_messenger.dart';

// Pages (still available via named routes if you use them elsewhere)
import 'package:serv_app/Pagesusers/login_page.dart';
import 'package:serv_app/Pagesadmin/leave_page.dart';
import 'package:serv_app/Pagesadmin/leave_form_page.dart';
import 'package:serv_app/Pagesusers/landing_screen.dart';

// Background
import 'package:workmanager/workmanager.dart';
import 'package:serv_app/background/background_tasks.dart';

// Connectivity gate
import 'package:serv_app/services/connectivity_service.dart';
import 'package:serv_app/widgets/network_gate.dart';

// ────────────────────────────────────────────────────────────────────────────
// Tiny helper to avoid repeating the platform check
bool get _isAndroid => !kIsWeb && Platform.isAndroid;
// ────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Workmanager (Android only)
  try {
    if (_isAndroid) {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );
    }
  } catch (_) {}

  // Firebase init (+ anonymous auth in case your rules require an auth user)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      try {
        if (FirebaseAuth.instance.currentUser == null) {
          await FirebaseAuth.instance.signInAnonymously();
          // ignore: avoid_print
          print('[FirebaseAuth] Anonymous sign-in OK');
        }
      } catch (e) {
        // ignore: avoid_print
        print('Anonymous sign-in failed: $e');
      }
    }
  } catch (e) {
    // ignore: avoid_print
    print('Firebase initialization error: $e');
  }

  // Initialize background systems on Android after first frame
  if (_isAndroid) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await initializeBackgroundSystems();
      } catch (e) {
        debugPrint('initializeBackgroundSystems failed: $e');
      }
    });
  }

  // Start connectivity watcher for the whole app
  ConnectivityService.I.start();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // If you still need platform-specific initial routes elsewhere, keep this helper.
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

      // App-wide icon defaults
      iconTheme: const IconThemeData(
        color: Color(0xFF0F3D3E),
        size: 24,
      ),

      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 14, color: Colors.black),
      ),

      // ✅ Normalized AppBar (from your first code) + status bar style
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF8C6EAF),
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.20,
          letterSpacing: 0.15,
        ),
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
        // Taller like your original screenshot
        toolbarHeight: 64,
        elevation: 2,
        centerTitle: false,
        // a bit of left padding like the screenshot
        titleSpacing: 16,
        // Ensure status bar icons are light and bar color matches
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Color(0xFF8C6EAF),
          statusBarIconBrightness: Brightness.light, // Android
          statusBarBrightness: Brightness.dark,      // iOS
        ),
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
      scaffoldMessengerKey: AppMessenger.key, // keep your global messenger

      // Gentle clamp for system text scaling + wrap with global NetworkGate
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final scaler = media.textScaler.clamp(minScaleFactor: 0.90, maxScaleFactor: 1.15);
        final wrapped = NetworkGate(child: (child ?? const SizedBox.shrink()));
        return MediaQuery(data: media.copyWith(textScaler: scaler), child: wrapped);
      },

      // ✅ IMPORTANT: Start at AuthGuard (from your second code)
      // It will send users to:
      //  - LoginPage (no token)
      //  - Admin dashboard (admin role)
      //  - Employee home (employee role)
      home: const AuthGuard(),

      // Optional named routes (still available if used elsewhere)
      routes: {
        '/login': (context) => const LoginPage(),
        '/leave': (context) => const LeavePage(),
        '/add-leave': (context) => const LeaveFormPage(),
        '/landing': (context) => const LandingScreen(),
      },

      // If you prefer to start at a route by platform in some flows, keep this:
      // initialRoute: _initialRouteForPlatform(),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Wrappers for background tracking (kept from your first code)
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
    // If you also want WorkManager backup to start right away, you can:
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
    // If you scheduled WorkManager backup on start, cancel here as needed.
  } catch (e) {
    debugPrint('stopFgTracking error: $e');
  }
}