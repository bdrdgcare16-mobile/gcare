import {
  DEFAULT_ATTENDANCE_POLICY,
  classifyOfficePresence,
  evaluateAttendanceGate,
  resolveAttendancePolicy,
} from './attendancePolicy';

const MAX = DEFAULT_ATTENDANCE_POLICY.maxAccuracyMeters; // 200

describe('classifyOfficePresence', () => {
  test('confident inside when the whole error circle fits in the geofence', () => {
    expect(classifyOfficePresence(30, 100, 20, MAX)).toBe('inside');
    expect(classifyOfficePresence(80, 100, 20, MAX)).toBe('inside'); // 80+20<=100
  });

  test('confident outside when the whole error circle clears the boundary', () => {
    expect(classifyOfficePresence(500, 100, 20, MAX)).toBe('outside');
    expect(classifyOfficePresence(121, 100, 20, MAX)).toBe('outside'); // 121-20>100
  });

  test('boundary-straddling fixes are uncertain', () => {
    expect(classifyOfficePresence(90, 100, 20, MAX)).toBe('uncertain'); // 90+20>100, 90-20<100
    expect(classifyOfficePresence(110, 100, 50, MAX)).toBe('uncertain');
    expect(classifyOfficePresence(60, 100, 50, MAX)).toBe('uncertain'); // 60+50>100, 60-50<100
  });

  test('indoor-grade accuracy at/above the cap is uncertain, never inside or outside', () => {
    expect(classifyOfficePresence(10, 100, 200, MAX)).toBe('uncertain'); // acc == cap
    expect(classifyOfficePresence(10, 100, 500, MAX)).toBe('uncertain');
    expect(classifyOfficePresence(2000, 100, 500, MAX)).toBe('uncertain'); // far away but untrusted
  });

  test('missing/invalid accuracy is uncertain, not treated as perfect', () => {
    expect(classifyOfficePresence(10, 100, null, MAX)).toBe('uncertain');
    expect(classifyOfficePresence(10, 100, NaN, MAX)).toBe('uncertain');
    expect(classifyOfficePresence(10, 100, -5, MAX)).toBe('uncertain');
  });

  test('no geofence or non-positive radius is uncertain', () => {
    expect(classifyOfficePresence(10, null, 10, MAX)).toBe('uncertain');
    expect(classifyOfficePresence(10, 0, 10, MAX)).toBe('uncertain');
    expect(classifyOfficePresence(10, -50, 10, MAX)).toBe('uncertain');
    expect(classifyOfficePresence(null, 100, 10, MAX)).toBe('uncertain');
  });

  test('custom maxAccuracyMeters is honored', () => {
    expect(classifyOfficePresence(10, 100, 60, 50)).toBe('uncertain'); // cap 50
    expect(classifyOfficePresence(10, 100, 60, 100)).toBe('inside');
  });
});

describe('resolveAttendancePolicy', () => {
  test('missing policy yields flexible defaults', () => {
    expect(resolveAttendancePolicy(undefined)).toEqual(DEFAULT_ATTENDANCE_POLICY);
    expect(resolveAttendancePolicy(null)).toEqual(DEFAULT_ATTENDANCE_POLICY);
    expect(resolveAttendancePolicy('flexible')).toEqual(DEFAULT_ATTENDANCE_POLICY);
  });

  test('partial policy merges with defaults', () => {
    expect(resolveAttendancePolicy({ locationMode: 'strict' })).toEqual({
      locationMode: 'strict',
      maxAccuracyMeters: 200,
      allowAttendanceWithoutGps: false,
    });
  });

  test('invalid field values fall back to defaults', () => {
    const p = resolveAttendancePolicy({
      locationMode: 'everything-is-allowed',
      maxAccuracyMeters: -10,
      allowAttendanceWithoutGps: 'yes',
    });
    expect(p.locationMode).toBe('flexible');
    expect(p.maxAccuracyMeters).toBe(200);
    expect(p.allowAttendanceWithoutGps).toBe(false);
  });
});

describe('evaluateAttendanceGate', () => {
  const flexible = resolveAttendancePolicy(undefined);
  const strict = resolveAttendancePolicy({ locationMode: 'strict' });

  test('flexible mode allows inside, outside, and uncertain fixes', () => {
    for (const p of ['inside', 'outside', 'uncertain'] as const) {
      expect(evaluateAttendanceGate(true, p, flexible)).toBe('allow');
    }
  });

  test('flexible mode rejects requests with no GPS fix', () => {
    expect(evaluateAttendanceGate(false, 'unavailable', flexible))
      .toBe('location-unavailable');
  });

  test('flexible + allowAttendanceWithoutGps permits fix-less attendance', () => {
    const p = resolveAttendancePolicy({ allowAttendanceWithoutGps: true });
    expect(evaluateAttendanceGate(false, 'unavailable', p)).toBe('allow');
  });

  test('strict mode only allows confident inside', () => {
    expect(evaluateAttendanceGate(true, 'inside', strict)).toBe('allow');
    expect(evaluateAttendanceGate(true, 'outside', strict)).toBe('outside-geofence');
    expect(evaluateAttendanceGate(true, 'uncertain', strict)).toBe('outside-geofence');
    expect(evaluateAttendanceGate(false, 'unavailable', strict))
      .toBe('location-unavailable');
  });
});
