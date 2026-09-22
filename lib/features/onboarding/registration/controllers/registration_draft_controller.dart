// lib/features/onboarding/registration/controllers/registration_draft_controller.dart

import 'package:flutter/foundation.dart';

import '../models/organization_registration_draft.dart';
import '../services/organization_registration_service.dart';
import '../services/registration_draft_storage_service.dart';

/// Shared state for the organization-registration wizard.
///
/// A lightweight ChangeNotifier singleton — no extra state-management
/// packages. Screens mutate [draft] and call [persist] (autosave) or rely
/// on [markStepCompleted] / [goToStep] which persist automatically.
///
/// Every persist also attempts a best-effort backend sync. A backend
/// failure NEVER discards the local draft — the applicant keeps their data
/// and the sync is retried on the next save.
class RegistrationDraftController extends ChangeNotifier {
  RegistrationDraftController._();

  static final RegistrationDraftController instance =
      RegistrationDraftController._();

  static const int stepOrganization = 0;
  static const int stepFeatures = 1;
  static const int stepAdmin = 2;
  static const int stepVerification = 3;
  static const int stepDocuments = 4;
  static const int stepReview = 5;
  static const int lastEditableStep = stepAdmin;

  final _api = OrganizationRegistrationService.instance;

  OrganizationRegistrationDraft draft = OrganizationRegistrationDraft();
  bool hydrated = false;

  /// Load any saved draft from local storage, then attempt a backend
  /// refresh when a server registrationId exists. Idempotent.
  Future<void> hydrate() async {
    if (hydrated) return;
    hydrated = true;
    final saved = await RegistrationDraftStorageService.instance.loadDraft();
    if (saved != null) {
      draft = saved;
      notifyListeners();
    }
    await refreshApplicationStatus();
    // A submitted application is server-owned — never pull it back into the
    // editable wizard or re-sync local edits over it.
    if (draft.isSubmitted) return;
    await _refreshFromBackend();
  }

  /// Fetches the authoritative application status.
  ///
  /// On a backend outage the cached status is preserved — a submitted
  /// application is never silently reverted to draft, and an unsubmitted one
  /// is never shown as submitted.
  Future<void> refreshApplicationStatus() async {
    if (draft.registrationId.isEmpty) return;
    final token = await _api.loadResumeToken();
    if (token == null || token.isEmpty) return;
    try {
      final status = await _api.getStatus(draft.registrationId, token);
      final serverStatus = (status['status'] ?? '').toString();
      if (serverStatus.isNotEmpty) {
        draft.applicationStatus = serverStatus;
        await RegistrationDraftStorageService.instance.saveDraft(draft);
        notifyListeners();
      }
    } on RegistrationApiException {
      // Outage or revoked credential — keep the last-known cached status.
    }
  }

  /// Pull the authoritative server draft if we have an id + credential.
  /// Failures keep the local draft — never wiped on transient errors.
  ///
  /// Skipped entirely when the local draft has unsynced changes
  /// ([backendSyncFailed]) — otherwise a stale server copy would overwrite
  /// newer local edits on restart.
  Future<void> _refreshFromBackend() async {
    if (draft.registrationId.isEmpty || draft.backendSyncFailed) return;
    final token = await _api.loadResumeToken();
    if (token == null || token.isEmpty) {
      // Credential lost (e.g. secure storage cleared) — keep local data and
      // re-create a fresh server draft on next save.
      draft.registrationId = '';
      return;
    }
    try {
      final serverDraft = await _api.getDraft(draft.registrationId, token);
      OrganizationRegistrationService.applyServerDraft(draft, serverDraft);
      draft.backendSyncFailed = false;
      await RegistrationDraftStorageService.instance.saveDraft(draft);
      notifyListeners();
    } on RegistrationCredentialException {
      // Expired/revoked credential — keep local data, create a new server
      // draft on next save.
      draft.registrationId = '';
      await _api.clearResumeToken();
      await RegistrationDraftStorageService.instance.saveDraft(draft);
      notifyListeners();
    } on RegistrationApiException {
      // Backend unavailable — keep the local draft as-is.
    }
  }

  Future<void> persist() async {
    await RegistrationDraftStorageService.instance.saveDraft(draft);
    // Submitted applications are read-only — do not attempt a draft sync
    // (the server would reject it) and do not create a replacement draft.
    if (draft.isSubmitted) return;
    await _syncToBackend();
  }

  /// Submits the application for platform-admin review.
  ///
  /// Returns the authoritative status from the backend. Throws
  /// [RegistrationApiException] on validation/conflict/network failures so
  /// the caller can surface the real reason.
  Future<Map<String, dynamic>> submitApplication() async {
    if (draft.registrationId.isEmpty) {
      throw const RegistrationApiException(
          'The application has not been saved to the server yet.');
    }
    final token = await _api.loadResumeToken();
    if (token == null || token.isEmpty) {
      throw const RegistrationApiException(
          'Registration credential is unavailable on this device.');
    }
    final body = await _api.submit(
      draft.registrationId,
      token,
      declarationAccepted: true,
    );
    final status = (body['status'] ?? '').toString();
    if (status.isNotEmpty) {
      draft.applicationStatus = status;
      await RegistrationDraftStorageService.instance.saveDraft(draft);
      notifyListeners();
    }
    return body;
  }

  /// Best-effort backend sync — errors are swallowed into
  /// [draft.backendSyncFailed] so navigation/UX never breaks.
  Future<void> _syncToBackend() async {
    try {
      if (draft.registrationId.isEmpty) {
        final created = await _api.createDraft(draft);
        draft.registrationId = created.registrationId;
        await _api.saveResumeToken(created.resumeToken);
      } else {
        final token = await _api.loadResumeToken();
        if (token == null || token.isEmpty) {
          draft.registrationId = '';
          await _syncToBackend();
          return;
        }
        await _api.updateDraft(draft.registrationId, token, draft);
      }
      draft.backendSyncFailed = false;
    } on RegistrationCredentialException {
      // Server rejected the credential — drop the stale linkage, keep local
      // data, and create a fresh draft next save.
      draft.registrationId = '';
      await _api.clearResumeToken();
      draft.backendSyncFailed = true;
    } on RegistrationApiException {
      draft.backendSyncFailed = true;
    }
    // Persist the updated sync metadata locally too.
    await RegistrationDraftStorageService.instance.saveDraft(draft);
  }

  /// Records that [step] was completed and moves the wizard position.
  Future<void> markStepCompleted(int step, {int? nextStep}) async {
    if (step > draft.maxCompletedStep) {
      draft.maxCompletedStep = step;
    }
    draft.currentStep = nextStep ?? (step + 1).clamp(0, stepReview);
    await persist();
    notifyListeners();
  }

  Future<void> goToStep(int step) async {
    draft.currentStep = step.clamp(0, stepReview);
    await persist();
    notifyListeners();
  }

  /// True when unsent local work would be lost by starting a new application.
  bool get hasUnsentDraftWork => !draft.isSubmitted && !draft.isEmpty;

  /// Starts a genuinely new organization application.
  ///
  /// The previously submitted application is NEVER touched in Firestore —
  /// its status, audit trail and documents are left exactly as they are.
  /// Only the LOCAL active association is detached:
  ///   * a submitted application is archived (reference + credential kept so
  ///     it remains retrievable) and its cached status is dropped;
  ///   * an unsent server draft simply has its credential released.
  ///
  /// The new application starts with no registrationId and no credential, so
  /// the previous application's resume token or cached status can never be
  /// attached to it. A fresh registrationId is minted by the backend on the
  /// first save of the new draft.
  Future<void> startNewApplication() async {
    final previous = draft;

    if (previous.registrationId.isNotEmpty) {
      if (previous.isSubmitted) {
        await RegistrationDraftStorageService.instance.archiveApplication(
          registrationId: previous.registrationId,
          organizationName: previous.organizationName,
          status: previous.applicationStatus,
        );
        // Preserve the once-issued credential under a per-registration key.
        await _api.archiveResumeToken(previous.registrationId);
      } else {
        // Unsent draft — release the credential; the orphaned server draft
        // expires on its own TTL and is never mutated here.
        await _api.clearResumeToken();
      }
    } else {
      await _api.clearResumeToken();
    }

    await RegistrationDraftStorageService.instance.clearDraft();

    // Blank draft: no registrationId, no cached status, step 0.
    draft = OrganizationRegistrationDraft();
    // Keep `hydrated` true so the cleared draft is not re-loaded from disk.
    hydrated = true;
    notifyListeners();
  }

  /// Clears the draft entirely, discarding the active credential.
  ///
  /// Prefer [startNewApplication] for the applicant-facing flow — it retains
  /// the submitted application's credential instead of destroying it.
  Future<void> reset() async {
    draft = OrganizationRegistrationDraft();
    await RegistrationDraftStorageService.instance.clearDraft();
    await _api.clearResumeToken();
    hydrated = true;
    notifyListeners();
  }
}
