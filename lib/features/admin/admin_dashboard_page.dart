import 'package:flutter/material.dart';
import 'package:serv_app/config/feature_flags.dart';
import 'package:serv_app/shared/app_theme.dart';
import 'package:serv_app/features/users/login_page.dart';
import 'live_attendance_page.dart';
import 'leave_approval_screen.dart';
import 'employee_management_page.dart';
import 'attendance_report_page.dart';
import 'payroll_admin_page.dart';
import 'employee_onboarding_form_page.dart';
import 'others_page.dart';
import 'settings_page.dart'; // ✅ Added
import 'admin_notifications_page.dart';
import 'admin_theme.dart';
import 'package:serv_app/services/notification_service.dart';
import 'package:serv_app/models/company_profile.dart';
import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/services/feature_service.dart';
import 'package:serv_app/widgets/feature_gate.dart';

class _NavEntry {
  final IconData icon;
  final String title;
  final int pageIndex;
  final List<String> features; // empty => always visible

  /// When true the entry is always visible to tenant admins even if none
  /// of [features] are enabled — the page itself filters its items
  /// (Settings contains unkeyed subpages like Profile). Has no effect in
  /// HR mode: visibility is still driven purely by the approved set.
  final bool adminAlways;

  const _NavEntry(this.icon, this.title, this.pageIndex,
      [this.features = const [], this.adminAlways = false]);
}

class AdminDashboard extends StatefulWidget {
  final CompanyProfile companyProfile;

  /// HR mode: when non-null, the dashboard renders ONLY the modules whose
  /// feature keys are in this set. The set comes from
  /// GET /api/hr/features/approved (`users/<hrUserId>.approvedFeatures` +
  /// dependency closure) — never from company-level enabledFeatures.
  /// null => normal admin behaviour (tenant entitlements via FeatureAccess).
  /// An empty set means "nothing approved yet" — it never falls back to
  /// the full admin module list.
  final Set<String>? restrictToFeatures;

  const AdminDashboard({
    super.key,
    required this.companyProfile,
    this.restrictToFeatures,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    // HR mode: land on the first approved module instead of index 0,
    // which may not be approved. Admin behaviour is unchanged.
    if (widget.restrictToFeatures != null) {
      final vis = _visibleEntries;
      if (vis.isNotEmpty && !vis.any((e) => e.pageIndex == selectedIndex)) {
        selectedIndex = vis.first.pageIndex;
      }
    }
    _refreshUnreadCount();
  }

  Future<void> _refreshUnreadCount() async {
    final count = await NotificationService.fetchUnreadCount();
    if (!mounted) return;
    setState(() => _unreadNotifications = count);
  }

  // Drawer entries mapped to tenant feature keys. Entries with an empty
  // feature list are always visible; others show only when the company
  // has the feature enabled (legacy companies => all enabled).
  static const List<_NavEntry> _navEntries = [
    _NavEntry(Icons.check_circle, "Live Attendance", 0, [FeatureAccess.attendance]),
    _NavEntry(Icons.calendar_today, "Request and Leave Approvals", 1, [FeatureAccess.leave]),
    _NavEntry(Icons.group, "Employee Management", 2, [FeatureAccess.employees]),
    _NavEntry(Icons.bar_chart, "Attendance Reports", 3, [FeatureAccess.reports]),
    // "Payroll Management" (pageIndex 4) is temporarily hidden from the
    // drawer — re-enable by restoring this entry. The page and its
    // feature gate remain in _pageFeatures/_buildPageContent.
    _NavEntry(Icons.person_add_alt_1, "Employee Onboarding", 5, [FeatureAccess.onboarding]),
    _NavEntry(Icons.chat, "Others", 6, [
      FeatureAccess.tasks,
      FeatureAccess.rewards,
      FeatureAccess.feedback,
      FeatureAccess.events,
    ]),
    // Settings carries the features of its gated subpages (Workdays &
    // Shift, Leave Holiday, Office Location, Reason Master) so HR sees
    // it only when an approved feature maps to a Settings item. Admin
    // keeps it always visible — Profile has no feature key.
    _NavEntry(Icons.settings, "Settings", 7,
        [FeatureAccess.attendance, FeatureAccess.leave], true),
  ];

  /// Whether a module is visible/usable for the current viewer.
  /// Admin: tenant entitlements (features.isEmpty => always visible).
  /// HR (restrictToFeatures set): only keys inside the approved set;
  /// entries without feature keys are hidden.
  bool _isAllowed(List<String> features, {bool adminAlways = false}) {
    final restrict = widget.restrictToFeatures;
    if (restrict == null) {
      return adminAlways ||
          features.isEmpty ||
          FeatureAccess.hasAny(features);
    }
    return features.isNotEmpty && features.any(restrict.contains);
  }

  List<_NavEntry> get _visibleEntries =>
      _navEntries.where((e) => _isAllowed(e.features, adminAlways: e.adminAlways)).toList();

  static const List<List<String>> _pageFeatures = [
    [FeatureAccess.attendance],
    [FeatureAccess.leave],
    [FeatureAccess.employees],
    [FeatureAccess.reports],
    [FeatureAccess.payroll],
    [FeatureAccess.onboarding],
    [
      FeatureAccess.tasks,
      FeatureAccess.rewards,
      FeatureAccess.feedback,
      FeatureAccess.events,
    ],
    // index 7 = Settings: gated by the features its subpages need.
    [FeatureAccess.attendance, FeatureAccess.leave],
    // index 8 = former HR Users entry — removed from navigation; the
    // unkeyed feature list below is kept so the index stays aligned.
    <String>[],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Title reflects the signed-in user's display role: "Admin
        // Dashboard" for tenant admins, "HR Dashboard" for the
        // HR-labelled accounts created via Company Admin → HR Management
        // (backend authorization role remains 'admin').
        title: Text("${CompanyData.roleLabel} Dashboard"),
        backgroundColor: kAdminAppBarColor,
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: Badge(
              isLabelVisible: _unreadNotifications > 0,
              label: Text('$_unreadNotifications'),
              child: const Icon(Icons.notifications_none),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminNotificationsPage(),
                ),
              ).then((_) => _refreshUnreadCount());
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text("Logout"),
                  ],
                ),
                onTap: () {
                  Future.delayed(Duration.zero, () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginPage(),
                      ),
                    );
                  });
                },
              ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            _buildDrawerHeader(),
            ..._visibleEntries.map(
              (e) => _buildDrawerItem(e.icon, e.title, e.pageIndex),
            ),
          ],
        ),
      ),
      body: _buildPageContent(),
    );
  }

  Widget _buildDrawerHeader() {
    return UserAccountsDrawerHeader(
      decoration: const BoxDecoration(color: kAdminAppBarColor),
      accountName: Text(widget.companyProfile.name),
      accountEmail:
          Text("${CompanyData.roleLabel}: ${widget.companyProfile.adminName}"),
      currentAccountPicture: widget.companyProfile.hasLogo
          ? CircleAvatar(
              backgroundImage: NetworkImage(widget.companyProfile.logoUrl!),
            )
          : CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                widget.companyProfile.initials,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(
        icon,
        color: selectedIndex == index ? Colors.deepPurple : Colors.black54,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight:
              selectedIndex == index ? FontWeight.bold : FontWeight.normal,
          color: selectedIndex == index ? Colors.deepPurple : Colors.black87,
        ),
      ),
      selected: selectedIndex == index,
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildPageContent() {
    final required = _pageFeatures[selectedIndex];
    final adminAlways = _navEntries
        .where((e) => e.pageIndex == selectedIndex)
        .map((e) => e.adminAlways)
        .fold(false, (a, b) => a || b);
    if (!_isAllowed(required, adminAlways: adminAlways)) {
      // HR with an empty approved set gets an explicit empty state —
      // never a fallback to the full admin module list.
      if (widget.restrictToFeatures?.isEmpty == true) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No features have been approved yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ),
        );
      }
      return const FeatureAccessDenied();
    }

    switch (selectedIndex) {
      case 0:
        return LiveAttendancePage(companyProfile: widget.companyProfile);
      case 1:
        return const LeaveApprovalsScreen();
      case 2:
        return EmployeeListScreen(
            allowedFeatures: widget.restrictToFeatures);
      case 3:
        return const AttendanceReportScreen(
          initialFilter: '',
        );
      case 4:
        return PayrollAdminPage(
            allowedFeatures: widget.restrictToFeatures);
      case 5:
        return const EmployeeOnboardingFormPage();
      case 6:
        // HR mode: filter Others items by the approved set, not the
        // company's enabledFeatures.
        return OthersPage(allowedFeatures: widget.restrictToFeatures);
      case 7:
        // HR mode: restrictToFeatures carries the approved set so the
        // page can filter items by it instead of company entitlements.
        return SettingsPage(allowedFeatures: widget.restrictToFeatures);
      default:
        return const Center(child: Text("Unknown page"));
    }
  }
}
