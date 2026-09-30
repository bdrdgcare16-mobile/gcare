// test/platform_admin/platform_admin_audit_test.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serv_app/features/platform_admin/platform_admin_audit_page.dart';
import 'package:serv_app/models/company_data.dart';

// ── Minimal HttpClient stubs (dart:io transport used by IOClient in tests) ──
// Mirrors test/platform_admin/platform_admin_registrations_test.dart.

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

Map<String, dynamic> _event(
  String registrationId,
  String action, {
  String organizationName = 'SERV Demo Technologies Pvt Ltd',
  Map<String, dynamic> extra = const {},
}) =>
    {
      'registrationId': registrationId,
      'organizationName': organizationName,
      'organizationCode': null,
      'action': action,
      'eventLabel': const {
        'submitted': 'Application Submitted',
        'changes_requested': 'Changes Requested',
        'application_resubmitted': 'Application Resubmitted',
        'application_approved': 'Application Approved',
        'application_rejected': 'Application Rejected',
        'organization_activated': 'Organization Activated',
      }[action],
      'previousStatus': null,
      'newStatus': null,
      'actorEmail': null,
      'actorRole': null,
      'note': null,
      'revision': null,
      'changedFieldsCount': null,
      'at': '2024-06-01T10:00:00.000Z',
      ...extra,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides? previous;

  setUp(() {
    CompanyData.token = 'platform-admin-jwt';
    previous = HttpOverrides.current;
  });

  tearDown(() => HttpOverrides.global = previous);

  Future<void> pumpAuditPage(WidgetTester tester, _StubHttpClient client) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    HttpOverrides.global = _StubOverrides(client);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PlatformAdminAuditPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('PlatformAdminAuditPage', () {
    testWidgets('renders history list with event labels and org name',
        (tester) async {
      final client = _StubHttpClient((method, url) async {
        return _json(200, {
          'events': [
            _event('serv-demo', 'organization_activated', extra: {
              'organizationCode': 'SERV001',
              'previousStatus': 'approved',
              'newStatus': 'activated',
              'actorEmail': 'pa@serv.test',
              'actorRole': 'Platform Admin',
            }),
          ],
          'page': 1,
          'pageSize': 10,
          'hasMore': false,
        });
      });
      await pumpAuditPage(tester, client);

      expect(client.requests.first, contains('/platform-admin/registrations/audit-history'));
      expect(find.text('ORGANIZATION ACTIVATED'), findsOneWidget);
      expect(find.text('SERV Demo Technologies Pvt Ltd'), findsOneWidget);
      expect(find.text('Ref: serv-demo'), findsOneWidget);
      expect(find.textContaining('SERV001'), findsOneWidget);
      expect(find.textContaining('pa@serv.test'), findsOneWidget);
    });

    testWidgets('shows the empty state only when there are no events',
        (tester) async {
      final client = _StubHttpClient((method, url) async {
        return _json(200, {'events': [], 'page': 1, 'pageSize': 10, 'hasMore': false});
      });
      await pumpAuditPage(tester, client);

      expect(find.text('No review history yet'), findsOneWidget);
    });

    testWidgets('reviewer message shown for changes requested', (tester) async {
      final client = _StubHttpClient((method, url) async {
        return _json(200, {
          'events': [
            _event('r1', 'changes_requested', extra: {
              'previousStatus': 'pending_approval',
              'newStatus': 'changes_requested',
              'actorEmail': 'pa@serv.test',
              'actorRole': 'Platform Admin',
              'note': 'Please fix employee count',
            }),
          ],
          'page': 1,
          'pageSize': 10,
          'hasMore': false,
        });
      });
      await pumpAuditPage(tester, client);

      expect(find.text('Please fix employee count'), findsOneWidget);
      expect(find.textContaining('Pending Approval'), findsOneWidget);
      expect(find.textContaining('Changes Requested'), findsWidgets);
    });

    testWidgets('rejection reason shown for rejected applications', (tester) async {
      final client = _StubHttpClient((method, url) async {
        return _json(200, {
          'events': [
            _event('r2', 'application_rejected', extra: {
              'previousStatus': 'pending_approval',
              'newStatus': 'rejected',
              'actorEmail': 'pa@serv.test',
              'actorRole': 'Platform Admin',
              'note': 'Documents illegible',
            }),
          ],
          'page': 1,
          'pageSize': 10,
          'hasMore': false,
        });
      });
      await pumpAuditPage(tester, client);

      expect(find.text('Documents illegible'), findsOneWidget);
    });

    testWidgets('revision badge shown for resubmission', (tester) async {
      final client = _StubHttpClient((method, url) async {
        return _json(200, {
          'events': [
            _event('r3', 'application_resubmitted', extra: {
              'previousStatus': 'changes_requested',
              'newStatus': 'pending_approval',
              'actorRole': 'Applicant',
              'revision': 1,
              'changedFieldsCount': 2,
            }),
          ],
          'page': 1,
          'pageSize': 10,
          'hasMore': false,
        });
      });
      await pumpAuditPage(tester, client);

      expect(find.textContaining('Revision 1'), findsOneWidget);
      expect(find.textContaining('2 fields updated'), findsOneWidget);
    });

    testWidgets('filter chips send the action query param', (tester) async {
      final client = _StubHttpClient((method, url) async {
        return _json(200, {'events': [], 'page': 1, 'pageSize': 10, 'hasMore': false});
      });
      await pumpAuditPage(tester, client);

      await tester.tap(find.text('Activated'));
      await tester.pumpAndSettle();
      expect(client.requests.last, contains('action=organization_activated'));

      await tester.tap(find.text('Changes Requested'));
      await tester.pumpAndSettle();
      expect(client.requests.last, contains('action=changes_requested'));

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(client.requests.last, isNot(contains('action=')));
    });

    testWidgets('search box sends the search query param', (tester) async {
      final client = _StubHttpClient((method, url) async {
        return _json(200, {'events': [], 'page': 1, 'pageSize': 10, 'hasMore': false});
      });
      await pumpAuditPage(tester, client);

      await tester.enterText(find.byType(TextField), 'SERV Demo');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(client.requests.last, contains('search=SERV'));
    });

    testWidgets('pagination requests the next page', (tester) async {
      final client = _StubHttpClient((method, url) async {
        final page = int.parse(url.queryParameters['page'] ?? '1');
        return _json(200, {
          'events': [_event('r1', 'submitted')],
          'page': page,
          'pageSize': 10,
          'hasMore': page == 1,
        });
      });
      await pumpAuditPage(tester, client);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(client.requests.last, contains('page=2'));
    });

    testWidgets('View Application navigates to the existing detail route',
        (tester) async {
      final client = _StubHttpClient((method, url) async {
        return _json(200, {
          'events': [_event('serv-demo', 'submitted')],
          'page': 1,
          'pageSize': 10,
          'hasMore': false,
        });
      });
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      HttpOverrides.global = _StubOverrides(client);

      String? navigatedTo;
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(body: PlatformAdminAuditPage()),
          onGenerateRoute: (settings) {
            navigatedTo = settings.name;
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('detail')),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('View Application'));
      await tester.pumpAndSettle();
      expect(navigatedTo, '/platform-admin/registrations/serv-demo');
    });

    testWidgets('shows an error when the API rejects the call', (tester) async {
      final client = _StubHttpClient(
        (method, url) async => _json(403, {'error': 'Not authorized'}),
      );
      await pumpAuditPage(tester, client);
      expect(find.textContaining('Not authorized'), findsOneWidget);
    });
  });
}
