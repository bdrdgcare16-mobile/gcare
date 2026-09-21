// lib/features/onboarding/screens/select_user_type_page.dart

import 'package:flutter/material.dart';
import 'package:serv_app/features/users/login_page.dart';
import '../services/onboarding_storage_service.dart';
import '../registration/guards/registration_resume_guard.dart';
import 'employee_login_page.dart';

enum _UserType { employee, admin, organization }

/// Third screen of the initial install onboarding flow.
///
/// The user selects how they want to use SERV. The selection is recorded and
/// the onboarding flag is marked completed here before routing to the
/// appropriate existing entry point.
class SelectUserTypePage extends StatefulWidget {
  const SelectUserTypePage({super.key});

  @override
  State<SelectUserTypePage> createState() => _SelectUserTypePageState();
}

class _SelectUserTypePageState extends State<SelectUserTypePage> {
  _UserType? _selected;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('How would you like to use SERV?'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose the option that describes you. You can change this later '
                'after signing in.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF555555),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _UserTypeCard(
                      title: 'Employee',
                      description:
                          'Access attendance, leave, tasks, documents and other '
                          'employee services.',
                      icon: Icons.person_outline,
                      selected: _selected == _UserType.employee,
                      onTap: () => setState(() => _selected = _UserType.employee),
                    ),
                    const SizedBox(height: 14),
                    _UserTypeCard(
                      title: 'Existing HR / Admin',
                      description:
                          'Manage employees and organization functions based on '
                          'your assigned role.',
                      icon: Icons.admin_panel_settings_outlined,
                      selected: _selected == _UserType.admin,
                      onTap: () => setState(() => _selected = _UserType.admin),
                    ),
                    const SizedBox(height: 14),
                    _UserTypeCard(
                      title: 'Register Organization',
                      description:
                          'Register a new organization and request SERV modules.',
                      icon: Icons.business_outlined,
                      selected: _selected == _UserType.organization,
                      onTap: () =>
                          setState(() => _selected = _UserType.organization),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _selected != null && !_busy ? _onContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF655193),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFF655193).withValues(alpha: 0.35),
                    disabledForegroundColor:
                        Colors.white.withValues(alpha: 0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onContinue() async {
    if (_selected == null || _busy) return;

    setState(() => _busy = true);

    final userType = _mapUserType(_selected!);

    // Mark onboarding completed after Welcome → Policies → User Type.
    await OnboardingStorageService.instance.markInitialOnboardingCompleted(
      userType: userType,
    );

    if (!mounted) return;

    switch (_selected!) {
      case _UserType.employee:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const EmployeeLoginPage()),
        );
        break;
      case _UserType.admin:
        // Existing HR/Admin uses the shared LoginPage.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
        break;
      case _UserType.organization:
        // RegistrationResumeGuard resumes a saved draft or starts step 1.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const RegistrationResumeGuard(),
          ),
        );
        break;
    }
  }

  String _mapUserType(_UserType type) {
    switch (type) {
      case _UserType.employee:
        return OnboardingUserType.employee;
      case _UserType.admin:
        return OnboardingUserType.hrAdmin;
      case _UserType.organization:
        return OnboardingUserType.registerOrganization;
    }
  }
}

class _UserTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _UserTypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0EBF8) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF655193)
                : const Color(0xFFE0E0E0),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF655193).withValues(alpha: 0.12)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: selected ? const Color(0xFF655193) : const Color(0xFF666666),
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F3D3E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF555555),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF655193),
              )
            else
              const Icon(
                Icons.radio_button_unchecked,
                color: Color(0xFFBDBDBD),
              ),
          ],
        ),
      ),
    );
  }
}
