import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences key: epoch ms of the most recent /tracking/pos post the
/// backend CONFIRMED is represented in pathMap (appended, duplicate, or
/// throttled because a point younger than 15 min already exists).
const String kLastPersistedPosMsKey = 'bg_last_pos_ms';

/// Bumped (same isolate only) whenever a tracking point is confirmed stored,
/// so an open My Tracking page can reload once instead of polling.
final ValueNotifier<int> trackingPointPersisted = ValueNotifier<int>(0);

/// Local calendar date used as the tracking document key. Readers (My
/// Tracking, admin views, check-out, logout) all query by local date, so
/// writers must send the same key instead of relying on the backend's UTC
/// default.
String trackingDateIso([DateTime? at]) {
  final d = at ?? DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// SharedPreferences key holding the session date pinned at tracking
/// check-in. A session that crosses midnight keeps writing to the SAME
/// tracking document (the one the backend session validation is anchored
/// to) instead of silently starting a new doc at 00:00. Cleared with the
/// rest of the tracking identity on check-out/logout.
const String kTrackingSessionDateKey = 'bg_session_date';

/// The tracking-document date for the active session. Returns the pinned
/// session date when one exists, else the device's current local date
/// (which is correct for a not-yet-started session).
Future<String> trackingSessionDateIso() async {
  try {
    final sp = await SharedPreferences.getInstance();
    final pinned = sp.getString(kTrackingSessionDateKey);
    if (pinned != null && pinned.isNotEmpty) return pinned;
  } catch (_) {}
  return trackingDateIso();
}

/// Parsed outcome of POST /tracking/pos. HTTP 200 alone is NOT proof that a
/// point was stored - the backend also returns 200 when it skips a point.
class TrackingPostResult {
  final int httpStatus;

  /// appended | duplicate | time_throttled | too_close | session_ended |
  /// http_error | unknown
  final String status;
  final int? pathMapCount;

  const TrackingPostResult(this.httpStatus, this.status, this.pathMapCount);

  bool get httpOk => httpStatus >= 200 && httpStatus < 300;

  /// This exact point is stored in pathMap.
  bool get persisted => status == 'appended' || status == 'duplicate';

  /// pathMap holds a point younger than the 15-min window, so a fresh GPS
  /// capture now would only be throttled. Only these outcomes may set the
  /// dedupe marker.
  bool get recentPointExists => persisted || status == 'time_throttled';

  /// The backend reports the tracking session closed (check-out, logout, or
  /// server-side close when attendance ended). Local tracking must stop -
  /// every subsequent post will keep failing with the same status.
  bool get sessionEnded => status == 'session_ended';

  /// Network/5xx failures are worth retrying; a well-formed skip is not.
  bool get retryable => !httpOk && (httpStatus == 0 || httpStatus >= 500);

  factory TrackingPostResult.fromResponse(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      return TrackingPostResult(res.statusCode, 'http_error', null);
    }
    try {
      final body = jsonDecode(res.body);
      if (body is! Map) {
        return TrackingPostResult(res.statusCode, 'unknown', null);
      }
      final count = body['pathMapCount'];
      final status = body['status'];
      if (status is String && status.isNotEmpty) {
        return TrackingPostResult(
            res.statusCode, status, count is num ? count.toInt() : null);
      }
      // Older backend: infer from `added` / `reason`.
      if (body['added'] != null) {
        return TrackingPostResult(res.statusCode, 'appended', null);
      }
      final reason = (body['reason'] ?? '').toString();
      if (reason.startsWith('Time throttled')) {
        return TrackingPostResult(res.statusCode, 'time_throttled', null);
      }
      if (reason.startsWith('Movement too small')) {
        return TrackingPostResult(res.statusCode, 'too_close', null);
      }
      if (reason.contains('session already ended')) {
        return TrackingPostResult(res.statusCode, 'session_ended', null);
      }
      return TrackingPostResult(res.statusCode, 'unknown', null);
    } catch (_) {
      return TrackingPostResult(res.statusCode, 'unknown', null);
    }
  }

  /// Development-only summary - no coordinates or identifiers.
  @override
  String toString() =>
      'http=$httpStatus status=$status persisted=$persisted pathMapCount=${pathMapCount ?? '?'}';
}
