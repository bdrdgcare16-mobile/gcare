// lib/features/onboarding/screens/organization_registration_placeholder_page.dart

import 'package:flutter/material.dart';
import 'package:serv_app/features/users/login_page.dart';

/// Placeholder for the Organization Registration flow.
///
/// This screen is shown when a user selects "Register Organization" during
/// initial onboarding. The full registration implementation is planned for the
/// next milestone.
class OrganizationRegistrationPlaceholderPage extends StatelessWidget {
  const OrganizationRegistrationPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Organization Registration'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.business_outlined,
                size: 80,
                color: Color(0xFF655193),
              ),
              const SizedBox(height: 32),
              Text(
                'Organization Registration',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F3D3E),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Coming in the next implementation stage.\n\n'
                'For now, if you already have an account, please return to the '
                'existing login flow.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF555555),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _goToLogin(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF655193),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Go to Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToLogin(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }
}
