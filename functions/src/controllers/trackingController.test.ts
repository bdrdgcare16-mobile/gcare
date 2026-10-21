/**
 * Authorization tests for trackingController P0 fixes:
 * employee impersonation, cross-company access, duplicate empids across
 * companies, and closed-session reopen rules.
 */
import * as ctrl from './trackingController';

// ---- Fake Firestore plumbing -------------------------------------------

type FakeDoc = Record<string, any> | undefined;

function makeSnap(doc: FakeDoc) {
  return { exists: doc !== undefined, data: () => doc };
}

function queryResult(rows: any[]) {
  const chain: any = {
    where: () => chain,
    limit: () => chain,
    get: async () => ({
      empty: rows.length === 0,
      docs: rows.map((d) => ({ data: () => d })),
    }),
  };
  return chain;
}

/**
 * docs: map of "collection/docId" -> document data.
 * employeesRows / attendanceRows feed the membership + session queries.
 */
function makeDb(opts: {
  docs?: Record<string, any>;
  employeesRows?: any[];
  attendanceRows?: any[];
  trackingRows?: any[];
}) {
  const docs = { ...(opts.docs ?? {}) };
  // Interpret FieldValue sentinels so assertions see the same shape a real
  // write produces: delete removes the key, arrayUnion appends to an array.
  const applyFields = (target: Record<string, any>, data: Record<string, any>) => {
    for (const [k, val] of Object.entries(data)) {
      const m = (val as any)?.methodName;
      if (m === 'FieldValue.delete') {
        delete target[k];
      } else if (m === 'FieldValue.arrayUnion') {
        const els = (val as any).elements ?? [];
        const cur = Array.isArray(target[k]) ? target[k] : [];
        for (const e of els) {
          if (!cur.some((x: any) => JSON.stringify(x) === JSON.stringify(e))) {
            cur.push(e);
          }
        }
        target[k] = cur;
      } else {
        target[k] = val;
      }
    }
    return target;
  };
  const collection = (name: string) => {
    const api: any = {
      doc: (id: string) => ({
        get: async () => makeSnap(docs[`${name}/${id}`]),
        set: jest.fn(async (data: any, _opts?: any) => {
          docs[`${name}/${id}`] =
            applyFields({ ...(docs[`${name}/${id}`] ?? {}) }, data);
        }),
        update: jest.fn(async (data: any) => {
          docs[`${name}/${id}`] =
            applyFields({ ...(docs[`${name}/${id}`] ?? {}) }, data);
        }),
      }),
      where: () => {
        const rows =
          name === 'employees' ? (opts.employeesRows ?? [])
          : name === 'attendance' ? (opts.attendanceRows ?? [])
          : name === 'tracking' ? (opts.trackingRows ?? [])
          : [];
        return queryResult(rows);
      },
    };
    return api;
  };

  return {
    collection,
    runTransaction: async (fn: (tx: any) => Promise<any>) => {
      const tx = {
        get: async (ref: any) => ref.get(),
        set: (ref: any, data: any) => ref.set(data),
        update: (ref: any, data: any) => ref.update(data),
        create: (ref: any, data: any) => ref.set(data),
      };
      return fn(tx);
    },
    _docs: docs,
  };
}

// Mock firebase config BEFORE controller import resolves db. The controller
// captures `db` at import time, so the mock must return a mutable object
// whose collection/runTransaction we swap per test.
jest.mock('../config/firebase', () => ({
  db: {
    collection: (...args: any[]) => (currentDb as any).collection(...args),
    runTransaction: (...args: any[]) => (currentDb as any).runTransaction(...args),
  },
}));

let currentDb: ReturnType<typeof makeDb>;
function useDb(opts: Parameters<typeof makeDb>[0]) {
  currentDb = makeDb(opts);
}

// ---- req/res helpers ----------------------------------------------------

function req(over: {
  role?: string; empid?: string | null; companyId?: string | null;
  headers?: any; query?: any; body?: any;
}) {
  return {
    user: {
      userId: 'u1',
      email: 'u@x.com',
      role: over.role ?? 'employee',
      empid: over.empid ?? null,
      companyId:
        'companyId' in over ? over.companyId : 'COMP_A',
    },
    headers: over.headers ?? {},
    query: over.query ?? {},
    body: over.body ?? {},
  } as any;
}

function res() {
  const r: any = { statusCode: 0, body: null };
  r.status = (c: number) => { r.statusCode = c; return r; };
  r.json = (b: any) => {
    r.body = b;
    if (r.statusCode === 0) r.statusCode = 200; // Express default
    return r;
  };
  return r;
}

const DAY = '2026-10-12';

// ---- Tests ---------------------------------------------------------------

describe('tracking authorization', () => {
  test('employee cannot read another employee via x-empid (impersonation)', async () => {
    useDb({});
    const r = res();
    await ctrl.trackingGetDay(
      req({ empid: 'EMP001', headers: { 'x-empid': 'EMP999' } }), r);
    expect(r.statusCode).toBe(403);
  });

  test('employee reads own day with no client-supplied empid', async () => {
    useDb({ docs: { [`tracking/COMP_A_EMP001_${DAY}`]: {
      empid: 'EMP001', companyId: 'COMP_A', dateIso: DAY,
      pathMap: [{ lat: 1, lng: 2, ts: '2026-10-12T08:00:00Z' }],
      events: [], endedAt: null, lastUpdateAt: '' } } });
    const r = res();
    await ctrl.trackingGetDay(req({ empid: 'EMP001', query: { dateIso: DAY } }), r);
    expect(r.statusCode).toBe(200);
    expect(r.body.data.pathMap).toHaveLength(1);
  });

  test('request without companyId in token is rejected', async () => {
    useDb({});
    const r = res();
    await ctrl.trackingAppendPos(
      req({ empid: 'EMP001', companyId: null, body: { lat: 1, lng: 2 } }), r);
    expect(r.statusCode).toBe(403);
  });

  test('admin may read another employee in same company', async () => {
    useDb({
      employeesRows: [{ empid: 'EMP002', companyId: 'COMP_A' }],
      docs: { [`tracking/COMP_A_EMP002_${DAY}`]: {
        empid: 'EMP002', companyId: 'COMP_A', dateIso: DAY,
        pathMap: [], events: [], endedAt: null, lastUpdateAt: '' } },
    });
    const r = res();
    await ctrl.trackingGetDay(
      req({ role: 'admin', empid: 'ADMIN1', query: { empid: 'EMP002', dateIso: DAY } }), r);
    expect(r.statusCode).toBe(200);
  });

  test('admin cannot read employee of another company (duplicate empid collision)', async () => {
    // Same empid 'EMP001' exists in COMP_B - not in admin's COMP_A.
    useDb({ employeesRows: [] });
    const r = res();
    await ctrl.trackingGetDay(
      req({ role: 'admin', empid: 'ADMIN1', query: { empid: 'EMP001', dateIso: DAY } }), r);
    expect(r.statusCode).toBe(403);
  });

  test('/pos never touches another company doc (creates own-scoped doc only when attendance active)', async () => {
    useDb({ docs: { [`tracking/COMP_B_EMP001_${DAY}`]: {
      empid: 'EMP001', companyId: 'COMP_B', dateIso: DAY,
      pathMap: [], events: [], endedAt: null, lastUpdateAt: '' } },
      attendanceRows: [{ empid: 'EMP001', companyId: 'COMP_A', date: DAY, checkIn: '09:00:00', checkOut: null }] });
    const r = res();
    await ctrl.trackingAppendPos(
      req({ empid: 'EMP001', body: { lat: 1, lng: 2, dateIso: DAY } }), r);
    // Doc id is company-scoped, so this creates a NEW doc in COMP_A rather
    // than touching COMP_B's doc - verify isolation instead of rejection:
    // (cross-company doc can never be addressed by this actor)
    expect(r.statusCode).toBe(200);
    expect(currentDb._docs[`tracking/COMP_B_EMP001_${DAY}`].pathMap).toHaveLength(0);
  });

  test('/pos cannot create a session without active attendance', async () => {
    useDb({ attendanceRows: [] });
    const r = res();
    await ctrl.trackingAppendPos(
      req({ empid: 'EMP001', body: { lat: 1, lng: 2, dateIso: DAY } }), r);
    expect(r.statusCode).toBe(403);
  });

  test('admin may NOT write tracking data for another employee', async () => {
    useDb({
      employeesRows: [{ empid: 'EMP002', companyId: 'COMP_A' }],
      attendanceRows: [{ empid: 'EMP002', companyId: 'COMP_A', date: DAY, checkIn: '09:00:00', checkOut: null }],
    });
    const r = res();
    await ctrl.trackingAppendPos(req({
      role: 'admin', empid: 'ADMIN1',
      body: { empid: 'EMP002', lat: 1, lng: 2, dateIso: DAY },
    }), r);
    expect(r.statusCode).toBe(403);
  });

  test('super_admin may read a same-company employee day', async () => {
    useDb({
      employeesRows: [{ empid: 'EMP002', companyId: 'COMP_A' }],
      docs: { [`tracking/COMP_A_EMP002_${DAY}`]: {
        empid: 'EMP002', companyId: 'COMP_A', dateIso: DAY,
        pathMap: [], events: [], endedAt: null, lastUpdateAt: '' } },
    });
    const r = res();
    await ctrl.trackingGetDay(
      req({ role: 'super_admin', empid: 'SA1', query: { empid: 'EMP002', dateIso: DAY } }), r);
    expect(r.statusCode).toBe(200);
  });

  test('ambiguous legacy doc is hidden when empid spans companies', async () => {
    // EMP001 exists in COMP_A AND COMP_B; a legacy untenanted doc cannot
    // be safely attributed, so it must not merge into the read.
    useDb({
      employeesRows: [
        { empid: 'EMP001', companyId: 'COMP_A' },
        { empid: 'EMP001', companyId: 'COMP_B' },
      ],
      docs: { [`tracking/EMP001_${DAY}`]: {
        empid: 'EMP001', dateIso: DAY,
        pathMap: [{ lat: 5, lng: 6, ts: '2026-10-12T07:00:00Z' }],
        events: [], endedAt: null, lastUpdateAt: '' } },
    });
    const r = res();
    await ctrl.trackingGetDay(req({ empid: 'EMP001', query: { dateIso: DAY } }), r);
    expect(r.statusCode).toBe(200);
    expect(r.body.data.pathMap).toHaveLength(0);
  });

  test('/event rejects a closed session', async () => {
    useDb({ docs: { [`tracking/COMP_A_EMP001_${DAY}`]: {
      empid: 'EMP001', companyId: 'COMP_A', dateIso: DAY,
      pathMap: [], events: [], endedAt: '2026-10-12T10:00:00Z', lastUpdateAt: '' } } });
    const r = res();
    await ctrl.trackingAddEvent(req({
      empid: 'EMP001',
      body: { type: 'location_disabled', dateIso: DAY },
    }), r);
    expect(r.statusCode).toBe(409);
  });

  test('/event rejects when no session exists', async () => {
    useDb({});
    const r = res();
    await ctrl.trackingAddEvent(req({
      empid: 'EMP001',
      body: { type: 'location_disabled', dateIso: DAY },
    }), r);
    expect(r.statusCode).toBe(409);
  });

  test('/event adds event with eventId to active session', async () => {
    useDb({ docs: { [`tracking/COMP_A_EMP001_${DAY}`]: {
      empid: 'EMP001', companyId: 'COMP_A', dateIso: DAY,
      pathMap: [], events: [], endedAt: null, lastUpdateAt: '' } } });
    const r = res();
    await ctrl.trackingAddEvent(req({
      empid: 'EMP001',
      body: { type: 'location_disabled', dateIso: DAY, clientEventId: 'gps-off-1' },
    }), r);
    expect(r.statusCode).toBe(200);
    expect(r.body.status).toBe('added');
    expect(r.body.event.eventId).toMatch(/^evt_/);
  });

  test('/event dedupes by clientEventId', async () => {
    useDb({ docs: { [`tracking/COMP_A_EMP001_${DAY}`]: {
      empid: 'EMP001', companyId: 'COMP_A', dateIso: DAY,
      pathMap: [], events: [{ type: 'location_disabled', ts: '2026-10-12T08:00:00Z', clientEventId: 'gps-off-1' }],
      endedAt: null, lastUpdateAt: '' } } });
    const r = res();
    await ctrl.trackingAddEvent(req({
      empid: 'EMP001',
      body: { type: 'location_disabled', dateIso: DAY, clientEventId: 'gps-off-1' },
    }), r);
    expect(r.statusCode).toBe(200);
    expect(r.body.status).toBe('duplicate');
  });

  test('/event rejects invalid type', async () => {
    useDb({});
    const r = res();
    await ctrl.trackingAddEvent(req({
      empid: 'EMP001',
      body: { type: 'teleport', dateIso: DAY },
    }), r);
    expect(r.statusCode).toBe(400);
  });

  test('closed session cannot be reopened without active attendance', async () => {
    useDb({
      docs: { [`tracking/COMP_A_EMP001_${DAY}`]: {
        empid: 'EMP001', companyId: 'COMP_A', dateIso: DAY,
        pathMap: [], events: [], endedAt: '2026-10-12T10:00:00Z', lastUpdateAt: '' } },
      attendanceRows: [], // no attendance record -> reopen denied
    });
    const r = res();
    await ctrl.trackingCheckIn(req({ empid: 'EMP001', body: { dateIso: DAY } }), r);
    expect(r.statusCode).toBe(403);
  });

  test('closed session reopens while attendance is still checked in', async () => {
    useDb({
      docs: { [`tracking/COMP_A_EMP001_${DAY}`]: {
        empid: 'EMP001', companyId: 'COMP_A', dateIso: DAY,
        pathMap: [], events: [], endedAt: '2026-10-12T10:00:00Z',
        startedAt: '2026-10-12T08:00:00.000Z', lastUpdateAt: '' } },
      attendanceRows: [{ empid: 'EMP001', companyId: 'COMP_A', date: DAY, checkIn: '09:00:00', checkOut: null }],
    });
    const r = res();
    await ctrl.trackingCheckIn(req({ empid: 'EMP001', body: { dateIso: DAY } }), r);
    expect(r.statusCode).toBe(200);
    expect(r.body.reopened).toBe(true);
    // Reopen re-stamps the session boundary so queued events from the
    // previous session can be identified as stale.
    const doc = currentDb._docs[`tracking/COMP_A_EMP001_${DAY}`];
    expect(doc.currentSessionStartedAt).toBeTruthy();
    expect(doc.currentSessionStartedAt)
      .not.toBe('2026-10-12T08:00:00.000Z');
  });

  test('closed session NOT reopened when attendance shows check-out', async () => {
    useDb({
      docs: { [`tracking/COMP_A_EMP001_${DAY}`]: {
        empid: 'EMP001', companyId: 'COMP_A', dateIso: DAY,
        pathMap: [], events: [], endedAt: '2026-10-12T10:00:00Z', lastUpdateAt: '' } },
      attendanceRows: [{ empid: 'EMP001', companyId: 'COMP_A', date: DAY, checkIn: '09:00:00', checkOut: '18:00:00' }],
    });
    const r = res();
    await ctrl.trackingCheckIn(req({ empid: 'EMP001', body: { dateIso: DAY } }), r);
    expect(r.statusCode).toBe(403);
  });

  test('legacy (un-tenanted) doc merges into getDay read', async () => {
    useDb({ docs: { [`tracking/EMP001_${DAY}`]: {
      empid: 'EMP001', dateIso: DAY,
      pathMap: [{ lat: 5, lng: 6, ts: '2026-10-12T07:00:00Z' }],
      events: [], endedAt: null, lastUpdateAt: '' } } });
    const r = res();
    await ctrl.trackingGetDay(req({ empid: 'EMP001', query: { dateIso: DAY } }), r);
    expect(r.statusCode).toBe(200);
    expect(r.body.data.pathMap).toHaveLength(1);
  });

  test('/pos rejects impossible coordinates (lat/lng out of range)', async () => {
    useDb({ docs: { [`tracking/COMP_A_EMP001_${DAY}`]: {
      empid: 'EMP001', companyId: 'COMP_A', dateIso: DAY,
      pathMap: [], events: [], endedAt: null, lastUpdateAt: '' } } });
    const r = res();
    await ctrl.trackingAppendPos(
      req({ empid: 'EMP001', body: { lat: 999, lng: 2, dateIso: DAY } }), r);
    expect(r.statusCode).toBe(400);
    const r2 = res();
    await ctrl.trackingAppendPos(
      req({ empid: 'EMP001', body: { lat: 1, lng: 181, dateIso: DAY } }), r2);
    expect(r2.statusCode).toBe(400);
  });

  test('/event strips impossible optional coords but still records event', async () => {
    useDb({ docs: { [`tracking/COMP_A_EMP001_${DAY}`]: {
      empid: 'EMP001', companyId: 'COMP_A', dateIso: DAY,
      pathMap: [], events: [], endedAt: null, lastUpdateAt: '' } } });
    const r = res();
    await ctrl.trackingAddEvent(req({
      empid: 'EMP001',
      body: { type: 'location_disabled', dateIso: DAY, latitude: 999, longitude: -999 },
    }), r);
    expect(r.statusCode).toBe(200);
    expect(r.body.status).toBe('added');
    expect(r.body.event.latitude).toBeUndefined();
    expect(r.body.event.longitude).toBeUndefined();
  });

  test('/event keeps plausible optional coords', async () => {
    useDb({ docs: { [`tracking/COMP_A_EMP001_${DAY}`]: {
      empid: 'EMP001', companyId: 'COMP_A', dateIso: DAY,
      pathMap: [], events: [], endedAt: null, lastUpdateAt: '' } } });
    const r = res();
    await ctrl.trackingAddEvent(req({
      empid: 'EMP001',
      body: { type: 'location_enabled', dateIso: DAY, latitude: 12.3, longitude: 45.6 },
    }), r);
    expect(r.statusCode).toBe(200);
    expect(r.body.event.latitude).toBe(12.3);
    expect(r.body.event.longitude).toBe(45.6);
  });
});

describe('session close enforcement', () => {
  const DOC_ID = `COMP_A_EMP001_${DAY}`;
  const openTrackingDoc = {
    empid: 'EMP001', companyId: 'COMP_A', dateIso: DAY,
    pathMap: [{ lat: 12.0, lng: 77.0, ts: '2020-01-01T00:00:00.000Z' }],
    events: [], endedAt: null, lastUpdateAt: '2020-01-01T00:00:00.000Z',
  };
  const posBody = {
    empid: 'EMP001', lat: 12.5, lng: 77.5, accuracy: 10,
    ts: '2026-10-12T10:00:00.000Z', dateIso: DAY, pointId: 'pt-x',
  };

  test('append rejected + doc closed when attendance shows check-out '
      + '(crash between attendance and tracking check-out)', async () => {
    useDb({
      docs: { [`tracking/${DOC_ID}`]: { ...openTrackingDoc } },
      attendanceRows: [{
        empid: 'EMP001', companyId: 'COMP_A', date: DAY,
        checkIn: '09:00:00', checkOut: '18:00:00',
      }],
    });
    const r = res();
    await ctrl.trackingAppendPos(
      req({ empid: 'EMP001', body: posBody }), r);
    expect(r.statusCode).toBe(200);
    expect(r.body.status).toBe('session_ended');
    expect(r.body.persisted).toBe(false);
    const doc = currentDb._docs[`tracking/${DOC_ID}`];
    expect(doc.endedAt).toBeTruthy();
    expect(doc.pathMap).toHaveLength(1); // rejected point not stored
  });

  test('append rejected when attendance record is missing '
      + '(orphaned open doc self-heals)', async () => {
    useDb({
      docs: { [`tracking/${DOC_ID}`]: { ...openTrackingDoc } },
      attendanceRows: [],
    });
    const r = res();
    await ctrl.trackingAppendPos(
      req({ empid: 'EMP001', body: posBody }), r);
    expect(r.body.status).toBe('session_ended');
    expect(currentDb._docs[`tracking/${DOC_ID}`].endedAt).toBeTruthy();
  });

  test('append still accepted while attendance session is active', async () => {
    useDb({
      docs: { [`tracking/${DOC_ID}`]: { ...openTrackingDoc } },
      attendanceRows: [{
        empid: 'EMP001', companyId: 'COMP_A', date: DAY,
        checkIn: '09:00:00', checkOut: null,
      }],
    });
    const r = res();
    await ctrl.trackingAppendPos(
      req({ empid: 'EMP001', body: posBody }), r);
    expect(r.body.status).toBe('appended');
    expect(r.body.persisted).toBe(true);
    expect(currentDb._docs[`tracking/${DOC_ID}`].pathMap).toHaveLength(2);
    expect(currentDb._docs[`tracking/${DOC_ID}`].endedAt).toBeNull();
  });

  test('closeTrackingSession stamps endedAt on an open doc', async () => {
    useDb({ docs: { [`tracking/${DOC_ID}`]: { ...openTrackingDoc } } });
    const out = await ctrl.closeTrackingSession(
      { companyId: 'COMP_A', empid: 'EMP001', dateIso: DAY });
    expect(out.closed).toBe(true);
    expect(currentDb._docs[`tracking/${DOC_ID}`].endedAt).toBeTruthy();
  });

  test('closeTrackingSession is a no-op on missing or closed docs', async () => {
    useDb({ docs: {} });
    expect(await ctrl.closeTrackingSession(
      { companyId: 'COMP_A', empid: 'EMP001', dateIso: DAY }))
      .toEqual({ closed: false });
    useDb({ docs: { [`tracking/${DOC_ID}`]: {
      ...openTrackingDoc, endedAt: '2026-10-12T18:00:00.000Z' } } });
    expect(await ctrl.closeTrackingSession(
      { companyId: 'COMP_A', empid: 'EMP001', dateIso: DAY }))
      .toEqual({ closed: false });
  });

  test('check-out closes the PREVIOUS-day session for overnight shifts',
      async () => {
    // Check-in Oct 12, check-out after midnight Oct 13: the dated doc is
    // missing, the open Oct-12 session must still be closed.
    const NEXT_DAY = '2026-10-13';
    useDb({ docs: { [`tracking/COMP_A_EMP001_${DAY}`]: {
      ...openTrackingDoc } } });
    const r = res();
    await ctrl.trackingCheckOut(
      req({ empid: 'EMP001', body: { empid: 'EMP001', dateIso: NEXT_DAY } }),
      r);
    expect(r.statusCode).toBe(200);
    expect(currentDb._docs[`tracking/COMP_A_EMP001_${DAY}`].endedAt)
      .toBeTruthy();
    // The stub today's doc also exists (pre-existing merge-set behaviour).
    expect(currentDb._docs[`tracking/COMP_A_EMP001_${NEXT_DAY}`].endedAt)
      .toBeTruthy();
  });

  test('check-out does not touch another company\'s previous-day doc',
      async () => {
    const NEXT_DAY = '2026-10-13';
    useDb({ docs: { [`tracking/COMP_B_EMP001_${DAY}`]: {
      ...openTrackingDoc, companyId: 'COMP_B' } } });
    const r = res();
    await ctrl.trackingCheckOut(
      req({ empid: 'EMP001', body: { empid: 'EMP001', dateIso: NEXT_DAY } }),
      r);
    expect(r.statusCode).toBe(200);
    expect(
      currentDb._docs[`tracking/COMP_B_EMP001_${DAY}`].endedAt).toBeNull();
  });
});

describe('computeTrackingStatus', () => {
  const NOW = Date.parse('2026-10-12T12:00:00.000Z');
  const freshIso = '2026-10-12T11:50:00.000Z';   // 10 min ago
  const staleIso = '2026-10-12T10:30:00.000Z';   // 90 min ago
  const base = {
    id: `COMP_A_EMP001_${DAY}`,
    empid: 'EMP001', companyId: 'COMP_A', dateIso: DAY,
    startedAt: '2026-10-12T08:00:00.000Z',
    lastUpdateAt: '2026-10-12T08:00:00.000Z',
    pathMap: [] as any[], events: [] as any[], endedAt: null,
  };

  test('no doc -> unknown; ended doc -> checked_out', () => {
    expect(ctrl.computeTrackingStatus(null, NOW)).toBe('unknown');
    expect(ctrl.computeTrackingStatus(
      { ...base, endedAt: staleIso, lastUpdateAt: staleIso }, NOW))
      .toBe('checked_out');
  });

  test('fresh contact + fresh fix -> healthy; old contact -> interrupted', () => {
    expect(ctrl.computeTrackingStatus(
      { ...base, lastUpdateAt: freshIso, lastGpsFixAt: freshIso }, NOW))
      .toBe('healthy');
    expect(ctrl.computeTrackingStatus(
      { ...base, lastUpdateAt: staleIso, lastGpsFixAt: staleIso }, NOW))
      .toBe('interrupted');
  });

  test('fresh contact but stale GPS fix -> gps_delayed', () => {
    expect(ctrl.computeTrackingStatus(
      { ...base, lastUpdateAt: freshIso, lastGpsFixAt: staleIso }, NOW))
      .toBe('gps_delayed');
    // Same via heartbeat timestamp (lastUpdateAt legacy only).
    expect(ctrl.computeTrackingStatus(
      { ...base, lastHeartbeatAt: freshIso, lastGpsFixAt: staleIso }, NOW))
      .toBe('gps_delayed');
  });

  test('alerted interruption beats staleness', () => {
    expect(ctrl.computeTrackingStatus({
      ...base, lastUpdateAt: staleIso, lastGpsFixAt: freshIso,
      interruption: { since: staleIso, alertSent: true, alertedAt: staleIso },
    }, NOW)).toBe('interrupted');
  });

  test('confirmed GPS OFF event -> gps_unavailable; newer fix clears it', () => {
    expect(ctrl.computeTrackingStatus({
      ...base, lastUpdateAt: staleIso,
      events: [{ type: 'location_disabled', ts: staleIso }],
    }, NOW)).toBe('gps_unavailable');
    // A fix AFTER the disable event means tracking recovered.
    expect(ctrl.computeTrackingStatus({
      ...base, lastUpdateAt: freshIso, lastGpsFixAt: freshIso,
      events: [{ type: 'location_disabled', ts: staleIso }],
    }, NOW)).toBe('healthy');
  });

  test('permission_revoked is its own status', () => {
    expect(ctrl.computeTrackingStatus({
      ...base, lastUpdateAt: staleIso,
      events: [{ type: 'permission_revoked', ts: staleIso }],
    }, NOW)).toBe('permission_revoked');
  });

  test('heartbeat-reported states: service_off / perm_denied on live contact', () => {
    expect(ctrl.computeTrackingStatus({
      ...base, lastHeartbeatAt: freshIso, lastGpsFixAt: freshIso,
      lastGpsState: 'service_off',
    }, NOW)).toBe('gps_unavailable');
    expect(ctrl.computeTrackingStatus({
      ...base, lastHeartbeatAt: freshIso, lastGpsFixAt: freshIso,
      lastGpsState: 'perm_denied',
    }, NOW)).toBe('permission_revoked');
    // no_fix keeps gps evaluation honest: stale fix -> gps_delayed.
    expect(ctrl.computeTrackingStatus({
      ...base, lastHeartbeatAt: freshIso, lastGpsFixAt: staleIso,
      lastGpsState: 'no_fix',
    }, NOW)).toBe('gps_delayed');
  });

  test('stale contact beats a stale heartbeat-reported state', () => {
    expect(ctrl.computeTrackingStatus({
      ...base, lastHeartbeatAt: staleIso, lastUpdateAt: staleIso,
      lastGpsState: 'service_off', lastGpsFixAt: freshIso,
    }, NOW)).toBe('interrupted');
  });
});

describe('GET /tracking/live', () => {
  const NOW_FRESH = new Date(Date.now() - 5 * 60000).toISOString();
  const row = (over: any) => ({
    empid: 'EMP001', companyId: 'COMP_A', dateIso: DAY,
    pathMap: [{ lat: 1, lng: 2, ts: NOW_FRESH }],
    events: [], endedAt: null, lastUpdateAt: NOW_FRESH,
    ...over,
  });

  test('employee role is rejected', async () => {
    useDb({});
    const r = res();
    await ctrl.trackingLiveStatus(
      req({ role: 'employee', empid: 'EMP001', query: { dateIso: DAY } }), r);
    expect(r.statusCode).toBe(403);
  });

  test('admin gets company rows with computed status', async () => {
    useDb({ trackingRows: [
      row({}),
      row({ empid: 'EMP002', endedAt: NOW_FRESH }),
    ] });
    const r = res();
    await ctrl.trackingLiveStatus(
      req({ role: 'admin', query: { dateIso: DAY } }), r);
    expect(r.statusCode).toBe(200);
    const rows = r.body.data.rows;
    expect(rows).toHaveLength(2);
    expect(rows[0].status).toBe('healthy');
    expect(rows[0].lastPoint.lat).toBe(1);
    expect(rows[1].status).toBe('checked_out');
    expect(r.body.data.serverNow).toBeTruthy();
  });

  test('admin without companyId in token is rejected', async () => {
    useDb({});
    const r = res();
    await ctrl.trackingLiveStatus(
      req({ role: 'admin', companyId: null }), r);
    expect(r.statusCode).toBe(403);
  });
});

describe('suspicious-location admin alerting', () => {
  const DOC_ID = `COMP_A_EMP001_${DAY}`;
  const openDoc = {
    empid: 'EMP001', companyId: 'COMP_A', dateIso: DAY,
    pathMap: [{ lat: 12.0, lng: 77.0, ts: '2020-01-01T00:00:00.000Z' }],
    events: [], endedAt: null, lastUpdateAt: '2020-01-01T00:00:00.000Z',
  };
  const activeAttendance = [{
    empid: 'EMP001', companyId: 'COMP_A', date: DAY,
    checkIn: '09:00:00', checkOut: null,
  }];
  const pos = (over: any = {}) => ({
    empid: 'EMP001', lat: 12.5, lng: 77.5, accuracy: 10,
    ts: '2026-10-12T10:00:00.000Z', dateIso: DAY,
    pointId: 'pt-susp', mocked: true, ...over,
  });

  test('flagged append records suspiciousNotified dedup state', async () => {
    useDb({ docs: { [`tracking/${DOC_ID}`]: { ...openDoc } },
      attendanceRows: activeAttendance });
    const r = res();
    await ctrl.trackingAppendPos(req({ empid: 'EMP001', body: pos() }), r);
    expect(r.body.status).toBe('appended');
    const doc = currentDb._docs[`tracking/${DOC_ID}`];
    expect(doc.suspiciousNotified.mock_location).toBeTruthy();
    expect(doc.events.some((e: any) => e.type === 'suspicious_location'))
      .toBe(true);
  });

  test('a second flagged point does not re-arm the same flag', async () => {
    useDb({ docs: { [`tracking/${DOC_ID}`]: { ...openDoc,
      suspiciousNotified: { mock_location: '2026-10-12T09:00:00.000Z' } } },
      attendanceRows: activeAttendance });
    const r = res();
    await ctrl.trackingAppendPos(req({ empid: 'EMP001', body: pos() }), r);
    expect(r.body.status).toBe('appended');
    const notified = currentDb._docs[`tracking/${DOC_ID}`].suspiciousNotified;
    // Key stays the pre-existing timestamp - not overwritten.
    expect(notified.mock_location).toBe('2026-10-12T09:00:00.000Z');
  });
});

describe('GPS freshness fields (heartbeat vs fix vs stored point)', () => {
  const DOC_ID = `COMP_A_EMP001_${DAY}`;
  const activeAttendance = [{
    empid: 'EMP001', companyId: 'COMP_A', date: DAY,
    checkIn: '09:00:00', checkOut: null,
  }];
  const NOW_FRESH = new Date(Date.now() - 2 * 60000).toISOString();
  const OPEN = {
    empid: 'EMP001', companyId: 'COMP_A', dateIso: DAY,
    pathMap: [{ lat: 12.0, lng: 77.0, ts: '2020-01-01T00:00:00.000Z' }],
    events: [], endedAt: null, lastUpdateAt: '2020-01-01T00:00:00.000Z',
    lastGpsFixAt: '2020-01-01T00:00:00.000Z',
  };
  const pos = (over: any = {}) => ({
    empid: 'EMP001', lat: 12.5, lng: 77.5, accuracy: 10,
    ts: NOW_FRESH, capturedAtUtc: NOW_FRESH, dateIso: DAY,
    pointId: 'pt-fresh', ...over,
  });

  test('appended point sets lastGpsFixAt AND lastLocationAt', async () => {
    useDb({ docs: { [`tracking/${DOC_ID}`]: { ...OPEN } },
      attendanceRows: activeAttendance });
    const r = res();
    await ctrl.trackingAppendPos(req({ empid: 'EMP001', body: pos() }), r);
    expect(r.body.status).toBe('appended');
    const doc = currentDb._docs[`tracking/${DOC_ID}`];
    expect(doc.lastGpsFixAt).toBe(NOW_FRESH);
    expect(doc.lastLocationAt).toBeTruthy();
    expect(doc.lastHeartbeatAt).toBeTruthy();
    expect(doc.lastGpsState).toBe('ok');
  });

  test('stationary employee (too_close): fix freshness advances, '
      + 'location does not', async () => {
    // >15min since the last stored point, but within 10m of it - the
    // route filter skips the point while the fix stays fresh.
    const r = res();
    useDb({ docs: { [`tracking/${DOC_ID}`]: { ...OPEN } },
      attendanceRows: activeAttendance });
    await ctrl.trackingAppendPos(req({ empid: 'EMP001', body: pos({
      lat: 12.00001, lng: 77.00001, // ~1.5m from the stored point
    }) }), r);
    expect(r.body.status).toBe('too_close');
    const doc = currentDb._docs[`tracking/${DOC_ID}`];
    expect(doc.pathMap).toHaveLength(1);           // route unchanged
    expect(doc.lastGpsFixAt).toBe(NOW_FRESH);      // GPS is fresh
    expect(doc.lastLocationAt).toBeUndefined();    // no stored point
    expect(doc.lastHeartbeatAt).toBeTruthy();      // contact recorded
    // Status must stay healthy - never flag a stationary employee.
    expect(ctrl.computeTrackingStatus(doc, Date.now())).toBe('healthy');
  });

  test('time-throttled point still refreshes lastGpsFixAt', async () => {
    const recent = new Date(Date.now() - 5 * 60000).toISOString();
    useDb({ docs: { [`tracking/${DOC_ID}`]: { ...OPEN,
      lastGpsFixAt: '2020-01-01T00:00:00.000Z',
      pathMap: [{ lat: 12.0, lng: 77.0, ts: recent }] } },
      attendanceRows: activeAttendance });
    const r = res();
    await ctrl.trackingAppendPos(req({ empid: 'EMP001', body: pos() }), r);
    expect(r.body.status).toBe('time_throttled');
    expect(currentDb._docs[`tracking/${DOC_ID}`].lastGpsFixAt)
      .toBe(NOW_FRESH);
  });

  test('movement of 9.56 metres does NOT pass the 10m movement gate '
      + '(no rounding up)', async () => {
    // Regression: distanceMeters used Math.round, so a 9.58m move (seen
    // in production doc COMP001_dsfd_2026-10-16) was stored. 0.0000860 deg
    // latitude at lat 12 = ~9.56m - must be rejected as too_close.
    useDb({ docs: { [`tracking/${DOC_ID}`]: { ...OPEN } },
      attendanceRows: activeAttendance });
    const r = res();
    await ctrl.trackingAppendPos(req({ empid: 'EMP001', body: pos({
      lat: 12.0000860, lng: 77.0, pointId: 'pt-9m',
    }) }), r);
    expect(r.body.status).toBe('too_close');
    expect(currentDb._docs[`tracking/${DOC_ID}`].pathMap).toHaveLength(1);
  });

  test('movement of ~10.0 metres IS appended when the interval '
      + 'condition holds', async () => {
    // 0.0000900 deg latitude at lat 12 = ~10.01m - just over the gate.
    useDb({ docs: { [`tracking/${DOC_ID}`]: { ...OPEN } },
      attendanceRows: activeAttendance });
    const r = res();
    await ctrl.trackingAppendPos(req({ empid: 'EMP001', body: pos({
      lat: 12.0000900, lng: 77.0, pointId: 'pt-10m',
    }) }), r);
    expect(r.body.status).toBe('appended');
    expect(currentDb._docs[`tracking/${DOC_ID}`].pathMap).toHaveLength(2);
  });

  test('a fresh fix clears an alerted gpsGap', async () => {
    const gapSince = new Date(Date.now() - 40 * 60000).toISOString();
    useDb({ docs: { [`tracking/${DOC_ID}`]: { ...OPEN,
      gpsGap: { since: gapSince, alertSent: true, alertedAt: gapSince } } },
      attendanceRows: activeAttendance });
    const r = res();
    await ctrl.trackingAppendPos(req({ empid: 'EMP001', body: pos() }), r);
    expect(r.statusCode).toBe(200);
    const doc = currentDb._docs[`tracking/${DOC_ID}`];
    expect(doc.gpsGap == null || doc.gpsGap.alertSent !== true).toBe(true);
  });

  test('a late queued upload (capture older than the gap) does not '
      + 'fake a recovery', async () => {
    const gapSince = new Date(Date.now() - 30 * 60000).toISOString();
    const oldFix = new Date(Date.now() - 60 * 60000).toISOString();
    useDb({ docs: { [`tracking/${DOC_ID}`]: { ...OPEN,
      gpsGap: { since: gapSince, alertSent: true, alertedAt: gapSince } } },
      attendanceRows: activeAttendance });
    const r = res();
    await ctrl.trackingAppendPos(req({ empid: 'EMP001', body: pos({
      capturedAtUtc: oldFix,
    }) }), r);
    expect(r.statusCode).toBe(200);
    const doc = currentDb._docs[`tracking/${DOC_ID}`];
    // The fix predates the gap - it cannot clear it.
    expect(doc.gpsGap?.alertSent).toBe(true);
  });
});

describe('POST /tracking/heartbeat', () => {
  const DOC_ID = `COMP_A_EMP001_${DAY}`;
  const activeAttendance = [{
    empid: 'EMP001', companyId: 'COMP_A', date: DAY,
    checkIn: '09:00:00', checkOut: null,
  }];
  const OPEN = {
    empid: 'EMP001', companyId: 'COMP_A', dateIso: DAY,
    pathMap: [], events: [], endedAt: null,
    startedAt: '2026-10-12T08:00:00.000Z',
    lastUpdateAt: '2026-10-12T08:00:00.000Z',
  };
  const hbReq = (over: any = {}) => req({
    empid: 'EMP001',
    body: { empid: 'EMP001', dateIso: DAY, gpsState: 'no_fix', ...over },
  });

  test('heartbeat on an open session records contact + gps state', async () => {
    useDb({ docs: { [`tracking/${DOC_ID}`]: { ...OPEN } },
      attendanceRows: activeAttendance });
    const r = res();
    await ctrl.trackingHeartbeat(hbReq(), r);
    expect(r.statusCode).toBe(200);
    expect(r.body.status).toBe('ok');
    const doc = currentDb._docs[`tracking/${DOC_ID}`];
    expect(doc.lastHeartbeatAt).toBeTruthy();
    expect(doc.lastGpsState).toBe('no_fix');
    expect(doc.pathMap).toHaveLength(0); // heartbeat never writes points
  });

  test('heartbeat persists capture diagnostics (result + reason) so '
      + 'a skipped/failed capture is explainable', async () => {
    useDb({ docs: { [`tracking/${DOC_ID}`]: { ...OPEN } },
      attendanceRows: activeAttendance });
    const r = res();
    await ctrl.trackingHeartbeat(hbReq({
      diag: {
        captureId: 'cap-fg-1',
        origin: 'fg',
        captureResult: 'skipped_recent',
        failureReason: 'none',
        scheduledCaptureAt: '2026-10-12T08:48:00.000Z',
        apiRequestStartedAt: '2026-10-12T08:48:01.000Z',
      },
    }), r);
    expect(r.statusCode).toBe(200);
    const doc = currentDb._docs[`tracking/${DOC_ID}`];
    expect(doc.lastCaptureDiag?.captureResult).toBe('skipped_recent');
    expect(doc.lastCaptureDiag?.failureReason).toBe('none');
    expect(doc.lastCaptureDiag?.captureId).toBe('cap-fg-1');
    // ...and never fabricates a stored route point.
    expect(doc.pathMap).toHaveLength(0);
    expect(doc.lastLocationAt ?? null).toBeNull();
  });

  test('heartbeat carrying a fix timestamp advances lastGpsFixAt', async () => {
    const fixIso = new Date(Date.now() - 3 * 60000).toISOString();
    useDb({ docs: { [`tracking/${DOC_ID}`]: { ...OPEN } },
      attendanceRows: activeAttendance });
    const r = res();
    await ctrl.trackingHeartbeat(
      hbReq({ gpsState: 'ok', gpsFixAtUtc: fixIso }), r);
    expect(r.body.status).toBe('ok');
    expect(currentDb._docs[`tracking/${DOC_ID}`].lastGpsFixAt).toBe(fixIso);
  });

  test('heartbeat never moves lastGpsFixAt backwards', async () => {
    const old = '2020-01-01T00:00:00.000Z';
    const newer = new Date(Date.now() - 5 * 60000).toISOString();
    useDb({ docs: { [`tracking/${DOC_ID}`]: { ...OPEN,
      lastGpsFixAt: newer } },
      attendanceRows: activeAttendance });
    const r = res();
    await ctrl.trackingHeartbeat(
      hbReq({ gpsFixAtUtc: old }), r);
    expect(currentDb._docs[`tracking/${DOC_ID}`].lastGpsFixAt).toBe(newer);
  });

  test('closed session -> session_ended (client must stop)', async () => {
    useDb({ docs: { [`tracking/${DOC_ID}`]: { ...OPEN,
      endedAt: '2026-10-12T18:00:00.000Z' } },
      attendanceRows: activeAttendance });
    const r = res();
    await ctrl.trackingHeartbeat(hbReq(), r);
    expect(r.statusCode).toBe(200);
    expect(r.body.status).toBe('session_ended');
  });

  test('attendance ended -> self-heals the doc and reports session_ended',
      async () => {
    useDb({ docs: { [`tracking/${DOC_ID}`]: { ...OPEN } },
      attendanceRows: [{ ...activeAttendance[0], checkOut: '18:00' }] });
    const r = res();
    await ctrl.trackingHeartbeat(hbReq(), r);
    expect(r.body.status).toBe('session_ended');
    expect(currentDb._docs[`tracking/${DOC_ID}`].endedAt).toBeTruthy();
  });

  test('missing doc + active attendance -> session is created', async () => {
    useDb({ docs: {}, attendanceRows: activeAttendance });
    const r = res();
    await ctrl.trackingHeartbeat(hbReq({ gpsState: 'service_off' }), r);
    expect(r.body.status).toBe('ok');
    const doc = currentDb._docs[`tracking/${DOC_ID}`];
    expect(doc).toBeTruthy();
    expect(doc.endedAt).toBeNull();
    expect(doc.lastGpsState).toBe('service_off');
  });

  test('missing doc + no attendance -> session_ended, no doc created',
      async () => {
    useDb({ docs: {}, attendanceRows: [] });
    const r = res();
    await ctrl.trackingHeartbeat(hbReq(), r);
    expect(r.body.status).toBe('session_ended');
    expect(currentDb._docs[`tracking/${DOC_ID}`]).toBeUndefined();
  });

  test('fresh fix in heartbeat clears an alerted gpsGap', async () => {
    const gapSince = new Date(Date.now() - 40 * 60000).toISOString();
    const fixIso = new Date(Date.now() - 2 * 60000).toISOString();
    useDb({ docs: { [`tracking/${DOC_ID}`]: { ...OPEN,
      gpsGap: { since: gapSince, alertSent: true, alertedAt: gapSince } } },
      attendanceRows: activeAttendance });
    const r = res();
    await ctrl.trackingHeartbeat(
      hbReq({ gpsState: 'ok', gpsFixAtUtc: fixIso }), r);
    expect(r.body.status).toBe('ok');
    const doc = currentDb._docs[`tracking/${DOC_ID}`];
    expect(doc.gpsGap == null || doc.gpsGap.alertSent !== true).toBe(true);
  });

  test('heartbeat clears an alerted contact interruption', async () => {
    const since = new Date(Date.now() - 60 * 60000).toISOString();
    useDb({ docs: { [`tracking/${DOC_ID}`]: { ...OPEN,
      lastUpdateAt: since,
      interruption: { since, alertSent: true, alertedAt: since } } },
      attendanceRows: activeAttendance });
    const r = res();
    await ctrl.trackingHeartbeat(hbReq(), r);
    const doc = currentDb._docs[`tracking/${DOC_ID}`];
    expect(doc.interruption == null || doc.interruption.alertSent !== true)
      .toBe(true);
  });

  test('heartbeat cannot impersonate another employee', async () => {
    useDb({ docs: { [`tracking/${DOC_ID}`]: { ...OPEN } },
      attendanceRows: activeAttendance });
    const r = res();
    await ctrl.trackingHeartbeat(
      req({ empid: 'EMP001',
        body: { empid: 'EMP999', dateIso: DAY } }), r);
    expect(r.statusCode).toBe(403);
  });
});

describe('idempotent duplicate delivery vs replay detection', () => {
  const DOC_ID = `COMP_A_EMP001_${DAY}`;
  // Recent instants - a capturedAt older than the stale window would be
  // clamped/flagged ts_stale before replay logic is reached.
  const storedFixIso = new Date(Date.now() - 20 * 60000).toISOString();
  const storedPoint = {
    lat: 13.1302, lng: 79.9084,
    ts: storedFixIso,
    capturedAt: storedFixIso,
    pointId: 'pt-1786000000000',
    source: 'checkin-seed',
  };
  const openDoc = {
    empid: 'EMP001', companyId: 'COMP_A', dateIso: DAY,
    pathMap: [storedPoint], events: [], endedAt: null,
    lastUpdateAt: storedPoint.ts,
  };
  const activeAtt = [{
    empid: 'EMP001', companyId: 'COMP_A', date: DAY,
    checkIn: '08:00:00', checkOut: null,
  }];
  const pos = (over: Record<string, unknown>) =>
    req({ empid: 'EMP001', body: {
      empid: 'EMP001', lat: 13.1302, lng: 79.9084, accuracy: 25,
      ts: new Date().toISOString(), dateIso: DAY, ...over } });

  test('same fix under a DIFFERENT pointId is a benign duplicate, never '
      + 'a replay flag (production false-positive case)', async () => {
    useDb({ docs: { [`tracking/${DOC_ID}`]: { ...openDoc, pathMap: [
      { ...storedPoint } ] } }, attendanceRows: activeAtt });
    const r = res();
    // Second producer re-delivers the identical fix (identical capturedAt,
    // identical coords) with a different producer-derived pointId.
    await ctrl.trackingAppendPos(pos({
      capturedAtUtc: storedFixIso,
      pointId: 'fg-sampling-1786000000000',
    }), r);
    expect(r.statusCode).toBe(200);
    expect(r.body.status).toBe('duplicate');
    const doc = currentDb._docs[`tracking/${DOC_ID}`];
    expect(doc.pathMap).toHaveLength(1);
    const events = doc.events ?? [];
    expect(events.some((e: any) => e.type === 'suspicious_location'))
      .toBe(false);
    expect(doc.suspiciousNotified?.replay).toBeUndefined();
    // Still counts as contact + a (re-delivered) valid fix.
    expect(doc.lastHeartbeatAt).toBeTruthy();
    expect(doc.lastGpsFixAt).toBe(storedFixIso);
  });

  test('same capture instant at a DIFFERENT location is still flagged '
      + 'replay - physically impossible, so not a benign duplicate',
    async () => {
      useDb({ docs: { [`tracking/${DOC_ID}`]: { ...openDoc, pathMap: [
        { ...storedPoint } ] } }, attendanceRows: activeAtt });
      const r = res();
      await ctrl.trackingAppendPos(pos({
        capturedAtUtc: storedFixIso,
        pointId: 'pt-other-1',
        lat: 13.2, lng: 79.95, // ~7 km away, same instant
      }), r);
      expect(r.statusCode).toBe(200);
      const doc = currentDb._docs[`tracking/${DOC_ID}`];
      const susp = (doc.events ?? [])
        .filter((e: any) => e.type === 'suspicious_location');
      expect(susp.length).toBe(1);
      expect(susp[0].message).toContain('replay');
      // Diagnostic identity is recorded for after-the-fact tracing.
      expect(susp[0].pointId).toBe('pt-other-1');
    });

  test('delayed queued point (out-of-order, older capturedAt) is not '
      + 'flagged - offline delivery is normal', async () => {
    const newerStored = {
      lat: 13.1302, lng: 79.9084,
      ts: new Date(Date.now() - 30 * 60000).toISOString(),
      capturedAt: new Date(Date.now() - 35 * 60000).toISOString(),
      pointId: 'pt-newer-1',
    };
    useDb({ docs: { [`tracking/${DOC_ID}`]: { ...openDoc,
      pathMap: [newerStored] } }, attendanceRows: activeAtt });
    const r = res();
    await ctrl.trackingAppendPos(pos({
      capturedAtUtc: new Date(Date.now() - 20 * 60000).toISOString(),
      lat: 13.1400, lng: 79.9150,
      pointId: 'pt-late-2',
    }), r);
    expect(r.statusCode).toBe(200);
    const doc = currentDb._docs[`tracking/${DOC_ID}`];
    const susp = (doc.events ?? [])
      .filter((e: any) => e.type === 'suspicious_location');
    expect(susp).toHaveLength(0);
  });
});

describe('queued account_logged_out closes the session', () => {
  // Regression for production doc COMP001_dsfd_2026-10-16: when the
  // /tracking/check-out POST fails at logout, the client enqueues
  // account_logged_out and it is later delivered through /tracking/event.
  // Before the fix that path appended the event but left endedAt null, so
  // heartbeats kept the session open as long as attendance stayed active.
  test('account_logged_out event stamps endedAt on an open session', async () => {
    const id = `COMP_A_EMP001_${DAY}`;
    const hourAgo = new Date(Date.now() - 3600000).toISOString();
    useDb({ docs: { [`tracking/${id}`]: {
      empid: 'EMP001', companyId: 'COMP_A', dateIso: DAY,
      pathMap: [], events: [], endedAt: null, lastUpdateAt: '',
      startedAt: hourAgo, currentSessionStartedAt: hourAgo,
      interruption: { alertSent: true }, gpsGap: { alertSent: true },
    } } });
    const r = res();
    await ctrl.trackingAddEvent(req({
      empid: 'EMP001',
      body: { type: 'account_logged_out', dateIso: DAY, message: 'User logged out',
        createdAtUtc: new Date().toISOString() },
    }), r);
    expect(r.statusCode).toBe(200);
    const doc = currentDb._docs[`tracking/${id}`];
    expect(doc.endedAt).toBeTruthy();
    expect(doc.events.some((e: any) => e.type === 'account_logged_out')).toBe(true);
    // Alert state is cleared - a closed session is never mid-gap.
    expect(doc.interruption).toBeUndefined();
    expect(doc.gpsGap).toBeUndefined();
  });

  test('deduped re-delivery of the logout event still closes the session', async () => {
    const id = `COMP_A_EMP001_${DAY}`;
    const hourAgo = new Date(Date.now() - 3600000).toISOString();
    useDb({ docs: { [`tracking/${id}`]: {
      empid: 'EMP001', companyId: 'COMP_A', dateIso: DAY,
      pathMap: [], endedAt: null, lastUpdateAt: '',
      startedAt: hourAgo, currentSessionStartedAt: hourAgo,
      events: [{ type: 'account_logged_out', ts: '2026-10-12T10:00:00Z',
        clientEventId: 'logout-1' }],
    } } });
    const r = res();
    await ctrl.trackingAddEvent(req({
      empid: 'EMP001',
      body: { type: 'account_logged_out', dateIso: DAY,
        clientEventId: 'logout-1',
        createdAtUtc: new Date().toISOString() },
    }), r);
    expect(r.statusCode).toBe(200);
    expect(r.body.status).toBe('duplicate');
    const doc = currentDb._docs[`tracking/${id}`];
    expect(doc.endedAt).toBeTruthy();
  });

  test('a logout event generated BEFORE the current session began '
      + 'cannot close it (queued stale delivery)', async () => {
    const id = `COMP_A_EMP001_${DAY}`;
    // Session reopened at T-30min; the queued logout was generated at
    // T-60min during the previous session on the same day document.
    const reopenedAt = new Date(Date.now() - 30 * 60000).toISOString();
    const queuedAt = new Date(Date.now() - 60 * 60000).toISOString();
    useDb({ docs: { [`tracking/${id}`]: {
      empid: 'EMP001', companyId: 'COMP_A', dateIso: DAY,
      pathMap: [], events: [], endedAt: null, lastUpdateAt: '',
      startedAt: new Date(Date.now() - 5 * 3600000).toISOString(),
      currentSessionStartedAt: reopenedAt,
    } } });
    const r = res();
    await ctrl.trackingAddEvent(req({
      empid: 'EMP001',
      body: { type: 'account_logged_out', dateIso: DAY,
        createdAtUtc: queuedAt },
    }), r);
    expect(r.statusCode).toBe(200);
    const doc = currentDb._docs[`tracking/${id}`];
    // Evidence recorded - but the newer session survives.
    expect(doc.endedAt ?? null).toBeNull();
    expect(doc.events.some((e: any) =>
      e.type === 'account_logged_out' && e.staleDelivery === true)).toBe(true);
  });

  test('a logout event without createdAtUtc is recorded but cannot '
      + 'close the session (unverifiable, legacy client)', async () => {
    const id = `COMP_A_EMP001_${DAY}`;
    const hourAgo = new Date(Date.now() - 3600000).toISOString();
    useDb({ docs: { [`tracking/${id}`]: {
      empid: 'EMP001', companyId: 'COMP_A', dateIso: DAY,
      pathMap: [], events: [], endedAt: null, lastUpdateAt: '',
      startedAt: hourAgo, currentSessionStartedAt: hourAgo,
    } } });
    const r = res();
    await ctrl.trackingAddEvent(req({
      empid: 'EMP001',
      body: { type: 'account_logged_out', dateIso: DAY },
    }), r);
    expect(r.statusCode).toBe(200);
    const doc = currentDb._docs[`tracking/${id}`];
    expect(doc.endedAt ?? null).toBeNull();
    expect(doc.events.some((e: any) => e.type === 'account_logged_out'))
      .toBe(true);
  });

  test('a logout event with a future createdAtUtc beyond skew is '
      + 'not trusted to close', async () => {
    const id = `COMP_A_EMP001_${DAY}`;
    const hourAgo = new Date(Date.now() - 3600000).toISOString();
    useDb({ docs: { [`tracking/${id}`]: {
      empid: 'EMP001', companyId: 'COMP_A', dateIso: DAY,
      pathMap: [], events: [], endedAt: null, lastUpdateAt: '',
      startedAt: hourAgo, currentSessionStartedAt: hourAgo,
    } } });
    const r = res();
    await ctrl.trackingAddEvent(req({
      empid: 'EMP001',
      body: { type: 'account_logged_out', dateIso: DAY,
        createdAtUtc: new Date(Date.now() + 60 * 60000).toISOString() },
    }), r);
    expect(r.statusCode).toBe(200);
    expect(currentDb._docs[`tracking/${id}`].endedAt ?? null).toBeNull();
  });

  test('non-logout events do not close the session', async () => {
    const id = `COMP_A_EMP001_${DAY}`;
    useDb({ docs: { [`tracking/${id}`]: {
      empid: 'EMP001', companyId: 'COMP_A', dateIso: DAY,
      pathMap: [], events: [], endedAt: null, lastUpdateAt: '' } } });
    const r = res();
    await ctrl.trackingAddEvent(req({
      empid: 'EMP001',
      body: { type: 'location_disabled', dateIso: DAY },
    }), r);
    expect(r.statusCode).toBe(200);
    expect(currentDb._docs[`tracking/${id}`].endedAt ?? null).toBeNull();
  });
});

describe('Employee GPS Restored notification gating', () => {
  const DAY2 = '2026-10-12';
  const docId = `COMP_A_EMP001_${DAY2}`;
  const sessionDoc = (over: Record<string, any> = {}) => ({
    empid: 'EMP001', companyId: 'COMP_A', dateIso: DAY2,
    pathMap: [], events: [], endedAt: null,
    startedAt: '2026-10-12T08:00:00.000Z',
    currentSessionStartedAt: '2026-10-12T08:00:00.000Z',
    lastUpdateAt: '', ...over,
  });
  const enabledReq = () => req({
    empid: 'EMP001',
    body: { type: 'location_enabled', dateIso: DAY2 },
  });

  // The fake db has no `users` rows, so an attempted admin notify always
  // produces 0 records -> pendingAdminNotify is flagged. Flag presence is
  // therefore an exact proxy for "a restored notification was generated".

  test('check-in / first fix: location_enabled on fresh session is evidence only', async () => {
    useDb({ docs: { [`tracking/${docId}`]: sessionDoc() } });
    const r = res();
    await ctrl.trackingAddEvent(enabledReq(), r);
    expect(r.statusCode).toBe(200);
    expect(r.body.status).toBe('added');
    const doc = currentDb._docs[`tracking/${docId}`];
    // Event recorded, explicitly marked, no notify flag set.
    expect(doc.events).toHaveLength(1);
    expect(doc.events[0].restoredUnconfirmed).toBe(true);
    expect(doc.pendingAdminNotify).toBeUndefined();
  });

  test('GPS already ON all session: enabled event does not notify', async () => {
    useDb({ docs: { [`tracking/${docId}`]: sessionDoc({
      events: [{ type: 'poor_gps', ts: '2026-10-12T09:00:00Z' }],
    }) } });
    const r = res();
    await ctrl.trackingAddEvent(enabledReq(), r);
    expect(r.statusCode).toBe(200);
    expect(currentDb._docs[`tracking/${docId}`].pendingAdminNotify)
      .toBeUndefined();
  });

  test('genuine OFF -> ON in same session notifies (flagged for retry)', async () => {
    useDb({ docs: { [`tracking/${docId}`]: sessionDoc({
      events: [
        { type: 'location_disabled', ts: '2026-10-12T09:30:00Z' },
      ],
    }) } });
    const r = res();
    await ctrl.trackingAddEvent(enabledReq(), r);
    expect(r.statusCode).toBe(200);
    const doc = currentDb._docs[`tracking/${docId}`];
    // Notify was attempted -> pending flag set (no admins in fake db).
    expect(doc.pendingAdminNotify).toBe(true);
    expect(doc.events[1].restoredUnconfirmed).toBeUndefined();
  });

  test('legacy gps_disabled event also counts as confirmed OFF', async () => {
    useDb({ docs: { [`tracking/${docId}`]: sessionDoc({
      events: [{ type: 'gps_disabled', ts: '2026-10-12T09:30:00Z' }],
    }) } });
    const r = res();
    await ctrl.trackingAddEvent(enabledReq(), r);
    expect(currentDb._docs[`tracking/${docId}`].pendingAdminNotify).toBe(true);
  });

  test('OFF event from a previous session does not trigger restored', async () => {
    useDb({ docs: { [`tracking/${docId}`]: sessionDoc({
      // Session reopened at 12:00 - the OFF event is 3h stale.
      currentSessionStartedAt: '2026-10-12T12:00:00.000Z',
      events: [
        { type: 'location_disabled', ts: '2026-10-12T09:30:00Z' },
        { type: 'location_enabled', ts: '2026-10-12T09:45:00Z' },
      ],
    }) } });
    const r = res();
    await ctrl.trackingAddEvent(enabledReq(), r);
    expect(r.statusCode).toBe(200);
    const doc = currentDb._docs[`tracking/${docId}`];
    expect(doc.pendingAdminNotify).toBeUndefined();
    expect(doc.events[2].restoredUnconfirmed).toBe(true);
  });

  test('duplicate enabled event stays deduped and silent', async () => {
    useDb({ docs: { [`tracking/${docId}`]: sessionDoc() } });
    const r1 = res();
    await ctrl.trackingAddEvent(enabledReq(), r1);
    expect(r1.body.status).toBe('added');
    const r2 = res();
    await ctrl.trackingAddEvent(enabledReq(), r2);
    expect(r2.body.status).toBe('duplicate');
    const doc = currentDb._docs[`tracking/${docId}`];
    expect(doc.pendingAdminNotify).toBeUndefined();
    expect(doc.events).toHaveLength(1);
  });

  test('location_disabled still notifies unconditionally (control)', async () => {
    useDb({ docs: { [`tracking/${docId}`]: sessionDoc() } });
    const r = res();
    await ctrl.trackingAddEvent(req({
      empid: 'EMP001',
      body: { type: 'location_disabled', dateIso: DAY2 },
    }), r);
    expect(r.statusCode).toBe(200);
    expect(currentDb._docs[`tracking/${docId}`].pendingAdminNotify).toBe(true);
  });
});
