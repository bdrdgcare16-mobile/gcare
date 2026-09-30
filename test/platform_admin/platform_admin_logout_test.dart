// test/platform_admin/platform_admin_logout_test.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serv_app/features/platform_admin/platform_admin_app.dart';
import 'package:serv_app/features/platform_admin/platform_admin_login_page.dart';
import 'package:serv_app/features/platform_admin/platform_admin_session.dart';
import 'package:serv_app/features/platform_admin/platform_admin_shell.dart';
import 'package:serv_app/features/platform_admin/platform_admin_theme.dart';
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

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    requests.add('$method ${url.path}${url.hasQuery ? '?${url.query}' : ''}');
    final buf = <int>[];
    final response = await handler(method, url);
    return _StubRequest(response, buf, () {});
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

_StubHttpClient _emptyListClient() => _StubHttpClient(
      (method, url) async =>
          _json(200, {'registrations': [], 'events': [], 'hasMore': false}),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides? previous;

  setUp(() {
    previous = HttpOverrides.current;
    PlatformAdminSession.save(token: 'pa-jwt', email: 'pa@serv.test');
  });

  tearDown(() {
    HttpOverrides.global = previous;
    CompanyData.token = '';
    CompanyData.role = '';
    CompanyData.email = '';
    CompanyData.companyId = '';
  });

  Future<void> pumpPortal(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    HttpOverrides.global = _StubOverrides(_emptyListClient());
    await tester.pumpWidget(const PlatformAdminApp());
    await tester.pumpAndSettle();
  }

  group('PlatformAdminSession.signOut', () {
    test('clears stored session keys and in-memory CompanyData', () async {
      expect(PlatformAdminSession.isSignedIn, isTrue);
      expect(CompanyData.token, 'pa-jwt');
      CompanyData.companyId = 'platform';

      // FirebaseAuth.instance throws (no Firebase app in tests) — the
      // session still clears fully because local state is wiped first.
      await PlatformAdminSession.signOut();

      expect(PlatformAdminSession.isSignedIn, isFalse);
      expect(PlatformAdminSession.email, isEmpty);
      expect(CompanyData.token, isEmpty);
      expect(CompanyData.role, isEmpty);
      expect(CompanyData.email, isEmpty);
      expect(CompanyData.companyId, isEmpty);
    });
  });

  group('PlatformAdminShell logout', () {
    testWidgets(
        'clicking Logout clears the session and lands on the login page',
        (tester) async {
      await pumpPortal(tester);
      expect(find.byType(PlatformAdminShell), findsOneWidget);

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      expect(find.byType(PlatformAdminLoginPage), findsOneWidget);
      expect(find.byType(PlatformAdminShell), findsNothing);
      expect(PlatformAdminSession.isSignedIn, isFalse);
      expect(CompanyData.token, isEmpty);
    });

    testWidgets(
        'previous authenticated routes are removed — browser Back cannot '
        'reopen the shell', (tester) async {
      await pumpPortal(tester);
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();
      expect(find.byType(PlatformAdminLoginPage), findsOneWidget);

      final nav =
          tester.state<NavigatorState>(find.byType(Navigator).first);
      expect(nav.canPop(), isFalse);

      // Simulate browser Back — nothing to pop, stay on login.
      expect(await nav.maybePop(), isFalse);
      await tester.pumpAndSettle();
      expect(find.byType(PlatformAdminLoginPage), findsOneWidget);
      expect(find.byType(PlatformAdminShell), findsNothing);
    });

    testWidgets(
        'a protected route pushed after logout redirects back to login',
        (tester) async {
      await pumpPortal(tester);
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      final nav =
          tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.pushNamed('/platform-admin/dashboard');
      await tester.pumpAndSettle();

      expect(find.byType(PlatformAdminLoginPage), findsOneWidget);
      expect(find.byType(PlatformAdminShell), findsNothing);
    });

    testWidgets('Logout row has hover and pressed feedback', (tester) async {
      await pumpPortal(tester);

      AnimatedContainer logoutContainer() => tester.widget<AnimatedContainer>(
            find
                .ancestor(
                  of: find.byIcon(Icons.logout),
                  matching: find.byType(AnimatedContainer),
                )
                .first,
          );
      Color? bg() =>
          (logoutContainer().decoration as BoxDecoration).color;

      expect(bg(), Colors.transparent);

      // Hover → soft highlight + pointer cursor via MouseRegion.
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.moveTo(tester.getCenter(find.byIcon(Icons.logout)));
      await tester.pump();
      expect(bg(), PlatformAdminColors.primarySofter);

      // Press down → stronger pressed tint.
      final gesture = await tester.startGesture(
          tester.getCenter(find.byIcon(Icons.logout)));
      await tester.pump();
      expect(bg(), PlatformAdminColors.primarySoft);
      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
