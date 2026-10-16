import 'package:flutter_test/flutter_test.dart';
import 'package:serv_app/features/admin/my_task_page.dart';

void main() {
  group('parseEmployeeOptions', () {
    test('parses a plain list payload into "EMPID — Name" options', () {
      final options = parseEmployeeOptions([
        {'empid': 'EMP001', 'name': 'Arun Kumar'},
        {'empid': 'EMP002', 'name': 'Priya S'},
        {'empid': 'EMP003', 'name': 'Karthik R'},
      ]);

      expect(options.map((o) => o.label), [
        'EMP001 — Arun Kumar',
        'EMP002 — Priya S',
        'EMP003 — Karthik R',
      ]);
      expect(options.map((o) => o.empid), ['EMP001', 'EMP002', 'EMP003']);
    });

    test('supports a wrapped {"data": [...]} payload', () {
      final options = parseEmployeeOptions({
        'data': [
          {'empid': 'EMP001', 'name': 'Arun Kumar'},
        ],
      });
      expect(options, hasLength(1));
      expect(options.single.empid, 'EMP001');
    });

    test('returns empty list for empty or malformed payloads', () {
      expect(parseEmployeeOptions([]), isEmpty);
      expect(parseEmployeeOptions(null), isEmpty);
      expect(parseEmployeeOptions({'unexpected': true}), isEmpty);
      expect(parseEmployeeOptions('not json'), isEmpty);
    });

    test('skips records without an employee ID and dedupes by empid', () {
      final options = parseEmployeeOptions([
        {'empid': '', 'name': 'No ID'},
        {'name': 'Missing empid entirely'},
        {'empid': 'EMP001', 'name': 'Arun Kumar'},
        {'empid': 'EMP001', 'name': 'Duplicate Name'},
      ]);

      expect(options, hasLength(1));
      expect(options.single.empid, 'EMP001');
      expect(options.single.name, 'Arun Kumar');
    });

    test('falls back to bare empid label when name is missing', () {
      final options = parseEmployeeOptions([
        {'empid': 'EMP007'},
      ]);

      expect(options.single.label, 'EMP007');
    });

    test('keeps employees with duplicate names as separate unique options', () {
      final options = parseEmployeeOptions([
        {'empid': 'EMP004', 'name': 'Priya S'},
        {'empid': 'EMP005', 'name': 'Priya S'},
      ]);

      expect(options, hasLength(2));
      expect(options.map((o) => o.label),
          ['EMP004 — Priya S', 'EMP005 — Priya S']);
      expect(options.map((o) => o.empid).toSet(), hasLength(2));
    });

    test('sorts options by employee ID and reads alt ID/name fields', () {
      final options = parseEmployeeOptions([
        {'employeeId': 'EMP010', 'fullName': 'Zed'},
        {'empId': 'EMP002', 'employeeName': 'Priya S'},
        {'empid': 'EMP001', 'name': 'Arun Kumar'},
      ]);

      expect(options.map((o) => o.empid), ['EMP001', 'EMP002', 'EMP010']);
      expect(options.map((o) => o.name), ['Arun Kumar', 'Priya S', 'Zed']);
    });
  });
}
