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
    await _refreshFromBackend();
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
    await _syncToBackend();
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
    draft.currentStep = nextStep ?? (step + 1).clamp(0, stepDocuments);
    await persist();
    notifyListeners();
  }

  Future<void> goToStep(int step) async {
    draft.currentStep = step.clamp(0, stepDocuments);
    await persist();
    notifyListeners();
  }

  /// Clears the draft entirely (e.g. after a future successful submission).
  Future<void> reset() async {
    draft = OrganizationRegistrationDraft();
    await RegistrationDraftStorageService.instance.clearDraft();
    await _api.clearResumeToken();
    notifyListeners();
  }
}
