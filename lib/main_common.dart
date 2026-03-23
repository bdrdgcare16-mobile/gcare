import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:workmanager/workmanager.dart';
import 'package:serv_app/features/auth/auth_guard.dart';
import 'core/app_messenger.dart';
import 'package:serv_app/features/users/login_page.dart';
import 'package:serv_app/features/admin/leave_page.dart';
import 'package:serv_app/features/admin/leave_form_page.dart';
import 'package:serv_app/features/users/landing_screen.dart';
import 'package:serv_app/features/users/background_tasks.dart';
import 'package:serv_app/services/connectivity_service.dart';
import 'package:serv_app/widgets/network_gate.dart';

bool get _isAndroid => !kIsWeb && Platform.isAndroid;

Future<void> startApp({
  required FirebaseOptions firebaseOptions,
  required String environmentName,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (_isAndroid) {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );
    }
  } catch (_) {}

  try {
    final app = await Firebase.initializeApp(
      options: firebaseOptions,
    );
    debugPrint('Firebase initialized for [$environmentName]: ${app.options.projectId}');
    debugPrint('Using API key for [$environmentName]: ${app.options.apiKey}');

    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
        debugPrint('[FirebaseAuth][$environmentName] Anonymous sign-in OK');
        debugPrint('[AUTH][$environmentName] user=${FirebaseAuth.instance.currentUser?.uid}');
      }
    } catch (e) {
      debugPrint('Anonymous sign-in failed [$environmentName]: $e');
    }
  } catch (e) {
    debugPrint('Firebase initialization error [$environmentName]: $e');
  }

  if (_isAndroid) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await initializeBackgroundSystems();
      } catch (e) {
        debugPrint('initializeBackgroundSystems failed [$environmentName]: $e');
      }
    });
  }

  ConnectivityService.I.start();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData myTheme = ThemeData(
      fontFamily: 'Inter',
      scaffoldBackgroundColor: const Color(0xFFF8F6FF),
      cardColor: Colors.white,
      iconTheme: const IconThemeData(
        color: Color(0xFF0F3D3E),
        size: 24,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 14, color: Colors.black),
      ),
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
        toolbarHeight: 64,
        elevation: 2,
        centerTitle: false,
        titleSpacing: 16,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Color(0xFF8C6EAF),
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
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
      scaffoldMessengerKey: AppMessenger.key,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final scaler =
            media.textScaler.clamp(minScaleFactor: 0.90, maxScaleFactor: 1.15);
        final wrapped = NetworkGate(child: child ?? const SizedBox.shrink());
        return MediaQuery(
          data: media.copyWith(textScaler: scaler),
          child: wrapped,
        );
      },
      home: const AuthGuard(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/leave': (context) => const LeavePage(),
        '/add-leave': (context) => const LeaveFormPage(),
        '/landing': (context) => const LandingScreen(),
      },
    );
  }
}

Future<void> initBackgroundService() async {
  if (_isAndroid) {
    await initializeBackgroundSystems();
  }
}

Future<void> startFgTracking({
  required String empid,
  required String token,
}) async {
  if (!_isAndroid) return;
  try {
    await setTrackingIdentity(empid: empid, token: token);
    await startForegroundTracking();
  } catch (e) {
    debugPrint('startFgTracking error: $e');
  }
}

Future<void> stopFgTracking() async {
  if (!_isAndroid) return;
  try {
    await stopForegroundTracking();
  } catch (e) {
    debugPrint('stopFgTracking error: $e');
  }
}