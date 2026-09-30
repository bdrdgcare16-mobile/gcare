import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serv_app/features/onboarding/registration/controllers/registration_draft_controller.dart';
import 'package:serv_app/features/onboarding/registration/models/organization_registration_draft.dart';
import 'package:serv_app/features/onboarding/registration/screens/feature_selection_page.dart';
import 'package:serv_app/features/onboarding/registration/services/organization_registration_service.dart';
import 'package:serv_app/models/hrms_features.dart';

/// Recording HTTP stub — captures the request body sent to
/// /org-registration/draft and replies with a minimal 201 payload.
class _RecordingOverrides extends HttpOverrides {
  String? lastBody;

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _RecordingClient(this);
}

class _RecordingClient implements HttpClient {
  final _RecordingOverrides owner;
  _RecordingClient(this.owner);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _RecordingRequest(owner);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _RecordingRequest implements HttpClientRequest {
  final _RecordingOverrides owner;
  final _buf = BytesBuilder();
  _RecordingRequest(this.owner);

  @override
  void add(List<int> data) => _buf.add(data);
  @override
  void write(Object? object) => _buf.add(utf8.encode('$object'));
  @override
  Future<HttpClientResponse> close() async {
    owner.lastBody = utf8.decode(_buf.takeBytes());
    return _FakeResponse(
      utf8.encode(jsonEncode({
        'registrationId': 'reg-test-1',
        'resumeToken': 'tok',
      })),
      201,
    );
  }

  @override
  HttpHeaders get headers => _FakeHeaders();
  @override
  List<Cookie> get cookies => [];
  @override
  Future<void> addStream(Stream<List<int>> s) async {
    await for (final chunk in s) {
      _buf.add(chunk);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHeaders implements HttpHeaders {
  @override
  void forEach(void Function(String name, List<String> values) action) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeResponse extends Stream<List<int>> implements HttpClientResponse {
  final List<int> _bytes;
  final int _status;
  _FakeResponse(this._bytes, this._status);

  @override
  int get statusCode => _status;
  @override
  int get contentLength => _bytes.length;
  @override
  HttpHeaders get headers => _FakeHeaders();
  @override
  List<RedirectInfo> get redirects => const [];
  @override
  bool get isRedirect => false;
  @override
  bool get persistentConnection => false;
  @override
  String get reasonPhrase => 'OK';
  @override
  X509Certificate? get certificate => null;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      Stream.value(_bytes).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

CheckboxListTile _tile(WidgetTester tester, String title) =>
    tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, title),
    );

void main() {
  setUp(() {
    RegistrationDraftController.instance.draft =
        OrganizationRegistrationDraft();
  });

  group('Feature Selection — Basic HRMS', () {
    testWidgets(
        'renders locked Basic HRMS section and optional modules',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: FeatureSelectionPage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Basic HRMS — Included by Default'), findsOneWidget);
      expect(
        find.text('These core HRMS modules are included by default.'),
        findsOneWidget,
      );
      expect(find.text('Optional HRMS Modules'), findsOneWidget);

      // All four core modules render selected and locked (onChanged null).
      for (final title in [
        'Attendance',
        'Employee Master',
        'Feedback',
        'Shift Management',
      ]) {
        final tile = _tile(tester, title);
        expect(tile.value, isTrue, reason: '$title must be pre-selected');
        expect(tile.onChanged, isNull, reason: '$title must be locked');
      }

      // Optional modules render unselected and enabled.
      final payroll = _tile(tester, 'Payroll');
      expect(payroll.value, isFalse);
      expect(payroll.onChanged, isNotNull);
    });

    testWidgets(
        'shows only implemented optional modules — unimplemented keys absent',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: FeatureSelectionPage()),
      );
      await tester.pumpAndSettle();

      // Implemented optional modules are offered.
      for (final title in [
        'Location Tracking',
        'Tasks',
        'Leave Management',
        'Payroll',
        'Performance',
        'Events',
      ]) {
        expect(
          find.text(title),
          findsOneWidget,
          reason: '$title should be selectable',
        );
      }

      // Modules with no working implementation are never offered.
      for (final title in [
        'Organization Structure',
        'Users and Roles',
        'Recruitment',
        'Reporting',
      ]) {
        expect(
          find.text(title),
          findsNothing,
          reason: '$title must not be selectable',
        );
      }
    });

    testWidgets(
        'draft containing legacy unselectable keys does not crash or '
        'inflate the requested count', (tester) async {
      // Simulate an older draft that already contains a canonical key no
      // longer offered in the UI.
      RegistrationDraftController.instance.draft.requestedFeatures
          .addAll(['recruitment', 'payroll']);

      await tester.pumpWidget(
        const MaterialApp(home: FeatureSelectionPage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recruitment'), findsNothing);
      // 4 locked basics + 1 selectable optional (payroll) — 'recruitment'
      // is preserved in the draft but not counted as a UI selection.
      expect(find.text('5 feature(s) requested'), findsOneWidget);
      expect(
        RegistrationDraftController.instance.draft.requestedFeatures,
        containsAll(<String>['recruitment', 'payroll']),
      );
    });

    testWidgets(
        'basic tiles cannot be deselected; optionals toggle the draft',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: FeatureSelectionPage()),
      );
      await tester.pumpAndSettle();

      final draft = RegistrationDraftController.instance.draft;

      // Tapping a locked basic tile is a no-op — never added/removed.
      await tester.tap(find.text('Attendance'));
      await tester.pump();
      expect(draft.requestedFeatures.contains('attendance'), isFalse);
      expect(draft.requestedFeatures.length, 0);

      await tester.ensureVisible(find.text('Payroll'));
      await tester.tap(find.text('Payroll'));
      await tester.pump();
      await tester.ensureVisible(find.text('Location Tracking'));
      await tester.tap(find.text('Location Tracking'));
      await tester.pump();

      expect(
        draft.requestedFeatures,
        containsAll(<String>['payroll', 'location_tracking']),
      );
      // Only optional selections land in the draft — basics are injected
      // at payload time and enforced server-side.
      expect(draft.requestedFeatures.contains('attendance'), isFalse);
    });
  });

  group('Registration payload', () {
    test('createDraft always sends BASIC + selected optional features',
        () async {
      final overrides = _RecordingOverrides();
      HttpOverrides.global = overrides;
      try {
        final draft = OrganizationRegistrationDraft();
        draft.requestedFeatures.addAll(['payroll', 'location_tracking']);

        await OrganizationRegistrationService.instance.createDraft(draft);

        final body =
            jsonDecode(overrides.lastBody!) as Map<String, dynamic>;
        final sent =
            (body['requestedFeatures'] as List).map((e) => '$e').toSet();
        expect(
          sent,
          equals({
            'attendance',
            'employee_master',
            'feedback',
            'shifts',
            'payroll',
            'location_tracking',
          }),
        );
      } finally {
        HttpOverrides.global = null;
      }
    });

    test('kBasicHrmsFeatures is exactly the four mandated core modules',
        () {
      expect(
        kBasicHrmsFeatures,
        equals(['attendance', 'employee_master', 'feedback', 'shifts']),
      );
    });
  });
}
