import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:serv_app/services/api_service.dart';
import 'package:serv_app/services/tracking_post_result.dart';

/// Shared GPS service-state transition tracking for the attendance
/// tracking feature. Used by both the main-isolate TrackingService and
/// the foreground-service isolate: a single SharedPreferences dedup store
/// and a single offline queue serve both emitters so a transition is
/// reported exactly once no matter which isolate observed it first.
///
/// The backend additionally dedupes identical clientEventIds and same-type
/// events inside a 60s window, so an isolate race can never produce
/// duplicate admin alerts.
const String kGpsServiceStateKey = 'bg_gps_state'; // 'on' | 'off'
const String kPendingTrackingEventsKey = 'tracking_pending_events';

/// Dedup for permission_revoked events: a revoked permission is reported
/// once per session, then the flag stays set until permission is observed
/// healthy again (or the tracking identity is cleared) - so each distinct
/// revocation is reported, but the 15-min tick cannot spam duplicates.
const String kPermissionRevokedKey = 'bg_perm_revoked';

/// HTTP 404 on /tracking/event means the DEPLOYED backend predates the
/// route (deployment skew) - not bad data. Such events are queued and
/// retried through the normal sync path instead of being dropped, but
/// never forever: after this many delivery attempts an event is dropped
/// to keep the queue bounded and the failure observable in logs.
const int kMaxEventSendAttempts = 25;

/// Seeds the observed service state WITHOUT emitting an event. Called when
/// tracking starts so only real transitions generate events.
/// With [onlyIfAbsent] the seed never overwrites an already-recorded
/// state: if a transition was observed between the session start and this
/// seed (main isolate vs FG isolate race), the recorded value wins and the
/// event is not silently lost.
Future<void> seedGpsServiceState({bool onlyIfAbsent = false}) async {
  try {
    final enabled = await Geolocator.isLocationServiceEnabled();
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // fresh view across isolates
    if (onlyIfAbsent && prefs.getString(kGpsServiceStateKey) != null) return;
    await prefs.setString(kGpsServiceStateKey, enabled ? 'on' : 'off');
  } catch (_) {}
}

/// Records a GPS service-state transition and emits the matching tracking
/// event when the state actually changed. No-op when the state did not
/// change (dedup) or when the persisted tracking identity is gone
/// (checkout/logout - never emit outside an active session).
Future<void> recordGpsServiceTransition({
  required bool enabled,
  required String empid,
  required String token,
  double? latitude,
  double? longitude,
}) async {
  try {
    if (empid.isEmpty || token.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    // The other isolate may have written dedup/identity keys moments ago;
    // without reload this isolate could re-emit a transition already
    // recorded elsewhere (or miss a logout).
    await prefs.reload();
    // Identity may have been cleared between the service-status callback
    // and this point (logout) - never emit outside an active session.
    if ((prefs.getString('bg_empid') ?? '').isEmpty ||
        (prefs.getString('bg_token') ?? '').isEmpty) {
      return;
    }
    final prev = prefs.getString(kGpsServiceStateKey);
    final next = enabled ? 'on' : 'off';
    if (prev == next) return;
    await prefs.setString(kGpsServiceStateKey, next);
    await _emitTrackingEvent(
      empid: empid,
      token: token,
      type: enabled ? 'location_enabled' : 'location_disabled',
      latitude: latitude,
      longitude: longitude,
    );
  } catch (e) {
    debugPrint('[TrackingEvents] transition record error: $e');
  }
}

/// Emits a `permission_revoked` event the first time a tick observes the
/// location permission as denied/deniedForever during an active session.
/// Session-scoped dedup via [kPermissionRevokedKey] - a repeated denial is
/// reported once, and a restore + revoke cycle reports again. No-op when
/// the persisted tracking identity is gone.
Future<void> recordPermissionRevoked({
  required String empid,
  required String token,
}) async {
  try {
    if (empid.isEmpty || token.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    if ((prefs.getString('bg_empid') ?? '').isEmpty ||
        (prefs.getString('bg_token') ?? '').isEmpty) {
      return;
    }
    if (prefs.getBool(kPermissionRevokedKey) == true) return;
    await prefs.setBool(kPermissionRevokedKey, true);
    await _emitTrackingEvent(
      empid: empid,
      token: token,
      type: 'permission_revoked',
    );
  } catch (e) {
    debugPrint('[TrackingEvents] permission_revoked record error: $e');
  }
}

/// Clears the revocation dedup flag once permission is observed healthy
/// again, so a FUTURE revocation produces a fresh event.
Future<void> clearPermissionRevokedReported() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kPermissionRevokedKey);
  } catch (_) {}
}

Map<String, String> _headers(String empid, String token) => {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'x-empid': empid,
    };

Future<void> _emitTrackingEvent({
  required String empid,
  required String token,
  required String type,
  double? latitude,
  double? longitude,
}) async {
  final clientEventId =
      'gps-$type-${DateTime.now().toUtc().millisecondsSinceEpoch}';
  final payload = <String, dynamic>{
    'empid': empid,
    'type': type,
    // Pinned session date - a GPS transition after midnight belongs to the
    // session's original tracking document, not a new-day doc.
    'dateIso': await trackingSessionDateIso(),
    'clientEventId': clientEventId,
    'message': type == 'location_disabled'
        ? 'Location services turned off during tracking'
        : type == 'permission_revoked'
            ? 'Location permission revoked or unavailable during tracking'
            : 'Location services turned back on during tracking',
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };

  try {
    final res = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/tracking/event'),
          headers: _headers(empid, token),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      debugPrint('[TrackingEvents] $type delivered');
      return;
    }
    if (res.statusCode == 404) {
      // Endpoint missing on the running backend (stale deploy), not a
      // data error - the event stays valid, so keep it for later sync.
      debugPrint('[TrackingEvents] $type endpoint 404 - '
          'queued until backend supports /tracking/event');
      await _enqueueTrackingEvent(payload);
      return;
    }
    // Other 4xx = permanent rejection (invalid payload, auth, closed
    // session). Do not queue - retrying cannot succeed.
    if (res.statusCode >= 400 && res.statusCode < 500) {
      debugPrint('[TrackingEvents] $type rejected ${res.statusCode} - dropped');
      return;
    }
    await _enqueueTrackingEvent(payload);
  } catch (e) {
    debugPrint('[TrackingEvents] $type send error: $e - queued');
    await _enqueueTrackingEvent(payload);
  }
}

Future<void> _enqueueTrackingEvent(Map<String, dynamic> payload) async {
  final prefs = await SharedPreferences.getInstance();
  final list = prefs.getStringList(kPendingTrackingEventsKey) ?? <String>[];
  list.add(jsonEncode(payload));
  await prefs.setStringList(kPendingTrackingEventsKey, list);
}

/// Uploads queued tracking events owned by [empid]. Other accounts'
/// records stay queued for their own session. Called on connectivity
/// restore, service start and before tracking stops.
Future<void> syncPendingTrackingEvents(String empid, String token) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(kPendingTrackingEventsKey) ?? <String>[];
  if (raw.isEmpty) return;
  if ((prefs.getString('token') ?? '').isEmpty) return; // logged out

  final kept = <String>[];
  for (final entry in raw) {
    Map<String, dynamic> item;
    try {
      item = jsonDecode(entry) as Map<String, dynamic>;
    } catch (_) {
      continue; // corrupted entry - drop
    }
    if (item['empid']?.toString() != empid) {
      kept.add(entry);
      continue;
    }
    final attempts = (item['_attempts'] as int? ?? 0) + 1;
    item['_attempts'] = attempts;
    final encoded = jsonEncode(item);
    try {
      final res = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/tracking/event'),
            headers: _headers(empid, token),
            body: jsonEncode(item),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 404) {
        // Stale backend - retryable, but bounded so an event cannot ping
        // a never-deployed route forever.
        if (attempts < kMaxEventSendAttempts) {
          kept.add(encoded);
        } else {
          debugPrint('[TrackingEvents] queued event dropped after '
              '$attempts attempts (endpoint still 404)');
        }
        continue;
      }
      if (res.statusCode >= 400 && res.statusCode < 500) {
        continue; // permanent rejection - drop
      }
      if (res.statusCode < 200 || res.statusCode >= 300) {
        kept.add(encoded);
      }
    } catch (_) {
      kept.add(encoded);
    }
  }
  await prefs.setStringList(kPendingTrackingEventsKey, kept);
}

/* ──────────────────────────────────────────────────────────────────────────
 * TrackingEvents — generic event-reporting facade used by attendance/auth
 * code paths (mock-location reports, account events, service-state polls).
 * It shares the SAME offline queue (kPendingTrackingEventsKey) and the same
 * backend dedup contract (clientEventId + 60s type window) as the GPS
 * transition helpers above, so a queue filled by either API is drained by
 * the same sync.
 * ──────────────────────────────────────────────────────────────────────── */
class TrackingEvents {
  static const List<String> _empKeys = ['empid', 'empId', 'bg_empid'];
  static const List<String> _tokKeys = ['token', 'bg_token'];

  static Future<String?> _empid([String? override]) async {
    if (override != null && override.isNotEmpty) return override;
    final sp = await SharedPreferences.getInstance();
    for (final k in _empKeys) {
      final v = sp.getString(k);
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  static Future<String?> _token([String? override]) async {
    if (override != null && override.isNotEmpty) return override;
    final sp = await SharedPreferences.getInstance();
    for (final k in _tokKeys) {
      final v = sp.getString(k);
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  /// Persist an event into the shared offline queue. The payload must carry
  /// its 'empid' so [syncPendingTrackingEvents] can attribute it; a missing
  /// empid is filled from the current identity when possible.
  static Future<void> enqueue(Map<String, dynamic> event) async {
    try {
      final item = Map<String, dynamic>.from(event);
      if ((item['empid']?.toString() ?? '').isEmpty) {
        final emp = await _empid();
        if (emp != null && emp.isNotEmpty) item['empid'] = emp;
      }
      await _enqueueTrackingEvent(item);
    } catch (_) {}
  }

  /// Retry all queued events for the resolved identity - delegates to the
  /// shared drain so queue entries produced by either API sync identically.
  static Future<void> syncPendingEvents({String? empid, String? token}) async {
    try {
      final emp = await _empid(empid);
      final tok = await _token(token);
      if (emp == null || emp.isEmpty || tok == null || tok.isEmpty) return;
      await syncPendingTrackingEvents(emp, tok);
    } catch (_) {}
  }

  /// Post a tracking event. On network/5xx failure it is queued for retry;
  /// a 4xx rejection is dropped (retrying cannot succeed). Never throws.
  static Future<void> report({
    required String type,
    String? message,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? eventId,
    String? empid,
    String? token,
  }) async {
    try {
      final emp = await _empid(empid);
      final payload = <String, dynamic>{
        if (emp != null && emp.isNotEmpty) 'empid': emp,
        'type': type,
        'dateIso': await trackingSessionDateIso(),
        // The backend dedupes on clientEventId - map the caller's
        // idempotency key onto it so report() retries cannot double-emit.
        'clientEventId': (eventId != null && eventId.isNotEmpty)
            ? eventId
            : 'ev-$type-${DateTime.now().toUtc().millisecondsSinceEpoch}',
        if (message != null) 'message': message,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
      };

      final tok = await _token(token);
      if (emp == null || emp.isEmpty || tok == null || tok.isEmpty) {
        await _enqueueTrackingEvent(payload);
        return;
      }

      try {
        final res = await http
            .post(
              Uri.parse('${ApiService.baseUrl}/tracking/event'),
              headers: _headers(emp, tok),
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 10));
        if (res.statusCode >= 200 && res.statusCode < 300) return;
        if (res.statusCode == 404) {
          // Stale backend (deployment skew) - keep for later sync.
          await _enqueueTrackingEvent(payload);
          return;
        }
        if (res.statusCode >= 400 && res.statusCode < 500) return; // permanent
        await _enqueueTrackingEvent(payload);
      } catch (_) {
        await _enqueueTrackingEvent(payload);
      }
    } catch (_) {}
  }

  /// Record a location-service transition; delegates to the shared dedup
  /// store so a transition is reported exactly once across isolates.
  static Future<void> reportServiceState(
    bool enabled, {
    double? latitude,
    double? longitude,
    String? empid,
    String? token,
  }) async {
    try {
      final emp = await _empid(empid);
      final tok = await _token(token);
      if (emp == null || emp.isEmpty || tok == null || tok.isEmpty) return;
      await recordGpsServiceTransition(
        enabled: enabled,
        empid: emp,
        token: tok,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (_) {}
  }

  /// Prime the stored state without emitting an event (call at tracking
  /// start so the first *change* is the first event).
  static Future<void> primeServiceState(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kGpsServiceStateKey, enabled ? 'on' : 'off');
    } catch (_) {}
  }
}
