import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serv_app/features/admin/profile_page.dart';
import 'package:serv_app/models/company_data.dart';
import 'package:serv_app/models/organization_context.dart';

/// Stub HTTP layer — `/company/profile` returns a complete profile;
/// every other endpoint returns an empty object.
class _StubOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _StubClient();
}

class _StubClient implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
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
    final body = url.path.contains('/company/profile')
        ? jsonEncode({
            'success': true,
            'data': {
              'companyName': 'Acme Corp',
              'email': 'acme@x.com',
              'phone': '+91 1',
              'website': 'acme.example.com',
              'adminName': 'Admin One',
              'designation': 'HR Manager',
            },
          })
        : '{}';
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

void main() {
  setUp(() {
    HttpOverrides.global = _StubOverrides();
    OrganizationContext.current = const OrganizationContext(
      companyId: 'viki@gmail.com',
      organizationCode: 'SERV001',
      organizationName: 'Acme Corp',
      adminName: 'Admin',
      enabledFeatures: [
        'attendance',
        'employee_master',
        'feedback',
        'shifts',
        'leave_management',
      ],
    );
  });

  tearDown(() {
    OrganizationContext.clear();
    HttpOverrides.global = null;
    CompanyData.token = '';
  });

  group('CompanyProfilePage — organization info + enabled modules', () {
    testWidgets('shows Organization Code and Enabled Modules from org '
        'context; internal companyId never visible', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CompanyProfilePage()));
      await tester.pumpAndSettle();

      // Organization info loads (stubbed /company/profile).
      expect(find.text('Acme Corp'), findsWidgets);
      expect(find.text('Organization Code'), findsOneWidget);
      expect(find.text('SERV001'), findsWidgets);

      // Enabled Modules section, friendly labels.
      expect(find.text('Enabled Modules'), findsOneWidget);
      expect(find.text('Attendance'), findsWidgets);
      expect(find.text('Employee Master'), findsWidgets);
      expect(find.text('Feedback'), findsWidgets);
      expect(find.text('Shift Management'), findsWidgets);
      expect(find.text('Leave Management'), findsWidgets);

      // Internal canonical companyId never surfaces as an identifier.
      expect(find.text('viki@gmail.com'), findsNothing);
    });
  });
}
