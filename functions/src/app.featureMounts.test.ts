/// <reference types="jest" />
/**
 * Route-level tests for feature-gated mounts introduced with Basic HRMS.
 *
 *  - /events        → events           (optional)
 *  - /feedback      → feedback         (Basic HRMS — always on)
 *  - /office        → attendance OR location_tracking (shared surface)
 *  - /reasons       → attendance OR leave_management (permission workflows)
 *
 * A mount gate passes when the request does NOT come back with
 * 403 FEATURE_NOT_ENABLED (inner router auth still applies).
 */

import request from 'supertest';

process.env.JWT_SECRET = 'test-jwt-secret-feature-mounts';

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

function installDb(profile: any | undefined) {
  mockFirebaseState.getDb.mockReturnValue({
    collection: jest.fn((_name: string) => {
      const q: any = {
        where: jest.fn().mockReturnThis(),
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

const BASIC = ['attendance', 'employee_master', 'feedback', 'shifts'];

async function expectFeatureBlocked(
  path: string,
  features: string[],
) {
  installDb({ status: 'active', enabledFeatures: features });
  const res = await request(app)
    .get(path)
    .set('Authorization', `Bearer ${adminToken('c1')}`);
  expect(res.status).toBe(403);
  expect(res.body.error).toBe('FEATURE_NOT_ENABLED');
}

async function expectFeatureAllowed(
  path: string,
  features: string[],
) {
  installDb({ status: 'active', enabledFeatures: features });
  const res = await request(app)
    .get(path)
    .set('Authorization', `Bearer ${adminToken('c1')}`);
  // Gate passed — the inner router may still respond with any non-gate
  // status (mocked db, controllers return 200/empty).
  expect(
    res.status === 403 && res.body?.error === 'FEATURE_NOT_ENABLED',
  ).toBe(false);
}

describe('feature-gated mounts', () => {
  beforeEach(() => jest.clearAllMocks());

  test('GET /events blocked without events feature', async () => {
    await expectFeatureBlocked('/api/events', BASIC);
  });

  test('GET /events allowed with events enabled', async () => {
    await expectFeatureAllowed('/api/events', [...BASIC, 'events']);
  });

  test('GET /feedback allowed on Basic HRMS (feedback is core)', async () => {
    await expectFeatureAllowed('/api/feedback', BASIC);
  });

  test('GET /office/locations allowed with attendance (basic)', async () => {
    await expectFeatureAllowed('/api/office/locations', BASIC);
  });

  test('GET /office/locations allowed with location_tracking', async () => {
    await expectFeatureAllowed('/api/office/locations', [
      'location_tracking',
    ]);
  });

  test('GET /office/locations blocked with neither attendance nor tracking',
    async () => {
      await expectFeatureBlocked('/api/office/locations', ['payroll']);
    });

  test('GET /reasons/types allowed with attendance (basic)', async () => {
    await expectFeatureAllowed('/api/reasons/types', BASIC);
  });

  test('GET /reasons/types allowed with leave_management only', async () => {
    await expectFeatureAllowed('/api/reasons/types', ['leave_management']);
  });

  test('GET /reasons/types blocked with neither attendance nor leave',
    async () => {
      await expectFeatureBlocked('/api/reasons/types', ['payroll']);
    });

  test('GET /payroll blocked on Basic HRMS (payroll stays optional)',
    async () => {
      await expectFeatureBlocked('/api/payroll/summary', BASIC);
    });

  test('unauthenticated gated mount → 401', async () => {
    installDb({ status: 'active', enabledFeatures: BASIC });
    const res = await request(app).get('/api/events');
    expect(res.status).toBe(401);
  });
});
