import 'package:flutter_test/flutter_test.dart';
import 'package:serv_app/utils/attendance_time.dart';

void main() {
  test('eligible active session restores until exactly 24 hours', () {
    final record = <String, dynamic>{'sessionState': 'active',
      'checkInTsUtc': '2026-10-21T16:30:00Z', 'expiresAt': '2026-10-22T16:30:00Z'};
    expect(attendanceAutoInactive(record, DateTime.parse('2026-10-22T16:29:00Z')), isFalse);
    expect(attendanceAutoInactive(record, DateTime.parse('2026-10-22T16:30:00Z')), isTrue);
  });

  test('auto-inactive restoration preserves history without requiring checkout', () {
    final record = <String, dynamic>{'sessionState': 'auto_inactive',
      'date': '2026-10-21', 'checkInTsUtc': '2026-10-21T16:30:00Z'};
    expect(attendanceAutoInactive(record), isTrue);
    expect(record['checkOutTsUtc'], isNull);
    final start = parseAttendanceTime(record['checkInTsUtc'], null, record['date'])!;
    expect([start.day, start.hour], [21, 22]);
  });

  test('legacy and checked-out records do not infer automatic expiry', () {
    expect(attendanceAutoInactive({'checkIn': '22:00:00'}), isFalse);
    expect(attendanceAutoInactive({'sessionState': 'checked_out',
      'expiresAt': '2020-01-01T00:00:00Z'}), isFalse);
    expect(attendanceAutoInactive({'sessionState': 'active', 'expiresAt': 'bad'}), isFalse);
  });
  test('UTC timestamps display in Asia/Kolkata independently of device timezone', () {
    final start = parseAttendanceTime('2026-10-21T16:30:00Z', null, null)!;
    final end = parseAttendanceTime('2026-10-22T00:30:00Z', null, null)!;
    expect([start.year, start.month, start.day, start.hour], [2026, 10, 21, 22]);
    expect([end.year, end.month, end.day, end.hour], [2026, 10, 22, 6]);
    expect(end.difference(start), const Duration(hours: 8));
  });

  test('reopening after midnight restores the original date rather than today', () {
    final start = parseAttendanceTime(null, '22:00:00', '2026-10-21')!;
    final now = attendanceWallTime(DateTime.parse('2026-10-21T19:30:00Z'));
    expect(start.day, 21);
    expect(now.day, 22);
    expect(now.difference(start), const Duration(hours: 3));
  });

  test('same-day duration and legacy HH:mm remain supported', () {
    final start = parseAttendanceTime(null, '09:00', '2026-10-21')!;
    final end = parseAttendanceTime(null, '18:00:00', '2026-10-21')!;
    expect(end.difference(start), const Duration(hours: 9));
  });

  test('full timestamps override stale clock-only fields and retain actual checkout date', () {
    final end = parseAttendanceTime('2026-10-22T00:30:00Z', '23:00:00', '2026-10-21')!;
    expect(end.day, 22);
    expect(end.hour, 6);
  });

  test('missing and malformed legacy dates and times do not invent attendance', () {
    expect(parseAttendanceTime(null, null, null), isNull);
    expect(parseAttendanceTime('bad', '25:00:00', '2026-10-21'), isNull);
    expect(parseAttendanceTime(null, '09:70', '2026-10-21'), isNull);
    expect(parseAttendanceTime(null, '09:00', '2026-02-31'), isNull);
  });
}
