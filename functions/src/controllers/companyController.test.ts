/// <reference types="jest" />
import {
  normalizeOrgCode,
  normalizeOrgStatus,
  getCompanyProfileByCode,
} from './companyController';

jest.mock('../config/firebase', () => ({
  getDb: jest.fn(),
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
