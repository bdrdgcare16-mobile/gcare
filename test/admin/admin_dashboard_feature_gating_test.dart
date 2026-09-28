import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serv_app/features/admin/admin_dashboard_page.dart';
import 'package:serv_app/features/admin/admin_feature_gate.dart';
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
    testWidgets('shows org name, code, and internal org ID on Home',
        (tester) async {
      await _pumpDashboard(tester, ['employee_master']);
      expect(find.text('ghhf'), findsWidgets);
      expect(find.text('Organization Code'), findsOneWidget);
      expect(find.text('SERV001'), findsWidgets);
      expect(find.text('Organization ID'), findsOneWidget);
      expect(find.text('viki@gmail.com'), findsWidgets);
    });

    testWidgets('enabled modules listed on Home', (tester) async {
      await _pumpDashboard(tester, ['employee_master']);
      expect(find.text('Enabled Modules'), findsOneWidget);
      expect(find.text('Employee Master'), findsOneWidget);
    });

    testWidgets(
        'default home is generic — does not build LiveAttendancePage '
        '(no automatic GET /attendance/live)', (tester) async {
      await _pumpDashboard(tester, ['employee_master']);
      expect(find.byType(LiveAttendancePage), findsNothing);
    });

    testWidgets('menu hides disabled modules, shows Employee Master',
        (tester) async {
      await _pumpDashboard(tester, ['employee_master']);
      await _openDrawer(tester);

      // universal
      expect(find.text('Home'), findsOneWidget);
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
      // enabled-module chips on home
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Leave Management'), findsOneWidget);
      // still generic home — not a live attendance page
      expect(find.byType(LiveAttendancePage), findsNothing);
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
}
