// lib/features/onboarding/registration/controllers/registration_draft_controller.dart

import 'package:flutter/foundation.dart';

import '../models/organization_registration_draft.dart';
import '../services/registration_draft_storage_service.dart';

/// Shared state for the organization-registration wizard.
///
/// A lightweight ChangeNotifier singleton — no extra state-management
/// packages. Screens mutate [draft] and call [persist] (autosave) or rely
/// on [markStepCompleted] / [goToStep] which persist automatically.
class RegistrationDraftController extends ChangeNotifier {
  RegistrationDraftController._();

  static final RegistrationDraftController instance =
      RegistrationDraftController._();

  static const int stepOrganization = 0;
  static const int stepFeatures = 1;
  static const int stepAdmin = 2;
  static const int stepVerification = 3;
  static const int lastEditableStep = stepAdmin;

  OrganizationRegistrationDraft draft = OrganizationRegistrationDraft();
  bool hydrated = false;

  /// Load any saved draft from local storage. Idempotent.
  Future<void> hydrate() async {
    if (hydrated) return;
    hydrated = true;
    final saved = await RegistrationDraftStorageService.instance.loadDraft();
    if (saved != null) {
      draft = saved;
      notifyListeners();
    }
  }

  Future<void> persist() async {
    await RegistrationDraftStorageService.instance.saveDraft(draft);
  }

  /// Records that [step] was completed and moves the wizard position.
  Future<void> markStepCompleted(int step, {int? nextStep}) async {
    if (step > draft.maxCompletedStep) {
      draft.maxCompletedStep = step;
    }
    draft.currentStep = nextStep ?? (step + 1).clamp(0, stepVerification);
    await persist();
    notifyListeners();
  }

  Future<void> goToStep(int step) async {
    draft.currentStep = step.clamp(0, stepVerification);
    await persist();
    notifyListeners();
  }

  /// Clears the draft entirely (e.g. after a future successful submission).
  Future<void> reset() async {
    draft = OrganizationRegistrationDraft();
    await RegistrationDraftStorageService.instance.clearDraft();
    notifyListeners();
  }
}
