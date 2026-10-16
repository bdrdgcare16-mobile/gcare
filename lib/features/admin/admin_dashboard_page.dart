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

class AdminDashboard extends StatefulWidget {
  final CompanyProfile companyProfile;

  const AdminDashboard({super.key, required this.companyProfile});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _refreshUnreadCount();
  }

  Future<void> _refreshUnreadCount() async {
    final count = await NotificationService.fetchUnreadCount();
    if (!mounted) return;
    setState(() => _unreadNotifications = count);
  }

  List<_AdminDestination> get _destinations => [
        _AdminDestination(
          Icons.check_circle,
          "Live Attendance",
          (profile) => LiveAttendancePage(companyProfile: profile),
        ),
        _AdminDestination(
          Icons.calendar_today,
          "Request and Leave Approvals",
          (_) => const LeaveApprovalsScreen(),
        ),
        _AdminDestination(
          Icons.group,
          "Employee Management",
          (_) => const EmployeeListScreen(),
        ),
        _AdminDestination(
          Icons.bar_chart,
          "Attendance Reports",
          (_) => const AttendanceReportScreen(initialFilter: ''),
        ),
        if (FeatureFlags.showPayrollUI)
          _AdminDestination(
            Icons.payments_outlined,
            "Payroll Management",
            (_) => const PayrollAdminPage(),
          ),
        _AdminDestination(
          Icons.person_add_alt_1,
          "Employee Onboarding",
          (_) => const EmployeeOnboardingFormPage(),
        ),
        _AdminDestination(
          Icons.chat,
          "Others",
          (_) => const OthersPage(),
        ),
        _AdminDestination(
          Icons.settings,
          "Settings",
          (_) => const SettingsPage(), // ✅ Navigate to settings
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
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
            for (int i = 0; i < _destinations.length; i++)
              _buildDrawerItem(
                _destinations[i].icon,
                _destinations[i].title,
                i,
              ),
          ],
        ),
      ),
      body: _destinations[selectedIndex].builder(widget.companyProfile),
    );
  }

  Widget _buildDrawerHeader() {
    return UserAccountsDrawerHeader(
      decoration: const BoxDecoration(color: kAdminAppBarColor),
      accountName: Text(widget.companyProfile.name),
      accountEmail: Text("Admin: ${widget.companyProfile.adminName}"),
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

}

class _AdminDestination {
  final IconData icon;
  final String title;
  final Widget Function(CompanyProfile) builder;

  const _AdminDestination(this.icon, this.title, this.builder);
}
