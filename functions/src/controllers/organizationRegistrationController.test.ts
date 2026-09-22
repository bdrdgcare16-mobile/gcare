// functions/src/controllers/organizationRegistrationController.test.ts
/// <reference types="jest" />

import { Request, Response } from 'express';
import {
  createRegistrationDraft,
  getRegistrationDraft,
  getRegistrationStatus,
  submitRegistration,
  updateRegistrationDraft,
} from './organizationRegistrationController';

process.env.FUNCTIONS_EMULATOR = 'true';
process.env.STORAGE_EMULATOR_HOST = '127.0.0.1:9199';

jest.mock('../config/firebase', () => ({
  getDb: jest.fn(),
  getAdminAuth: jest.fn(),
  getBucket: jest.fn(),
  checkFirestoreAccess: jest.fn().mockResolvedValue(true),
}));

import { getDb, getBucket } from '../config/firebase';

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
      // Resolve FieldValue.increment sentinels so attempt counters work.
      if (v && typeof v === 'object' && typeof v.operand === 'number') {
        const cur = Number(getPath(target.data, k) || 0);
        setPath(target.data, k, cur + v.operand);
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
    },
    collections,
  };
}

function makeReq({
  body = {},
  params = {},
  resumeToken,
}: {
  body?: any;
  params?: any;
  resumeToken?: string;
}): Partial<Request> {
  return {
    body,
    params,
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
      await createRegistrationDraft(makeReq({ body: validBody() }) as Request, res);
      expect(statusCode(res)).toBe(409);
    });

    it('allows distinct organizations that share a name', async () => {
      await createDraft();
      // Same org name, different official email — a different organization
      // applicant, not a duplicate. Name collisions are resolved at review.
      const res = mockResponse();
      await createRegistrationDraft(
        makeReq({
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
          body: { registrationId: body.registrationId },
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
