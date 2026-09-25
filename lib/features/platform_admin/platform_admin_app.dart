// lib/features/platform_admin/platform_admin_app.dart

import 'package:flutter/material.dart';

import 'platform_admin_login_page.dart';
import 'platform_admin_registration_detail_page.dart';
import 'platform_admin_session.dart';
import 'platform_admin_shell.dart';

/// Browser-based Platform Admin portal app (Milestone 3D-B).
///
/// Routes:
///   /platform-admin/login
///   /platform-admin/dashboard
///   /platform-admin/registrations
///   /platform-admin/registrations/:id
///   /platform-admin/audit
///
/// Unauthenticated visitors (no platform_admin session) are redirected to
/// the login route. Server-side roleMiddleware(['platform_admin']) is the
/// real enforcement — route guards are UX only.
class PlatformAdminApp extends StatelessWidget {
  const PlatformAdminApp({super.key});

  Route<dynamic> _route(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');
    final path = uri.path;

    Widget page;
    switch (path) {
      case '/platform-admin/login':
        page = const PlatformAdminLoginPage();
        break;
      case '/platform-admin':
      case '/platform-admin/dashboard':
        page = const PlatformAdminShell(selectedIndex: 0);
        break;
      case '/platform-admin/registrations':
        page = const PlatformAdminShell(selectedIndex: 1);
        break;
      case '/platform-admin/audit':
        page = const PlatformAdminShell(selectedIndex: 2);
        break;
      default:
        if (path.startsWith('/platform-admin/registrations/')) {
          final id = path.substring('/platform-admin/registrations/'.length);
          page = id.isEmpty || id.contains('/')
              ? const PlatformAdminShell(selectedIndex: 1)
              : PlatformAdminRegistrationDetailPage(registrationId: id);
        } else {
          page = PlatformAdminSession.isSignedIn
              ? const PlatformAdminShell(selectedIndex: 0)
              : const PlatformAdminLoginPage();
        }
    }

    // Protected routes require a portal session.
    final isProtected =
        path.startsWith('/platform-admin') && path != '/platform-admin/login';
    if (isProtected && !PlatformAdminSession.restore()) {
      page = const PlatformAdminLoginPage();
    }

    return MaterialPageRoute(settings: settings, builder: (_) => page);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SERV Platform Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF4F2FA),
        cardColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4B3B73),
        ),
        useMaterial3: true,
      ),
      initialRoute: PlatformAdminSession.isSignedIn
          ? '/platform-admin/dashboard'
          : '/platform-admin/login',
      onGenerateRoute: _route,
    );
  }
}
