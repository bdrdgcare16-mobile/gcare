// lib/features/onboarding/registration/guards/registration_resume_guard.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:serv_app/models/company_data.dart';
import '../controllers/registration_draft_controller.dart';
import '../services/organization_registration_service.dart';
import '../screens/organization_information_page.dart';
import '../screens/feature_selection_page.dart';
import '../screens/admin_information_page.dart';
import '../screens/registration_verification_page.dart';
import '../screens/registration_documents_page.dart';
import '../screens/registration_review_page.dart';
import '../screens/registration_status_page.dart';
import '../screens/org_applicant_auth_page.dart';

/// Entry point for the Register Organization path.
///
/// For an authenticated `org_applicant` the SERVER decides the destination:
/// the caller's application is resolved via GET /org-registration/mine and
/// routed by its authoritative status — local draft/resume state is never
/// trusted for routing:
///
///   no application       → Organization Information (fresh start)
///   draft                → wizard at the saved step (server draft hydrated)
///   pending_approval     → Application Status
///   changes_requested    → Application Status (Edit resumes the wizard)
///   rejected             → Rejected status
///   approved             → Approved / awaiting activation
///   activated            → Application Status (org-admin provisioning is a
///                          later milestone — the wizard never claims it)
///
/// Without an applicant session the legacy local draft + resume-token path
/// is preserved. With NO applicant session and no local draft the applicant
/// is sent to the account gate.
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

  /// Restores a persisted org_applicant session into CompanyData.
  /// Returns true when the caller has an applicant session.
  Future<bool> _applicantSession() async {
    if (CompanyData.role == 'org_applicant' && CompanyData.token.isNotEmpty) {
      return true;
    }
    try {
      final sp = await SharedPreferences.getInstance();
      final role = sp.getString('role') ?? '';
      final token = sp.getString('token') ?? '';
      if (role == 'org_applicant' && token.isNotEmpty) {
        CompanyData.role = role;
        CompanyData.token = token;
        CompanyData.companyId = sp.getString('companyId') ?? '';
        CompanyData.email = sp.getString('email') ?? '';
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Authenticated resolution: GET /mine is the routing authority.
  /// Returns null on any failure so the caller can fall back to the
  /// local resume-token path.
  Future<Widget?> _resolveAuthenticated() async {
    final api = OrganizationRegistrationService.instance;
    final controller = RegistrationDraftController.instance;
    try {
      final app = await api.getMyApplication();
      if (app == null) {
        // No application — start registration at step 0.
        await controller.hydrate();
        return const OrganizationInformationPage();
      }
      final status = (app['status'] ?? '').toString();
      final registrationId = (app['registrationId'] ?? '').toString();

      if (status == 'draft' || status == 'pending_verification') {
        // Resume the wizard at the server-saved step, with the server
        // draft hydrated so another device's work is preserved.
        await controller.hydrate();
        await controller.hydrateFromServer(registrationId);
        return _pageForStep(controller.draft.currentStep);
      }

      // All non-editable statuses → the Application Status page (which
      // renders the pending / changes-requested / rejected / approved
      // views). Keep the linkage so the page can refetch.
      controller.draft.registrationId = registrationId;
      controller.draft.applicationStatus = status;
      return const RegistrationStatusPage();
    } on RegistrationApiException {
      return null;
    }
  }

  Future<void> _resolve() async {
    Widget? target;

    if (await _applicantSession()) {
      // Server resolution is authoritative. A failure falls through to the
      // local resume path — the applicant never returns to Role Selection.
      target = await _resolveAuthenticated();
    }

    if (target == null) {
      // hydrate() reconciles the backend application status before deciding.
      await RegistrationDraftController.instance.hydrate();
      final draft = RegistrationDraftController.instance.draft;

      if (draft.registrationId.isEmpty &&
          draft.isEmpty &&
          CompanyData.role != 'org_applicant') {
        // No session and no draft — collect the applicant account first.
        target = const OrgApplicantAuthPage();
      } else {
        // Submitted (or decided) applications are read-only — the resume
        // credential authorizes status retrieval, never further edits.
        target = draft.isSubmitted
            ? const RegistrationStatusPage()
            : _pageForStep(draft.currentStep);
      }
    }

    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => target!),
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
