// functions/src/controllers/organizationRegistrationController.test.ts
/// <reference types="jest" />

import { Request, Response } from 'express';
import {
  createRegistrationDraft as createRegistrationDraftImpl,
  getMyRegistration,
  getRegistrationDraft,
  getRegistrationStatus,
  submitRegistration,
  updateRegistrationDraft,
} from './organizationRegistrationController';

// Draft creation now requires an authenticated org_applicant. Wrap the
// impl so existing call sites behave as the default applicant; tests for
// auth failures call createRegistrationDraftImpl directly.
const APPLICANT = {
  userId: 'applicant-uid-A',
  email: 'applicant-a@example.com',
  role: 'org_applicant',
};
const APPLICANT_B = {
  userId: 'applicant-uid-B',
  email: 'applicant-b@example.com',
  role: 'org_applicant',
};

const createRegistrationDraft = (
  req: Request,
  res: Response,
): Promise<Response> => {
  if (!(req as any).user) (req as any).user = APPLICANT;
  return createRegistrationDraftImpl(req, res);
};

process.env.FUNCTIONS_EMULATOR = 'true';
process.env.STORAGE_EMULATOR_HOST = '127.0.0.1:9199';

jest.mock('../config/firebase', () => ({
  getDb: jest.fn(),
  getAdminAuth: jest.fn(),
  getBucket: jest.fn(),
  checkFirestoreAccess: jest.fn().mockResolvedValue(true),
}));

import { getDb, getBucket } from '../config/firebase';
import { roleMiddleware } from '../middlewares/authMiddleware';
import { captureChangeRequestBaseline } from '../models/organizationRegistration';

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

function statusCode(res: Response): number {
  return (res.status as jest.Mock).mock.calls[0]?.[0];
}

interface MockDoc {
  id: string;
  data: any;
}

function getPath(obj: any, path: string): any {
  return path.split('.').reduce((o, k) => o?.[k], obj);
}

function setPath(obj: any, path: string, value: any): void {
  const parts = path.split('.');
  const last = parts.pop()!;
  const target = parts.reduce((o, k) => (o[k] = o[k] ?? {}), obj);
  target[last] = value;
}

/**
 * Minimal in-memory Firestore mock with dotted-field `where` support and
 * `doc.ref.update` (dot-path keys merged into the doc).
 */
function makeMockDb(collections: Record<string, MockDoc[]>) {
  function applyUpdates(col: MockDoc[], id: string, updates: Record<string, any>) {
    const target = col.find((d) => d.id === id);
    if (!target) throw new Error('NOT_FOUND');
    for (const [k, v] of Object.entries(updates)) {
      // Firestore FieldValue sentinels are opaque transform objects —
      // identify them by constructor name and apply the real semantics.
      const kind =
        v && typeof v === 'object' ? String(v.constructor?.name ?? '') : '';
      if (v && typeof v === 'object' && typeof v.operand === 'number') {
        // NumericIncrementTransform.
        const cur = Number(getPath(target.data, k) || 0);
        setPath(target.data, k, cur + v.operand);
      } else if (kind === 'ArrayUnionTransform') {
        const cur = getPath(target.data, k) ?? [];
        const els = Array.isArray(v.elements) ? v.elements : [];
        setPath(target.data, k, [...cur, ...els]);
      } else if (kind === 'ServerTimestampTransform') {
        setPath(target.data, k, new Date());
      } else {
        setPath(target.data, k, v);
      }
    }
  }

  function makeDocRef(col: MockDoc[], id: string) {
    return {
      id,
      _col: col,
      get: jest.fn(async () => {
        const doc = col.find((d) => d.id === id);
        return {
          id,
          exists: !!doc,
          data: () => (doc ? doc.data : undefined),
          ref: {
            update: jest.fn(async (updates: Record<string, any>) =>
              applyUpdates(col, id, updates)),
          },
        };
      }),
      set: jest.fn(async (data: any) => {
        const existing = col.find((d) => d.id === id);
        if (existing) targetMerge(existing.data, data);
        else col.push({ id, data });
      }),
      update: jest.fn(async (updates: Record<string, any>) =>
        applyUpdates(col, id, updates)),
      delete: jest.fn(async () => {
        const i = col.findIndex((d) => d.id === id);
        if (i >= 0) col.splice(i, 1);
      }),
    };
  }

  function targetMerge(target: any, src: any) {
    Object.assign(target, src);
  }

  function makeQuery(col: MockDoc[], filters: Array<[string, any]> = []) {
    // Firestore queries are immutable — each where() returns a new query.
    const q: any = {
      where: jest.fn((field: string, _op: string, value: any) =>
        makeQuery(col, [...filters, [field, value]])),
      limit: jest.fn(() => q),
      get: jest.fn(async () => {
        const matched = col.filter((d) =>
          filters.every(([f, v]) => getPath(d.data, f) === v),
        );
        return {
          empty: matched.length === 0,
          docs: matched.map((d) => ({
            id: d.id,
            data: () => d.data,
          })),
        };
      }),
      doc: jest.fn((id: string) => makeDocRef(col, id)),
    };
    return q;
  }

  return {
    db: {
      collection: jest.fn((name: string) => {
        const col = collections[name] || (collections[name] = []);
        return makeQuery(col);
      }),
      batch: jest.fn(() => {
        const ops: Array<{ ref: any; updates: Record<string, any> }> = [];
        return {
          update: jest.fn((ref: any, updates: Record<string, any>) => {
            ops.push({ ref, updates });
          }),
          set: jest.fn(),
          commit: jest.fn(async () => {
            for (const op of ops) applyUpdates(op.ref._col, op.ref.id, op.updates);
          }),
        };
      }),
      // Transactions apply immediately in the mock — sequential test calls
      // still exercise the status guard that prevents double submission.
      runTransaction: jest.fn(async (fn: any) =>
        fn({
          get: (ref: any) => ref.get(),
          update: (ref: any, updates: Record<string, any>) =>
            applyUpdates(ref._col, ref.id, updates),
          set: (ref: any, data: any) => {
            const existing = ref._col.find((d: MockDoc) => d.id === ref.id);
            if (existing) Object.assign(existing.data, data);
            else ref._col.push({ id: ref.id, data });
          },
        }),
      ),
    },
    collections,
  };
}

function makeReq({
  body = {},
  params = {},
  resumeToken,
  user,
}: {
  body?: any;
  params?: any;
  resumeToken?: string;
  user?: any;
}): Partial<Request> {
  return {
    body,
    params,
    user,
    ip: '127.0.0.1',
    header: (name: string) =>
      name.toLowerCase() === 'x-registration-resume-token'
        ? resumeToken
        : undefined,
    headers: {},
  } as any;
}

const VALID_ORG = {
  name: 'Acme Test Org',
  type: 'Private Limited',
  industry: 'Information Technology',
  employeeCount: 25,
  branchCount: 2,
  registeredAddress: '1 Test Street, Test City',
  officialEmail: 'hr@acme-test.example.com',
  contactNumber: '+91 80 1234 5678', // landline-style contact is allowed
  website: 'https://acme-test.example.com',
};

const VALID_ADMIN = {
  fullName: 'Jane Tester',
  designation: 'HR Manager',
  email: 'jane@acme-test.example.com',
  mobile: '9876543210',
};

const validBody = () => ({
  organization: { ...VALID_ORG },
  adminContact: { ...VALID_ADMIN },
  requestedFeatures: ['attendance', 'leave_management'],
  currentStep: 0,
  maxCompletedStep: -1,
});

async function createDraft(res?: Response) {
  const r = res ?? mockResponse();
  await createRegistrationDraft(makeReq({ body: validBody() }) as Request, r);
  return { res: r, body: jsonBody(r) };
}

// ---------- Tests ----------

describe('organizationRegistrationController', () => {
  let collections: Record<string, MockDoc[]>;

  beforeEach(() => {
    collections = {};
    (getDb as jest.Mock).mockReturnValue(makeMockDb(collections).db);
  });

  describe('POST /draft', () => {
    it('creates a draft and returns a resume token once', async () => {
      const { res, body } = await createDraft();
      expect(statusCode(res)).toBe(201);
      expect(body.registrationId).toBeTruthy();
      expect(body.resumeToken).toBeTruthy();
      expect(body.status).toBe('draft');

      const doc = collections['organizationRegistrations'][0];
      // Token stored only as hash — plaintext never persisted.
      expect(doc.data.resumeTokenHash).toMatch(/^[0-9a-f]{64}$/);
      expect(doc.data.resumeTokenHash).not.toBe(body.resumeToken);
      expect(doc.data.status).toBe('draft');
      expect(doc.data.verification).toEqual({
        orgEmail: { verified: false, target: '' },
        adminEmail: { verified: false, target: '' },
        adminMobile: { verified: false, target: '' },
      });
    });

    it('creates no organization profile or account', async () => {
      await createDraft();
      expect(collections['companyProfile']).toBeUndefined();
      expect(collections['users']).toBeUndefined();
      expect(collections['employees']).toBeUndefined();
    });

    it('rejects client-controlled approval fields', async () => {
      const res = mockResponse();
      await createRegistrationDraft(
        makeReq({
          body: {
            ...validBody(),
            status: 'approved',
            approvedFeatures: ['payroll'],
            organizationCode: 'HACKED01',
          },
        }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(400);
      expect(collections['organizationRegistrations']).toBeUndefined();
    });

    it('rejects an invalid 9-digit mobile', async () => {
      const res = mockResponse();
      await createRegistrationDraft(
        makeReq({
          body: {
            ...validBody(),
            adminContact: { ...VALID_ADMIN, mobile: '987654321' },
          },
        }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(400);
    });

    it('rejects a mobile starting with an invalid digit', async () => {
      const res = mockResponse();
      await createRegistrationDraft(
        makeReq({
          body: {
            ...validBody(),
            adminContact: { ...VALID_ADMIN, mobile: '1234567890' },
          },
        }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(400);
    });

    it('rejects a repeated-digit mobile', async () => {
      const res = mockResponse();
      await createRegistrationDraft(
        makeReq({
          body: {
            ...validBody(),
            adminContact: { ...VALID_ADMIN, mobile: '9999999999' },
          },
        }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(400);
    });

    it('rejects an unknown requested feature', async () => {
      const res = mockResponse();
      await createRegistrationDraft(
        makeReq({
          body: { ...validBody(), requestedFeatures: ['not_a_feature'] },
        }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(400);
      expect(jsonBody(res).error).toContain('not_a_feature');
    });

    it('rejects a duplicate application by official email', async () => {
      await createDraft();
      const res = mockResponse();
      // A DIFFERENT applicant with the same organization email → 409.
      await createRegistrationDraft(
        makeReq({ body: validBody(), user: APPLICANT_B }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(409);
    });

    it('allows distinct organizations that share a name', async () => {
      await createDraft();
      // Same org name, different official email — a different organization
      // applicant, not a duplicate. Name collisions are resolved at review.
      const res = mockResponse();
      await createRegistrationDraft(
        makeReq({
          user: APPLICANT_B,
          body: {
            ...validBody(),
            organization: {
              ...VALID_ORG,
              officialEmail: 'other-hr@other-org.example.com',
            },
          },
        }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(201);
    });
  });

  describe('GET /draft/:id', () => {
    it('returns the draft with a valid resume token', async () => {
      const { body } = await createDraft();
      const res = mockResponse();
      await getRegistrationDraft(
        makeReq({
          params: { id: body.registrationId },
          resumeToken: body.resumeToken,
        }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(200);
      expect(jsonBody(res).organization.name).toBe('Acme Test Org');
      expect(jsonBody(res).resumeTokenHash).toBeUndefined();
    });

    it('rejects a missing resume token', async () => {
      const { body } = await createDraft();
      const res = mockResponse();
      await getRegistrationDraft(
        makeReq({ params: { id: body.registrationId } }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(401);
    });

    it('rejects a wrong resume token (cross-applicant access)', async () => {
      const a = await createDraft();
      const res = mockResponse();
      await getRegistrationDraft(
        makeReq({
          params: { id: a.body.registrationId },
          resumeToken: 'a-different-token-that-is-wrong',
        }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(401);
    });

    it('returns 404 for an unknown registration id', async () => {
      const res = mockResponse();
      await getRegistrationDraft(
        makeReq({
          params: { id: 'does-not-exist' },
          resumeToken: 'any',
        }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(404);
    });
  });

  describe('PATCH /draft/:id', () => {
    it('updates editable fields with a valid token', async () => {
      const { body } = await createDraft();
      const res = mockResponse();
      await updateRegistrationDraft(
        makeReq({
          params: { id: body.registrationId },
          resumeToken: body.resumeToken,
          body: {
            organization: { ...VALID_ORG, employeeCount: 50 },
            currentStep: 2,
          },
        }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(200);
      const doc = collections['organizationRegistrations'][0];
      expect(doc.data.organization.employeeCount).toBe(50);
      expect(doc.data.currentStep).toBe(2);
    });

    it('rejects the update without a valid token', async () => {
      const { body } = await createDraft();
      const res = mockResponse();
      await updateRegistrationDraft(
        makeReq({
          params: { id: body.registrationId },
          body: { currentStep: 2 },
        }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(401);
    });

    it('rejects approval-field updates via PATCH', async () => {
      const { body } = await createDraft();
      const res = mockResponse();
      await updateRegistrationDraft(
        makeReq({
          params: { id: body.registrationId },
          resumeToken: body.resumeToken,
          body: { status: 'pending_approval', organizationCode: 'X' },
        }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(400);
    });

    it('rejects an email change that collides with another draft', async () => {
      const first = await createDraft();
      // Second draft with a different official email.
      const second = await createRegistrationDraft(
        makeReq({
          user: APPLICANT_B,
          body: {
            ...validBody(),
            organization: {
              ...VALID_ORG,
              officialEmail: 'other@acme-test.example.com',
            },
          },
        }) as Request,
        mockResponse(),
      ).then(() => null);

      const res = mockResponse();
      await updateRegistrationDraft(
        makeReq({
          params: { id: first.body.registrationId },
          resumeToken: first.body.resumeToken,
          body: {
            organization: {
              ...VALID_ORG,
              officialEmail: 'other@acme-test.example.com',
            },
          },
        }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(409);
      expect(second).toBeNull();
    });
  });

  describe('GET /status/:id', () => {
    it('returns status with a valid token', async () => {
      const { body } = await createDraft();
      const res = mockResponse();
      await getRegistrationStatus(
        makeReq({
          params: { id: body.registrationId },
          resumeToken: body.resumeToken,
        }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(200);
      expect(jsonBody(res).status).toBe('draft');
    });
  });

  describe('POST /submit', () => {
    it('rejects an unverified/undocumented application', async () => {
      const { body } = await createDraft();
      const res = mockResponse();
      await submitRegistration(
        makeReq({
          body: {
            registrationId: body.registrationId,
            declarationAccepted: true,
          },
          resumeToken: body.resumeToken,
        }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(400);
      expect(jsonBody(res).error).toContain('incomplete');
      // Status remains draft — submission was not faked.
      expect(collections['organizationRegistrations'][0].data.status)
        .toBe('draft');
    });
  });

  describe('resume after restart', () => {
    it('draft remains retrievable across controller invocations', async () => {
      const { body } = await createDraft();
      // Simulate restart: a brand-new request with only id + token.
      const res = mockResponse();
      await getRegistrationDraft(
        makeReq({
          params: { id: body.registrationId },
          resumeToken: body.resumeToken,
        }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(200);
      expect(jsonBody(res).requestedFeatures).toEqual([
        'attendance',
        'leave_management',
      ]);
    });
  });
});

// -- Milestone 3C: OTP verification + document upload -------------------------

import {
  confirmRegistrationVerification,
  getRegistrationDocument,
  listRegistrationDocuments,
  requestRegistrationVerification,
  uploadRegistrationDocuments,
} from './organizationRegistrationController';

describe('organizationRegistrationController � verification (3C)', () => {
  let collections: Record<string, MockDoc[]>;
  let bucketCalls: { saved: Array<{ path: string; size: number }> };

  beforeEach(() => {
    collections = {};
    (getDb as jest.Mock).mockReturnValue(makeMockDb(collections).db);
    bucketCalls = { saved: [] };
    (getBucket as jest.Mock).mockReturnValue({
      file: (p: string) => ({
        save: jest.fn(async (buf: Buffer) => {
          bucketCalls.saved.push({ path: p, size: buf.length });
        }),
        getSignedUrl: jest.fn(async () => [
          `https://storage.emulator/${p}?sig=dev`,
        ]),
      }),
    });
  });

  async function draftWithToken() {
    const res = mockResponse();
    await createRegistrationDraft(makeReq({ body: validBody() }) as Request, res);
    const body = jsonBody(res);
    return { id: body.registrationId as string, token: body.resumeToken as string };
  }

  async function requestCode(
    id: string,
    token: string,
    channel: string,
  ): Promise<{ status: number; body: any }> {
    const res = mockResponse();
    await requestRegistrationVerification(
      makeReq({
        body: { registrationId: id, channel },
        resumeToken: token,
      }) as Request,
      res,
    );
    return { status: statusCode(res), body: jsonBody(res) };
  }

  async function confirmCode(
    id: string,
    token: string,
    channel: string,
    code: string,
  ): Promise<{ status: number; body: any }> {
    const res = mockResponse();
    await confirmRegistrationVerification(
      makeReq({
        body: { registrationId: id, channel, code },
        resumeToken: token,
      }) as Request,
      res,
    );
    return { status: statusCode(res), body: jsonBody(res) };
  }

  it('requests an OTP and returns a dev code in emulator mode', async () => {
    const { id, token } = await draftWithToken();
    const r = await requestCode(id, token, 'orgEmail');
    expect(r.status).toBe(200);
    expect(r.body.delivered).toBe('dev');
    expect(r.body.devCode).toMatch(/^\d{6}$/);

    const otpDoc = collections['registrationOtps'][0];
    // Plaintext OTP is never stored � only the hash.
    expect(otpDoc.data.codeHash).toMatch(/^[0-9a-f]{64}$/);
    expect(otpDoc.data.codeHash).not.toBe(r.body.devCode);
  });

  it('confirms a correct OTP and stamps verification', async () => {
    const { id, token } = await draftWithToken();
    const { body } = await requestCode(id, token, 'orgEmail');
    const r = await confirmCode(id, token, 'orgEmail', body.devCode);
    expect(r.status).toBe(200);

    const doc = collections['organizationRegistrations'].find((d) => d.id === id)!;
    expect(doc.data.verification.orgEmail.verified).toBe(true);
    expect(doc.data.verification.orgEmail.target)
      .toBe('hr@acme-test.example.com');
  });

  it('rejects an incorrect OTP and counts the attempt', async () => {
    const { id, token } = await draftWithToken();
    await requestCode(id, token, 'orgEmail');
    const r = await confirmCode(id, token, 'orgEmail', '000000');
    expect(r.status).toBe(400);
    expect(collections['registrationOtps'][0].data.attempts)
      .toBeGreaterThanOrEqual(1);
  });

  it('enforces the 5-attempt limit', async () => {
    const { id, token } = await draftWithToken();
    await requestCode(id, token, 'orgEmail');
    for (let i = 0; i < 5; i++) {
      await confirmCode(id, token, 'orgEmail', '000000');
    }
    const r = await confirmCode(id, token, 'orgEmail', '111111');
    expect(r.status).toBe(429);
  });

  it('enforces the 60-second resend cooldown', async () => {
    const { id, token } = await draftWithToken();
    await requestCode(id, token, 'orgEmail');
    const r = await requestCode(id, token, 'orgEmail');
    expect(r.status).toBe(429);
  });

  it('rejects an expired OTP', async () => {
    const { id, token } = await draftWithToken();
    const { body } = await requestCode(id, token, 'orgEmail');
    // Expire the record in the mock store.
    collections['registrationOtps'][0].data.expiresAt =
      new Date(Date.now() - 1000);
    const r = await confirmCode(id, token, 'orgEmail', body.devCode);
    expect(r.status).toBe(400);
    expect(r.body.error).toContain('expired');
  });

  it('rejects reuse of a verified OTP', async () => {
    const { id, token } = await draftWithToken();
    const { body } = await requestCode(id, token, 'orgEmail');
    await confirmCode(id, token, 'orgEmail', body.devCode);
    const r = await confirmCode(id, token, 'orgEmail', body.devCode);
    expect(r.status).toBe(400);
    expect(r.body.error).toContain('already been used');
  });

  it('a code minted for registration A fails on registration B', async () => {
    const a = await draftWithToken();
    // Second registration needs a unique email to avoid the dedup rule.
    const resB = mockResponse();
    await createRegistrationDraft(
      makeReq({
        user: APPLICANT_B,
        body: {
          ...validBody(),
          organization: {
            ...VALID_ORG,
            officialEmail: 'b@acme-test.example.com',
          },
        },
      }) as Request,
      resB,
    );
    const b = jsonBody(resB);

    const { body } = await requestCode(a.id, a.token, 'orgEmail');
    const r = await confirmCode(b.registrationId, b.resumeToken, 'orgEmail', body.devCode);
    expect(r.status).toBe(400);
  });

  it('changing the org email invalidates its verification', async () => {
    const { id, token } = await draftWithToken();
    const { body } = await requestCode(id, token, 'orgEmail');
    await confirmCode(id, token, 'orgEmail', body.devCode);

    const res = mockResponse();
    await updateRegistrationDraft(
      makeReq({
        params: { id },
        resumeToken: token,
        body: {
          organization: {
            ...VALID_ORG,
            officialEmail: 'new-hr@acme-test.example.com',
          },
        },
      }) as Request,
      res,
    );
    expect(statusCode(res)).toBe(200);
    const doc = collections['organizationRegistrations'].find((d) => d.id === id)!;
    expect(doc.data.verification.orgEmail.verified).toBe(false);
    // Outstanding OTP for the old target is cleared.
    expect(collections['registrationOtps'].length).toBe(0);
  });

  it('admin email is required only when it differs from org email', async () => {
    const res = mockResponse();
    await createRegistrationDraft(
      makeReq({
        body: {
          ...validBody(),
          adminContact: { ...VALID_ADMIN, email: VALID_ORG.officialEmail },
        },
      }) as Request,
      res,
    );
    const { registrationId, resumeToken } = jsonBody(res);
    // adminEmail is NOT required when it equals orgEmail.
    const r = await requestCode(registrationId, resumeToken, 'adminEmail');
    expect(r.status).toBe(400);
    // orgEmail + adminMobile remain required.
    expect((await requestCode(registrationId, resumeToken, 'adminMobile')).status)
      .toBe(200);
  });

  it('rejects verification requests without a resume token', async () => {
    const { id } = await draftWithToken();
    const res = mockResponse();
    await requestRegistrationVerification(
      makeReq({ body: { registrationId: id, channel: 'orgEmail' } }) as Request,
      res,
    );
    expect(statusCode(res)).toBe(401);
  });
});

describe('organizationRegistrationController � documents (3C)', () => {
  let collections: Record<string, MockDoc[]>;
  let bucketCalls: { saved: Array<{ path: string; size: number }> };

  const PDF = Buffer.from('%PDF-1.4 fake-pdf-content');
  const PNG = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 1, 2, 3]);

  beforeEach(() => {
    collections = {};
    (getDb as jest.Mock).mockReturnValue(makeMockDb(collections).db);
    bucketCalls = { saved: [] };
    (getBucket as jest.Mock).mockReturnValue({
      file: (p: string) => ({
        save: jest.fn(async (buf: Buffer) => {
          bucketCalls.saved.push({ path: p, size: buf.length });
        }),
        download: jest.fn(async () => [PDF]),
      }),
    });
  });

  async function verifiedDraft() {
    const res = mockResponse();
    await createRegistrationDraft(makeReq({ body: validBody() }) as Request, res);
    const body = jsonBody(res);
    const id = body.registrationId as string;
    const token = body.resumeToken as string;
    const doc = collections['organizationRegistrations'].find((d) => d.id === id)!;
    doc.data.verification.orgEmail = { verified: true, target: 'hr@acme-test.example.com' };
    doc.data.verification.adminMobile = { verified: true, target: '9876543210' };
    doc.data.verification.adminEmail = { verified: true, target: 'jane@acme-test.example.com' };
    return { id, token };
  }

  function uploadReq(
    id: string,
    token: string | undefined,
    files: Record<string, Buffer>,
  ): Partial<Request> {
    const req = makeReq({
      body: { registrationId: id },
      resumeToken: token,
    }) as any;
    req.files = Object.fromEntries(
      Object.entries(files).map(([k, buf]) => [
        k,
        [{
          fieldname: k,
          originalname: `${k}.pdf`,
          mimetype: 'application/pdf',
          buffer: buf,
          size: buf.length,
        }],
      ]),
    );
    return req;
  }

  it('uploads a document to a private registration path', async () => {
    const { id, token } = await verifiedDraft();
    const res = mockResponse();
    await uploadRegistrationDocuments(
      uploadReq(id, token, { registrationCertificate: PDF }) as Request,
      res,
    );
    expect(statusCode(res)).toBe(200);
    expect(bucketCalls.saved[0].path).toContain(`org-registrations/${id}/registrationCertificate/`);
    const doc = collections['organizationRegistrations'].find((d) => d.id === id)!;
    expect(doc.data.documents.registrationCertificate.contentType)
      .toBe('application/pdf');
  });

  it('rejects upload without a resume token', async () => {
    const { id } = await verifiedDraft();
    const res = mockResponse();
    await uploadRegistrationDocuments(
      uploadReq(id, undefined, { registrationCertificate: PDF }) as Request,
      res,
    );
    expect(statusCode(res)).toBe(401);
  });

  it('rejects upload before contact verification', async () => {
    const res = mockResponse();
    await createRegistrationDraft(makeReq({ body: validBody() }) as Request, res);
    const { registrationId, resumeToken } = jsonBody(res);
    const r = mockResponse();
    await uploadRegistrationDocuments(
      uploadReq(registrationId, resumeToken, { registrationCertificate: PDF }) as Request,
      r,
    );
    expect(statusCode(r)).toBe(403);
  });

  it('rejects a file that is not PDF/JPG/PNG by content', async () => {
    const { id, token } = await verifiedDraft();
    const res = mockResponse();
    await uploadRegistrationDocuments(
      uploadReq(id, token, {
        registrationCertificate: Buffer.from('PK\x03\x04 zip-not-pdf'),
      }) as Request,
      res,
    );
    expect(statusCode(res)).toBe(400);
    expect(bucketCalls.saved.length).toBe(0);
  });

  it('rejects an unknown document field', async () => {
    const { id, token } = await verifiedDraft();
    const res = mockResponse();
    await uploadRegistrationDocuments(
      uploadReq(id, token, { notAField: PDF }) as Request,
      res,
    );
    expect(statusCode(res)).toBe(400);
  });

  it('replaces an existing document', async () => {
    const { id, token } = await verifiedDraft();
    await uploadRegistrationDocuments(
      uploadReq(id, token, { registrationCertificate: PDF }) as Request,
      mockResponse(),
    );
    const res = mockResponse();
    await uploadRegistrationDocuments(
      uploadReq(id, token, { registrationCertificate: PNG }) as Request,
      res,
    );
    expect(statusCode(res)).toBe(200);
    const doc = collections['organizationRegistrations'].find((d) => d.id === id)!;
    expect(doc.data.documents.registrationCertificate.contentType)
      .toBe('image/png');
  });

  it('lists document metadata with a valid token', async () => {
    const { id, token } = await verifiedDraft();
    await uploadRegistrationDocuments(
      uploadReq(id, token, { registrationCertificate: PDF }) as Request,
      mockResponse(),
    );
    const res = mockResponse();
    await listRegistrationDocuments(
      makeReq({ params: { id }, resumeToken: token }) as Request,
      res,
    );
    expect(statusCode(res)).toBe(200);
    expect(jsonBody(res).documents.registrationCertificate).toBeTruthy();
  });

  it('streams the document to the applicant only', async () => {
    const { id, token } = await verifiedDraft();
    await uploadRegistrationDocuments(
      uploadReq(id, token, { registrationCertificate: PDF }) as Request,
      mockResponse(),
    );
    const res = {
      setHeader: jest.fn(),
      send: jest.fn(),
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    } as any;
    await getRegistrationDocument(
      makeReq({
        params: { id, field: 'registrationCertificate' },
        resumeToken: token,
      }) as Request,
      res,
    );
    expect(res.send).toHaveBeenCalledWith(PDF);
    expect(res.setHeader).toHaveBeenCalledWith(
      'Content-Type',
      'application/pdf',
    );

    const bad = mockResponse();
    await getRegistrationDocument(
      makeReq({
        params: { id, field: 'registrationCertificate' },
        resumeToken: 'wrong',
      }) as Request,
      bad,
    );
    expect(statusCode(bad)).toBe(401);
  });
});

// -- Milestone 3D-A: applicant submission --------------------------------------

describe('organizationRegistrationController - submission (3D-A)', () => {
  let collections: Record<string, MockDoc[]>;

  const DOC_META = () => ({
    field: 'registrationCertificate',
    storagePath: 'org-registrations/x/registrationCertificate/1_a.pdf',
    originalName: 'a.pdf',
    contentType: 'application/pdf',
    size: 100,
    uploadedAt: new Date(),
  });

  beforeEach(() => {
    collections = {};
    (getDb as jest.Mock).mockReturnValue(makeMockDb(collections).db);
    (getBucket as jest.Mock).mockReturnValue({
      file: (p: string) => ({
        save: jest.fn(async () => undefined),
        download: jest.fn(async () => [Buffer.from('%PDF-x')]),
      }),
    });
  });

  /** Creates a draft that satisfies every submission gate. */
  async function completeDraft(overrides: any = {}) {
    const res = mockResponse();
    await createRegistrationDraft(
      makeReq({ body: { ...validBody(), ...overrides } }) as Request,
      res,
    );
    const { registrationId: id, resumeToken: token } = jsonBody(res);
    const doc = collections['organizationRegistrations'].find(
      (d) => d.id === id,
    )!;
    doc.data.verification = {
      orgEmail: { verified: true, target: 'hr@acme-test.example.com' },
      adminEmail: { verified: true, target: 'jane@acme-test.example.com' },
      adminMobile: { verified: true, target: '9876543210' },
    };
    doc.data.documents = {
      registrationCertificate: DOC_META(),
      authorizationLetter: { ...DOC_META(), field: 'authorizationLetter' },
      adminIdProof: { ...DOC_META(), field: 'adminIdProof' },
    };
    return { id, token, doc };
  }

  async function submit(
    id: string,
    token: string | undefined,
    extra: any = {},
  ): Promise<{ status: number; body: any }> {
    const res = mockResponse();
    await submitRegistration(
      makeReq({
        body: { registrationId: id, declarationAccepted: true, ...extra },
        resumeToken: token,
      }) as Request,
      res,
    );
    return { status: statusCode(res), body: jsonBody(res) };
  }

  it('submits a complete application to pending_approval', async () => {
    const { id, token, doc } = await completeDraft();
    const r = await submit(id, token);
    expect(r.status).toBe(200);
    expect(r.body.status).toBe('pending_approval');
    expect(doc.data.status).toBe('pending_approval');
    expect(doc.data.submittedAt).toBeTruthy();
    expect(doc.data.declarationAccepted).toBe(true);
    const actions = doc.data.auditTrail.map((a: any) => a.action);
    expect(actions).toContain('submitted');
  });

  it('requires the applicant declaration', async () => {
    const { id, token } = await completeDraft();
    const res = mockResponse();
    await submitRegistration(
      makeReq({ body: { registrationId: id }, resumeToken: token }) as Request,
      res,
    );
    expect(statusCode(res)).toBe(400);
    expect(collections['organizationRegistrations'][0].data.status)
      .toBe('draft');
  });

  it('rejects incomplete organization details', async () => {
    const res = mockResponse();
    await createRegistrationDraft(
      makeReq({
        body: {
          ...validBody(),
          organization: { ...VALID_ORG, name: '' },
        },
      }) as Request,
      res,
    );
    const { registrationId: id, resumeToken: token } = jsonBody(res);
    const doc = collections['organizationRegistrations'].find(
      (d) => d.id === id,
    )!;
    doc.data.verification = {
      orgEmail: { verified: true, target: 'hr@acme-test.example.com' },
      adminEmail: { verified: true, target: 'jane@acme-test.example.com' },
      adminMobile: { verified: true, target: '9876543210' },
    };
    doc.data.documents = {
      registrationCertificate: DOC_META(),
      authorizationLetter: DOC_META(),
      adminIdProof: DOC_META(),
    };
    const r = await submit(id, token);
    expect(r.status).toBe(400);
    expect(r.body.error).toContain('organization');
  });

  it('rejects incomplete HR/Admin details', async () => {
    const res = mockResponse();
    await createRegistrationDraft(
      makeReq({
        body: {
          ...validBody(),
          adminContact: { ...VALID_ADMIN, fullName: '' },
        },
      }) as Request,
      res,
    );
    const { registrationId: id, resumeToken: token } = jsonBody(res);
    const doc = collections['organizationRegistrations'].find(
      (d) => d.id === id,
    )!;
    doc.data.verification = {
      orgEmail: { verified: true, target: 'hr@acme-test.example.com' },
      adminEmail: { verified: true, target: 'jane@acme-test.example.com' },
      adminMobile: { verified: true, target: '9876543210' },
    };
    doc.data.documents = {
      registrationCertificate: DOC_META(),
      authorizationLetter: DOC_META(),
      adminIdProof: DOC_META(),
    };
    const r = await submit(id, token);
    expect(r.status).toBe(400);
    expect(r.body.error).toContain('adminContact');
  });

  it('rejects when a required OTP channel is unverified', async () => {
    const { id, token, doc } = await completeDraft();
    doc.data.verification.adminMobile = { verified: false, target: '' };
    const r = await submit(id, token);
    expect(r.status).toBe(400);
    expect(r.body.error).toContain('mobile verification');
  });

  it('rejects when a required document is missing', async () => {
    const { id, token, doc } = await completeDraft();
    delete doc.data.documents.adminIdProof;
    const r = await submit(id, token);
    expect(r.status).toBe(400);
    expect(r.body.error).toContain('adminIdProof');
  });

  it('enforces the conditional GST certificate requirement', async () => {
    const { id, token, doc } = await completeDraft({
      organization: { ...VALID_ORG, gstNumber: '29ABCDE1234F1Z5' },
    });
    // GST number present but no GST certificate -> rejected.
    let r = await submit(id, token);
    expect(r.status).toBe(400);
    expect(r.body.error).toContain('gstCertificate');
    // With the certificate uploaded -> accepted.
    doc.data.documents.gstCertificate = {
      ...DOC_META(),
      field: 'gstCertificate',
    };
    r = await submit(id, token);
    expect(r.status).toBe(200);
    expect(doc.data.status).toBe('pending_approval');
  });

  it('rejects invalid stored requested-feature IDs', async () => {
    const { id, token, doc } = await completeDraft();
    doc.data.requestedFeatures = ['attendance', 'bogus_module'];
    const r = await submit(id, token);
    expect(r.status).toBe(400);
    expect(r.body.error).toContain('bogus_module');
  });

  it('rejects missing and wrong resume credentials', async () => {
    const { id, token } = await completeDraft();
    expect((await submit(id, undefined)).status).toBe(401);
    expect((await submit(id, 'wrong-token')).status).toBe(401);
    expect((await submit(id, token)).status).toBe(200);
  });

  it('rejects a credential belonging to a different registration', async () => {
    const a = await completeDraft();
    const resB = mockResponse();
    await createRegistrationDraft(
      makeReq({
        user: APPLICANT_B,
        body: {
          ...validBody(),
          organization: {
            ...VALID_ORG,
            officialEmail: 'b@acme-test.example.com',
          },
        },
      }) as Request,
      resB,
    );
    const b = jsonBody(resB);
    const r = await submit(a.id, b.resumeToken);
    expect(r.status).toBe(401);
  });

  it('returns idempotent success on repeat submission', async () => {
    const { id, token, doc } = await completeDraft();
    expect((await submit(id, token)).status).toBe(200);
    const second = await submit(id, token);
    expect(second.status).toBe(200);
    expect(second.body.alreadySubmitted).toBe(true);
    const submittedEvents = doc.data.auditTrail.filter(
      (a: any) => a.action === 'submitted',
    );
    expect(submittedEvents.length).toBe(1);
  });

  it('handles concurrent submissions without duplicate audit events', async () => {
    const { id, token, doc } = await completeDraft();
    const [r1, r2] = await Promise.all([submit(id, token), submit(id, token)]);
    expect([r1.status, r2.status].sort()).toEqual([200, 200]);
    const submittedEvents = doc.data.auditTrail.filter(
      (a: any) => a.action === 'submitted',
    );
    expect(submittedEvents.length).toBe(1);
    expect(doc.data.status).toBe('pending_approval');
  });

  it('blocks PATCH edits after submission', async () => {
    const { id, token } = await completeDraft();
    await submit(id, token);
    const res = mockResponse();
    await updateRegistrationDraft(
      makeReq({
        params: { id },
        resumeToken: token,
        body: { currentStep: 1 },
      }) as Request,
      res,
    );
    expect(statusCode(res)).toBe(403);
  });

  it('blocks document upload after submission', async () => {
    const { id, token } = await completeDraft();
    await submit(id, token);
    const req = makeReq({
      body: { registrationId: id },
      resumeToken: token,
    }) as any;
    req.files = {
      registrationCertificate: [
        {
          fieldname: 'registrationCertificate',
          originalname: 'new.pdf',
          mimetype: 'application/pdf',
          buffer: Buffer.from('%PDF-1.4 x'),
          size: 12,
        },
      ],
    };
    const res = mockResponse();
    await uploadRegistrationDocuments(req as Request, res);
    expect(statusCode(res)).toBe(403);
  });

  it('blocks OTP requests after submission', async () => {
    const { id, token } = await completeDraft();
    await submit(id, token);
    const res = mockResponse();
    await requestRegistrationVerification(
      makeReq({
        body: { registrationId: id, channel: 'orgEmail' },
        resumeToken: token,
      }) as Request,
      res,
    );
    expect(statusCode(res)).toBe(403);
  });

  it('still returns status to the submitted applicant', async () => {
    const { id, token } = await completeDraft();
    await submit(id, token);
    const res = mockResponse();
    await getRegistrationStatus(
      makeReq({ params: { id }, resumeToken: token }) as Request,
      res,
    );
    expect(statusCode(res)).toBe(200);
    expect(jsonBody(res).status).toBe('pending_approval');
    expect(jsonBody(res).organizationName).toBe('Acme Test Org');
  });

  it('creates no operational organization or account on submit', async () => {
    const { id, token, doc } = await completeDraft();
    await submit(id, token);
    expect(collections['companyProfile']).toBeUndefined();
    expect(collections['users']).toBeUndefined();
    expect(collections['employees']).toBeUndefined();
    expect(doc.data.organizationCode).toBeUndefined();
    expect(doc.data.approvedFeatures).toBeUndefined();
    expect(doc.data.enabledFeatures).toBeUndefined();
  });

  it('supports resubmission from changes_requested', async () => {
    const { id, token, doc } = await completeDraft();
    doc.data.status = 'changes_requested';
    const r = await submit(id, token);
    expect(r.status).toBe(200);
    expect(doc.data.status).toBe('pending_approval');
    expect(doc.data.resubmissionCount).toBe(1);
    const actions = doc.data.auditTrail.map((a: any) => a.action);
    expect(actions).toContain('application_resubmitted');
  });

  it('conflicts when the status is not submittable', async () => {
    const { id, token, doc } = await completeDraft();
    doc.data.status = 'approved';
    const r = await submit(id, token);
    expect(r.status).toBe(409);
  });
});

// ─── 3D-C follow-up: authenticated applicant binding ──────────────────────────

describe('authenticated applicant flow (3D-C)', () => {
  let collections: Record<string, MockDoc[]>;

  beforeEach(() => {
    collections = { organizationRegistrations: [] };
    (getDb as jest.Mock).mockReturnValue(makeMockDb(collections).db);
    (getBucket as jest.Mock).mockReturnValue({});
  });

  it('rejects draft creation without authentication', async () => {
    const res = mockResponse();
    await createRegistrationDraftImpl(
      makeReq({ body: validBody() }) as Request,
      res,
    );
    expect(statusCode(res)).toBe(401);
  });

  it('rejects draft creation for a non-applicant role', async () => {
    const res = mockResponse();
    await createRegistrationDraftImpl(
      makeReq({
        body: validBody(),
        user: { userId: 'u1', email: 'a@b.c', role: 'admin' },
      }) as Request,
      res,
    );
    expect(statusCode(res)).toBe(403);
  });

  it('binds applicantUid/applicantEmail from the verified JWT', async () => {
    const res = mockResponse();
    await createRegistrationDraft(
      makeReq({ body: validBody() }) as Request,
      res,
    );
    const doc = collections['organizationRegistrations'][0];
    expect(doc.data.applicantUid).toBe(APPLICANT.userId);
    expect(doc.data.applicantEmail).toBe(APPLICANT.email);
  });

  it('rejects client-supplied applicant identity fields', async () => {
    const res = mockResponse();
    await createRegistrationDraft(
      makeReq({
        body: { ...validBody(), applicantUid: 'spoofed', applicantEmail: 'x@y.z' },
      }) as Request,
      res,
    );
    expect(statusCode(res)).toBe(400);
  });

  it('returns the existing active application instead of duplicating', async () => {
    const first = mockResponse();
    await createRegistrationDraft(makeReq({ body: validBody() }) as Request, first);
    const id = jsonBody(first).registrationId;
    const second = mockResponse();
    await createRegistrationDraft(makeReq({ body: validBody() }) as Request, second);
    expect(statusCode(second)).toBe(200);
    expect(jsonBody(second).alreadyExists).toBe(true);
    expect(jsonBody(second).registrationId).toBe(id);
    expect(collections['organizationRegistrations'].length).toBe(1);
  });

  it('bound owner JWT accesses the draft without a resume token', async () => {
    const res = mockResponse();
    await createRegistrationDraft(makeReq({ body: validBody() }) as Request, res);
    const id = jsonBody(res).registrationId;
    // No x-registration-resume-token — JWT owner match authorizes.
    const get = mockResponse();
    await getRegistrationDraft(
      makeReq({ params: { id }, user: APPLICANT }) as Request,
      get,
    );
    expect(statusCode(get)).toBe(200);
    expect(jsonBody(get).registrationId).toBe(id);
  });

  it('a different applicant JWT is forbidden — even with a valid token', async () => {
    const res = mockResponse();
    await createRegistrationDraft(makeReq({ body: validBody() }) as Request, res);
    const id = jsonBody(res).registrationId;
    const token = jsonBody(res).resumeToken;
    const get = mockResponse();
    await getRegistrationDraft(
      makeReq({ params: { id }, resumeToken: token, user: APPLICANT_B }) as Request,
      get,
    );
    expect(statusCode(get)).toBe(403);
  });

  it('a different applicant without token gets unauthorized', async () => {
    const res = mockResponse();
    await createRegistrationDraft(makeReq({ body: validBody() }) as Request, res);
    const id = jsonBody(res).registrationId;
    const get = mockResponse();
    await getRegistrationDraft(
      makeReq({ params: { id }, user: APPLICANT_B }) as Request,
      get,
    );
    expect(statusCode(get)).toBe(403);
  });

  it('GET /mine resolves the caller application server-side', async () => {
    const res = mockResponse();
    await createRegistrationDraft(makeReq({ body: validBody() }) as Request, res);
    const id = jsonBody(res).registrationId;
    const mine = mockResponse();
    await getMyRegistration(makeReq({ user: APPLICANT }) as Request, mine);
    const app = jsonBody(mine).application;
    expect(app.registrationId).toBe(id);
    expect(app.status).toBe('draft');
  });

  it('GET /mine returns null when the applicant has no application', async () => {
    const mine = mockResponse();
    await getMyRegistration(makeReq({ user: APPLICANT_B }) as Request, mine);
    expect(jsonBody(mine).application).toBeNull();
  });

  it('GET /mine never returns another applicant application', async () => {
    await createRegistrationDraft(makeReq({ body: validBody() }) as Request, mockResponse());
    const mine = mockResponse();
    await getMyRegistration(makeReq({ user: APPLICANT_B }) as Request, mine);
    expect(jsonBody(mine).application).toBeNull();
  });
});

describe('org_applicant access control (3D-C)', () => {
  const next = jest.fn();
  beforeEach(() => next.mockClear());

  it('org_applicant is forbidden from admin-only routes', () => {
    const guard = roleMiddleware(['admin']);
    const req = makeReq({}) as Request;
    req.user = { userId: 'a1', email: 'a@b.c', role: 'org_applicant' };
    const res = mockResponse();
    guard(req, res, next);
    expect(statusCode(res)).toBe(403);
    expect(next).not.toHaveBeenCalled();
  });

  it('org_applicant is forbidden from platform_admin routes', () => {
    const guard = roleMiddleware(['platform_admin']);
    const req = makeReq({}) as Request;
    req.user = { userId: 'a1', email: 'a@b.c', role: 'org_applicant' };
    const res = mockResponse();
    guard(req, res, next);
    expect(statusCode(res)).toBe(403);
    expect(next).not.toHaveBeenCalled();
  });

  it('org_applicant is allowed through its own role gate', () => {
    const guard = roleMiddleware(['org_applicant']);
    const req = makeReq({}) as Request;
    req.user = { userId: 'a1', email: 'a@b.c', role: 'org_applicant' };
    const res = mockResponse();
    guard(req, res, next);
    expect(next).toHaveBeenCalled();
  });
});

// ─── 3D-C follow-up: in-place correction & resubmission ───────────────────────

describe('in-place correction and resubmission (3D-C)', () => {
  let collections: Record<string, MockDoc[]>;

  const DOC_META = (field = 'registrationCertificate') => ({
    field,
    storagePath: `org-registrations/x/${field}/1_a.pdf`,
    originalName: 'a.pdf',
    contentType: 'application/pdf',
    size: 100,
    uploadedAt: new Date(),
  });

  beforeEach(() => {
    collections = { organizationRegistrations: [] };
    (getDb as jest.Mock).mockReturnValue(makeMockDb(collections).db);
    (getBucket as jest.Mock).mockReturnValue({});
  });

  /** A submission-ready draft owned by APPLICANT, currently changes_requested. */
  async function changesRequestedApp() {
    const res = mockResponse();
    await createRegistrationDraft(
      makeReq({ body: validBody() }) as Request,
      res,
    );
    const { registrationId: id, resumeToken: token } = jsonBody(res);
    const doc = collections['organizationRegistrations'].find(
      (d) => d.id === id,
    )!;
    doc.data.verification = {
      orgEmail: { verified: true, target: 'hr@acme-test.example.com' },
      adminEmail: { verified: true, target: 'jane@acme-test.example.com' },
      adminMobile: { verified: true, target: '9876543210' },
    };
    doc.data.documents = {
      registrationCertificate: DOC_META(),
      authorizationLetter: DOC_META('authorizationLetter'),
      adminIdProof: DOC_META('adminIdProof'),
    };
    doc.data.status = 'changes_requested';
    doc.data.submittedAt = new Date();
    doc.data.review = {
      reviewerId: 'rev-1',
      reviewerEmail: 'rev@serv.test',
      decidedAt: new Date(),
      decision: 'changes_requested',
      reasons: ['Fix GST number'],
      note: 'Fix GST number',
    };
    // The request-changes decision captures the sanitized baseline that
    // the resubmission diff is computed against.
    doc.data.changeRequestBaseline = captureChangeRequestBaseline(
      doc.data as any,
    );
    return { id, token, doc };
  }

  async function doSubmit(id: string, token?: string, user?: any) {
    const res = mockResponse();
    await submitRegistration(
      makeReq({
        body: { registrationId: id, declarationAccepted: true },
        resumeToken: token,
        user,
      }) as Request,
      res,
    );
    return res;
  }

  it('PATCH updates the SAME registration while changes_requested', async () => {
    const { id, doc } = await changesRequestedApp();
    const res = mockResponse();
    await updateRegistrationDraft(
      makeReq({
        params: { id },
        user: APPLICANT,
        body: { organization: { ...VALID_ORG, gstNumber: 'GST-NEW-1' } },
      }) as Request,
      res,
    );
    expect(statusCode(res)).toBe(200);
    expect(collections['organizationRegistrations'].length).toBe(1);
    expect(doc.id).toBe(id);
    expect(doc.data.organization.gstNumber).toBe('GST-NEW-1');
    expect(doc.data.status).toBe('changes_requested');
  });

  it('resubmission keeps the same id, uid and applicant binding', async () => {
    const { id, token, doc } = await changesRequestedApp();
    const res = await doSubmit(id, token, APPLICANT);
    expect(statusCode(res)).toBe(200);
    expect(jsonBody(res).registrationId).toBe(id);
    expect(doc.data.status).toBe('pending_approval');
    expect(doc.data.applicantUid).toBe(APPLICANT.userId);
    expect(doc.data.resubmissionCount).toBe(1);
    expect(doc.data.resubmittedAt).toBeTruthy();
    expect(collections['organizationRegistrations'].length).toBe(1);
  });

  it('appends application_resubmitted exactly once with revision', async () => {
    const { id, token, doc } = await changesRequestedApp();
    await doSubmit(id, token, APPLICANT);
    const events = doc.data.auditTrail.filter(
      (a: any) => a.action === 'application_resubmitted',
    );
    expect(events.length).toBe(1);
    expect(events[0].revision).toBe(1);
    expect(events[0].actor).toBe(APPLICANT.userId);
  });

  it('archives the prior review into reviewHistory', async () => {
    const { id, token, doc } = await changesRequestedApp();
    await doSubmit(id, token, APPLICANT);
    expect(doc.data.reviewHistory.length).toBe(1);
    expect(doc.data.reviewHistory[0].decision).toBe('changes_requested');
    expect(doc.data.reviewHistory[0].note).toBe('Fix GST number');
    // The changes_requested decision audit event also survives.
    const actions = doc.data.auditTrail.map((a: any) => a.action);
    expect(actions).toContain('application_resubmitted');
  });

  it('a repeat submit is idempotent — no second resubmission event', async () => {
    const { id, token, doc } = await changesRequestedApp();
    await doSubmit(id, token, APPLICANT);
    const again = await doSubmit(id, token, APPLICANT);
    expect(statusCode(again)).toBe(200);
    expect(jsonBody(again).alreadySubmitted).toBe(true);
    const events = doc.data.auditTrail.filter(
      (a: any) => a.action === 'application_resubmitted',
    );
    expect(events.length).toBe(1);
  });

  it('another applicant cannot PATCH the application', async () => {
    const { id, token } = await changesRequestedApp();
    const res = mockResponse();
    await updateRegistrationDraft(
      makeReq({
        params: { id },
        resumeToken: token,
        user: APPLICANT_B,
        body: { organization: { ...VALID_ORG, name: 'Hijack Org' } },
      }) as Request,
      res,
    );
    expect(statusCode(res)).toBe(403);
  });

  it('another applicant cannot resubmit the application', async () => {
    const { id, token } = await changesRequestedApp();
    const res = await doSubmit(id, token, APPLICANT_B);
    expect(statusCode(res)).toBe(403);
  });

  it('unchanged verified contacts keep their verification', async () => {
    const { id, doc } = await changesRequestedApp();
    const res = mockResponse();
    await updateRegistrationDraft(
      makeReq({
        params: { id },
        user: APPLICANT,
        body: { organization: { ...VALID_ORG, name: 'Renamed Org' } },
      }) as Request,
      res,
    );
    expect(statusCode(res)).toBe(200);
    expect(doc.data.verification.orgEmail.verified).toBe(true);
    expect(doc.data.verification.adminMobile.verified).toBe(true);
  });

  it('changing a verified contact invalidates ONLY that channel', async () => {
    const { id, doc } = await changesRequestedApp();
    const res = mockResponse();
    await updateRegistrationDraft(
      makeReq({
        params: { id },
        user: APPLICANT,
        body: {
          adminContact: { ...VALID_ADMIN, mobile: '9000000001' },
        },
      }) as Request,
      res,
    );
    expect(statusCode(res)).toBe(200);
    expect(doc.data.verification.adminMobile.verified).toBe(false);
    expect(doc.data.verification.orgEmail.verified).toBe(true);
    expect(doc.data.verification.adminEmail.verified).toBe(true);
  });

  it('documents are preserved through resubmission', async () => {
    const { id, token, doc } = await changesRequestedApp();
    await doSubmit(id, token, APPLICANT);
    expect(Object.keys(doc.data.documents).length).toBe(3);
    expect(doc.data.documents.registrationCertificate).toBeTruthy();
  });

  it('PATCH rejects client-supplied changeRequestBaseline/changedFields', async () => {
    const { id } = await changesRequestedApp();
    for (const bad of ['changeRequestBaseline', 'changedFields']) {
      const res = mockResponse();
      await updateRegistrationDraft(
        makeReq({
          params: { id },
          user: APPLICANT,
          body: { [bad]: { spoofed: true } },
        }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(400);
    }
  });
});

// ─── Resubmission change diff (server-side baseline comparison) ─────────────

describe('resubmission change diff', () => {
  let collections: Record<string, MockDoc[]>;

  const DOC_META = (field = 'registrationCertificate', name = 'a.pdf') => ({
    field,
    storagePath: `org-registrations/x/${field}/1_${name}`,
    originalName: name,
    contentType: 'application/pdf',
    size: 100,
    uploadedAt: new Date(2024, 0, 1),
  });

  beforeEach(() => {
    collections = { organizationRegistrations: [] };
    (getDb as jest.Mock).mockReturnValue(makeMockDb(collections).db);
    (getBucket as jest.Mock).mockReturnValue({});
  });

  async function changesRequestedApp() {
    const res = mockResponse();
    await createRegistrationDraft(
      makeReq({ body: validBody() }) as Request,
      res,
    );
    const { registrationId: id, resumeToken: token } = jsonBody(res);
    const doc = collections['organizationRegistrations'].find(
      (d) => d.id === id,
    )!;
    doc.data.verification = {
      orgEmail: { verified: true, target: 'hr@acme-test.example.com' },
      adminEmail: { verified: true, target: 'jane@acme-test.example.com' },
      adminMobile: { verified: true, target: '9876543210' },
    };
    doc.data.documents = {
      registrationCertificate: DOC_META(),
      authorizationLetter: DOC_META('authorizationLetter', 'auth.pdf'),
      adminIdProof: DOC_META('adminIdProof', 'id.pdf'),
    };
    doc.data.status = 'changes_requested';
    doc.data.submittedAt = new Date();
    doc.data.review = {
      reviewerId: 'rev-1',
      reviewerEmail: 'rev@serv.test',
      decidedAt: new Date(),
      decision: 'changes_requested',
      note: 'Correct employees and address',
    };
    doc.data.changeRequestBaseline = captureChangeRequestBaseline(
      doc.data as any,
    );
    return { id, token, doc };
  }

  async function doSubmit(id: string, token?: string) {
    const res = mockResponse();
    await submitRegistration(
      makeReq({
        body: { registrationId: id, declarationAccepted: true },
        resumeToken: token,
        user: APPLICANT,
      }) as Request,
      res,
    );
    return res;
  }

  async function doPatch(id: string, body: any) {
    const res = mockResponse();
    await updateRegistrationDraft(
      makeReq({ params: { id }, user: APPLICANT, body }) as Request,
      res,
    );
    return res;
  }

  it('first submission produces no changedFields', async () => {
    const res = mockResponse();
    await createRegistrationDraft(
      makeReq({ body: validBody() }) as Request,
      res,
    );
    const { registrationId: id, resumeToken: token } = jsonBody(res);
    const doc = collections['organizationRegistrations'].find(
      (d) => d.id === id,
    )!;
    doc.data.verification = {
      orgEmail: { verified: true, target: 'hr@acme-test.example.com' },
      adminEmail: { verified: true, target: 'jane@acme-test.example.com' },
      adminMobile: { verified: true, target: '9876543210' },
    };
    doc.data.documents = {
      registrationCertificate: DOC_META(),
      authorizationLetter: DOC_META('authorizationLetter'),
      adminIdProof: DOC_META('adminIdProof'),
    };
    await doSubmit(id, token);
    expect(doc.data.status).toBe('pending_approval');
    expect(doc.data.changedFields).toBeUndefined();
    expect(doc.data.resubmissionCount ?? 0).toBe(0);
  });

  it('resubmission emits old/new only for modified fields', async () => {
    const { id, token, doc } = await changesRequestedApp();
    await doPatch(id, {
      organization: {
        ...doc.data.organization,
        employeeCount: 36,
        registeredAddress: 'XYZ Street',
      },
    });
    await doSubmit(id, token);

    const cf = doc.data.changedFields;
    const fields = cf.map((c: any) => c.field);
    expect(fields).toEqual([
      'organization.employeeCount',
      'organization.registeredAddress',
    ]);
    const emp = cf.find((c: any) => c.field === 'organization.employeeCount');
    expect(emp.label).toBe('Employees');
    expect(emp.oldValue).toBe('25');
    expect(emp.newValue).toBe('36');
    const addr = cf.find(
      (c: any) => c.field === 'organization.registeredAddress',
    );
    expect(addr.oldValue).toBe('1 Test Street, Test City');
    expect(addr.newValue).toBe('XYZ Street');
  });

  it('unchanged fields never appear in the diff', async () => {
    const { id, token, doc } = await changesRequestedApp();
    await doPatch(id, {
      organization: { ...doc.data.organization, employeeCount: 36 },
    });
    await doSubmit(id, token);
    const fields = doc.data.changedFields.map((c: any) => c.field);
    expect(fields).not.toContain('organization.name');
    expect(fields).not.toContain('adminContact.email');
    expect(fields).not.toContain('requestedFeatures');
    expect(fields.some((f: string) => f.startsWith('documents.'))).toBe(false);
  });

  it('features diff reports added and removed ids', async () => {
    const { id, token, doc } = await changesRequestedApp();
    await doPatch(id, {
      requestedFeatures: ['attendance', 'payroll'],
    });
    await doSubmit(id, token);
    const feat = doc.data.changedFields.find(
      (c: any) => c.field === 'requestedFeatures',
    );
    expect(feat.added).toEqual(['payroll']);
    expect(feat.removed).toEqual(['leave_management']);
  });

  it('a replaced document is marked replaced; unchanged docs are silent', async () => {
    const { id, token, doc } = await changesRequestedApp();
    // Simulate a re-upload by swapping the stored metadata directly
    // (the upload endpoint writes new meta for the same field).
    doc.data.documents.registrationCertificate = DOC_META(
      'registrationCertificate',
      'new-cert.pdf',
    );
    await doSubmit(id, token);
    const docDiff = doc.data.changedFields.filter((c: any) =>
      c.field.startsWith('documents.'),
    );
    expect(docDiff).toHaveLength(1);
    expect(docDiff[0].field).toBe('documents.registrationCertificate');
    expect(docDiff[0].label).toBe('Registration Certificate');
    expect(docDiff[0].changeType).toBe('replaced');
  });

  it('a newly added document is marked added', async () => {
    const { id, token, doc } = await changesRequestedApp();
    doc.data.documents.gstCertificate = DOC_META('gstCertificate', 'gst.pdf');
    await doSubmit(id, token);
    const d = doc.data.changedFields.find(
      (c: any) => c.field === 'documents.gstCertificate',
    );
    expect(d.changeType).toBe('added');
  });

  it('a channel verified since the request shows as a verification change', async () => {
    const { id, token, doc } = await changesRequestedApp();
    // Baseline captured while the channel was still unverified; the
    // applicant verified it during corrections before resubmitting.
    doc.data.changeRequestBaseline.verification.adminMobile = {
      verified: false,
    };
    await doSubmit(id, token);
    const v = doc.data.changedFields.find(
      (c: any) => c.field === 'verification.adminMobile',
    );
    expect(v).toBeTruthy();
    expect(v.oldValue).toBe('Not verified');
    expect(v.newValue).toBe('Verified');
  });

  it('the diff never contains storage paths or credential material', async () => {
    const { id, token, doc } = await changesRequestedApp();
    doc.data.documents.registrationCertificate = DOC_META(
      'registrationCertificate',
      'replaced.pdf',
    );
    await doPatch(id, {
      organization: { ...doc.data.organization, employeeCount: 36 },
    });
    await doSubmit(id, token);
    const raw = JSON.stringify(doc.data.changedFields);
    expect(raw).not.toContain('storagePath');
    expect(raw).not.toContain('org-registrations/');
    expect(raw).not.toContain('resumeTokenHash');
    expect(raw).not.toContain(doc.data.resumeTokenHash);
  });

  it('a second correction cycle increments the revision and re-diffs', async () => {
    const { id, token, doc } = await changesRequestedApp();
    await doPatch(id, {
      organization: { ...doc.data.organization, employeeCount: 36 },
    });
    await doSubmit(id, token);
    expect(doc.data.resubmissionCount).toBe(1);

    // Cycle 2: reviewer requests changes again — new baseline, new review.
    doc.data.status = 'changes_requested';
    doc.data.review = {
      reviewerId: 'rev-1',
      reviewerEmail: 'rev@serv.test',
      decidedAt: new Date(),
      decision: 'changes_requested',
      note: 'One more fix',
    };
    doc.data.changeRequestBaseline = captureChangeRequestBaseline(
      doc.data as any,
    );
    await doPatch(id, {
      organization: { ...doc.data.organization, branchCount: 4 },
    });
    await doSubmit(id, token);

    expect(doc.data.resubmissionCount).toBe(2);
    const events = doc.data.auditTrail.filter(
      (a: any) => a.action === 'application_resubmitted',
    );
    expect(events).toHaveLength(2);
    expect(events[1].revision).toBe(2);
    expect(doc.data.reviewHistory).toHaveLength(2);
    // The new diff only shows cycle-2 changes (baseline was refreshed).
    const fields = doc.data.changedFields.map((c: any) => c.field);
    expect(fields).toEqual(['organization.branchCount']);
  });
});
