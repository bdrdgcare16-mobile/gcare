/// <reference types="jest" />
/**
 * Geo Fence module (`geo_fence`) — check-in/check-out office validation.
 *
 * Contract:
 *  - enabledFeatures WITHOUT 'geo_fence'  → attendance behaves exactly as
 *    before (distance is computed & recorded, outside-radius is flagged —
 *    never blocked; missing office is tolerated).
 *  - enabledFeatures WITH 'geo_fence'     → a usable office location
 *    (finite coords + positive radius) is REQUIRED; missing/invalid →
 *    controlled 400 OFFICE_LOCATION_NOT_CONFIGURED and NOTHING is written.
 *    Outside-radius keeps the pre-existing flag policy (no invented block).
 *  - No enabledFeatures field (legacy org) → geo_fence OFF (missing key
 *    must never enable an additive feature).
 */

import request from 'supertest';

process.env.JWT_SECRET = 'test-jwt-secret-geo-fence';

const mockFirebaseState = {
  getDb: jest.fn(),
  getAdminAuth: jest.fn(),
  checkFirestoreAccess: jest.fn().mockResolvedValue(true),
};

jest.mock('./config/firebase', () => ({
  getDb: (...args: any[]) => mockFirebaseState.getDb(...args),
  getAdminAuth: (...args: any[]) => mockFirebaseState.getAdminAuth(...args),
  checkFirestoreAccess: (...args: any[]) =>
    mockFirebaseState.checkFirestoreAccess(...args),
}));

// eslint-disable-next-line import/first
import app from './app';
// eslint-disable-next-line import/first
import { issueToken } from './common/auth.utils';

const employeeToken = (companyId: string) =>
  issueToken({
    userId: 'emp-1',
    email: 'emp@org.test',
    role: 'employee',
    empid: 'E001',
    companyId,
  });

const OFFICE = {
  branchName: 'HQ',
  latitude: 12.9,
  longitude: 77.6,
  radius: 500,
  companyId: 'c1',
};

const EMPLOYEE = { empid: 'E001', companyId: 'c1', location: 'HQ' };

const validCheckInBody = (over: any = {}) => ({
  name: 'Test Employee',
  location: 'HQ',
  latitude: 12.9,
  longitude: 77.6,
  accuracy: 10,
  locationTimestamp: Date.now(),
  ...over,
});

function makeDoc(d: any, updateBucket?: any[]) {
  return {
    id: d.id || 'doc-1',
    data: () => d.data || d,
    ref: {
      set: jest.fn().mockResolvedValue(undefined),
      update: jest.fn(async (payload: any) => {
        updateBucket?.push(payload);
      }),
    },
  };
}

/**
 * Firestore mock — per-collection query results.
 *  companyProfile → doc().get() returns opts.profile
 *  employees      → opts.employees
 *  officeLocations→ opts.office (both exact & fallback queries)
 *  attendance     → opts.attendance (today's docs); .add() captured
 *  otherLocation  → .add() captured
 */
function installDb(opts: {
  profile?: any;
  employees?: any[];
  office?: any | null;
  attendance?: any[];
}) {
  const writes = {
    attendanceAdded: [] as any[],
    attendanceUpdated: [] as any[],
    otherLocationAdded: [] as any[],
  };

  mockFirebaseState.getDb.mockReturnValue({
    collection: jest.fn((name: string) => {
      if (name === 'companyProfile') {
        return {
          doc: jest.fn((_id: string) => ({
            get: jest.fn(async () => ({
              exists: opts.profile !== undefined,
              data: () => opts.profile,
            })),
          })),
        };
      }
      const q: any = {};
      q.where = jest.fn(() => q);
      q.limit = jest.fn(() => q);
      q.orderBy = jest.fn(() => q);
      q.get = jest.fn(async () => {
        let docs: any[] = [];
        if (name === 'employees') docs = opts.employees ?? [];
        else if (name === 'officeLocations')
          docs = opts.office ? [opts.office] : [];
        else if (name === 'attendance') docs = opts.attendance ?? [];
        return {
          empty: docs.length === 0,
          docs: docs.map((d) =>
            makeDoc(
              d,
              name === 'attendance' ? writes.attendanceUpdated : undefined,
            ),
          ),
        };
      });
      q.add = jest.fn(async (payload: any) => {
        if (name === 'attendance') writes.attendanceAdded.push(payload);
        if (name === 'otherLocation') writes.otherLocationAdded.push(payload);
        return { id: `${name}-new` };
      });
      q.doc = jest.fn((_id: string) => ({
        get: jest.fn(async () => ({ exists: false, data: () => ({}) })),
      }));
      return q;
    }),
    getAll: jest.fn().mockResolvedValue([]),
    batch: jest.fn().mockReturnValue({
      set: jest.fn(),
      update: jest.fn(),
      commit: jest.fn().mockResolvedValue(undefined),
    }),
  });
  return writes;
}

const basicProfile = (extra: any = {}) => ({
  status: 'active',
  enabledFeatures: ['attendance', 'employee_master', 'feedback', 'shifts'],
  ...extra,
});

const geoProfile = (extra: any = {}) => ({
  status: 'active',
  enabledFeatures: [
    'attendance',
    'employee_master',
    'feedback',
    'shifts',
    'geo_fence',
  ],
  ...extra,
});

describe('Geo Fence — POST /attendance/check-in', () => {
  beforeEach(() => jest.clearAllMocks());

  // CASE 1 — existing org, geo_fence absent, location_tracking absent.
  test('geo_fence absent + no office → check-in succeeds (unchanged)', async () => {
    const w = installDb({ profile: basicProfile(), employees: [EMPLOYEE] });
    const res = await request(app)
      .post('/api/attendance/check-in')
      .set('Authorization', `Bearer ${employeeToken('c1')}`)
      .send(validCheckInBody());
    expect(res.status).toBe(200);
    expect(w.attendanceAdded.length).toBe(1);
    expect(w.attendanceAdded[0].withinRadius).toBeNull();
    expect(w.attendanceAdded[0].companyId).toBe('c1');
  });

  test('legacy profile (no enabledFeatures) → geo_fence OFF → succeeds', async () => {
    const w = installDb({
      profile: { status: 'active' },
      employees: [EMPLOYEE],
    });
    const res = await request(app)
      .post('/api/attendance/check-in')
      .set('Authorization', `Bearer ${employeeToken('c1')}`)
      .send(validCheckInBody());
    expect(res.status).toBe(200);
    expect(w.attendanceAdded.length).toBe(1);
  });

  // CASE 5 — geo_fence enabled, no office configured → controlled error.
  test('geo_fence enabled + no office → 400, nothing written', async () => {
    const w = installDb({ profile: geoProfile(), employees: [EMPLOYEE] });
    const res = await request(app)
      .post('/api/attendance/check-in')
      .set('Authorization', `Bearer ${employeeToken('c1')}`)
      .send(validCheckInBody());
    expect(res.status).toBe(400);
    expect(res.body.code).toBe('OFFICE_LOCATION_NOT_CONFIGURED');
    expect(res.body.error).toBe(
      'Office location is not configured for this organization.',
    );
    expect(w.attendanceAdded.length).toBe(0);
  });

  test('geo_fence enabled + unusable office (radius 0) → 400', async () => {
    const w = installDb({
      profile: geoProfile(),
      employees: [EMPLOYEE],
      office: { ...OFFICE, radius: 0 },
    });
    const res = await request(app)
      .post('/api/attendance/check-in')
      .set('Authorization', `Bearer ${employeeToken('c1')}`)
      .send(validCheckInBody());
    expect(res.status).toBe(400);
    expect(res.body.code).toBe('OFFICE_LOCATION_NOT_CONFIGURED');
    expect(w.attendanceAdded.length).toBe(0);
  });

  // CASE 3 — geo_fence enabled, inside radius → validates & records.
  test('geo_fence enabled + inside radius → 200, withinRadius=true', async () => {
    const w = installDb({
      profile: geoProfile(),
      employees: [EMPLOYEE],
      office: OFFICE,
    });
    const res = await request(app)
      .post('/api/attendance/check-in')
      .set('Authorization', `Bearer ${employeeToken('c1')}`)
      .send(validCheckInBody());
    expect(res.status).toBe(200);
    expect(w.attendanceAdded.length).toBe(1);
    expect(w.attendanceAdded[0].withinRadius).toBe(true);
    expect(w.attendanceAdded[0].expectedRadius).toBe(500);
  });

  test('geo_fence enabled + outside radius → flagged, not blocked', async () => {
    const w = installDb({
      profile: geoProfile(),
      employees: [EMPLOYEE],
      office: OFFICE,
    });
    const res = await request(app)
      .post('/api/attendance/check-in')
      .set('Authorization', `Bearer ${employeeToken('c1')}`)
      .send(validCheckInBody({ latitude: 13.5, longitude: 77.6 }));
    expect(res.status).toBe(200);
    expect(w.attendanceAdded.length).toBe(1);
    expect(w.attendanceAdded[0].withinRadius).toBe(false);
    expect(w.attendanceAdded[0].otherLocation).toContain('Outside radius');
    expect(w.otherLocationAdded.length).toBe(1);
  });
});

describe('Geo Fence — POST /attendance/check-out', () => {
  beforeEach(() => jest.clearAllMocks());

  const checkedInRecord = (expected: any = {}) => ({
    empid: 'E001',
    companyId: 'c1',
    name: 'Test Employee',
    branchName: 'HQ',
    checkIn: '09:00:00',
    ...expected,
  });

  const checkOutBody = (over: any = {}) => ({
    location: 'HQ',
    latitude: 12.9,
    longitude: 77.6,
    accuracy: 10,
    ...over,
  });

  test('geo_fence enabled + stored office config → checkout succeeds', async () => {
    const w = installDb({
      profile: geoProfile(),
      employees: [EMPLOYEE],
      attendance: [
        {
          data: checkedInRecord({
            expectedLatitude: 12.9,
            expectedLongitude: 77.6,
            expectedRadius: 500,
          }),
        },
      ],
    });
    const res = await request(app)
      .post('/api/attendance/check-out')
      .set('Authorization', `Bearer ${employeeToken('c1')}`)
      .send(checkOutBody());
    expect(res.status).toBe(200);
    expect(w.attendanceUpdated.length).toBe(1);
    expect(w.attendanceUpdated[0].checkoutWithinRadius).toBe(true);
  });

  test('geo_fence enabled + no office anywhere → 400, nothing written', async () => {
    const w = installDb({
      profile: geoProfile(),
      employees: [EMPLOYEE],
      attendance: [{ data: checkedInRecord() }],
    });
    const res = await request(app)
      .post('/api/attendance/check-out')
      .set('Authorization', `Bearer ${employeeToken('c1')}`)
      .send(checkOutBody());
    expect(res.status).toBe(400);
    expect(res.body.code).toBe('OFFICE_LOCATION_NOT_CONFIGURED');
    expect(w.attendanceUpdated.length).toBe(0);
  });

  test('geo_fence enabled + valid office + missing GPS → 400 controlled', async () => {
    const w = installDb({
      profile: geoProfile(),
      employees: [EMPLOYEE],
      office: OFFICE,
      attendance: [{ data: checkedInRecord() }],
    });
    const res = await request(app)
      .post('/api/attendance/check-out')
      .set('Authorization', `Bearer ${employeeToken('c1')}`)
      .send(checkOutBody({ latitude: undefined, longitude: undefined }));
    expect(res.status).toBe(400);
    expect(res.body.code).toBe('INVALID_COORDINATES');
    expect(w.attendanceUpdated.length).toBe(0);
  });

  // Existing behavior: geo_fence OFF → checkout tolerates no office & no GPS.
  test('geo_fence absent + no office + no GPS → checkout succeeds', async () => {
    const w = installDb({
      profile: basicProfile(),
      employees: [EMPLOYEE],
      attendance: [{ data: checkedInRecord() }],
    });
    const res = await request(app)
      .post('/api/attendance/check-out')
      .set('Authorization', `Bearer ${employeeToken('c1')}`)
      .send({ location: 'HQ' });
    expect(res.status).toBe(200);
    expect(w.attendanceUpdated.length).toBe(1);
    expect(w.attendanceUpdated[0].checkoutWithinRadius).toBeNull();
  });
});
