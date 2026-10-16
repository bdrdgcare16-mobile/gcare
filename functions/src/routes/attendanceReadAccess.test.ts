// Regression tests for attendance read-access authorization:
//   self-read endpoints  -> roleMiddleware(['admin','hr','employee'])
//                           + hrFeatureGate + controller empid self-check
//   roster endpoints     -> roleMiddleware(['admin','hr']) + hrFeatureGate
//   employee-details/request-details -> admin/hr + companyId on every query

const mockStore: Record<string, any> = {};

// Chainable query mock: every .where/.orderBy/.limit returns itself;
// .get() yields an empty snapshot. doc(id).get() reads mockStore.
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
import {
  getEmployeeAttendance,
  getMonthlySummary,
} from '../controllers/attendanceController';
import { getRequestDetails } from '../controllers/employeeDetailsController';

const isAdminOrHr = roleMiddleware(['admin', 'hr']);
const isAdminHrOrEmployee = roleMiddleware(['admin', 'hr', 'employee']);
const hrGateAttendance = hrFeatureGate(['attendance']);
const hrGateReportsOrAttendance = hrFeatureGate(['reports', 'attendance']);

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

// Simulates the route chain for the self-read endpoints
// (/live, /employee/:empid, /monthly, /summary).
async function selfReadChain(user: any): Promise<number> {
  const req: any = { user, params: {}, query: {}, body: {} };
  const res = mkRes();
  if (!(await runMw(isAdminHrOrEmployee, req, res))) return res.statusCode;
  if (!(await runMw(hrGateAttendance, req, res))) return res.statusCode;
  return 200;
}

// Simulates the route chain for the roster endpoints
// (/history, /roster, /request-details).
async function rosterChain(user: any): Promise<number> {
  const req: any = { user, params: {}, query: {}, body: {} };
  const res = mkRes();
  if (!(await runMw(isAdminOrHr, req, res))) return res.statusCode;
  if (!(await runMw(hrGateAttendance, req, res))) return res.statusCode;
  return 200;
}

// /range-summary accepts either 'reports' or 'attendance' for HR.
async function rangeSummaryChain(user: any): Promise<number> {
  const req: any = { user, params: {}, query: {}, body: {} };
  const res = mkRes();
  if (!(await runMw(isAdminOrHr, req, res))) return res.statusCode;
  if (!(await runMw(hrGateReportsOrAttendance, req, res))) return res.statusCode;
  return 200;
}

describe('attendance read-access authorization', () => {
  beforeEach(() => {
    for (const k of Object.keys(mockStore)) delete mockStore[k];
    mockStore['hr-att'] = { approvedFeatures: ['attendance'] };
    mockStore['hr-none'] = { approvedFeatures: [] };
    mockStore['att-foreign'] = { empid: 'E9', companyId: 'OTHERCO', date: '2025-01-01' };
  });

  // --- role gate on self-read endpoints ---
  test('admin passes the self-read gate (company-scoped)', async () => {
    expect(await selfReadChain({ role: 'admin', companyId: 'C1', userId: 'a1' })).toBe(200);
  });

  test('HR with attendance approved passes the self-read gate', async () => {
    expect(await selfReadChain({ role: 'hr', companyId: 'C1', userId: 'hr-att' })).toBe(200);
  });

  test('HR without attendance gets 403 on self-read gate', async () => {
    expect(await selfReadChain({ role: 'hr', companyId: 'C1', userId: 'hr-none' })).toBe(403);
  });

  test('employee passes the self-read gate (controller enforces own empid)', async () => {
    expect(await selfReadChain({ role: 'employee', companyId: 'C1', userId: 'e1', empid: 'E1' })).toBe(200);
  });

  test('company_admin cannot use self-read endpoints (403)', async () => {
    expect(await selfReadChain({ role: 'company_admin', companyId: 'C1', userId: 'ca1' })).toBe(403);
  });

  test('unauthenticated request on self-read endpoint is 401', async () => {
    expect(await selfReadChain(null)).toBe(401);
  });

  // --- role gate on roster endpoints ---
  test('admin passes the roster gate', async () => {
    expect(await rosterChain({ role: 'admin', companyId: 'C1', userId: 'a1' })).toBe(200);
  });

  test('HR with attendance approved passes the roster gate', async () => {
    expect(await rosterChain({ role: 'hr', companyId: 'C1', userId: 'hr-att' })).toBe(200);
  });

  test('HR without attendance gets 403 on roster gate', async () => {
    expect(await rosterChain({ role: 'hr', companyId: 'C1', userId: 'hr-none' })).toBe(403);
  });

  test('employee cannot use roster endpoints (403)', async () => {
    expect(await rosterChain({ role: 'employee', companyId: 'C1', userId: 'e1', empid: 'E1' })).toBe(403);
  });

  test('company_admin cannot use roster endpoints (403)', async () => {
    expect(await rosterChain({ role: 'company_admin', companyId: 'C1', userId: 'ca1' })).toBe(403);
  });

  // --- range-summary: either reports or attendance for HR ---
  test('HR with reports can read range-summary', async () => {
    mockStore['hr-rep'] = { approvedFeatures: ['reports'] };
    expect(await rangeSummaryChain({ role: 'hr', companyId: 'C1', userId: 'hr-rep' })).toBe(200);
  });

  test('employee cannot read range-summary (403)', async () => {
    expect(await rangeSummaryChain({ role: 'employee', companyId: 'C1', userId: 'e1', empid: 'E1' })).toBe(403);
  });

  // --- controller-level employee self-scope ---
  test('employee requesting another empid on /employee/:empid is 403', async () => {
    const req: any = {
      user: { role: 'employee', companyId: 'C1', empid: 'E1' },
      params: { empid: 'E2' },
    };
    const res = mkRes();
    await (getEmployeeAttendance as any)(req, res);
    expect(res.statusCode).toBe(403);
  });

  test('employee requesting own empid on /employee/:empid is not 403', async () => {
    const req: any = {
      user: { role: 'employee', companyId: 'C1', empid: 'E1' },
      params: { empid: 'E1' },
    };
    const res = mkRes();
    await (getEmployeeAttendance as any)(req, res);
    expect(res.statusCode).not.toBe(403);
    expect(res.statusCode).not.toBe(401);
  });

  test('employee with no token empid is denied even if param looks valid', async () => {
    const req: any = {
      user: { role: 'employee', companyId: 'C1', empid: null },
      params: { empid: 'E1' },
    };
    const res = mkRes();
    await (getEmployeeAttendance as any)(req, res);
    expect(res.statusCode).toBe(403);
  });

  test('employee requesting another empid on monthly summary is 403', async () => {
    const req: any = {
      user: { role: 'employee', companyId: 'C1', empid: 'E1' },
      params: { empid: 'E2', year: '2025', month: '1' },
    };
    const res = mkRes();
    await (getMonthlySummary as any)(req, res);
    expect(res.statusCode).toBe(403);
  });

  test('employee requesting own monthly summary is not 403', async () => {
    const req: any = {
      user: { role: 'employee', companyId: 'C1', empid: 'E1' },
      params: { empid: 'E1', year: '2025', month: '1' },
    };
    const res = mkRes();
    await (getMonthlySummary as any)(req, res);
    expect(res.statusCode).not.toBe(403);
    expect(res.statusCode).not.toBe(401);
  });

  // --- employee-details/request-details companyId enforcement ---
  test('cross-company document id is rejected with 403', async () => {
    const req: any = {
      user: { role: 'admin', companyId: 'C1' },
      query: { id: 'att-foreign', src: 'attendance' },
    };
    const res = mkRes();
    await getRequestDetails(req, res);
    expect(res.statusCode).toBe(403);
  });

  test('request without companyId on token is rejected with 403', async () => {
    const req: any = {
      user: { role: 'admin', companyId: null },
      query: { id: 'att-foreign', src: 'attendance' },
    };
    const res = mkRes();
    await getRequestDetails(req, res);
    expect(res.statusCode).toBe(403);
  });
});
