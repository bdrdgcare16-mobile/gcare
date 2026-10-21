/**
 * Notification recipient tests: tracking/GPS alerts must reach tenant
 * admins (role 'admin') only, while getCompanyAdmins keeps its legacy
 * ['admin','super_admin'] default for unrelated notification categories.
 */
import {
  getCompanyAdmins,
  notifyCompanyAdminsOfTrackingInterruption,
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
            if (d) Object.assign(d, data);
          }),
          set: jest.fn(async (data: Row, _o?: any) => {
            const d = rows().find((r) => r.id === docId);
            if (d) Object.assign(d, data);
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
