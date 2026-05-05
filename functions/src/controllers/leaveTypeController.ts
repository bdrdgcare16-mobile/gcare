import { Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { db } from '../config/firebase';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { trackUsage } from '../services/usageService';

const COLL = 'leave_types';

/* ============================== Usage Tracking Helper ============================== */

async function trackLeaveTypeUsage(
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
    console.error('Usage tracking failed in leaveType:', trackingError);
  }
}

/**
 * POST /api/leave-types
 * Body: { type, fromDate, toDate, days }
 * Admin only
 */
export const createLeaveType = async (req: Request, res: Response): Promise<Response | void> => {
  try {
    console.log('[createLeaveType] req.user =', (req as any).user);
    console.log('[createLeaveType] role =', (req as any).user?.role);
    console.log('[createLeaveType] companyId =', (req as any).user?.companyId);
    
    const { userId, role, companyId } = ((req as any).user ?? {}) as {
      userId?: string;
      role?: string;
      companyId?: string | null;
    };

    if (role !== 'admin') {
      return res.status(403).json({ message: 'Access restricted to administrators' });
    }

    if (!companyId) {
      return res.status(403).json({ message: 'Company ID missing in token' });
    }

    let { type, fromDate, toDate, days } = (req.body ?? {}) as {
      type?: string;
      fromDate?: string;
      toDate?: string;
      days?: number | string;
    };

    type = String(type ?? '').trim();

    if (!type || !fromDate || !toDate || days == null) {
      return res.status(400).json({ message: 'Please fill in all required fields' });
    }

    const s = new Date(fromDate);
    const e = new Date(toDate);
    const allowedDays = Number(days);

    if (Number.isNaN(s.getTime()) || Number.isNaN(e.getTime()) || e < s) {
      return res.status(400).json({ message: 'Please enter valid dates' });
    }

    if (!Number.isFinite(allowedDays) || allowedDays <= 0) {
      return res.status(400).json({ message: 'Number of days must be greater than zero' });
    }

    const id = uuidv4();

    const payload = {
      id,
      companyId,
      type,
      fromDate: Timestamp.fromDate(s),
      toDate: Timestamp.fromDate(e),
      allowedDays,
      active: true,
      createdBy: userId ?? null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };

    console.log('[createLeaveType] payload =', payload);

    await db.collection(COLL).doc(id).set(payload);

    // Track usage after successful leave type creation
    await trackLeaveTypeUsage(req, {
      writeCount: 1,
      apiCalls: 1,
    });

    return res.status(201).json({
      status: 'success',
      message: 'Leave type created successfully',
      data: payload,
    });
  } catch (err: any) {
    console.error('[leave-types:create] error', err);
    return res.status(500).json({
      message: 'An error occurred while processing your request',
      error: err?.message || 'Unknown error',
    });
  }
};

/**
 * GET /api/leave-types
 * Admin and employee
 * Return only active leave types for logged-in user's company
 */
export const listLeaveTypes = async (req: Request, res: Response): Promise<Response | void> => {
  try {
    const { companyId } = ((req as any).user ?? {}) as {
      companyId?: string | null;
    };

    if (!companyId) {
      return res.status(403).json({ message: 'Company ID missing in token' });
    }

    const snaps = await db
      .collection(COLL)
      .where('companyId', '==', companyId)
      .where('active', '==', true)
      .get();

    const out = snaps.docs.map((d) => d.data());

    // Track usage after successful leave types read
    await trackLeaveTypeUsage(req, {
      readCount: 1,
      apiCalls: 1,
    });

    return res.status(200).json({
      status: 'success',
      count: out.length,
      data: out,
    });
  } catch (err: any) {
    console.error('[leave-types:list] error', err);
    return res.status(500).json({
      message: 'Unable to load leave types',
      error: err?.message || 'Unknown error',
    });
  }
};

/**
 * DELETE /api/leave-types/:id
 * Admin only
 * Soft delete only within same company
 */
export const deleteLeaveType = async (req: Request, res: Response): Promise<Response | void> => {
  try {
    const { companyId } = ((req as any).user ?? {}) as {
      companyId?: string | null;
    };

    if (!companyId) {
      return res.status(403).json({ message: 'Company ID missing in token' });
    }

    const { id } = req.params;

    if (!id) {
      return res.status(400).json({ message: 'Leave type ID is required' });
    }

    const ref = db.collection(COLL).doc(id);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ message: 'Leave type not found' });
    }

    const data = doc.data() as any;

    if ((data.companyId || null) !== companyId) {
      return res.status(403).json({ message: 'You are not allowed to delete this leave type' });
    }

    await ref.update({
      active: false,
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Track usage after successful leave type deletion
    await trackLeaveTypeUsage(req, {
      deleteCount: 1,
      apiCalls: 1,
    });

    return res.status(200).json({
      status: 'success',
      message: 'Leave type deleted successfully',
    });
  } catch (err: any) {
    console.error('[leave-types:delete] error', err);
    return res.status(500).json({
      message: 'Failed to delete leave type',
      error: err?.message || 'Unknown error',
    });
  }
};