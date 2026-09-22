/// <reference types="jest" />
import { Request, Response } from 'express';
import { employeeLoginValidate, firebaseLogin } from './authController';

jest.mock('../config/firebase', () => ({
  getDb: jest.fn(),
  getAdminAuth: jest.fn(),
  checkFirestoreAccess: jest.fn().mockResolvedValue(true),
}));

import { getDb, getAdminAuth } from '../config/firebase';

process.env.JWT_SECRET = 'test-jwt-secret-minimum-32-characters-long';

function mockResponse() {
  const res: Partial<Response> = {
    status: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis(),
  };
  return res as Response;
}

function makeQuery(docs: any[], chain: any = {}) {
  return {
    where: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    doc: jest.fn((id: string) => ({
      id,
      get: jest.fn().mockResolvedValue({ exists: false }),
      set: jest.fn().mockResolvedValue(undefined),
      ref: { set: jest.fn().mockResolvedValue(undefined) },
    })),
    get: jest.fn().mockResolvedValue({
      empty: docs.length === 0,
      docs: docs.map((d) => ({
        id: d.id || 'doc-id',
        data: () => d.data || {},
        ref: { set: jest.fn().mockResolvedValue(undefined) },
      })),
    }),
    ...chain,
  };
}

function makeDb(companyProfileQuery: any, usersQuery: any, employeesQuery?: any) {
  return jest.fn().mockReturnValue({
    collection: jest.fn((name: string) => {
      if (name === 'companyProfile') return companyProfileQuery;
      if (name === 'users') return usersQuery;
      if (name === 'employees') return employeesQuery || usersQuery;
      return makeQuery([]);
    }),
    getAll: jest.fn().mockResolvedValue([]),
    batch: jest.fn().mockReturnValue({
      set: jest.fn(),
      commit: jest.fn().mockResolvedValue(undefined),
    }),
  });
}

describe('employeeLoginValidate', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  function makeReq(body: any): Partial<Request> {
    return { body } as any;
  }

  test('active employee + correct organization passes validation', async () => {
    const companyQuery = makeQuery([
      { id: 'company-1', data: { code: 'SERV001', status: 'active' } },
    ]);
    const usersQuery = makeQuery([
      {
        id: 'user-1',
        data: {
          email: 'emp@example.com',
          role: 'employee',
          status: 'active',
          companyId: 'company-1',
        },
      },
    ]);

    (getDb as jest.Mock).mockImplementation(
      makeDb(companyQuery, usersQuery)
    );

    const req = makeReq({ organizationCode: 'SERV001', email: 'emp@example.com' });
    const res = mockResponse();

    await employeeLoginValidate(req as Request, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect((res.json as jest.Mock).mock.calls[0][0]).toMatchObject({
      message: 'Employee validated successfully',
      canProceed: true,
    });
  });

  test('lowercase organization code is normalized', async () => {
    const companyQuery = makeQuery([
      { id: 'company-1', data: { code: 'SERV001', status: 'active' } },
    ]);
    const usersQuery = makeQuery([
      {
        id: 'user-1',
        data: {
          email: 'emp@example.com',
          role: 'employee',
          status: 'active',
          companyId: 'company-1',
        },
      },
    ]);

    (getDb as jest.Mock).mockImplementation(
      makeDb(companyQuery, usersQuery)
    );

    const req = makeReq({ organizationCode: 'serv001', email: 'emp@example.com' });
    const res = mockResponse();

    await employeeLoginValidate(req as Request, res);

    expect(res.status).toHaveBeenCalledWith(200);
  });

  test('unknown organization code is rejected with generic message', async () => {
    (getDb as jest.Mock).mockImplementation(
      makeDb(makeQuery([]), makeQuery([]))
    );

    const req = makeReq({ organizationCode: 'UNKNOWN', email: 'emp@example.com' });
    const res = mockResponse();

    await employeeLoginValidate(req as Request, res);

    expect(res.status).toHaveBeenCalledWith(401);
  });

  test('inactive organization is rejected', async () => {
    const companyQuery = makeQuery([
      { id: 'company-1', data: { code: 'SERV001', status: 'inactive' } },
    ]);
    const usersQuery = makeQuery([
      {
        id: 'user-1',
        data: {
          role: 'employee',
          status: 'active',
          companyId: 'company-1',
        },
      },
    ]);

    (getDb as jest.Mock).mockImplementation(
      makeDb(companyQuery, usersQuery)
    );

    const req = makeReq({ organizationCode: 'SERV001', email: 'emp@example.com' });
    const res = mockResponse();

    await employeeLoginValidate(req as Request, res);

    expect(res.status).toHaveBeenCalledWith(401);
  });

  test('suspended organization is rejected', async () => {
    const companyQuery = makeQuery([
      { id: 'company-1', data: { code: 'SERV001', status: 'suspended' } },
    ]);

    (getDb as jest.Mock).mockImplementation(
      makeDb(companyQuery, makeQuery([]))
    );

    const req = makeReq({ organizationCode: 'SERV001', email: 'emp@example.com' });
    const res = mockResponse();

    await employeeLoginValidate(req as Request, res);

    expect(res.status).toHaveBeenCalledWith(401);
  });

  test('employee from different organization is rejected', async () => {
    const companyQuery = makeQuery([
      { id: 'company-1', data: { code: 'SERV001', status: 'active' } },
    ]);
    const usersQuery = makeQuery([
      {
        id: 'user-1',
        data: {
          role: 'employee',
          status: 'active',
          companyId: 'company-2',
        },
      },
    ]);

    (getDb as jest.Mock).mockImplementation(
      makeDb(companyQuery, usersQuery)
    );

    const req = makeReq({ organizationCode: 'SERV001', email: 'emp@example.com' });
    const res = mockResponse();

    await employeeLoginValidate(req as Request, res);

    expect(res.status).toHaveBeenCalledWith(401);
  });

  test('inactive employee is rejected', async () => {
    const companyQuery = makeQuery([
      { id: 'company-1', data: { code: 'SERV001', status: 'active' } },
    ]);
    const usersQuery = makeQuery([
      {
        id: 'user-1',
        data: {
          role: 'employee',
          status: 'inactive',
          companyId: 'company-1',
        },
      },
    ]);

    (getDb as jest.Mock).mockImplementation(
      makeDb(companyQuery, usersQuery)
    );

    const req = makeReq({ organizationCode: 'SERV001', email: 'emp@example.com' });
    const res = mockResponse();

    await employeeLoginValidate(req as Request, res);

    expect(res.status).toHaveBeenCalledWith(401);
  });

  test('admin attempting employee login is rejected', async () => {
    const companyQuery = makeQuery([
      { id: 'company-1', data: { code: 'SERV001', status: 'active' } },
    ]);
    const usersQuery = makeQuery([
      {
        id: 'user-1',
        data: {
          role: 'admin',
          status: 'active',
          companyId: 'company-1',
        },
      },
    ]);

    (getDb as jest.Mock).mockImplementation(
      makeDb(companyQuery, usersQuery)
    );

    const req = makeReq({ organizationCode: 'SERV001', email: 'admin@example.com' });
    const res = mockResponse();

    await employeeLoginValidate(req as Request, res);

    expect(res.status).toHaveBeenCalledWith(401);
  });

  test('super_admin attempting employee login is rejected', async () => {
    const companyQuery = makeQuery([
      { id: 'company-1', data: { code: 'SERV001', status: 'active' } },
    ]);
    const usersQuery = makeQuery([
      {
        id: 'user-1',
        data: {
          role: 'super_admin',
          status: 'active',
          companyId: 'company-1',
        },
      },
    ]);

    (getDb as jest.Mock).mockImplementation(
      makeDb(companyQuery, usersQuery)
    );

    const req = makeReq({ organizationCode: 'SERV001', email: 'super@example.com' });
    const res = mockResponse();

    await employeeLoginValidate(req as Request, res);

    expect(res.status).toHaveBeenCalledWith(401);
  });

  test('missing organization code returns 400', async () => {
    const req = makeReq({ email: 'emp@example.com' });
    const res = mockResponse();

    await employeeLoginValidate(req as Request, res);

    expect(res.status).toHaveBeenCalledWith(400);
  });

  test('malformed email returns 400', async () => {
    const req = makeReq({ organizationCode: 'SERV001', email: 'not-an-email' });
    const res = mockResponse();

    await employeeLoginValidate(req as Request, res);

    expect(res.status).toHaveBeenCalledWith(400);
  });
});

describe('firebaseLogin employee context', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  function makeReq(body: any, authHeader?: string): Partial<Request> {
    return {
      body,
      headers: { authorization: authHeader || '' },
    } as any;
  }

  test('employee + matching organization issues token', async () => {
    (getAdminAuth as jest.Mock).mockReturnValue({
      verifyIdToken: jest.fn().mockResolvedValue({
        email: 'emp@example.com',
        uid: 'firebase-uid',
      }),
    });

    const companyQuery = makeQuery([
      { id: 'company-1', data: { code: 'SERV001', status: 'active' } },
    ]);
    const usersQuery = makeQuery([
      {
        id: 'user-1',
        data: {
          email: 'emp@example.com',
          role: 'employee',
          status: 'active',
          companyId: 'company-1',
          name: 'Test Employee',
        },
      },
    ]);

    (getDb as jest.Mock).mockImplementation(
      makeDb(companyQuery, usersQuery)
    );

    const req = makeReq(
      { organizationCode: 'SERV001', loginContext: 'employee' },
      'Bearer fake-token'
    );
    const res = mockResponse();

    await firebaseLogin(req as Request, res);

    expect(res.status).toHaveBeenCalledWith(200);
    const json = (res.json as jest.Mock).mock.calls[0][0];
    expect(json.message).toBe('Login successful');
    expect(json.token).toBeDefined();
    expect(json.role).toBe('employee');
  });

  test('employee + wrong organization code is rejected', async () => {
    (getAdminAuth as jest.Mock).mockReturnValue({
      verifyIdToken: jest.fn().mockResolvedValue({
        email: 'emp@example.com',
        uid: 'firebase-uid',
      }),
    });

    // Code SERV002 belongs to company-2, but the user is in company-1.
    const companyQuery = makeQuery([
      { id: 'company-2', data: { code: 'SERV002', status: 'active' } },
    ]);
    const usersQuery = makeQuery([
      {
        id: 'user-1',
        data: {
          role: 'employee',
          status: 'active',
          companyId: 'company-1',
        },
      },
    ]);

    (getDb as jest.Mock).mockImplementation(
      makeDb(companyQuery, usersQuery)
    );

    const req = makeReq(
      { organizationCode: 'SERV002', loginContext: 'employee' },
      'Bearer fake-token'
    );
    const res = mockResponse();

    await firebaseLogin(req as Request, res);

    expect(res.status).toHaveBeenCalledWith(401);
  });

  test('admin login without employee context remains supported', async () => {
    (getAdminAuth as jest.Mock).mockReturnValue({
      verifyIdToken: jest.fn().mockResolvedValue({
        email: 'admin@example.com',
        uid: 'firebase-uid',
      }),
    });

    const usersQuery = makeQuery([
      {
        id: 'user-1',
        data: {
          email: 'admin@example.com',
          role: 'admin',
          status: 'active',
          companyId: 'company-1',
          name: 'Admin User',
        },
      },
    ]);

    (getDb as jest.Mock).mockImplementation(
      makeDb(makeQuery([]), usersQuery)
    );

    const req = makeReq({}, 'Bearer fake-token');
    const res = mockResponse();

    await firebaseLogin(req as Request, res);

    expect(res.status).toHaveBeenCalledWith(200);
    const json = (res.json as jest.Mock).mock.calls[0][0];
    expect(json.message).toBe('Login successful');
    expect(json.role).toBe('admin');
  });

  test('super admin login remains supported', async () => {
    (getAdminAuth as jest.Mock).mockReturnValue({
      verifyIdToken: jest.fn().mockResolvedValue({
        email: 'super@example.com',
        uid: 'firebase-uid',
      }),
    });

    const usersQuery = makeQuery([
      {
        id: 'user-1',
        data: {
          email: 'super@example.com',
          role: 'super_admin',
          status: 'active',
          companyId: 'company-1',
        },
      },
    ]);

    (getDb as jest.Mock).mockImplementation(
      makeDb(makeQuery([]), usersQuery)
    );

    const req = makeReq({}, 'Bearer fake-token');
    const res = mockResponse();

    await firebaseLogin(req as Request, res);

    expect(res.status).toHaveBeenCalledWith(200);
  });
});
