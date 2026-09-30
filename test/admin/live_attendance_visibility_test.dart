import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serv_app/features/admin/live_attendance_page.dart';
import 'package:serv_app/models/company_profile.dart';
import 'package:serv_app/models/organization_context.dart';

/// Stub HTTP layer — `/attendance/live` returns a live feed that includes
/// one employee ON LEAVE so the leave widgets would render if ungated.
/// Every other endpoint returns an empty list.
class _StubOverrides extends HttpOverrides {
  final List<Uri> requests = [];

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _StubClient(this);
}

class _StubClient implements HttpClient {
  final _StubOverrides owner;
  _StubClient(this.owner);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    owner.requests.add(url);
    return _StubRequest(url);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _StubRequest implements HttpClientRequest {
  final Uri url;
  _StubRequest(this.url);

  @override
  Future<HttpClientResponse> close() async {
    final body = url.path.contains('/attendance/live')
        ? jsonEncode([
            {
              'empid': 'E1',
              'name': 'On Leave Emp',
              'status': 'Leave',
            },
            {
              'empid': 'E2',
              'name': 'Present Emp',
              'status': 'Present',
              'checkIn': '09:00',
            },
          ])
        : '[]';
    return _StubResponse(utf8.encode(body), 200);
  }

  @override
  HttpHeaders get headers => _StubHeaders();
  @override
  List<Cookie> get cookies => [];
  @override
  Future<void> addStream(Stream<List<int>> s) async {}
  @override
  void add(List<int> data) {}
  @override
  void write(Object? object) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _StubHeaders implements HttpHeaders {
  @override
  void forEach(void Function(String name, List<String> values) action) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _StubResponse extends Stream<List<int>> implements HttpClientResponse {
  final List<int> _bytes;
  final int _status;
  _StubResponse(this._bytes, this._status);

  @override
  int get statusCode => _status;
  @override
  int get contentLength => _bytes.length;
  @override
  HttpHeaders get headers => _StubHeaders();
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

const _basic = ['attendance', 'employee_master', 'feedback', 'shifts'];

OrganizationContext _org(List<String> features) => OrganizationContext(
      companyId: 'org@test.dev',
      organizationCode: 'SERV999',
      organizationName: 'Test Org',
      adminName: 'Admin',
      enabledFeatures: features,
    );

CompanyProfile _profile() =>
    CompanyProfile(name: 'Test Org', adminName: 'Admin');

void main() {
  late _StubOverrides overrides;

  setUp(() {
    overrides = _StubOverrides();
    HttpOverrides.global = overrides;
  });

  tearDown(() {
    OrganizationContext.clear();
    HttpOverrides.global = null;
  });

  group('Live Attendance — feature composition', () {
    testWidgets(
        'Basic HRMS only: attendance metrics shown, leave widgets hidden',
        (tester) async {
      OrganizationContext.current = _org(_basic);
      await tester.pumpWidget(
          MaterialApp(home: LiveAttendancePage(companyProfile: _profile())));
      await tester.pumpAndSettle();

      // Core attendance metrics render.
      expect(find.text('Absent'), findsWidgets);
      expect(find.text('Present'), findsWidgets);

      // Leave widgets suppressed — even though the feed contains a
      // 'Leave'-status record.
      expect(find.text('On Leave'), findsNothing);

      // Live feed was fetched; no leave/tracking endpoints were hit.
      expect(
        overrides.requests.any((u) => u.path.contains('/attendance/live')),
        isTrue,
      );
      expect(
        overrides.requests.any((u) => u.path.contains('/tracking')),
        isFalse,
      );
      expect(
        overrides.requests.any((u) => u.path.contains('/leaves')),
        isFalse,
      );
    });

    testWidgets(
        'Basic + leave_management: leave widgets visible', (tester) async {
      OrganizationContext.current = _org([..._basic, 'leave_management']);
      await tester.pumpWidget(
          MaterialApp(home: LiveAttendancePage(companyProfile: _profile())));
      await tester.pumpAndSettle();

      expect(find.text('On Leave'), findsWidgets);
    });
  });
}
