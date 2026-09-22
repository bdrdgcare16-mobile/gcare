// lib/features/onboarding/registration/guards/registration_resume_guard.dart

import 'package:flutter/material.dart';

import '../controllers/registration_draft_controller.dart';
import '../screens/organization_information_page.dart';
import '../screens/feature_selection_page.dart';
import '../screens/admin_information_page.dart';
import '../screens/registration_verification_page.dart';
import '../screens/registration_documents_page.dart';
import '../screens/registration_review_page.dart';
import '../screens/registration_status_page.dart';

/// Entry point for the Register Organization path.
///
/// Hydrates the local draft, reconciles the AUTHORITATIVE application status
/// with the backend, and routes accordingly.
///
/// A submitted application (pending_approval / approved / rejected) always
/// opens Application Status — never the editable wizard. `changes_requested`
/// is editable again and resumes the wizard. Otherwise the last saved step:
///   0 → Organization Information (also used when no draft exists)
///   1 → Feature Selection
///   2 → Authorized HR/Admin Information
///   3 → Contact Verification
///   4 → Organization Documents
///   5 → Review Application
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
        return const RegistrationVerificationPage();
      case RegistrationDraftController.stepDocuments:
        return const RegistrationDocumentsPage();
      case RegistrationDraftController.stepReview:
        return const RegistrationReviewPage();
      case RegistrationDraftController.stepOrganization:
      default:
        return const OrganizationInformationPage();
    }
  }

  Future<void> _resolve() async {
    // hydrate() reconciles the backend application status before deciding.
    await RegistrationDraftController.instance.hydrate();
    if (!mounted || _navigated) return;
    _navigated = true;
    final draft = RegistrationDraftController.instance.draft;

    // Submitted (or decided) applications are read-only — the resume
    // credential authorizes status retrieval, never further edits.
    final Widget target = draft.isSubmitted
        ? const RegistrationStatusPage()
        : _pageForStep(draft.currentStep);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => target),
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
