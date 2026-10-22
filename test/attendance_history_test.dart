import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:serv_app/features/users/my_attendance_detail_page.dart';

void main() {
  for (final autoInactive in [true, false]) {
    testWidgets('history restores ${autoInactive ? 'auto-inactive' : 'overnight checked-out'} session on its original date', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final record = <String, dynamic>{
        'date': '2026-10-21',
        'checkIn': '22:00:00',
        'checkInTsUtc': '2026-10-21T16:30:00Z',
        'sessionState': autoInactive ? 'auto_inactive' : 'checked_out',
        if (!autoInactive) ...{
          'checkOut': '06:00:00',
          'checkOutTsUtc': '2026-10-22T00:30:00Z',
          'checkOutDate': '2026-10-22',
        },
      };
      final client = MockClient((request) async => http.Response(jsonEncode(
        request.url.path.endsWith('/auth/me') ? {'shiftGroup': 'Night'} : [record]), 200));
      addTearDown(client.close);
      for (var reopen = 0; reopen < 2; reopen++) {
        await tester.pumpWidget(MaterialApp(home: MyAttendanceDetailPage(
          key: ValueKey(reopen), empId: 'E1', date: DateTime(2026, 10, 21),
          baseUrl: 'http://localhost', httpClient: client,
        )));
        await tester.pumpAndSettle();
        expect(find.text('10:00 PM'), findsOneWidget);
        if (autoInactive) {
          expect(find.text('Auto-Inactivated'), findsOneWidget);
          expect(find.text('06:00 AM'), findsNothing);
          expect(find.text('Total hours: -'), findsOneWidget);
          expect(find.text('Total hours: 24 Hrs 00 Mins'), findsNothing);
        } else {
          expect(find.text('06:00 AM'), findsOneWidget);
          expect(find.text('Total hours: 8 Hrs 00 Mins'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      }
    });
  }
}
