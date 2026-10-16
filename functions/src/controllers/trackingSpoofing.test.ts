/**
 * Anti-spoof + heartbeat-liveness tests for trackingController /pos and
 * /event: mocked flags, timestamp validation, impossible-speed/replay
 * detection, liveness refresh on skipped points, and interruption
 * recovery - all company-scoped.
 *
 * All timestamps are relative to Date.now() so the suite is wall-clock
 * independent.
 */
import * as ctrl from './trackingController';

// ---- Fake Firestore plumbing -------------------------------------------

type FakeDoc = Record<string, any> | undefined;

function makeSnap(doc: FakeDoc) {
  return { exists: doc !== undefined, data: () => doc };
}

/** Merge honouring the FieldValue.delete() sentinel (removes the key).
 *  firebase-admin v13 returns a `DeleteTransform` instance; older versions
 *  expose `_methodName: 'FieldValue.delete'` - accept both. */
function applyUpdate(target: Record<string, any>, data: Record<string, any>) {
  for (const [k, v] of Object.entries(data)) {
    if (
      v !== null && typeof v === 'object' &&
      ((v as any)._methodName === 'FieldValue.delete' ||
        v.constructor?.name === 'DeleteTransform')
    ) {
      delete target[k];
    } else {
      target[k] = v;
    }
  }
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

function makeDb(opts: {
  docs?: Record<string, any>;
  employeesRows?: any[];
  attendanceRows?: any[];
  usersRows?: any[];
}) {
  const docs = { ...(opts.docs ?? {}) };
  const collection = (name: string) => {
    const api: any = {
      doc: (id: string) => ({
        get: async () => makeSnap(docs[`${name}/${id}`]),
        set: jest.fn(async (data: any, _opts?: any) => {
          docs[`${name}/${id}`] = { ...(docs[`${name}/${id}`] ?? {}), ...data };
        }),
        update: jest.fn(async (data: any) => {
          docs[`${name}/${id}`] = docs[`${name}/${id}`] ?? {};
          applyUpdate(docs[`${name}/${id}`], data);
        }),
      }),
      where: () => {
        const rows =
          name === 'employees' ? (opts.employeesRows ?? [])
          : name === 'attendance' ? (opts.attendanceRows ?? [])
          : name === 'users' ? (opts.usersRows ?? [])
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

// Notification service fully stubbed - no FCM, no notification writes.
const notifyTrackingEvent =
  jest.fn(async (..._a: any[]) => ({ sent: 0, failed: 0, records: 0 }));
const notifyInterruption =
  jest.fn(async (..._a: any[]) => ({ sent: 0, failed: 0, records: 0 }));
jest.mock('../services/notification.service', () => ({
  notifyCompanyAdminsOfTrackingEvent: (...args: any[]) =>
    notifyTrackingEvent(...args),
  notifyCompanyAdminsOfTrackingInterruption: (...args: any[]) =>
    notifyInterruption(...args),
}));

jest.mock('../config/firebase', () => ({
  db: {
    collection: (...args: any[]) => (currentDb as any).collection(...args),
    runTransaction: (...args: any[]) =>
      (currentDb as any).runTransaction(...args),
  },
}));

let currentDb: ReturnType<typeof makeDb>;
function useDb(opts: Parameters<typeof makeDb>[0]) {
  currentDb = makeDb(opts);
}

function req(over: { role?: string; empid?: string | null; companyId?: string | null;
  headers?: any; query?: any; body?: any }) {
  return {
    user: {
      userId: 'u1',
      email: 'u@x.com',
      role: over.role ?? 'employee',
      empid: over.empid ?? null,
      companyId: 'companyId' in over ? over.companyId : 'COMP_A',
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
    if (r.statusCode === 0) r.statusCode = 200;
    return r;
  };
  return r;
}

const DAY = '2026-10-12';
const DOC = `COMP_A_EMP1_${DAY}`;
const EMP = { role: 'employee', empid: 'EMP1' };
const ACTIVE_ATT =
  { empid: 'EMP1', companyId: 'COMP_A', date: DAY, checkIn: '08:00', checkOut: '' };

const isoMinAgo = (min: number) => new Date(Date.now() - min * 60000).toISOString();

/** Open tracking doc whose last accepted point is `seedMinAgo` minutes old. */
function openDoc(seedMinAgo = 30, extra: Record<string, any> = {}) {
  const seedTs = isoMinAgo(seedMinAgo);
  return {
    [`tracking/${DOC}`]: {
      id: DOC, empid: 'EMP1', companyId: 'COMP_A', dateIso: DAY,
      pathMap: [{
        lat: 12.0, lng: 77.0,
        ts: seedTs, capturedAt: seedTs, pointId: 'seed-1',
      }],
      events: [], startedAt: isoMinAgo(seedMinAgo + 10),
      endedAt: null, lastUpdateAt: seedTs,
      ...extra,
    },
  };
}

function posBody(over: Record<string, any> = {}) {
  return {
    empid: 'EMP1',
    lat: 12.01, lng: 77.01,
    accuracy: 12,
    source: 'fg/worker',
    ts: new Date().toISOString(),
    capturedAtUtc: new Date().toISOString(),
    dateIso: DAY,
    pointId: 'pt-2',
    ...over,
  };
}

describe('tracking anti-spoof flags', () => {
  beforeEach(() => {
    notifyTrackingEvent.mockClear();
    notifyInterruption.mockClear();
  });

  test('mocked=true is stored on the point and flagged + evented', async () => {
    useDb({ docs: openDoc(), attendanceRows: [ACTIVE_ATT] });
    const r = res();
    await ctrl.trackingAppendPos(
      req({ ...EMP, body: posBody({ mocked: true }) }), r);
    expect(r.statusCode).toBe(200);
    const doc = currentDb._docs[`tracking/${DOC}`];
    const pt = doc.pathMap[1];
    expect(pt.mocked).toBe(true);
    expect(pt.flags).toContain('mock_location');
    expect(
      doc.events.some((e: any) => e.type === 'suspicious_location'),
    ).toBe(true);
  });

  test('mocked=false/omitted stores no flag', async () => {
    useDb({ docs: openDoc(), attendanceRows: [ACTIVE_ATT] });
    const r = res();
    await ctrl.trackingAppendPos(req({ ...EMP, body: posBody() }), r);
    const doc = currentDb._docs[`tracking/${DOC}`];
    expect(doc.pathMap[1].mocked).toBeUndefined();
    expect(doc.pathMap[1].flags).toBeUndefined();
    expect(doc.events).toHaveLength(0);
  });

  test('capturedAtUtc in the far future is flagged and not stored', async () => {
    useDb({ docs: openDoc(), attendanceRows: [ACTIVE_ATT] });
    const r = res();
    await ctrl.trackingAppendPos(req({
      ...EMP,
      body: posBody({ capturedAtUtc: '2999-01-01T00:00:00.000Z' }),
    }), r);
    const pt = currentDb._docs[`tracking/${DOC}`].pathMap[1];
    expect(pt.flags).toContain('ts_future');
    expect(pt.capturedAt).toBeUndefined();
  });

  test('capturedAtUtc older than 72h is flagged ts_stale', async () => {
    useDb({ docs: openDoc(), attendanceRows: [ACTIVE_ATT] });
    const r = res();
    await ctrl.trackingAppendPos(req({
      ...EMP,
      body: posBody({ capturedAtUtc: '2001-01-01T00:00:00.000Z' }),
    }), r);
    const pt = currentDb._docs[`tracking/${DOC}`].pathMap[1];
    expect(pt.flags).toContain('ts_stale');
    expect(pt.capturedAt).toBeUndefined();
  });

  test('unparseable capturedAtUtc is flagged ts_invalid', async () => {
    useDb({ docs: openDoc(), attendanceRows: [ACTIVE_ATT] });
    const r = res();
    await ctrl.trackingAppendPos(req({
      ...EMP,
      body: posBody({ capturedAtUtc: 'not-a-date' }),
    }), r);
    const pt = currentDb._docs[`tracking/${DOC}`].pathMap[1];
    expect(pt.flags).toContain('ts_invalid');
    expect(pt.capturedAt).toBeUndefined();
  });

  test('impossible speed between consecutive fixes is flagged', async () => {
    useDb({ docs: openDoc(), attendanceRows: [ACTIVE_ATT] });
    const r = res();
    // ~5000 km (Chennai->NYC) in 30 min >> 350 km/h threshold.
    await ctrl.trackingAppendPos(req({
      ...EMP,
      body: posBody({ lat: 40.0, lng: -74.0 }),
    }), r);
    const pt = currentDb._docs[`tracking/${DOC}`].pathMap[1];
    expect(pt.flags).toContain('impossible_speed');
    expect(pt.flags).not.toContain('mock_location');
  });

  test('plausible speed is not flagged', async () => {
    useDb({ docs: openDoc(), attendanceRows: [ACTIVE_ATT] });
    const r = res();
    // ~1.5 km in 30 min - normal movement, no flags.
    await ctrl.trackingAppendPos(req({ ...EMP, body: posBody() }), r);
    const pt = currentDb._docs[`tracking/${DOC}`].pathMap[1];
    expect(pt.flags).toBeUndefined();
  });

  test('identical capturedAt+coords under a new pointId is a benign '
      + 'duplicate - one fix cannot be two points, and two producers CAN '
      + 'legitimately deliver it (verified production false-positive)',
      async () => {
    const docs = openDoc();
    const seed = docs[`tracking/${DOC}`].pathMap[0];
    useDb({ docs, attendanceRows: [ACTIVE_ATT] });
    const r = res();
    await ctrl.trackingAppendPos(req({
      ...EMP,
      body: posBody({
        lat: seed.lat, lng: seed.lng,
        capturedAtUtc: seed.capturedAt, // identical fix, new pointId
        pointId: 'replayed-1',
      }),
    }), r);
    expect(r.body.status).toBe('duplicate');
    const doc = currentDb._docs[`tracking/${DOC}`];
    expect(doc.pathMap).toHaveLength(1);
    expect(
      doc.events.some((e: any) => e.type === 'suspicious_location'),
    ).toBe(false);
  });

  test('identical capturedAt at a DIFFERENT location is flagged replay - '
      + 'timestamp reuse is physically impossible', async () => {
    const docs = openDoc();
    const seed = docs[`tracking/${DOC}`].pathMap[0];
    useDb({ docs, attendanceRows: [ACTIVE_ATT] });
    const r = res();
    await ctrl.trackingAppendPos(req({
      ...EMP,
      body: posBody({
        lat: seed.lat + 0.01, lng: seed.lng + 0.01, // ~1.4 km away
        capturedAtUtc: seed.capturedAt, // same instant, different place
        pointId: 'replayed-2',
      }),
    }), r);
    const doc = currentDb._docs[`tracking/${DOC}`];
    expect(
      doc.events.some((e: any) =>
        e.type === 'suspicious_location' &&
        String(e.message).includes('replay')),
    ).toBe(true);
  });

  test('mocked point skipped by throttle still emits a suspicious event', async () => {
    useDb({ docs: openDoc(2), attendanceRows: [ACTIVE_ATT] }); // 2min -> throttled
    const r = res();
    await ctrl.trackingAppendPos(req({
      ...EMP,
      body: posBody({ mocked: true }),
    }), r);
    expect(r.body.status).toBe('time_throttled');
    const doc = currentDb._docs[`tracking/${DOC}`];
    expect(doc.pathMap).toHaveLength(1);
    expect(
      doc.events.some((e: any) =>
        e.type === 'suspicious_location' &&
        String(e.message).includes('mock_location')),
    ).toBe(true);
  });

  test('out-of-range coordinates are rejected outright (400)', async () => {
    useDb({ docs: openDoc(), attendanceRows: [ACTIVE_ATT] });
    const r = res();
    await ctrl.trackingAppendPos(req({
      ...EMP,
      body: posBody({ lat: 999, lng: 0 }),
    }), r);
    expect(r.statusCode).toBe(400);
  });
});

describe('heartbeat liveness + recovery', () => {
  beforeEach(() => {
    notifyTrackingEvent.mockClear();
    notifyInterruption.mockClear();
  });

  test('throttled contact still refreshes lastUpdateAt (liveness)', async () => {
    // Seed point only 2 min old -> strict 15-min throttle kicks in.
    useDb({ docs: openDoc(2), attendanceRows: [ACTIVE_ATT] });
    const before = isoMinAgo(2);
    const r = res();
    await ctrl.trackingAppendPos(req({ ...EMP, body: posBody() }), r);
    expect(r.body.status).toBe('time_throttled');
    const doc = currentDb._docs[`tracking/${DOC}`];
    expect(doc.pathMap).toHaveLength(1);
    expect(doc.lastUpdateAt).not.toBe(before);
  });

  test('same-spot skip (too_close) still refreshes lastUpdateAt', async () => {
    useDb({ docs: openDoc(30), attendanceRows: [ACTIVE_ATT] });
    const r = res();
    // Same coords as the seed, 30+ min later -> past throttle but <10 m.
    await ctrl.trackingAppendPos(req({
      ...EMP,
      body: posBody({ lat: 12.0, lng: 77.0, pointId: 'same-spot' }),
    }), r);
    expect(r.body.status).toBe('too_close');
    const doc = currentDb._docs[`tracking/${DOC}`];
    expect(doc.pathMap).toHaveLength(1);
    expect(Date.parse(doc.lastUpdateAt)).toBeGreaterThan(
      Date.parse(isoMinAgo(29)));
  });

  test('duplicate pointId contact refreshes lastUpdateAt', async () => {
    useDb({ docs: openDoc(30), attendanceRows: [ACTIVE_ATT] });
    const r = res();
    await ctrl.trackingAppendPos(req({
      ...EMP,
      body: posBody({ pointId: 'seed-1' }),
    }), r);
    expect(r.body.status).toBe('duplicate');
    const doc = currentDb._docs[`tracking/${DOC}`];
    expect(Date.parse(doc.lastUpdateAt)).toBeGreaterThan(
      Date.parse(isoMinAgo(29)));
  });

  test('first contact clears an alerted interruption and notifies recovery', async () => {
    useDb({
      docs: openDoc(30, {
        interruption: {
          since: isoMinAgo(60), alertSent: true, alertedAt: isoMinAgo(50),
        },
      }),
      attendanceRows: [ACTIVE_ATT],
    });
    const r = res();
    await ctrl.trackingAppendPos(req({ ...EMP, body: posBody() }), r);
    expect(r.statusCode).toBe(200);
    const doc = currentDb._docs[`tracking/${DOC}`];
    expect(doc.interruption).toBeUndefined();
    expect(notifyInterruption).toHaveBeenCalledTimes(1);
    expect(notifyInterruption).toHaveBeenCalledWith(
      expect.objectContaining({ kind: 'recovered', companyId: 'COMP_A' }));
  });

  test('no interruption flag -> no recovery notification', async () => {
    useDb({ docs: openDoc(30), attendanceRows: [ACTIVE_ATT] });
    const r = res();
    await ctrl.trackingAppendPos(req({ ...EMP, body: posBody() }), r);
    expect(notifyInterruption).not.toHaveBeenCalled();
  });

  test('/event contact clears interruption and notifies recovery', async () => {
    useDb({
      docs: openDoc(30, {
        interruption: {
          since: isoMinAgo(60), alertSent: true, alertedAt: isoMinAgo(50),
        },
      }),
      attendanceRows: [ACTIVE_ATT],
    });
    const r = res();
    await ctrl.trackingAddEvent(req({
      ...EMP,
      body: { type: 'location_disabled', dateIso: DAY },
    }), r);
    expect(r.statusCode).toBe(200);
    const doc = currentDb._docs[`tracking/${DOC}`];
    expect(doc.interruption).toBeUndefined();
    expect(notifyInterruption).toHaveBeenCalledWith(
      expect.objectContaining({ kind: 'recovered', companyId: 'COMP_A' }));
    // The GPS-off admin alert still fires independently.
    expect(notifyTrackingEvent).toHaveBeenCalledWith(
      expect.objectContaining({
        eventType: 'location_disabled', companyId: 'COMP_A',
      }));
  });

  test('cross-company: recovery notify is scoped to the actor company', async () => {
    useDb({
      docs: openDoc(30, {
        interruption: { since: 'x', alertSent: true, alertedAt: 'x' },
      }),
      attendanceRows: [ACTIVE_ATT],
    });
    const r = res();
    await ctrl.trackingAppendPos(req({ ...EMP, body: posBody() }), r);
    expect(notifyInterruption).toHaveBeenCalledTimes(1);
    for (const call of notifyInterruption.mock.calls) {
      expect(call[0].companyId).toBe('COMP_A');
    }
  });
});
