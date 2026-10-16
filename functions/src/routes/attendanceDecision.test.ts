// Regression tests for the /attendance/approvals/decision authorization
// chain: roleMiddleware(['admin','hr']) + hrFeatureGate(approvalsSrc).
// The controller's own companyId scoping is exercised by the emulator
// suite; these unit tests cover the middleware gate ordering.

const mockStore: Record<string, any> = {};

jest.mock('../config/firebase', () => ({
  db: {
    collection: () => ({
      doc: (id: string) => ({
        get: async () => ({
          exists: id in mockStore,
          data: () => mockStore[id],
        }),
      }),
    }),
  },
}));

import { roleMiddleware } from '../middlewares/authMiddleware';
import { hrFeatureGate } from '../middlewares/hrFeatureMiddleware';
import { approvalsSrc } from './attendanceRoutes';

const isAdminOrHr = roleMiddleware(['admin', 'hr']);
const hrGate = hrFeatureGate(approvalsSrc);

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

// Runs the real middleware chain in route order. Returns the terminal
// status code (200 when the chain reaches the controller).
async function chain(user: any, body: any): Promise<number> {
  const req: any = { user, body, query: {} };
  const res = mkRes();
  let passed = false;
  await (isAdminOrHr as any)(req, res, () => {
    passed = true;
  });
  if (!passed) return res.statusCode;
  passed = false;
  await (hrGate as any)(req, res, () => {
    passed = true;
  });
  return passed ? 200 : res.statusCode;
}

describe('/attendance/approvals/decision authorization', () => {
  beforeEach(() => {
    for (const k of Object.keys(mockStore)) delete mockStore[k];
    mockStore['hr-leave'] = { approvedFeatures: ['leave'] };
    mockStore['hr-att'] = { approvedFeatures: ['attendance'] };
    mockStore['hr-none'] = { approvedFeatures: [] };
    mockStore['hr-noco'] = { approvedFeatures: ['leave', 'attendance'] };
  });

  test('admin can decide a leave request', async () => {
    expect(
      await chain(
        { role: 'admin', companyId: 'C1', userId: 'a1' },
        { source: 'leaves', leaveId: 'L1', status: 'Approved' },
      ),
    ).toBe(200);
  });

  test('admin can decide an attendance request', async () => {
    expect(
      await chain(
        { role: 'admin', companyId: 'C1', userId: 'a1' },
        { source: 'attendance', attendanceId: 'A1', status: 'Rejected' },
      ),
    ).toBe(200);
  });

  test('HR with leave approved can decide a leave request', async () => {
    expect(
      await chain(
        { role: 'hr', companyId: 'C1', userId: 'hr-leave' },
        { source: 'leaves', leaveId: 'L1', status: 'Approved' },
      ),
    ).toBe(200);
  });

  test('HR without leave cannot decide a leave request (403)', async () => {
    expect(
      await chain(
        { role: 'hr', companyId: 'C1', userId: 'hr-att' },
        { source: 'leaves', leaveId: 'L1', status: 'Approved' },
      ),
    ).toBe(403);
  });

  test('HR without attendance cannot decide attendance request (403)', async () => {
    expect(
      await chain(
        { role: 'hr', companyId: 'C1', userId: 'hr-leave' },
        { source: 'attendance', attendanceId: 'A1', status: 'Approved' },
      ),
    ).toBe(403);
  });

  test('HR with no approved features is denied (403)', async () => {
    expect(
      await chain(
        { role: 'hr', companyId: 'C1', userId: 'hr-none' },
        { source: 'leaves', leaveId: 'L1', status: 'Approved' },
      ),
    ).toBe(403);
  });

  test('HR without companyId on token is denied (403)', async () => {
    expect(
      await chain(
        { role: 'hr', companyId: '', userId: 'hr-noco' },
        { source: 'leaves', leaveId: 'L1', status: 'Approved' },
      ),
    ).toBe(403);
  });

  test('employee cannot decide any request (403)', async () => {
    for (const source of ['leaves', 'attendance']) {
      expect(
        await chain(
          { role: 'employee', companyId: 'C1', userId: 'e1', empid: 'E1' },
          { source, id: 'X1', status: 'Approved' },
        ),
      ).toBe(403);
    }
  });

  test('company_admin cannot decide approval requests (403)', async () => {
    expect(
      await chain(
        { role: 'company_admin', companyId: 'C1', userId: 'ca1' },
        { source: 'leaves', leaveId: 'L1', status: 'Approved' },
      ),
    ).toBe(403);
  });

  test('unauthenticated request is denied (401)', async () => {
    expect(
      await chain(null, { source: 'leaves', leaveId: 'L1', status: 'Approved' }),
    ).toBe(401);
  });

  test('HR with missing user document is denied (403)', async () => {
    expect(
      await chain(
        { role: 'hr', companyId: 'C1', userId: 'ghost' },
        { source: 'leave', leaveId: 'L1', status: 'Approved' },
      ),
    ).toBe(403);
  });
});
