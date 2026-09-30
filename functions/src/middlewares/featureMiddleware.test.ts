// functions/src/middlewares/featureMiddleware.test.ts
/// <reference types="jest" />

import { Request, Response } from 'express';

process.env.FUNCTIONS_EMULATOR = 'true';
process.env.JWT_SECRET = 'test-jwt-secret-features';

jest.mock('../config/firebase', () => ({
  getDb: jest.fn(),
  checkFirestoreAccess: jest.fn().mockResolvedValue(true),
}));

import { getDb } from '../config/firebase';
import { requireAnyFeature, requireFeature } from './featureMiddleware';

function mockResponse() {
  const res: Partial<Response> = {
    status: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis(),
  };
  return res as Response;
}

const statusCode = (res: Response) =>
  (res.status as jest.Mock).mock.calls[0]?.[0];
const jsonBody = (res: Response) =>
  (res.json as jest.Mock).mock.calls[0]?.[0];

function mockDbWithProfile(profile: any | undefined) {
  (getDb as jest.Mock).mockReturnValue({
    collection: jest.fn().mockReturnValue({
      doc: jest.fn().mockReturnValue({
        get: jest.fn(async () => ({
          exists: profile !== undefined,
          data: () => profile,
        })),
      }),
    }),
  });
}

const reqWith = (user?: any) => ({ user }) as Request;

describe('requireFeature', () => {
  const next = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('rejects unauthenticated requests (401)', async () => {
    const res = mockResponse();
    await requireFeature('payroll')(reqWith(), res, next);
    expect(statusCode(res)).toBe(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('allows when the organization enabledFeatures contains the feature', async () => {
    mockDbWithProfile({
      status: 'active',
      enabledFeatures: ['employee_master', 'attendance'],
    });
    const res = mockResponse();
    await requireFeature('employee_master')(
      reqWith({ userId: 'u1', email: 'a@x.com', role: 'admin', companyId: 'c1' }),
      res,
      next,
    );
    expect(next).toHaveBeenCalled();
  });

  it('denies a disabled feature (403 FEATURE_NOT_ENABLED)', async () => {
    mockDbWithProfile({
      status: 'active',
      enabledFeatures: ['employee_master'],
    });
    const res = mockResponse();
    await requireFeature('payroll')(
      reqWith({ userId: 'u1', email: 'a@x.com', role: 'admin', companyId: 'c1' }),
      res,
      next,
    );
    expect(statusCode(res)).toBe(403);
    expect(jsonBody(res).error).toBe('FEATURE_NOT_ENABLED');
    expect(next).not.toHaveBeenCalled();
  });

  it('denies disabled features for employees too (403)', async () => {
    mockDbWithProfile({
      status: 'active',
      enabledFeatures: ['employee_master'],
    });
    const res = mockResponse();
    await requireFeature('attendance')(
      reqWith({
        userId: 'e1',
        email: 'e@x.com',
        role: 'employee',
        companyId: 'c1',
      }),
      res,
      next,
    );
    expect(statusCode(res)).toBe(403);
    expect(next).not.toHaveBeenCalled();
  });

  it('scopes the check to the caller companyId — another org\u2019s features are irrelevant', async () => {
    // company 'other' has payroll enabled; caller belongs to 'c1'.
    mockDbWithProfile({ status: 'active', enabledFeatures: ['payroll'] });
    const res = mockResponse();
    const docGet = jest.fn();
    (getDb as jest.Mock).mockReturnValue({
      collection: jest.fn().mockReturnValue({
        doc: (id: string) => {
          docGet(id);
          return {
            get: async () => ({
              exists: id === 'other',
              data: () =>
                id === 'other'
                  ? { status: 'active', enabledFeatures: ['payroll'] }
                  : { status: 'active', enabledFeatures: ['employee_master'] },
            }),
          };
        },
      }),
    });
    await requireFeature('payroll')(
      reqWith({ userId: 'u1', email: 'a@x.com', role: 'admin', companyId: 'c1' }),
      res,
      next,
    );
    expect(docGet).toHaveBeenCalledWith('c1');
    expect(statusCode(res)).toBe(403);
    expect(next).not.toHaveBeenCalled();
  });

  it('denies when enabledFeatures is present but empty', async () => {
    mockDbWithProfile({ status: 'active', enabledFeatures: [] });
    const res = mockResponse();
    await requireFeature('employee_master')(
      reqWith({ userId: 'u1', email: 'a@x.com', role: 'admin', companyId: 'c1' }),
      res,
      next,
    );
    expect(statusCode(res)).toBe(403);
  });

  it('allows legacy organizations without an enabledFeatures field', async () => {
    mockDbWithProfile({ status: 'active', companyName: 'Legacy' });
    const res = mockResponse();
    await requireFeature('payroll')(
      reqWith({ userId: 'u1', email: 'a@x.com', role: 'admin', companyId: 'c1' }),
      res,
      next,
    );
    expect(next).toHaveBeenCalled();
  });

  it('denies when the organization profile does not exist', async () => {
    mockDbWithProfile(undefined);
    const res = mockResponse();
    await requireFeature('payroll')(
      reqWith({ userId: 'u1', email: 'a@x.com', role: 'admin', companyId: 'c1' }),
      res,
      next,
    );
    expect(statusCode(res)).toBe(403);
  });

  it('denies when the organization is not active (403 ORGANIZATION_INACTIVE)', async () => {
    mockDbWithProfile({
      status: 'suspended',
      enabledFeatures: ['payroll'],
    });
    const res = mockResponse();
    await requireFeature('payroll')(
      reqWith({ userId: 'u1', email: 'a@x.com', role: 'admin', companyId: 'c1' }),
      res,
      next,
    );
    expect(statusCode(res)).toBe(403);
    expect(jsonBody(res).error).toBe('ORGANIZATION_INACTIVE');
  });

  it.each(['platform_admin', 'super_admin'])(
    'bypasses %s (not organization-scoped)',
    async (role) => {
      const res = mockResponse();
      await requireFeature('payroll')(
        reqWith({
          userId: 'p1',
          email: 'p@x.com',
          role,
          companyId: 'platform',
        }),
        res,
        next,
      );
      expect(next).toHaveBeenCalled();
    },
  );

  it('denies when the token carries no companyId', async () => {
    const res = mockResponse();
    await requireFeature('payroll')(
      reqWith({ userId: 'u1', email: 'a@x.com', role: 'admin' }),
      res,
      next,
    );
    expect(statusCode(res)).toBe(403);
  });
});

describe('requireAnyFeature', () => {
  const next = jest.fn();
  const LIVE_FEATURES = ['attendance', 'location_tracking'];

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('allows when `location_tracking` is enabled (shared Live Attendance)', async () => {
    mockDbWithProfile({
      status: 'active',
      enabledFeatures: ['location_tracking', 'payroll'],
    });
    const res = mockResponse();
    await requireAnyFeature(LIVE_FEATURES)(
      reqWith({ userId: 'u1', email: 'a@x.com', role: 'admin', companyId: 'c1' }),
      res,
      next,
    );
    expect(next).toHaveBeenCalled();
  });

  it('allows when `attendance` is enabled', async () => {
    mockDbWithProfile({ status: 'active', enabledFeatures: ['attendance'] });
    const res = mockResponse();
    await requireAnyFeature(LIVE_FEATURES)(
      reqWith({ userId: 'u1', email: 'a@x.com', role: 'admin', companyId: 'c1' }),
      res,
      next,
    );
    expect(statusCode(res)).not.toBe(403);
    expect(next).toHaveBeenCalled();
  });

  it('denies when neither feature is enabled (403 FEATURE_NOT_ENABLED)', async () => {
    mockDbWithProfile({ status: 'active', enabledFeatures: ['payroll'] });
    const res = mockResponse();
    await requireAnyFeature(LIVE_FEATURES)(
      reqWith({ userId: 'u1', email: 'a@x.com', role: 'admin', companyId: 'c1' }),
      res,
      next,
    );
    expect(statusCode(res)).toBe(403);
    expect(jsonBody(res).error).toBe('FEATURE_NOT_ENABLED');
    expect(next).not.toHaveBeenCalled();
  });

  it('denies when enabledFeatures is empty', async () => {
    mockDbWithProfile({ status: 'active', enabledFeatures: [] });
    const res = mockResponse();
    await requireAnyFeature(LIVE_FEATURES)(
      reqWith({ userId: 'u1', email: 'a@x.com', role: 'admin', companyId: 'c1' }),
      res,
      next,
    );
    expect(statusCode(res)).toBe(403);
  });

  it('allows legacy organizations without enabledFeatures', async () => {
    mockDbWithProfile({ status: 'active' });
    const res = mockResponse();
    await requireAnyFeature(LIVE_FEATURES)(
      reqWith({ userId: 'u1', email: 'a@x.com', role: 'admin', companyId: 'c1' }),
      res,
      next,
    );
    expect(next).toHaveBeenCalled();
  });

  it('rejects unauthenticated requests (401)', async () => {
    const res = mockResponse();
    await requireAnyFeature(LIVE_FEATURES)(reqWith(), res, next);
    expect(statusCode(res)).toBe(401);
  });

  it('denies when the organization is not active', async () => {
    mockDbWithProfile({
      status: 'suspended',
      enabledFeatures: ['location_tracking'],
    });
    const res = mockResponse();
    await requireAnyFeature(LIVE_FEATURES)(
      reqWith({ userId: 'u1', email: 'a@x.com', role: 'admin', companyId: 'c1' }),
      res,
      next,
    );
    expect(statusCode(res)).toBe(403);
    expect(jsonBody(res).error).toBe('ORGANIZATION_INACTIVE');
  });
});
