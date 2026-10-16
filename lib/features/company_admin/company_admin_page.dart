import 'package:flutter/material.dart';
import 'package:serv_app/features/admin/hr_users_page.dart';
import 'package:serv_app/features/onboarding/onboarding_review_view.dart';
import 'package:serv_app/utils/logout.dart';

const Color _kPurple = Color(0xFF8C6EAF);

/// Company Admin dashboard (role 'company_admin').
///
/// Two sections only:
///   - HR Management   — the existing HR-user creation/management UI.
///   - Onboarding Requests — the shared employee-onboarding review UI;
///     the backend scopes list/detail/status to the admin's company.
///
/// Company Admins must NOT reach the normal SERV Admin dashboard, HR's
/// policy/feature-selection flow, or any Platform Admin surface.
class CompanyAdminPage extends StatefulWidget {
  const CompanyAdminPage({super.key});

  @override
  State<CompanyAdminPage> createState() => _CompanyAdminPageState();
}

class _CompanyAdminPageState extends State<CompanyAdminPage> {
  int _section = 0;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;

    final body = _section == 0
        ? const HrUsersPage()
        : const OnboardingReviewView();

    final content = Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        title: Text(_section == 0 ? 'HR Management' : 'Onboarding Requests'),
        backgroundColor: _kPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _section,
              onDestinationSelected: (i) => setState(() => _section = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.group_outlined),
                  label: 'HR Management',
                ),
                NavigationDestination(
                  icon: Icon(Icons.assignment_turned_in_outlined),
                  label: 'Onboarding',
                ),
              ],
            ),
    );

    if (!isWide) return content;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _section,
            onDestinationSelected: (i) => setState(() => _section = i),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.group_outlined),
                label: Text('HR Management'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assignment_turned_in_outlined),
                label: Text('Onboarding'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: content),
        ],
      ),
    );
  }
}
