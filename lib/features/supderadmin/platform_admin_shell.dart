import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:serv_app/html_stub.dart'
    if (dart.library.html) 'package:serv_app/html_web.dart' as html;

import 'package:serv_app/features/users/login_page.dart';
import 'package:serv_app/features/platform_admin/platform_admin_login_page.dart';
import 'package:serv_app/features/platform_admin/platform_admin_session.dart';
import 'package:serv_app/utils/logout.dart';

import 'package:serv_app/features/platform_admin/hr_feature_requests_page.dart';
import 'package:serv_app/features/platform_admin/pa_ui.dart';
import 'package:serv_app/features/platform_admin/platform_admin_registrations_page.dart';

import 'platform_admin_dashboard_page.dart';
import 'platform_admin_audit_page.dart';
import 'super_admin_companies_page.dart';

enum PlatformAdminSection {
  dashboard,
  companies,
  registrations,
  hrRequests,
  audit,
}

/// Shared Platform Admin (platform_admin) shell: persistent light sidebar
/// on wide screens, Drawer on narrow screens. Guards access to the
/// platform admin roles only.
class PlatformAdminShell extends StatefulWidget {
  final PlatformAdminSection selected;
  final String title;
  final Widget body;
  final Widget? floatingActionButton;

  const PlatformAdminShell({
    super.key,
    required this.selected,
    required this.title,
    required this.body,
    this.floatingActionButton,
  });

  /// Push a section's page, replacing the current route (sidebar-style nav).
  static void navigate(BuildContext context, PlatformAdminSection section) {
    final Widget page;
    switch (section) {
      case PlatformAdminSection.dashboard:
        page = const PlatformAdminDashboardPage();
        break;
      case PlatformAdminSection.companies:
        page = const SuperAdminCompaniesPage();
        break;
      case PlatformAdminSection.registrations:
        // 'Organization Registrations' = org-registration applications
        // (/api/platform/registrations). Employee onboarding review moved
        // to Company Admin — the old onboarding page is no longer routed.
        page = const PlatformAdminShell(
          selected: PlatformAdminSection.registrations,
          title: 'Organization Registrations',
          body: PlatformAdminRegistrationsPage(),
        );
        break;
      case PlatformAdminSection.hrRequests:
        page = const PlatformAdminHrRequestsPage();
        break;
      case PlatformAdminSection.audit:
        page = const PlatformAdminAuditPage();
        break;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  State<PlatformAdminShell> createState() => _PlatformAdminShellState();
}

class _PlatformAdminShellState extends State<PlatformAdminShell> {
  static const _sections = [
    (PlatformAdminSection.dashboard, 'Dashboard', Icons.dashboard_outlined),
    (PlatformAdminSection.companies, 'Companies', Icons.business_outlined),
    (
      PlatformAdminSection.registrations,
      'Organization Registrations',
      Icons.domain_verification_outlined,
    ),
    (
      PlatformAdminSection.hrRequests,
      'HR Feature Requests',
      Icons.playlist_add_check_circle_outlined,
    ),
    // 'Audit / Review History' (PlatformAdminSection.audit) hidden from the
    // sidebar — page + route kept for easy re-enable.
  ];

  @override
  void initState() {
    super.initState();
    _guardRole();
  }

  /// In the dedicated Platform Admin web app the session is the portal
  /// session (serv_pa_* keys) — sign out returns to the portal login.
  /// In the main SERV app a super_admin signed in through the normal
  /// login, so the shared logout flow is kept there.
  Future<void> _handleLogout() async {
    if (PlatformAdminSession.isSignedIn) {
      await PlatformAdminSession.signOut();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PlatformAdminLoginPage()),
        (_) => false,
      );
      return;
    }
    await logout(context);
  }

  Future<void> _guardRole() async {
    final sp = await SharedPreferences.getInstance();
    var role = sp.getString('role') ?? '';
    if (role.isEmpty) {
      try {
        role = html.window.localStorage['role'] ?? '';
      } catch (_) {}
    }
    if (role != 'super_admin' && role != 'platform_admin' && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }

  Widget _buildBrand() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [PaColors.primary, PaColors.deep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SERV',
                  style: TextStyle(
                    color: PaColors.deep,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    height: 1.1,
                  ),
                ),
                Text(
                  'Platform Admin',
                  style: TextStyle(
                    color: PaColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    PlatformAdminSection section,
    String label,
    IconData icon,
  ) {
    final isSelected = widget.selected == section;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: PaHover(
        onTap: isSelected
            ? null
            : () {
                if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                  Navigator.of(context).pop();
                }
                PlatformAdminShell.navigate(context, section);
              },
        builder: (context, hovering) {
          final highlighted = isSelected || hovering;
          return AnimatedContainer(
            duration: kPaAnim,
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? PaColors.soft
                  : hovering
                      ? PaColors.soft.withValues(alpha: 0.55)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: kPaAnim,
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isSelected ? PaColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  icon,
                  size: 19,
                  color: isSelected
                      ? PaColors.primary
                      : highlighted
                          ? PaColors.accent
                          : PaColors.muted,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? PaColors.deep : PaColors.muted,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNav() {
    return Column(
      children: [
        _buildBrand(),
        const Divider(height: 1, color: PaColors.border),
        const SizedBox(height: 10),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              for (final (section, label, icon) in _sections)
                _navItem(section, label, icon),
            ],
          ),
        ),
        const Divider(height: 1, color: PaColors.border),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: PaHover(
            onTap: _handleLogout,
            builder: (context, hovering) => AnimatedContainer(
              duration: kPaAnim,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: hovering
                    ? PaColors.danger.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(
                    Icons.logout_rounded,
                    size: 19,
                    color: hovering ? PaColors.danger : PaColors.muted,
                  ),
                  const SizedBox(width: 11),
                  Text(
                    'Logout',
                    style: TextStyle(
                      color: hovering ? PaColors.danger : PaColors.muted,
                      fontWeight: FontWeight.w500,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Slim light top bar — replaces the old heavy purple AppBar.
    PreferredSizeWidget topBar({bool showMenu = false}) {
      return AppBar(
        automaticallyImplyLeading: showMenu,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: PaColors.text,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: PaColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: PaColors.border),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Scaffold(
            backgroundColor: PaColors.bg,
            body: Row(
              children: [
                Material(
                  color: Colors.white,
                  child: Container(
                    width: 236,
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: PaColors.border),
                      ),
                    ),
                    child: SafeArea(child: _buildNav()),
                  ),
                ),
                Expanded(
                  child: Scaffold(
                    backgroundColor: PaColors.bg,
                    appBar: topBar(),
                    floatingActionButton: widget.floatingActionButton,
                    body: widget.body,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: PaColors.bg,
          appBar: topBar(showMenu: true),
          drawer: Drawer(
            backgroundColor: Colors.white,
            child: SafeArea(child: _buildNav()),
          ),
          floatingActionButton: widget.floatingActionButton,
          body: widget.body,
        );
      },
    );
  }
}
