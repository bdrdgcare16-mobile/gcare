/**
 * Tenant isolation for task assignment: an admin must not be able to assign a
 * task to an empid that does not belong to their own company (verified from
 * the JWT-derived companyId, never from client input).
 *
 * Covers createBroadcastTask (audience='employee' and 'all') and
 * createSingleTask, plus the users-collection fallback for employee identity.
 */
import { createBroadcastTask, createSingleTask } from './taskController';

// ---- In-memory Firestore fake --------------------------------------------

type Row = Record<string, any>;

function makeDb(seed: Record<string, Row[]>) {
  const store = seed;
  const written: { collection: string; id: string; data: Row }[] = [];
  let autoId = 0;

  function matches(d: Row, filters: [string, string, any][]) {
    return filters.every(([f, op, v]) => {
      const dv = d?.[f];
      if (op === '==') return dv === v;
      if (op === 'in') return Array.isArray(v) && v.includes(dv);
      return true;
    });
  }

  function makeQuery(name: string, filters: [string, string, any][]): any {
    return {
      where: (f: string, op: string, v: any) =>
        makeQuery(name, [...filters, [f, op, v]]),
      limit: () => makeQuery(name, filters),
      orderBy: () => makeQuery(name, filters),
      get: async () => {
        const matched = (store[name] ?? []).filter((r) =>
          matches(r, filters),
        );
        return {
          empty: matched.length === 0,
          size: matched.length,
          docs: matched.map((d, i) => ({
            id: d.id ?? `${name}-doc-${i}`,
            data: () => d,
          })),
        };
      },
    };
  }

  function docRef(name: string, id: string): any {
    return {
      id,
      get: async () => {
        const d = (store[name] ?? []).find((r) => r.id === id);
        return { id, exists: d !== undefined, data: () => d };
      },
      set: jest.fn(async (data: Row) => {
        written.push({ collection: name, id, data });
        (store[name] ??= []).push({ ...data, id });
      }),
    };
  }

  const collection = (name: string): any => ({
    where: (f: string, op: string, v: any) => makeQuery(name, [[f, op, v]]),
    doc: (id?: string) => docRef(name, id ?? `auto-${++autoId}`),
  });

  const batch = () => {
    const ops: { ref: any; data: Row }[] = [];
    return {
      set: (ref: any, data: Row) => {
        ops.push({ ref, data });
      },
      commit: async () => {
        for (const op of ops) await op.ref.set(op.data);
      },
    };
  };

  return { collection, batch, _written: written };
}

jest.mock('../config/firebase', () => ({
  db: {
    collection: (...args: any[]) => (currentDb as any).collection(...args),
    batch: () => (currentDb as any).batch(),
  },
}));

jest.mock('../services/usageService', () => ({
  trackUsage: jest.fn(async () => undefined),
}));

jest.mock('../services/notification.service', () => ({
  createAndSend: jest.fn(async () => ({ sent: 0, failed: 0 })),
  resolveUserIdByEmpid: jest.fn(async () => null),
}));

jest.mock('../services/taskProofUpload.service', () => ({
  uploadTaskProofToFirebase: jest.fn(),
  getTaskProofSignedUrl: jest.fn(),
}));

let currentDb: ReturnType<typeof makeDb>;
function useDb(seed: Record<string, Row[]>) {
  currentDb = makeDb(seed);
}

// ---- req/res helpers ------------------------------------------------------

function req(over: { companyId?: string | null; body?: any }) {
  return {
    user: {
      userId: 'admin-1',
      email: 'admin@example.com',
      role: 'admin',
      empid: 'ADM1',
      companyId: over.companyId,
    },
    headers: {},
    query: {},
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

const VALID_BODY = {
  title: 'Site visit',
  description: 'Inspect the site',
  audience: 'employee',
  assignedTo: 'EMP001',
};

// ---- Tests ----------------------------------------------------------------

describe('createBroadcastTask employee assignment isolation', () => {
  test('assigns to an employee of the same company (201 + assignment doc)', async () => {
    useDb({
      employees: [
        { empid: 'EMP001', companyId: 'COMP_A', name: 'Arun Kumar' },
        { empid: 'EMP002', companyId: 'COMP_B', name: 'Priya S' },
      ],
      users: [],
    });
    const r = res();
    await createBroadcastTask(req({ companyId: 'COMP_A', body: VALID_BODY }), r);

    expect(r.statusCode).toBe(201);
    expect(r.body.assignedTo).toBe('EMP001');
    expect(r.body.companyId).toBe('COMP_A');

    const assignments = currentDb._written.filter(
      (w) => w.collection === 'taskAssignments',
    );
    expect(assignments).toHaveLength(1);
    expect(assignments[0].data.employeeId).toBe('EMP001');
    expect(assignments[0].data.companyId).toBe('COMP_A');
  });

  test('rejects an empid that only exists in another company (403)', async () => {
    useDb({
      employees: [{ empid: 'EMP002', companyId: 'COMP_B', name: 'Priya S' }],
      users: [{ empid: 'EMP002', companyId: 'COMP_B', role: 'employee' }],
    });
    const r = res();
    await createBroadcastTask(
      req({
        companyId: 'COMP_A',
        body: { ...VALID_BODY, assignedTo: 'EMP002' },
      }),
      r,
    );

    expect(r.statusCode).toBe(403);
    expect(currentDb._written).toHaveLength(0);
  });

  test('rejects a nonexistent empid (403)', async () => {
    useDb({
      employees: [{ empid: 'EMP001', companyId: 'COMP_A', name: 'Arun Kumar' }],
      users: [],
    });
    const r = res();
    await createBroadcastTask(
      req({
        companyId: 'COMP_A',
        body: { ...VALID_BODY, assignedTo: 'EMP999' },
      }),
      r,
    );

    expect(r.statusCode).toBe(403);
    expect(currentDb._written).toHaveLength(0);
  });

  test('accepts an empid that only exists on a same-company users doc', async () => {
    useDb({
      employees: [],
      users: [
        {
          empid: 'EMP009',
          companyId: 'COMP_A',
          role: 'employee',
          name: 'Karthik R',
        },
        { empid: 'EMP009', companyId: 'COMP_B', role: 'employee' },
      ],
    });
    const r = res();
    await createBroadcastTask(
      req({
        companyId: 'COMP_A',
        body: { ...VALID_BODY, assignedTo: 'EMP009' },
      }),
      r,
    );

    expect(r.statusCode).toBe(201);
  });

  test("audience='all' still broadcasts to same-company users only", async () => {
    useDb({
      employees: [],
      users: [
        { empid: 'EMP001', companyId: 'COMP_A', role: 'employee' },
        { empid: 'EMP003', companyId: 'COMP_A', role: 'employee' },
        { empid: 'EMP002', companyId: 'COMP_B', role: 'employee' },
      ],
    });
    const r = res();
    await createBroadcastTask(
      req({
        companyId: 'COMP_A',
        body: { title: 'All hands', description: 'Broadcast', audience: 'all' },
      }),
      r,
    );

    expect(r.statusCode).toBe(201);
    const assignedEmpids = currentDb._written
      .filter((w) => w.collection === 'taskAssignments')
      .map((w) => w.data.employeeId)
      .sort();
    expect(assignedEmpids).toEqual(['EMP001', 'EMP003']);
  });

  test('requires companyId from the verified token (401)', async () => {
    useDb({ employees: [], users: [] });
    const r = res();
    await createBroadcastTask(req({ companyId: null, body: VALID_BODY }), r);
    expect(r.statusCode).toBe(401);
    expect(currentDb._written).toHaveLength(0);
  });
});

describe('createSingleTask employee assignment isolation', () => {
  test('assigns to a same-company employee (201)', async () => {
    useDb({
      employees: [{ empid: 'EMP001', companyId: 'COMP_A', name: 'Arun Kumar' }],
      users: [],
    });
    const r = res();
    await createSingleTask(
      req({
        companyId: 'COMP_A',
        body: { title: 'T', description: 'D', assignedTo: 'EMP001' },
      }),
      r,
    );
    expect(r.statusCode).toBe(201);
  });

  test('rejects an empid from another company (403)', async () => {
    useDb({
      employees: [{ empid: 'EMP002', companyId: 'COMP_B', name: 'Priya S' }],
      users: [],
    });
    const r = res();
    await createSingleTask(
      req({
        companyId: 'COMP_A',
        body: { title: 'T', description: 'D', assignedTo: 'EMP002' },
      }),
      r,
    );
    expect(r.statusCode).toBe(403);
    expect(currentDb._written).toHaveLength(0);
  });
});
