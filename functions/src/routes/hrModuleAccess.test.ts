// Regression tests for HR module-level access (Phase 2/3 audit fixes):
//   shift writes        -> admin|hr + hrFeatureGate(['attendance'])
//   office locations    -> admin|hr + hrFeatureGate(['attendance'])
//   reason master       -> admin|hr + hrFeatureGate(['attendance'])
//   liveEmployeeDetails -> admin|hr only + companyId-scoped queries
//   overtime            -> admin|hr + hrFeatureGate(['attendance'])
//   tracking /day       -> admin|hr|employee + hrFeatureGate
// Employee mutations (create/update/delete) intentionally stay
// admin-only — covered by asserting ['admin'] on those routes indirectly
// via controller field sensitivity (not re-tested here).

// Explicit imports keep IDE type resolution working even when the
// language server doesn't pick up tsconfig's "types": ["jest"] globals.
import { describe, it, expect, beforeEach, jest } from '@jest/globals';

const mockStore: Record<string, any> = {};

const chainQ: any = {
  where: () => chainQ,
  orderBy: () => chainQ,
  limit: () => chainQ,
  get: async () => ({ empty: true, docs: [] }),
};

jest.mock('../config/firebase', () => ({
  db: {
    collection: () => ({
      doc: (id: string) => ({
        get: async () => ({
          exists: id in mockStore,
          data: () => mockStore[id],
        }),
      }),
      where: () => chainQ,
      orderBy: () => chainQ,
      limit: () => chainQ,
      get: async () => ({ empty: true, docs: [] }),
    }),
  },
}));

import { roleMiddleware } from '../middlewares/authMiddleware';
import { hrFeatureGate } from '../middlewares/hrFeatureMiddleware';

const isAdminOrHr = roleMiddleware(['admin', 'hr']);
const isAdminHrOrEmployee = roleMiddleware(['admin', 'hr', 'employee']);
const hrAttendance = hrFeatureGate(['attendance']);

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

async function runMw(mw: any, req: any, res: any): Promise<boolean> {
  let passed = false;
  await mw(req, res, () => {
    passed = true;
  });
  return passed;
}

const mkReq = (user: any) => ({ user });
const ADMIN = { userId: 'a1', role: 'admin', companyId: 'C1' };
const EMP = { userId: 'e1', role: 'employee', companyId: 'C1' };
const CA = { userId: 'ca1', role: 'company_admin', companyId: 'C1' };
const HR_ATT = { userId: 'hr-att', role: 'hr', companyId: 'C1' };
const HR_NONE = { userId: 'hr-none', role: 'hr', companyId: 'C1' };

beforeEach(() => {
  for (const k of Object.keys(mockStore)) delete mockStore[k];
  mockStore['hr-att'] = { approvedFeatures: ['attendance'] };
  // 'tasks' has no requires — its closure excludes 'attendance'.
  // ('payroll' would resolve to attendance via dependency closure.)
  mockStore['hr-none'] = { approvedFeatures: ['tasks'] };
});

describe('shift write chain (roleMiddleware + hrFeatureGate)', () => {
  it('admin passes', async () => {
    expect(await runMw(isAdminOrHr, mkReq(ADMIN), mkRes())).toBe(true);
  });
  it('hr passes role middleware', async () => {
    expect(await runMw(isAdminOrHr, mkReq(HR_ATT), mkRes())).toBe(true);
  });
  it('employee blocked at role middleware', async () => {
    const res = mkRes();
    expect(await runMw(isAdminOrHr, mkReq(EMP), res)).toBe(false);
    expect(res.statusCode).toBe(403);
  });
  it('company_admin blocked at role middleware', async () => {
    const res = mkRes();
    expect(await runMw(isAdminOrHr, mkReq(CA), res)).toBe(false);
    expect(res.statusCode).toBe(403);
  });
  it('hr with attendance approved passes the feature gate', async () => {
    expect(await runMw(hrAttendance, mkReq(HR_ATT), mkRes())).toBe(true);
  });
  it('hr without attendance approved blocked by the gate', async () => {
    const res = mkRes();
    expect(await runMw(hrAttendance, mkReq(HR_NONE), res)).toBe(false);
    expect(res.statusCode).toBe(403);
  });
  it('admin passes through the hr gate unaffected', async () => {
    expect(await runMw(hrAttendance, mkReq(ADMIN), mkRes())).toBe(true);
  });
});

describe('office locations / reason master chain', () => {
  // Real middleware order: roleMiddleware → hrFeatureGate. A request only
  // reaches the handler when the role gate passes AND the HR feature
  // gate passes (the gate is a pass-through for non-hr roles).
  it.each([
    ['admin', ADMIN, true],
    ['hr+attendance', HR_ATT, true],
    ['hr without attendance', HR_NONE, false],
    ['employee', EMP, false],
    ['company_admin', CA, false],
  ])('%s → allowed=%s', async (_label, user, ok) => {
    const rolePass = await runMw(isAdminOrHr, mkReq(user), mkRes());
    const gatePass = rolePass
      ? await runMw(hrAttendance, mkReq(user), mkRes())
      : false;
    expect(rolePass && gatePass).toBe(ok);
  });
});

describe('liveEmployeeDetails / overtime (admin|hr only)', () => {
  it('employee blocked (was previously reachable)', async () => {
    const res = mkRes();
    expect(await runMw(isAdminOrHr, mkReq(EMP), res)).toBe(false);
    expect(res.statusCode).toBe(403);
  });
  it('company_admin blocked', async () => {
    const res = mkRes();
    expect(await runMw(isAdminOrHr, mkReq(CA), res)).toBe(false);
    expect(res.statusCode).toBe(403);
  });
  it('hr+attendance passes', async () => {
    expect(await runMw(isAdminOrHr, mkReq(HR_ATT), mkRes())).toBe(true);
    expect(await runMw(hrAttendance, mkReq(HR_ATT), mkRes())).toBe(true);
  });
});

describe('tracking /day role list', () => {
  it('employee passes role middleware (self-scoped in controller)', async () => {
    expect(await runMw(isAdminHrOrEmployee, mkReq(EMP), mkRes())).toBe(true);
  });
  it('company_admin blocked', async () => {
    const res = mkRes();
    expect(await runMw(isAdminHrOrEmployee, mkReq(CA), res)).toBe(false);
    expect(res.statusCode).toBe(403);
  });
});
