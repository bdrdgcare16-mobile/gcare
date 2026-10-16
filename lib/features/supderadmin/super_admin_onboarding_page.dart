import 'package:flutter/material.dart';
import 'package:serv_app/features/onboarding/onboarding_review_view.dart';

import 'platform_admin_shell.dart';

/// Legacy Platform/Super Admin onboarding review shell. The shared
/// review UI lives in OnboardingReviewView; backend authorization now
/// restricts these endpoints to company_admin, so this surface renders
/// the shared view but receives 403s from the API.
class SuperAdminOnboardingPage extends StatelessWidget {
  const SuperAdminOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlatformAdminShell(
      selected: PlatformAdminSection.registrations,
      title: 'Organization Registrations',
      body: OnboardingReviewView(),
    );
  }
}
