// functions/src/controllers/platformAdminRegistrationController.test.ts
/// <reference types="jest" />

import { Request, Response, NextFunction } from 'express';

process.env.FUNCTIONS_EMULATOR = 'true';
process.env.STORAGE_EMULATOR_HOST = '127.0.0.1:9199';
process.env.JWT_SECRET = 'test-jwt-secret-for-3db';

jest.mock('../config/firebase', () => ({
  getDb: jest.fn(),
  getAdminAuth: jest.fn(),
  getBucket: jest.fn(),
  checkFirestoreAccess: jest.fn().mockResolvedValue(true),
}));

import { getDb, getBucket } from '../config/firebase';
import {
  approveRegistration,
  getRegistrationDocumentForReview,
  getRegistrationForReview,
  listRegistrations,
  rejectRegistration,
  requestRegistrationChanges,
} from './platformAdminRegistrationController';
import {
  authMiddleware,
  roleMiddleware,
} from '../middlewares/authMiddleware';

// ---------- Helpers ----------

function mockResponse() {
  const res: Partial<Response> = {
    status: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis(),
    setHeader: jest.fn().mockReturnThis(),
    send: jest.fn().mockReturnThis(),
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

/**
 * In-memory Firestore mock extended for the review list query:
 * where() equality filters, orderBy on a stored field, offset/limit.
 */
function makeMockDb(collections: Record<string, MockDoc[]>) {
  /**
   * Applies a partial update the way Firestore does for the shapes this
   * controller writes: FieldValue.arrayUnion appends, other FieldValue
   * sentinels (serverTimestamp/increment) become a Date stub, plain values
   * overwrite. Nested objects (e.g. `review`) are written whole.
   */
  function applyUpdate(data: any, updates: Record<string, any>) {
    for (const [k, v] of Object.entries(updates)) {
      if (v && Array.isArray((v as any).elements)) {
        // FieldValue.arrayUnion sentinel (ArrayUnionTransform).
        data[k] = [
          ...(Array.isArray(data[k]) ? data[k] : []),
          ...(v as any).elements,
        ];
      } else if (
        v &&
        v.constructor &&
        /FieldValue|Transform/.test(v.constructor.name)
      ) {
        data[k] = new Date();
      } else {
        data[k] = v;
      }
    }
  }

  function makeDocRef(col: MockDoc[], id: string) {
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
      update: jest.fn(async (updates: Record<string, any>) => {
        const doc = col.find((d) => d.id === id);
        if (!doc) throw new Error('No document to update');
        applyUpdate(doc.data, updates);
      }),
    };
  }

  // Transaction mock: tx.get/tx.update operate on the same in-memory doc
  // so the controller's re-read-inside-transaction sees current state.
  function makeTx() {
    return {
      get: jest.fn(async (ref: any) => ref.get()),
      update: jest.fn((ref: any, updates: Record<string, any>) =>
        ref.update(updates),
      ),
    };
  }

  function makeQuery(
    col: MockDoc[],
    filters: Array<[string, any]> = [],
    orderField?: string,
    orderDir: 'asc' | 'desc' = 'asc',
    off = 0,
    lim?: number,
  ) {
    const q: any = {
      where: jest.fn((field: string, _op: string, value: any) =>
        makeQuery(col, [...filters, [field, value]], orderField, orderDir, off, lim)),
      orderBy: jest.fn((field: string, dir: 'asc' | 'desc' = 'asc') =>
        makeQuery(col, filters, field, dir, off, lim)),
      offset: jest.fn((n: number) =>
        makeQuery(col, filters, orderField, orderDir, n, lim)),
      limit: jest.fn((n: number) =>
        makeQuery(col, filters, orderField, orderDir, off, n)),
      get: jest.fn(async () => {
        // Firestore orderBy implicitly excludes docs missing the field.
        let matched = col.filter((d) =>
          filters.every(([f, v]) => getPath(d.data, f) === v),
        );
        if (orderField) {
          matched = matched.filter(
            (d) => getPath(d.data, orderField) !== undefined,
          );
          matched.sort((a, b) => {
            const av = getPath(a.data, orderField);
            const bv = getPath(b.data, orderField);
            const cmp =
              av instanceof Date && bv instanceof Date
                ? av.getTime() - bv.getTime()
                : String(av).localeCompare(String(bv));
            return orderDir === 'desc' ? -cmp : cmp;
          });
        }
        if (off) matched = matched.slice(off);
        if (lim !== undefined) matched = matched.slice(0, lim);
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
    collection: jest.fn((name: string) => {
      const col = collections[name] || (collections[name] = []);
      return makeQuery(col);
    }),
    runTransaction: jest.fn(async (fn: (tx: any) => any) => fn(makeTx())),
  };
}

function makeReq({
  params = {},
  query = {},
  headers = {},
  body = {},
  user = undefined,
}: {
  params?: any;
  query?: any;
  headers?: Record<string, string>;
  body?: any;
  user?: any;
}): Partial<Request> {
  return {
    params,
    query,
    body,
    user,
    ip: '127.0.0.1',
    headers,
    header: (name: string) => headers[name.toLowerCase()],
  } as any;
}

const PA_USER = { userId: 'pa1', email: 'pa@x.com', role: 'platform_admin' };

function docData(
  collections: Record<string, MockDoc[]>,
  id: string,
): any {
  return collections['organizationRegistrations'].find((d) => d.id === id)!
    .data;
}

let regSeq = 0;
function seedRegistration(
  collections: Record<string, MockDoc[]>,
  overrides: any = {},
): string {
  regSeq += 1;
  const id = overrides.id ?? `reg-${regSeq}`;
  const col =
    collections['organizationRegistrations'] ||
    (collections['organizationRegistrations'] = []);
  col.push({
    id,
    data: {
      applicationId: id,
      status: 'pending_approval',
      organization: {
        name: `Org ${regSeq}`,
        nameLower: `org ${regSeq}`,
        type: 'Private Limited',
        industry: 'IT',
        employeeCount: 10,
        branchCount: 1,
        registeredAddress: '1 St',
        officialEmail: `hr${regSeq}@org.example.com`,
        officialEmailLower: `hr${regSeq}@org.example.com`,
        contactNumber: '+91 80 1111 2222',
      },
      requestedFeatures: ['attendance', 'leave_management'],
      adminContact: {
        fullName: `Admin ${regSeq}`,
        designation: 'HR Manager',
        email: `admin${regSeq}@org.example.com`,
        emailLower: `admin${regSeq}@org.example.com`,
        mobile: '9876543210',
      },
      currentStep: 5,
      maxCompletedStep: 5,
      resumeTokenHash: 'a'.repeat(64),
      verification: {
        orgEmail: { verified: true, target: `hr${regSeq}@org.example.com` },
        adminEmail: { verified: true, target: `admin${regSeq}@org.example.com` },
        adminMobile: { verified: true, target: '9876543210' },
      },
      documents: {
        registrationCertificate: {
          field: 'registrationCertificate',
          storagePath: `org-registrations/${id}/registrationCertificate/f.pdf`,
          originalName: 'cert.pdf',
          contentType: 'application/pdf',
          size: 5,
          uploadedAt: new Date(),
        },
      },
      auditTrail: [
        { at: new Date(), action: 'draft_created', actor: 'applicant' },
        { at: new Date(), action: 'submitted', actor: 'applicant' },
      ],
      submittedAt: new Date(2024, 0, regSeq),
      declarationAccepted: true,
      declarationAcceptedAt: new Date(),
      createdAt: new Date(2024, 0, regSeq),
      updatedAt: new Date(2024, 0, regSeq),
      expiresAt: new Date(Date.now() + 86400000),
      ...overrides,
    },
  });
  return id;
}

// ---------- Tests ----------

describe('platformAdminRegistrationController (3D-B)', () => {
  let collections: Record<string, MockDoc[]>;

  beforeEach(() => {
    collections = {};
    regSeq = 0;
    (getDb as jest.Mock).mockReturnValue(makeMockDb(collections));
    (getBucket as jest.Mock).mockReturnValue({
      file: (p: string) => ({
        download: jest.fn(async () => [Buffer.from(`PDF:${p}`)]),
      }),
    });
  });

  describe('route protection (middleware chain)', () => {
    const guard = roleMiddleware(['platform_admin']);
    const next: NextFunction = jest.fn();

    beforeEach(() => (next as jest.Mock).mockClear());

    it('rejects an unauthenticated caller (401)', () => {
      const res = mockResponse();
      guard(makeReq({}) as Request, res, next);
      expect(statusCode(res)).toBe(401);
      expect(next).not.toHaveBeenCalled();
    });

    it('rejects an employee JWT (403)', () => {
      const res = mockResponse();
      const req = makeReq({}) as Request;
      req.user = { userId: 'u1', email: 'e@x.com', role: 'employee' };
      guard(req, res, next);
      expect(statusCode(res)).toBe(403);
      expect(next).not.toHaveBeenCalled();
    });

    it('rejects an organization admin JWT (403)', () => {
      const res = mockResponse();
      const req = makeReq({}) as Request;
      req.user = { userId: 'u2', email: 'a@x.com', role: 'admin' };
      guard(req, res, next);
      expect(statusCode(res)).toBe(403);
      expect(next).not.toHaveBeenCalled();
    });

    it('rejects a mobile super_admin JWT (403) — portal uses platform_admin', () => {
      const res = mockResponse();
      const req = makeReq({}) as Request;
      req.user = { userId: 'sa1', email: 'sa@x.com', role: 'super_admin' };
      guard(req, res, next);
      expect(statusCode(res)).toBe(403);
      expect(next).not.toHaveBeenCalled();
    });

    it('admits a platform_admin JWT', () => {
      const res = mockResponse();
      const req = makeReq({}) as Request;
      req.user = { userId: 'pa1', email: 'pa@x.com', role: 'platform_admin' };
      guard(req, res, next);
      expect(next).toHaveBeenCalled();
    });

    it('an applicant resume token is not a JWT and fails authMiddleware', async () => {
      const res = mockResponse();
      await authMiddleware(
        makeReq({
          headers: {
            authorization: 'Bearer some-applicant-resume-token-not-a-jwt',
          },
        }) as Request,
        res,
        jest.fn(),
      );
      // jwt.verify fails → 403; either way the caller never reaches a handler.
      expect(statusCode(res)).toBe(403);
    });
  });

  describe('GET / list', () => {
    it('lists registrations ordered by createdAt desc', async () => {
      seedRegistration(collections, { id: 'r1' });
      seedRegistration(collections, { id: 'r2' });
      const res = mockResponse();
      await listRegistrations(makeReq({}) as Request, res);
      expect(statusCode(res)).toBe(200);
      const body = jsonBody(res);
      expect(body.registrations).toHaveLength(2);
      expect(body.registrations[0].registrationId).toBe('r2');
      expect(body.registrations[0].organizationName).toBe('Org 2');
      expect(body.registrations[0].adminContact.fullName).toBe('Admin 2');
      expect(body.hasMore).toBe(false);
    });

    it('filters by status', async () => {
      seedRegistration(collections, { id: 'r1', status: 'pending_approval' });
      seedRegistration(collections, { id: 'r2', status: 'draft' });
      const res = mockResponse();
      await listRegistrations(
        makeReq({ query: { status: 'pending_approval' } }) as Request,
        res,
      );
      const body = jsonBody(res);
      expect(body.registrations).toHaveLength(1);
      expect(body.registrations[0].registrationId).toBe('r1');
    });

    it('rejects an invalid status filter', async () => {
      const res = mockResponse();
      await listRegistrations(
        makeReq({ query: { status: 'not-a-status' } }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(400);
    });

    it('paginates with page/pageSize and hasMore', async () => {
      for (let i = 0; i < 5; i++) seedRegistration(collections);
      const res1 = mockResponse();
      await listRegistrations(
        makeReq({ query: { page: '1', pageSize: '2' } }) as Request,
        res1,
      );
      expect(jsonBody(res1).registrations).toHaveLength(2);
      expect(jsonBody(res1).hasMore).toBe(true);

      const res3 = mockResponse();
      await listRegistrations(
        makeReq({ query: { page: '3', pageSize: '2' } }) as Request,
        res3,
      );
      expect(jsonBody(res3).registrations).toHaveLength(1);
      expect(jsonBody(res3).hasMore).toBe(false);
    });

    it('never leaks credential fields in list items', async () => {
      seedRegistration(collections);
      const res = mockResponse();
      await listRegistrations(makeReq({}) as Request, res);
      const item = jsonBody(res).registrations[0];
      expect(JSON.stringify(item)).not.toContain('resumeTokenHash');
      expect(JSON.stringify(item)).not.toContain('storagePath');
    });
  });

  describe('GET /:id detail', () => {
    it('returns the full application minus credentials', async () => {
      const id = seedRegistration(collections);
      const res = mockResponse();
      await getRegistrationForReview(
        makeReq({ params: { id } }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(200);
      const reg = jsonBody(res).registration;
      expect(reg.organization.name).toBe('Org 1');
      expect(reg.requestedFeatures).toEqual(['attendance', 'leave_management']);
      expect(reg.verification.orgEmail.verified).toBe(true);
      expect(reg.documents.registrationCertificate.originalName).toBe('cert.pdf');
      expect(reg.auditTrail).toHaveLength(2);
      expect(reg.submittedAt).toBeTruthy();
      // Credential/internal fields must not be exposed.
      expect(JSON.stringify(reg)).not.toContain('resumeTokenHash');
      expect(JSON.stringify(reg)).not.toContain('storagePath');
    });

    it('returns 404 for an unknown registration', async () => {
      const res = mockResponse();
      await getRegistrationForReview(
        makeReq({ params: { id: 'nope' } }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(404);
    });
  });

  describe('GET /:id/documents/:field', () => {
    it('streams the private document for an allowed field', async () => {
      const id = seedRegistration(collections);
      const res = mockResponse();
      await getRegistrationDocumentForReview(
        makeReq({
          params: { id, field: 'registrationCertificate' },
        }) as Request,
        res,
      );
      expect((res.setHeader as jest.Mock)).toHaveBeenCalledWith(
        'Content-Type',
        'application/pdf',
      );
      expect((res.send as jest.Mock)).toHaveBeenCalled();
    });

    it('rejects an invalid document field', async () => {
      const id = seedRegistration(collections);
      const res = mockResponse();
      await getRegistrationDocumentForReview(
        makeReq({ params: { id, field: 'evilField' } }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(400);
    });

    it('returns 404 when the document was not uploaded', async () => {
      const id = seedRegistration(collections);
      const res = mockResponse();
      await getRegistrationDocumentForReview(
        makeReq({ params: { id, field: 'adminIdProof' } }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(404);
    });

    it('returns 404 for an unknown registration', async () => {
      const res = mockResponse();
      await getRegistrationDocumentForReview(
        makeReq({
          params: { id: 'missing', field: 'registrationCertificate' },
        }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(404);
    });
  });

  describe('POST review decisions (3D-C)', () => {
    it('platform_admin approves a pending application', async () => {
      const id = seedRegistration(collections);
      const res = mockResponse();
      await approveRegistration(
        makeReq({
          params: { id },
          user: PA_USER,
          body: { comment: 'Looks good' },
        }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(200);
      expect(jsonBody(res).status).toBe('approved');

      const d = docData(collections, id);
      expect(d.status).toBe('approved');
      expect(d.reviewedBy).toBe('pa1');
      expect(d.reviewerRole).toBe('platform_admin');
      expect(d.reviewedAt).toBeTruthy();
      expect(d.review.decision).toBe('approved');
      expect(d.review.reviewerId).toBe('pa1');
      expect(d.reviewComment).toBe('Looks good');
      expect(d.auditTrail).toHaveLength(3);
      expect(d.auditTrail[2].action).toBe('application_approved');
      // 3D-C boundary — approval never provisions.
      expect(d.organizationCode).toBeUndefined();
      expect(d.approvedCompanyId).toBeUndefined();
      expect(d.approvedFeatures).toBeUndefined();
      expect(collections['companies'] ?? []).toHaveLength(0);
      expect(collections['companyProfile'] ?? []).toHaveLength(0);
      expect(collections['users'] ?? []).toHaveLength(0);
    });

    it('platform_admin rejects a pending application with a reason', async () => {
      const id = seedRegistration(collections);
      const res = mockResponse();
      await rejectRegistration(
        makeReq({
          params: { id },
          user: PA_USER,
          body: { reason: 'Documents illegible' },
        }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(200);
      const d = docData(collections, id);
      expect(d.status).toBe('rejected');
      expect(d.reviewReason).toBe('Documents illegible');
      expect(d.review.reasons).toEqual(['Documents illegible']);
      expect(d.reviewedBy).toBe('pa1');
      expect(d.auditTrail[2].action).toBe('application_rejected');
      // Application + documents are preserved, never deleted.
      expect(d.documents.registrationCertificate).toBeTruthy();
    });

    it('platform_admin requests changes with a message', async () => {
      const id = seedRegistration(collections);
      const res = mockResponse();
      await requestRegistrationChanges(
        makeReq({
          params: { id },
          user: PA_USER,
          body: { message: 'Please re-upload the authorization letter' },
        }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(200);
      const d = docData(collections, id);
      expect(d.status).toBe('changes_requested');
      expect(d.changeRequestMessage).toBe(
        'Please re-upload the authorization letter',
      );
      expect(d.review.note).toBe('Please re-upload the authorization letter');
      expect(d.auditTrail[2].action).toBe('changes_requested');
      // Submitted data / verification / documents are not cleared.
      expect(d.verification.orgEmail.verified).toBe(true);
      expect(d.documents.registrationCertificate).toBeTruthy();
      expect(d.submittedAt).toBeTruthy();
    });

    it('reject without a reason returns 400 and writes nothing', async () => {
      const id = seedRegistration(collections);
      const res = mockResponse();
      await rejectRegistration(
        makeReq({ params: { id }, user: PA_USER, body: {} }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(400);
      expect(docData(collections, id).status).toBe('pending_approval');
      expect(docData(collections, id).auditTrail).toHaveLength(2);
    });

    it('request-changes without a message returns 400', async () => {
      const id = seedRegistration(collections);
      const res = mockResponse();
      await requestRegistrationChanges(
        makeReq({ params: { id }, user: PA_USER, body: {} }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(400);
      expect(docData(collections, id).status).toBe('pending_approval');
    });

    it.each([
      ['employee', { userId: 'e1', email: 'e@x.com', role: 'employee' }],
      ['org_admin', { userId: 'a1', email: 'a@x.com', role: 'admin' }],
      ['super_admin', { userId: 's1', email: 's@x.com', role: 'super_admin' }],
    ])('%s caller is forbidden from approve (403)', async (_label, user) => {
      const id = seedRegistration(collections);
      const res = mockResponse();
      await approveRegistration(
        makeReq({ params: { id }, user }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(403);
      expect(docData(collections, id).status).toBe('pending_approval');
    });

    it('caller with no authenticated identity is rejected (403)', async () => {
      const id = seedRegistration(collections);
      const res = mockResponse();
      await approveRegistration(
        makeReq({ params: { id } }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(403);
    });

    it('a tampered JWT fails authMiddleware', async () => {
      const jwt = require('jsonwebtoken');
      const forged = jwt.sign(
        { userId: 'evil', role: 'platform_admin' },
        'wrong-secret',
      );
      const res = mockResponse();
      await authMiddleware(
        makeReq({
          headers: { authorization: `Bearer ${forged}` },
        }) as Request,
        res,
        jest.fn(),
      );
      expect(statusCode(res)).toBe(403);
    });

    it('reviewer identity is never taken from the request body', async () => {
      const id = seedRegistration(collections);
      const res = mockResponse();
      await approveRegistration(
        makeReq({
          params: { id },
          user: PA_USER,
          body: {
            comment: 'ok',
            role: 'super_admin',
            reviewedBy: 'spoofed-uid',
            reviewerId: 'spoofed-uid',
          },
        }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(200);
      const d = docData(collections, id);
      expect(d.reviewedBy).toBe('pa1');
      expect(d.reviewerRole).toBe('platform_admin');
      expect(d.review.reviewerId).toBe('pa1');
    });

    it('approve on a missing registration returns 404', async () => {
      const res = mockResponse();
      await approveRegistration(
        makeReq({ params: { id: 'nope' }, user: PA_USER }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(404);
    });

    it('decision on a draft returns 409 (invalid transition)', async () => {
      const id = seedRegistration(collections, { status: 'draft' });
      const res = mockResponse();
      await approveRegistration(
        makeReq({ params: { id }, user: PA_USER }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(409);
      expect(docData(collections, id).status).toBe('draft');
    });

    it('an already-approved application cannot be approved again (409)', async () => {
      const id = seedRegistration(collections, { status: 'approved' });
      const res = mockResponse();
      await approveRegistration(
        makeReq({ params: { id }, user: PA_USER }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(409);
    });

    it('approved cannot be rejected (409)', async () => {
      const id = seedRegistration(collections, { status: 'approved' });
      const res = mockResponse();
      await rejectRegistration(
        makeReq({
          params: { id },
          user: PA_USER,
          body: { reason: 'too late' },
        }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(409);
      expect(docData(collections, id).status).toBe('approved');
    });

    it('rejected cannot be re-approved (409)', async () => {
      const id = seedRegistration(collections, { status: 'rejected' });
      const res = mockResponse();
      await approveRegistration(
        makeReq({ params: { id }, user: PA_USER }) as Request,
        res,
      );
      expect(statusCode(res)).toBe(409);
    });

    it('concurrent decisions: the second reviewer loses (409), audit written once', async () => {
      const id = seedRegistration(collections);
      const resA = mockResponse();
      await approveRegistration(
        makeReq({ params: { id }, user: PA_USER }) as Request,
        resA,
      );
      expect(statusCode(resA)).toBe(200);

      // Reviewer B's reject now re-reads 'approved' inside the txn → 409.
      const resB = mockResponse();
      await rejectRegistration(
        makeReq({
          params: { id },
          user: { userId: 'pa2', email: 'pb@x.com', role: 'platform_admin' },
          body: { reason: 'conflicting opinion' },
        }) as Request,
        resB,
      );
      expect(statusCode(resB)).toBe(409);

      const d = docData(collections, id);
      expect(d.status).toBe('approved');
      const decisionEvents = d.auditTrail.filter((e: any) =>
        ['application_approved', 'application_rejected', 'changes_requested'].includes(e.action),
      );
      expect(decisionEvents).toHaveLength(1);
      expect(decisionEvents[0].action).toBe('application_approved');
    });

    it('decision response carries no sensitive fields', async () => {
      const id = seedRegistration(collections);
      const res = mockResponse();
      await approveRegistration(
        makeReq({ params: { id }, user: PA_USER }) as Request,
        res,
      );
      const body = JSON.stringify(jsonBody(res));
      expect(body).not.toContain('resumeTokenHash');
      expect(body).not.toContain('storagePath');
    });
  });
});

// ─── Resubmission review context: baseline capture + projections ────────────

describe('resubmission review context (change diff)', () => {
  let collections: Record<string, MockDoc[]>;

  beforeEach(() => {
    collections = { organizationRegistrations: [] };
    regSeq = 0;
    (getDb as jest.Mock).mockReturnValue(makeMockDb(collections));
    (getBucket as jest.Mock).mockReturnValue({});
  });

  it('request-changes captures a sanitized changeRequestBaseline', async () => {
    const id = seedRegistration(collections);
    const res = mockResponse();
    await requestRegistrationChanges(
      makeReq({
        params: { id },
        user: PA_USER,
        body: { message: 'Fix employees and address' },
      }) as Request,
      res,
    );
    expect(statusCode(res)).toBe(200);

    const d = docData(collections, id);
    const b = d.changeRequestBaseline;
    expect(b).toBeTruthy();
    expect(b.organization.name).toBe('Org 1');
    expect(b.organization.employeeCount).toBe(10);
    expect(b.requestedFeatures).toEqual(['attendance', 'leave_management']);
    expect(b.adminContact.fullName).toBe('Admin 1');
    expect(b.verification.orgEmail).toEqual({ verified: true });
    expect(b.documents.registrationCertificate.originalName).toBe('cert.pdf');
    expect(b.capturedAt).toBeTruthy();
  });

  it('baseline never contains secrets, storage paths, or credential material', async () => {
    const id = seedRegistration(collections);
    await requestRegistrationChanges(
      makeReq({
        params: { id },
        user: PA_USER,
        body: { message: 'fix it' },
      }) as Request,
      mockResponse(),
    );
    const raw = JSON.stringify(docData(collections, id).changeRequestBaseline);
    expect(raw).not.toContain('storagePath');
    expect(raw).not.toContain('resumeTokenHash');
    expect(raw).not.toContain('org-registrations/');
    // Derived/internal fields are excluded too.
    expect(raw).not.toContain('nameLower');
    expect(raw).not.toContain('emailLower');
  });

  it('approve and reject do NOT capture a baseline', async () => {
    const idA = seedRegistration(collections);
    const idB = seedRegistration(collections);
    await approveRegistration(
      makeReq({ params: { id: idA }, user: PA_USER }) as Request,
      mockResponse(),
    );
    await rejectRegistration(
      makeReq({
        params: { id: idB },
        user: PA_USER,
        body: { reason: 'no' },
      }) as Request,
      mockResponse(),
    );
    expect(docData(collections, idA).changeRequestBaseline).toBeUndefined();
    expect(docData(collections, idB).changeRequestBaseline).toBeUndefined();
  });

  it('first submission has no resubmission marker in list items', async () => {
    seedRegistration(collections);
    const res = mockResponse();
    await listRegistrations(
      makeReq({ user: PA_USER }) as Request,
      res,
    );
    const item = jsonBody(res).registrations[0];
    expect(item.resubmissionCount).toBe(0);
    expect(item.resubmittedAt).toBeNull();
    expect(item.changedFieldsCount).toBe(0);
  });

  it('list item exposes resubmissionCount and changedFieldsCount', async () => {
    seedRegistration(collections, {
      resubmissionCount: 1,
      resubmittedAt: new Date(),
      changedFields: [
        { field: 'organization.employeeCount', label: 'Employees', changeType: 'modified', oldValue: '10', newValue: '36' },
        { field: 'documents.gstCertificate', label: 'GST Certificate', changeType: 'added' },
      ],
    });
    const res = mockResponse();
    await listRegistrations(
      makeReq({ user: PA_USER, query: { status: 'pending_approval' } }) as Request,
      res,
    );
    const item = jsonBody(res).registrations[0];
    expect(item.resubmissionCount).toBe(1);
    expect(item.changedFieldsCount).toBe(2);
    expect(item.resubmittedAt).toBeTruthy();
  });

  it('detail exposes changedFields and reviewHistory without internals', async () => {
    const id = seedRegistration(collections, {
      resubmissionCount: 1,
      resubmittedAt: new Date(),
      changedFields: [
        {
          field: 'organization.registeredAddress',
          label: 'Registered Address',
          changeType: 'modified',
          oldValue: '1 St',
          newValue: '9 Avenue',
        },
      ],
      reviewHistory: [
        {
          reviewerId: 'pa1',
          reviewerEmail: 'pa@x.com',
          decidedAt: new Date(),
          decision: 'changes_requested',
          note: 'Fix employees and address',
        },
      ],
    });
    const res = mockResponse();
    await getRegistrationForReview(
      makeReq({ params: { id }, user: PA_USER }) as Request,
      res,
    );
    const reg = jsonBody(res).registration;
    expect(reg.resubmissionCount).toBe(1);
    expect(reg.changedFields).toHaveLength(1);
    expect(reg.changedFields[0].oldValue).toBe('1 St');
    expect(reg.changedFields[0].newValue).toBe('9 Avenue');
    expect(reg.reviewHistory[0].note).toBe('Fix employees and address');
    expect(reg.reviewHistory[0].reviewerEmail).toBe('pa@x.com');
    // No baseline or credential internals in the projection.
    const raw = JSON.stringify(reg);
    expect(raw).not.toContain('changeRequestBaseline');
    expect(raw).not.toContain('resumeTokenHash');
    expect(raw).not.toContain('storagePath');
    expect(raw).not.toContain('reviewerId');
  });
});
