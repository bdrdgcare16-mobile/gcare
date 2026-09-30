// test/platform_admin/platform_admin_sidebar_test.dart
//
// Hover-to-expand sidebar coverage: collapsed icon rail by default,
// whole-rail expansion on hover/focus with labels, instant page swaps
// (no route transition animation), and no overflow at desktop or
// narrow widths.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serv_app/features/platform_admin/platform_admin_app.dart';
import 'package:serv_app/features/platform_admin/platform_admin_audit_page.dart';
import 'package:serv_app/features/platform_admin/platform_admin_dashboard_page.dart';
import 'package:serv_app/features/platform_admin/platform_admin_registrations_page.dart';
import 'package:serv_app/features/platform_admin/platform_admin_session.dart';
import 'package:serv_app/features/platform_admin/platform_admin_theme.dart';
import 'package:serv_app/models/company_data.dart';

// ── Minimal HttpClient stubs (mirrors platform_admin_logout_test.dart) ──

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
    final response = await handler(method, url);
    return _StubRequest(response, <int>[], () {});
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides? previous;

  setUp(() {
    previous = HttpOverrides.current;
    PlatformAdminSession.save(token: 'pa-jwt', email: 'pa@serv.test');
    HttpOverrides.global = _StubOverrides(_StubHttpClient(
      (method, url) async =>
          _json(200, {'registrations': [], 'events': [], 'hasMore': false}),
    ));
  });

  tearDown(() {
    HttpOverrides.global = previous;
    CompanyData.token = '';
    CompanyData.role = '';
    CompanyData.email = '';
    CompanyData.companyId = '';
  });

  Future<void> pumpPortal(WidgetTester tester,
      {Size size = const Size(1400, 1000)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const PlatformAdminApp());
    await tester.pumpAndSettle();
  }

  Finder sidebar() => find.byKey(const ValueKey('admin-sidebar'));

  double sidebarWidth(WidgetTester tester) =>
      tester.getSize(sidebar()).width;

  double labelOpacity(WidgetTester tester, String label) =>
      tester
          .widget<AnimatedOpacity>(
            find
                .ancestor(
                  of: find.descendant(
                    of: sidebar(),
                    matching: find.text(label),
                  ),
                  matching: find.byType(AnimatedOpacity),
                )
                .first,
          )
          .opacity;

  group('PlatformAdminShell expanding rail', () {
    testWidgets('renders a ~68px icon rail with labels hidden by default',
        (tester) async {
      await pumpPortal(tester);

      // Icon-only destinations are present.
      expect(
          find.widgetWithIcon(
              PlatformAdminSidebarItem, Icons.dashboard_outlined),
          findsOneWidget);
      expect(
          find.widgetWithIcon(PlatformAdminSidebarItem,
              Icons.domain_verification_outlined),
          findsOneWidget);
      expect(
          find.widgetWithIcon(
              PlatformAdminSidebarItem, Icons.history_outlined),
          findsOneWidget);
      expect(
          find.widgetWithIcon(PlatformAdminSidebarItem, Icons.logout),
          findsOneWidget);

      // Labels exist for semantics but are fully transparent while
      // collapsed.
      expect(labelOpacity(tester, 'Dashboard'), 0);
      expect(labelOpacity(tester, 'Organization Registrations'), 0);
      expect(labelOpacity(tester, 'Audit / Review History'), 0);
      expect(labelOpacity(tester, 'Logout'), 0);
      expect(labelOpacity(tester, 'Platform Admin'), 0);

      // Rail is compact; content keeps the fixed gutter.
      expect(sidebarWidth(tester), 68);
      // The rail must fill the viewport height — a shrink-wrapped Stack
      // would stop the hover region short of the bottom of the window.
      expect(tester.getSize(sidebar()).height, 1000);
      // Logout is pinned at the bottom.
      expect(
          tester.getBottomLeft(find.widgetWithIcon(
              PlatformAdminSidebarItem, Icons.logout)).dy,
          greaterThan(950));
      final bodyLeft =
          tester.getTopLeft(find.byType(PlatformAdminDashboardPage)).dx;
      expect(bodyLeft, 68);
    });

    testWidgets('no Tooltip widgets exist inside the sidebar',
        (tester) async {
      await pumpPortal(tester);
      expect(
        find.descendant(
          of: sidebar(),
          matching: find.byType(Tooltip),
        ),
        findsNothing,
      );
      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets(
        'hovering anywhere on the rail expands it with labels — '
        'content does not move', (tester) async {
      await pumpPortal(tester);
      final bodyLeftBefore =
          tester.getTopLeft(find.byType(PlatformAdminDashboardPage)).dx;

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.moveTo(tester.getCenter(find.widgetWithIcon(
          PlatformAdminSidebarItem, Icons.history_outlined)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(sidebarWidth(tester), 256);
      expect(labelOpacity(tester, 'Audit / Review History'), 1);
      expect(labelOpacity(tester, 'Dashboard'), 1);
      expect(labelOpacity(tester, 'Logout'), 1);
      expect(labelOpacity(tester, 'Platform Admin'), 1);
      // Body did not move — the rail overlays it.
      expect(tester.getTopLeft(find.byType(PlatformAdminDashboardPage)).dx,
          bodyLeftBefore);

      // Leaving the rail collapses it again.
      await mouse.moveTo(const Offset(700, 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(sidebarWidth(tester), 68);
      expect(labelOpacity(tester, 'Dashboard'), 0);
    });

    testWidgets('keyboard focus expands the sidebar', (tester) async {
      await pumpPortal(tester);
      expect(sidebarWidth(tester), 68);

      // Tab until a sidebar item receives focus (the dashboard page has
      // no other focusable controls).
      for (var i = 0; i < 8 && sidebarWidth(tester) == 68; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(sidebarWidth(tester), 256);
      expect(labelOpacity(tester, 'Dashboard'), 1);
    });

    testWidgets('nav clicks swap pages immediately — no route transition',
        (tester) async {
      await pumpPortal(tester);
      expect(find.byType(PlatformAdminDashboardPage), findsOneWidget);

      // A single pump is enough: the PageRouteBuilder uses zero-duration
      // transitions, so there is no animation to settle.
      await tester.tap(find.widgetWithIcon(PlatformAdminSidebarItem, Icons.domain_verification_outlined));
      await tester.pump();
      expect(
          find.byType(PlatformAdminRegistrationsPage), findsOneWidget);
      expect(find.byType(PlatformAdminDashboardPage), findsNothing);

      await tester.tap(find.widgetWithIcon(PlatformAdminSidebarItem, Icons.history_outlined));
      await tester.pump();
      expect(find.byType(PlatformAdminAuditPage), findsOneWidget);
      expect(find.byType(PlatformAdminRegistrationsPage), findsNothing);

      await tester.tap(find.widgetWithIcon(PlatformAdminSidebarItem, Icons.dashboard_outlined));
      await tester.pump();
      expect(find.byType(PlatformAdminDashboardPage), findsOneWidget);
      expect(find.byType(PlatformAdminAuditPage), findsNothing);
    });

    testWidgets('no AnimatedSwitcher wraps the page body', (tester) async {
      await pumpPortal(tester);
      final bodySwitcher = find.ancestor(
        of: find.byType(PlatformAdminDashboardPage),
        matching: find.byType(AnimatedSwitcher),
      );
      expect(bodySwitcher, findsNothing);
    });

    testWidgets('lays out without overflow at narrow widths',
        (tester) async {
      await pumpPortal(tester, size: const Size(760, 700));
      expect(find.byType(PlatformAdminDashboardPage), findsOneWidget);
      expect(sidebarWidth(tester), 68);
      // A RenderFlex overflow would have thrown during pump already.
    });

    testWidgets(
        'touch-width screens (<600px): hover does not expand; brand tap '
        'toggles the rail', (tester) async {
      await pumpPortal(tester, size: const Size(500, 700));

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.moveTo(tester.getCenter(find.widgetWithIcon(
          PlatformAdminSidebarItem, Icons.history_outlined)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(sidebarWidth(tester), 68);

      // Brand icon acts as the drawer toggle.
      await tester.tap(find.byIcon(Icons.admin_panel_settings));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(sidebarWidth(tester), 256);
      expect(labelOpacity(tester, 'Dashboard'), 1);

      // Selecting a destination auto-collapses on narrow screens.
      await tester.tap(find.widgetWithIcon(
          PlatformAdminSidebarItem, Icons.domain_verification_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(sidebarWidth(tester), 68);
      expect(
          find.byType(PlatformAdminRegistrationsPage), findsOneWidget);
    });
  });
}
