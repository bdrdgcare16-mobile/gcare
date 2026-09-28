import 'package:flutter_test/flutter_test.dart';
import 'package:serv_app/features/admin/live_attendance_page.dart';

void main() {
  group('AttendanceRecord.fromJson (post-activation dashboard contract)', () {
    test('parses a record shaped like a provisioned org-admin membership row', () {
      // 3D-D activation writes empid/employeeId/name/status on the admin's
      // employees row, so /attendance/live must never emit a null empid.
      final r = AttendanceRecord.fromJson({
        'empid': 'ADMIN001',
        'name': 'Admin 1',
        'status': 'Absent',
        'checkIn': null,
        'checkOut': null,
        'late': false,
        'early': false,
        'permissionCount': 0,
      });
      expect(r.empid, 'ADMIN001');
      expect(r.name, 'Admin 1');
      expect(r.status, 'Absent');
      expect(r.checkIn, isNull);
      expect(r.checkOut, isNull);
      expect(r.late, isFalse);
      expect(r.permissionCount, 0);
    });

    test('optional checkIn/checkOut fields tolerate null', () {
      final r = AttendanceRecord.fromJson({
        'empid': 'E1',
        'name': 'x',
        'status': 'Present',
      });
      expect(r.checkIn, isNull);
      expect(r.checkOut, isNull);
    });
  });
}
