// lib/features/onboarding/screens/serv_policies_page.dart

import 'package:flutter/material.dart';
import 'package:serv_app/features/auth/auth_guard.dart';
import '../services/onboarding_storage_service.dart';
import 'select_user_type_page.dart';

/// Policies screen shown during the initial install onboarding or when a
/// returning user must accept a new policy version.
///
/// The user must explicitly accept the displayed policies before continuing.
/// A future policy-version update can force re-acceptance via
/// [OnboardingStorageService.shouldShowPolicyUpdate].
class ServPoliciesPage extends StatefulWidget {
  /// When true, this page was opened for a policy-version update on a
  /// returning user. Accepting the policies returns the user to the existing
  /// auth/session flow instead of the first-install user-type selection.
  final bool isPolicyUpdate;

  const ServPoliciesPage({
    super.key,
    this.isPolicyUpdate = false,
  });

  @override
  State<ServPoliciesPage> createState() => _ServPoliciesPageState();
}

class _ServPoliciesPageState extends State<ServPoliciesPage> {
  bool _agreed = false;

  final List<_PolicySection> _sections = const [
    _PolicySection(
      title: 'Terms of Service',
      body:
          'By using SERV, you agree to use the platform in compliance with '
          'applicable laws and your organization\'s policies. SERV provides '
          'workforce management tools including attendance, tasks, leave and '
          'document services.',
    ),
    _PolicySection(
      title: 'Privacy Policy',
      body:
          'SERV collects and processes information necessary to deliver workforce '
          'services, such as profile, attendance, location and task data. We '
          'handle this information responsibly and in line with data protection '
          'requirements.',
    ),
    _PolicySection(
      title: 'Employee Data Processing Policy',
      body:
          'Employee data is processed only for authorized HR and operational '
          'purposes. Access is role-based and administrators are responsible '
          'for maintaining accurate and lawful employee records.',
    ),
    _PolicySection(
      title: 'Location Data Policy',
      body:
          'Attendance features may collect location data when you check in or '
          'out. Location is used for geofence verification and is only '
          'processed while you are using the attendance features.',
    ),
    _PolicySection(
      title: 'Biometric Data Policy',
      body:
          'If biometric authentication is enabled, your device\'s biometric '
          'hardware is used locally to unlock the app. SERV does not store or '
          'transmit raw biometric data.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('SERV Policies'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Please review the following policies before using SERV.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF555555),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._sections.map((s) => _buildPolicyCard(context, s)),
                  ],
                ),
              ),
            ),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyCard(BuildContext context, _PolicySection section) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F3D3E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            section.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF555555),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _agreed = !_agreed),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                    activeColor: const Color(0xFF655193),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'I have read and agree to the SERV policies.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF333333),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _agreed ? _onAgree : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF655193),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF655193).withValues(alpha: 0.35),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Agree & Continue'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: TextButton(
              onPressed: _onDecline,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF655193),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Decline & Exit'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onAgree() async {
    if (widget.isPolicyUpdate) {
      // Returning user accepted the updated policy: record acceptance and
      // return to the existing auth/session flow without re-selecting a user
      // type.
      await OnboardingStorageService.instance.acceptPolicyVersion();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthGuard()),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SelectUserTypePage()),
    );
  }

  void _onDecline() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit SERV'),
        content: const Text(
          'You must accept the SERV policies to continue. The app will close.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Review Again'),
          ),
          TextButton(
            onPressed: () {
              // Close the dialog; the user can then dismiss the app.
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _PolicySection {
  final String title;
  final String body;

  const _PolicySection({required this.title, required this.body});
}
