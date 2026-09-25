// lib/features/onboarding/onboarding_guard.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:serv_app/features/auth/auth_guard.dart';
import 'registration/guards/registration_resume_guard.dart';
import 'screens/serv_policies_page.dart';
import 'screens/serv_welcome_page.dart';
import 'services/onboarding_storage_service.dart';

/// Decides the first screen shown after app launch based on onboarding and
/// policy-acceptance state.
///
/// Fresh install:
///   Welcome → Policies → Select User Type
///
/// Returning user with an outdated accepted policy version:
///   Policies → AuthGuard (skips Welcome and User Type selection)
///
/// Returning organization applicant with incomplete registration:
///   RegistrationResumeGuard → last saved registration step
///
/// Otherwise:
///   AuthGuard (existing session/login/role routing preserved)
class OnboardingGuard extends StatefulWidget {
  const OnboardingGuard({super.key});

  @override
  State<OnboardingGuard> createState() => _OnboardingGuardState();
}

class _OnboardingGuardState extends State<OnboardingGuard> {
  bool _ready = false;
  Widget? _destination;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decide());
  }

  Future<void> _decide() async {
    try {
      final completed =
          await OnboardingStorageService.instance.isInitialOnboardingCompleted();
      final policyUpdate =
          await OnboardingStorageService.instance.shouldShowPolicyUpdate();
      final userType =
          await OnboardingStorageService.instance.getSelectedUserType();
      final orgRegistrationComplete =
          await OnboardingStorageService.instance
              .isOrganizationRegistrationCompleted();
      // A persisted org_applicant session always resolves its application
      // server-side — Role Selection is never shown again, even if the
      // local user-type flag is absent or stale.
      String persistedRole = '';
      try {
        persistedRole =
            (await SharedPreferences.getInstance()).getString('role') ?? '';
      } catch (_) {}

      Widget destination;

      if (!completed) {
        // Fresh install: start the full onboarding flow.
        destination = const ServWelcomePage();
      } else if (policyUpdate) {
        // Returning user with an outdated policy version: show policies only.
        destination = const ServPoliciesPage();
      } else if (persistedRole == 'org_applicant') {
        // Authenticated applicant: server-side application resolution.
        destination = const RegistrationResumeGuard();
      } else if (userType == OnboardingUserType.registerOrganization &&
          !orgRegistrationComplete) {
        // Organization applicant whose registration is not yet complete:
        // resume the wizard at the saved step (or step 1 for a fresh draft).
        destination = const RegistrationResumeGuard();
      } else {
        // Onboarding completed and up to date: hand off to existing auth flow.
        destination = const AuthGuard();
      }

      setState(() {
        _destination = destination;
        _ready = true;
      });
    } catch (_) {
      // Fail safe: if storage cannot be read, show onboarding rather than
      // blocking the app.
      setState(() {
        _destination = const ServWelcomePage();
        _ready = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _destination ?? const AuthGuard();
  }
}
