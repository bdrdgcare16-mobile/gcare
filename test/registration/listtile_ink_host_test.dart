// test/registration/listtile_ink_host_test.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:serv_app/features/onboarding/onboarding_guard.dart';
import 'package:serv_app/features/onboarding/registration/controllers/registration_draft_controller.dart';
import 'package:serv_app/features/onboarding/registration/models/organization_registration_draft.dart';
import 'package:serv_app/features/onboarding/registration/screens/registration_review_page.dart';
import 'package:serv_app/features/onboarding/registration/screens/registration_status_page.dart';
import 'package:serv_app/features/users/multi_language_page.dart';

/// Regression coverage for the "ListTile background color or ink splashes
/// may be invisible" framework report: every ListTile-family widget must
/// have a Material ancestor between it and any decorated/colored ancestor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final controller = RegistrationDraftController.instance;
    controller.draft = OrganizationRegistrationDraft();
    controller.hydrated = true;
  });

  testWidgets(
      'detection sanity check — tile under a decorated box reports the error',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Container(
            decoration: const BoxDecoration(color: Color(0xFFFFF8E1)),
            child: CheckboxListTile(
              value: false,
              onChanged: (_) {},
              title: const Text('replica'),
            ),
          ),
        ),
      ),
    );
    final error = tester.takeException();
    expect(error, isA<FlutterError>());
    expect(error.toString(), contains('may be invisible'));
  });

  testWidgets(
      'Review Application declaration tile has a Material ink host',
      (tester) async {
    // Empty draft → _load() short-circuits before any network call and
    // renders the full page (including the declaration tile).
    await tester.pumpWidget(
      const MaterialApp(home: RegistrationReviewPage()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // No framework error may be reported while building the page.
    expect(tester.takeException(), isNull);
    expect(find.text('Declaration'), findsOneWidget);
  });

  testWidgets(
      'MultiLanguagePage radio tiles have a Material ink host',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MultiLanguagePage()),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(RadioListTile<String>), findsWidgets);
  });

  testWidgets(
      'startup → submitted application → Status page reports no tile error',
      (tester) async {
    // Reproduce the exact reload path: onboarding completed, user type =
    // registerOrganization, submitted draft stored, NO resume token (so
    // refreshApplicationStatus/_load short-circuit without any HTTP).
    final submitted = OrganizationRegistrationDraft(
      organizationName: 'NovaCare Digital Solutions Private Limited',
      registrationId: 'b5c7192e-9dfa-47fb-94a5-6c8d6a75a311',
      currentStep: RegistrationDraftController.stepReview,
      applicationStatus: 'pending_approval',
    );
    SharedPreferences.setMockInitialValues({
      'serv_initial_onboarding_completed': true,
      'serv_accepted_policy_version': '1.0',
      'serv_selected_user_type': 'register_organization',
      'serv_organization_registration_completed': false,
      'serv_org_registration_draft_v1': jsonEncode(submitted.toJson()),
    });
    FlutterSecureStorage.setMockInitialValues({});
    RegistrationDraftController.instance.hydrated = false;

    await tester.pumpWidget(const MaterialApp(home: OnboardingGuard()));
    // Let every async guard/load stage settle.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Any ListTile under a decorated ancestor anywhere in the startup
    // chain would have reported the framework error by now.
    expect(tester.takeException(), isNull);
    expect(find.byType(RegistrationStatusPage), findsOneWidget);
  });
}
