/// <reference types="jest" />
/**
 * Integration test verifying that pre-authentication auth routes are reachable
 * without a SERV JWT while protected routes still require one.
 */

import request from 'supertest';

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
  db: mockFirebaseState.getDb,
}));

// eslint-disable-next-line import/first
import app from './app';

function makeFirestoreSnap(docs: any[]) {
  return {
    empty: docs.length === 0,
    docs: docs.map((d) => ({
      id: d.id || 'doc-id',
      data: () => d.data || {},
      ref: { set: jest.fn().mockResolvedValue(undefined) },
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

describe('/api/auth public pre-authentication routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('POST /api/auth/employee-login/validate is reachable without SERV JWT', async () => {
    mockFirebaseState.getDb.mockReturnValue({
      collection: jest.fn((name: string) => {
        if (name === 'companyProfile') {
          return makeQuery(
            makeFirestoreSnap([
              {
                id: 'company-1',
                data: { code: 'SERV001', status: 'active' },
              },
            ])
          );
        }
        if (name === 'users') {
          return makeQuery(
            makeFirestoreSnap([
              {
                id: 'user-1',
                data: {
                  email: 'emp@example.com',
                  role: 'employee',
                  status: 'active',
                  companyId: 'company-1',
                },
              },
            ])
          );
        }
        return makeQuery(makeFirestoreSnap([]));
      }),
    });

    const res = await request(app)
      .post('/api/auth/employee-login/validate')
      .send({
        organizationCode: 'SERV001',
        email: 'emp@example.com',
      });

    expect(res.status).toBe(200);
    expect(res.body.canProceed).toBe(true);
  });

  test('POST /api/auth/employee-login/validate without body does not trigger "No token provided"', async () => {
    mockFirebaseState.getDb.mockReturnValue({
      collection: jest.fn(() => makeQuery(makeFirestoreSnap([]))),
    });

    const res = await request(app)
      .post('/api/auth/employee-login/validate')
      .send({});

    expect(res.status).not.toBe(401);
    expect(res.body.message || res.body.error).not.toBe('No token provided');
  });

  test('GET /api/auth/me still requires authentication', async () => {
    const res = await request(app).get('/api/auth/me');

    expect(res.status).toBe(401);
    expect(res.body.message).toBe('No token provided');
  });
});
