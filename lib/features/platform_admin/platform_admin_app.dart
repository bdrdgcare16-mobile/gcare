// lib/features/platform_admin/platform_admin_app.dart

import 'package:flutter/material.dart';

import 'package:serv_app/features/supderadmin/platform_admin_dashboard_page.dart'
    as superadmin;
import 'package:serv_app/features/supderadmin/super_admin_companies_page.dart';
import 'package:serv_app/features/supderadmin/platform_admin_shell.dart'
    as superadmin_shell;

import 'hr_feature_requests_page.dart';
import 'platform_admin_login_page.dart';
import 'platform_admin_registration_detail_page.dart';
import 'platform_admin_registrations_page.dart';
import 'platform_admin_session.dart';

/// Browser-based Platform Admin portal app.
///
/// Routes:
///   /platform-admin/login
///   /platform-admin/dashboard
///   /platform-admin/companies
///   /platform-admin/registrations
///   /platform-admin/registrations/:id
///   /platform-admin/audit          → redirects to Dashboard (section hidden)
///
/// The section bodies come from the supderadmin implementation — the
/// working Platform Admin UI that talks to this backend's
/// /api/platform/* endpoints (platform_admin). Employee onboarding
/// review belongs to Company Admin and no longer appears here.
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
        page = const superadmin.PlatformAdminDashboardPage();
        break;
      case '/platform-admin/companies':
        page = const SuperAdminCompaniesPage();
        break;
      case '/platform-admin/registrations':
        page = const superadmin_shell.PlatformAdminShell(
          selected: superadmin_shell.PlatformAdminSection.registrations,
          title: 'Organization Registrations',
          body: PlatformAdminRegistrationsPage(),
        );
        break;
      case '/platform-admin/hr-requests':
        page = const PlatformAdminHrRequestsPage();
        break;
      case '/platform-admin/audit':
        // Audit section is hidden from the sidebar — deep links redirect
        // safely to the Dashboard. Page code is preserved for re-enable.
        page = const superadmin.PlatformAdminDashboardPage();
        break;
      default:
        if (path.startsWith('/platform-admin/registrations/')) {
          final id = path.substring('/platform-admin/registrations/'.length);
          page = id.isEmpty || id.contains('/')
              ? const superadmin_shell.PlatformAdminShell(
                  selected: superadmin_shell.PlatformAdminSection.registrations,
                  title: 'Organization Registrations',
                  body: PlatformAdminRegistrationsPage(),
                )
              : PlatformAdminRegistrationDetailPage(registrationId: id);
        } else {
          page = PlatformAdminSession.isSignedIn
              ? const superadmin.PlatformAdminDashboardPage()
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
        scaffoldBackgroundColor: const Color(0xFFF7F3FC),
        cardColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6F42C1),
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
