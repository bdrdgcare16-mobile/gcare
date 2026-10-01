/// <reference types="jest" />
/**
 * Leave Management hardening tests.
 *
 * Covers: employee create + overlap prevention (409), companyId always
 * from JWT, admin approve/reject, self-approval blocked, company
 * isolation, leave_management feature gate (route mount + shared
 * approvals surface), legacy-org compat (no enabledFeatures → allowed),
 * IDOR protection on request-details, and cancel ownership rules.
 */

import request from 'supertest';

process.env.JWT_SECRET = 'test-jwt-secret-leave';

const mockFirebaseState = {
  getDb: jest.fn(),
  getAdminAuth: jest.fn(),
  checkFirestoreAccess: jest.fn().mockResolvedValue(true),
};

jest.mock('./config/firebase', () => ({
  getDb: (...args: any[]) => mockFirebaseState.getDb(...args),
  getAdminAuth: (...args: any[]) => mockFirebaseState.getAdminAuth(...args),
  checkFirestoreAccess: (...args: any[]) =>
    mockFirebaseState.checkFirestoreAccess(...args),
}));

// eslint-disable-next-line import/first
import app from './app';
// eslint-disable-next-line import/first
import { issueToken } from './common/auth.utils';

const tok = (role: string, companyId = 'c1', userId = 'u-1', empid = 'E001') =>
  issueToken({ userId, email: `${userId}@org.test`, role, empid, companyId });

const leaveBody = (over: any = {}) => ({
  leaveType: 'Casual Leave',
  startDate: '2030-01-10',
  endDate: '2030-01-12',
  reason: 'family event',
  ...over,
});

type Doc = { id?: string; data?: any } & Record<string, any>;

function installDb(opts: {
  profile?: any;
  employees?: Doc[];
  users?: Record<string, any>;
  leaves?: Doc[]; // collection-query results
  leaveDocs?: Record<string, Doc>; // doc(id).get() results
}) {
  const writes = {
    leavesAdded: [] as any[],
    leavesUpdated: [] as any[],
    leavesDeleted: [] as string[],
  };

  const applyConds = (rows: Doc[], conds: any[]) =>
    rows.filter((d) => {
      const v = d.data ?? d;
      return conds.every(([f, op, val]) => {
        if (op === '==') return v[f] === val;
        if (op === 'in') return Array.isArray(val) && val.includes(v[f]);
        if (op === '<=') return v[f] <= val;
        if (op === '>=') return v[f] >= val;
        return true;
      });
    });

  const collData = (name: string): Doc[] => {
    if (name === 'employees') return opts.employees ?? [];
    if (name === 'leaves') return opts.leaves ?? [];
    return [];
  };

  mockFirebaseState.getDb.mockReturnValue({
    collection: jest.fn((name: string) => {
      if (name === 'companyProfile' || name === 'companies') {
        return {
          doc: jest.fn((_id: string) => ({
            get: jest.fn(async () => ({
              exists: opts.profile !== undefined,
              data: () => opts.profile,
            })),
          })),
        };
      }
      const conds: any[] = [];
      const q: any = {};
      q.where = jest.fn((f: string, op: string, v: any) => {
        conds.push([f, op, v]);
        return q;
      });
      q.limit = jest.fn(() => q);
      q.orderBy = jest.fn(() => q);
      q.get = jest.fn(async () => {
        const rows = applyConds(collData(name), conds);
        return {
          empty: rows.length === 0,
          size: rows.length,
          docs: rows.map((d, i) => ({
            id: d.id || `${name}-${i}`,
            data: () => d.data ?? d,
            ref: {
              set: jest.fn().mockResolvedValue(undefined),
              update: jest.fn(async (p: any) => {
                if (name === 'leaves') writes.leavesUpdated.push(p);
              }),
              delete: jest.fn(async () => {
                if (name === 'leaves') writes.leavesDeleted.push(d.id || '');
              }),
            },
          })),
        };
      });
      q.add = jest.fn(async (payload: any) => {
        if (name === 'leaves') writes.leavesAdded.push(payload);
        return {
          id: `${name}-new`,
          get: async () => ({ id: `${name}-new`, data: () => payload }),
        };
      });
      q.doc = jest.fn((id: string) => {
        const rec =
          name === 'leaves'
            ? opts.leaveDocs?.[id]
            : name === 'users'
              ? opts.users?.[id]
              : undefined;
        const exists = rec !== undefined;
        const ref = {
          set: jest.fn().mockResolvedValue(undefined),
          update: jest.fn(async (p: any) => {
            if (name === 'leaves') writes.leavesUpdated.push(p);
          }),
          delete: jest.fn(async () => {
            if (name === 'leaves') writes.leavesDeleted.push(id);
          }),
        };
        return {
          id,
          get: jest.fn(async () => ({
            exists,
            id,
            data: () => rec?.data ?? rec,
            ref,
          })),
          ...ref,
        };
      });
      return q;
    }),
    getAll: jest.fn().mockResolvedValue([]),
    batch: jest.fn().mockReturnValue({
      set: jest.fn(),
      update: jest.fn(),
      commit: jest.fn().mockResolvedValue(undefined),
    }),
  });
  return writes;
}

const profile = (features: string[] | undefined, extra: any = {}) => ({
  status: 'active',
  ...(features !== undefined ? { enabledFeatures: features } : {}),
  ...extra,
});

const LEAVE_FEATURES = [
  'attendance',
  'employee_master',
  'feedback',
  'shifts',
  'leave_management',
];

const pendingLeave = (over: any = {}) => ({
  companyId: 'c1',
  userId: 'u-2',
  empid: 'E002',
  name: 'Other Employee',
  leaveType: 'Casual Leave',
  startDate: '2030-01-10',
  endDate: '2030-01-12',
  reason: 'x',
  status: 'Pending',
  ...over,
});

describe('Leave — POST /api/leaves (create)', () => {
  beforeEach(() => jest.clearAllMocks());

  test('creates request with companyId from JWT (body companyId ignored)', async () => {
    const w = installDb({
      profile: profile(LEAVE_FEATURES),
      employees: [{ empid: 'E001', companyId: 'c1', firstName: 'Emp', lastName: 'One' }],
    });
    const res = await request(app)
      .post('/api/leaves')
      .set('Authorization', `Bearer ${tok('employee')}`)
      .send(leaveBody({ companyId: 'c2-spoofed' }));
    expect(res.status).toBe(201);
    expect(w.leavesAdded.length).toBe(1);
    expect(w.leavesAdded[0].companyId).toBe('c1');
    expect(w.leavesAdded[0].status).toBe('Pending');
  });

  test('overlap with existing Pending/Approved → 409 LEAVE_OVERLAP, no write', async () => {
    const w = installDb({
      profile: profile(LEAVE_FEATURES),
      employees: [{ empid: 'E001', companyId: 'c1', name: 'Emp' }],
      leaves: [
        {
          data: pendingLeave({
            userId: 'u-1',
            empid: 'E001',
            startDate: '2030-01-11',
            endDate: '2030-01-15',
          }),
        },
      ],
    });
    const res = await request(app)
      .post('/api/leaves')
      .set('Authorization', `Bearer ${tok('employee')}`)
      .send(leaveBody());
    expect(res.status).toBe(409);
    expect(res.body.code).toBe('LEAVE_OVERLAP');
    expect(w.leavesAdded.length).toBe(0);
  });

  test('non-overlapping existing leave → creates', async () => {
    const w = installDb({
      profile: profile(LEAVE_FEATURES),
      employees: [{ empid: 'E001', companyId: 'c1', name: 'Emp' }],
      leaves: [
        {
          data: pendingLeave({
            userId: 'u-1',
            empid: 'E001',
            startDate: '2030-02-01',
            endDate: '2030-02-02',
          }),
        },
      ],
    });
    const res = await request(app)
      .post('/api/leaves')
      .set('Authorization', `Bearer ${tok('employee')}`)
      .send(leaveBody());
    expect(res.status).toBe(201);
    expect(w.leavesAdded.length).toBe(1);
  });

  test('leave_management disabled → 403 FEATURE_NOT_ENABLED, no write', async () => {
    const w = installDb({
      profile: profile(['attendance', 'employee_master', 'feedback', 'shifts']),
      employees: [{ empid: 'E001', companyId: 'c1' }],
    });
    const res = await request(app)
      .post('/api/leaves')
      .set('Authorization', `Bearer ${tok('employee')}`)
      .send(leaveBody());
    expect(res.status).toBe(403);
    expect(res.body.error).toBe('FEATURE_NOT_ENABLED');
    expect(w.leavesAdded.length).toBe(0);
  });

  test('legacy org (no enabledFeatures) → create works', async () => {
    const w = installDb({
      profile: profile(undefined),
      employees: [{ empid: 'E001', companyId: 'c1', name: 'Emp' }],
    });
    const res = await request(app)
      .post('/api/leaves')
      .set('Authorization', `Bearer ${tok('employee')}`)
      .send(leaveBody());
    expect(res.status).toBe(201);
    expect(w.leavesAdded.length).toBe(1);
  });

  test('missing required fields → 400', async () => {
    installDb({ profile: profile(LEAVE_FEATURES) });
    const res = await request(app)
      .post('/api/leaves')
      .set('Authorization', `Bearer ${tok('employee')}`)
      .send({ startDate: '2030-01-01' });
    expect(res.status).toBe(400);
  });
});

describe('Leave — employee read isolation', () => {
  beforeEach(() => jest.clearAllMocks());

  test('employee cannot list another userId requests', async () => {
    installDb({ profile: profile(LEAVE_FEATURES) });
    const res = await request(app)
      .get('/api/leaves?userId=someone-else')
      .set('Authorization', `Bearer ${tok('employee')}`);
    expect(res.status).toBe(403);
  });

  test('employee can list own requests', async () => {
    installDb({
      profile: profile(LEAVE_FEATURES),
      leaves: [{ data: pendingLeave({ userId: 'u-1', empid: 'E001' }) }],
    });
    const res = await request(app)
      .get('/api/leaves')
      .set('Authorization', `Bearer ${tok('employee')}`);
    expect(res.status).toBe(200);
    expect(res.body.data.length).toBe(1);
  });

  test('request-details: employee cannot read coworker leave (IDOR)', async () => {
    installDb({
      profile: profile(LEAVE_FEATURES),
      leaveDocs: { 'L1': { data: pendingLeave() } },
    });
    const res = await request(app)
      .get('/api/attendance/request-details?src=leaves&id=L1')
      .set('Authorization', `Bearer ${tok('employee')}`);
    expect(res.status).toBe(403);
  });

  test('request-details: employee can read own leave', async () => {
    installDb({
      profile: profile(LEAVE_FEATURES),
      leaveDocs: {
        'L1': { data: pendingLeave({ userId: 'u-1', empid: 'E001' }) },
      },
    });
    const res = await request(app)
      .get('/api/attendance/request-details?src=leaves&id=L1')
      .set('Authorization', `Bearer ${tok('employee')}`);
    expect(res.status).toBe(200);
    expect(res.body.requestId).toBe('L1');
  });

  test('request-details: admin can read any leave in own company', async () => {
    installDb({
      profile: profile(LEAVE_FEATURES),
      leaveDocs: { 'L1': { data: pendingLeave() } },
    });
    const res = await request(app)
      .get('/api/attendance/request-details?src=leaves&id=L1')
      .set('Authorization', `Bearer ${tok('admin', 'c1', 'adm-1', 'A001')}`);
    expect(res.status).toBe(200);
  });
});

describe('Leave — admin decisions', () => {
  beforeEach(() => jest.clearAllMocks());

  test('employee role cannot hit /attendance/approvals/decision', async () => {
    const w = installDb({
      profile: profile(LEAVE_FEATURES),
      leaveDocs: { 'L1': { data: pendingLeave() } },
    });
    const res = await request(app)
      .post('/api/attendance/approvals/decision')
      .set('Authorization', `Bearer ${tok('employee')}`)
      .send({ source: 'leaves', leaveId: 'L1', status: 'Approved' });
    expect(res.status).toBe(403);
    expect(w.leavesUpdated.length).toBe(0);
  });

  test('admin approve normal leave requires paid/unpaid', async () => {
    const w = installDb({
      profile: profile(LEAVE_FEATURES),
      leaveDocs: { 'L1': { data: pendingLeave() } },
    });
    const res = await request(app)
      .post('/api/attendance/approvals/decision')
      .set('Authorization', `Bearer ${tok('admin', 'c1', 'adm-1', 'A001')}`)
      .send({ source: 'leaves', leaveId: 'L1', status: 'Approved' });
    expect(res.status).toBe(400);
    expect(w.leavesUpdated.length).toBe(0);
  });

  test('admin approve with leavePayType=paid → 200, status written', async () => {
    const w = installDb({
      profile: profile(LEAVE_FEATURES),
      leaveDocs: { 'L1': { data: pendingLeave() } },
    });
    const res = await request(app)
      .post('/api/attendance/approvals/decision')
      .set('Authorization', `Bearer ${tok('admin', 'c1', 'adm-1', 'A001')}`)
      .send({
        source: 'leaves',
        leaveId: 'L1',
        status: 'Approved',
        leavePayType: 'paid',
      });
    expect(res.status).toBe(200);
    expect(w.leavesUpdated.length).toBe(1);
    expect(w.leavesUpdated[0].status).toBe('Approved');
    expect(w.leavesUpdated[0].leavePayType).toBe('paid');
  });

  test('admin reject clears leavePayType', async () => {
    const w = installDb({
      profile: profile(LEAVE_FEATURES),
      leaveDocs: { 'L1': { data: pendingLeave() } },
    });
    const res = await request(app)
      .post('/api/attendance/approvals/decision')
      .set('Authorization', `Bearer ${tok('admin', 'c1', 'adm-1', 'A001')}`)
      .send({ source: 'leaves', leaveId: 'L1', status: 'Rejected' });
    expect(res.status).toBe(200);
    expect(w.leavesUpdated[0].status).toBe('Rejected');
    expect(w.leavesUpdated[0].leavePayType).toBeNull();
  });

  test('admin cannot decide own leave (self-approval blocked)', async () => {
    const w = installDb({
      profile: profile(LEAVE_FEATURES),
      leaveDocs: { 'L1': { data: pendingLeave({ userId: 'adm-1', empid: 'A001' }) } },
    });
    const res = await request(app)
      .post('/api/attendance/approvals/decision')
      .set('Authorization', `Bearer ${tok('admin', 'c1', 'adm-1', 'A001')}`)
      .send({
        source: 'leaves',
        leaveId: 'L1',
        status: 'Approved',
        leavePayType: 'paid',
      });
    expect(res.status).toBe(403);
    expect(w.leavesUpdated.length).toBe(0);
  });

  test('cross-company leave decision → 403', async () => {
    const w = installDb({
      profile: profile(LEAVE_FEATURES),
      leaveDocs: { 'L1': { data: pendingLeave({ companyId: 'c2' }) } },
    });
    const res = await request(app)
      .post('/api/attendance/approvals/decision')
      .set('Authorization', `Bearer ${tok('admin', 'c1', 'adm-1', 'A001')}`)
      .send({
        source: 'leaves',
        leaveId: 'L1',
        status: 'Approved',
        leavePayType: 'paid',
      });
    expect(res.status).toBe(403);
    expect(w.leavesUpdated.length).toBe(0);
  });

  test('leave_management off → leave decision denied via approvals route', async () => {
    const w = installDb({
      profile: profile(['attendance', 'employee_master']),
      leaveDocs: { 'L1': { data: pendingLeave() } },
    });
    const res = await request(app)
      .post('/api/attendance/approvals/decision')
      .set('Authorization', `Bearer ${tok('admin', 'c1', 'adm-1', 'A001')}`)
      .send({ source: 'leaves', leaveId: 'L1', status: 'Rejected' });
    expect(res.status).toBe(403);
    expect(res.body.error).toBe('FEATURE_NOT_ENABLED');
    expect(w.leavesUpdated.length).toBe(0);
  });

  test('legacy org (no enabledFeatures) → leave decision allowed', async () => {
    const w = installDb({
      profile: profile(undefined),
      leaveDocs: { 'L1': { data: pendingLeave() } },
    });
    const res = await request(app)
      .post('/api/attendance/approvals/decision')
      .set('Authorization', `Bearer ${tok('admin', 'c1', 'adm-1', 'A001')}`)
      .send({ source: 'leaves', leaveId: 'L1', status: 'Rejected' });
    expect(res.status).toBe(200);
    expect(w.leavesUpdated.length).toBe(1);
  });

  test('PUT /leaves/:id/status — self-approval blocked', async () => {
    const w = installDb({
      profile: profile(LEAVE_FEATURES),
      leaveDocs: {
        'L1': { data: pendingLeave({ userId: 'adm-1', empid: 'A001' }) },
      },
    });
    const res = await request(app)
      .put('/api/leaves/L1/status')
      .set('Authorization', `Bearer ${tok('admin', 'c1', 'adm-1', 'A001')}`)
      .send({ status: 'Approved' });
    expect(res.status).toBe(403);
    expect(w.leavesUpdated.length).toBe(0);
  });

  test('PUT /leaves/:id/status — admin approve other user works', async () => {
    const w = installDb({
      profile: profile(LEAVE_FEATURES),
      leaveDocs: { 'L1': { data: pendingLeave() } },
    });
    const res = await request(app)
      .put('/api/leaves/L1/status')
      .set('Authorization', `Bearer ${tok('admin', 'c1', 'adm-1', 'A001')}`)
      .send({ status: 'Approved' });
    expect(res.status).toBe(200);
    expect(w.leavesUpdated[0].status).toBe('Approved');
  });
});

describe('Leave — cancel + pending list', () => {
  beforeEach(() => jest.clearAllMocks());

  test('owner cancels own pending → 200', async () => {
    const w = installDb({
      profile: profile(LEAVE_FEATURES),
      leaveDocs: {
        'L1': { data: pendingLeave({ userId: 'u-1', empid: 'E001' }) },
      },
    });
    const res = await request(app)
      .put('/api/leaves/L1/cancel')
      .set('Authorization', `Bearer ${tok('employee')}`)
      .send({ reason: 'plans changed' });
    expect(res.status).toBe(200);
    expect(w.leavesUpdated[0].status).toBe('Cancelled');
  });

  test('employee cannot cancel another user leave', async () => {
    const w = installDb({
      profile: profile(LEAVE_FEATURES),
      leaveDocs: { 'L1': { data: pendingLeave() } },
    });
    const res = await request(app)
      .put('/api/leaves/L1/cancel')
      .set('Authorization', `Bearer ${tok('employee')}`)
      .send({});
    expect(res.status).toBe(403);
    expect(w.leavesUpdated.length).toBe(0);
  });

  test('non-pending leave cannot be cancelled', async () => {
    installDb({
      profile: profile(LEAVE_FEATURES),
      leaveDocs: {
        'L1': {
          data: pendingLeave({ userId: 'u-1', empid: 'E001', status: 'Approved' }),
        },
      },
    });
    const res = await request(app)
      .put('/api/leaves/L1/cancel')
      .set('Authorization', `Bearer ${tok('employee')}`)
      .send({});
    expect(res.status).toBe(400);
  });

  test('GET /leaves/pending is admin-only and company-scoped', async () => {
    installDb({ profile: profile(LEAVE_FEATURES) });
    const empRes = await request(app)
      .get('/api/leaves/pending')
      .set('Authorization', `Bearer ${tok('employee')}`);
    expect(empRes.status).toBe(403);

    const w = installDb({
      profile: profile(LEAVE_FEATURES),
      leaves: [
        { data: pendingLeave() },
        { data: pendingLeave({ companyId: 'c2' }) },
      ],
    });
    const adminRes = await request(app)
      .get('/api/leaves/pending')
      .set('Authorization', `Bearer ${tok('admin', 'c1', 'adm-1', 'A001')}`);
    expect(adminRes.status).toBe(200);
    expect(adminRes.body.length).toBe(1);
    expect(adminRes.body[0].companyId).toBe('c1');
    void w;
  });
});
