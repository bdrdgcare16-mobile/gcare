/// <reference types="jest" />
import {
  normalizeOrgCode,
  normalizeOrgStatus,
  getCompanyProfileByCode,
  saveCompanyProfile,
} from './companyController';
import type { Request, Response } from 'express';

jest.mock('../config/firebase', () => ({
  getDb: jest.fn(),
}));

jest.mock('../services/usageService', () => ({
  trackUsage: jest.fn().mockResolvedValue(undefined),
}));

import { getDb } from '../config/firebase';

function makeFirestoreSnapshot(docs: any[]) {
  return {
    empty: docs.length === 0,
    docs: docs.map((d) => ({
      id: d.id || 'doc-id',
      data: () => d.data || {},
    })),
  };
}

function makeQuery(snap: any) {
  return {
    where: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    get: jest.fn().mockResolvedValue(snap),
  };
}

describe('organization code helpers', () => {
  test('normalizeOrgCode trims and uppercases', () => {
    expect(normalizeOrgCode(' serv001 ')).toBe('SERV001');
  });

  test('normalizeOrgCode leaves already uppercase code unchanged', () => {
    expect(normalizeOrgCode('SERV123')).toBe('SERV123');
  });

  test('normalizeOrgCode returns empty string for empty input', () => {
    expect(normalizeOrgCode('')).toBe('');
    expect(normalizeOrgCode(null)).toBe('');
    expect(normalizeOrgCode(undefined)).toBe('');
  });
});

describe('organization status helper', () => {
  test('normalizeOrgStatus returns active for missing/empty legacy status', () => {
    expect(normalizeOrgStatus(undefined)).toBe('active');
    expect(normalizeOrgStatus(null)).toBe('active');
    expect(normalizeOrgStatus('')).toBe('active');
  });

  test('normalizeOrgStatus accepts valid explicit statuses', () => {
    expect(normalizeOrgStatus('active')).toBe('active');
    expect(normalizeOrgStatus('inactive')).toBe('inactive');
    expect(normalizeOrgStatus('pending_approval')).toBe('pending_approval');
    expect(normalizeOrgStatus('suspended')).toBe('suspended');
  });

  test('normalizeOrgStatus rejects invalid explicit statuses', () => {
    expect(normalizeOrgStatus('suspendd')).toBeNull();
    expect(normalizeOrgStatus('blocked')).toBeNull();
  });

  test('normalizeOrgStatus is case-insensitive', () => {
    expect(normalizeOrgStatus('ACTIVE')).toBe('active');
    expect(normalizeOrgStatus('Inactive')).toBe('inactive');
  });
});

describe('getCompanyProfileByCode', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('returns document when code matches', async () => {
    const expectedDoc = { id: 'company-1', data: { code: 'SERV001' } };
    const query = makeQuery(makeFirestoreSnapshot([expectedDoc]));
    (getDb as jest.Mock).mockReturnValue({
      collection: jest.fn().mockReturnValue(query),
    });

    const result = await getCompanyProfileByCode('SERV001');
    expect(result).not.toBeNull();
    expect(result!.id).toBe('company-1');
  });

  test('normalizes lowercase code before querying', async () => {
    const query = makeQuery(makeFirestoreSnapshot([{ id: 'company-1' }]));
    (getDb as jest.Mock).mockReturnValue({
      collection: jest.fn().mockReturnValue(query),
    });

    await getCompanyProfileByCode('serv001');
    expect(query.where).toHaveBeenCalledWith('code', '==', 'SERV001');
  });

  test('returns null when no document matches', async () => {
    const query = makeQuery(makeFirestoreSnapshot([]));
    (getDb as jest.Mock).mockReturnValue({
      collection: jest.fn().mockReturnValue(query),
    });

    const result = await getCompanyProfileByCode('UNKNOWN');
    expect(result).toBeNull();
  });

  test('returns null for empty code', async () => {
    (getDb as jest.Mock).mockReturnValue({
      collection: jest.fn(),
    });

    const result = await getCompanyProfileByCode('  ');
    expect(result).toBeNull();
    expect(getDb).not.toHaveBeenCalled();
  });
});

// ─── saveCompanyProfile doc-key selection (generated internal companyId) ──

describe('saveCompanyProfile profile doc key', () => {
  const BASE_BODY = {
    companyName: 'Org',
    email: 'org@x.com',
    phone: '1',
    adminName: 'Admin',
    designation: 'HR',
  };

  function mockRes() {
    const res: any = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json = jest.fn().mockReturnValue(res);
    return res as Response;
  }

  /** Mock db where doc(id) records the id and code-lookup returns `codeDocs`. */
  function mockDbWithDoc(codeDocs: any[] = []) {
    const docCalls: string[] = [];
    const setCalls: Array<{ id: string; data: any }> = [];
    const db: any = {
      collection: jest.fn(() => ({
        doc: jest.fn((id: string) => {
          docCalls.push(id);
          return {
            get: jest.fn().mockResolvedValue({
              exists: false,
              data: () => ({}),
            }),
            set: jest.fn((data: any) => {
              setCalls.push({ id, data });
              return Promise.resolve({});
            }),
          };
        }),
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest
          .fn()
          .mockResolvedValue(makeFirestoreSnapshot(codeDocs)),
      })),
    };
    (getDb as jest.Mock).mockReturnValue(db);
    return { docCalls, setCalls };
  }

  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('activated org: profile doc keyed by internal companyId, not email', async () => {
    const { docCalls, setCalls } = mockDbWithDoc();
    const res = mockRes();

    await saveCompanyProfile(
      {
        user: { email: 'Admin@X.com', companyId: 'org-reg-9' },
        body: BASE_BODY,
      } as unknown as Request,
      res,
    );

    expect(docCalls).toContain('org-reg-9');
    expect(docCalls).not.toContain('admin@x.com');
    expect(setCalls[0].id).toBe('org-reg-9');
    expect(setCalls[0].data.id).toBe('org-reg-9');
    // adminEmail fields still carry the real admin email so
    // findProfileDoc() field lookups keep working.
    expect(setCalls[0].data.adminEmailLower).toBe('admin@x.com');
  });

  test('legacy org (companyId == email): identical email-keyed behavior', async () => {
    const { docCalls, setCalls } = mockDbWithDoc();
    const res = mockRes();

    await saveCompanyProfile(
      {
        user: { email: 'Admin@X.com', companyId: 'admin@x.com' },
        body: BASE_BODY,
      } as unknown as Request,
      res,
    );

    expect(docCalls).toContain('admin@x.com');
    expect(setCalls[0].id).toBe('admin@x.com');
  });

  test('missing companyId falls back to the admin email key', async () => {
    const { docCalls } = mockDbWithDoc();
    const res = mockRes();

    await saveCompanyProfile(
      {
        user: { email: 'Admin@X.com', companyId: '' },
        body: BASE_BODY,
      } as unknown as Request,
      res,
    );

    expect(docCalls).toContain('admin@x.com');
  });

  test('platform token keeps the email convention', async () => {
    const { docCalls } = mockDbWithDoc();
    const res = mockRes();

    await saveCompanyProfile(
      {
        user: { email: 'PA@X.com', companyId: 'platform' },
        body: BASE_BODY,
      } as unknown as Request,
      res,
    );

    expect(docCalls).toContain('pa@x.com');
  });

  test('unchanged own code is not reported as in-use for a generated-id org', async () => {
    // The org's own profile (doc id org-reg-9) holds SERV001 — re-saving
    // the same code must exclude itself by the real doc id, not email.
    const { docCalls } = mockDbWithDoc([
      { id: 'org-reg-9', data: { code: 'SERV001' } },
    ]);
    const res = mockRes();

    await saveCompanyProfile(
      {
        user: { email: 'admin@x.com', companyId: 'org-reg-9' },
        body: { ...BASE_BODY, code: 'SERV001' },
      } as unknown as Request,
      res,
    );

    expect(res.status).not.toHaveBeenCalledWith(409);
    expect(docCalls).toContain('org-reg-9');
  });
});
