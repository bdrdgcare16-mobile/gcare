/**
 * Regression tests for the post-deploy production incident: the merged
 * entitlement layer (requireFeature on attendance / events / tasks / …)
 * requires a `companies/<id>` document, but production companies predate
 * that layer — the collection is empty in prod — so every existing
 * employee got 403 COMPANY_NOT_FOUND.
 *
 * Contract after the fix:
 *  - companies doc missing BUT tenant data (employees/users) references
 *    the companyId  → legacy entitlement (all features, exists=true).
 *  - companies doc missing AND no tenant data references the companyId →
 *    still denied (exists=false). Fabricated companyIds gain nothing.
 *  - the tenant probe failing → lookupFailed → callers serve 503, never
 *    silently grant.
 *  - companies doc present without enabledFeatures → legacy (unchanged).
 */
import {
  getCompanyEntitlement,
  getCompanyEntitlementSafe,
  companyHasFeature,
} from '../services/entitlementService';
import { requireFeature } from '../middlewares/featureMiddleware';

type Rows = Record<string, any>[];

function makeDb(opts: {
  companyDocs?: Record<string, any>;
  employeesRows?: Rows;
  usersRows?: Rows;
  failCollections?: Set<string>;
}) {
  const collection = (name: string) => ({
    doc: (id: string) => ({
      get: async () => {
        if (opts.failCollections?.has(`${name}.doc`)) {
          throw new Error('simulated firestore failure');
        }
        const data =
          name === 'companies' ? opts.companyDocs?.[id] : undefined;
        return { exists: data !== undefined, data: () => data };
      },
    }),
    where: (field: string, _op: string, value: any) => {
      const rows = name === 'employees'
        ? opts.employeesRows ?? []
        : name === 'users'
        ? opts.usersRows ?? []
        : [];
      const matched = rows.filter((r) => r?.[field] === value);
      const get = async () => {
        if (opts.failCollections?.has(name)) {
          throw new Error('simulated firestore failure');
        }
        return {
          empty: matched.length === 0,
          docs: matched.map((r) => ({ data: () => r })),
        };
      };
      return {
        where: () => ({ get, limit: () => ({ get }) }),
        limit: (n: number) => ({
          get: async () => {
            if (opts.failCollections?.has(name)) {
              throw new Error('simulated firestore failure');
            }
            return {
              empty: matched.length === 0,
              docs: matched.slice(0, n).map((r) => ({ data: () => r })),
            };
          },
        }),
        get,
      };
    },
  });
  return { collection };
}

// Mock firebase config BEFORE the service import resolves `db`.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
let currentDb: any;
jest.mock('../config/firebase', () => ({
  db: {
    collection: (...args: any[]) => currentDb.collection(...args),
  },
}));

function useDb(opts: Parameters<typeof makeDb>[0]) {
  currentDb = makeDb(opts);
}

describe('pre-entitlement production tenants (no companies doc)', () => {
  test('companyId referenced by employees => legacy, all features', async () => {
    // Mirrors production: COMP001 has 27 employees but companies/COMP001
    // does not exist.
    useDb({
      companyDocs: {},
      employeesRows: [{ empid: 'E1', companyId: 'COMP001' }],
      usersRows: [],
    });
    const ent = await getCompanyEntitlement('COMP001');
    expect(ent.exists).toBe(true);
    expect(ent.isLegacy).toBe(true);
    expect(ent.status).toBe('active');
    expect(ent.maxUsers).toBeNull();
    expect(companyHasFeature(ent, 'attendance')).toBe(true);
    expect(companyHasFeature(ent, 'tasks')).toBe(true);
    expect(companyHasFeature(ent, 'events')).toBe(true);
  });

  test('companyId referenced only by a company-admin user => legacy',
      async () => {
    // A freshly created company can have an admin in `users` but no
    // employees yet - it is still a real tenant.
    useDb({
      companyDocs: {},
      employeesRows: [],
      usersRows: [{ email: 'admin@x.com', companyId: 'COMP009', role: 'admin' }],
    });
    const ent = await getCompanyEntitlement('COMP009');
    expect(ent.exists).toBe(true);
    expect(ent.isLegacy).toBe(true);
    expect(companyHasFeature(ent, 'attendance')).toBe(true);
  });

  test('companyId with NO document and NO tenant data is still denied',
      async () => {
    useDb({
      companyDocs: {},
      employeesRows: [{ empid: 'E1', companyId: 'COMP001' }],
      usersRows: [{ email: 'a@x.com', companyId: 'COMP001' }],
    });
    const ent = await getCompanyEntitlement('FAKE_CO');
    expect(ent.exists).toBe(false);
    expect(ent.isLegacy).toBe(false);
    expect(companyHasFeature(ent, 'attendance')).toBe(false);
  });

  test('probe failure fails closed (lookupFailed, not legacy)', async () => {
    useDb({
      companyDocs: {},
      employeesRows: [],
      usersRows: [],
      failCollections: new Set(['employees']),
    });
    const ent = await getCompanyEntitlement('COMP001');
    expect(ent.exists).toBe(false);
    expect(ent.lookupFailed).toBe(true);
    expect(companyHasFeature(ent, 'attendance')).toBe(false);
  });

  test('existing contract: companies doc WITHOUT enabledFeatures is '
      + 'legacy and unaffected', async () => {
    useDb({
      companyDocs: { COMP002: { name: 'Co Two', status: 'active' } },
      employeesRows: [],
      usersRows: [],
    });
    const ent = await getCompanyEntitlement('COMP002');
    expect(ent.exists).toBe(true);
    expect(ent.isLegacy).toBe(true);
    expect(ent.name).toBe('Co Two');
    expect(companyHasFeature(ent, 'payroll')).toBe(true);
  });

  test('companies doc WITH enabledFeatures still restricts features '
      + '(entitlements not bypassed)', async () => {
    useDb({
      companyDocs: {
        COMP003: { name: 'Co Three', enabledFeatures: ['attendance'] },
      },
      employeesRows: [{ empid: 'E9', companyId: 'COMP003' }],
      usersRows: [],
    });
    const ent = await getCompanyEntitlement('COMP003');
    expect(ent.isLegacy).toBe(false);
    expect(companyHasFeature(ent, 'attendance')).toBe(true);
    expect(companyHasFeature(ent, 'payroll')).toBe(false);
  });

  test('tenant isolation: entitlement of one company never implies '
      + 'access for another companyId', async () => {
    useDb({
      companyDocs: {},
      employeesRows: [{ empid: 'E1', companyId: 'COMP_A' }],
      usersRows: [],
    });
    const entA = await getCompanyEntitlement('COMP_A');
    const entB = await getCompanyEntitlement('COMP_B');
    expect(entA.exists).toBe(true);
    expect(entB.exists).toBe(false);
    expect(companyHasFeature(entB, 'attendance')).toBe(false);
  });
});

/**
 * Route-level regression: the production 403s surfaced through
 * requireFeature(), not getCompanyEntitlement() directly. These tests
 * exercise the exact middleware deployed in front of /attendance/live,
 * /attendance/monthly, events and my-tasks.
 */
describe('requireFeature middleware — pre-entitlement tenants', () => {
  function mkRes() {
    const res: any = {
      statusCode: 0,
      body: null,
      status(c: number) {
        this.statusCode = c;
        return this;
      },
      json(b: any) {
        this.body = b;
        return this;
      },
    };
    return res;
  }
  const mkReq = (over: Record<string, any> = {}) => ({
    user: { role: 'employee', companyId: 'COMP001' },
    body: {},
    query: {},
    params: {},
    ...over,
  });

  test.each(['attendance', 'events', 'tasks'])(
    'existing employee (JWT companyId, no companies doc) passes %s gate',
    async (feature) => {
      useDb({
        companyDocs: {},
        employeesRows: [{ empid: 'MR019', companyId: 'COMP001' }],
        usersRows: [],
      });
      const res = mkRes();
      const next = jest.fn();
      await requireFeature(feature)(mkReq() as any, res, next);
      expect(next).toHaveBeenCalled();
      expect(res.statusCode).toBe(0);
    },
  );

  test('JWT companyId wins over a forged body companyId', async () => {
    useDb({
      companyDocs: {},
      employeesRows: [{ empid: 'E1', companyId: 'COMP001' }],
      usersRows: [],
    });
    const res = mkRes();
    const next = jest.fn();
    await requireFeature('attendance')(
      mkReq({ body: { companyId: 'EVIL_CO' } }) as any,
      res,
      next,
    );
    expect(next).toHaveBeenCalled();
  });

  test('valid employee of ANOTHER real tenant also passes (tenant data '
      + 'still scoped by their own JWT companyId)', async () => {
    useDb({
      companyDocs: {},
      employeesRows: [
        { empid: 'E1', companyId: 'COMP001' },
        { empid: 'E2', companyId: 'COMP002' },
      ],
      usersRows: [],
    });
    const res = mkRes();
    const next = jest.fn();
    await requireFeature('events')(
      mkReq({ user: { role: 'employee', companyId: 'COMP002' } }) as any,
      res,
      next,
    );
    expect(next).toHaveBeenCalled();
  });

  test('fabricated/unknown companyId still gets 403 COMPANY_NOT_FOUND',
      async () => {
    useDb({
      companyDocs: {},
      employeesRows: [{ empid: 'E1', companyId: 'COMP001' }],
      usersRows: [],
    });
    const res = mkRes();
    const next = jest.fn();
    await requireFeature('attendance')(
      mkReq({ user: { role: 'employee', companyId: 'FAKE_CO' } }) as any,
      res,
      next,
    );
    expect(next).not.toHaveBeenCalled();
    expect(res.statusCode).toBe(403);
    expect(res.body.error).toBe('COMPANY_NOT_FOUND');
  });

  test('newly onboarded company (doc WITH enabledFeatures) honours the '
      + 'feature list', async () => {
    useDb({
      companyDocs: {
        NEWCO: { name: 'New Co', enabledFeatures: ['attendance'] },
      },
      employeesRows: [{ empid: 'E9', companyId: 'NEWCO' }],
      usersRows: [],
    });
    const resOk = mkRes();
    const nextOk = jest.fn();
    await requireFeature('attendance')(
      mkReq({ user: { role: 'employee', companyId: 'NEWCO' } }) as any,
      resOk,
      nextOk,
    );
    expect(nextOk).toHaveBeenCalled();

    const resNo = mkRes();
    const nextNo = jest.fn();
    await requireFeature('payroll')(
      mkReq({ user: { role: 'employee', companyId: 'NEWCO' } }) as any,
      resNo,
      nextNo,
    );
    expect(nextNo).not.toHaveBeenCalled();
    expect(resNo.statusCode).toBe(403);
    expect(resNo.body.error).toBe('FEATURE_NOT_ENABLED');
  });

  test('employee missing companyId entirely -> COMPANY_CONTEXT_REQUIRED',
      async () => {
    useDb({ companyDocs: {}, employeesRows: [], usersRows: [] });
    const res = mkRes();
    const next = jest.fn();
    await requireFeature('attendance')(
      mkReq({ user: { role: 'employee' } }) as any,
      res,
      next,
    );
    expect(next).not.toHaveBeenCalled();
    expect(res.statusCode).toBe(403);
    expect(res.body.error).toBe('COMPANY_CONTEXT_REQUIRED');
  });

  test('unauthenticated legacy route resolves tenant via empid -> allowed',
      async () => {
    useDb({
      companyDocs: {},
      employeesRows: [{ empid: 'MR019', companyId: 'COMP001' }],
      usersRows: [],
    });
    const res = mkRes();
    const next = jest.fn();
    await requireFeature('attendance')(
      mkReq({ user: undefined, query: { empid: 'MR019' } }) as any,
      res,
      next,
    );
    expect(next).toHaveBeenCalled();
  });

  test('suspended companies doc -> COMPANY_NOT_ACTIVE even with tenant data',
      async () => {
    useDb({
      companyDocs: { COMP001: { name: 'Co', status: 'suspended' } },
      employeesRows: [{ empid: 'E1', companyId: 'COMP001' }],
      usersRows: [],
    });
    const res = mkRes();
    const next = jest.fn();
    await requireFeature('attendance')(mkReq() as any, res, next);
    expect(next).not.toHaveBeenCalled();
    expect(res.statusCode).toBe(403);
    expect(res.body.error).toBe('COMPANY_NOT_ACTIVE');
  });

  test('platform_admin is never tenant-gated', async () => {
    useDb({ companyDocs: {}, employeesRows: [], usersRows: [] });
    const res = mkRes();
    const next = jest.fn();
    await requireFeature('attendance')(
      mkReq({ user: { role: 'platform_admin', companyId: 'platform' } }) as any,
      res,
      next,
    );
    expect(next).toHaveBeenCalled();
  });
});

describe('getCompanyEntitlementSafe caching with legacy tenants', () => {
  test('legacy result is cached (no per-request probe storm)', async () => {
    useDb({
      companyDocs: {},
      employeesRows: [{ empid: 'E1', companyId: 'COMPCACHE' }],
      usersRows: [],
    });
    const a = await getCompanyEntitlementSafe('COMPCACHE');
    const b = await getCompanyEntitlementSafe('COMPCACHE');
    expect(a.exists).toBe(true);
    expect(b.exists).toBe(true);
    expect(b.isLegacy).toBe(true);
  });
});
