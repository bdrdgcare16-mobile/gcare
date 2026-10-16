/**
 * Company-isolation and count tests for employeeController.
 * The employee list powering the Admin Dashboard summary cards must be
 * scoped exclusively by the JWT's verified companyId - a companyId sent
 * by the client must never widen or redirect the query.
 */
import * as ctrl from './employeeController';

// ---- Fake Firestore with real equality-filter semantics -----------------

type Row = Record<string, any> & { _docId?: string };

type Filter = { field: string; value: any };

function applyFilters(rows: Row[], filters: Filter[]) {
  return rows.filter((r) => filters.every((f) => r[f.field] === f.value));
}

function makeQuery(rows: Row[]) {
  const filters: Filter[] = [];
  const chain: any = {
    where: (field: string, _op: string, value: any) => {
      filters.push({ field, value });
      return chain;
    },
    limit: (n: number) => {
      chain._limit = n;
      return chain;
    },
    get: async () => {
      let out = applyFilters(rows, filters);
      if (chain._limit) out = out.slice(0, chain._limit);
      return {
        empty: out.length === 0,
        size: out.length,
        docs: out.map((d, i) => ({
          id: d._docId ?? `doc${i}`,
          exists: true,
          data: () => d,
        })),
      };
    },
  };
  return chain;
}

function makeDb(seed: Record<string, Row[]>, docs: Record<string, any> = {}) {
  return {
    collection: (name: string) => ({
      where: (field: string, op: string, value: any) =>
        makeQuery(seed[name] ?? []).where(field, op, value),
      doc: (id: string) => ({
        get: async () => {
          const d = docs[`${name}/${id}`];
          return { exists: d !== undefined, id, data: () => d };
        },
        update: jest.fn(async () => {}),
        delete: jest.fn(async () => {}),
      }),
      add: jest.fn(async (data: any) => ({
        id: 'new-doc',
        get: async () => ({ exists: true, data: () => data }),
      })),
    }),
    _seed: seed,
    _docs: docs,
  };
}

jest.mock('../config/firebase', () => ({
  db: {
    collection: (...args: any[]) => (currentDb as any).collection(...args),
  },
}));

jest.mock('../services/usageService', () => ({
  trackUsage: jest.fn(async () => {}),
}));

let currentDb: ReturnType<typeof makeDb>;

const COMPANY_A_EMPS: Row[] = [
  { _docId: 'a1', companyId: 'COMP_A', empid: 'A001', name: 'A One', email: 'a1@x.com', status: 'active', password: 'hash1' },
  { _docId: 'a2', companyId: 'COMP_A', empid: 'A002', name: 'A Two', email: 'a2@x.com', status: 'active', password: 'hash2' },
  { _docId: 'a3', companyId: 'COMP_A', empid: 'A003', name: 'A Three', email: 'a3@x.com', status: 'inactive', password: 'hash3' },
];
const COMPANY_B_EMPS: Row[] = [
  { _docId: 'b1', companyId: 'COMP_B', empid: 'B001', name: 'B One', email: 'b1@x.com', status: 'active', password: 'hashB' },
  { _docId: 'b2', companyId: 'COMP_B', empid: 'B002', name: 'B Two', email: 'b2@x.com', status: 'suspended', password: 'hashB2' },
];

function seedDb() {
  currentDb = makeDb(
    { employees: [...COMPANY_A_EMPS, ...COMPANY_B_EMPS] },
    {
      'employees/a1': { ...COMPANY_A_EMPS[0] },
      'employees/b1': { ...COMPANY_B_EMPS[0] },
    },
  );
}

function req(over: {
  companyId?: string | null;
  role?: string;
  query?: any;
  body?: any;
  params?: any;
}) {
  return {
    user: {
      userId: 'u1',
      email: 'admin@x.com',
      role: over.role ?? 'admin',
      companyId: 'companyId' in over ? over.companyId : 'COMP_A',
    },
    query: over.query ?? {},
    body: over.body ?? {},
    params: over.params ?? {},
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

beforeEach(seedDb);

describe('getEmployees company isolation', () => {
  it('returns only Company A employees for a Company A admin', async () => {
    const r = res();
    await ctrl.getEmployees(req({}), r);
    expect(r.statusCode).toBe(200);
    const ids = (r.body as any[]).map((e) => e.empid).sort();
    expect(ids).toEqual(['A001', 'A002', 'A003']);
    expect((r.body as any[]).every((e) => e.companyId === 'COMP_A')).toBe(true);
  });

  it('returns only Company B employees for a Company B admin', async () => {
    const r = res();
    await ctrl.getEmployees(req({ companyId: 'COMP_B' }), r);
    const ids = (r.body as any[]).map((e) => e.empid).sort();
    expect(ids).toEqual(['B001', 'B002']);
  });

  it('ignores a companyId supplied in the request query', async () => {
    const r = res();
    await ctrl.getEmployees(req({ query: { companyId: 'COMP_B' } }), r);
    const ids = (r.body as any[]).map((e) => e.empid).sort();
    expect(ids).toEqual(['A001', 'A002', 'A003']);
  });

  it('ignores a companyId supplied in the request body', async () => {
    const r = res();
    await ctrl.getEmployees(req({ body: { companyId: 'COMP_B' } }), r);
    const ids = (r.body as any[]).map((e) => e.empid).sort();
    expect(ids).toEqual(['A001', 'A002', 'A003']);
  });

  it('returns 401 when the JWT carries no companyId', async () => {
    const r = res();
    await ctrl.getEmployees(req({ companyId: null }), r);
    expect(r.statusCode).toBe(401);
  });

  it('counts are derived from the same dataset the table shows', async () => {
    const r = res();
    await ctrl.getEmployees(req({}), r);
    const rows = r.body as any[];
    const total = rows.length;
    const active = rows.filter((e) => e.status === 'active').length;
    const inactive = rows.filter((e) => e.status === 'inactive').length;
    const suspended = rows.filter((e) => e.status === 'suspended').length;
    const relieved = rows.filter((e) => e.status === 'relieved').length;
    expect(total).toBe(3);
    expect(active + inactive + suspended + relieved).toBe(total);
  });

  it('company B status buckets sum to its own total', async () => {
    const r = res();
    await ctrl.getEmployees(req({ companyId: 'COMP_B' }), r);
    const rows = r.body as any[];
    const buckets = ['active', 'inactive', 'suspended', 'relieved']
      .map((s) => rows.filter((e) => e.status === s).length);
    expect(buckets.reduce((a, b) => a + b, 0)).toBe(rows.length);
    expect(rows.filter((e) => e.status === 'suspended').length).toBe(1);
  });

  it('never returns the stored password hash', async () => {
    const r = res();
    await ctrl.getEmployees(req({}), r);
    expect((r.body as any[]).every((e) => e.password === undefined)).toBe(true);
  });
});

describe('getEmployeeById company isolation', () => {
  it('allows reading a same-company employee', async () => {
    const r = res();
    await ctrl.getEmployeeById(req({ params: { id: 'a1' } }), r);
    expect(r.statusCode).toBe(200);
    expect((r.body as any).empid).toBe('A001');
    expect((r.body as any).password).toBeUndefined();
  });

  it('rejects reading another company\'s employee', async () => {
    const r = res();
    await ctrl.getEmployeeById(req({ params: { id: 'b1' } }), r);
    expect(r.statusCode).toBe(403);
  });
});
