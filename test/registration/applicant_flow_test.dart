// test/registration/applicant_flow_test.dart
//
// 3D-C follow-up — authenticated organization applicant flow.
// Covers: server-side application resolution routing, Role Selection
// bypass for org_applicant, JWT header attachment, and Admin-dashboard
// exclusion for the restricted role.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:serv_app/features/admin/admin_dashboard_page.dart';
import 'package:serv_app/features/auth/auth_guard.dart';
import 'package:serv_app/features/onboarding/onboarding_guard.dart';
import 'package:serv_app/features/onboarding/registration/controllers/registration_draft_controller.dart';
import 'package:serv_app/features/onboarding/registration/guards/registration_resume_guard.dart';
import 'package:serv_app/features/onboarding/registration/models/organization_registration_draft.dart';
import 'package:serv_app/features/onboarding/registration/screens/org_applicant_auth_page.dart';
import 'package:serv_app/features/onboarding/registration/screens/organization_information_page.dart';
import 'package:serv_app/features/onboarding/registration/screens/registration_review_page.dart';
import 'package:serv_app/features/onboarding/registration/screens/registration_status_page.dart';
import 'package:serv_app/features/onboarding/registration/services/organization_registration_service.dart';
import 'package:serv_app/features/onboarding/screens/select_user_type_page.dart';
import 'package:serv_app/models/company_data.dart';

// ── Minimal HttpClient stubs (same pattern as test/platform_admin) ──────────

/// Captures header writes so tests can assert the Authorization header.
class _StubHeaders implements HttpHeaders {
  _StubHeaders(this.captured);
  final Map<String, String> captured;
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    captured[name.toLowerCase()] = value.toString();
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    captured[name.toLowerCase()] = value.toString();
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    captured.forEach((k, v) => action(k, [v]));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _StubRequest implements HttpClientRequest {
  _StubRequest(this._onClose);
  final Future<HttpClientResponse> Function(List<int> body) _onClose;
  final List<int> _bodySink = [];
  final Map<String, String> headersCapture = {};
  @override
  HttpHeaders get headers => _StubHeaders(headersCapture);
  @override
  Future<void> addStream(Stream<List<int>> stream) =>
      stream.forEach(_bodySink.addAll);
  @override
  Future<HttpClientResponse> close() => _onClose(_bodySink);
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
  HttpHeaders get headers => _StubHeaders({});
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
  final Future<HttpClientResponse> Function(String method, Uri url,
      Map<String, String> headers, String body) handler;
  final List<String> requests = [];
  Map<String, String> lastHeaders = {};

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    requests.add('$method ${url.path}');
    late _StubRequest req;
    req = _StubRequest((body) async {
      lastHeaders = req.headersCapture;
      return handler(method, url, req.headersCapture, utf8.decode(body));
    });
    return req;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _StubHttpOverrides extends HttpOverrides {
  _StubHttpOverrides(this.client);
  final _StubHttpClient client;
  @override
  HttpClient createHttpClient(SecurityContext? context) => client;
}

// A JWT that expires far in the future so JwtDecoder.isExpired() is false.
String _fakeJwt(String role) {
  String b64(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${b64({'alg': 'none'})}.${b64({
        'userId': 'uid-1',
        'email': 'applicant@example.com',
        'role': role,
        'companyId': 'platform',
        'exp': 9999999999,
      })}.sig';
}

Map<String, dynamic> _app(String status, {String id = 'reg-1'}) => {
      'registrationId': id,
      'status': status,
      'currentStep': 2,
      'maxCompletedStep': 1,
      'organizationName': 'Acme Org',
      'submittedAt': null,
      'review': null,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _StubHttpClient httpClient;

  /// Routes stub responses by path suffix.
  void stub({
    Map<String, dynamic>? application,
    bool noApplication = false,
    String status = '',
  }) {
    httpClient = _StubHttpClient((method, url, headers, body) async {
      final path = url.path;
      if (path.endsWith('/org-registration/mine')) {
        return _StubResponse(
            200,
            utf8.encode(jsonEncode(
                {'application': noApplication ? null : application})));
      }
      if (path.contains('/org-registration/draft/')) {
        return _StubResponse(
            200,
            utf8.encode(jsonEncode({
              'registrationId': 'reg-1',
              'status': status.isNotEmpty ? status : 'draft',
              'organization': {
                'name': 'Acme Org',
                'type': 'Private Limited',
                'industry': 'IT',
                'employeeCount': 10,
                'branchCount': 1,
                'registeredAddress': 'x',
                'officialEmail': 'hr@acme.example.com',
                'contactNumber': '+91 80 0000 0000',
              },
              'requestedFeatures': ['attendance'],
              'adminContact': {
                'fullName': 'J',
                'designation': 'HR',
                'email': 'j@acme.example.com',
                'mobile': '9876543210',
              },
              'currentStep': 2,
              'maxCompletedStep': 1,
              'verification': {},
              'documents': {},
            })));
      }
      if (path.endsWith('/org-registration/submit')) {
        return _StubResponse(
            200,
            utf8.encode(jsonEncode({
              'registrationId': 'reg-1',
              'status': 'pending_approval',
            })));
      }
      if (path.endsWith('/org-registration/draft')) {
        return _StubResponse(
            201,
            utf8.encode(jsonEncode({
              'registrationId': 'new-reg',
              'resumeToken': 'new-token',
              'status': 'draft',
            })));
      }
      if (path.endsWith('/auth/me')) {
        return _StubResponse(
            200,
            utf8.encode(jsonEncode({
              'email': 'applicant@example.com',
              'role': 'org_applicant',
              'status': 'active',
              'companyId': 'platform',
            })));
      }
      return _StubResponse(404, utf8.encode('{"error":"not found"}'));
    });
    HttpOverrides.global = _StubHttpOverrides(httpClient);
  }

  void resetState() {
    final controller = RegistrationDraftController.instance;
    controller.draft = OrganizationRegistrationDraft();
    controller.hydrated = true;
    CompanyData.token = '';
    CompanyData.role = '';
    CompanyData.companyId = '';
    CompanyData.email = '';
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    resetState();
  });

  tearDown(() => resetState());

  group('service', () {
    test('attaches the applicant JWT to requests when signed in', () async {
      stub(application: _app('draft'));
      CompanyData.token = 'serv-jwt-token';
      CompanyData.role = 'org_applicant';
      await OrganizationRegistrationService.instance.getMyApplication();
      expect(httpClient.lastHeaders['authorization'],
          'Bearer serv-jwt-token');
    });
  });

  group('RegistrationResumeGuard (authenticated)', () {
    Future<void> pumpGuard(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'role': 'org_applicant',
        'token': _fakeJwt('org_applicant'),
        'companyId': 'platform',
        'email': 'applicant@example.com',
        'status': 'active',
      });
      await tester.pumpWidget(
          const MaterialApp(home: RegistrationResumeGuard()));
      await tester.pumpAndSettle();
    }

    testWidgets('no application → Start Organization Registration',
        (tester) async {
      stub(noApplication: true);
      await pumpGuard(tester);
      expect(find.byType(OrganizationInformationPage), findsOneWidget);
      expect(find.byType(SelectUserTypePage), findsNothing);
    });

    testWidgets('draft → resumes the wizard (Role Selection skipped)',
        (tester) async {
      stub(application: _app('draft'), status: 'draft');
      await pumpGuard(tester);
      // currentStep 2 → Admin Information page; importantly NOT Role
      // Selection and NOT the status page.
      expect(find.byType(SelectUserTypePage), findsNothing);
      expect(find.byType(RegistrationStatusPage), findsNothing);
    });

    testWidgets('pending_approval → Application Status', (tester) async {
      stub(application: _app('pending_approval'));
      await pumpGuard(tester);
      expect(find.byType(RegistrationStatusPage), findsOneWidget);
      expect(find.byType(SelectUserTypePage), findsNothing);
    });

    testWidgets('changes_requested → status page with edit affordance',
        (tester) async {
      stub(
          application: _app('changes_requested')
            ..['review'] = {
              'decision': 'changes_requested',
              'reasons': [],
              'note': 'Fix the registration certificate',
            });
      await pumpGuard(tester);
      expect(find.byType(RegistrationStatusPage), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.textContaining('Fix the registration certificate'),
          findsWidgets);
      expect(find.text('Edit application'), findsOneWidget);
    });

    testWidgets('rejected → rejected status', (tester) async {
      stub(
          application: _app('rejected')
            ..['review'] = {
              'decision': 'rejected',
              'reasons': ['Incomplete documents'],
              'note': 'Incomplete documents',
            });
      await pumpGuard(tester);
      expect(find.byType(RegistrationStatusPage), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.textContaining('not accepted'), findsWidgets);
      expect(find.textContaining('Incomplete documents'), findsWidgets);
    });

    testWidgets('approved → awaiting activation (not admin dashboard)',
        (tester) async {
      stub(application: _app('approved'));
      await pumpGuard(tester);
      expect(find.byType(RegistrationStatusPage), findsOneWidget);
      expect(find.byType(AdminDashboard), findsNothing);
      await tester.pumpAndSettle();
      expect(find.textContaining('Approved'), findsWidgets);
      expect(find.textContaining('not yet activated'), findsWidgets);
    });
  });

  group('unauthenticated guard', () {
    testWidgets('no session and no draft → applicant account gate',
        (tester) async {
      stub(noApplication: true);
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
          const MaterialApp(home: RegistrationResumeGuard()));
      await tester.pumpAndSettle();
      expect(find.byType(OrgApplicantAuthPage), findsOneWidget);
    });
  });

  group('OnboardingGuard', () {
    testWidgets('persisted org_applicant never sees Role Selection',
        (tester) async {
      stub(application: _app('pending_approval'));
      SharedPreferences.setMockInitialValues({
        'role': 'org_applicant',
        'token': _fakeJwt('org_applicant'),
        'serv_onboarding_completed': true,
        'serv_onboarding_user_type': 'registerOrganization',
      });
      await tester.pumpWidget(const MaterialApp(home: OnboardingGuard()));
      await tester.pumpAndSettle();
      expect(find.byType(SelectUserTypePage), findsNothing);
    });
  });

  group('AuthGuard', () {
    testWidgets('org_applicant routes to registration, never AdminDashboard',
        (tester) async {
      stub(application: _app('pending_approval'));
      SharedPreferences.setMockInitialValues({
        'role': 'org_applicant',
        'token': _fakeJwt('org_applicant'),
        'companyId': 'platform',
        'status': 'active',
        'email': 'applicant@example.com',
      });
      await tester.pumpWidget(const MaterialApp(home: AuthGuard()));
      await tester.pumpAndSettle();
      expect(find.byType(AdminDashboard), findsNothing);
      expect(find.byType(SelectUserTypePage), findsNothing);
    });
  });

  group('OrgApplicantAuthPage', () {
    testWidgets('renders sign-in and create-account affordances',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OrgApplicantAuthPage()));
      await tester.pumpAndSettle();
      expect(find.text('Sign in'), findsWidgets);
      expect(find.text('Create account'), findsWidgets);
    });
  });

  group('in-place correction / resubmission (3D-C follow-up)', () {
    void applicantSession() {
      SharedPreferences.setMockInitialValues({
        'role': 'org_applicant',
        'token': _fakeJwt('org_applicant'),
        'companyId': 'platform',
        'email': 'applicant@example.com',
        'status': 'active',
      });
      CompanyData.token = _fakeJwt('org_applicant');
      CompanyData.role = 'org_applicant';
    }

    void changesRequestedDraft() {
      final c = RegistrationDraftController.instance;
      c.draft = OrganizationRegistrationDraft()
        ..registrationId = 'reg-1'
        ..applicationStatus = 'changes_requested';
      c.hydrated = true;
    }

    testWidgets('Edit Application hydrates existing server values',
        (tester) async {
      stub(application: _app('changes_requested'), status: 'changes_requested');
      applicantSession();
      changesRequestedDraft();
      final c = RegistrationDraftController.instance;

      await tester.runAsync(() => c.hydrateFromServer('reg-1'));

      expect(c.draft.registrationId, 'reg-1');
      expect(c.draft.organizationName, 'Acme Org');
      expect(c.draft.adminEmail, 'j@acme.example.com');
      expect(c.draft.requestedFeatures, contains('attendance'));
      expect(c.draft.applicationStatus, 'changes_requested');
    });

    testWidgets('editing a changes_requested application only PATCHes — '
        'never creates a new draft', (tester) async {
      stub(application: _app('changes_requested'), status: 'changes_requested');
      applicantSession();
      changesRequestedDraft();
      final c = RegistrationDraftController.instance;
      c.draft.organizationName = 'Corrected Org';

      await tester.runAsync(() => c.persist());

      expect(
        httpClient.requests
            .where((r) => r.startsWith('POST') && r.endsWith('/draft'))
            .length,
        0,
      );
      expect(
        httpClient.requests
            .where((r) => r.startsWith('PATCH') && r.contains('/draft/reg-1'))
            .length,
        1,
      );
      expect(c.draft.registrationId, 'reg-1');
    });

    testWidgets('first submission shows "Submit Application"',
        (tester) async {
      stub(application: _app('draft'), status: 'draft');
      applicantSession();
      final c = RegistrationDraftController.instance;
      c.draft = OrganizationRegistrationDraft()
        ..registrationId = 'reg-1'
        ..applicationStatus = 'draft';
      c.hydrated = true;

      await tester.pumpWidget(
          const MaterialApp(home: RegistrationReviewPage()));
      await tester.pumpAndSettle();
      expect(find.text('Submit Application'), findsOneWidget);
      expect(find.text('Update & Send for Review'), findsNothing);
    });

    testWidgets('changes_requested shows "Update & Send for Review"',
        (tester) async {
      stub(application: _app('changes_requested'), status: 'changes_requested');
      applicantSession();
      changesRequestedDraft();

      await tester.pumpWidget(
          const MaterialApp(home: RegistrationReviewPage()));
      await tester.pumpAndSettle();
      expect(find.text('Update & Send for Review'), findsOneWidget);
      expect(find.text('Submit New Application'), findsNothing);
    });

    testWidgets('successful resubmission routes to Application Status with '
        'pending review and no active changes warning', (tester) async {
      stub(
          application: _app('pending_approval'),
          status: 'changes_requested');
      applicantSession();
      changesRequestedDraft();

      await tester.pumpWidget(
          const MaterialApp(home: RegistrationReviewPage()));
      await tester.pumpAndSettle();

      // Accept the declaration, then resubmit.
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Update & Send for Review'));
      await tester.tap(find.text('Update & Send for Review'));
      await tester.pumpAndSettle();

      expect(find.byType(RegistrationStatusPage), findsOneWidget);
      await tester.pumpAndSettle();
      // Pending review headline — the changes-requested warning is gone.
      expect(find.textContaining('submitted for review'), findsWidgets);
      expect(find.text('Requested corrections'), findsNothing);
      expect(
          RegistrationDraftController.instance.draft.applicationStatus,
          'pending_approval');
      expect(
          RegistrationDraftController.instance.draft.registrationId, 'reg-1');
    });
  });
}
