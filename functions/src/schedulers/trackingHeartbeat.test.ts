/**
 * Missing-heartbeat sweep tests: stale-session detection, duplicate-alert
 * suppression, attendance-active gating, recovery flag clearing, and
 * cross-company notification isolation.
 */
import { runTrackingHeartbeatSweep, runInterruptionCleanup, runGpsGapSweep }
  from './trackingHeartbeat';

// ---- Predicate-aware fake Firestore ------------------------------------

type Row = Record<string, any>;

type Pred = { field: string; op: string; value: any };

function match(row: Row, p: Pred): boolean {
  const v = p.field.split('.').reduce((o: any, k) => o?.[k], row);
  switch (p.op) {
    case '==': return v === p.value;
    case '!=': return v !== p.value;
    case '<': return v !== undefined && v !== null && v < p.value;
    case '<=': return v !== undefined && v !== null && v <= p.value;
    case '>': return v !== undefined && v !== null && v > p.value;
    case '>=': return v !== undefined && v !== null && v >= p.value;
    case 'in': return (p.value as any[]).includes(v);
    default: return true;
  }
}

function applyUpdate(target: Row, data: Row) {
  for (const [k, v] of Object.entries(data)) {
    if (v !== null && typeof v === 'object' &&
        ((v as any)._methodName === 'FieldValue.delete' ||
          v.constructor?.name === 'DeleteTransform')) {
      delete target[k];
    } else {
      target[k] = v;
    }
  }
}

function makeDb(collections: Record<string, Row[]>) {
  // Deep-copy so tests can mutate inputs without cross-talk.
  const store: Record<string, Row[]> = {};
  for (const [name, rows] of Object.entries(collections)) {
    store[name] = rows.map((r) => ({ ...r }));
  }

  const collection = (name: string) => {
    const preds: Pred[] = [];
    let maxResults = Infinity;
    let cursorId: string | null = null;
    const rows = () => (store[name] = store[name] ?? []);
    const api: any = {
      doc: (id: string) => {
        const ref = {
          get: async () => {
            const d = rows().find((r) => r.id === id);
            return { exists: !!d, data: () => d, ref };
          },
          update: jest.fn(async (data: Row) => {
            const d = rows().find((r) => r.id === id);
            if (d) applyUpdate(d, data);
          }),
          set: jest.fn(async (data: Row, _o?: any) => {
            const d = rows().find((r) => r.id === id);
            if (d) applyUpdate(d, data);
            else rows().push({ id, ...data });
          }),
        };
        return ref;
      },
      where: (field: string, op: string, value: any) => {
        preds.push({ field, op, value });
        return api;
      },
      limit: (n: number) => { maxResults = n; return api; },
      startAfter: (snapDoc: any) => { cursorId = snapDoc?.id ?? null; return api; },
      get: async () => {
        let matched = rows()
          .filter((r) => preds.every((p) => match(r, p)));
        if (cursorId != null) {
          const idx = matched.findIndex((r) => r.id === cursorId);
          if (idx >= 0) matched = matched.slice(idx + 1);
        }
        matched = matched.slice(0, maxResults);
        return {
          empty: matched.length === 0,
          size: matched.length,
          docs: matched.map((d) => ({
            id: d.id,
            data: () => d,
            ref: api.doc(d.id),
          })),
        };
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
    _store: store,
  };
}

const notifyInterruption =
  jest.fn(async (..._a: any[]) => ({ sent: 1, failed: 0, records: 1 }));
jest.mock('../services/notification.service', () => ({
  notifyCompanyAdminsOfTrackingInterruption: (...args: any[]) =>
    notifyInterruption(...args),
  notifyCompanyAdminsOfTrackingEvent: jest.fn(async (..._a: any[]) =>
    ({ sent: 0, failed: 0, records: 0 })),
}));

jest.mock('../config/firebase', () => ({
  db: {
    collection: (...args: any[]) => (currentDb as any).collection(...args),
    runTransaction: (...args: any[]) =>
      (currentDb as any).runTransaction(...args),
  },
}));

let currentDb: ReturnType<typeof makeDb>;

const DAY = '2026-10-12';
const ACTIVE_ATT =
  { empid: 'EMP1', companyId: 'COMP_A', date: DAY, checkIn: '08:00', checkOut: '' };

function trackingDoc(over: Partial<Row> = {}): Row {
  return {
    id: `COMP_A_EMP1_${DAY}`,
    empid: 'EMP1', companyId: 'COMP_A', dateIso: DAY,
    pathMap: [], events: [],
    startedAt: new Date(Date.now() - 3 * 3600000).toISOString(),
    endedAt: null,
    lastUpdateAt: new Date(Date.now() - 60 * 60000).toISOString(), // stale
    ...over,
  };
}

describe('runTrackingHeartbeatSweep', () => {
  beforeEach(() => notifyInterruption.mockClear());

  test('stale open session + active attendance -> alert sent, flag set', async () => {
    currentDb = makeDb({
      tracking: [trackingDoc()],
      attendance: [ACTIVE_ATT],
      employees: [{ empid: 'EMP1', companyId: 'COMP_A', name: 'Alice' }],
    });
    const out = await runTrackingHeartbeatSweep();
    expect(out.alerted).toBe(1);
    expect(notifyInterruption).toHaveBeenCalledWith(
      expect.objectContaining({
        companyId: 'COMP_A', empid: 'EMP1', employeeName: 'Alice',
        kind: 'interrupted',
      }));
    const doc = currentDb._store.tracking[0];
    expect(doc.interruption?.alertSent).toBe(true);
    expect(doc.interruption?.since).toBe(doc.lastUpdateAt);
  });

  test('fresh session is never scanned (lastUpdateAt newer than cutoff)', async () => {
    currentDb = makeDb({
      tracking: [trackingDoc({
        lastUpdateAt: new Date(Date.now() - 5 * 60000).toISOString(),
      })],
      attendance: [ACTIVE_ATT],
    });
    const out = await runTrackingHeartbeatSweep();
    expect(out.scanned).toBe(0);
    expect(out.alerted).toBe(0);
    expect(notifyInterruption).not.toHaveBeenCalled();
  });

  test('already-alerted gap produces no duplicate alert', async () => {
    currentDb = makeDb({
      tracking: [trackingDoc({
        interruption: {
          since: 'x', alertSent: true,
          alertedAt: new Date().toISOString(),
        },
      })],
      attendance: [ACTIVE_ATT],
    });
    const out = await runTrackingHeartbeatSweep();
    expect(out.scanned).toBe(1);
    expect(out.alreadyAlerted).toBe(1);
    expect(out.alerted).toBe(0);
    expect(notifyInterruption).not.toHaveBeenCalled();
  });

  test('no active attendance (employee checked out / absent) -> no alert', async () => {
    currentDb = makeDb({
      tracking: [trackingDoc()],
      attendance: [
        { ...ACTIVE_ATT, checkOut: '18:00' }, // session closed
      ],
    });
    const out = await runTrackingHeartbeatSweep();
    expect(out.noActiveAttendance).toBe(1);
    expect(out.alerted).toBe(0);
    expect(notifyInterruption).not.toHaveBeenCalled();
  });

  test('closed tracking session (endedAt set) is never scanned', async () => {
    currentDb = makeDb({
      tracking: [trackingDoc({ endedAt: new Date().toISOString() })],
      attendance: [ACTIVE_ATT],
    });
    const out = await runTrackingHeartbeatSweep();
    expect(out.scanned).toBe(0);
    expect(notifyInterruption).not.toHaveBeenCalled();
  });

  test('cross-company: other-company stale session never notifies COMP_A admins', async () => {
    currentDb = makeDb({
      tracking: [trackingDoc({
        id: 'COMP_B_EMP9_2026-10-12',
        empid: 'EMP9', companyId: 'COMP_B',
      })],
      attendance: [
        { empid: 'EMP9', companyId: 'COMP_B', date: DAY, checkIn: '08:00', checkOut: '' },
      ],
      employees: [{ empid: 'EMP9', companyId: 'COMP_B', name: 'Bob' }],
    });
    const out = await runTrackingHeartbeatSweep();
    expect(out.alerted).toBe(1);
    for (const call of notifyInterruption.mock.calls) {
      expect(call[0].companyId).toBe('COMP_B'); // only that company's admins
      expect(call[0].companyId).not.toBe('COMP_A');
    }
  });

  test('configurable threshold respected', async () => {
    currentDb = makeDb({
      tracking: [trackingDoc({
        lastUpdateAt: new Date(Date.now() - 10 * 60000).toISOString(),
      })],
      attendance: [ACTIVE_ATT],
    });
    // Default 45 min: 10-min gap must NOT alert.
    const out = await runTrackingHeartbeatSweep();
    expect(out.scanned).toBe(0);
    // With a 5-min threshold the same doc is stale.
    const out5 = await runTrackingHeartbeatSweep(new Date(), { staleAfterMin: 5 });
    expect(out5.alerted).toBe(1);
  });

  test('regression: >300 stale legacy docs cannot starve new-format sessions', async () => {
    // Prod reality: ~1800 open tracking docs in legacy {empid}_{date}
    // format with no companyId field. Before the companyId >= '' query
    // filter they matched endedAt==null + lastUpdateAt<cutoff, sorted
    // oldest-first, filled the 300 batch, and were skipped on !companyId
    // - so new-format stale sessions could never be reached. The query
    // now excludes field-missing docs server-side.
    const legacy = Array.from({ length: 350 }, (_, i) => ({
      id: `EMP${i}_2026-04-01`,
      empid: `EMP${i}`,
      dateIso: '2026-04-01',
      pathMap: [], events: [],
      startedAt: '2026-04-01T08:00:00.000Z',
      endedAt: null,
      lastUpdateAt: '2026-04-01T09:00:00.000Z', // very stale, oldest first
      // note: NO companyId field - legacy doc shape
    }));
    currentDb = makeDb({
      tracking: [
        ...legacy,
        trackingDoc(), // COMP_A/EMP1 stale, new format
        trackingDoc({
          id: `COMP_B_EMP9_${DAY}`, empid: 'EMP9', companyId: 'COMP_B',
        }),
      ],
      attendance: [
        ACTIVE_ATT,
        { empid: 'EMP9', companyId: 'COMP_B', date: DAY, checkIn: '08:00', checkOut: '' },
      ],
      employees: [
        { empid: 'EMP1', companyId: 'COMP_A', name: 'Alice' },
        { empid: 'EMP9', companyId: 'COMP_B', name: 'Bob' },
      ],
    });
    const out = await runTrackingHeartbeatSweep();
    expect(out.scanned).toBe(2); // legacy docs excluded by the query itself
    expect(out.alerted).toBe(2);
    const companies = notifyInterruption.mock.calls
      .map((c) => c[0].companyId).sort();
    expect(companies).toEqual(['COMP_A', 'COMP_B']); // isolation preserved
  });

  test('regression: >300 eligible sessions across companies - pagination prevents starvation', async () => {
    // 175 stale COMP_A + 175 stale COMP_B new-format sessions = 350
    // eligible docs > one SWEEP_BATCH_LIMIT page. Cursor pagination must
    // process ALL of them in a single run - neither company starves.
    const mkDoc = (co: string, i: number) => ({
      id: `${co}_W${i}_${DAY}`,
      empid: `W${i}`, companyId: co, dateIso: DAY,
      pathMap: [], events: [],
      startedAt: new Date(Date.now() - 3 * 3600000).toISOString(),
      endedAt: null,
      lastUpdateAt: new Date(Date.now() - 120 * 60000).toISOString(),
    });
    const docsA = Array.from({ length: 175 }, (_, i) => mkDoc('COMP_A', i));
    const docsB = Array.from({ length: 175 }, (_, i) => mkDoc('COMP_B', i));
    currentDb = makeDb({
      tracking: [...docsA, ...docsB],
      attendance: [
        ...docsA.map((d) => ({
          empid: d.empid, companyId: 'COMP_A', date: DAY,
          checkIn: '08:00', checkOut: '',
        })),
        ...docsB.map((d) => ({
          empid: d.empid, companyId: 'COMP_B', date: DAY,
          checkIn: '08:00', checkOut: '',
        })),
      ],
      employees: [],
    });
    const out = await runTrackingHeartbeatSweep();
    expect(out.scanned).toBe(350);
    expect(out.alerted).toBe(350);
    const counts = new Map<string, number>();
    for (const c of notifyInterruption.mock.calls) {
      const co = c[0].companyId;
      counts.set(co, (counts.get(co) || 0) + 1);
    }
    expect(counts.get('COMP_A')).toBe(175);
    expect(counts.get('COMP_B')).toBe(175); // no company starvation
    // second sweep: all flagged -> zero new alerts (no duplicates)
    notifyInterruption.mockClear();
    const out2 = await runTrackingHeartbeatSweep();
    expect(out2.alerted).toBe(0);
    expect(out2.alreadyAlerted).toBe(350);
  });

  test('claim transaction is idempotent for a doc already flagged mid-sweep', async () => {
    // The sweep reads the listing once, then re-reads inside a tx before
    // marking. The fake db re-reads on every tx.get, so pre-seeding the
    // flag exercises the same guard a racing /pos write would hit.
    currentDb = makeDb({
      tracking: [trackingDoc({
        interruption: {
          since: 'y', alertSent: true, alertedAt: new Date().toISOString(),
        },
      })],
      attendance: [ACTIVE_ATT],
    });
    const out = await runTrackingHeartbeatSweep();
    expect(out.alerted).toBe(0);
    expect(out.alreadyAlerted).toBe(1);
    expect(notifyInterruption).not.toHaveBeenCalled();
  });
});

describe('runGpsGapSweep', () => {
  beforeEach(() => notifyInterruption.mockClear());

  // Contact is fresh (device alive) but no valid GPS fix - the case the
  // contact sweep cannot see.
  const gpsStaleDoc = (over: Partial<Row> = {}) => trackingDoc({
    lastUpdateAt: new Date(Date.now() - 3 * 60000).toISOString(), // fresh contact
    lastHeartbeatAt: new Date(Date.now() - 3 * 60000).toISOString(),
    lastGpsFixAt: new Date(Date.now() - 50 * 60000).toISOString(), // stale fix
    lastGpsState: 'no_fix',
    ...over,
  });

  test('live contact + stale GPS fix -> gps_delayed alert, flag set', async () => {
    const doc = gpsStaleDoc();
    currentDb = makeDb({
      tracking: [doc],
      attendance: [ACTIVE_ATT],
      employees: [{ empid: 'EMP1', companyId: 'COMP_A', name: 'Alice' }],
    });
    const out = await runGpsGapSweep();
    expect(out.alerted).toBe(1);
    expect(notifyInterruption).toHaveBeenCalledWith(
      expect.objectContaining({
        companyId: 'COMP_A', empid: 'EMP1', employeeName: 'Alice',
        kind: 'gps_delayed', sinceTs: doc.lastGpsFixAt,
      }));
    expect(currentDb._store.tracking[0].gpsGap?.alertSent).toBe(true);
  });

  test('session that never produced a fix alerts off startedAt', async () => {
    const doc = gpsStaleDoc({ lastGpsFixAt: undefined });
    currentDb = makeDb({
      tracking: [doc],
      attendance: [ACTIVE_ATT],
      employees: [],
    });
    const out = await runGpsGapSweep();
    expect(out.alerted).toBe(1);
    expect(notifyInterruption.mock.calls[0][0].sinceTs).toBe(doc.startedAt);
  });

  test('stationary employee: fresh fix inside grace -> no alert', async () => {
    currentDb = makeDb({
      tracking: [gpsStaleDoc({
        lastGpsFixAt: new Date(Date.now() - 10 * 60000).toISOString(),
        // pathMap point is old - GPS freshness, not route freshness, wins.
        pathMap: [{ lat: 1, lng: 2, ts: new Date(Date.now() - 3 * 3600000).toISOString() }],
      })],
      attendance: [ACTIVE_ATT],
    });
    const out = await runGpsGapSweep();
    expect(out.alerted).toBe(0);
    expect(notifyInterruption).not.toHaveBeenCalled();
  });

  test('fresh stored point (no lastGpsFixAt) counts as a fresh fix', async () => {
    currentDb = makeDb({
      tracking: [gpsStaleDoc({
        lastGpsFixAt: undefined,
        pathMap: [{ lat: 1, lng: 2,
          capturedAt: new Date(Date.now() - 10 * 60000).toISOString(),
          ts: 'x' }],
      })],
      attendance: [ACTIVE_ATT],
    });
    const out = await runGpsGapSweep();
    expect(out.alerted).toBe(0);
  });

  test('stale contact -> skipped (45-min contact sweep owns that case)',
      async () => {
    currentDb = makeDb({
      tracking: [gpsStaleDoc({
        lastUpdateAt: new Date(Date.now() - 50 * 60000).toISOString(),
        lastHeartbeatAt: new Date(Date.now() - 50 * 60000).toISOString(),
      })],
      attendance: [ACTIVE_ATT],
    });
    const out = await runGpsGapSweep();
    expect(out.contactStale).toBe(1);
    expect(out.alerted).toBe(0);
  });

  test('confirmed cause (service_off / perm_denied) -> no duplicate alert',
      async () => {
    for (const state of ['service_off', 'perm_denied']) {
      notifyInterruption.mockClear();
      currentDb = makeDb({
        tracking: [gpsStaleDoc({ lastGpsState: state })],
        attendance: [ACTIVE_ATT],
      });
      const out = await runGpsGapSweep();
      expect(out.confirmedCause).toBe(1);
      expect(out.alerted).toBe(0);
      expect(notifyInterruption).not.toHaveBeenCalled();
    }
  });

  test('already-alerted gap -> exactly one alert per gap', async () => {
    currentDb = makeDb({
      tracking: [gpsStaleDoc({
        gpsGap: { since: 'x', alertSent: true,
          alertedAt: new Date().toISOString() },
      })],
      attendance: [ACTIVE_ATT],
    });
    const out = await runGpsGapSweep();
    expect(out.alreadyAlerted).toBe(1);
    expect(out.alerted).toBe(0);
    // Second run on the now-flagged doc still alerts nothing.
    const out2 = await runGpsGapSweep();
    expect(out2.alerted).toBe(0);
    expect(notifyInterruption).not.toHaveBeenCalled();
  });

  test('no active attendance -> no alert (never alerts after check-out)',
      async () => {
    currentDb = makeDb({
      tracking: [gpsStaleDoc()],
      attendance: [{ ...ACTIVE_ATT, checkOut: '18:00' }],
    });
    const out = await runGpsGapSweep();
    expect(out.noActiveAttendance).toBe(1);
    expect(out.alerted).toBe(0);
  });

  test('closed session never scanned', async () => {
    currentDb = makeDb({
      tracking: [gpsStaleDoc({ endedAt: new Date().toISOString() })],
      attendance: [ACTIVE_ATT],
    });
    const out = await runGpsGapSweep();
    expect(out.scanned).toBe(0);
  });

  test('cross-company isolation: alert only reaches that company', async () => {
    currentDb = makeDb({
      tracking: [
        gpsStaleDoc(),
        gpsStaleDoc({
          id: `COMP_B_EMP9_${DAY}`, empid: 'EMP9', companyId: 'COMP_B',
        }),
      ],
      attendance: [
        ACTIVE_ATT,
        { empid: 'EMP9', companyId: 'COMP_B', date: DAY,
          checkIn: '08:00', checkOut: '' },
      ],
      employees: [],
    });
    const out = await runGpsGapSweep();
    expect(out.alerted).toBe(2);
    const companies = notifyInterruption.mock.calls
      .map((c) => c[0].companyId).sort();
    expect(companies).toEqual(['COMP_A', 'COMP_B']);
  });

  test('grace period respected: 20-min gap under 35-min threshold -> quiet',
      async () => {
    currentDb = makeDb({
      tracking: [gpsStaleDoc({
        lastGpsFixAt: new Date(Date.now() - 20 * 60000).toISOString(),
      })],
      attendance: [ACTIVE_ATT],
    });
    const out = await runGpsGapSweep();
    expect(out.alerted).toBe(0);
    // A 15-min override would flag the same gap.
    const out15 = await runGpsGapSweep(new Date(), { staleAfterMin: 15 });
    expect(out15.alerted).toBe(1);
  });
});

describe('runInterruptionCleanup', () => {
  test('clears interruption flags only on closed sessions', async () => {
    currentDb = makeDb({
      tracking: [
        trackingDoc({
          id: 'open_1', endedAt: null,
          interruption: { since: 'x', alertSent: true, alertedAt: 'x' },
        }),
        trackingDoc({
          id: 'closed_1', endedAt: new Date().toISOString(),
          interruption: { since: 'x', alertSent: true, alertedAt: 'x' },
        }),
      ],
    });
    const out = await runInterruptionCleanup();
    expect(out.cleared).toBe(1);
    expect(currentDb._store.tracking[0].interruption).toBeDefined(); // open kept
    expect(currentDb._store.tracking[1].interruption).toBeUndefined();
  });
});
