// lib/features/platform_admin/platform_admin_shell.dart

import 'package:flutter/material.dart';

import 'platform_admin_audit_page.dart';
import 'platform_admin_dashboard_page.dart';
import 'platform_admin_registrations_page.dart';
import 'platform_admin_session.dart';
import 'platform_admin_sidebar.dart';
import 'platform_admin_theme.dart';

/// Browser shell for the Platform Admin portal — a desktop-first
/// NavigationRail layout. Selected destinations swap the body in place;
/// the URL stays on /platform-admin/* via pushReplacementNamed so deep
/// links keep working.
class PlatformAdminShell extends StatefulWidget {
  final int selectedIndex;

  const PlatformAdminShell({super.key, this.selectedIndex = 0});

  @override
  State<PlatformAdminShell> createState() => _PlatformAdminShellState();
}

class _PlatformAdminShellState extends State<PlatformAdminShell> {
  static const _destinations = <AdminNavItem>[
    AdminNavItem(
      icon: Icons.dashboard_outlined,
      label: 'Dashboard',
      route: '/platform-admin/dashboard',
    ),
    AdminNavItem(
      icon: Icons.domain_verification_outlined,
      label: 'Organization Registrations',
      route: '/platform-admin/registrations',
    ),
    AdminNavItem(
      icon: Icons.history_outlined,
      label: 'Audit / Review History',
      route: '/platform-admin/audit',
    ),
  ];

  late int _selected = widget.selectedIndex;

  @override
  void initState() {
    super.initState();
    // Defence-in-depth: server rejects non-platform_admin JWTs, and the
    // router guards too, but never render portal content without session.
    if (!PlatformAdminSession.restore()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/platform-admin/login',
            (route) => false,
          );
        }
      });
    }
  }

  /// Single logout path for the portal: PlatformAdminSession.signOut()
  /// wipes the stored + in-memory session (and best-effort Firebase
  /// sign-out), then every authenticated route is popped and replaced by
  /// the login page so browser Back cannot reopen protected pages.
  Future<void> _logout() async {
    try {
      await PlatformAdminSession.signOut();
    } catch (e) {
      debugPrint('[PlatformAdmin] signOut error: $e');
    }
    if (!mounted) return;
    try {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/platform-admin/login',
        (route) => false,
      );
    } catch (e) {
      debugPrint('[PlatformAdmin] logout navigation failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logout failed — please refresh the page.'),
        ),
      );
    }
  }

  void _select(int i) {
    if (i == _selected) return;
    setState(() => _selected = i);
    Navigator.of(context).pushReplacementNamed(_destinations[i].route);
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (_selected) {
      1 => const PlatformAdminRegistrationsPage(),
      2 => const PlatformAdminAuditPage(),
      _ => const PlatformAdminDashboardPage(),
    };

    return Scaffold(
      backgroundColor: PlatformAdminColors.background,
      body: PlatformAdminBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fixed left gutter = collapsed rail width, so expanding the
            // sidebar never shifts or resizes the page content.
            Row(
              children: [
                const SizedBox(width: AdminSidebar.collapsedWidth),
                Expanded(child: body),
              ],
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: AdminSidebar(
                brandIcon: Icons.admin_panel_settings,
                brandLabel: 'Platform Admin',
                items: _destinations,
                selectedIndex: _selected,
                onSelect: _select,
                footerIcon: Icons.logout,
                footerLabel: 'Logout',
                onFooterTap: _logout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
