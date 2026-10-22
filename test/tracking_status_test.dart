import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:serv_app/features/admin/tracking_status.dart';
import 'package:serv_app/features/users/background_tasks.dart';
import 'package:serv_app/services/tracking_payload.dart';
import 'package:serv_app/services/tracking_post_result.dart';

/// Phase 2 client logic: /tracking/live row parsing, status labels,
/// freshness text, and the pinned session-date that keeps an overnight
/// shift writing to its original tracking document.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TrackingLiveRow.fromJson', () {
    test('parses a full row', () {
      final row = TrackingLiveRow.fromJson({
        'empid': 'E1',
        'status': 'active',
        'interrupted': false,
        'pathMapCount': 7,
        'suspiciousCount': 1,
        'flaggedTypes': ['mock_location'],
        'lastUpdateAt': '2026-10-15T09:00:00.000Z',
        'lastHeartbeatAt': '2026-10-15T09:00:00.000Z',
        'lastGpsFixAt': '2026-10-15T08:58:00.000Z',
        'lastLocationAt': '2026-10-15T08:59:00.000Z',
        'lastGpsState': 'ok',
        'lastPoint': {
          'lat': 13.08,
          'lng': 80.27,
          'ts': '2026-10-15T08:59:00.000Z',
        },
        'endedAt': null,
      });
      expect(row.empid, 'E1');
      expect(row.status, 'active');
      expect(row.pathMapCount, 7);
      expect(row.suspiciousCount, 1);
      expect(row.flaggedTypes, contains('mock_location'));
      expect(row.lastUpdateAt, isNotNull);
      expect(row.lastHeartbeatAt, isNotNull);
      expect(row.lastGpsFixAt, isNotNull);
      expect(row.lastLocationAt, isNotNull);
      expect(row.lastGpsState, 'ok');
      expect(row.lastPointAt, isNotNull);
      expect(row.lastLat, closeTo(13.08, 0.0001));
      expect(row.lastLng, closeTo(80.27, 0.0001));
      expect(row.endedAt, isNull);
    });

    test('tolerates missing fields', () {
      final row = TrackingLiveRow.fromJson({'empid': 'E2'});
      expect(row.status, 'unknown');
      expect(row.lastUpdateAt, isNull);
      expect(row.lastHeartbeatAt, isNull);
      expect(row.lastGpsFixAt, isNull);
      expect(row.lastLocationAt, isNull);
      expect(row.lastGpsState, isNull);
      expect(row.lastPointAt, isNull);
      expect(row.flaggedTypes, isEmpty);
    });
  });

  group('trackingStatusLabel', () {
    test('maps the current backend vocabulary', () {
      expect(trackingStatusLabel('healthy'), 'Tracking Healthy');
      expect(trackingStatusLabel('gps_delayed'), 'GPS Update Delayed');
      expect(trackingStatusLabel('gps_unavailable'), 'GPS Unavailable');
      expect(trackingStatusLabel('permission_revoked'),
          'Permission Revoked');
      expect(trackingStatusLabel('interrupted'), 'Tracking Interrupted');
      expect(trackingStatusLabel('checked_out'), 'Checked Out');
      expect(trackingStatusLabel('unknown'), 'Status Unknown');
      expect(trackingStatusLabel('anything-else'), 'Status Unknown');
    });

    test('keeps pre-upgrade strings readable (deployment skew)', () {
      expect(trackingStatusLabel('active'), 'Tracking Active');
      expect(trackingStatusLabel('stale'), 'Location Stale');
      expect(trackingStatusLabel('gps_disabled'), 'GPS Disabled');
    });
  });

  group('trackingFreshnessLabel', () {
    final now = DateTime(2026, 10, 15, 12, 0, 0);
    test('null -> No updates yet', () {
      expect(trackingFreshnessLabel(null, now: now), 'No updates yet');
    });
    test('<60s -> just now', () {
      expect(
          trackingFreshnessLabel(now.subtract(const Duration(seconds: 30)),
              now: now),
          'Updated just now');
    });
    test('minutes / hours / days', () {
      expect(
          trackingFreshnessLabel(now.subtract(const Duration(minutes: 5)),
              now: now),
          'Updated 5 min ago');
      expect(
          trackingFreshnessLabel(now.subtract(const Duration(hours: 3)),
              now: now),
          'Updated 3 hr ago');
      expect(
          trackingFreshnessLabel(now.subtract(const Duration(days: 2)),
              now: now),
          'Updated 2 d ago');
    });
  });

  group('GPS-fix freshness and contact labels', () {
    final now = DateTime(2026, 10, 15, 12, 0, 0);
    test('GPS fix freshness wording', () {
      expect(trackingGpsFreshnessLabel(null, now: now), 'No GPS fix yet');
      expect(
          trackingGpsFreshnessLabel(
              now.subtract(const Duration(seconds: 30)), now: now),
          'GPS fix just now');
      expect(
          trackingGpsFreshnessLabel(
              now.subtract(const Duration(minutes: 18)), now: now),
          'GPS fix 18 min ago');
      expect(
          trackingGpsFreshnessLabel(
              now.subtract(const Duration(hours: 2)), now: now),
          'GPS fix 2 hr ago');
    });
    test('contact (heartbeat) wording', () {
      expect(trackingContactLabel(null, now: now), '');
      expect(
          trackingContactLabel(
              now.subtract(const Duration(minutes: 2)), now: now),
          'Contact 2 min ago');
      expect(
          trackingContactLabel(
              now.subtract(const Duration(hours: 1)), now: now),
          'Contact 1 hr ago');
    });
  });

  group('tracking heartbeat payload', () {
    test('carries gps state, session date and fix time - no coordinates',
        () {
      final fix = DateTime.utc(2026, 10, 15, 11, 45);
      final p = buildTrackingHeartbeatPayload(
        empid: 'E1',
        gpsState: TrackingGpsState.noFix,
        dateIso: '2026-10-15',
        gpsFixAt: fix,
      );
      expect(p['empid'], 'E1');
      expect(p['gpsState'], 'no_fix');
      expect(p['dateIso'], '2026-10-15');
      expect(p['gpsFixAtUtc'], fix.toIso8601String());
      expect(p.containsKey('lat'), isFalse);
      expect(p.containsKey('lng'), isFalse);
    });

    test('omits gpsFixAtUtc when the device has no fix', () {
      final p = buildTrackingHeartbeatPayload(
        empid: 'E1', gpsState: TrackingGpsState.serviceOff,
        dateIso: '2026-10-15');
      expect(p.containsKey('gpsFixAtUtc'), isFalse);
    });

    test('network loss is an interface report, not an internet-disconnection claim', () {
      expect(trackingNetworkState([ConnectivityResult.none]), 'none');
      expect(trackingNetworkState([ConnectivityResult.wifi]), 'wifi');
      expect(trackingNetworkState([ConnectivityResult.mobile]), 'mobile');
      expect(trackingNetworkState([]), isNull);
      final payload = buildTrackingHeartbeatPayload(empid: 'E1', gpsState: TrackingGpsState.serviceOff,
        networkState: trackingNetworkState([ConnectivityResult.none]));
      expect(payload['networkState'], 'none');
      expect(payload.containsKey('isOnline'), isFalse);
      expect(payload.containsKey('batteryPercent'), isFalse);
    });

    test('missing or invalid network diagnostics remain unknown', () {
      final payload = buildTrackingHeartbeatPayload(empid: 'E1', gpsState: TrackingGpsState.permDenied,
        networkState: 'internet disconnected');
      expect(payload.containsKey('networkState'), isFalse);
      expect(payload['gpsState'], 'perm_denied');
    });

    test('gps state constants match the wire contract', () {
      expect(TrackingGpsState.ok, 'ok');
      expect(TrackingGpsState.noFix, 'no_fix');
      expect(TrackingGpsState.serviceOff, 'service_off');
      expect(TrackingGpsState.permDenied, 'perm_denied');
    });
  });

  group('tracking session date pinning', () {
    test('falls back to the device date when nothing is pinned', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await trackingSessionDateIso(), trackingDateIso());
    });

    test('setTrackingIdentity pins today on a new session', () async {
      SharedPreferences.setMockInitialValues({});
      await setTrackingIdentity(
          empid: 'E1', token: 't', newSession: true);
      final sp = await SharedPreferences.getInstance();
      expect(
          sp.getString(kTrackingSessionDateKey), trackingDateIso());
      expect(await trackingSessionDateIso(), trackingDateIso());
    });

    test('recovery keeps the pinned (original) session date', () async {
      // Simulate an overnight session: pinned date differs from today.
      SharedPreferences.setMockInitialValues({
        'bg_session_date': '2026-10-12',
      });
      await setTrackingIdentity(
          empid: 'E1', token: 't', newSession: false);
      final sp = await SharedPreferences.getInstance();
      expect(sp.getString(kTrackingSessionDateKey), '2026-10-12');
      expect(await trackingSessionDateIso(), '2026-10-12');
    });

    test('a fresh check-in re-pins even when an old pin exists', () async {
      SharedPreferences.setMockInitialValues({
        'bg_session_date': '2026-10-12',
      });
      await setTrackingIdentity(
          empid: 'E1', token: 't', newSession: true);
      final sp = await SharedPreferences.getInstance();
      expect(sp.getString(kTrackingSessionDateKey), trackingDateIso());
    });

    test('clearTrackingSessionIdentity removes the pin and perm flag',
        () async {
      SharedPreferences.setMockInitialValues({
        'bg_empid': 'E1',
        'bg_token': 't',
        'bg_session_date': '2026-10-12',
        'bg_perm_revoked': true,
        'bg_last_gps_fix_ms': 12345,
        'empid': 'E1',
        'token': 't',
      });
      final sp = await SharedPreferences.getInstance();
      await clearTrackingSessionIdentity();
      expect(sp.getString(kTrackingSessionDateKey), isNull);
      expect(sp.getBool('bg_perm_revoked'), isNull);
      expect(sp.getInt('bg_last_gps_fix_ms'), isNull);
      // Login session preserved.
      expect(sp.getString('empid'), 'E1');
      expect(sp.getString('token'), 't');
    });
  });
}
