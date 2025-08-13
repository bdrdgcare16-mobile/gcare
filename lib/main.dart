import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'services/user_session.dart';
import 'providers/realtime_provider.dart';
import 'providers/reports_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Starting Nishali App...');
  
  try {
    print('📱 Loading user session...');
    await UserSession.instance.loadUserSession();
    print('✅ User session loaded successfully');
  } catch (e) {
    print('❌ Error loading user session: $e');
  }
  
  print('🎯 Running MyApp...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('🏗️ Building MyApp...');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RealtimeProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
      ],
      child: MaterialApp(
        title: 'Nishali - Employee Management',
        home: const LoginScreen(),
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFE3F2FD),
        ),
      ),
    );
  }
}
