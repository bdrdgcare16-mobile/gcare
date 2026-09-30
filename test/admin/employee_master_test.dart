import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serv_app/features/admin/employee_management_page.dart';
import 'package:serv_app/models/organization_context.dart';

/// Minimal HttpClient stub — the create/edit screen calls
/// fetchShiftGroups() on init; returning `[]` lets it succeed offline so
/// the shift dropdown resolves the prefilled value.
class _FakeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _FakeHttpClient();
}

class _FakeHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeRequest();
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _FakeResponse();
  @override
  HttpHeaders get headers => _FakeHeaders();
  @override
  List<Cookie> get cookies => [];
  @override
  Future<void> addStream(Stream<List<int>> s) async {}
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
  final _bytes = utf8.encode('[]');

  @override
  int get statusCode => 200;
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
  }) {
    return Stream.value(_bytes).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Employee _emp() => Employee(
      companyId: 'viki@gmail.com',
      name: 'Alice',
      id: 'EMP001',
      email: 'alice@x.com',
      mobile: '+91 9876543210',
      location: 'Chennai',
      dept: 'HR',
      designation: 'Exec',
      status: 'Active',
      shiftGroup: 'Morning',
      docId: 'docA1',
      password: 'secret123',
    );

void main() {
  setUp(() => HttpOverrides.global = _FakeHttpOverrides());
  tearDown(() {
    OrganizationContext.clear();
    HttpOverrides.global = null;
  });

  group('Employee payload contract', () {
    test('toUpdateBody contains only allowed business fields', () {
      final body = _emp().toUpdateBody();
      // backend EMPLOYEE_UPDATE_ALLOWED allowlist
      expect(
        body.keys.toSet(),
        {
          'name',
          'empid',
          'email',
          'phone',
          'location',
          'dept',
          'designation',
          'shiftGroup',
          'status',
        },
      );
      // protected/ownership/auth fields are never sent on edit
      expect(body.containsKey('companyId'), isFalse);
      expect(body.containsKey('role'), isFalse);
      expect(body.containsKey('password'), isFalse);
      expect(body.containsKey('id'), isFalse);
      expect(body['status'], 'active');
    });

    test('toCreateBody includes companyId context for legacy check', () {
      final body = _emp().toCreateBody();
      expect(body['companyId'], 'viki@gmail.com');
      expect(body['empid'], 'EMP001');
      expect(body['role'], 'employee');
    });

    test('fromServer parses the employees row shape', () {
      final e = Employee.fromServer({
        'id': 'docA1',
        'empid': 'EMP001',
        'name': 'Alice',
        'email': 'a@x.com',
        'phone': '999',
        'status': 'inactive',
        'companyId': 'viki@gmail.com',
      });
      expect(e.docId, 'docA1');
      expect(e.id, 'EMP001');
      expect(e.status, 'Inactive');
    });
  });

  group('CreateEmployeeScreen — edit mode (3D-E bug fix)', () {
    testWidgets(
        'edit submit pops the Employee instead of calling create',
        (tester) async {
      Employee? popped;
      bool popDone = false;

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: TextButton(
              onPressed: () async {
                popped = await Navigator.push<Employee>(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => CreateEmployeeScreen(editEmployee: _emp()),
                  ),
                );
                popDone = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Edit mode renders existing values.
      expect(find.text('Edit Employee'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('EMP001'), findsOneWidget);

      // The phone widget re-parses the mobile without dial code; make it
      // carry a valid 10-digit IN number.
      // (IntlPhoneField default validator checks length.)
      await tester.enterText(
        find.byType(TextFormField).at(4),
        '9876543210',
      );

      // Pick the shift so the dropdown validator passes.
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Morning').last);
      await tester.pumpAndSettle();

      // Company ID field is read-only org context (readOnly lives on the
      // inner TextField built by TextFormField).
      final innerField = tester.widget<TextField>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'viki@gmail.com'),
          matching: find.byType(TextField),
        ),
      );
      expect(innerField.readOnly, isTrue);

      await tester.ensureVisible(find.text('Update'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();

      // Debug: surface any validation errors that blocked the submit.
      if (!popDone) {
        final errors = tester
            .widgetList<Text>(find.byType(Text))
            .where((t) =>
                (t.data ?? '').contains('Required') ||
                (t.data ?? '').contains('Invalid') ||
                (t.data ?? '').contains('exists'))
            .map((t) => t.data)
            .toList();
        fail('submit did not pop; validation errors: $errors');
      }

      // Popped an Employee (not bool true) — the parent then calls
      // updateEmployee; createEmployee is never invoked in edit mode.
      expect(popDone, isTrue);
      expect(popped, isA<Employee>());
      expect(popped!.id, 'EMP001');
      expect(popped!.companyId, 'viki@gmail.com');
    });

    testWidgets('create mode prefills Company ID from org context',
        (tester) async {
      OrganizationContext.current = const OrganizationContext(
        companyId: 'viki@gmail.com',
        organizationCode: 'SERV001',
        organizationName: 'ghhf',
        adminName: 'Admin',
        enabledFeatures: ['employee_master'],
      );
      await tester.pumpWidget(
        const MaterialApp(home: CreateEmployeeScreen()),
      );
      await tester.pump();
      expect(find.text('viki@gmail.com'), findsOneWidget);
    });
  });
}
