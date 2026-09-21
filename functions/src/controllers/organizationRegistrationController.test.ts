// functions/src/controllers/organizationRegistrationController.test.ts

import { Request, Response } from 'express';
import {
  createRegistrationDraft,
  getRegistrationDraft,
  getRegistrationStatus,
  submitRegistration,
  updateRegistrationDraft,
} from './organizationRegistrationController';

jest.mock('../config/firebase', () => ({
  getDb: jest.fn(),
  getAdminAuth: jest.fn(),
  checkFirestoreAccess: jest.fn().mockResolvedValue(true),
}));

import { getDb } from '../config/firebase';

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
  function makeDocRef(col: MockDoc[], id: string) {
    return {
      id,
      get: jest.fn(async () => {
        const doc = col.find((d) => d.id === id);
        return {
          id,
          exists: !!doc,
          data: () => (doc ? doc.data : undefined),
          ref: {
            update: jest.fn(async (updates: Record<string, any>) => {
              const target = col.find((d) => d.id === id);
              if (!target) throw new Error('NOT_FOUND');
              for (const [k, v] of Object.entries(updates)) {
                setPath(target.data, k, v);
              }
            }),
          },
        };
      }),
      set: jest.fn(async (data: any) => {
        const existing = col.find((d) => d.id === id);
        if (existing) targetMerge(existing.data, data);
        else col.push({ id, data });
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
        emailVerified: false,
        mobileVerified: false,
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
