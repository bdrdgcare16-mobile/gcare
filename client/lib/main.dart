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
      iconTheme: const IconThemeData(color: Color(0xFF0F3D3E)),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 14, color: Colors.black),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF8C6EAF),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 2,
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
