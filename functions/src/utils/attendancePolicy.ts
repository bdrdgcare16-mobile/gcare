// Pure attendance location-policy helpers. No Firestore imports so this
// module can be unit-tested in isolation.

export type OfficePresence = 'inside' | 'outside' | 'uncertain' | 'unavailable';

export type AttendancePolicy = {
  // 'flexible' records attendance regardless of office presence;
  // 'strict' rejects anything that is not confidently inside the geofence.
  locationMode: 'flexible' | 'strict';
  // Fixes with horizontal accuracy worse than this can never be confidently
  // classified and are always 'uncertain'.
  maxAccuracyMeters: number;
  // Separate decision for "no GPS fix at all" (permission denied, GPS off,
  // acquisition timeout). When false the request is rejected rather than
  // silently recording an unverifiable location.
  allowAttendanceWithoutGps: boolean;
};

export const DEFAULT_ATTENDANCE_POLICY: AttendancePolicy = {
  locationMode: 'flexible',
  maxAccuracyMeters: 200,
  allowAttendanceWithoutGps: false,
};

// Normalize a raw companies/{id}.attendancePolicy value; unknown/missing
// fields fall back to the defaults so existing companies keep the flexible
// behavior.
export function resolveAttendancePolicy(raw: unknown): AttendancePolicy {
  if (!raw || typeof raw !== 'object') return { ...DEFAULT_ATTENDANCE_POLICY };
  const r = raw as Record<string, unknown>;
  return {
    locationMode: r.locationMode === 'strict' ? 'strict' : 'flexible',
    maxAccuracyMeters:
      Number.isFinite(Number(r.maxAccuracyMeters)) &&
      Number(r.maxAccuracyMeters) > 0
        ? Number(r.maxAccuracyMeters)
        : DEFAULT_ATTENDANCE_POLICY.maxAccuracyMeters,
    allowAttendanceWithoutGps: r.allowAttendanceWithoutGps === true,
  };
}

// Boundary-overlap classification: never claim inside/outside with certainty
// when the reported GPS accuracy radius straddles the geofence edge.
//   inside      - the whole error circle fits inside the geofence
//   outside     - the whole error circle is past the geofence boundary
//   uncertain   - accuracy overlaps the boundary, exceeds the policy cap, or
//                 no geofence/office is configured to compare against
//   unavailable - no device fix at all (decided by callers, never returned
//                 here since a fix implies coordinates exist)
export function classifyOfficePresence(
  distanceMeters: number | null,
  radiusMeters: number | null,
  accuracyMeters: number | null,
  maxAccuracyMeters: number,
): OfficePresence {
  if (
    distanceMeters == null ||
    !Number.isFinite(distanceMeters) ||
    radiusMeters == null ||
    !Number.isFinite(radiusMeters) ||
    radiusMeters <= 0
  ) {
    return 'uncertain';
  }
  // Unknown or invalid error bound (missing/NaN/negative accuracy) cannot
  // produce a confident inside/outside verdict.
  if (
    accuracyMeters == null ||
    !Number.isFinite(accuracyMeters) ||
    accuracyMeters < 0
  ) {
    return 'uncertain';
  }
  const acc = accuracyMeters;
  if (acc >= maxAccuracyMeters) return 'uncertain';
  if (distanceMeters + acc <= radiusMeters) return 'inside';
  if (distanceMeters - acc > radiusMeters) return 'outside';
  return 'uncertain';
}

export type AttendanceGateDecision =
  | 'allow'
  | 'location-unavailable'
  | 'outside-geofence';

// Policy gate shared by check-in and check-out. 'unavailable' presence means
// no GPS fix was attached to the request.
export function evaluateAttendanceGate(
  hasFix: boolean,
  presence: OfficePresence,
  policy: AttendancePolicy,
): AttendanceGateDecision {
  if (!hasFix && !policy.allowAttendanceWithoutGps) {
    return 'location-unavailable';
  }
  if (policy.locationMode === 'strict' && presence !== 'inside') {
    return 'outside-geofence';
  }
  return 'allow';
}
