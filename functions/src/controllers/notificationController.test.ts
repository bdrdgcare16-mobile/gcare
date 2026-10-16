/**
 * Tests for notificationController (GET /notifications, unread-count,
 * read/unread, read-all) and the pendingAdminNotify reconciliation sweep
 * that listNotifications triggers for admins.
 *
 * Covers: authentication, tenant isolation (companyId + recipientUserId),
 * ownership enforcement on read-state mutations, and dedup-safe
 * reconciliation of GPS OFF/ON admin alerts.
 */
import * as ctrl from './notificationController';

// ---- Deterministic FieldValue sentinels --------------------------------
jest.mock('firebase-admin/firestore', () => ({
  FieldValue: {
    serverTimestamp: () => '__server_ts__',
    delete: () => '__DELETE__',
    arrayUnion: (v: any) => ({ __arrayUnion: v }),
  },
}));

// ---- In-memory Firestore fake -------------------------------------------

type Row = Record<string, any>;
type Seed = Record<string, Record<string, Row>>;

let autoId = 0;
const queryLog: { collection: string; filters: [string, string, any][] }[] = [];

function makeDb(seed: Seed) {
  const store: Seed = seed;

  function matches(d: Row, filters: [string, string, any][]) {
    return filters.every(([f, op, v]) => {
      const dv = d?.[f];
      if (op === '==') return dv === v;
      if (op === 'in') return Array.isArray(v) && v.includes(dv);
      return true;
    });
  }

  function applyUpdate(existing: Row | undefined, data: Row) {
    const out = { ...(existing ?? {}) };
    for (const [k, v] of Object.entries(data)) {
      if (v === '__DELETE__') delete out[k];
      else out[k] = v;
    }
    return out;
  }

  function docRef(name: string, id: string): any {
    return {
      id,
      get: async () => ({
        id,
        exists: store[name]?.[id] !== undefined,
        data: () => store[name]?.[id],
        ref: docRef(name, id),
      }),
      set: jest.fn(async (data: Row) => {
        (store[name] ??= {})[id] = data;
      }),
      update: jest.fn(async (data: Row) => {
        (store[name] ??= {})[id] = applyUpdate(store[name]?.[id], data);
      }),
    };
  }

  function query(
    name: string,
    filters: [string, string, any][] = [],
    order?: [string, 'asc' | 'desc'],
    limitN?: number,
  ): any {
    return {
      where: (f: string, op: string, v: any) =>
        query(name, [...filters, [f, op, v]], order, limitN),
      orderBy: (f: string, dir: 'asc' | 'desc' = 'asc') =>
        query(name, filters, [f, dir], limitN),
      limit: (n: number) => query(name, filters, order, n),
      count: () => ({
        get: async () => ({
          data: () => ({
            count: Object.values(store[name] ?? {}).filter((d) =>
              matches(d, filters),
            ).length,
          }),
        }),
      }),
      get: async () => {
        queryLog.push({ collection: name, filters });
        let rows = Object.entries(store[name] ?? {}).filter(([, d]) =>
          matches(d, filters),
        );
        if (order) {
          const [f, dir] = order;
          rows.sort((a, b) => {
            const av = String(a[1]?.[f] ?? '');
            const bv = String(b[1]?.[f] ?? '');
            return dir === 'desc' ? bv.localeCompare(av) : av.localeCompare(bv);
          });
        }
        if (limitN) rows = rows.slice(0, limitN);
        return {
          empty: rows.length === 0,
          size: rows.length,
          docs: rows.map(([id, d]) => ({
            id,
            data: () => d,
            ref: docRef(name, id),
          })),
        };
      },
    };
  }

  return {
    collection: (name: string) => ({
      doc: (id?: string) => docRef(name, id ?? `auto_${++autoId}`),
      add: async (data: Row) => {
        const id = `auto_${++autoId}`;
        (store[name] ??= {})[id] = data;
        return docRef(name, id);
      },
      where: (f: string, op: string, v: any) => query(name, [[f, op, v]]),
    }),
    batch: () => {
      const ops: [any, Row][] = [];
      return {
        update: (ref: any, data: Row) => ops.push([ref, data]),
        commit: async () => {
          for (const [ref, data] of ops) await ref.update(data);
        },
      };
    },
    _store: store,
  };
}

// Mock firebase config BEFORE controller/service import resolves db/messaging.
const sendEachForMulticast = jest.fn(async (msg: any) => ({
  responses: (msg.tokens ?? []).map(() => ({ success: true })),
}));

jest.mock('../config/firebase', () => ({
  db: {
    collection: (...args: any[]) => (currentDb as any).collection(...args),
    batch: () => (currentDb as any).batch(),
  },
  messaging: { sendEachForMulticast: (msg: any) => sendEachForMulticast(msg) },
}));

let currentDb: ReturnType<typeof makeDb>;
function useDb(seed: Seed) {
  currentDb = makeDb(seed);
  queryLog.length = 0;
  sendEachForMulticast.mockClear();
}

// ---- req/res helpers ----------------------------------------------------

function req(over: {
  userId?: string;
  role?: string;
  companyId?: string | null;
  params?: any;
  query?: any;
  body?: any;
  noUser?: boolean;
}) {
  return {
    user: over.noUser
      ? undefined
      : {
          userId: over.userId ?? 'admin-1',
          email: 'a@x.com',
          role: over.role ?? 'admin',
          empid: null,
          companyId: 'companyId' in over ? over.companyId : 'COMP_A',
        },
    params: over.params ?? {},
    query: over.query ?? {},
    body: over.body ?? {},
  } as any;
}

function res() {
  const r: any = { statusCode: 0, body: null };
  r.status = (c: number) => {
    r.statusCode = c;
    return r;
  };
  r.json = (b: any) => {
    r.body = b;
    if (r.statusCode === 0) r.statusCode = 200;
    return r;
  };
  return r;
}

const notif = (over: Partial<Row> = {}): Row => ({
  companyId: 'COMP_A',
  recipientUserId: 'admin-1',
  type: 'LOCATION_DISABLED',
  title: 'Employee GPS Turned Off',
  body: 'X turned OFF location',
  entityType: 'tracking_event',
  entityId: 'EMP001_2026-10-12',
  data: { empid: 'EMP001', eventType: 'location_disabled', eventTs: '2026-10-12T08:00:00Z', dateIso: '2026-10-12' },
  isRead: false,
  pushStatus: 'sent',
  createdAt: '2026-10-12T08:00:01Z',
  readAt: null,
  ...over,
});

// ---- Tests ---------------------------------------------------------------

describe('GET /notifications', () => {
  test('rejects unauthenticated requests', async () => {
    useDb({});
    const r = res();
    await ctrl.listNotifications(req({ noUser: true }), r);
    expect(r.statusCode).toBe(401);
  });

  test('returns only notifications owned by token companyId + userId', async () => {
    useDb({
      notifications: {
        n1: notif(),
        n2: notif({ recipientUserId: 'admin-2' }), // same company, other user
        n3: notif({ companyId: 'COMP_B' }),        // other company
        n4: notif({ isRead: true }),
      },
    });
    const r = res();
    await ctrl.listNotifications(req({}), r);
    expect(r.statusCode).toBe(200);
    const ids = r.body.notifications.map((n: any) => n.id).sort();
    expect(ids).toEqual(['n1', 'n4']);
  });

  test('unreadOnly=true filters read items', async () => {
    useDb({
      notifications: { n1: notif(), n4: notif({ isRead: true }) },
    });
    const r = res();
    await ctrl.listNotifications(req({ query: { unreadOnly: 'true' } }), r);
    expect(r.body.notifications.map((n: any) => n.id)).toEqual(['n1']);
  });
});

describe('GET /notifications/unread-count', () => {
  test('counts only own unread notifications', async () => {
    useDb({
      notifications: {
        n1: notif(),
        n2: notif(),
        n3: notif({ isRead: true }),
        n4: notif({ recipientUserId: 'admin-2' }),
        n5: notif({ companyId: 'COMP_B' }),
      },
    });
    const r = res();
    await ctrl.unreadCount(req({}), r);
    expect(r.statusCode).toBe(200);
    expect(r.body.count).toBe(2);
  });
});

describe('read-state endpoints', () => {
  test('markRead flips own notification', async () => {
    const seed: Seed = { notifications: { n1: notif() } };
    useDb(seed);
    const r = res();
    await ctrl.markRead(req({ params: { id: 'n1' } }), r);
    expect(r.statusCode).toBe(200);
    expect(currentDb._store.notifications.n1.isRead).toBe(true);
    expect(currentDb._store.notifications.n1.readAt).toBe('__server_ts__');
  });

  test('markUnread resets state', async () => {
    useDb({ notifications: { n1: notif({ isRead: true, readAt: 'x' }) } });
    const r = res();
    await ctrl.markUnread(req({ params: { id: 'n1' } }), r);
    expect(r.statusCode).toBe(200);
    expect(currentDb._store.notifications.n1.isRead).toBe(false);
    expect(currentDb._store.notifications.n1.readAt).toBeNull();
  });

  test('cannot mark another company\'s notification (404, unchanged)', async () => {
    useDb({ notifications: { n1: notif({ companyId: 'COMP_B' }) } });
    const r = res();
    await ctrl.markRead(req({ params: { id: 'n1' } }), r);
    expect(r.statusCode).toBe(404);
    expect(currentDb._store.notifications.n1.isRead).toBe(false);
  });

  test('cannot mark another user\'s notification (404, unchanged)', async () => {
    useDb({ notifications: { n1: notif({ recipientUserId: 'admin-2' }) } });
    const r = res();
    await ctrl.markRead(req({ params: { id: 'n1' } }), r);
    expect(r.statusCode).toBe(404);
    expect(currentDb._store.notifications.n1.isRead).toBe(false);
  });

  test('markAllRead marks only own unread', async () => {
    useDb({
      notifications: {
        n1: notif(),
        n2: notif(),
        n3: notif({ isRead: true }),
        n4: notif({ recipientUserId: 'admin-2' }),
        n5: notif({ companyId: 'COMP_B' }),
      },
    });
    const r = res();
    await ctrl.markAllRead(req({}), r);
    expect(r.statusCode).toBe(200);
    expect(r.body.marked).toBe(2);
    const s = currentDb._store.notifications;
    expect(s.n1.isRead).toBe(true);
    expect(s.n2.isRead).toBe(true);
    expect(s.n3.isRead).toBe(true);
    expect(s.n4.isRead).toBe(false); // untouched - other user
    expect(s.n5.isRead).toBe(false); // untouched - other company
  });
});

describe('pendingAdminNotify reconciliation', () => {
  const flaggedTracking = (over: Partial<Row> = {}): Row => ({
    empid: 'EMP001',
    companyId: 'COMP_A',
    dateIso: '2026-10-12',
    pathMap: [],
    events: [],
    endedAt: null,
    pendingAdminNotify: true,
    pendingAdminNotifyEvent: {
      eventId: 'evt_1',
      type: 'location_disabled',
      ts: '2026-10-12T08:00:00Z',
      dateIso: '2026-10-12',
      empid: 'EMP001',
    },
    ...over,
  });
  const adminUser = { role: 'admin', companyId: 'COMP_A', name: 'Boss' };
  const employeeDoc = { empid: 'EMP001', companyId: 'COMP_A', name: 'Alice' };

  test('admin GET sweeps flagged doc: creates notification records and clears flag', async () => {
    useDb({
      tracking: { 'COMP_A_EMP001_2026-10-12': flaggedTracking() },
      users: { 'admin-1': adminUser },
      employees: { e1: employeeDoc },
      deviceRegistrations: {},
      notifications: {},
    });
    const r = res();
    await ctrl.listNotifications(req({}), r);
    expect(r.statusCode).toBe(200);

    const t = currentDb._store.tracking['COMP_A_EMP001_2026-10-12'];
    expect(t.pendingAdminNotify).toBeUndefined();
    expect(t.pendingAdminNotifyEvent).toBeUndefined();

    const notifs = Object.values(currentDb._store.notifications ?? {});
    expect(notifs).toHaveLength(1);
    expect((notifs[0] as any).recipientUserId).toBe('admin-1');
    expect((notifs[0] as any).type).toBe('LOCATION_DISABLED');
    // Admin sees the reconciled record immediately in the same response.
    expect(r.body.notifications.map((n: any) => n.type)).toContain('LOCATION_DISABLED');
  });

  test('sweep does not duplicate when a notification record already exists', async () => {
    useDb({
      tracking: { 'COMP_A_EMP001_2026-10-12': flaggedTracking() },
      users: { 'admin-1': adminUser },
      employees: { e1: employeeDoc },
      notifications: { existing: notif() }, // same entityId + eventTs
    });
    const r = res();
    await ctrl.listNotifications(req({}), r);
    expect(r.statusCode).toBe(200);
    const t = currentDb._store.tracking['COMP_A_EMP001_2026-10-12'];
    expect(t.pendingAdminNotify).toBeUndefined(); // flag cleared
    expect(Object.values(currentDb._store.notifications)).toHaveLength(1); // no dup
  });

  test('flag survives when the company has no admins yet', async () => {
    useDb({
      tracking: { 'COMP_A_EMP001_2026-10-12': flaggedTracking() },
      users: {},
      employees: { e1: employeeDoc },
      notifications: {},
    });
    const r = res();
    await ctrl.listNotifications(req({}), r);
    expect(r.statusCode).toBe(200);
    const t = currentDb._store.tracking['COMP_A_EMP001_2026-10-12'];
    expect(t.pendingAdminNotify).toBe(true); // kept for next sweep
    expect(currentDb._store.notifications ?? {}).toEqual({});
  });

  test('employee GET does NOT trigger the sweep', async () => {
    useDb({
      tracking: { 'COMP_A_EMP001_2026-10-12': flaggedTracking() },
      users: { 'admin-1': adminUser, 'emp-u1': { role: 'employee', companyId: 'COMP_A' } },
      employees: { e1: employeeDoc },
      notifications: {},
    });
    const r = res();
    await ctrl.listNotifications(req({ role: 'employee', userId: 'emp-u1' }), r);
    expect(r.statusCode).toBe(200);
    const t = currentDb._store.tracking['COMP_A_EMP001_2026-10-12'];
    expect(t.pendingAdminNotify).toBe(true);
    expect(Object.keys(currentDb._store.notifications ?? {})).toHaveLength(0);
  });

  test('sweep never touches another company\'s flagged docs', async () => {
    useDb({
      tracking: {
        'COMP_A_EMP001_2026-10-12': flaggedTracking(),
        'COMP_B_EMP009_2026-10-12': flaggedTracking({
          empid: 'EMP009',
          companyId: 'COMP_B',
          pendingAdminNotifyEvent: {
            eventId: 'evt_9', type: 'location_enabled',
            ts: '2026-10-12T09:00:00Z', dateIso: '2026-10-12', empid: 'EMP009',
          },
        }),
      },
      users: { 'admin-1': adminUser },
      employees: { e1: employeeDoc },
      notifications: {},
    });
    const r = res();
    await ctrl.listNotifications(req({}), r);
    expect(r.statusCode).toBe(200);
    const other = currentDb._store.tracking['COMP_B_EMP009_2026-10-12'];
    expect(other.pendingAdminNotify).toBe(true); // COMP_B doc untouched
    // Only COMP_A's admin was notified.
    for (const n of Object.values(currentDb._store.notifications ?? {})) {
      expect((n as any).companyId).toBe('COMP_A');
    }
  });
});
