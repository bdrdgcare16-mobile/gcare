// functions/src/controllers/employeeController.test.ts
/// <reference types="jest" />

import { Request, Response } from 'express';

process.env.FUNCTIONS_EMULATOR = 'true';
process.env.JWT_SECRET = 'test-jwt-secret-emp';

jest.mock('../config/firebase', () => ({
  getDb: jest.fn(),
  checkFirestoreAccess: jest.fn().mockResolvedValue(true),
}));

jest.mock('../services/usageService', () => ({
  trackUsage: jest.fn().mockResolvedValue(undefined),
}));

import { getDb } from '../config/firebase';
import {
  createEmployee,
  deleteEmployee,
  getEmployeeById,
  getEmployees,
  updateEmployee,
} from './employeeController';
import { roleMiddleware } from '../middlewares/authMiddleware';
import { liveEmployeeDetails } from './liveEmployeeDetailsController';

/* ------------------------- fake Firestore ------------------------- */

function makeDb(seed: Record<string, any[]>) {
  const store: Record<string, any[]> = {};
  for (const [k, docs] of Object.entries(seed)) {
    store[k] = docs.map((d) => ({ ...d }));
  }
  const snap = (docs: any[]) => ({
    empty: docs.length === 0,
    size: docs.length,
    docs: docs.map((d) => ({
      id: d.id,
      data: () => d,
      ref: { set: jest.fn(async () => {}), update: jest.fn(async () => {}) },
    })),
  });
  const collection = (name: string): any => {
    const mkQuery = (filters: [string, any][]): any => ({
      where: (f: string, _op: string, v: any) => mkQuery([...filters, [f, v]]),
      limit: () => mkQuery(filters),
      get: async () =>
        snap(
          (store[name] || []).filter((d) =>
            filters.every(([f, v]) => d[f] === v),
          ),
        ),
    });
    return {
      where: (f: string, _op: string, v: any) => mkQuery([[f, v]]),
      get: async () => snap(store[name] || []),
      doc: (id: string) => ({
        get: async () => {
          const d = (store[name] || []).find((x) => x.id === id);
          return { exists: !!d, id, data: () => d };
        },
        update: jest.fn(async (updates: any) => {
          const d = store[name].find((x) => x.id === id);
          if (d) Object.assign(d, updates);
        }),
        delete: jest.fn(async () => {
          store[name] = (store[name] || []).filter((x) => x.id !== id);
        }),
        set: jest.fn(),
      }),
      add: jest.fn(async (data: any) => {
        const id = `new-${(store[name] || []).length + 1}`;
        const d = { id, ...data };
        (store[name] ||= []).push(d);
        return { id, get: async () => ({ id, exists: true, data: () => d }) };
      }),
    };
  };
  return { collection, _store: store };
}

/* ------------------------- helpers ------------------------- */

function mockResponse() {
  const res: Partial<Response> = {
    status: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis(),
  };
  return res as Response;
}
const statusCode = (res: Response) => (res.status as jest.Mock).mock.calls[0]?.[0];
const jsonBody = (res: Response) => (res.json as jest.Mock).mock.calls[0]?.[0];

const ADMIN_A = { userId: 'adm-a', email: 'a@a.com', role: 'admin', companyId: 'companyA' };
const ADMIN_B = { userId: 'adm-b', email: 'b@b.com', role: 'admin', companyId: 'companyB' };

const reqWith = (user: any, body: any = {}, params: any = {}, query: any = {}) =>
  ({ user, body, params, query, headers: {} }) as unknown as Request;

const seedEmps = () => ({
  employees: [
    { id: 'eA1', companyId: 'companyA', empid: 'EMP001', name: 'Alice', email: 'alice@a.com', status: 'active', role: 'employee' },
    { id: 'eB1', companyId: 'companyB', empid: 'EMP777', name: 'Bob', email: 'bob@b.com', status: 'active', role: 'employee' },
  ],
});

describe('Employee Master controller (3D-E)', () => {
  beforeEach(() => jest.clearAllMocks());

  describe('role gate (route middleware)', () => {
    const next = jest.fn();
    it.each(['employee', 'org_applicant'])(
      'denies %s from admin employee endpoints',
      async (role) => {
        const mw = roleMiddleware(['admin']);
        const res = mockResponse();
        await mw(reqWith({ role, companyId: 'companyA' }), res, next);
        expect(statusCode(res)).toBe(403);
      },
    );
    it('allows admin', async () => {
      const mw = roleMiddleware(['admin']);
      const res = mockResponse();
      const nextFn = jest.fn();
      await mw(reqWith(ADMIN_A), res, nextFn);
      expect(nextFn).toHaveBeenCalled();
    });
  });

  describe('list', () => {
    it('returns only own-company employees', async () => {
      const db = makeDb(seedEmps());
      (getDb as jest.Mock).mockReturnValue(db);
      const res = mockResponse();
      await getEmployees(reqWith(ADMIN_A), res);
      const body = jsonBody(res) as any[];
      expect(body).toHaveLength(1);
      expect(body[0].name).toBe('Alice');
      expect(body.every((e) => e.companyId === 'companyA')).toBe(true);
    });
  });

  describe('create', () => {
    it('derives companyId from JWT even when body omits it', async () => {
      const db = makeDb({ employees: [] });
      (getDb as jest.Mock).mockReturnValue(db);
      const res = mockResponse();
      await createEmployee(
        reqWith(ADMIN_A, { empid: 'EMP001', name: 'New', email: 'n@a.com' }),
        res,
      );
      expect(statusCode(res)).toBe(201);
      expect(db._store.employees[0].companyId).toBe('companyA');
      expect(db._store.employees[0].role).toBe('employee');
    });

    it('rejects a mismatched body companyId (spoof)', async () => {
      const db = makeDb({ employees: [] });
      (getDb as jest.Mock).mockReturnValue(db);
      const res = mockResponse();
      await createEmployee(
        reqWith(ADMIN_A, {
          companyId: 'companyB',
          empid: 'X1',
          name: 'x',
          email: 'x@a.com',
        }),
        res,
      );
      expect(statusCode(res)).toBe(403);
      expect(db._store.employees).toHaveLength(0);
    });

    it('rejects duplicate empid inside the same company (409)', async () => {
      const db = makeDb(seedEmps());
      (getDb as jest.Mock).mockReturnValue(db);
      const res = mockResponse();
      await createEmployee(
        reqWith(ADMIN_A, { empid: 'EMP001', name: 'dup', email: 'dup@a.com' }),
        res,
      );
      expect(statusCode(res)).toBe(409);
    });

    it('allows the same empid in a different company', async () => {
      const db = makeDb(seedEmps());
      (getDb as jest.Mock).mockReturnValue(db);
      const res = mockResponse();
      await createEmployee(
        reqWith(ADMIN_B, { empid: 'EMP001', name: 'bob2', email: 'b2@b.com' }),
        res,
      );
      expect(statusCode(res)).toBe(201);
      const created = db._store.employees.find(
        (e) => e.companyId === 'companyB' && e.name === 'bob2',
      );
      expect(created).toBeTruthy();
    });

    it('ignores client-supplied role (always employee)', async () => {
      const db = makeDb({ employees: [] });
      (getDb as jest.Mock).mockReturnValue(db);
      const res = mockResponse();
      await createEmployee(
        reqWith(ADMIN_A, {
          empid: 'E2',
          name: 'x',
          email: 'x@a.com',
          role: 'admin',
        }),
        res,
      );
      expect(statusCode(res)).toBe(201);
      expect(db._store.employees[0].role).toBe('employee');
    });
  });

  describe('get by id (IDOR)', () => {
    it('returns own-company employee', async () => {
      const db = makeDb(seedEmps());
      (getDb as jest.Mock).mockReturnValue(db);
      const res = mockResponse();
      await getEmployeeById(reqWith(ADMIN_A, {}, { id: 'eA1' }), res);
      expect(statusCode(res)).toBe(200);
      expect(jsonBody(res).name).toBe('Alice');
    });

    it('blocks cross-company employee access (403)', async () => {
      const db = makeDb(seedEmps());
      (getDb as jest.Mock).mockReturnValue(db);
      const res = mockResponse();
      await getEmployeeById(reqWith(ADMIN_A, {}, { id: 'eB1' }), res);
      expect(statusCode(res)).toBe(403);
    });

    it('404 for nonexistent id', async () => {
      const db = makeDb(seedEmps());
      (getDb as jest.Mock).mockReturnValue(db);
      const res = mockResponse();
      await getEmployeeById(reqWith(ADMIN_A, {}, { id: 'nope' }), res);
      expect(statusCode(res)).toBe(404);
    });
  });

  describe('update', () => {
    it('updates allowed business fields', async () => {
      const db = makeDb(seedEmps());
      (getDb as jest.Mock).mockReturnValue(db);
      const res = mockResponse();
      await updateEmployee(
        reqWith(ADMIN_A, { name: 'Alice2', dept: 'HR' }, { id: 'eA1' }),
        res,
      );
      expect(statusCode(res)).toBe(200);
      const d = db._store.employees.find((e) => e.id === 'eA1');
      expect(d.name).toBe('Alice2');
      expect(d.dept).toBe('HR');
    });

    it.each([
      'companyId',
      'role',
      'password',
      'id',
      'createdAt',
      'createdBy',
    ])('rejects mass assignment of protected field: %s', async (field) => {
      const db = makeDb(seedEmps());
      (getDb as jest.Mock).mockReturnValue(db);
      const res = mockResponse();
      await updateEmployee(
        reqWith(ADMIN_A, { [field]: 'evil', name: 'ok' }, { id: 'eA1' }),
        res,
      );
      expect(statusCode(res)).toBe(400);
      const d = db._store.employees.find((e) => e.id === 'eA1');
      expect(d[field]).not.toBe('evil');
      expect(d.companyId).toBe('companyA');
    });

    it('blocks cross-company update (403)', async () => {
      const db = makeDb(seedEmps());
      (getDb as jest.Mock).mockReturnValue(db);
      const res = mockResponse();
      await updateEmployee(
        reqWith(ADMIN_A, { name: 'hacked' }, { id: 'eB1' }),
        res,
      );
      expect(statusCode(res)).toBe(403);
      expect(db._store.employees.find((e) => e.id === 'eB1').name).toBe('Bob');
    });

    it('rejects empid change that collides in-company (409)', async () => {
      const db = makeDb({
        employees: [
          ...seedEmps().employees,
          { id: 'eA2', companyId: 'companyA', empid: 'EMP002', name: 'A2', email: 'a2@a.com' },
        ],
      });
      (getDb as jest.Mock).mockReturnValue(db);
      const res = mockResponse();
      await updateEmployee(
        reqWith(ADMIN_A, { empid: 'EMP001' }, { id: 'eA2' }),
        res,
      );
      expect(statusCode(res)).toBe(409);
    });
  });

  describe('delete', () => {
    it('deletes own-company employee', async () => {
      const db = makeDb(seedEmps());
      (getDb as jest.Mock).mockReturnValue(db);
      const res = mockResponse();
      await deleteEmployee(reqWith(ADMIN_A, {}, { id: 'eA1' }), res);
      expect(statusCode(res)).toBe(200);
      expect(db._store.employees.find((e) => e.id === 'eA1')).toBeUndefined();
    });

    it('blocks cross-company delete (403)', async () => {
      const db = makeDb(seedEmps());
      (getDb as jest.Mock).mockReturnValue(db);
      const res = mockResponse();
      await deleteEmployee(reqWith(ADMIN_A, {}, { id: 'eB1' }), res);
      expect(statusCode(res)).toBe(403);
      expect(db._store.employees.find((e) => e.id === 'eB1')).toBeTruthy();
    });
  });

  describe('liveEmployeeDetails scoping', () => {
    it('does not leak another company’s employee record', async () => {
      const db = makeDb(seedEmps());
      (getDb as jest.Mock).mockReturnValue(db);
      const res = mockResponse();
      // EMP001 exists in companyB — requesting it as companyA admin must
      // not return Bob's record.
      await liveEmployeeDetails(
        reqWith(ADMIN_A, {}, { empid: 'EMP001' }),
        res,
      );
      const body = jsonBody(res);
      // own-company EMP001 (Alice) resolves; no cross-company data
      expect(body.data.name).toBe('Alice');
    });

    it('returns empty detail for an empid that only exists in another company', async () => {
      const db = makeDb({
        employees: [
          { id: 'eB1', companyId: 'companyB', empid: 'ONLYB', name: 'Bob' },
        ],
      });
      (getDb as jest.Mock).mockReturnValue(db);
      const res = mockResponse();
      await liveEmployeeDetails(
        reqWith(ADMIN_A, {}, { empid: 'ONLYB' }),
        res,
      );
      const body = jsonBody(res);
      expect(body.data.name).toBe('-');
      expect(body.data.status).toBe('Absent');
    });
  });
});
