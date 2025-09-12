// import { Request, Response } from 'express';
// import * as admin from 'firebase-admin';
// import { v4 as uuidv4 } from 'uuid';

// const db = admin.firestore();
// const LEAVE_TYPES_COLLECTION = 'leave_types';

// type LeaveType = {
//   id: string;
//   name: string;
//   description?: string;
//   maxDays: number;
//   isActive: boolean;
//   createdAt: admin.firestore.Timestamp;
//   updatedAt: admin.firestore.Timestamp;
//   createdBy: string;
// };

// /**
//  * Create a new leave type (Admin only)
//  * POST /api/leave-types
//  * Body: { name, description?, maxDays }
//  */
// export const createLeaveType = async (req: Request, res: Response): Promise<Response> => {
//   try {
//     // Check admin permissions
//     if (req.user?.role !== 'admin') {
//       return res.status(403).json({ error: 'Admin access required' });
//     }

//     const { name, description, maxDays } = req.body as {
//       name?: string;
//       description?: string;
//       maxDays?: number;
//     };

//     // Input validation
//     if (!name || maxDays === undefined) {
//       return res.status(400).json({ 
//         error: 'Missing required fields: name, maxDays' 
//       });
//     }

//     if (typeof maxDays !== 'number' || maxDays <= 0) {
//       return res.status(400).json({ 
//         error: 'maxDays must be a positive number' 
//       });
//     }

//     const id = uuidv4();
//     const now = admin.firestore.Timestamp.now();
//     const userId = req.user?.userId || 'system';
    
//     const leaveType: Omit<LeaveType, 'id'> = {
//       name: name.trim(),
//       description: description?.trim(),
//       maxDays,
//       isActive: true,
//       createdAt: now,
//       updatedAt: now,
//       createdBy: userId,
//     };

//     await db.collection(LEAVE_TYPES_COLLECTION).doc(id).set(leaveType);

//     return res.status(201).json({
//       id,
//       ...leaveType,
//     });
//   } catch (error) {
//     console.error('Error creating leave type:', error);
//     return res.status(500).json({ 
//       error: 'Failed to create leave type',
//       details: error instanceof Error ? error.message : 'Unknown error'
//     });
//   }
// };

// /**
//  * List all active leave types
//  * GET /api/leave-types
//  */
// export const listLeaveTypes = async (req: Request, res: Response): Promise<Response> => {
//   try {
//     const snapshot = await db
//       .collection(LEAVE_TYPES_COLLECTION)
//       .where('isActive', '==', true)
//       .orderBy('name')
//       .get();

//     const leaveTypes = snapshot.docs.map(doc => ({
//       id: doc.id,
//       ...doc.data()
//     }));

//     return res.status(200).json(leaveTypes);
//   } catch (error) {
//     console.error('Error listing leave types:', error);
//     return res.status(500).json({ 
//       error: 'Failed to fetch leave types',
//       details: error instanceof Error ? error.message : 'Unknown error'
//     });
//   }
// };

// /**
//  * Simple ping endpoint to verify the route is working
//  * GET /api/leave-types/__ping
//  */
// export const pingLeaveTypes = (_req: Request, res: Response): void => {
//   res.status(200).json({ status: 'ok', message: 'Leave types route is working' });
// };
import { Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import * as admin from 'firebase-admin';
import { db } from '../config/firebase';

const COLL = 'leave_types';

/**
 * POST /api/leave-types
 * Body: { type, shift, fromDate, toDate, days }
 * Admin only
 */
export const createLeaveType = async (req: Request, res: Response): Promise<Response | void> => {
  try {
    const { userId, role } = ((req as any).user ?? {}) as { userId?: string; role?: string };
    if (role !== 'admin') {
      return res.status(403).json({ error: 'Admin only' });
    }

    let { type, shift, fromDate, toDate, days } = (req.body ?? {}) as {
      type?: string;
      shift?: string;
      fromDate?: string;
      toDate?: string;
      days?: number | string;
    };

    type = String(type ?? '').trim();
    shift = String(shift ?? '').trim();

    if (!type || !shift || !fromDate || !toDate || days == null) {
      return res
        .status(400)
        .json({ error: 'type, shift, fromDate, toDate and days are required' });
    }

    const s = new Date(fromDate);
    const e = new Date(toDate);
    const allowedDays = Number(days);

    if (Number.isNaN(s.getTime()) || Number.isNaN(e.getTime()) || e < s) {
      return res.status(400).json({ error: 'Invalid fromDate/toDate' });
    }
    if (!Number.isFinite(allowedDays) || allowedDays <= 0) {
      return res.status(400).json({ error: '"days" must be a positive number' });
    }

    const id = uuidv4();
    const payload = {
      id,
      type,
      shift,
      // Use Firestore Timestamps to be explicit
      fromDate: admin.firestore.Timestamp.fromDate(s),
      toDate: admin.firestore.Timestamp.fromDate(e),
      allowedDays,
      active: true,
      createdBy: userId ?? null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection(COLL).doc(id).set(payload);
    return res.status(201).json(payload);
  } catch (err: any) {
    console.error('[leave-types:create] error', err);
    return res.status(500).json({ error: err?.message || 'Internal error' });
  }
};

/**
 * GET /api/leave-types?shift=...
 * (shift is OPTIONAL; deliberately NO orderBy to avoid composite index)
 */
export const listLeaveTypes = async (req: Request, res: Response): Promise<Response | void> => {
  try {
    const raw = req.query.shift;
    const shift = typeof raw === 'string' ? raw.trim() : '';

    let q: FirebaseFirestore.Query = db.collection(COLL).where('active', '==', true);
    if (shift) q = q.where('shift', '==', shift);

    const snaps = await q.get();
    const out = snaps.docs.map((d) => d.data());
    return res.status(200).json(out);
  } catch (err: any) {
    console.error('[leave-types:list] error', err);
    return res.status(500).json({ error: 'Internal error' });
  }
};
