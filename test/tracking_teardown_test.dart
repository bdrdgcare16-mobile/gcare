import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:serv_app/features/users/background_tasks.dart';
import 'package:serv_app/services/tracking_retry_policy.dart';

/// Regression tests for the Phase-1 tracking lifecycle fixes:
/// session termination must not leave per-employee credentials behind.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('clearTrackingSessionIdentity', () {
    test('removes tracking identity keys but keeps auth/session keys', () async {
      SharedPreferences.setMockInitialValues({
        'bg_empid': 'E1007',
        'bg_token': 'jwt-token',
        'bg_last_pos_ms': 12345,
        'bg_gps_state': 'enabled',
        'tracking_state': 'active',
        'tracking_state_empid': 'E1007',
        'tracking_state_date': '2026-10-12',
        'bg_session_date': '2026-10-12',
        'bg_perm_revoked': true,
        'empid': 'E1007',
        'token': 'jwt-token',
        'isCheckedIn': true,
        'last_check_in_ms': 999,
      });
      final prefs = await SharedPreferences.getInstance();
      await clearTrackingSessionIdentity();

      for (final k in [
        'bg_empid', 'bg_token', 'bg_last_pos_ms', 'bg_gps_state',
        'tracking_state', 'tracking_state_empid', 'tracking_state_date',
        'bg_session_date', 'bg_perm_revoked',
      ]) {
        expect(prefs.get(k), isNull, reason: k);
      }
      // Authenticated session untouched - the employee stays logged in.
      expect(prefs.getString('empid'), 'E1007');
      expect(prefs.getString('token'), 'jwt-token');
      expect(prefs.getBool('isCheckedIn'), isTrue);
      expect(prefs.getInt('last_check_in_ms'), 999);
    });

    test('is safe on empty prefs (idempotent teardown)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await clearTrackingSessionIdentity();
      expect(prefs.getString('bg_empid'), isNull);
      await clearTrackingSessionIdentity(); // second call no-throw
    });
  });

  group('trackingInitRetryDelay', () {
    test('returns the bounded backoff schedule', () {
      expect(trackingInitRetryDelay(0), const Duration(seconds: 5));
      expect(trackingInitRetryDelay(1), const Duration(seconds: 15));
      expect(trackingInitRetryDelay(2), const Duration(seconds: 45));
    });

    test('stops after the max attempts - recovery is connectivity-driven',
        () {
      expect(trackingInitRetryDelay(3), isNull);
      expect(trackingInitRetryDelay(10), isNull);
      expect(kTrackingInitRetryBackoffs, hasLength(kMaxTrackingInitAttempts));
    });
  });
}
