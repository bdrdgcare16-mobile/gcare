import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serv_app/features/admin/others_page.dart';
import 'package:serv_app/features/admin/settings_page.dart';
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

  group('Settings — conditional visibility', () {
    testWidgets('Basic HRMS only: profile/workdays/reasons visible; '
        'leave, office hidden', (tester) async {
      OrganizationContext.current = _org(_basic);
      await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Workdays & Shift Permission'), findsOneWidget);
      expect(find.text('Reason Master'), findsOneWidget);
      expect(find.text('Leave Holiday'), findsNothing);
      expect(find.text('Office Location'), findsNothing);
    });

    testWidgets('Basic + leave_management: Leave Holiday visible',
        (tester) async {
      OrganizationContext.current = _org([..._basic, 'leave_management']);
      await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Leave Holiday'), findsOneWidget);
      expect(find.text('Office Location'), findsNothing);
    });

    testWidgets('Basic + location_tracking: Office Location visible',
        (tester) async {
      OrganizationContext.current = _org([..._basic, 'location_tracking']);
      await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Office Location'), findsOneWidget);
      expect(find.text('Leave Holiday'), findsNothing);
    });

    testWidgets('Basic + geo_fence: Office Location visible',
        (tester) async {
      OrganizationContext.current = _org([..._basic, 'geo_fence']);
      await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Office Location'), findsOneWidget);
      expect(find.text('Leave Holiday'), findsNothing);
    });
  });

  group('Others — conditional module entries', () {
    testWidgets('Basic HRMS only: Feedback visible, Events/Tasks/Rewards '
        'hidden', (tester) async {
      OrganizationContext.current = _org(_basic);
      await tester.pumpWidget(const MaterialApp(home: OthersPage()));
      await tester.pumpAndSettle();

      expect(find.text('Feedback'), findsOneWidget);
      expect(find.text('Event Updates'), findsNothing);
      expect(find.text('My Tasks'), findsNothing);
      expect(find.text('Rewards'), findsNothing);
    });

    testWidgets('events enabled: Event Updates visible', (tester) async {
      OrganizationContext.current = _org([..._basic, 'events']);
      await tester.pumpWidget(const MaterialApp(home: OthersPage()));
      await tester.pumpAndSettle();

      expect(find.text('Event Updates'), findsOneWidget);
      expect(find.text('My Tasks'), findsNothing);
    });
  });
}
