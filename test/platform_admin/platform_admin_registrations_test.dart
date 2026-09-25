// test/platform_admin/platform_admin_registrations_test.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serv_app/config/api_config.dart';
import 'package:serv_app/features/platform_admin/platform_admin_registration_detail_page.dart';
import 'package:serv_app/features/platform_admin/platform_admin_registrations_page.dart';
import 'package:serv_app/models/company_data.dart';

// ── Minimal HttpClient stubs (dart:io transport used by IOClient in tests) ──

class _StubHeaders implements HttpHeaders {
  const _StubHeaders();
  @override
  void forEach(void Function(String name, List<String> values) action) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _StubRequest implements HttpClientRequest {
  _StubRequest(this._response, this._bodySink, this._onClose);
  final HttpClientResponse _response;
  final List<int> _bodySink;
  final void Function() _onClose;
  @override
  HttpHeaders get headers => const _StubHeaders();
  @override
  Future<void> addStream(Stream<List<int>> stream) =>
      stream.forEach(_bodySink.addAll);
  @override
  Future<void> flush() async {}
  @override
  Future<HttpClientResponse> close() async {
    _onClose();
    return _response;
  }
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

class _StubHttpClient implements HttpClient {
  _StubHttpClient(this.handler);
  final Future<HttpClientResponse> Function(String method, Uri url) handler;
  final List<String> requests = [];
  /// Decoded request bodies, appended in close() order.
  final List<String> bodies = [];

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    requests.add('$method ${url.path}${url.hasQuery ? '?${url.query}' : ''}');
    final buf = <int>[];
    final response = await handler(method, url);
    return _StubRequest(
      response,
      buf,
      () => bodies.add(utf8.decode(buf, allowMalformed: true)),
    );
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

Map<String, dynamic> _listItem(String id, String name, String status,
        {Map<String, dynamic> extra = const {}}) =>
    {
      'registrationId': id,
      'status': status,
      'organizationName': name,
      'organizationType': 'Private Limited',
      'adminContact': {
        'fullName': 'HR $name',
        'designation': 'HR Manager',
        'email': 'hr@$id.example.com',
        'mobile': '9876543210',
      },
      'submittedAt': '2024-06-01T10:00:00.000Z',
      'createdAt': '2024-05-30T10:00:00.000Z',
      ...extra,
    };

Map<String, dynamic> _detail(String id,
        {String status = 'pending_approval',
        Map<String, dynamic> extra = const {}}) =>
    {
      'registrationId': id,
      'status': status,
      'organization': {
        'name': 'NovaCare Digital Solutions Private Limited',
        'type': 'Private Limited',
        'industry': 'IT',
        'employeeCount': 42,
        'branchCount': 2,
        'registeredAddress': '1 Main Street',
        'officialEmail': 'hr@novacare.example.com',
        'contactNumber': '+91 80 1111 2222',
        'gstNumber': 'GST123',
      },
      'requestedFeatures': ['attendance', 'payroll'],
      'adminContact': {
        'fullName': 'Nova HR',
        'designation': 'HR Manager',
        'email': 'hr@novacare.example.com',
        'mobile': '9876543210',
      },
      'verification': {
        'orgEmail': {'verified': true, 'target': 'hr@novacare.example.com'},
        'adminEmail': {'verified': true, 'target': 'hr@novacare.example.com'},
        'adminMobile': {'verified': true, 'target': '9876543210'},
      },
      'documents': {
        'registrationCertificate': {
          'field': 'registrationCertificate',
          'originalName': 'cert.pdf',
          'contentType': 'application/pdf',
          'size': 1024,
          'uploadedAt': '2024-06-01T10:00:00.000Z',
        },
      },
      'submittedAt': '2024-06-01T10:00:00.000Z',
      'declarationAccepted': true,
      'auditTrail': [
        {'at': '2024-05-30T10:00:00.000Z', 'action': 'draft_created', 'actor': 'applicant'},
        {'at': '2024-06-01T10:00:00.000Z', 'action': 'submitted', 'actor': 'applicant'},
      ],
      'createdAt': '2024-05-30T10:00:00.000Z',
      'updatedAt': '2024-06-01T10:00:00.000Z',
      ...extra,
    };

/// Detail payload for a resubmitted application (revision 2): previous
/// changes_requested in reviewHistory, resubmittedAt, and the
/// server-computed changedFields diff.
Map<String, dynamic> _resubmittedDetail(String id) => _detail(
      id,
      extra: {
        'resubmissionCount': 1,
        'resubmittedAt': '2024-06-05T09:30:00.000Z',
        'reviewHistory': [
          {
            'decision': 'changes_requested',
            'note': 'Correct employees and address',
            'decidedAt': '2024-06-03T12:00:00.000Z',
            'reviewerEmail': 'pa@serv.test',
          },
        ],
        'changedFields': [
          {
            'field': 'organization.employeeCount',
            'label': 'Employees',
            'changeType': 'modified',
            'oldValue': '32',
            'newValue': '36',
          },
          {
            'field': 'organization.registeredAddress',
            'label': 'Registered Address',
            'changeType': 'modified',
            'oldValue': 'ABC',
            'newValue': 'XYZ',
          },
          {
            'field': 'requestedFeatures',
            'label': 'Requested Features',
            'changeType': 'modified',
            'added': ['recruitment'],
            'removed': ['attendance'],
          },
          {
            'field': 'documents.registrationCertificate',
            'label': 'Registration Certificate',
            'changeType': 'replaced',
            'oldValue': 'cert.pdf',
            'newValue': 'cert-v2.pdf',
          },
        ],
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides? previous;

  setUp(() {
    CompanyData.token = 'super-admin-jwt';
    previous = HttpOverrides.current;
  });

  tearDown(() => HttpOverrides.global = previous);

  group('DEV API URL safety', () {
    test('debug/test builds resolve ApiConfig.baseUrl to the local emulator',
        () {
      // flutter test always runs in debug mode — kReleaseMode is false.
      // Non-web debug resolves to the LAN emulator URL; web uses 127.0.0.1.
      // Either way it must be the DEV Functions emulator, never production.
      expect(ApiConfig.baseUrl, contains(':5002'));
      expect(ApiConfig.baseUrl, contains('serv-dev-f2557'));
      expect(ApiConfig.baseUrl, isNot(contains('run.app')));
    });

    test('no super admin service source hardcodes the production API', () {
      for (final path in [
        'lib/services/super_admin_onboarding_service_new.dart',
        'lib/services/platform_admin_registration_service.dart',
      ]) {
        final src = File(path).readAsStringSync();
        expect(src, isNot(contains('api-zmj7dqloiq-uc.a.run.app')),
            reason: '$path must resolve its base URL via ApiConfig');
      }
    });
  });

  group('PlatformAdminRegistrationsPage', () {
    testWidgets('lists applications with status filter and pagination',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final client = _StubHttpClient((method, url) async {
        final status = url.queryParameters['status'];
        final page = int.parse(url.queryParameters['page'] ?? '1');
        if (status == 'pending_approval') {
          return _json(200, {
            'registrations': [_listItem('r1', 'NovaCare', 'pending_approval')],
            'page': page,
            'pageSize': 10,
            'hasMore': false,
          });
        }
        return _json(200, {
          'registrations': [
            _listItem('r1', 'NovaCare', 'pending_approval'),
            _listItem('r2', 'DraftOrg', 'draft'),
          ],
          'page': page,
          'pageSize': 10,
          'hasMore': page == 1,
        });
      });
      HttpOverrides.global = _StubOverrides(client);

      // The page is a shell body (Column with Expanded) — give it a
      // bounded Scaffold like the real NavigationRail layout does.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PlatformAdminRegistrationsPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Default tab is "Pending" (status=pending_approval): the draft is
      // filtered out server-side and must not render.
      expect(find.text('NovaCare'), findsOneWidget);
      expect(find.text('DraftOrg'), findsNothing);
      expect(find.text('PENDING APPROVAL'), findsOneWidget);
      expect(client.requests.first, contains('/platform-admin/registrations'));
      expect(client.requests.first, contains('status=pending_approval'));

      // "All Applications" removes the status filter.
      await tester.tap(find.text('All Applications'));
      await tester.pumpAndSettle();
      expect(find.text('NovaCare'), findsOneWidget);
      expect(find.text('DraftOrg'), findsOneWidget);
      expect(find.text('View Application'), findsNWidgets(2));

      // Pagination requests page 2 (unfiltered stub reports hasMore on page 1).
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(client.requests.last, contains('page=2'));
    });

    testWidgets('sends search and submittedAt sort params', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final client = _StubHttpClient((method, url) async {
        return _json(200, {
          'registrations': [_listItem('r1', 'NovaCare', 'pending_approval')],
          'page': 1,
          'pageSize': 10,
          'hasMore': false,
        });
      });
      HttpOverrides.global = _StubOverrides(client);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PlatformAdminRegistrationsPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextField).first, 'nova');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(client.requests.last, contains('search=nova'));

      // Sort dropdown → Submission date → sort=submittedAt.
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submission date').last);
      await tester.pumpAndSettle();
      expect(client.requests.last, contains('sort=submittedAt'));
    });

    testWidgets('shows an error when the API rejects the call', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final client = _StubHttpClient(
        (method, url) async => _json(403, {'error': 'Not authorized'}),
      );
      HttpOverrides.global = _StubOverrides(client);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PlatformAdminRegistrationsPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Not authorized'), findsOneWidget);
    });
  });

  group('PlatformAdminRegistrationDetailPage', () {
    testWidgets(
        'renders full application, REQUESTED feature labels, documents, audit',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final client = _StubHttpClient((method, url) async {
        return _json(200, {'registration': _detail('r1')});
      });
      HttpOverrides.global = _StubOverrides(client);

      await tester.pumpWidget(
        const MaterialApp(
          home: PlatformAdminRegistrationDetailPage(registrationId: 'r1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NovaCare Digital Solutions Private Limited'),
          findsOneWidget);
      expect(find.textContaining('PENDING APPROVAL'), findsWidgets);
      // Features are REQUESTED — never approved/enabled.
      expect(find.text('Attendance — REQUESTED'), findsOneWidget);
      expect(find.text('Payroll — REQUESTED'), findsOneWidget);
      expect(find.text('Nova HR'), findsOneWidget);
      expect(find.text('Verified'), findsNWidgets(3));
      expect(find.text('View Document'), findsNWidgets(1));
      expect(find.text('Not uploaded'), findsNWidgets(3));
      expect(find.textContaining('submitted'), findsOneWidget);
      // 3D-C — pending_approval exposes the three review actions.
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
      expect(find.text('Request Changes'), findsOneWidget);
      expect(client.requests.single, contains('/platform-admin/registrations/r1'));
    });
  });

  group('PlatformAdminRegistrationDetailPage — 3D-C review actions', () {
    Future<void> pumpDetail(
      WidgetTester tester,
      _StubHttpClient client, {
      String status = 'pending_approval',
    }) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      HttpOverrides.global = _StubOverrides(client);
      await tester.pumpWidget(
        const MaterialApp(
          home: PlatformAdminRegistrationDetailPage(registrationId: 'r1'),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('decision buttons appear only for pending_approval',
        (tester) async {
      final client = _StubHttpClient((method, url) async =>
          _json(200, {'registration': _detail('r1', status: 'approved')}));
      await pumpDetail(tester, client);

      expect(find.textContaining('not awaiting review'), findsOneWidget);
      expect(find.text('Approve'), findsNothing);
      expect(find.text('Reject'), findsNothing);
      expect(find.text('Request Changes'), findsNothing);
    });

    testWidgets('approve shows a confirmation dialog and records the decision',
        (tester) async {
      var detailStatus = 'pending_approval';
      final client = _StubHttpClient((method, url) async {
        if (method == 'POST' && url.path.endsWith('/approve')) {
          detailStatus = 'approved';
          return _json(200, {'status': 'approved', 'decision': 'approved'});
        }
        return _json(
            200, {'registration': _detail('r1', status: detailStatus)});
      });
      await pumpDetail(tester, client);

      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      expect(find.text('Approve application?'), findsOneWidget);

      // Optional note, then confirm via the dialog FilledButton.
      await tester.enterText(find.byType(TextField).last, 'Docs verified');
      await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
      await tester.pumpAndSettle();

      expect(client.requests.any((r) => r.startsWith('POST') && r.contains('/approve')), isTrue);
      // A GET refetch follows the POST — find the body on the POST request.
      expect(client.bodies.any((b) => b.contains('Docs verified')), isTrue);
      // After success the page refetches — new status, no more buttons.
      expect(find.textContaining('APPROVED'), findsWidgets);
      expect(find.text('Approve'), findsNothing);
      expect(find.text('Reject'), findsNothing);
      expect(find.text('Request Changes'), findsNothing);
    });

    testWidgets('reject requires a reason — confirm is blocked when empty',
        (tester) async {
      final client = _StubHttpClient((method, url) async =>
          _json(200, {'registration': _detail('r1')}));
      await pumpDetail(tester, client);

      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();
      expect(find.text('Reject application?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Reject application'));
      await tester.pumpAndSettle();
      expect(find.text('This field is required.'), findsOneWidget);
      expect(client.requests.any((r) => r.startsWith('POST')), isFalse);
    });

    testWidgets('request changes requires a message', (tester) async {
      final client = _StubHttpClient((method, url) async =>
          _json(200, {'registration': _detail('r1')}));
      await pumpDetail(tester, client);

      await tester.tap(find.text('Request Changes'));
      await tester.pumpAndSettle();
      expect(find.text('Request changes?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Request changes'));
      await tester.pumpAndSettle();
      expect(find.text('This field is required.'), findsOneWidget);
      expect(client.requests.any((r) => r.startsWith('POST')), isFalse);
    });

    testWidgets('action buttons are disabled while the request runs',
        (tester) async {
      final gate = Completer<HttpClientResponse>();
      final client = _StubHttpClient((method, url) async {
        if (method == 'POST') return gate.future;
        return _json(200, {'registration': _detail('r1')});
      });
      await pumpDetail(tester, client);

      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
      await tester.pump();

      // While POST is in flight all three buttons are disabled.
      final approveBtn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Approve'));
      final rejectBtn = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Reject'));
      final changesBtn = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Request Changes'));
      expect(approveBtn.onPressed, isNull);
      expect(rejectBtn.onPressed, isNull);
      expect(changesBtn.onPressed, isNull);

      gate.complete(_json(200, {'status': 'approved'}));
      await tester.pumpAndSettle();
    });

    testWidgets('a decided application no longer exposes action buttons',
        (tester) async {
      var status = 'pending_approval';
      final client = _StubHttpClient((method, url) async {
        if (method == 'POST' && url.path.endsWith('/reject')) {
          status = 'rejected';
          return _json(200, {'status': 'rejected'});
        }
        return _json(200, {'registration': _detail('r1', status: status)});
      });
      await pumpDetail(tester, client);

      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byType(TextField).last, 'Certificate mismatch');
      await tester.tap(find.widgetWithText(FilledButton, 'Reject application'));
      await tester.pumpAndSettle();

      expect(client.bodies.any((b) => b.contains('Certificate mismatch')),
          isTrue);
      expect(find.textContaining('REJECTED'), findsWidgets);
      expect(find.text('Approve'), findsNothing);
      expect(find.text('Reject'), findsNothing);
      expect(find.text('Request Changes'), findsNothing);
    });
  });

  group('Resubmission review context', () {
    testWidgets(
        'a resubmitted list card shows RESUBMITTED, revision and change count',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final client = _StubHttpClient((method, url) async {
        return _json(200, {
          'registrations': [
            _listItem('r1', 'NovaCare', 'pending_approval', extra: {
              'resubmissionCount': 1,
              'resubmittedAt': '2024-06-05T09:30:00.000Z',
              'changedFieldsCount': 3,
            }),
            _listItem('r2', 'FreshOrg', 'pending_approval'),
          ],
          'page': 1,
          'pageSize': 10,
          'hasMore': false,
        });
      });
      HttpOverrides.global = _StubOverrides(client);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PlatformAdminRegistrationsPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RESUBMITTED • REVISION 2'), findsOneWidget);
      expect(find.text('3 fields updated'), findsOneWidget);
      // The first-submission card carries no badge.
      expect(find.text('NovaCare'), findsOneWidget);
      expect(find.text('FreshOrg'), findsOneWidget);
      expect(find.textContaining('REVISION'), findsOneWidget);
    });

    testWidgets(
        'a first-submission card shows no resubmission badge',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final client = _StubHttpClient((method, url) async {
        return _json(200, {
          'registrations': [
            _listItem('r1', 'NovaCare', 'pending_approval'),
          ],
          'page': 1,
          'pageSize': 10,
          'hasMore': false,
        });
      });
      HttpOverrides.global = _StubOverrides(client);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PlatformAdminRegistrationsPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('RESUBMITTED'), findsNothing);
      expect(find.textContaining('fields updated'), findsNothing);
    });

    testWidgets(
        'resubmitted detail shows review context, diff and active actions',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final client = _StubHttpClient((method, url) async =>
          _json(200, {'registration': _resubmittedDetail('r1')}));
      HttpOverrides.global = _StubOverrides(client);

      await tester.pumpWidget(
        const MaterialApp(
          home: PlatformAdminRegistrationDetailPage(registrationId: 'r1'),
        ),
      );
      await tester.pumpAndSettle();

      // Context panel: badge, previous request, resubmitted stamp.
      expect(find.text('Resubmitted Application'), findsOneWidget);
      expect(find.text('RESUBMITTED • REVISION 2'), findsOneWidget);
      expect(find.text('Previous Request for Changes'), findsOneWidget);
      expect(find.text('"Correct employees and address"'), findsOneWidget);
      expect(find.textContaining('pa@serv.test'), findsOneWidget);

      // Diff section: only changed fields, old/new rendered.
      expect(find.text('Changes Made by Applicant'), findsOneWidget);
      expect(find.text('Employees'), findsWidgets);
      expect(find.text('Old: 32'), findsOneWidget);
      expect(find.text('New: 36'), findsOneWidget);
      expect(find.text('Old: ABC'), findsOneWidget);
      expect(find.text('New: XYZ'), findsOneWidget);
      expect(find.text('Added: recruitment'), findsOneWidget);
      expect(find.text('Removed: attendance'), findsOneWidget);
      expect(find.textContaining('Replaced'), findsWidgets);

      // status is still pending_approval — review actions remain.
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Request Changes'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
      expect(
        find.textContaining('resubmitted after requested corrections'),
        findsOneWidget,
      );
    });

    testWidgets(
        'first-submission detail shows no resubmission panel or diff',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final client = _StubHttpClient((method, url) async =>
          _json(200, {'registration': _detail('r1')}));
      HttpOverrides.global = _StubOverrides(client);

      await tester.pumpWidget(
        const MaterialApp(
          home: PlatformAdminRegistrationDetailPage(registrationId: 'r1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Resubmitted Application'), findsNothing);
      expect(find.text('Changes Made by Applicant'), findsNothing);
      expect(find.textContaining('RESUBMITTED'), findsNothing);
      // Actions still available — it is pending_approval.
      expect(find.text('Approve'), findsOneWidget);
    });
  });
}
