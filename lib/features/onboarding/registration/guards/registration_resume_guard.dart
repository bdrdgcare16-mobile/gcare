// lib/features/onboarding/registration/guards/registration_resume_guard.dart

import 'package:flutter/material.dart';

import '../controllers/registration_draft_controller.dart';
import '../screens/organization_information_page.dart';
import '../screens/feature_selection_page.dart';
import '../screens/admin_information_page.dart';
import '../screens/registration_verification_placeholder_page.dart';

/// Entry point for the Register Organization path.
///
/// Hydrates the local draft and routes to the last saved step:
///   0 → Organization Information (also used when no draft exists)
///   1 → Feature Selection
///   2 → Authorized HR/Admin Information
///   3 → Verification placeholder
class RegistrationResumeGuard extends StatefulWidget {
  const RegistrationResumeGuard({super.key});

  @override
  State<RegistrationResumeGuard> createState() =>
      _RegistrationResumeGuardState();
}

class _RegistrationResumeGuardState extends State<RegistrationResumeGuard> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Widget _pageForStep(int step) {
    switch (step) {
      case RegistrationDraftController.stepFeatures:
        return const FeatureSelectionPage();
      case RegistrationDraftController.stepAdmin:
        return const AdminInformationPage();
      case RegistrationDraftController.stepVerification:
        return const RegistrationVerificationPlaceholderPage();
      case RegistrationDraftController.stepOrganization:
      default:
        return const OrganizationInformationPage();
    }
  }

  Future<void> _resolve() async {
    await RegistrationDraftController.instance.hydrate();
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            _pageForStep(RegistrationDraftController.instance.draft.currentStep),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
