// lib/features/platform_admin/platform_admin_shell.dart

import 'package:flutter/material.dart';

import 'platform_admin_audit_page.dart';
import 'platform_admin_dashboard_page.dart';
import 'platform_admin_registrations_page.dart';
import 'platform_admin_session.dart';

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
  static const _destinations = <(IconData, String, String)>[
    (Icons.dashboard_outlined, 'Dashboard', '/platform-admin/dashboard'),
    (
      Icons.domain_verification_outlined,
      'Organization Registrations',
      '/platform-admin/registrations',
    ),
    (Icons.history_outlined, 'Audit / Review History', '/platform-admin/audit'),
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

  Future<void> _logout() async {
    await PlatformAdminSession.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/platform-admin/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (_selected) {
      1 => const PlatformAdminRegistrationsPage(),
      2 => const PlatformAdminAuditPage(),
      _ => const PlatformAdminDashboardPage(),
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF4F2FA),
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: const Color(0xFF2E2450),
            selectedIndex: _selected,
            onDestinationSelected: (i) {
              if (i == _selected) return;
              setState(() => _selected = i);
              Navigator.of(context).pushReplacementNamed(_destinations[i].$3);
            },
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: const IconThemeData(color: Colors.white),
            unselectedIconTheme:
                const IconThemeData(color: Color(0xFFB8AED8)),
            selectedLabelTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelTextStyle: const TextStyle(
              color: Color(0xFFB8AED8),
              fontSize: 12,
            ),
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 30,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Platform Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(
                      Icons.logout,
                      color: Color(0xFFB8AED8),
                      size: 18,
                    ),
                    label: const Text(
                      'Logout',
                      style: TextStyle(color: Color(0xFFB8AED8)),
                    ),
                  ),
                ),
              ),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.$1),
                  label: Text(
                    d.$2,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
          const VerticalDivider(width: 1, color: Color(0xFFE0DAF0)),
          Expanded(child: body),
        ],
      ),
    );
  }
}
