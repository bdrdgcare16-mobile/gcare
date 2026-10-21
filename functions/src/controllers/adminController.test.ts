/**
 * Tests for the Company Admin → "HR user" creation workflow and related
 * tenant-admin account management (adminController + the privileged-user
 * branch of authController).
 *
 * Contract under test:
 *  - POST /api/admin/hr-users stores role 'admin' + displayRole 'hr'
 *    (the "HR" label is a non-authoritative display classification).
 *  - GET /api/admin/hr-users lists legacy 'hr' accounts AND 'admin'
 *    accounts carrying displayRole 'hr' — never unrelated admin accounts.
 *  - update/deactivate apply to both stored shapes, company-scoped.
 *  - promoteToAdmin is company-scoped and cannot rewrite privileged roles.
 *  - createPrivilegedUser cannot mint super_admin.
 */
// Explicit imports keep IDE type resolution working even when the
// language server doesn't pick up tsconfig's "types": ["jest"] globals.
import { describe, it, expect, beforeEach, jest } from '@jest/globals';

import * as ctrl from './adminController';
import * as authCtrl from './authController';

// ---- Fake Firestore ------------------------------------------------------

type Row = Record<string, any> & { _id: string };
type Filter = { field: string; value: any };

const usersCol: Row[] = [];

function snap(d: Row): any {
  return {
    id: d._id,
    exists: true,
    data: () => d,
    ref: {
      update: jest.fn(async (u: any) => {
        Object.assign(d, u);
      }),
      set: jest.fn(async (u: any, opts?: any) => {
        if (opts?.merge) Object.assign(d, u);
        else Object.keys(d).forEach((k) => k !== '_id' && delete d[k]);
        if (!opts?.merge) Object.assign(d, u);
      }),
      get: async () => snap(d),
    },
  };
}

function makeQuery(all: Row[], filters: Filter[] = [], lim?: number): any {
  return {
    where: (f: string, op: string, v: any) => {
      if (op === '==') return makeQuery(all, [...filters, { field: f, value: v }], lim);
      // 'in' and other ops not needed by the code under test
      return makeQuery(all, [...filters, { field: f, value: v }], lim);
    },
    limit: (n: number) => makeQuery(all, filters, n),
    get: async () => {
      let out = all.filter((r) => filters.every((f) => r[f.field] === f.value));
      if (lim) out = out.slice(0, lim);
      return {
        empty: out.length === 0,
        size: out.length,
        docs: out.map((d) => snap(d)),
      };
    },
  };
}

const db = {
  collection: (name: string) => {
    const rows = name === 'users' ? usersCol : [];
    return {
      where: (f: string, op: string, v: any) => makeQuery(rows, [{ field: f, value: v }]),
      doc: (id: string) => ({
        get: async () => {
          const d = usersCol.find((r) => r._id === id);
          return d
            ? snap(d)
            : { exists: false, id, data: () => undefined };
        },
        set: jest.fn(async (data: any) => {
          const existing = usersCol.find((r) => r._id === id);
          if (existing) Object.assign(existing, data);
          else usersCol.push({ ...data, _id: id });
        }),
        update: jest.fn(async (u: any) => {
          const d = usersCol.find((r) => r._id === id);
          if (d) Object.assign(d, u);
        }),
      }),
      add: jest.fn(async (data: any) => {
        const id = `added-${usersCol.length}`;
        usersCol.push({ ...data, _id: id });
        return { id };
      }),
    };
  },
};

// ---- Mocks ---------------------------------------------------------------

jest.mock('../config/firebase', () => ({
  db: {
    collection: (name: string) => (db as any).collection(name),
  },
  auth: {
    createUser: jest.fn(async ({ email }: any) => ({
      uid: `fb-${email}`,
    })),
    getUserByEmail: jest.fn(async (email: string) => ({ uid: `fb-${email}` })),
    updateUser: jest.fn(async () => ({})),
  },
}));

jest.mock('../services/usageService', () => ({
  trackUsage: jest.fn(async () => {}),
}));

let limitResult = {
  lookupFailed: false,
  companyExists: true,
  allowed: true,
  companyStatus: 'active' as string,
};

jest.mock('../services/entitlementService', () => ({
  checkUserLimit: jest.fn(async () => limitResult),
  getCompanyEntitlement: jest.fn(async () => ({
    exists: true,
    status: 'active',
    enabledFeatures: null,
    maxUsers: null,
  })),
}));

jest.mock('../services/passwordService', () => ({
  rotatePassword: jest.fn(async () => {}),
}));

// ---- Helpers -------------------------------------------------------------

function mkReq(over: any = {}): any {
  return { body: {}, query: {}, params: {}, ...over };
}

function mkRes() {
  const res: any = {
    statusCode: 0,
    body: null,
    status(c: number) {
      this.statusCode = c;
      return this;
    },
    json(b: any) {
      if (!this.statusCode) this.statusCode = 200;
      this.body = b;
      return this;
    },
  };
  return res;
}

const CA = { userId: 'ca-1', role: 'company_admin', companyId: 'C1' };
const CA_B = { userId: 'ca-b', role: 'company_admin', companyId: 'C2' };
const ADMIN = { userId: 'a-1', role: 'admin', companyId: 'C1' };

function seedUsers() {
  usersCol.length = 0;
  usersCol.push(
    { _id: 'u-legacy-hr', role: 'hr', companyId: 'C1', email: 'legacy@x.com', emailLower: 'legacy@x.com', name: 'Legacy HR', branch: 'B1', department: 'D1', status: 'active' },
    { _id: 'u-flagged-admin', role: 'admin', displayRole: 'hr', companyId: 'C1', email: 'flagged@x.com', emailLower: 'flagged@x.com', name: 'Flagged Admin', branch: 'B2', department: 'D2', status: 'active', firebaseUid: 'fb-flagged' },
    { _id: 'u-plain-admin', role: 'admin', companyId: 'C1', email: 'plain@x.com', emailLower: 'plain@x.com', name: 'Plain Admin', status: 'active' },
    { _id: 'u-emp', role: 'employee', companyId: 'C1', email: 'emp@x.com', emailLower: 'emp@x.com', name: 'Emp', status: 'active' },
    { _id: 'u-ca', role: 'company_admin', companyId: 'C1', email: 'ca@x.com', emailLower: 'ca@x.com', name: 'CA', status: 'active' },
    { _id: 'u-other-co', role: 'admin', displayRole: 'hr', companyId: 'C2', email: 'other@x.com', emailLower: 'other@x.com', name: 'Other Co', status: 'active' },
  );
}

beforeEach(() => {
  seedUsers();
  limitResult = { lookupFailed: false, companyExists: true, allowed: true, companyStatus: 'active' };
});

// ---- createHrUser --------------------------------------------------------

describe('createHrUser', () => {
  it('company_admin creates an account stored as role admin + displayRole hr', async () => {
    const res = mkRes();
    await ctrl.createHrUser(
      mkReq({
        user: CA,
        body: { name: 'New HR', email: 'new@x.com', branch: 'B', department: 'D', password: 'Secret@123' },
      }),
      res,
    );
    expect(res.statusCode).toBe(201);
    expect(res.body.hrUser.role).toBe('admin');
    expect(res.body.hrUser.displayRole).toBe('hr');
    expect(res.body.hrUser.companyId).toBe('C1');
    const stored = usersCol.find((r) => r.email === 'new@x.com');
    expect(stored?.role).toBe('admin');
    expect(stored?.displayRole).toBe('hr');
  });

  it('ignores body companyId — account lands in the caller company', async () => {
    const res = mkRes();
    await ctrl.createHrUser(
      mkReq({
        user: CA_B,
        body: { name: 'H', email: 'cb@x.com', branch: 'B', department: 'D', password: 'Secret@123', companyId: 'C1' },
      }),
      res,
    );
    expect(res.statusCode).toBe(201);
    expect(res.body.hrUser.companyId).toBe('C2');
  });

  it('admin callers can also create through the same workflow', async () => {
    const res = mkRes();
    await ctrl.createHrUser(
      mkReq({
        user: ADMIN,
        body: { name: 'N', email: 'byadmin@x.com', branch: 'B', department: 'D', password: 'Secret@123' },
      }),
      res,
    );
    expect(res.statusCode).toBe(201);
    expect(res.body.hrUser.role).toBe('admin');
  });

  it('rejects callers with no company context', async () => {
    const res = mkRes();
    await ctrl.createHrUser(
      mkReq({ user: { userId: 'x', role: 'company_admin' }, body: { name: 'N', email: 'e@x.com', branch: 'B', department: 'D' } }),
      res,
    );
    expect(res.statusCode).toBe(403);
  });

  it('fails closed when the company is over its user limit', async () => {
    limitResult = { lookupFailed: false, companyExists: true, allowed: false, companyStatus: 'active' };
    const res = mkRes();
    await ctrl.createHrUser(
      mkReq({ user: CA, body: { name: 'N', email: 'lim@x.com', branch: 'B', department: 'D' } }),
      res,
    );
    expect(res.statusCode).toBe(403);
  });

  it('rejects duplicate emails', async () => {
    const res = mkRes();
    await ctrl.createHrUser(
      mkReq({ user: CA, body: { name: 'N', email: 'plain@x.com', branch: 'B', department: 'D' } }),
      res,
    );
    expect(res.statusCode).toBe(409);
  });
});

// ---- listHrUsers ---------------------------------------------------------

describe('listHrUsers', () => {
  it('returns legacy hr + displayRole-flagged admins, excluding plain admins', async () => {
    const res = mkRes();
    await ctrl.listHrUsers(mkReq({ user: CA }), res);
    expect(res.statusCode).toBe(200);
    const ids = (res.body.hrUsers as any[]).map((u) => u.id);
    expect(ids).toContain('u-legacy-hr');
    expect(ids).toContain('u-flagged-admin');
    expect(ids).not.toContain('u-plain-admin');
    expect(ids).not.toContain('u-emp');
    expect(ids).not.toContain('u-ca');
    expect(ids).not.toContain('u-other-co');
  });

  it('is scoped to the caller company only', async () => {
    const res = mkRes();
    await ctrl.listHrUsers(mkReq({ user: CA_B, query: { companyId: 'C1' } }), res);
    expect(res.statusCode).toBe(200);
    const ids = (res.body.hrUsers as any[]).map((u) => u.id);
    expect(ids).toEqual(['u-other-co']);
  });

  it('denies callers without a company context', async () => {
    const res = mkRes();
    await ctrl.listHrUsers(mkReq({ user: { userId: 'x', role: 'company_admin' } }), res);
    expect(res.statusCode).toBe(403);
  });
});

// ---- update / deactivate -------------------------------------------------

describe('updateHrUser', () => {
  it('updates a displayRole-flagged admin account', async () => {
    const res = mkRes();
    await ctrl.updateHrUser(
      mkReq({ user: CA, params: { userId: 'u-flagged-admin' }, body: { name: 'Renamed', status: 'inactive' } }),
      res,
    );
    expect(res.statusCode).toBe(200);
    expect(usersCol.find((r) => r._id === 'u-flagged-admin')?.name).toBe('Renamed');
  });

  it('updates a legacy hr account', async () => {
    const res = mkRes();
    await ctrl.updateHrUser(
      mkReq({ user: CA, params: { userId: 'u-legacy-hr' }, body: { branch: 'B9' } }),
      res,
    );
    expect(res.statusCode).toBe(200);
    expect(usersCol.find((r) => r._id === 'u-legacy-hr')?.branch).toBe('B9');
  });

  it('refuses to manage a plain admin account', async () => {
    const res = mkRes();
    await ctrl.updateHrUser(
      mkReq({ user: CA, params: { userId: 'u-plain-admin' }, body: { name: 'Nope' } }),
      res,
    );
    expect(res.statusCode).toBe(404);
  });

  it('denies cross-company management', async () => {
    const res = mkRes();
    await ctrl.updateHrUser(
      mkReq({ user: CA, params: { userId: 'u-other-co' }, body: { name: 'Hijack' } }),
      res,
    );
    expect(res.statusCode).toBe(403);
    expect(usersCol.find((r) => r._id === 'u-other-co')?.name).toBe('Other Co');
  });

  it('cannot rewrite role via mass assignment', async () => {
    const res = mkRes();
    await ctrl.updateHrUser(
      mkReq({ user: CA, params: { userId: 'u-flagged-admin' }, body: { role: 'platform_admin', name: 'Still HR' } }),
      res,
    );
    expect(res.statusCode).toBe(200);
    const u = usersCol.find((r) => r._id === 'u-flagged-admin');
    expect(u?.role).toBe('admin');
    expect(u?.displayRole).toBe('hr');
  });
});

describe('deactivateHrUser', () => {
  it('deactivates a flagged admin account', async () => {
    const res = mkRes();
    await ctrl.deactivateHrUser(mkReq({ user: CA, params: { userId: 'u-flagged-admin' } }), res);
    expect(res.statusCode).toBe(200);
    expect(usersCol.find((r) => r._id === 'u-flagged-admin')?.status).toBe('inactive');
  });

  it('denies cross-company deactivation', async () => {
    const res = mkRes();
    await ctrl.deactivateHrUser(mkReq({ user: CA, params: { userId: 'u-other-co' } }), res);
    expect(res.statusCode).toBe(403);
    expect(usersCol.find((r) => r._id === 'u-other-co')?.status).toBe('active');
  });
});

// ---- promoteToAdmin ------------------------------------------------------

describe('promoteToAdmin', () => {
  it('promotes a same-company employee', async () => {
    const res = mkRes();
    await ctrl.promoteToAdmin(mkReq({ user: ADMIN, body: { email: 'emp@x.com' } }), res);
    expect(res.statusCode).toBe(200);
    expect(usersCol.find((r) => r._id === 'u-emp')?.role).toBe('admin');
  });

  it('cannot reach another company — cross-tenant promote is denied', async () => {
    const res = mkRes();
    await ctrl.promoteToAdmin(mkReq({ user: ADMIN, body: { email: 'other@x.com' } }), res);
    expect(res.statusCode).toBe(404);
    expect(usersCol.find((r) => r._id === 'u-other-co')?.role).toBe('admin'); // unchanged (was admin already)
  });

  it('refuses to rewrite a company_admin role', async () => {
    const res = mkRes();
    await ctrl.promoteToAdmin(mkReq({ user: ADMIN, body: { email: 'ca@x.com' } }), res);
    expect(res.statusCode).toBe(403);
    expect(usersCol.find((r) => r._id === 'u-ca')?.role).toBe('company_admin');
  });

  it('requires a company context on the caller token', async () => {
    const res = mkRes();
    await ctrl.promoteToAdmin(mkReq({ user: { userId: 'x', role: 'admin' }, body: { email: 'emp@x.com' } }), res);
    expect(res.statusCode).toBe(403);
  });
});

// ---- createPrivilegedUser (authController) -------------------------------

describe('createPrivilegedUser', () => {
  const base = { name: 'P', email: 'priv@x.com', password: 'Secret@123', companyId: 'C1' };

  it('cannot create super_admin — privilege escalation blocked', async () => {
    const res = mkRes();
    await authCtrl.createPrivilegedUser(
      mkReq({ user: ADMIN, body: { ...base, role: 'super_admin' } }),
      res,
    );
    expect(res.statusCode).toBe(400);
    expect(usersCol.find((r) => r.email === 'priv@x.com')).toBeUndefined();
  });

  it('cannot create platform_admin or company_admin', async () => {
    for (const role of ['platform_admin', 'company_admin']) {
      const res = mkRes();
      await authCtrl.createPrivilegedUser(
        mkReq({ user: ADMIN, body: { ...base, email: `${role}@x.com`, role } }),
        res,
      );
      expect(res.statusCode).toBe(400);
    }
  });

  it('admin can still create a same-company admin', async () => {
    const res = mkRes();
    await authCtrl.createPrivilegedUser(
      mkReq({ user: ADMIN, body: { ...base, role: 'admin' } }),
      res,
    );
    expect(res.statusCode).toBe(200);
    expect(usersCol.find((r) => r.email === 'priv@x.com')?.role).toBe('admin');
  });

  it('company mismatch is denied', async () => {
    const res = mkRes();
    await authCtrl.createPrivilegedUser(
      mkReq({ user: ADMIN, body: { ...base, companyId: 'C2', role: 'admin' } }),
      res,
    );
    expect(res.statusCode).toBe(403);
  });
});
