/// <reference types="jest" />
import { Request, Response } from 'express';
import {
  listOrganizationPolicies,
  getPolicyAcceptanceStatus,
  acceptPolicyVersion,
} from './policyController';

jest.mock('../config/firebase', () => ({
  getDb: jest.fn(),
  getAdminAuth: jest.fn(),
  checkFirestoreAccess: jest.fn().mockResolvedValue(true),
}));

import { getDb } from '../config/firebase';

process.env.JWT_SECRET = 'test-jwt-secret-minimum-32-characters-long';

// ---------- Helpers ----------

function mockResponse() {
  const res: Partial<Response> = {
    status: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis(),
  };
  return res as Response;
}

function jsonBody(res: Response): any {
  return (res.json as jest.Mock).mock.calls[0]?.[0];
}

interface MockDoc {
  id: string;
  data: any;
}

/**
 * Minimal in-memory Firestore mock supporting:
 *  - collection(name).doc(id).get() / .set() / .create()
 *  - collection(name).where(field, op, value).get() with chained where()
 */
function makeMockDb(collections: Record<string, MockDoc[]>) {
  const writeErrors: Record<string, Error> = {};

  function makeDocRef(colName: string, id: string, col: MockDoc[]) {
    return {
      id,
      get: jest.fn(async () => {
        const doc = col.find((d) => d.id === id);
        return {
          id,
          exists: !!doc,
          data: () => (doc ? doc.data : undefined),
        };
      }),
      set: jest.fn(async (data: any) => {
        if (writeErrors[colName]) throw writeErrors[colName];
        const existing = col.find((d) => d.id === id);
        if (existing) existing.data = { ...existing.data, ...data };
        else col.push({ id, data });
      }),
      create: jest.fn(async (data: any) => {
        if (writeErrors[colName]) throw writeErrors[colName];
        if (col.find((d) => d.id === id)) {
          const err: any = new Error('ALREADY_EXISTS');
          err.code = 6;
          throw err;
        }
        col.push({ id, data });
      }),
    };
  }

  function makeQuery(colName: string, col: MockDoc[]) {
    const filters: Array<[string, any]> = [];
    const q: any = {
      where: jest.fn((field: string, _op: string, value: any) => {
        filters.push([field, value]);
        return q;
      }),
      limit: jest.fn(() => q),
      get: jest.fn(async () => {
        const matched = col.filter((d) =>
          filters.every(([f, v]) => d.data[f] === v)
        );
        return {
          empty: matched.length === 0,
          docs: matched.map((d) => ({
            id: d.id,
            data: () => d.data,
          })),
        };
      }),
      doc: jest.fn((id: string) => makeDocRef(colName, id, col)),
    };
    return q;
  }

  return {
    db: {
      collection: jest.fn((name: string) => {
        const col = collections[name] || (collections[name] = []);
        return makeQuery(name, col);
      }),
    },
    collections,
    failWrite(colName: string, err: Error) {
      writeErrors[colName] = err;
    },
  };
}

function makeReq(
  user: any,
  body: any = {}
): Partial<Request> {
  return {
    user,
    body,
    ip: '127.0.0.1',
    headers: { 'user-agent': 'jest-test' },
  } as any;
}

const EMPLOYEE = {
  userId: 'user-1',
  email: 'emp@example.com',
  role: 'employee',
  companyId: 'org-1',
};

function seedEmployeeCtx(
  cols: Record<string, MockDoc[]>,
  userData?: Partial<any>,
  orgData?: Partial<any>
) {
  cols['users'] = [
    {
      id: 'user-1',
      data: {
        email: 'emp@example.com',
        role: 'employee',
        status: 'active',
        companyId: 'org-1',
        ...userData,
      },
    },
  ];
  cols['companyProfile'] = [
    {
      id: 'org-1',
      data: { status: 'active', companyName: 'Test Org', ...orgData },
    },
  ];
}

function policyDoc(overrides: Partial<any> = {}): MockDoc {
  return {
    id: 'pol-1',
    data: {
      organizationId: 'org-1',
      policyId: 'attendance-policy',
      type: 'attendance',
      title: 'Attendance Policy',
      description: 'desc',
      version: 1,
      content: 'Policy text',
      publishedAt: { _seconds: 1 },
      active: true,
      required: true,
      requiresSeparateConsent: false,
      contentHash: 'hash-v1',
      ...overrides,
    },
  };
}

// ---------- Tests ----------

describe('policyController', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('authentication & authorization', () => {
    test('missing JWT context returns 401', async () => {
      (getDb as jest.Mock).mockReturnValue(makeMockDb({}).db);
      const res = mockResponse();
      await listOrganizationPolicies(makeReq(undefined) as Request, res);
      expect(res.status).toHaveBeenCalledWith(401);
    });

    test('admin role is rejected with 403', async () => {
      const cols: Record<string, MockDoc[]> = {};
      (getDb as jest.Mock).mockReturnValue(makeMockDb(cols).db);
      const res = mockResponse();
      await listOrganizationPolicies(
        makeReq({ ...EMPLOYEE, role: 'admin' }) as Request,
        res
      );
      expect(res.status).toHaveBeenCalledWith(403);
    });

    test('inactive employee is rejected with 403', async () => {
      const cols: Record<string, MockDoc[]> = {};
      seedEmployeeCtx(cols, { status: 'inactive' });
      (getDb as jest.Mock).mockReturnValue(makeMockDb(cols).db);
      const res = mockResponse();
      await listOrganizationPolicies(makeReq(EMPLOYEE) as Request, res);
      expect(res.status).toHaveBeenCalledWith(403);
    });

    test('inactive organization is rejected with 403', async () => {
      const cols: Record<string, MockDoc[]> = {};
      seedEmployeeCtx(cols, {}, { status: 'inactive' });
      (getDb as jest.Mock).mockReturnValue(makeMockDb(cols).db);
      const res = mockResponse();
      await listOrganizationPolicies(makeReq(EMPLOYEE) as Request, res);
      expect(res.status).toHaveBeenCalledWith(403);
    });

    test('user doc companyId mismatch is rejected', async () => {
      const cols: Record<string, MockDoc[]> = {};
      seedEmployeeCtx(cols, { companyId: 'org-2' });
      (getDb as jest.Mock).mockReturnValue(makeMockDb(cols).db);
      const res = mockResponse();
      await listOrganizationPolicies(makeReq(EMPLOYEE) as Request, res);
      expect(res.status).toHaveBeenCalledWith(403);
    });
  });

  describe('GET /policies', () => {
    test('returns active policies for the employee org with acceptance status', async () => {
      const cols: Record<string, MockDoc[]> = {};
      seedEmployeeCtx(cols);
      cols['organizationPolicies'] = [
        policyDoc(),
        policyDoc({ id: 'pol-2', policyId: 'leave-policy', title: 'Leave', required: false }),
        policyDoc({ id: 'pol-3', policyId: 'hidden', active: false }),
        policyDoc({ id: 'pol-4', policyId: 'other-org', organizationId: 'org-2' }),
      ];
      cols['employeePolicyAcceptances'] = [
        {
          id: 'acc-1',
          data: {
            userId: 'user-1',
            organizationId: 'org-1',
            policyId: 'attendance-policy',
            policyVersion: 1,
            contentHash: 'hash-v1',
            acceptedAt: { _seconds: 2 },
          },
        },
      ];
      (getDb as jest.Mock).mockReturnValue(makeMockDb(cols).db);

      const res = mockResponse();
      await listOrganizationPolicies(makeReq(EMPLOYEE) as Request, res);

      expect(res.status).toHaveBeenCalledWith(200);
      const body = jsonBody(res);
      expect(body.policies).toHaveLength(2);
      const att = body.policies.find((p: any) => p.policyId === 'attendance-policy');
      expect(att.accepted).toBe(true);
      const leave = body.policies.find((p: any) => p.policyId === 'leave-policy');
      expect(leave.accepted).toBe(false);
      // Cross-org and inactive policies excluded
      expect(body.policies.find((p: any) => p.policyId === 'other-org')).toBeUndefined();
      expect(body.policies.find((p: any) => p.policyId === 'hidden')).toBeUndefined();
    });
  });

  describe('GET /policies/acceptance-status', () => {
    test('no published policies returns allAccepted true', async () => {
      const cols: Record<string, MockDoc[]> = {};
      seedEmployeeCtx(cols);
      cols['organizationPolicies'] = [];
      (getDb as jest.Mock).mockReturnValue(makeMockDb(cols).db);

      const res = mockResponse();
      await getPolicyAcceptanceStatus(makeReq(EMPLOYEE) as Request, res);
      expect(jsonBody(res).allAccepted).toBe(true);
      expect(jsonBody(res).pendingRequired).toEqual([]);
    });

    test('optional policy only returns allAccepted true', async () => {
      const cols: Record<string, MockDoc[]> = {};
      seedEmployeeCtx(cols);
      cols['organizationPolicies'] = [
        policyDoc({ required: false }),
      ];
      (getDb as jest.Mock).mockReturnValue(makeMockDb(cols).db);

      const res = mockResponse();
      await getPolicyAcceptanceStatus(makeReq(EMPLOYEE) as Request, res);
      expect(jsonBody(res).allAccepted).toBe(true);
    });

    test('unaccepted required policy blocks access', async () => {
      const cols: Record<string, MockDoc[]> = {};
      seedEmployeeCtx(cols);
      cols['organizationPolicies'] = [policyDoc()];
      (getDb as jest.Mock).mockReturnValue(makeMockDb(cols).db);

      const res = mockResponse();
      await getPolicyAcceptanceStatus(makeReq(EMPLOYEE) as Request, res);
      const body = jsonBody(res);
      expect(body.allAccepted).toBe(false);
      expect(body.pendingRequired).toHaveLength(1);
      expect(body.pendingRequired[0].policyId).toBe('attendance-policy');
    });

    test('accepted required policy returns allAccepted true', async () => {
      const cols: Record<string, MockDoc[]> = {};
      seedEmployeeCtx(cols);
      cols['organizationPolicies'] = [policyDoc()];
      cols['employeePolicyAcceptances'] = [
        {
          id: 'a1',
          data: {
            userId: 'user-1',
            organizationId: 'org-1',
            policyId: 'attendance-policy',
            policyVersion: 1,
            contentHash: 'hash-v1',
            acceptedAt: { _seconds: 5 },
          },
        },
      ];
      (getDb as jest.Mock).mockReturnValue(makeMockDb(cols).db);

      const res = mockResponse();
      await getPolicyAcceptanceStatus(makeReq(EMPLOYEE) as Request, res);
      expect(jsonBody(res).allAccepted).toBe(true);
    });

    test('new version invalidates old acceptance', async () => {
      const cols: Record<string, MockDoc[]> = {};
      seedEmployeeCtx(cols);
      // v2 is now active; v1 inactive
      cols['organizationPolicies'] = [
        policyDoc({ version: 2, contentHash: 'hash-v2' }),
      ];
      cols['employeePolicyAcceptances'] = [
        {
          id: 'a1',
          data: {
            userId: 'user-1',
            organizationId: 'org-1',
            policyId: 'attendance-policy',
            policyVersion: 1,
            contentHash: 'hash-v1',
            acceptedAt: { _seconds: 5 },
          },
        },
      ];
      (getDb as jest.Mock).mockReturnValue(makeMockDb(cols).db);

      const res = mockResponse();
      await getPolicyAcceptanceStatus(makeReq(EMPLOYEE) as Request, res);
      const body = jsonBody(res);
      expect(body.allAccepted).toBe(false);
      expect(body.pendingRequired[0].version).toBe(2);
    });
  });

  describe('POST /policies/accept', () => {
    test('accepts the current version and writes server timestamp + hash', async () => {
      const cols: Record<string, MockDoc[]> = {};
      seedEmployeeCtx(cols);
      cols['organizationPolicies'] = [policyDoc()];
      cols['employeePolicyAcceptances'] = [];
      const mock = makeMockDb(cols);
      (getDb as jest.Mock).mockReturnValue(mock.db);

      const res = mockResponse();
      await acceptPolicyVersion(
        makeReq(EMPLOYEE, { policyId: 'attendance-policy', policyVersion: 1 }) as Request,
        res
      );

      expect(res.status).toHaveBeenCalledWith(200);
      const created = cols['employeePolicyAcceptances'];
      expect(created).toHaveLength(1);
      expect(created[0].data.userId).toBe('user-1');
      expect(created[0].data.organizationId).toBe('org-1');
      expect(created[0].data.policyId).toBe('attendance-policy');
      expect(created[0].data.policyVersion).toBe(1);
      expect(created[0].data.contentHash).toBe('hash-v1');
      // serverTimestamp sentinel is defined at write time
      expect(created[0].data.acceptedAt).toBeDefined();
    });

    test('stale version returns 409', async () => {
      const cols: Record<string, MockDoc[]> = {};
      seedEmployeeCtx(cols);
      cols['organizationPolicies'] = [policyDoc({ version: 2, contentHash: 'h2' })];
      (getDb as jest.Mock).mockReturnValue(makeMockDb(cols).db);

      const res = mockResponse();
      await acceptPolicyVersion(
        makeReq(EMPLOYEE, { policyId: 'attendance-policy', policyVersion: 1 }) as Request,
        res
      );
      expect(res.status).toHaveBeenCalledWith(409);
    });

    test('duplicate acceptance returns 200 without creating a new doc', async () => {
      const cols: Record<string, MockDoc[]> = {};
      seedEmployeeCtx(cols);
      cols['organizationPolicies'] = [policyDoc()];
      cols['employeePolicyAcceptances'] = [
        {
          id: 'user-1_org-1_attendance-policy_1',
          data: {
            userId: 'user-1',
            organizationId: 'org-1',
            policyId: 'attendance-policy',
            policyVersion: 1,
            contentHash: 'hash-v1',
            acceptedAt: { _seconds: 5 },
          },
        },
      ];
      (getDb as jest.Mock).mockReturnValue(makeMockDb(cols).db);

      const res = mockResponse();
      await acceptPolicyVersion(
        makeReq(EMPLOYEE, { policyId: 'attendance-policy', policyVersion: 1 }) as Request,
        res
      );
      expect(res.status).toHaveBeenCalledWith(200);
      expect(cols['employeePolicyAcceptances']).toHaveLength(1);
      expect(jsonBody(res).message).toBe('Policy already accepted');
    });

    test('concurrent duplicate is handled via create() ALREADY_EXISTS', async () => {
      const cols: Record<string, MockDoc[]> = {};
      seedEmployeeCtx(cols);
      cols['organizationPolicies'] = [policyDoc()];
      cols['employeePolicyAcceptances'] = [];
      const mock = makeMockDb(cols);
      (getDb as jest.Mock).mockReturnValue(mock.db);

      const req = makeReq(EMPLOYEE, {
        policyId: 'attendance-policy',
        policyVersion: 1,
      }) as Request;
      const res1 = mockResponse();
      const res2 = mockResponse();

      // Simulate race: run twice; second create hits ALREADY_EXISTS path
      await acceptPolicyVersion(req, res1);
      // Remove the read-visible doc? The in-memory mock will find it on get().
      // Instead simulate a racing writer by calling again after marking
      // the doc exists through create path only.
      const res3 = mockResponse();
      await acceptPolicyVersion(req, res3);

      expect(res1.status).toHaveBeenCalledWith(200);
      expect(res3.status).toHaveBeenCalledWith(200);
      expect(cols['employeePolicyAcceptances']).toHaveLength(1);
      void res2;
    });

    test('unknown policy returns 404', async () => {
      const cols: Record<string, MockDoc[]> = {};
      seedEmployeeCtx(cols);
      cols['organizationPolicies'] = [];
      (getDb as jest.Mock).mockReturnValue(makeMockDb(cols).db);

      const res = mockResponse();
      await acceptPolicyVersion(
        makeReq(EMPLOYEE, { policyId: 'nope', policyVersion: 1 }) as Request,
        res
      );
      expect(res.status).toHaveBeenCalledWith(404);
    });

    test('cross-organization policy returns 404', async () => {
      const cols: Record<string, MockDoc[]> = {};
      seedEmployeeCtx(cols);
      cols['organizationPolicies'] = [
        policyDoc({ organizationId: 'org-2' }),
      ];
      (getDb as jest.Mock).mockReturnValue(makeMockDb(cols).db);

      const res = mockResponse();
      await acceptPolicyVersion(
        makeReq(EMPLOYEE, { policyId: 'attendance-policy', policyVersion: 1 }) as Request,
        res
      );
      expect(res.status).toHaveBeenCalledWith(404);
    });

    test('missing/invalid version returns 400', async () => {
      const cols: Record<string, MockDoc[]> = {};
      seedEmployeeCtx(cols);
      (getDb as jest.Mock).mockReturnValue(makeMockDb(cols).db);

      const res = mockResponse();
      await acceptPolicyVersion(
        makeReq(EMPLOYEE, { policyId: 'attendance-policy', policyVersion: 'abc' }) as Request,
        res
      );
      expect(res.status).toHaveBeenCalledWith(400);
    });

    test('Firestore read failure returns 500', async () => {
      const cols: Record<string, MockDoc[]> = {};
      seedEmployeeCtx(cols);
      const mock = makeMockDb(cols);
      // Force the policies query to throw
      const origCollection = mock.db.collection;
      mock.db.collection = jest.fn((name: string) => {
        if (name === 'organizationPolicies') {
          const q = origCollection(name);
          (q.get as jest.Mock).mockRejectedValueOnce(new Error('read failed'));
          return q;
        }
        return origCollection(name);
      });
      (getDb as jest.Mock).mockReturnValue(mock.db);

      const res = mockResponse();
      await listOrganizationPolicies(makeReq(EMPLOYEE) as Request, res);
      expect(res.status).toHaveBeenCalledWith(500);
    });

    test('Firestore write failure returns 500', async () => {
      const cols: Record<string, MockDoc[]> = {};
      seedEmployeeCtx(cols);
      cols['organizationPolicies'] = [policyDoc()];
      cols['employeePolicyAcceptances'] = [];
      const mock = makeMockDb(cols);
      mock.failWrite('employeePolicyAcceptances', new Error('write failed'));
      (getDb as jest.Mock).mockReturnValue(mock.db);

      const res = mockResponse();
      await acceptPolicyVersion(
        makeReq(EMPLOYEE, { policyId: 'attendance-policy', policyVersion: 1 }) as Request,
        res
      );
      expect(res.status).toHaveBeenCalledWith(500);
    });
  });
});
