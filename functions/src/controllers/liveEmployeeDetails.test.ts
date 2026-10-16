/**
 * Tenant isolation for liveEmployeeDetails, and approval-behavior for
 * decideOtherLocationEvent (outside-office audit decisions must never
 * invalidate the attendance record itself).
 */
import { liveEmployeeDetails } from './liveEmployeeDetailsController';
import { decideOtherLocationEvent } from './attendanceController';

// ---- Fake Firestore -------------------------------------------------------

type Row = Record<string, any>;

function makeSnap(doc: Row | undefined) {
  return { exists: doc !== undefined, data: () => doc };
}

/**
 * `rows`: collection name -> candidate documents for where()-based queries.
 * `docs`: "collection/docId" -> document data for doc(id) lookups.
 */
function makeDb(opts: { rows?: Record<string, Row[]>; docs?: Record<string, Row> }) {
  const docs = { ...(opts.docs ?? {}) };

  const makeQuery = (name: string, filters: Array<[string, any]>): any => ({
    where: (f: string, _op: string, v: any) =>
      makeQuery(name, [...filters, [f, v]]),
    limit: () => makeQuery(name, filters),
    orderBy: () => makeQuery(name, filters),
    get: async () => {
      const matched = (opts.rows?.[name] ?? []).filter((r) =>
        filters.every(([f, v]) => r[f] === v),
      );
      return {
        empty: matched.length === 0,
        docs: matched.map((d) => ({ data: () => d })),
      };
    },
  });

  const collection = (name: string) => {
    const api: any = {
      doc: (id: string) => ({
        get: async () => makeSnap(docs[`${name}/${id}`]),
        update: jest.fn(async (data: Row) => {
          docs[`${name}/${id}`] = { ...(docs[`${name}/${id}`] ?? {}), ...data };
        }),
        set: jest.fn(async (data: Row) => {
          docs[`${name}/${id}`] = { ...(docs[`${name}/${id}`] ?? {}), ...data };
        }),
      }),
    };
    api.where = (f: string, _op: string, v: any) => makeQuery(name, [[f, v]]);
    return api;
  };

  return { collection, _docs: docs };
}

// The controllers capture `db` at import time; the mock must delegate to a
// swappable currentDb.
jest.mock('../config/firebase', () => ({
  db: {
    collection: (...args: any[]) => (currentDb as any).collection(...args),
  },
}));

let currentDb: ReturnType<typeof makeDb>;
function useDb(opts: Parameters<typeof makeDb>[0]) {
  currentDb = makeDb(opts);
}

// ---- req/res helpers ------------------------------------------------------

function req(over: {
  companyId?: string | null;
  empid?: string;
  query?: any;
  body?: any;
}) {
  return {
    user: { userId: 'u1', role: 'admin', empid: 'ADM1', companyId: over.companyId },
    params: { empid: over.empid ?? 'EMP001' },
    headers: {},
    query: over.query ?? {},
    body: over.body ?? {},
  } as any;
}

function res() {
  const r: any = { statusCode: 0, body: null };
  r.status = (c: number) => { r.statusCode = c; return r; };
  r.json = (b: any) => { r.body = b; if (r.statusCode === 0) r.statusCode = 200; return r; };
  return r;
}

const DAY = new Date().toISOString().slice(0, 10);

const ownAttendance: Row = {
  empid: 'EMP001', name: 'Alice', date: DAY, companyId: 'COMP_A',
  checkIn: '09:05:00', checkInLatitude: 12.9, checkInLongitude: 77.6,
  checkInAccuracy: 300, expectedLatitude: 12.9, expectedLongitude: 77.6,
  expectedRadius: 100, distanceFromBranch: 50, withinRadius: true,
  checkInOfficePresence: 'uncertain', checkInLocationStatus: 'fix',
};

// ---- Tests ----------------------------------------------------------------

describe('liveEmployeeDetails tenant isolation', () => {
  test('serves same-company attendance with location + presence fields', async () => {
    useDb({
      rows: {
        attendance: [ownAttendance],
        employees: [{ empid: 'EMP001', companyId: 'COMP_A', name: 'Alice', dept: 'IT' }],
      },
    });
    const r = res();
    await liveEmployeeDetails(req({ companyId: 'COMP_A' }), r);
    expect(r.statusCode).toBe(200);
    expect(r.body.data.status).toBe('Present');
    expect(r.body.data.latitude).toBe(12.9);
    expect(r.body.data.checkInAccuracy).toBe(300);
    expect(r.body.data.officePresence).toBe('uncertain');
  });

  test('never serves another company\'s attendance doc for the same empid', async () => {
    useDb({
      rows: {
        attendance: [{ ...ownAttendance, companyId: 'COMP_B' }],
        employees: [{ empid: 'EMP001', companyId: 'COMP_B', name: 'Mallory' }],
      },
    });
    const r = res();
    await liveEmployeeDetails(req({ companyId: 'COMP_A' }), r);
    expect(r.statusCode).toBe(200);
    expect(r.body.data.status).toBe('Absent');
    expect(r.body.data.latitude).toBeNull();
    expect(r.body.data.name).toBe('-'); // COMP_B employee not leaked
  });

  test('empid collision across companies returns only own company', async () => {
    useDb({
      rows: {
        attendance: [
          { ...ownAttendance, companyId: 'COMP_B', name: 'Mallory', checkIn: '08:00:00' },
          ownAttendance,
        ],
        employees: [
          { empid: 'EMP001', companyId: 'COMP_B', name: 'Mallory' },
          { empid: 'EMP001', companyId: 'COMP_A', name: 'Alice' },
        ],
      },
    });
    const r = res();
    await liveEmployeeDetails(req({ companyId: 'COMP_A' }), r);
    expect(r.body.data.name).toBe('Alice');
    expect(r.body.data.checkIn).toBe('09:05:00');
  });

  test('legacy docs missing companyId are not served', async () => {
    const legacy = { ...ownAttendance };
    delete legacy.companyId;
    useDb({
      rows: {
        attendance: [legacy],
        employees: [{ empid: 'EMP001', name: 'Legacy Bob' }],
      },
    });
    const r = res();
    await liveEmployeeDetails(req({ companyId: 'COMP_A' }), r);
    expect(r.statusCode).toBe(200);
    expect(r.body.data.status).toBe('Absent');
    expect(r.body.data.latitude).toBeNull();
    expect(r.body.data.name).toBe('-');
  });

  test('rejects when the token carries no companyId', async () => {
    useDb({ rows: { attendance: [ownAttendance] } });
    const r = res();
    await liveEmployeeDetails(req({ companyId: null }), r);
    expect(r.statusCode).toBe(403);
  });
});

describe('decideOtherLocationEvent approval behavior', () => {
  test('rejecting an outside-office audit event does not touch the attendance record', async () => {
    const db = makeDb({
      docs: {
        'otherLocation/ol1': {
          companyId: 'COMP_A', empid: 'EMP001', approvalStatus: 'Pending',
        },
        'attendance/att1': {
          companyId: 'COMP_A', empid: 'EMP001', status: 'Present',
          approvalStatus: 'Pending',
        },
      },
    });
    currentDb = db;
    const r = res();
    await decideOtherLocationEvent(
      req({
        companyId: 'COMP_A',
        body: { requestId: 'ol1', source: 'other_location', status: 'rejected' },
      }),
      r,
    );
    expect(r.statusCode).toBe(200);
    expect(db._docs['otherLocation/ol1'].approvalStatus).toBe('rejected');
    // Attendance itself stays valid: nothing on the record was modified.
    expect(db._docs['attendance/att1'].status).toBe('Present');
    expect(db._docs['attendance/att1'].approvalStatus).toBe('Pending');
  });

  test('a decision targeted at the attendance doc keeps status Present', async () => {
    const db = makeDb({
      docs: {
        'attendance/att1': {
          companyId: 'COMP_A', empid: 'EMP001', status: 'Present',
          approvalStatus: 'Pending',
        },
      },
    });
    currentDb = db;
    const r = res();
    await decideOtherLocationEvent(
      req({
        companyId: 'COMP_A',
        body: { requestId: 'att1', source: 'attendance', status: 'rejected' },
      }),
      r,
    );
    expect(r.statusCode).toBe(200);
    expect(db._docs['attendance/att1'].status).toBe('Present'); // still counts
    expect(db._docs['attendance/att1'].approvalStatus).toBe('rejected');
  });

  test('cross-company decision is denied', async () => {
    const db = makeDb({
      docs: {
        'otherLocation/ol1': { companyId: 'COMP_B', approvalStatus: 'Pending' },
      },
    });
    currentDb = db;
    const r = res();
    await decideOtherLocationEvent(
      req({
        companyId: 'COMP_A',
        body: { requestId: 'ol1', source: 'other_location', status: 'rejected' },
      }),
      r,
    );
    expect(r.statusCode).toBe(403);
    expect(db._docs['otherLocation/ol1'].approvalStatus).toBe('Pending');
  });
});
