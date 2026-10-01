import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serv_app/features/users/myserv_page.dart';
import 'package:serv_app/models/organization_context.dart';

const _basic = ['attendance', 'employee_master', 'feedback', 'shifts'];

OrganizationContext _org(List<String> features) => OrganizationContext(
      companyId: 'org@test.dev',
      organizationCode: 'SERV999',
      organizationName: 'Test Org',
      adminName: 'Admin',
      enabledFeatures: features,
    );

void main() {
  tearDown(() => OrganizationContext.clear());

  // The tile list is a lazily-built GridView — give the test surface enough
  // height that every tile is actually instantiated.
  Future<void> pumpMyServ(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: MyServPage()));
    await tester.pumpAndSettle();
  }

  group('My SERV — leave_management gating', () {
    testWidgets('leave_management enabled: Type of Request visible',
        (tester) async {
      OrganizationContext.current = _org([..._basic, 'leave_management']);
      await pumpMyServ(tester);

      expect(find.text('Type of Request'), findsOneWidget);
      expect(find.text('My Request'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
    });

    testWidgets('leave_management disabled: Type of Request hidden, '
        'other tiles unaffected', (tester) async {
      OrganizationContext.current = _org(_basic);
      await pumpMyServ(tester);

      expect(find.text('Type of Request'), findsNothing);
      expect(find.text('My Request'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
    });

    testWidgets('legacy org (null context): all tiles visible',
        (tester) async {
      OrganizationContext.current = null;
      await pumpMyServ(tester);

      expect(find.text('Type of Request'), findsOneWidget);
      expect(find.text('My Track'), findsOneWidget);
      expect(find.text('My Task'), findsOneWidget);
      expect(find.text('Events Update'), findsOneWidget);
      expect(find.text('Rewards'), findsOneWidget);
      expect(find.text('Payslip'), findsOneWidget);
      expect(find.text('My Request'), findsOneWidget);
    });

    testWidgets('each optional tile hides when its feature is disabled',
        (tester) async {
      // Basic-only org: every optional tile hidden, core tiles stay.
      OrganizationContext.current = _org(_basic);
      await pumpMyServ(tester);

      expect(find.text('My Track'), findsNothing);
      expect(find.text('My Task'), findsNothing);
      expect(find.text('Events Update'), findsNothing);
      expect(find.text('Rewards'), findsNothing);
      expect(find.text('Payslip'), findsNothing);
      expect(find.text('Type of Request'), findsNothing);
      // attendance is Basic → My Request stays visible.
      expect(find.text('My Request'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
    });

    testWidgets('each optional tile appears when its feature is enabled',
        (tester) async {
      OrganizationContext.current = _org([
        ..._basic,
        'leave_management',
        'location_tracking',
        'tasks',
        'events',
        'performance',
        'payroll',
      ]);
      await pumpMyServ(tester);

      expect(find.text('My Track'), findsOneWidget);
      expect(find.text('My Task'), findsOneWidget);
      expect(find.text('Events Update'), findsOneWidget);
      expect(find.text('Rewards'), findsOneWidget);
      expect(find.text('Payslip'), findsOneWidget);
      expect(find.text('Type of Request'), findsOneWidget);
    });
  });
}
