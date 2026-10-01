/// <reference types="jest" />
/**
 * Employee Auth provisioning tests.
 *
 * Covers: automatic Firebase Auth creation on POST /employees, authUid
 * persisted on the employee row, companyId always from JWT, email-exists
 * conflict rules, Auth→Firestore rollback, first-login users/{uid}
 * auto-provisioning from the trusted employee record, idempotent repeat
 * logins, existing-doc reuse without overwrite, cross-company conflict
 * rejection, ambiguous email rejection, deactivated-employee blocking,
 * and legacy employees (bcrypt password, no authUid) still working.
 */

import request from 'supertest';

process.env.JWT_SECRET = 'test-jwt-secret-emp-auth';
process.env.APP_FIREBASE_WEB_API_KEY = 'AIzaTESTKEY0000000000';

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

jest.mock('./services/usageService', () => ({
  trackUsage: jest.fn().mockResolvedValue(undefined),
}));

jest.mock('./services/passwordService', () => ({
  rotatePassword: jest.fn().mockResolvedValue(undefined),
}));

// eslint-disable-next-line import/first
import app from './app';
// eslint-disable-next-line import/first
import { issueToken } from './common/auth.utils';

const adminToken = (companyId = 'c1') =>
  issueToken({
    userId: 'admin-1',
    email: 'admin@org.test',
    role: 'admin',
    empid: 'ADM1',
    companyId,
  });

type Doc = { id?: string; [k: string]: any };

/** Minimal condition-aware Firestore fake. */
function installDb(seed: {
  employees?: Doc[];
  users?: Doc[];
  profile?: any;
  profileId?: string;
}) {
  const store: Record<string, Doc[]> = {
    employees: [...(seed.employees || [])],
    users: [...(seed.users || [])],
    companyProfile: seed.profile
      ? [{ id: seed.profileId || 'c1', ...seed.profile }]
      : [],
  };

  const applyConds = (rows: Doc[], conds: any[]) =>
    rows.filter((d) =>
      conds.every(([f, op, val]) => {
        if (op === '==') return d[f] === val;
        return true;
      }),
    );

  const docSnap = (name: string, d: Doc | undefined, id: string): any => ({
    exists: !!d,
    id,
    data: () => d,
    get: (f: string) => d?.[f],
    ref: {
      set: jest.fn(async (u: any) => {
        if (d) Object.assign(d, u);
      }),
      update: jest.fn(async (u: any) => {
        if (d) Object.assign(d, u);
      }),
      delete: jest.fn(async () => {}),
    },
  });

  const snapOf = (name: string, docs: Doc[]) => ({
    empty: docs.length === 0,
    size: docs.length,
    docs: docs.map((d) => docSnap(name, d, d.id || 'x')),
  });

  const collection = (name: string): any => {
    const mkQuery = (conds: any[]): any => ({
      where: (f: string, op: string, v: any) => mkQuery([...conds, [f, op, v]]),
      limit: () => mkQuery(conds),
      orderBy: () => mkQuery(conds),
      get: async () => snapOf(name, applyConds(store[name] || [], conds)),
    });
    return {
      where: (f: string, op: string, v: any) => mkQuery([[f, op, v]]),
      get: async () => snapOf(name, store[name] || []),
      doc: (id: string) => ({
        get: async () =>
          docSnap(name, (store[name] || []).find((x) => x.id === id), id),
        set: jest.fn(async (data: any, opts?: any) => {
          const ex = (store[name] || []).find((x) => x.id === id);
          if (ex && opts?.merge) Object.assign(ex, data);
          else if (ex) (store[name] ||= []).splice(store[name].indexOf(ex), 1, { id, ...data });
          else (store[name] ||= []).push({ id, ...data });
        }),
        update: jest.fn(async (u: any) => {
          const d = (store[name] || []).find((x) => x.id === id);
          if (d) Object.assign(d, u);
        }),
        delete: jest.fn(async () => {
          store[name] = (store[name] || []).filter((x) => x.id !== id);
        }),
      }),
      add: jest.fn(async (data: any) => {
        const id = `auto-${(store[name] || []).length + 1}`;
        const d = { id, ...data };
        (store[name] ||= []).push(d);
        return { id, get: async () => docSnap(name, d, id) };
      }),
    };
  };

  mockFirebaseState.getDb.mockReturnValue({
    collection: jest.fn(collection),
    getAll: jest.fn().mockResolvedValue([]),
    batch: jest.fn().mockReturnValue({
      set: jest.fn(),
      commit: jest.fn().mockResolvedValue(undefined),
    }),
  });

  return { store };
}

const ADMIN_PROFILE = {
  status: 'active',
  enabledFeatures: ['attendance', 'employee_master', 'feedback', 'shifts'],
};

const authStub = (over: any = {}) => ({
  getUserByEmail: jest
    .fn()
    .mockRejectedValue({ code: 'auth/user-not-found' }),
  createUser: jest.fn().mockResolvedValue({ uid: 'fb-uid-new' }),
  updateUser: jest.fn().mockResolvedValue(undefined),
  deleteUser: jest.fn().mockResolvedValue(undefined),
  ...over,
});

let fetchMock: jest.Mock;

const firebaseSignIn = (uid: string) => ({
  ok: true,
  json: async () => ({ idToken: 'tok', localId: uid }),
});

const firebaseFail = () => ({ ok: false, text: async () => 'bad' });

const empBody = (over: any = {}) => ({
  empid: 'EMP001',
  name: 'New Hire',
  email: 'hire@org.test',
  password: 'secret123',
  ...over,
});

describe('employee Auth provisioning + first-login users doc', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockFirebaseState.getAdminAuth.mockReturnValue(authStub());
    fetchMock = jest.fn();
    (globalThis as any).fetch = fetchMock;
    fetchMock.mockResolvedValue(firebaseSignIn('fb-uid-new') as any);
  });

  /* ─────────────── Admin creates employee ─────────────── */

  test('create → Auth user created and authUid stored on employee', async () => {
    const auth = authStub();
    mockFirebaseState.getAdminAuth.mockReturnValue(auth);
    const { store } = installDb({ profile: ADMIN_PROFILE });

    const res = await request(app)
      .post('/api/employees')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send(empBody());

    expect(res.status).toBe(201);
    expect(auth.createUser).toHaveBeenCalledWith(
      expect.objectContaining({
        email: 'hire@org.test',
        password: 'secret123',
        displayName: 'New Hire',
      }),
    );
    const emp = store.employees.find((e) => e.email === 'hire@org.test');
    expect(emp?.authUid).toBe('fb-uid-new');
    // no password material ever stored on the employees doc
    expect(emp?.password).toBeUndefined();
    expect(res.body.temporaryPassword).toBeUndefined();
  });

  test('create without password → generated temporaryPassword returned once', async () => {
    const auth = authStub();
    mockFirebaseState.getAdminAuth.mockReturnValue(auth);
    const { store } = installDb({ profile: ADMIN_PROFILE });

    const res = await request(app)
      .post('/api/employees')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send(empBody({ password: undefined }));

    expect(res.status).toBe(201);
    expect(res.body.temporaryPassword).toMatch(/^Tmp-/);
    const emp = store.employees[0];
    expect(emp?.password).toBeUndefined();
    expect(auth.createUser).toHaveBeenCalled();
  });

  test('password < 6 chars → 400, no Auth user created', async () => {
    const auth = authStub();
    mockFirebaseState.getAdminAuth.mockReturnValue(auth);
    installDb({ profile: ADMIN_PROFILE });

    const res = await request(app)
      .post('/api/employees')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send(empBody({ password: 'abc' }));

    expect(res.status).toBe(400);
    expect(auth.createUser).not.toHaveBeenCalled();
  });

  test('create → companyId comes from JWT, never body', async () => {
    installDb({ profile: ADMIN_PROFILE });

    const res = await request(app)
      .post('/api/employees')
      .set('Authorization', `Bearer ${adminToken('c1')}`)
      .send(empBody({ companyId: 'other-co' }));

    expect(res.status).toBe(403);
    expect(res.body.error).toBe('Invalid companyId');
  });

  test('Auth email exists claimed by another company → 409, no employee written', async () => {
    const auth = authStub({
      getUserByEmail: jest.fn().mockResolvedValue({ uid: 'fb-foreign' }),
    });
    mockFirebaseState.getAdminAuth.mockReturnValue(auth);
    const { store } = installDb({
      profile: ADMIN_PROFILE,
      users: [
        {
          id: 'u-foreign',
          emailLower: 'hire@org.test',
          companyId: 'c2',
          role: 'employee',
        },
      ],
    });

    const res = await request(app)
      .post('/api/employees')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send(empBody());

    expect(res.status).toBe(409);
    expect(res.body.error).toBe('Email is already in use by another account');
    expect(store.employees).toHaveLength(0);
    expect(auth.createUser).not.toHaveBeenCalled();
  });

  test('Auth email exists unclaimed → reused with password update', async () => {
    const auth = authStub({
      getUserByEmail: jest.fn().mockResolvedValue({ uid: 'fb-orphan' }),
    });
    mockFirebaseState.getAdminAuth.mockReturnValue(auth);
    const { store } = installDb({ profile: ADMIN_PROFILE });

    const res = await request(app)
      .post('/api/employees')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send(empBody());

    expect(res.status).toBe(201);
    expect(auth.createUser).not.toHaveBeenCalled();
    expect(auth.updateUser).toHaveBeenCalledWith(
      'fb-orphan',
      expect.objectContaining({ password: 'secret123' }),
    );
    expect(store.employees[0]?.authUid).toBe('fb-orphan');
  });

  test('employee write fails after Auth create → new Auth user rolled back', async () => {
    const auth = authStub();
    mockFirebaseState.getAdminAuth.mockReturnValue(auth);
    const { store } = installDb({ profile: ADMIN_PROFILE });
    // force add() failure
    (store as any); // store available for assertions
    mockFirebaseState.getDb.mockReturnValue({
      collection: jest.fn((name: string) => {
        if (name === 'companyProfile') {
          return {
            doc: jest.fn(() => ({
              get: jest.fn(async () => ({
                exists: true,
                data: () => ADMIN_PROFILE,
              })),
            })),
          };
        }
        return {
          where: jest.fn().mockReturnThis(),
          limit: jest.fn().mockReturnThis(),
          get: jest.fn(async () => ({ empty: true, size: 0, docs: [] })),
          add: jest.fn().mockRejectedValue(new Error('write failed')),
        };
      }),
      getAll: jest.fn().mockResolvedValue([]),
    });

    const res = await request(app)
      .post('/api/employees')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send(empBody());

    expect(res.status).toBe(500);
    expect(auth.deleteUser).toHaveBeenCalledWith('fb-uid-new');
  });

  /* ─────────────── First login → users/{uid} ─────────────── */

  test('first login → users/{uid} created from trusted employee record', async () => {
    const { store } = installDb({
      employees: [
        {
          id: 'e1',
          empid: 'EMP001',
          name: 'Hire One',
          email: 'hire@org.test',
          emailLower: 'hire@org.test',
          companyId: 'c1',
          status: 'active',
          authUid: 'fb-uid-new',
        },
      ],
    });
    fetchMock.mockResolvedValue(firebaseSignIn('fb-uid-new') as any);

    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'hire@org.test', password: 'secret123', role: 'admin', companyId: 'evil' });

    expect(res.status).toBe(200);
    const user = store.users.find((u) => u.id === 'fb-uid-new');
    expect(user).toBeTruthy();
    expect(user?.role).toBe('employee'); // never client-supplied
    expect(user?.companyId).toBe('c1'); // from employee record
    expect(user?.empid).toBe('EMP001'); // from employee record
    expect(user?.authUid).toBe('fb-uid-new');
    expect(user?.authSource).toBe('firebase');
  });

  test('repeat login → existing users/{uid} reused, no duplicate', async () => {
    const { store } = installDb({
      employees: [
        {
          id: 'e1',
          empid: 'EMP001',
          name: 'Hire',
          email: 'hire@org.test',
          companyId: 'c1',
          status: 'active',
          authUid: 'fb-uid-new',
        },
      ],
      users: [
        {
          id: 'fb-uid-new',
          email: 'hire@org.test',
          emailLower: 'hire@org.test',
          companyId: 'c1',
          role: 'employee',
          status: 'active',
          empid: 'EMP001',
        },
      ],
    });
    fetchMock.mockResolvedValue(firebaseSignIn('fb-uid-new') as any);

    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'hire@org.test', password: 'secret123' });

    expect(res.status).toBe(200);
    expect(store.users.filter((u) => u.emailLower === 'hire@org.test')).toHaveLength(1);
  });

  test('existing users doc by email (auto-id) → reused, companyId unchanged', async () => {
    const { store } = installDb({
      employees: [
        {
          id: 'e1',
          empid: 'EMP001',
          email: 'hire@org.test',
          companyId: 'c1',
          status: 'active',
          authUid: 'fb-uid-new',
        },
      ],
      users: [
        {
          id: 'u-auto-1',
          emailLower: 'hire@org.test',
          companyId: 'c1',
          role: 'employee',
          status: 'active',
          empid: 'EMP001',
        },
      ],
    });
    fetchMock.mockResolvedValue(firebaseSignIn('fb-uid-new') as any);

    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'hire@org.test', password: 'secret123' });

    expect(res.status).toBe(200);
    expect(res.body.uid).toBe('u-auto-1');
    expect(store.users).toHaveLength(1);
    expect(store.users[0].companyId).toBe('c1');
  });

  test('users/{uid} belonging to a different company → 403, not overwritten', async () => {
    // The uid-keyed users doc is not found by the login email lookup (it
    // records a different email), so the employees fallback reaches the
    // uid check — which must refuse to reuse a foreign-tenant account.
    const { store } = installDb({
      employees: [
        {
          id: 'e1',
          empid: 'EMP001',
          email: 'hire@org.test',
          companyId: 'c1',
          status: 'active',
          authUid: 'fb-uid-new',
        },
      ],
      users: [
        {
          id: 'fb-uid-new',
          emailLower: 'other@org.test',
          companyId: 'c2',
          role: 'employee',
        },
      ],
    });
    fetchMock.mockResolvedValue(firebaseSignIn('fb-uid-new') as any);

    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'hire@org.test', password: 'secret123' });

    expect(res.status).toBe(403);
    expect(res.body.error).toMatch(/different organization/i);
    expect(store.users[0].companyId).toBe('c2');
  });

  test('deactivated employee → login blocked, no users doc created', async () => {
    const { store } = installDb({
      employees: [
        {
          id: 'e1',
          empid: 'EMP001',
          email: 'hire@org.test',
          companyId: 'c1',
          status: 'inactive',
          authUid: 'fb-uid-new',
        },
      ],
    });
    fetchMock.mockResolvedValue(firebaseSignIn('fb-uid-new') as any);

    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'hire@org.test', password: 'secret123' });

    expect(res.status).toBe(403);
    expect(res.body.error).toBe('Account is not active');
    expect(store.users).toHaveLength(0);
  });

  test('ambiguous email across companies without authUid match → 403', async () => {
    installDb({
      employees: [
        {
          id: 'e1',
          empid: 'E1',
          email: 'dup@org.test',
          emailLower: 'dup@org.test',
          companyId: 'c1',
          status: 'active',
          authUid: 'fb-other',
        },
        {
          id: 'e2',
          empid: 'E2',
          email: 'dup@org.test',
          emailLower: 'dup@org.test',
          companyId: 'c2',
          status: 'active',
          authUid: 'fb-other2',
        },
      ],
    });
    fetchMock.mockResolvedValue(firebaseSignIn('fb-uid-unmatched') as any);

    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'dup@org.test', password: 'secret123' });

    expect(res.status).toBe(403);
    expect(res.body.error).toMatch(/ambiguous/i);
  });

  test('ambiguous email resolved by matching authUid → correct company', async () => {
    const { store } = installDb({
      employees: [
        {
          id: 'e1',
          empid: 'E1',
          email: 'dup@org.test',
          emailLower: 'dup@org.test',
          companyId: 'c1',
          status: 'active',
        },
        {
          id: 'e2',
          empid: 'E2',
          email: 'dup@org.test',
          emailLower: 'dup@org.test',
          companyId: 'c2',
          status: 'active',
          authUid: 'fb-uid-c2',
        },
      ],
    });
    fetchMock.mockResolvedValue(firebaseSignIn('fb-uid-c2') as any);

    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'dup@org.test', password: 'secret123' });

    expect(res.status).toBe(200);
    expect(res.body.companyId).toBe('c2');
    expect(res.body.user.companyId).toBe('c2');
    const user = store.users.find((u) => u.id === 'fb-uid-c2');
    expect(user?.companyId).toBe('c2');
    expect(user?.empid).toBe('E2');
  });

  test('legacy employee (bcrypt password, no authUid, no Auth account) still logs in', async () => {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const bcrypt = require('bcryptjs');
    const hash = bcrypt.hashSync('oldpass1', 4);
    const { store } = installDb({
      employees: [
        {
          id: 'e1',
          empid: 'OLD1',
          email: 'old@org.test',
          companyId: 'c1',
          status: 'active',
          password: hash,
        },
      ],
    });
    fetchMock.mockResolvedValue(firebaseFail() as any);

    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'old@org.test', password: 'oldpass1' });

    expect(res.status).toBe(200);
    expect(res.body.companyId).toBe('c1');
    const user = store.users.find((u) => u.emailLower === 'old@org.test');
    expect(user).toBeTruthy();
    expect(user?.role).toBe('employee');
    expect(user?.authSource).toBe('local');
    expect(user?.authUid).toBeUndefined();
  });

  test('legacy employee without authUid → authUid attached on proven login', async () => {
    const { store } = installDb({
      employees: [
        {
          id: 'e1',
          empid: 'LEG1',
          email: 'leg@org.test',
          companyId: 'c1',
          status: 'active',
        },
      ],
    });
    fetchMock.mockResolvedValue(firebaseSignIn('fb-uid-leg') as any);

    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'leg@org.test', password: 'secret123' });

    expect(res.status).toBe(200);
    expect(store.employees[0].authUid).toBe('fb-uid-leg');
  });

  test('login for unknown employee/Auth identity → 401', async () => {
    installDb({ employees: [] });
    fetchMock.mockResolvedValue(firebaseFail() as any);

    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'ghost@org.test', password: 'nope' });

    expect(res.status).toBe(401);
  });
});
