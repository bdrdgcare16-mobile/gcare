// Regression tests for the Onboarding V2 approval workflow:
//   POST /           -> ['admin','hr'] + hrFeatureGate('onboarding')
//   GET /, GET /:id, PATCH /:id/status, documents/resolve-url
//                    -> ['company_admin'] only
//   approve          -> provisionEmployeeFromOnboarding (dup checks,
//                       idempotent retry, companyId scoping)

const mockStore: Record<string, any> = {};

// Chainable query mock honoring simple where() equality filters.
function makeQuery(colName: string) {
  const filters: [string, any][] = [];
  const q: any = {
    where: (f: string, _op: string, v: any) => {
      filters.push([f, v]);
      return q;
    },
    limit: () => q,
    get: async () => {
      const docs = Object.entries(mockStore)
        .filter(([k]) => k.startsWith(colName + '/'))
        .filter(([, d]) =>
          filters.every(([f, v]) => {
            const parts = f.split('.');
            let cur: any = d;
            for (const p of parts) cur = cur?.[p];
            return cur === v;
          })
        )
        .map(([k, d]) => ({ id: k.split('/')[1], data: () => d, ref: { id: k.split('/')[1] } }));
      return { empty: docs.length === 0, docs, size: docs.length };
    },
  };
  return q;
}

const batchSets: { path: string; data: any; merge: boolean }[] = [];
const docSets: { path: string; data: any }[] = [];
const mockCreateUser = jest.fn(async (_args: any) => ({ uid: 'fb-uid-1' }));
const mockGetUserByEmail = jest.fn(async (_email: string) => ({ uid: 'fb-existing' }));

jest.mock('../config/firebase', () => ({
  db: {
    collection: (name: string) => ({
      doc: (id?: string) => ({
        id: id ?? 'auto-id',
        get: async () => {
          const d = mockStore[`${name}/${id}`];
          return { exists: !!d, id, data: () => d };
        },
        set: async (data: any, _opts?: any) => {
          docSets.push({ path: `${name}/${id}`, data });
        },
        update: async (data: any) => {
          docSets.push({ path: `${name}/${id}`, data });
        },
      }),
      where: (f: string, op: string, v: any) => makeQuery(name).where(f, op, v),
    }),
    batch: () => ({
      set: (ref: any, data: any, opts?: any) => {
        batchSets.push({ path: ref._path ?? 'unknown', data, merge: !!opts?.merge });
      },
      commit: async () => {},
    }),
    runTransaction: async (fn: any) => fn({}),
  },
  auth: {
    createUser: (args: any) => mockCreateUser(args),
    getUserByEmail: (email: string) => mockGetUserByEmail(email),
    updateUser: async () => ({}),
  },
}));

jest.mock('../services/entitlementService', () => ({
  checkUserLimit: async () => ({
    allowed: true,
    maxUsers: 100,
    currentUsers: 1,
    companyStatus: 'active',
    companyExists: true,
    lookupFailed: false,
  }),
}));

import { roleMiddleware } from '../middlewares/authMiddleware';
import { hrFeatureGate } from '../middlewares/hrFeatureMiddleware';
import { provisionEmployeeFromOnboarding, ProvisioningError } from '../services/employeeProvisioning.service';
import { encryptCredential } from '../services/onboardingCredential.service';

const isAdminOrHr = roleMiddleware(['admin', 'hr']);
const isCompanyAdmin = roleMiddleware(['company_admin']);
const hrGateOnboarding = hrFeatureGate(['onboarding']);

function mkRes() {
  const res: any = {
    statusCode: 0,
    body: null,
    status(c: number) { this.statusCode = c; return this; },
    json(b: any) { this.body = b; return this; },
  };
  return res;
}

async function runMw(mw: any, req: any, res: any): Promise<boolean> {
  let passed = false;
  await mw(req, res, () => { passed = true; });
  return passed;
}

async function submitChain(user: any): Promise<number> {
  const req: any = { user, body: {}, query: {}, params: {} };
  const res = mkRes();
  if (!(await runMw(isAdminOrHr, req, res))) return res.statusCode;
  if (!(await runMw(hrGateOnboarding, req, res))) return res.statusCode;
  return 200;
}

const EMPLOYEE_PASSWORD = 'Emp@1234x';

const onboardingDoc = {
  companyDetails: {
    companyId: 'C1',
    employeeId: 'EMP-N1',
    officialEmail: 'new.emp@test.local',
    department: 'Eng',
    designation: 'Dev',
    branchLocation: 'BLR',
  },
  personalDetails: { fullName: 'New Emp', mobileCountryCode: '+91', mobileNumber: '999' },
  // HR-assigned password, encrypted at rest (as written by the submit route).
  initialPasswordEnc: encryptCredential(EMPLOYEE_PASSWORD),
  status: 'pending',
};

describe('onboarding V2 authorization + provisioning', () => {
  beforeEach(() => {
    for (const k of Object.keys(mockStore)) delete mockStore[k];
    batchSets.length = 0;
    docSets.length = 0;
    mockCreateUser.mockClear();
    mockGetUserByEmail.mockClear();
    mockGetUserByEmail.mockImplementation(async () => ({ uid: 'fb-existing' }));
    mockStore['users/hr-onb'] = { approvedFeatures: ['onboarding'] };
    mockStore['users/hr-none'] = { approvedFeatures: [] };
  });

  // --- submission gate ---
  test('admin can submit onboarding', async () => {
    expect(await submitChain({ role: 'admin', companyId: 'C1', userId: 'a1' })).toBe(200);
  });

  test('HR with onboarding approved can submit', async () => {
    expect(await submitChain({ role: 'hr', companyId: 'C1', userId: 'hr-onb' })).toBe(200);
  });

  test('HR without onboarding gets 403 on submit', async () => {
    expect(await submitChain({ role: 'hr', companyId: 'C1', userId: 'hr-none' })).toBe(403);
  });

  test('employee cannot submit onboarding (403)', async () => {
    expect(await submitChain({ role: 'employee', companyId: 'C1', userId: 'e1', empid: 'E1' })).toBe(403);
  });

  test('company_admin cannot submit onboarding (403)', async () => {
    expect(await submitChain({ role: 'company_admin', companyId: 'C1', userId: 'ca1' })).toBe(403);
  });

  // --- review gate ---
  test('company_admin passes the review gate', async () => {
    const req: any = { user: { role: 'company_admin', companyId: 'C1', userId: 'ca1' } };
    const res = mkRes();
    expect(await runMw(isCompanyAdmin, req, res)).toBe(true);
  });

  test('platform_admin cannot review (403)', async () => {
    const req: any = { user: { role: 'platform_admin', userId: 'pa1' } };
    const res = mkRes();
    expect(await runMw(isCompanyAdmin, req, res)).toBe(false);
    expect(res.statusCode).toBe(403);
  });

  test('super_admin cannot review (403)', async () => {
    const req: any = { user: { role: 'super_admin', userId: 'sa1' } };
    const res = mkRes();
    expect(await runMw(isCompanyAdmin, req, res)).toBe(false);
    expect(res.statusCode).toBe(403);
  });

  test('hr cannot review (403)', async () => {
    const req: any = { user: { role: 'hr', companyId: 'C1', userId: 'hr-onb' } };
    const res = mkRes();
    expect(await runMw(isCompanyAdmin, req, res)).toBe(false);
    expect(res.statusCode).toBe(403);
  });

  test('employee cannot review (403)', async () => {
    const req: any = { user: { role: 'employee', companyId: 'C1', userId: 'e1' } };
    const res = mkRes();
    expect(await runMw(isCompanyAdmin, req, res)).toBe(false);
    expect(res.statusCode).toBe(403);
  });

  // --- provisioning ---
  test('approve creates employees + users + onboarding linkage', async () => {
    const r = await provisionEmployeeFromOnboarding('onb-1', onboardingDoc, 'C1', 'ca1');
    expect(r.alreadyProvisioned).toBe(false);
    expect(r.employeeDocId).toBeTruthy();
    expect(r.userId).toBeTruthy();
    expect(r.firebaseUid).toBe('fb-uid-1');
    expect(r.tempPassword).toBeNull();
    // Firebase Auth is provisioned with the HR-assigned password, not a
    // generated temporary one.
    expect(mockCreateUser).toHaveBeenCalledWith(
      expect.objectContaining({ password: EMPLOYEE_PASSWORD }),
    );
    // batch wrote onboarding status=approved + linkage
    const ob = batchSets.find(s => s.data.status === 'approved');
    expect(ob).toBeTruthy();
    expect(ob!.data.employeeDocId).toBe(r.employeeDocId);
    // users doc carries bcrypt hash, never plaintext (employees docs also
    // carry role:'employee' — disambiguate by the password fields)
    const userWrite = batchSets.find(s => s.data.passwordHash);
    expect(userWrite!.data.password).toMatch(/^\$2[ab]\$/);
    expect(userWrite!.data.mustChangePassword).toBe(false);
    // employees master record
    const empWrite = batchSets.find(s => s.data.empid === 'EMP-N1' && !s.data.passwordHash);
    expect(empWrite!.data.companyId).toBe('C1');
    expect(empWrite!.data.source).toBe('onboarding');
  });

  test('repeated approval is idempotent (no duplicates)', async () => {
    const provisioned = { ...onboardingDoc, employeeDocId: 'e-doc', userId: 'u-doc', firebaseUid: 'fb-1', status: 'approved' };
    const r = await provisionEmployeeFromOnboarding('onb-1', provisioned, 'C1', 'ca1');
    expect(r.alreadyProvisioned).toBe(true);
    expect(r.employeeDocId).toBe('e-doc');
    expect(r.tempPassword).toBeNull();
    expect(batchSets.length).toBe(0);
  });

  test('duplicate empid in same company is rejected (409)', async () => {
    mockStore['employees/existing'] = { companyId: 'C1', empid: 'EMP-N1', email: 'other@x.com' };
    await expect(
      provisionEmployeeFromOnboarding('onb-1', onboardingDoc, 'C1', 'ca1'),
    ).rejects.toMatchObject({ status: 409 });
  });

  test('same empid in another company does not block', async () => {
    mockStore['employees/other'] = { companyId: 'C2', empid: 'EMP-N1', email: 'x@y.com' };
    const r = await provisionEmployeeFromOnboarding('onb-1', onboardingDoc, 'C1', 'ca1');
    expect(r.alreadyProvisioned).toBe(false);
  });

  test('duplicate login email is rejected (409)', async () => {
    mockStore['users/dup'] = { emailLower: 'new.emp@test.local', companyId: 'C9', role: 'employee' };
    await expect(
      provisionEmployeeFromOnboarding('onb-1', onboardingDoc, 'C1', 'ca1'),
    ).rejects.toMatchObject({ status: 409, code: 'DUPLICATE_LOGIN' });
  });

  test('missing required onboarding fields rejected (400)', async () => {
    await expect(
      provisionEmployeeFromOnboarding('onb-1', { companyDetails: { companyId: 'C1' }, personalDetails: {} }, 'C1', 'ca1'),
    ).rejects.toBeInstanceOf(ProvisioningError);
  });

  test('record without stored credential is rejected (400)', async () => {
    const { initialPasswordEnc, ...legacyDoc } = onboardingDoc as any;
    await expect(
      provisionEmployeeFromOnboarding('onb-1', legacyDoc, 'C1', 'ca1'),
    ).rejects.toMatchObject({ status: 400, code: 'NO_STORED_CREDENTIAL' });
  });

  // --- shift assignment ---
  const docWithShift = (extra: any = {}) => ({
    ...onboardingDoc,
    companyDetails: { ...onboardingDoc.companyDetails, ...extra },
  });

  test('onboarding shift name resolves to the canonical shift doc', async () => {
    mockStore['shifts/sh-gen'] = {
      companyId: 'C1', name: 'General', shiftname: 'GEN',
      startTime: '09:00', endTime: '17:30',
    };
    const r = await provisionEmployeeFromOnboarding(
      'onb-1', docWithShift({ shiftTime: 'General' }), 'C1', 'ca1');
    expect(r.alreadyProvisioned).toBe(false);
    const empWrite = batchSets.find(
      s => s.data.empid === 'EMP-N1' && !s.data.passwordHash);
    expect(empWrite!.data.shiftGroup).toBe('General');
    expect(empWrite!.data.shiftId).toBe('sh-gen');
    expect(empWrite!.data.shiftName).toBe('General');
  });

  test('stable shiftId link wins over the display name', async () => {
    mockStore['shifts/sh-id'] = {
      companyId: 'C1', name: 'Night', shiftname: 'NGT',
      startTime: '21:00', endTime: '06:00',
    };
    await provisionEmployeeFromOnboarding(
      'onb-1', docWithShift({ shiftTime: 'Night', shiftId: 'sh-id' }), 'C1', 'ca1');
    const empWrite = batchSets.find(
      s => s.data.empid === 'EMP-N1' && !s.data.passwordHash);
    expect(empWrite!.data.shiftId).toBe('sh-id');
    expect(empWrite!.data.shiftGroup).toBe('Night');
  });

  test('shiftId belonging to another company is rejected', async () => {
    mockStore['shifts/sh-foreign'] = {
      companyId: 'C2', name: 'General', shiftname: 'GEN',
      startTime: '09:00', endTime: '17:30',
    };
    await expect(
      provisionEmployeeFromOnboarding(
        'onb-1', docWithShift({ shiftId: 'sh-foreign' }), 'C1', 'ca1'),
    ).rejects.toMatchObject({ status: 400, code: 'SHIFT_NOT_FOUND' });
  });

  test('unresolvable onboarding shift is rejected (400)', async () => {
    await expect(
      provisionEmployeeFromOnboarding(
        'onb-1', docWithShift({ shiftTime: 'Deleted Shift' }), 'C1', 'ca1'),
    ).rejects.toMatchObject({ status: 400, code: 'SHIFT_NOT_FOUND' });
  });

  // --- auth identity repair ---
  test('re-approval repairs a missing Firebase Auth identity', async () => {
    // Auth user gone (e.g. emulator restart) — credential still stored.
    mockGetUserByEmail.mockRejectedValueOnce(
      Object.assign(new Error('no user'), { code: 'auth/user-not-found' }),
    );
    const provisioned = {
      ...onboardingDoc,
      employeeDocId: 'e-doc',
      userId: 'u-doc',
      firebaseUid: 'fb-gone',
      status: 'approved',
    };
    const r = await provisionEmployeeFromOnboarding('onb-1', provisioned, 'C1', 'ca1');
    expect(r.alreadyProvisioned).toBe(true);
    expect(mockCreateUser).toHaveBeenCalledWith(
      expect.objectContaining({ password: EMPLOYEE_PASSWORD }),
    );
    expect(r.firebaseUid).toBe('fb-uid-1');
    // repaired uid persisted to both linkage records
    expect(docSets.some(s => s.path === 'users/u-doc')).toBe(true);
    expect(docSets.some(s => s.path === 'employee_onboarding_dev/onb-1')).toBe(true);
  });

  test('re-approval of credential-less record fails clearly (400)', async () => {
    mockGetUserByEmail.mockRejectedValueOnce(
      Object.assign(new Error('no user'), { code: 'auth/user-not-found' }),
    );
    const { initialPasswordEnc, ...noCred } = onboardingDoc as any;
    const provisioned = {
      ...noCred,
      employeeDocId: 'e-doc',
      userId: 'u-doc',
      firebaseUid: 'fb-gone',
      status: 'approved',
    };
    await expect(
      provisionEmployeeFromOnboarding('onb-1', provisioned, 'C1', 'ca1'),
    ).rejects.toMatchObject({ status: 400, code: 'NO_STORED_CREDENTIAL' });
  });
});
