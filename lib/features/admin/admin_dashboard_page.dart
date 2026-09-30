import 'package:flutter/material.dart';
import 'package:serv_app/features/users/login_page.dart';
import 'live_attendance_page.dart';
import 'leave_approval_screen.dart';
import 'employee_management_page.dart';
import 'attendance_report_page.dart';
import 'payroll_admin_page.dart';
import 'employee_onboarding_form_page.dart';
import 'others_page.dart';
import 'settings_page.dart'; // ✅ Added
import 'package:serv_app/models/company_profile.dart';
import 'package:serv_app/models/organization_context.dart';
import 'package:serv_app/services/organization_context_service.dart';
import 'admin_feature_gate.dart';

/// One drawer/module entry. `feature` == null → universal (always shown);
/// otherwise the entry exists only when the organization's
/// enabledFeatures contains it.
class _NavEntry {
  final String title;
  final IconData icon;
  final String? feature;

  /// Any-of feature list — the entry is visible when at least one of these
  /// is enabled. Used for shared surfaces like Live Attendance, which is
  /// reachable with `attendance` OR `location_tracking`.
  final List<String>? anyOfFeatures;
  final Widget Function() page;
  const _NavEntry({
    required this.title,
    required this.icon,
    required this.page,
    this.feature,
    this.anyOfFeatures,
  });
}

class AdminDashboard extends StatefulWidget {
  final CompanyProfile companyProfile;

  /// Server-authoritative org context (companyId/code/enabledFeatures).
  /// When null the dashboard loads it itself via
  /// [OrganizationContextService] — every existing construction site keeps
  /// working unchanged.
  final OrganizationContext? organization;

  const AdminDashboard({
    super.key,
    required this.companyProfile,
    this.organization,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;
  OrganizationContext? _org;

  /// Ordered module menu — features map 1:1 to CANONICAL_FEATURES on the
  /// backend. Home/Settings/Others/Logout are universal, never gated.
  late final List<_NavEntry> _allEntries = [
    _NavEntry(
      title: "Home",
      icon: Icons.home_outlined,
      page: () => _AdminHomeTab(
        org: _org,
        companyProfile: widget.companyProfile,
      ),
    ),
    _NavEntry(
      title: "Live Attendance",
      icon: Icons.check_circle,
      // Shared capability: `attendance` OR `location_tracking`. The
      // `attendance` feature alone still unlocks the full Attendance
      // module (reports etc. stay attendance-gated below).
      anyOfFeatures: const ['attendance', 'location_tracking'],
      page: () => FeatureGate.anyOf(
        features: const ['attendance', 'location_tracking'],
        child: LiveAttendancePage(companyProfile: widget.companyProfile),
      ),
    ),
    _NavEntry(
      title: "Request and Leave Approvals",
      icon: Icons.calendar_today,
      feature: 'leave_management',
      page: () => const FeatureGate(
        feature: 'leave_management',
        child: LeaveApprovalsScreen(),
      ),
    ),
    _NavEntry(
      title: "Employee Management",
      icon: Icons.group,
      feature: 'employee_master',
      page: () => const FeatureGate(
        feature: 'employee_master',
        child: EmployeeListScreen(),
      ),
    ),
    _NavEntry(
      title: "Attendance Reports",
      icon: Icons.bar_chart,
      feature: 'attendance',
      page: () => const FeatureGate(
        feature: 'attendance',
        child: AttendanceReportScreen(initialFilter: ''),
      ),
    ),
    _NavEntry(
      title: "Payroll Management",
      icon: Icons.payments_outlined,
      feature: 'payroll',
      page: () => const FeatureGate(
        feature: 'payroll',
        child: PayrollAdminPage(),
      ),
    ),
    _NavEntry(
      title: "Employee Onboarding",
      icon: Icons.person_add_alt_1,
      feature: 'employee_master',
      page: () => const FeatureGate(
        feature: 'employee_master',
        child: EmployeeOnboardingFormPage(),
      ),
    ),
    _NavEntry(
      title: "Others",
      icon: Icons.chat,
      page: () => const OthersPage(),
    ),
    _NavEntry(
      title: "Settings",
      icon: Icons.settings,
      page: () => const SettingsPage(),
    ),
  ];

  /// Menu actually shown — gated by the loaded org's enabledFeatures.
  /// When no context is loaded (legacy/unknown session) everything stays
  /// visible; backend requireFeature still enforces authorization.
  List<_NavEntry> get _entries {
    final org = _org;
    if (org == null) return _allEntries;
    return _allEntries
        .where(
          (e) => e.feature != null
              ? org.isFeatureEnabled(e.feature!)
              : e.anyOfFeatures != null
                  ? org.isAnyFeatureEnabled(e.anyOfFeatures!)
                  : true,
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _org = widget.organization ?? OrganizationContext.current;
    if (_org == null) _loadOrgContext();
  }

  Future<void> _loadOrgContext() async {
    final loaded = await OrganizationContextService.load();
    if (!mounted || loaded == null) return;
    setState(() => _org = loaded);
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    if (selectedIndex >= entries.length) selectedIndex = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _org?.organizationName.isNotEmpty == true
              ? _org!.organizationName
              : "Admin Dashboard",
        ),
        backgroundColor: const Color(0xFF6A1B9A),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.notifications_none),
          //   onPressed: () {},
          // ),
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
            if (_org != null && _org!.companyId.isNotEmpty)
              ListTile(
                dense: true,
                title: Text("Org ID: ${_org!.companyId}"),
              ),
            for (var i = 0; i < entries.length; i++)
              _buildDrawerItem(entries[i], i),
          ],
        ),
      ),
      body: entries[selectedIndex].page(),
    );
  }

  Widget _buildDrawerHeader() {
    final org = _org;
    return UserAccountsDrawerHeader(
      decoration: const BoxDecoration(color: Color(0xFF6A1B9A)),
      accountName: Text(
        org?.organizationName.isNotEmpty == true
            ? org!.organizationName
            : widget.companyProfile.name,
      ),
      accountEmail: Text(
        org != null && org.organizationCode.isNotEmpty
            ? "${org.organizationCode}  •  Admin: ${widget.companyProfile.adminName}"
            : "Admin: ${widget.companyProfile.adminName}",
      ),
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

  Widget _buildDrawerItem(_NavEntry entry, int index) {
    return ListTile(
      leading: Icon(
        entry.icon,
        color: selectedIndex == index ? Colors.deepPurple : Colors.black54,
      ),
      title: Text(
        entry.title,
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
}

/// Generic Admin home — organization identity + enabled modules.
/// Deliberately loads NO module data: an org without the attendance
/// feature must never trigger GET /attendance/live on open.
class _AdminHomeTab extends StatelessWidget {
  final OrganizationContext? org;
  final CompanyProfile companyProfile;

  const _AdminHomeTab({required this.org, required this.companyProfile});

  static const _featureLabels = {
    'employee_master': 'Employee Master',
    'organization_structure': 'Organization Structure',
    'users_and_roles': 'Users and Roles',
    'attendance': 'Attendance',
    'location_tracking': 'Location Tracking',
    'tasks': 'Tasks',
    'shifts': 'Shifts',
    'leave_management': 'Leave Management',
    'payroll': 'Payroll',
    'recruitment': 'Recruitment',
    'performance': 'Performance',
    'reporting': 'Reporting',
  };

  @override
  Widget build(BuildContext context) {
    final orgName = org?.organizationName.isNotEmpty == true
        ? org!.organizationName
        : companyProfile.name;
    final features = org?.enabledFeatures;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Organization',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _row('Organization Name', orgName.isEmpty ? '—' : orgName),
                _row(
                  'Organization Code',
                  org?.organizationCode.isNotEmpty == true
                      ? org!.organizationCode
                      : '—',
                ),
                _row(
                  'Organization ID',
                  org?.companyId.isNotEmpty == true ? org!.companyId : '—',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enabled Modules',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (features == null)
                  const Text('All modules')
                else if (features.isEmpty)
                  const Text('No modules enabled')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: features
                        .map(
                          (f) => Chip(
                            label: Text(_featureLabels[f] ?? f),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
