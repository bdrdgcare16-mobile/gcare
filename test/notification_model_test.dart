import 'package:flutter_test/flutter_test.dart';
import 'package:serv_app/services/notification_service.dart';

void main() {
  group('AppNotification.fromJson', () {
    test('parses a fully populated tracking-event notification', () {
      final n = AppNotification.fromJson({
        'id': 'n1',
        'type': 'LOCATION_DISABLED',
        'title': 'Employee GPS Turned Off',
        'body': 'Alice (EMP001) turned OFF location services.',
        'entityType': 'tracking_event',
        'entityId': 'EMP001_2026-10-12',
        'data': {
          'empid': 'EMP001',
          'eventType': 'location_disabled',
          'eventTs': '2026-10-12T08:00:00Z',
          'dateIso': '2026-10-12',
        },
        'isRead': false,
        'pushStatus': 'sent',
        'createdAt': '2026-10-12T08:00:01.000Z',
        'readAt': null,
      });

      expect(n.id, 'n1');
      expect(n.type, 'LOCATION_DISABLED');
      expect(n.kindLabel, 'GPS Disabled');
      expect(n.isTrackingEvent, isTrue);
      expect(n.isRead, isFalse);
      expect(n.empid, 'EMP001');
      expect(n.eventType, 'location_disabled');
      expect(n.dateIso, '2026-10-12');
      expect(n.createdAtDate, isNotNull);
    });

    test('parses a GPS-enabled event', () {
      final n = AppNotification.fromJson({
        'id': 'n2',
        'type': 'LOCATION_ENABLED',
        'entityType': 'tracking_event',
        'data': {'empid': 'EMP002', 'dateIso': '2026-10-13'},
      });
      expect(n.kindLabel, 'GPS Enabled');
      expect(n.empid, 'EMP002');
    });

    test('survives a minimal/empty payload without throwing', () {
      final n = AppNotification.fromJson({});
      expect(n.id, '');
      expect(n.type, '');
      expect(n.kindLabel, 'Notification');
      expect(n.isRead, isFalse);
      expect(n.isTrackingEvent, isFalse);
      expect(n.data, isEmpty);
      expect(n.createdAtDate, isNull);
      expect(n.empid, '');
    });

    test('non-map data field degrades to empty map', () {
      final n = AppNotification.fromJson({
        'id': 'n3',
        'type': 'TASK_ASSIGNED',
        'data': 'not-a-map',
      });
      expect(n.data, isEmpty);
      expect(n.kindLabel, 'Task Assigned');
    });

    test('unparseable createdAt returns null date', () {
      final n = AppNotification.fromJson({
        'id': 'n4',
        'type': 'x',
        'createdAt': 'not-a-date',
      });
      expect(n.createdAtDate, isNull);
    });
  });
}
