/// Shared, unit-testable parsing for GET /api/tracking/live rows and the
/// per-employee tracking status labels used by the admin live-attendance
/// dashboard and the employee detail page.
///
/// The backend is authoritative for `status` (see computeTrackingStatus in
/// trackingController.ts) - this file only maps it to display text and
/// computes "Updated X ago" freshness from the returned timestamps.
library;

/// One row of the /tracking/live response for a single employee+date.
class TrackingLiveRow {
  final String empid;
  final String status;
  final bool interrupted;
  final int pathMapCount;
  final int suspiciousCount;
  final List<String> flaggedTypes;

  /// ISO timestamp of the most recent authenticated contact (liveness).
  final DateTime? lastUpdateAt;

  /// ISO timestamp of the most recent device heartbeat. Heartbeats are
  /// sent even when no GPS fix exists, so this is the honest "device is
  /// alive" signal - fresher than lastPointAt in a GPS gap.
  final DateTime? lastHeartbeatAt;

  /// ISO timestamp of the last VALID device GPS fix, including fixes the
  /// route filter skipped (stationary/throttled). This is the real GPS
  /// freshness signal.
  final DateTime? lastGpsFixAt;

  /// ISO timestamp of the last point actually stored in the route.
  final DateTime? lastLocationAt;

  /// Device-reported GPS state at last heartbeat (ok/no_fix/service_off/
  /// perm_denied), null on pre-upgrade sessions.
  final String? lastGpsState;

  /// ISO timestamp of the most recent stored location point.
  final DateTime? lastPointAt;
  final double? lastLat;
  final double? lastLng;

  /// endedAt ISO when the session is closed.
  final DateTime? endedAt;

  const TrackingLiveRow({
    required this.empid,
    required this.status,
    required this.interrupted,
    required this.pathMapCount,
    required this.suspiciousCount,
    required this.flaggedTypes,
    this.lastUpdateAt,
    this.lastHeartbeatAt,
    this.lastGpsFixAt,
    this.lastLocationAt,
    this.lastGpsState,
    this.lastPointAt,
    this.lastLat,
    this.lastLng,
    this.endedAt,
  });

  static DateTime? _ts(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString())?.toLocal();
  }

  factory TrackingLiveRow.fromJson(Map<String, dynamic> j) {
    final lp = j['lastPoint'] is Map
        ? Map<String, dynamic>.from(j['lastPoint'] as Map)
        : null;
    return TrackingLiveRow(
      empid: (j['empid'] ?? '').toString(),
      status: (j['status'] ?? 'unknown').toString(),
      interrupted: j['interrupted'] == true,
      pathMapCount: (j['pathMapCount'] as num?)?.toInt() ?? 0,
      suspiciousCount: (j['suspiciousCount'] as num?)?.toInt() ?? 0,
      flaggedTypes: (j['flaggedTypes'] is List)
          ? (j['flaggedTypes'] as List).map((e) => e.toString()).toList()
          : const [],
      lastUpdateAt: _ts(j['lastUpdateAt']),
      lastHeartbeatAt: _ts(j['lastHeartbeatAt']),
      lastGpsFixAt: _ts(j['lastGpsFixAt']),
      lastLocationAt: _ts(j['lastLocationAt']),
      lastGpsState: j['lastGpsState']?.toString(),
      lastPointAt: _ts(lp?['ts']),
      lastLat: (lp?['lat'] as num?)?.toDouble(),
      lastLng: (lp?['lng'] as num?)?.toDouble(),
      endedAt: _ts(j['endedAt']),
    );
  }
}

/// Human label for the backend-computed status. Deliberately never says
/// "offline": missing contact is 'interrupted', not a claim about the
/// device's network state.
String trackingStatusLabel(String status) {
  switch (status) {
    // Current backend vocabulary (contact vs GPS freshness split).
    case 'healthy':
      return 'Tracking Healthy';
    case 'gps_delayed':
      return 'GPS Update Delayed';
    case 'gps_unavailable':
      return 'GPS Unavailable';
    // Pre-upgrade backend strings - kept so a status never renders as
    // "unknown" during deployment skew.
    case 'active':
      return 'Tracking Active';
    case 'stale':
      return 'Location Stale';
    case 'gps_disabled':
      return 'GPS Disabled';
    case 'permission_revoked':
      return 'Permission Revoked';
    case 'interrupted':
      return 'Tracking Interrupted';
    case 'checked_out':
      return 'Checked Out';
    default:
      return 'Status Unknown';
  }
}

/// "Updated just now / 5 min ago / 2 hr ago" from the freshest known
/// timestamp. [at] is injectable for tests.
String trackingFreshnessLabel(DateTime? at, {DateTime? now}) {
  if (at == null) return 'No updates yet';
  final n = now ?? DateTime.now();
  final diff = n.difference(at);
  if (diff.isNegative || diff.inSeconds < 60) return 'Updated just now';
  if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes} min ago';
  if (diff.inHours < 24) return 'Updated ${diff.inHours} hr ago';
  return 'Updated ${diff.inDays} d ago';
}

/// "GPS fix 5 min ago / No GPS fix yet" - freshness of the last VALID
/// device fix (stored or skipped), which is what GPS health means.
String trackingGpsFreshnessLabel(DateTime? at, {DateTime? now}) {
  if (at == null) return 'No GPS fix yet';
  final n = now ?? DateTime.now();
  final diff = n.difference(at);
  if (diff.isNegative || diff.inSeconds < 60) return 'GPS fix just now';
  if (diff.inMinutes < 60) return 'GPS fix ${diff.inMinutes} min ago';
  if (diff.inHours < 24) return 'GPS fix ${diff.inHours} hr ago';
  return 'GPS fix ${diff.inDays} d ago';
}

/// "Contact 2 min ago" - freshness of the last device heartbeat. A fresh
/// contact with a stale GPS fix means "alive but no fix", never offline.
String trackingContactLabel(DateTime? at, {DateTime? now}) {
  if (at == null) return '';
  final n = now ?? DateTime.now();
  final diff = n.difference(at);
  if (diff.isNegative || diff.inSeconds < 60) return 'Contact just now';
  if (diff.inMinutes < 60) return 'Contact ${diff.inMinutes} min ago';
  if (diff.inHours < 24) return 'Contact ${diff.inHours} hr ago';
  return 'Contact ${diff.inDays} d ago';
}
