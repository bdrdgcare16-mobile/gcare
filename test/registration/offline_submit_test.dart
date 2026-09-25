// test/registration/offline_submit_test.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:serv_app/features/onboarding/registration/controllers/registration_draft_controller.dart';
import 'package:serv_app/features/onboarding/registration/models/organization_registration_draft.dart';
import 'package:serv_app/features/onboarding/registration/screens/registration_review_page.dart';
import 'package:serv_app/features/onboarding/registration/screens/registration_status_page.dart';

// ── Minimal HttpClient stubs (dart:io transport used by IOClient in tests) ──

class _StubHeaders implements HttpHeaders {
  const _StubHeaders();
  @override
  void forEach(void Function(String name, List<String> values) action) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _StubRequest implements HttpClientRequest {
  _StubRequest(this._response);
  final HttpClientResponse _response;
  @override
  HttpHeaders get headers => const _StubHeaders();
  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.drain();
  @override
  Future<void> flush() async {}
  @override
  Future<HttpClientResponse> close() async => _response;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _StubResponse extends Stream<List<int>> implements HttpClientResponse {
  _StubResponse(this.statusCode, this._body);
  @override
  final int statusCode;
  final List<int> _body;
  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      Stream<List<int>>.value(_body).listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  @override
  int get contentLength => _body.length;
  @override
  HttpHeaders get headers => const _StubHeaders();
  @override
  bool get isRedirect => false;
  @override
  bool get persistentConnection => false;
  @override
  String get reasonPhrase => 'OK';
  @override
  List<RedirectInfo> get redirects => const [];
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Routes requests by method/path; records every request for assertions.
class _StubHttpClient implements HttpClient {
  _StubHttpClient(this.handler);
  final Future<HttpClientResponse> Function(String method, Uri url) handler;
  final List<String> requests = [];

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    requests.add('$method ${url.path}');
    return _StubRequest(await handler(method, url));
  }

  @override
  void close({bool force = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _StubOverrides extends HttpOverrides {
  _StubOverrides(this.client);
  final _StubHttpClient client;
  @override
  HttpClient createHttpClient(SecurityContext? context) => client;
}

HttpClientResponse _json(int status, Map<String, dynamic> body) =>
    _StubResponse(status, utf8.encode(jsonEncode(body)));

Never _offline(String method, Uri url) =>
    throw http.ClientException('offline', url);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final controller = RegistrationDraftController.instance;
  HttpOverrides? previous;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues(
        {'serv_org_reg_resume_token': 'test-token'});
    controller.draft = OrganizationRegistrationDraft(
      organizationName: 'Retry Test Org',
      registrationId: 'REG-OFFLINE-1',
      currentStep: RegistrationDraftController.stepReview,
    );
    controller.hydrated = true;
    previous = HttpOverrides.current;
  });

  tearDown(() => HttpOverrides.global = previous);

  Future<void> pumpReview(WidgetTester tester) async {
    // Large surface so the checkbox and submit button are hit-testable.
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: RegistrationReviewPage()));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> tapSubmit(WidgetTester tester) async {
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.text('Submit Application'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets(
      'offline submit: no false success, no navigation, error shown, '
      'draft intact, retry possible', (tester) async {
    final offline = _StubHttpClient((m, u) async => _offline(m, u));
    HttpOverrides.global = _StubOverrides(offline);

    await pumpReview(tester);
    await tapSubmit(tester);

    // The submit call was actually attempted and failed at transport level.
    expect(
        offline.requests.where((r) => r.startsWith('POST')),
        contains(endsWith('/org-registration/submit')));

    // No false success and no navigation to Application Status.
    expect(find.byType(RegistrationStatusPage), findsNothing);
    expect(find.text('Application submitted for review'), findsNothing);

    // Loading state cleared — the button is enabled again (retry possible).
    final button =
        tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);

    // A clear error message is shown.
    expect(find.textContaining('Network unavailable'), findsWidgets);

    // Registration ID and local draft survive the failed request.
    expect(controller.draft.registrationId, 'REG-OFFLINE-1');
    expect(controller.draft.organizationName, 'Retry Test Org');
    expect(controller.draft.applicationStatus, 'draft');

    // Retry while still offline → second POST attempted, same safe state.
    await tester.tap(find.text('Submit Application'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(
        offline.requests
            .where((r) => r.endsWith('/org-registration/submit'))
            .length,
        2);
    expect(find.byType(RegistrationStatusPage), findsNothing);
  });

  testWidgets(
      'ambiguous timeout is reconciled via authoritative status '
      '(submit request failed but server processed it)', (tester) async {
    final ambiguous = _StubHttpClient((m, u) async {
      if (m == 'POST' && u.path.endsWith('/org-registration/submit')) {
        _offline(m, u); // response lost — but the server DID apply it
      }
      if (u.path.contains('/org-registration/status/')) {
        return _json(200, {'status': 'pending_approval'});
      }
      return _json(200, {}); // GET draft
    });
    HttpOverrides.global = _StubOverrides(ambiguous);

    await pumpReview(tester);
    await tapSubmit(tester);

    // Reconciliation fetched the authoritative status and routed to the
    // read-only Application Status screen instead of retrying blindly.
    expect(find.byType(RegistrationStatusPage), findsOneWidget);
    expect(controller.draft.applicationStatus, 'pending_approval');
  });

  testWidgets('retry succeeds after connectivity returns', (tester) async {
    var online = false;
    final client = _StubHttpClient((m, u) async {
      if (!online) _offline(m, u);
      if (m == 'POST' && u.path.endsWith('/org-registration/submit')) {
        return _json(200, {'status': 'pending_approval'});
      }
      if (u.path.contains('/org-registration/status/')) {
        return _json(200, {'status': 'pending_approval'});
      }
      return _json(200, {});
    });
    HttpOverrides.global = _StubOverrides(client);

    await pumpReview(tester);

    // First attempt fails offline.
    await tapSubmit(tester);
    expect(find.byType(RegistrationStatusPage), findsNothing);
    expect(find.textContaining('Network unavailable'), findsWidgets);

    // Connectivity returns → retry the same button → submit succeeds.
    online = true;
    await tester.tap(find.text('Submit Application'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(RegistrationStatusPage), findsOneWidget);
  });
}
