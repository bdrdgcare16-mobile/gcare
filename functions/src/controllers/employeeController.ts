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
  isDeleted?: boolean;
  deletedAt?: Timestamp;
  deletedBy?: string;
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
      companyId,
      empid,
      name,
      email,
      phone,
      location,
      dept,
      designation,
      shiftGroup,
      role,
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
      role?: string;
      status?: string;
      password?: string;
    } = req.body;

    if (!tokenCompanyId || !currentUserId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    if (!companyId || !empid || !email || !name) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    if (companyId !== tokenCompanyId) {
      return res.status(403).json({ error: 'Invalid companyId' });
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
      role,
      status: status as 'active' | 'inactive',
      isDeleted: false,

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
    const companyId = String((req as any).user?.companyId ?? '').trim();

    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const snap = await getDb()
      .collection(EMPLOYEES)
      .where('companyId', '==', companyId)
      .get();

    const data = snap.docs
      .filter(doc => doc.data().isDeleted !== true)
      .map(doc => ({
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

    const companyId = String((req as any).user?.companyId ?? '').trim();
    const { id } = req.params;

    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const doc = await getDb().collection(EMPLOYEES).doc(id).get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Employee not found' });
    }

    const data = doc.data();

    if (data?.companyId !== companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    if (data?.isDeleted === true) {
      return res.status(404).json({ error: 'Employee not found' });
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
export const updateEmployee = async (req: Request, res: Response): Promise<Response> => {
  try {

    const companyId = (req as any).user?.companyId;
    const currentUserId = (req as any).user?.userId;
    const { id } = req.params;

    const ref = getDb().collection(EMPLOYEES).doc(id);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Employee not found' });
    }

    if (doc.data()?.companyId !== companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    if (doc.data()?.isDeleted === true) {
      return res.status(409).json({ error: 'Removed employees cannot be updated' });
    }

    // Field whitelist to prevent mass assignment
    // Status changes must use a dedicated status lifecycle endpoint (not general profile update)
    // Email changes require users mirror synchronization — deferred to dedicated endpoint
    const allowedFields = [
      'name',
      'phone',
      'location',
      'dept',
      'designation',
      'shiftGroup',
    ];

    const updates: Record<string, any> = {};
    const invalidFields: string[] = [];

    for (const key of Object.keys(req.body)) {
      if (!allowedFields.includes(key)) {
        invalidFields.push(key);
      } else {
        updates[key] = req.body[key];
      }
    }

    if (invalidFields.length > 0) {
      return res.status(400).json({
        error: 'Invalid fields',
        message: `The following fields are not allowed for update: ${invalidFields.join(', ')}`,
        invalidFields,
      });
    }

    // Set audit fields
    updates.updatedAt = Timestamp.now();
    updates.updatedBy = currentUserId;

    const outcome = await getDb().runTransaction(async transaction => {
      const currentDoc = await transaction.get(ref);

      if (!currentDoc.exists) {
        return 'not_found';
      }

      const currentEmployee = currentDoc.data();
      if (currentEmployee?.companyId !== companyId) {
        return 'forbidden';
      }

      if (currentEmployee?.isDeleted === true) {
        return 'removed';
      }

      transaction.update(ref, updates);
      return 'updated';
    });

    if (outcome === 'not_found') {
      return res.status(404).json({ error: 'Employee not found' });
    }

    if (outcome === 'forbidden') {
      return res.status(403).json({ error: 'Access denied' });
    }

    if (outcome === 'removed') {
      return res.status(409).json({ error: 'Removed employees cannot be updated' });
    }

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
// Soft remove employee from Employee Management (Admin only)
export const deleteEmployee = async (req: Request, res: Response): Promise<Response> => {
  try {
    const user = (req as any).user;
    const companyId = String(user?.companyId ?? '').trim();
    const actorId = String(user?.userId ?? '').trim();
    const { id } = req.params;

    if (!companyId || !actorId || actorId === 'unknown') {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const ref = getDb().collection(EMPLOYEES).doc(id);
    const outcome = await getDb().runTransaction(async transaction => {
      const doc = await transaction.get(ref);

      if (!doc.exists) {
        return 'not_found';
      }

      const employee = doc.data();
      if (employee?.companyId !== companyId) {
        return 'forbidden';
      }

      if (employee.isDeleted === true) {
        return 'already_removed';
      }

      transaction.update(ref, {
        isDeleted: true,
        deletedAt: Timestamp.now(),
        deletedBy: actorId,
      });
      return 'removed';
    });

    if (outcome === 'not_found') {
      return res.status(404).json({ error: 'Employee not found' });
    }

    if (outcome === 'forbidden') {
      return res.status(403).json({ error: 'Access denied' });
    }

    if (outcome === 'already_removed') {
      return res.status(409).json({ error: 'Employee is already removed' });
    }

    // Track usage only after the first successful soft delete.
    await trackEmployeeUsage(req, {
      deleteCount: 1,
      apiCalls: 1,
    });

    return res.status(200).json({ message: 'Employee removed successfully' });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: 'Failed to remove employee' });
  }
};
