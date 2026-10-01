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

  group('My SERV — leave_management gating', () {
    testWidgets('leave_management enabled: Type of Request visible',
        (tester) async {
      OrganizationContext.current = _org([..._basic, 'leave_management']);
      await tester.pumpWidget(const MaterialApp(home: MyServPage()));
      await tester.pumpAndSettle();

      expect(find.text('Type of Request'), findsOneWidget);
      expect(find.text('My Request'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
    });

    testWidgets('leave_management disabled: Type of Request hidden, '
        'other tiles unaffected', (tester) async {
      OrganizationContext.current = _org(_basic);
      await tester.pumpWidget(const MaterialApp(home: MyServPage()));
      await tester.pumpAndSettle();

      expect(find.text('Type of Request'), findsNothing);
      expect(find.text('My Request'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
    });

    testWidgets('legacy org (null context): Type of Request visible',
        (tester) async {
      OrganizationContext.current = null;
      await tester.pumpWidget(const MaterialApp(home: MyServPage()));
      await tester.pumpAndSettle();

      expect(find.text('Type of Request'), findsOneWidget);
    });
  });
}
