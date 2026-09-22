// test/registration/new_application_flow_test.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:serv_app/features/onboarding/registration/controllers/registration_draft_controller.dart';
import 'package:serv_app/features/onboarding/registration/models/organization_registration_draft.dart';
import 'package:serv_app/features/onboarding/registration/services/organization_registration_service.dart';
import 'package:serv_app/features/onboarding/registration/services/registration_draft_storage_service.dart';

/// Covers the "Start New Organization Application" flow:
///  - the previous application is detached but never destroyed,
///  - the new application starts blank with no inherited credential/status,
///  - re-hydration never resurrects the detached application.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final controller = RegistrationDraftController.instance;
  final api = OrganizationRegistrationService.instance;
  final storage = RegistrationDraftStorageService.instance;

  OrganizationRegistrationDraft submittedDraft() =>
      OrganizationRegistrationDraft(
        organizationName: 'Old Org Pvt Ltd',
        organizationType: 'Private Limited',
        officialEmail: 'hr@old-org.example',
        registrationId: 'REG-OLD-1',
        currentStep: RegistrationDraftController.stepReview,
        maxCompletedStep: RegistrationDraftController.stepReview,
        applicationStatus: 'pending_approval',
      );

  OrganizationRegistrationDraft editableDraft() =>
      OrganizationRegistrationDraft(
        organizationName: 'WIP Org',
        officialEmail: 'hr@wip.example',
        registrationId: 'REG-WIP-1',
        currentStep: 1,
        applicationStatus: 'draft',
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    controller.draft = OrganizationRegistrationDraft();
    controller.hydrated = false;
  });

  group('hasUnsentDraftWork', () {
    test('false for a submitted application', () {
      controller.draft = submittedDraft();
      expect(controller.hasUnsentDraftWork, isFalse);
    });

    test('false for a blank draft', () {
      controller.draft = OrganizationRegistrationDraft();
      expect(controller.hasUnsentDraftWork, isFalse);
    });

    test('true for an editable draft with content', () {
      controller.draft = editableDraft();
      expect(controller.hasUnsentDraftWork, isTrue);
    });

    test('true for changes_requested with content', () {
      final d = editableDraft()..applicationStatus = 'changes_requested';
      controller.draft = d;
      expect(controller.hasUnsentDraftWork, isTrue);
    });
  });

  group('startNewApplication', () {
    test('submitted app: archived, detached, new draft is blank', () async {
      controller.draft = submittedDraft();
      controller.hydrated = true;
      await storage.saveDraft(controller.draft);
      await api.saveResumeToken('old-token-value');

      await controller.startNewApplication();

      // New draft is a blank slate — no inherited ID, status or step.
      expect(controller.draft.registrationId, isEmpty);
      expect(controller.draft.applicationStatus, 'draft');
      expect(controller.draft.currentStep, 0);
      expect(controller.draft.isEmpty, isTrue);
      expect(controller.draft.isSubmitted, isFalse);

      // Active draft association and active credential are gone.
      expect(await storage.loadDraft(), isNull);
      expect(await api.loadResumeToken(), isNull);

      // The old credential is preserved under its per-registration key —
      // the once-issued token must not be destroyed.
      expect(await api.loadArchivedResumeToken('REG-OLD-1'),
          'old-token-value');

      // A non-secret archive entry remains for the submitted application.
      final archive = await storage.loadArchive();
      expect(archive, hasLength(1));
      expect(archive.single['registrationId'], 'REG-OLD-1');
      expect(archive.single['organizationName'], 'Old Org Pvt Ltd');
      expect(archive.single['status'], 'pending_approval');
    });

    test('editable draft: detached without archiving, credential released',
        () async {
      controller.draft = editableDraft();
      controller.hydrated = true;
      await storage.saveDraft(controller.draft);
      await api.saveResumeToken('wip-token');

      await controller.startNewApplication();

      expect(controller.draft.isEmpty, isTrue);
      expect(controller.draft.registrationId, isEmpty);
      expect(await storage.loadDraft(), isNull);
      expect(await api.loadResumeToken(), isNull);
      // Unsent drafts are not archived — no submitted application exists.
      expect(await storage.loadArchive(), isEmpty);
      expect(await api.loadArchivedResumeToken('REG-WIP-1'), isNull);
    });

    test('empty draft: starts new cleanly', () async {
      controller.draft = OrganizationRegistrationDraft();
      controller.hydrated = true;

      await controller.startNewApplication();

      expect(controller.draft.isEmpty, isTrue);
      expect(await api.loadResumeToken(), isNull);
      expect(await storage.loadArchive(), isEmpty);
    });

    test('hydrate() after start does not resurrect the old application',
        () async {
      controller.draft = submittedDraft();
      controller.hydrated = true;
      await storage.saveDraft(controller.draft);
      await api.saveResumeToken('old-token-value');

      await controller.startNewApplication();

      // Simulate the resume guard calling hydrate() again — it must not
      // reload the detached draft because the local store was cleared.
      controller.hydrated = false;
      await controller.hydrate();

      expect(controller.draft.registrationId, isEmpty);
      expect(controller.draft.applicationStatus, 'draft');
      expect(controller.draft.isSubmitted, isFalse);
      // The archived credential is still not the active credential.
      expect(await api.loadResumeToken(), isNull);
    });

    test('second start replaces only the active association', () async {
      // Archive a first submitted app, then start a second one.
      controller.draft = submittedDraft();
      controller.hydrated = true;
      await storage.saveDraft(controller.draft);
      await api.saveResumeToken('token-1');
      await controller.startNewApplication();

      // Simulate the second application being submitted later.
      final second = submittedDraft()
        ..registrationId = 'REG-NEW-2'
        ..organizationName = 'Second Org';
      controller.draft = second;
      await storage.saveDraft(second);
      await api.saveResumeToken('token-2');
      await controller.startNewApplication();

      final archive = await storage.loadArchive();
      expect(archive.map((e) => e['registrationId']),
          containsAll(<String>['REG-OLD-1', 'REG-NEW-2']));
      expect(await api.loadArchivedResumeToken('REG-OLD-1'), 'token-1');
      expect(await api.loadArchivedResumeToken('REG-NEW-2'), 'token-2');
      expect(await api.loadResumeToken(), isNull);
      expect(controller.draft.isEmpty, isTrue);
    });
  });
}
