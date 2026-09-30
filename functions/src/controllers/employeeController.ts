import { Request, Response } from 'express';
import { getDb } from '../config/firebase';
import * as bcrypt from 'bcryptjs';
import { Timestamp } from 'firebase-admin/firestore';
import { trackUsage } from '../services/usageService';

const EMPLOYEES = 'employees';

interface Employee {
  id?: string;
  companyId?: string;

  empid: string;
  name: string;
  email: string;
  phone?: string;
  location?: string;
  dept?: string;
  designation?: string;
  shiftGroup?: string | null;
  role?: string;
  status: 'active' | 'inactive';

  password?: string;

  emailLower?: string;
  searchKeywords?: string[];

  createdAt: Timestamp;
  updatedAt: Timestamp;
  createdBy?: string;
  updatedBy?: string;
};

/* ============================== Usage Tracking Helper ============================== */

async function trackEmployeeUsage(
  req: Request,
  updates: Record<string, number>
) {
  try {
    const user = (req as any).user;
    await trackUsage({
      companyId: user?.companyId || '',
      companyName: user?.companyName || '',
      plan: user?.plan || '',
      updates,
    });
  } catch (trackingError) {
    console.error('Usage tracking failed in employee:', trackingError);
  }
}

// Create a new employee (Admin only)
export const createEmployee = async (req: Request, res: Response): Promise<Response> => {
  try {

    const tokenCompanyId = (req as any).user?.companyId;
    const currentUserId = (req as any).user?.userId;

    const {
      companyId: requestedCompanyId,
      empid,
      name,
      email,
      phone,
      location,
      dept,
      designation,
      shiftGroup,
      status = 'active',
      password,
    }: {
      companyId?: string;
      empid?: string;
      name?: string;
      email?: string;
      phone?: string;
      location?: string;
      dept?: string;
      designation?: string;
      shiftGroup?: string;
      status?: string;
      password?: string;
    } = req.body;

    if (!tokenCompanyId || !currentUserId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    // companyId is always the authenticated admin's organization — the
    // client may echo it (legacy clients) but cannot steer it.
    if (
      requestedCompanyId &&
      String(requestedCompanyId).trim() !== tokenCompanyId
    ) {
      return res.status(403).json({ error: 'Invalid companyId' });
    }
    const companyId = tokenCompanyId;

    if (!empid || !email || !name) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Normalize email and empid
    const normalizedEmail = String(email || '').trim().toLowerCase();
    const normalizedEmpid = String(empid || '').trim();

    // Add backend logs
    console.log('[CREATE EMPLOYEE] companyId:', companyId);
    console.log('[CREATE EMPLOYEE] email:', normalizedEmail);
    console.log('[CREATE EMPLOYEE] empid:', normalizedEmpid);

    // Check duplicate email with companyId filter
    const emailSnap = await getDb().collection('employees')
      .where('companyId', '==', companyId)
      .where('email', '==', normalizedEmail)
      .limit(1)
      .get();

    console.log('[CREATE EMPLOYEE] duplicate email count:', emailSnap.size);

    if (!emailSnap.empty) {
      return res.status(409).json({ error: 'Email already exists for this company' });
    }

    // Check duplicate empid with companyId filter
    const empidSnap = await getDb().collection('employees')
      .where('companyId', '==', companyId)
      .where('empid', '==', normalizedEmpid)
      .limit(1)
      .get();

    console.log('[CREATE EMPLOYEE] duplicate empid count:', empidSnap.size);

    if (!empidSnap.empty) {
      return res.status(409).json({ error: 'Employee ID already exists for this company' });
    }

    const now = Timestamp.now();

    const employeeData: Employee = {
      companyId: tokenCompanyId,
      empid: normalizedEmpid,
      name,
      email: normalizedEmail,
      emailLower: normalizedEmail,
      phone,
      location,
      dept,
      designation,
      shiftGroup: shiftGroup ?? null,
      // Role is server-owned: membership rows created through Employee
      // Master are always plain employees. Org-admin rows are written by
      // activation provisioning, not this endpoint.
      role: 'employee',
      status: status === 'inactive' ? 'inactive' : 'active',

      createdAt: now,
      updatedAt: now,
      createdBy: currentUserId,
      updatedBy: currentUserId,
    };

    if (password) {
      employeeData.password = await bcrypt.hash(password, 10);
    }

    const ref = await getDb().collection(EMPLOYEES).add(employeeData);
    const doc = await ref.get();

    // Track usage after successful employee creation
    await trackEmployeeUsage(req, {
      writeCount: 1,
      apiCalls: 1,
    });

    return res.status(201).json({
      id: ref.id,
      ...doc.data()
    });

  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: 'Failed to create employee' });
  }
};

export const getEmployees = async (req: Request, res: Response): Promise<Response> => {
  try {

    const companyId = (req as any).user?.companyId;

    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const snap = await getDb()
      .collection(EMPLOYEES)
      .where('companyId', '==', companyId) // 
      .get();

    const data = snap.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    // Track usage after successful employees read
    await trackEmployeeUsage(req, {
      readCount: 1,
      apiCalls: 1,
    });

    return res.status(200).json(data);

  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: 'Failed to fetch employees' });
  }
};
// Get employee by document ID
export const getEmployeeById = async (req: Request, res: Response): Promise<Response> => {
  try {

    const companyId = (req as any).user?.companyId;
    const { id } = req.params;

    const doc = await getDb().collection(EMPLOYEES).doc(id).get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Employee not found' });
    }

    const data = doc.data();

    if (data?.companyId !== companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Track usage after successful employee read
    await trackEmployeeUsage(req, {
      readCount: 1,
      apiCalls: 1,
    });

    return res.status(200).json({
      id: doc.id,
      ...data
    });

  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: 'Failed' });
  }
};
// Update employee (Admin only)
//
// Allowlist update — same convention as payrollController. Fields like
// companyId, id, role, password, createdAt/createdBy and other
// ownership/auth fields can never be mass-assigned from the client.
const EMPLOYEE_UPDATE_ALLOWED = new Set([
  'name',
  'empid',
  'email',
  'phone',
  'location',
  'dept',
  'designation',
  'shiftGroup',
  'status',
]);

export const updateEmployee = async (req: Request, res: Response): Promise<Response> => {
  try {

    const companyId = (req as any).user?.companyId;
    const currentUserId = (req as any).user?.userId;
    const { id } = req.params;

    const unexpected = Object.keys(req.body ?? {}).filter(
      (field) => !EMPLOYEE_UPDATE_ALLOWED.has(field),
    );
    if (unexpected.length > 0) {
      return res.status(400).json({ error: 'Unexpected employee fields' });
    }

    const ref = getDb().collection(EMPLOYEES).doc(id);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Employee not found' });
    }

    const existing = doc.data() as Record<string, any>;
    if (existing?.companyId !== companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const body = req.body as Record<string, any>;
    const updates: Record<string, any> = {
      updatedAt: Timestamp.now(),
      updatedBy: currentUserId,
    };

    for (const field of EMPLOYEE_UPDATE_ALLOWED) {
      if (body[field] !== undefined) updates[field] = body[field];
    }

    if (updates.empid !== undefined) {
      const normalizedEmpid = String(updates.empid || '').trim();
      if (!normalizedEmpid) {
        return res.status(400).json({ error: 'Missing required fields' });
      }
      if (normalizedEmpid !== existing.empid) {
        const dup = await getDb()
          .collection(EMPLOYEES)
          .where('companyId', '==', companyId)
          .where('empid', '==', normalizedEmpid)
          .limit(1)
          .get();
        if (!dup.empty && dup.docs[0].id !== id) {
          return res
            .status(409)
            .json({ error: 'Employee ID already exists for this company' });
        }
      }
      updates.empid = normalizedEmpid;
      // keep empId aliases in sync where present
      if (existing.empId !== undefined) updates.empId = normalizedEmpid;
      if (existing.employeeId !== undefined) updates.employeeId = normalizedEmpid;
    }

    if (updates.email !== undefined) {
      const normalizedEmail = String(updates.email || '').trim().toLowerCase();
      if (!normalizedEmail) {
        return res.status(400).json({ error: 'Missing required fields' });
      }
      if (normalizedEmail !== existing.email) {
        const dup = await getDb()
          .collection(EMPLOYEES)
          .where('companyId', '==', companyId)
          .where('email', '==', normalizedEmail)
          .limit(1)
          .get();
        if (!dup.empty && dup.docs[0].id !== id) {
          return res
            .status(409)
            .json({ error: 'Email already exists for this company' });
        }
      }
      updates.email = normalizedEmail;
      updates.emailLower = normalizedEmail;
    }

    if (updates.status !== undefined) {
      updates.status =
        String(updates.status).toLowerCase() === 'inactive'
          ? 'inactive'
          : 'active';
    }

    await ref.update(updates);

    // Track usage after successful employee update
    await trackEmployeeUsage(req, {
      writeCount: 1,
      apiCalls: 1,
    });

    return res.status(200).json({ message: 'Updated successfully' });

  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: 'Failed' });
  }
};
// Delete employee (Admin only) — hard delete; switch to soft delete if needed
export const deleteEmployee = async (req: Request, res: Response): Promise<Response> => {
  try {

    const companyId = (req as any).user?.companyId;
    const { id } = req.params;

    const ref = getDb().collection(EMPLOYEES).doc(id);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Employee not found' });
    }

    if (doc.data()?.companyId !== companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    await ref.delete();

    // Track usage after successful employee deletion
    await trackEmployeeUsage(req, {
      deleteCount: 1,
      apiCalls: 1,
    });

    return res.status(200).json({ message: 'Deleted successfully' });

  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: 'Failed' });
  }
};