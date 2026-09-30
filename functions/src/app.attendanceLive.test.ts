/// <reference types="jest" />
/**
 * Route-level tests for the shared Live Attendance surface.
 *
 * GET /attendance/live is reachable with EITHER `attendance` OR
 * `location_tracking`; every other /attendance route stays
 * attendance-only. companyId/enabledFeatures are always derived
 * server-side — request body/query cannot grant access.
 */

import request from 'supertest';

process.env.JWT_SECRET = 'test-jwt-secret-attendance-live';

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

// eslint-disable-next-line import/first
import app from './app';
// eslint-disable-next-line import/first
import { issueToken } from './common/auth.utils';

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

const adminToken = (companyId: string) =>
  issueToken({
    userId: 'admin-1',
    email: 'admin@org.test',
    role: 'admin',
    empid: 'ADMIN001',
    companyId,
  });

let whereSpy: jest.Mock;

function installDb(profile: any | undefined) {
  whereSpy = jest.fn();
  mockFirebaseState.getDb.mockReturnValue({
    collection: jest.fn((_name: string) => {
      const q: any = {
        where: jest.fn((...args: any[]) => {
          whereSpy(...args);
          return q;
        }),
        limit: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue(makeFirestoreSnap([])),
        doc: jest.fn((_id: string) => ({
          get: jest.fn(async () => ({
            exists: profile !== undefined,
            data: () => profile,
          })),
        })),
      };
      return q;
    }),
    getAll: jest.fn().mockResolvedValue([]),
    batch: jest.fn().mockReturnValue({
      set: jest.fn(),
      commit: jest.fn().mockResolvedValue(undefined),
    }),
  });
}

describe('GET /attendance/live shared feature access', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('location_tracking only → 200', async () => {
    installDb({
      status: 'active',
      enabledFeatures: ['location_tracking'],
    });
    const res = await request(app)
      .get('/api/attendance/live')
      .set('Authorization', `Bearer ${adminToken('c1')}`);
    expect(res.status).toBe(200);
  });

  test('attendance only → 200', async () => {
    installDb({ status: 'active', enabledFeatures: ['attendance'] });
    const res = await request(app)
      .get('/api/attendance/live')
      .set('Authorization', `Bearer ${adminToken('c1')}`);
    expect(res.status).toBe(200);
  });

  test('payroll only → 403 FEATURE_NOT_ENABLED', async () => {
    installDb({ status: 'active', enabledFeatures: ['payroll'] });
    const res = await request(app)
      .get('/api/attendance/live')
      .set('Authorization', `Bearer ${adminToken('c1')}`);
    expect(res.status).toBe(403);
    expect(res.body.error).toBe('FEATURE_NOT_ENABLED');
  });

  test('empty enabledFeatures → 403', async () => {
    installDb({ status: 'active', enabledFeatures: [] });
    const res = await request(app)
      .get('/api/attendance/live')
      .set('Authorization', `Bearer ${adminToken('c1')}`);
    expect(res.status).toBe(403);
  });

  test('location_tracking does NOT unlock attendance-only routes', async () => {
    installDb({
      status: 'active',
      enabledFeatures: ['location_tracking'],
    });
    const res = await request(app)
      .get('/api/attendance/history')
      .set('Authorization', `Bearer ${adminToken('c1')}`);
    expect(res.status).toBe(403);
    expect(res.body.error).toBe('FEATURE_NOT_ENABLED');

    const res2 = await request(app)
      .post('/api/attendance/check-in')
      .set('Authorization', `Bearer ${adminToken('c1')}`)
      .send({});
    expect(res2.status).toBe(403);
  });

  test('live queries are scoped to the JWT companyId', async () => {
    installDb({
      status: 'active',
      enabledFeatures: ['location_tracking'],
    });
    const res = await request(app)
      .get('/api/attendance/live')
      .set('Authorization', `Bearer ${adminToken('c1')}`);
    expect(res.status).toBe(200);
    // Every Firestore where('companyId', '==', ...) must use the JWT
    // companyId — never another org.
    const companyFilters = whereSpy.mock.calls.filter(
      (c) => c[0] === 'companyId',
    );
    expect(companyFilters.length).toBeGreaterThan(0);
    for (const c of companyFilters) {
      expect(c[2]).toBe('c1');
    }
  });

  test('spoofed query params cannot grant access', async () => {
    installDb({ status: 'active', enabledFeatures: ['payroll'] });
    const res = await request(app)
      .get('/api/attendance/live')
      .query({ companyId: 'other', enabledFeatures: 'attendance' })
      .set('Authorization', `Bearer ${adminToken('c1')}`);
    expect(res.status).toBe(403);
    expect(res.body.error).toBe('FEATURE_NOT_ENABLED');
  });

  test('unauthenticated → 401', async () => {
    installDb({ status: 'active', enabledFeatures: ['location_tracking'] });
    const res = await request(app).get('/api/attendance/live');
    expect(res.status).toBe(401);
  });
});
