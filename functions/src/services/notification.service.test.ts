/**
 * Notification recipient tests: tracking/GPS alerts must reach tenant
 * admins (role 'admin') only, while getCompanyAdmins keeps its legacy
 * ['admin','super_admin'] default for unrelated notification categories.
 */
import {
  getCompanyAdmins,
  notifyCompanyAdminsOfTrackingEvent,
  notifyCompanyAdminsOfSuspiciousLocation,
  notifyCompanyAdminsOfTrackingInterruption,
  reconcilePendingAdminNotifies,
} from './notification.service';

// ---- Predicate-aware fake Firestore (same pattern as
// trackingHeartbeat.test.ts) ----------------------------------------

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

let autoId = 0;

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
  const store: Record<string, Row[]> = {};
  for (const [name, rows] of Object.entries(collections)) {
    store[name] = rows.map((r) => ({ ...r }));
  }

  const collection = (name: string) => {
    const preds: Pred[] = [];
    let maxResults = Infinity;
    const rows = () => (store[name] = store[name] ?? []);
    const api: any = {
      doc: (id?: string) => {
        const docId = id ?? `auto_${++autoId}`;
        const ref = {
          id: docId,
          get: async () => {
            const d = rows().find((r) => r.id === docId);
            return { exists: !!d, data: () => d, ref };
          },
          update: jest.fn(async (data: Row) => {
            const d = rows().find((r) => r.id === docId);
            if (d) applyUpdate(d, data);
          }),
          set: jest.fn(async (data: Row, _o?: any) => {
            const d = rows().find((r) => r.id === docId);
            if (d) applyUpdate(d, data);
            else rows().push({ id: docId, ...data });
          }),
        };
        return ref;
      },
      where: (field: string, op: string, value: any) => {
        preds.push({ field, op, value });
        return api;
      },
      limit: (n: number) => { maxResults = n; return api; },
      get: async () => {
        const matched = rows()
          .filter((r) => preds.every((p) => match(r, p)))
          .slice(0, maxResults);
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

  return { collection, _store: store };
}

const sendEachForMulticast = jest.fn(async (..._a: any[]) => ({
  responses: [] as any[],
  successCount: 0,
  failureCount: 0,
}));

jest.mock('../config/firebase', () => ({
  db: {
    collection: (...args: any[]) => (currentDb as any).collection(...args),
  },
  messaging: {
    sendEachForMulticast: (...args: any[]) => sendEachForMulticast(...args),
  },
}));

let currentDb: ReturnType<typeof makeDb>;

const USERS = [
  { id: 'U_ADMIN', companyId: 'COMP_A', role: 'admin', empid: null },
  { id: 'U_SUPER', companyId: 'COMP_A', role: 'super_admin', empid: null },
  { id: 'U_PLATFORM', companyId: 'COMP_A', role: 'platform_admin', empid: null },
  { id: 'U_EMP', companyId: 'COMP_A', role: 'employee', empid: 'EMP1' },
  { id: 'U_HR', companyId: 'COMP_A', role: 'hr', empid: null },
  { id: 'U_OTHER_ADMIN', companyId: 'COMP_B', role: 'admin', empid: null },
];

function seed() {
  currentDb = makeDb({
    users: USERS,
    notifications: [],
    deviceRegistrations: [],
    employees: [{ empid: 'EMP1', companyId: 'COMP_A', name: 'Alice' }],
    tracking: [],
  });
}

describe('getCompanyAdmins', () => {
  beforeEach(seed);

  test('default role set keeps admin + super_admin (other callers)', async () => {
    const admins = await getCompanyAdmins('COMP_A');
    expect(admins.map((a) => a.userId).sort())
      .toEqual(['U_ADMIN', 'U_SUPER']);
  });

  test("roles ['admin'] excludes super_admin/platform_admin/others", async () => {
    const admins = await getCompanyAdmins('COMP_A', ['admin']);
    expect(admins.map((a) => a.userId)).toEqual(['U_ADMIN']);
  });

  test('companyId filter: other-company admin is never returned', async () => {
    const admins = await getCompanyAdmins('COMP_B', ['admin']);
    expect(admins.map((a) => a.userId)).toEqual(['U_OTHER_ADMIN']);
    const aAdmins = await getCompanyAdmins('COMP_A', ['admin']);
    expect(aAdmins.map((a) => a.userId)).not.toContain('U_OTHER_ADMIN');
  });
});

describe('notifyCompanyAdminsOfTrackingInterruption recipients', () => {
  beforeEach(() => {
    seed();
    sendEachForMulticast.mockClear();
  });

  test("gps_delayed notifies only role 'admin' users of the company", async () => {
    const out = await notifyCompanyAdminsOfTrackingInterruption({
      companyId: 'COMP_A',
      empid: 'EMP1',
      employeeName: 'Alice',
      kind: 'gps_delayed',
      sinceTs: '2026-10-21T08:00:00.000Z',
      dateIso: '2026-10-21',
    });

    expect(out.records).toBe(1);
    const notifs = currentDb._store.notifications;
    expect(notifs).toHaveLength(1);
    expect(notifs[0].recipientUserId).toBe('U_ADMIN');
    expect(notifs[0].companyId).toBe('COMP_A');
    expect(notifs[0].type).toBe('TRACKING_GPS_DELAYED');
    expect(notifs[0].title).toBe('GPS Updates Delayed');
  });

  test('gps_recovered notifies only the tenant admin', async () => {
    const out = await notifyCompanyAdminsOfTrackingInterruption({
      companyId: 'COMP_A',
      empid: 'EMP1',
      employeeName: 'Alice',
      kind: 'gps_recovered',
      sinceTs: '2026-10-21T09:00:00.000Z',
      dateIso: '2026-10-21',
    });

    expect(out.records).toBe(1);
    const notifs = currentDb._store.notifications;
    expect(notifs.map((n: Row) => n.recipientUserId)).toEqual(['U_ADMIN']);
    expect(notifs[0].type).toBe('TRACKING_GPS_RECOVERED');
    expect(notifs[0].title).toBe('GPS Updates Recovered');
  });

  test('interrupted (Tracking Interrupted) is admin-only too', async () => {
    const out = await notifyCompanyAdminsOfTrackingInterruption({
      companyId: 'COMP_A',
      empid: 'EMP1',
      employeeName: 'Alice',
      kind: 'interrupted',
      sinceTs: '2026-10-21T10:00:00.000Z',
      dateIso: '2026-10-21',
    });

    expect(out.records).toBe(1);
    expect(currentDb._store.notifications[0].recipientUserId)
      .toBe('U_ADMIN');
    expect(currentDb._store.notifications[0].title)
      .toBe('Tracking Interrupted');
  });

  test('company with no admin produces no notification records', async () => {
    currentDb = makeDb({
      users: [
        { id: 'U_SUPER', companyId: 'COMP_C', role: 'super_admin', empid: null },
      ],
      notifications: [],
      deviceRegistrations: [],
      employees: [],
      tracking: [],
    });

    const out = await notifyCompanyAdminsOfTrackingInterruption({
      companyId: 'COMP_C',
      empid: 'EMP9',
      employeeName: 'Bob',
      kind: 'gps_delayed',
      sinceTs: '2026-10-21T08:00:00.000Z',
      dateIso: '2026-10-21',
    });

    expect(out.records).toBe(0);
    expect(currentDb._store.notifications).toHaveLength(0);
  });
});

describe('notifyCompanyAdminsOfTrackingEvent recipients', () => {
  beforeEach(() => {
    seed();
    sendEachForMulticast.mockClear();
  });

  test('GPS Turned Off (location_disabled) reaches admin only', async () => {
    const out = await notifyCompanyAdminsOfTrackingEvent({
      companyId: 'COMP_A',
      empid: 'EMP1',
      employeeName: 'Alice',
      eventType: 'location_disabled',
      eventTs: '2026-10-21T08:00:00.000Z',
      dateIso: '2026-10-21',
    });

    expect(out.records).toBe(1);
    const notifs = currentDb._store.notifications;
    expect(notifs.map((n: Row) => n.recipientUserId)).toEqual(['U_ADMIN']);
    expect(notifs[0].type).toBe('LOCATION_DISABLED');
    expect(notifs[0].title).toBe('Employee GPS Turned Off');
  });

  test('Location Permission Revoked reaches admin only', async () => {
    const out = await notifyCompanyAdminsOfTrackingEvent({
      companyId: 'COMP_A',
      empid: 'EMP1',
      employeeName: 'Alice',
      eventType: 'permission_revoked',
      eventTs: '2026-10-21T08:00:00.000Z',
      dateIso: '2026-10-21',
    });

    expect(out.records).toBe(1);
    const notifs = currentDb._store.notifications;
    expect(notifs.map((n: Row) => n.recipientUserId)).toEqual(['U_ADMIN']);
    expect(notifs[0].type).toBe('PERMISSION_REVOKED');
    expect(notifs[0].title).toBe('Location Permission Revoked');
  });
});

describe('notifyCompanyAdminsOfSuspiciousLocation recipients', () => {
  beforeEach(() => {
    seed();
    sendEachForMulticast.mockClear();
  });

  test('suspicious-location alert reaches admin only', async () => {
    const out = await notifyCompanyAdminsOfSuspiciousLocation({
      companyId: 'COMP_A',
      empid: 'EMP1',
      employeeName: 'Alice',
      flags: ['replay'],
      eventTs: '2026-10-21T08:00:00.000Z',
      dateIso: '2026-10-21',
    });

    expect(out.records).toBe(1);
    const notifs = currentDb._store.notifications;
    expect(notifs.map((n: Row) => n.recipientUserId)).toEqual(['U_ADMIN']);
    expect(notifs[0].type).toBe('SUSPICIOUS_LOCATION');
    expect(notifs[0].companyId).toBe('COMP_A');
  });
});

describe('reconcilePendingAdminNotifies (retry path)', () => {
  const TS = '2026-10-21T08:30:00.000Z';

  function pendingDoc(over: Row = {}): Row {
    return {
      id: `COMP_A_EMP1_2026-10-21`,
      empid: 'EMP1', companyId: 'COMP_A', dateIso: '2026-10-21',
      endedAt: null,
      pendingAdminNotify: true,
      pendingAdminNotifyEvent: {
        type: 'location_disabled', ts: TS,
        empid: 'EMP1', dateIso: '2026-10-21',
      },
      ...over,
    };
  }

  beforeEach(() => {
    seed();
    sendEachForMulticast.mockClear();
  });

  test('retry notifies admin only and clears the pending flag', async () => {
    currentDb._store.tracking.push(pendingDoc());

    const out = await reconcilePendingAdminNotifies('COMP_A');
    expect(out.notified).toBe(1);

    const notifs = currentDb._store.notifications;
    expect(notifs).toHaveLength(1);
    expect(notifs[0].recipientUserId).toBe('U_ADMIN');
    expect(notifs[0].type).toBe('LOCATION_DISABLED');
    expect(currentDb._store.tracking[0].pendingAdminNotify).toBeUndefined();
  });

  test('existing record for the same event is not duplicated', async () => {
    currentDb._store.tracking.push(pendingDoc());
    currentDb._store.notifications.push({
      id: 'N_EXIST',
      companyId: 'COMP_A',
      recipientUserId: 'U_ADMIN',
      entityType: 'tracking_event',
      entityId: 'EMP1_2026-10-21',
      type: 'LOCATION_DISABLED',
      data: { eventTs: TS },
    });

    const out = await reconcilePendingAdminNotifies('COMP_A');
    expect(out.notified).toBe(0);
    expect(currentDb._store.notifications).toHaveLength(1);
    expect(currentDb._store.tracking[0].pendingAdminNotify).toBeUndefined();
  });

  test('queued location_enabled with no session OFF event is cleared, not sent', async () => {
    currentDb._store.tracking.push(pendingDoc({
      events: [],
      startedAt: '2026-10-21T08:00:00.000Z',
      currentSessionStartedAt: '2026-10-21T08:00:00.000Z',
      pendingAdminNotifyEvent: {
        type: 'location_enabled', ts: TS,
        empid: 'EMP1', dateIso: '2026-10-21',
      },
    }));

    const out = await reconcilePendingAdminNotifies('COMP_A');
    expect(out.notified).toBe(0);
    expect(currentDb._store.notifications).toHaveLength(0);
    expect(currentDb._store.tracking[0].pendingAdminNotify).toBeUndefined();
  });

  test('queued location_enabled with session OFF event notifies admin', async () => {
    currentDb._store.tracking.push(pendingDoc({
      events: [
        { type: 'location_disabled', ts: '2026-10-21T08:15:00.000Z' },
      ],
      startedAt: '2026-10-21T08:00:00.000Z',
      currentSessionStartedAt: '2026-10-21T08:00:00.000Z',
      pendingAdminNotifyEvent: {
        type: 'location_enabled', ts: TS,
        empid: 'EMP1', dateIso: '2026-10-21',
      },
    }));

    const out = await reconcilePendingAdminNotifies('COMP_A');
    expect(out.notified).toBe(1);
    const notifs = currentDb._store.notifications;
    expect(notifs).toHaveLength(1);
    expect(notifs[0].recipientUserId).toBe('U_ADMIN');
    expect(notifs[0].type).toBe('LOCATION_ENABLED');
    expect(notifs[0].title).toBe('Employee GPS Restored');
  });

  test('OFF event from before the session boundary does not qualify', async () => {
    currentDb._store.tracking.push(pendingDoc({
      // Session reopened at 12:00; the OFF event predates the boundary.
      events: [
        { type: 'location_disabled', ts: '2026-10-21T09:15:00.000Z' },
      ],
      startedAt: '2026-10-21T08:00:00.000Z',
      currentSessionStartedAt: '2026-10-21T12:00:00.000Z',
      pendingAdminNotifyEvent: {
        type: 'location_enabled', ts: TS,
        empid: 'EMP1', dateIso: '2026-10-21',
      },
    }));

    const out = await reconcilePendingAdminNotifies('COMP_A');
    expect(out.notified).toBe(0);
    expect(currentDb._store.notifications).toHaveLength(0);
    expect(currentDb._store.tracking[0].pendingAdminNotify).toBeUndefined();
  });
});
