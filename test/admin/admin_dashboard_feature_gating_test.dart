import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serv_app/features/admin/admin_dashboard_page.dart';
import 'package:serv_app/features/admin/admin_feature_gate.dart';
import 'package:serv_app/features/admin/employee_management_page.dart';
import 'package:serv_app/features/admin/live_attendance_page.dart';
import 'package:serv_app/models/company_profile.dart';
import 'package:serv_app/models/organization_context.dart';

CompanyProfile _profile() =>
    CompanyProfile(name: 'ghhf', adminName: 'Admin');

OrganizationContext _org(List<String> features) => OrganizationContext(
      companyId: 'viki@gmail.com',
      organizationCode: 'SERV001',
      organizationName: 'ghhf',
      adminName: 'Admin',
      enabledFeatures: features,
    );

Future<void> _pumpDashboard(
  WidgetTester tester,
  List<String> features,
) async {
  final org = _org(features);
  OrganizationContext.current = org;
  await tester.pumpWidget(MaterialApp(
    home: AdminDashboard(companyProfile: _profile(), organization: org),
  ));
  await tester.pumpAndSettle();
}

Future<void> _openDrawer(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => OrganizationContext.clear());

  group('OrganizationContext', () {
    test('parses authoritative profile payload', () {
      final ctx = OrganizationContext.fromProfileJson({
        'id': 'viki@gmail.com',
        'code': 'SERV001',
        'companyName': 'ghhf',
        'adminName': 'Admin',
        'enabledFeatures': ['employee_master'],
      });
      expect(ctx.companyId, 'viki@gmail.com');
      expect(ctx.organizationCode, 'SERV001');
      expect(ctx.organizationName, 'ghhf');
      expect(ctx.isFeatureEnabled('employee_master'), isTrue);
      expect(ctx.isFeatureEnabled('payroll'), isFalse);
    });

    test('missing enabledFeatures = legacy org = unrestricted', () {
      final ctx = OrganizationContext.fromProfileJson({
        'id': 'acme',
        'companyName': 'Acme',
      });
      expect(ctx.enabledFeatures, isNull);
      expect(ctx.isFeatureEnabled('payroll'), isTrue);
    });
  });

  group('AdminDashboard — employee_master only (SERV001 shape)', () {
    testWidgets('no Home entry — landing is the first enabled module '
        '(Employee Management)', (tester) async {
      await _pumpDashboard(tester, ['employee_master']);
      // Landing = first enabled entry, not a Home/blank page.
      expect(find.byType(EmployeeListScreen), findsOneWidget);
      await _openDrawer(tester);
      expect(find.text('Home'), findsNothing);
      // Organization info / Enabled Modules live in Settings → Profile.
      expect(find.text('Organization'), findsNothing);
      expect(find.text('Enabled Modules'), findsNothing);
      // The internal canonical companyId must never surface.
      expect(find.text('viki@gmail.com'), findsNothing);
    });

    testWidgets(
        'landing does not build LiveAttendancePage for an org without '
        'attendance/location_tracking (no GET /attendance/live)',
        (tester) async {
      await _pumpDashboard(tester, ['employee_master']);
      expect(find.byType(LiveAttendancePage), findsNothing);
    });

    testWidgets('menu hides disabled modules, shows Employee Master',
        (tester) async {
      await _pumpDashboard(tester, ['employee_master']);
      await _openDrawer(tester);

      // universal
      expect(find.text('Home'), findsNothing);
      expect(find.text('Others'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      // enabled
      expect(find.text('Employee Management'), findsOneWidget);
      expect(find.text('Employee Onboarding'), findsOneWidget);
      // disabled
      expect(find.text('Live Attendance'), findsNothing);
      expect(find.text('Request and Leave Approvals'), findsNothing);
      expect(find.text('Attendance Reports'), findsNothing);
      expect(find.text('Payroll Management'), findsNothing);
    });
  });

  group('AdminDashboard — multi-feature org', () {
    testWidgets(
        'employee_master + attendance + leave_management exposes those '
        'modules only', (tester) async {
      await _pumpDashboard(
        tester,
        ['employee_master', 'attendance', 'leave_management'],
      );
      await _openDrawer(tester);

      expect(find.text('Live Attendance'), findsOneWidget);
      expect(find.text('Request and Leave Approvals'), findsOneWidget);
      expect(find.text('Attendance Reports'), findsOneWidget);
      expect(find.text('Employee Management'), findsOneWidget);
      expect(find.text('Payroll Management'), findsNothing);
      // attendance enabled → Live Attendance is the landing page
      expect(find.byType(LiveAttendancePage), findsOneWidget);
    });
  });

  group('FeatureGate — manual route protection', () {
    testWidgets('disabled feature shows access-denied surface',
        (tester) async {
      OrganizationContext.current = _org(['employee_master']);
      await tester.pumpWidget(const MaterialApp(
        home: FeatureGate(feature: 'payroll', child: Text('PAYROLL_BODY')),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Feature Not Enabled'), findsOneWidget);
      expect(find.text('PAYROLL_BODY'), findsNothing);
    });

    testWidgets('enabled feature renders child', (tester) async {
      OrganizationContext.current = _org(['employee_master']);
      await tester.pumpWidget(const MaterialApp(
        home: FeatureGate(
          feature: 'employee_master',
          child: Text('EMP_BODY'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('EMP_BODY'), findsOneWidget);
      expect(find.text('Feature Not Enabled'), findsNothing);
    });
  });

  group('Shared Live Attendance — attendance OR location_tracking', () {
    test('OrganizationContext.isAnyFeatureEnabled', () {
      expect(
        _org(['location_tracking']).isAnyFeatureEnabled(
          const ['attendance', 'location_tracking'],
        ),
        isTrue,
      );
      expect(
        _org(['attendance']).isAnyFeatureEnabled(
          const ['attendance', 'location_tracking'],
        ),
        isTrue,
      );
      expect(
        _org(['payroll']).isAnyFeatureEnabled(
          const ['attendance', 'location_tracking'],
        ),
        isFalse,
      );
      expect(
        _org([]).isAnyFeatureEnabled(const ['attendance', 'location_tracking']),
        isFalse,
      );
      // legacy org — no enabledFeatures field — unrestricted
      final legacy = OrganizationContext.fromProfileJson({
        'id': 'acme',
        'companyName': 'Acme',
      });
      expect(
        legacy.isAnyFeatureEnabled(const ['attendance', 'location_tracking']),
        isTrue,
      );
    });

    testWidgets(
        'location_tracking + payroll: Live Attendance + Payroll shown, '
        'full Attendance and unrelated modules hidden', (tester) async {
      await _pumpDashboard(tester, ['location_tracking', 'payroll']);
      await _openDrawer(tester);

      // universal
      expect(find.text('Home'), findsNothing);
      expect(find.text('Others'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      // enabled
      expect(find.text('Live Attendance'), findsOneWidget);
      expect(find.text('Payroll Management'), findsOneWidget);
      // full Attendance stays attendance-only
      expect(find.text('Attendance Reports'), findsNothing);
      // unrelated modules hidden
      expect(find.text('Employee Management'), findsNothing);
      expect(find.text('Request and Leave Approvals'), findsNothing);
      expect(find.text('Employee Onboarding'), findsNothing);
      // location_tracking → Live Attendance is the landing page
      expect(find.byType(LiveAttendancePage), findsOneWidget);
    });

    testWidgets(
        'attendance only: Live Attendance + Attendance Reports shown',
        (tester) async {
      await _pumpDashboard(tester, ['attendance']);
      await _openDrawer(tester);

      expect(find.text('Live Attendance'), findsOneWidget);
      expect(find.text('Attendance Reports'), findsOneWidget);
      expect(find.text('Payroll Management'), findsNothing);
      expect(find.text('Employee Management'), findsNothing);
    });

    testWidgets('no features: Live Attendance hidden', (tester) async {
      await _pumpDashboard(tester, []);
      await _openDrawer(tester);

      expect(find.text('Live Attendance'), findsNothing);
      expect(find.text('Payroll Management'), findsNothing);
      expect(find.text('Attendance Reports'), findsNothing);
    });

    testWidgets('FeatureGate.anyOf allows location_tracking only',
        (tester) async {
      OrganizationContext.current = _org(['location_tracking']);
      await tester.pumpWidget(const MaterialApp(
        home: FeatureGate.anyOf(
          features: ['attendance', 'location_tracking'],
          child: Text('LIVE_BODY'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('LIVE_BODY'), findsOneWidget);
      expect(find.text('Feature Not Enabled'), findsNothing);
    });

    testWidgets('FeatureGate.anyOf allows attendance only', (tester) async {
      OrganizationContext.current = _org(['attendance']);
      await tester.pumpWidget(const MaterialApp(
        home: FeatureGate.anyOf(
          features: ['attendance', 'location_tracking'],
          child: Text('LIVE_BODY'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('LIVE_BODY'), findsOneWidget);
    });

    testWidgets('FeatureGate.anyOf blocks when neither is enabled',
        (tester) async {
      OrganizationContext.current = _org(['payroll']);
      await tester.pumpWidget(const MaterialApp(
        home: FeatureGate.anyOf(
          features: ['attendance', 'location_tracking'],
          child: Text('LIVE_BODY'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Feature Not Enabled'), findsOneWidget);
      expect(find.text('LIVE_BODY'), findsNothing);
    });

    testWidgets('attendance-only route still blocked for location_tracking',
        (tester) async {
      OrganizationContext.current = _org(['location_tracking']);
      await tester.pumpWidget(const MaterialApp(
        home: FeatureGate(
          feature: 'attendance',
          child: Text('REPORT_BODY'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Feature Not Enabled'), findsOneWidget);
      expect(find.text('REPORT_BODY'), findsNothing);
    });
  });
}
