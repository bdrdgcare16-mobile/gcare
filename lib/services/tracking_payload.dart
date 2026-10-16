import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:serv_app/services/tracking_post_result.dart';

/// Builds the canonical POST /tracking/pos payload used by every producer
/// (attendance seed, main-isolate TrackingService, foreground-service tick).
/// Centralised so anti-spoof metadata can never drift between call sites:
/// `mocked` carries Position.isMocked through the offline queue to the
/// backend, which flags - never silently trusts - spoofed coordinates.
/// isMocked detects platform-level mock providers only; sophisticated
/// spoofing is caught by the server-side speed/replay checks instead.
Map<String, dynamic> buildTrackingPointPayload({
  required String empid,
  required double lat,
  required double lng,
  double? accuracy,
  required bool mocked,
  required String source,
  String? pointId,
  DateTime? capturedAt,
  // Tracking-document key. Defaults to the fix's own date; callers inside
  // an active session pass the pinned session date so a shift crossing
  // midnight keeps appending to the session's original document.
  String? dateIso,
  // Timing diagnostics for the 15-minute cadence audit. Whitelisted
  // server-side onto the stored point - contains no credentials or
  // location data beyond what the point already carries.
  Map<String, dynamic>? diag,
}) {
  final at = capturedAt ?? DateTime.now();
  return {
    'empid': empid,
    'lat': lat,
    'lng': lng,
    if (accuracy != null) 'accuracy': accuracy,
    'mocked': mocked,
    'source': source,
    // `ts` stays local-time ISO for backward compat with the old payload
    // shape; `capturedAtUtc` is the field the server actually trusts for
    // timestamp/replay/impossible-speed checks.
    'ts': at.toIso8601String(),
    'capturedAtUtc': at.toUtc().toIso8601String(),
    'dateIso': dateIso ?? trackingDateIso(at),
    if (pointId != null) 'pointId': pointId,
    if (diag != null) 'diag': diag,
  };
}

/// Canonical, producer-INDEPENDENT identity of a GPS fix.
///
/// A single device fix can legitimately be submitted by more than one
/// producer (the foreground-service tick and a main-isolate recovery
/// capture can both receive the platform's current Position). Deriving
/// the id from the capture instant alone - never from the source tag -
/// means the backend recognises the second delivery as an idempotent
/// duplicate instead of a new point with a reused timestamp.
String trackingPointIdFor(DateTime capturedAt) =>
    'pt-${capturedAt.toUtc().millisecondsSinceEpoch}';

/// Convenience wrapper for a geolocator [Position].
Map<String, dynamic> buildTrackingPointPayloadFromPosition({
  required String empid,
  required Position position,
  required String source,
  String? pointId,
  String? dateIso,
  Map<String, dynamic>? diag,
}) {
  return buildTrackingPointPayload(
    empid: empid,
    lat: position.latitude,
    lng: position.longitude,
    accuracy: position.accuracy,
    mocked: position.isMocked,
    source: source,
    pointId: pointId,
    capturedAt: position.timestamp,
    dateIso: dateIso,
    diag: diag,
  );
}

/// SharedPreferences key: epoch ms of the device's most recent VALID GPS
/// fix (a capture that passed the accuracy filter), regardless of whether
/// the backend stored it. Sent in heartbeats so the server can track GPS
/// freshness separately from device contact.
const String kLastGpsFixMsKey = 'bg_last_gps_fix_ms';

/// Device-reported GPS pipeline states for POST /tracking/heartbeat.
/// These strings are part of the wire contract - the server maps them to
/// status (perm_denied -> permission_revoked, service_off -> gps_unavailable,
/// no_fix -> still-evaluated for gps_delayed).
abstract final class TrackingGpsState {
  static const String ok = 'ok';
  static const String noFix = 'no_fix';
  static const String serviceOff = 'service_off';
  static const String permDenied = 'perm_denied';
}

/// A capture-attempt diagnostic record. Carried on /pos (stored with the
/// point) and /heartbeat (recorded as lastCaptureDiag), and appended to a
/// bounded local ring buffer, so capture cadence is provable end to end
/// even when the fix itself was never stored.
Map<String, dynamic> buildCaptureDiag({
  required String captureId,
  required String origin, // 'fg' | 'wm' | 'service' | 'seed'
  required DateTime scheduledCaptureAt,
  DateTime? actualCaptureStartedAt,
  DateTime? apiRequestStartedAt,
  String? captureResult,
  String? failureReason,
}) {
  return {
    'captureId': captureId,
    'origin': origin,
    'scheduledCaptureAt': scheduledCaptureAt.toUtc().toIso8601String(),
    if (actualCaptureStartedAt != null)
      'actualCaptureStartedAt': actualCaptureStartedAt.toUtc()
          .toIso8601String(),
    if (apiRequestStartedAt != null)
      'apiRequestStartedAt': apiRequestStartedAt.toUtc().toIso8601String(),
    if (captureResult != null) 'captureResult': captureResult,
    if (failureReason != null) 'failureReason': failureReason,
  };
}

/// Builds the POST /tracking/heartbeat payload - a lightweight liveness +
/// GPS-state ping carrying NO coordinates. [gpsFixAt] is the device's most
/// recent valid fix (persisted across ticks), letting the server advance
/// lastGpsFixAt without a route point. [diag] optionally reports the last
/// capture attempt (result/failureReason only - no coordinates).
Map<String, dynamic> buildTrackingHeartbeatPayload({
  required String empid,
  required String gpsState,
  String? dateIso,
  DateTime? gpsFixAt,
  Map<String, dynamic>? diag,
}) {
  return {
    'empid': empid,
    'gpsState': gpsState,
    'dateIso': dateIso ?? trackingDateIso(),
    if (gpsFixAt != null) 'gpsFixAtUtc': gpsFixAt.toUtc().toIso8601String(),
    if (diag != null) 'diag': diag,
  };
}

/// Identity of a pending-queue entry for dedup.
///
/// `pointId` is the canonical fix identity when present: it is derived
/// from the capture instant alone, so two producers queueing the SAME fix
/// collapse to one entry instead of both being uploaded (the second
/// upload would otherwise look like a reused timestamp server-side).
/// `mocked` is deliberately NOT part of the signature: it is metadata
/// about the same fix. The coordinate fallback keeps pre-upgrade queued
/// records (no pointId) de-duplicating as before.
String trackingPayloadSignature(Map<String, dynamic> payload) {
  final empid = payload['empid'] ?? '';
  final pointId = payload['pointId']?.toString() ?? '';
  if (pointId.isNotEmpty) return '$empid|$pointId';
  return '$empid|${payload['lat'] ?? ''}|${payload['lng'] ?? ''}|${payload['ts'] ?? ''}|${payload['source'] ?? ''}';
}

/// Serialises a pending-queue entry. Whole-map JSON keeps `mocked`,
/// `accuracy` and any future fields intact across the offline queue.
String encodePendingLocation(Map<String, dynamic> payload) =>
    jsonEncode(payload);

/// Parses a pending-queue entry. Returns null for corrupted entries so
/// callers can drop them without throwing.
Map<String, dynamic>? decodePendingLocation(String entry) {
  try {
    final parsed = jsonDecode(entry);
    return parsed is Map<String, dynamic> ? parsed : null;
  } catch (_) {
    return null;
  }
}
