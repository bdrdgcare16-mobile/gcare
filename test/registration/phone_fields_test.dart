import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:serv_app/features/onboarding/registration/controllers/registration_draft_controller.dart';
import 'package:serv_app/features/onboarding/registration/models/organization_registration_draft.dart';
import 'package:serv_app/features/onboarding/registration/screens/admin_information_page.dart';
import 'package:serv_app/features/onboarding/registration/screens/feature_selection_page.dart';
import 'package:serv_app/features/onboarding/registration/screens/organization_information_page.dart';
import 'package:serv_app/features/onboarding/registration/screens/registration_verification_page.dart';
import 'package:serv_app/features/onboarding/registration/widgets/registration_phone_field.dart';

/// Minimal HTTP stub — records request bodies and replies with a usable
/// draft payload for every registration endpoint.
class _StubOverrides extends HttpOverrides {
  String? lastBody;

  @override
  HttpClient createHttpClient(SecurityContext? context) => _StubClient(this);
}

class _StubClient implements HttpClient {
  final _StubOverrides owner;
  _StubClient(this.owner);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _StubRequest(owner, method, url);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _StubRequest implements HttpClientRequest {
  final _StubOverrides owner;
  @override
  final String method;
  @override
  final Uri uri;
  final _buf = BytesBuilder();
  _StubRequest(this.owner, this.method, this.uri);

  @override
  void add(List<int> data) => _buf.add(data);
  @override
  void write(Object? object) => _buf.add(utf8.encode('$object'));

  @override
  Future<HttpClientResponse> close() async {
    owner.lastBody = utf8.decode(_buf.takeBytes());
    final bool isCreate =
        method == 'POST' && uri.path.endsWith('/org-registration/draft');
    final payload = isCreate
        ? {'registrationId': 'reg-phone-1', 'resumeToken': 'tok'}
        : {
            'registrationId': 'reg-phone-1',
            'verification': {
              'orgEmail': {'verified': false, 'target': ''},
              'adminEmail': {'verified': false, 'target': ''},
              'adminMobile': {'verified': false, 'target': ''},
            },
            'documents': {},
          };
    return _FakeResponse(utf8.encode(jsonEncode(payload)),
        isCreate ? 201 : 200);
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

/// Enters digits into the IntlPhoneField's inner national-number input.
Future<void> _enterPhone(WidgetTester tester, String digits) async {
  final field = find.descendant(
    of: find.byType(IntlPhoneField),
    matching: find.byType(TextFormField),
  );
  await tester.enterText(field, digits);
  await tester.pump();
}

/// The IntlPhoneField's inner national-number input widget.
Finder _phoneInput() => find.descendant(
      of: find.byType(IntlPhoneField),
      matching: find.byType(TextFormField),
    );

Future<void> _pickCountry(WidgetTester tester, String name) async {
  await tester.tap(find.text('+91'));
  await tester.pumpAndSettle();
  // The picker is a lazily-built list — filter via its search field.
  await tester.enterText(find.byType(TextField).last, name);
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

void main() {
  late _StubOverrides http;

  setUp(() {
    RegistrationDraftController.instance.draft =
        OrganizationRegistrationDraft();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    http = _StubOverrides();
    HttpOverrides.global = http;
  });

  tearDown(() {
    HttpOverrides.global = null;
  });

  group('Country selector presence', () {
    testWidgets('Organization contact number has a country-code selector',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: OrganizationInformationPage()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RegistrationPhoneField), findsOneWidget);
      expect(find.byType(IntlPhoneField), findsOneWidget);
      expect(find.text('+91'), findsOneWidget); // default: India
    });

    testWidgets('HR/Admin mobile number has a country-code selector',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdminInformationPage()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RegistrationPhoneField), findsOneWidget);
      expect(find.byType(IntlPhoneField), findsOneWidget);
      expect(find.text('+91'), findsOneWidget);
    });
  });

  group('Country-based validation — Admin mobile', () {
    Future<void> fillRequired(WidgetTester tester, {String? phone}) async {
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Jane Tester');
      await tester.enterText(fields.at(1), 'HR Manager');
      await tester.enterText(fields.at(2), 'jane@acme.example.com');
      await tester.pump();
      if (phone != null) await _enterPhone(tester, phone);
    }

    testWidgets('valid Indian mobile passes and advances', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdminInformationPage()),
      );
      await tester.pumpAndSettle();

      await fillRequired(tester, phone: '9876543210');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.byType(RegistrationVerificationPage), findsOneWidget);
      // Normalized international value persisted to the draft.
      expect(
        RegistrationDraftController.instance.draft.adminMobile,
        '+919876543210',
      );
    });

    testWidgets('invalid Indian mobile shows a country-specific error',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdminInformationPage()),
      );
      await tester.pumpAndSettle();

      // 10 digits but starts with 1 — invalid for India.
      await fillRequired(tester, phone: '1234567890');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(
        find.text('Enter a valid mobile number for India'),
        findsOneWidget,
      );
      expect(find.byType(AdminInformationPage), findsOneWidget);
    });

    testWidgets('changing the country changes the validation rules',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AdminInformationPage()),
      );
      await tester.pumpAndSettle();

      // '123456789' (9 digits, starts 1) is invalid for India…
      await fillRequired(tester, phone: '123456789');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(
        find.text('Enter a valid mobile number for India'),
        findsOneWidget,
      );

      // …but valid for Malaysia (+60) — 9 national digits starting with 1.
      await _pickCountry(tester, 'Malaysia');
      expect(find.text('+60'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.byType(RegistrationVerificationPage), findsOneWidget);
      expect(
        RegistrationDraftController.instance.draft.adminMobile,
        '+60123456789',
      );
    });
  });

  group('Country-based validation — Organization contact number', () {
    testWidgets('invalid Indian number shows a country-specific error',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: OrganizationInformationPage()),
      );
      await tester.pumpAndSettle();

      await _enterPhone(tester, '12345');
      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(
        find.text('Enter a valid contact number for India'),
        findsOneWidget,
      );
    });

    testWidgets(
        'valid Indian number advances to Feature Selection and persists '
        'the normalized number', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: OrganizationInformationPage()),
      );
      await tester.pumpAndSettle();

      // Fill every required field so Next passes validation end-to-end.
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Acme Corp'); // org name
      await tester.tap(
        find.widgetWithText(
            DropdownButtonFormField<String>, 'Organization Type *'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Private Limited').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<String>, 'Industry *'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Information Technology').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Employee Count *'),
        '10',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'No. of Branches *'),
        '1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Registered Address *'),
        '1 Main Street',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Official Email Address *'),
        'hr@acme.example.com',
      );
      await tester.pump();
      await _enterPhone(tester, '9876543210');

      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.byType(FeatureSelectionPage), findsOneWidget);
      expect(
        RegistrationDraftController.instance.draft.contactNumber,
        '+919876543210',
      );
    });
  });

  group('Draft restore', () {
    testWidgets('stored international mobile restores country + number',
        (tester) async {
      RegistrationDraftController.instance.draft.adminMobile =
          '+60123456789';

      await tester.pumpWidget(
        const MaterialApp(home: AdminInformationPage()),
      );
      await tester.pumpAndSettle();

      // Country selector restored to Malaysia; national number prefilled.
      expect(find.text('+60'), findsOneWidget);
      final phoneField = tester.widget<TextFormField>(_phoneInput());
      expect(phoneField.initialValue, '123456789');
    });

    testWidgets('legacy bare 10-digit draft restores as India',
        (tester) async {
      RegistrationDraftController.instance.draft.adminMobile =
          '9876543210';

      await tester.pumpWidget(
        const MaterialApp(home: AdminInformationPage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('+91'), findsOneWidget);
      final phoneField = tester.widget<TextFormField>(_phoneInput());
      expect(phoneField.initialValue, '9876543210');
    });
  });

  group('Phone value submitted to backend', () {
    test('draft body sends normalized +<dial><national> for both fields',
        () async {
      final draft = OrganizationRegistrationDraft()
        ..contactNumber = '+919876543210'
        ..adminMobile = '+60123456789';
      RegistrationDraftController.instance.draft = draft;

      // Drive a save through the controller → POST /org-registration/draft.
      await RegistrationDraftController.instance.persist();

      final body = jsonDecode(http.lastBody!) as Map<String, dynamic>;
      expect(
        (body['organization'] as Map)['contactNumber'],
        '+919876543210',
      );
      expect((body['adminContact'] as Map)['mobile'], '+60123456789');
    });
  });
}
