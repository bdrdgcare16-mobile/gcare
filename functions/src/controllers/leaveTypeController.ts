import { Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { db } from '../config/firebase';

const COLL = 'leave_types';

/**
 * POST /api/leave-types
 * Body: { type, shift, fromDate, toDate, days }
 * Admin only
 */
export const createLeaveType = async (req: Request, res: Response): Promise<Response | void> => {
  try {
    const role = req.user?.role ?? '';
    const userId = req.user?.userId ?? '';
    if (role !== 'admin') {
      return res.status(403).json({ error: 'Admin only' });
    }

    let { type, shift, fromDate, toDate, days } = (req.body || {}) as {
      type?: string;
      shift?: string;
      fromDate?: string;
      toDate?: string;
      days?: number | string;
    };

    const typeStr = String(type ?? '').trim();
    const shiftStr = String(shift ?? '').trim();
    const start = new Date(String(fromDate ?? ''));
    const end = new Date(String(toDate ?? ''));
    const allowedDays = Number(days);

    if (!typeStr || !shiftStr || !fromDate || !toDate || days === undefined || days === null) {
      return res
        .status(400)
        .json({ error: 'type, shift, fromDate, toDate and days are required' });
    }

    if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime()) || end < start) {
      return res.status(400).json({ error: 'Invalid fromDate/toDate' });
    }

    if (!Number.isFinite(allowedDays) || allowedDays <= 0) {
      return res.status(400).json({ error: '"days" must be a positive number' });
    }

    const id = uuidv4();
    const payload = {
      id,
      type: typeStr,
      shift: shiftStr,
      fromDate: start,
      toDate: end,
      allowedDays,
      active: true,
      createdBy: userId || null,
      createdAt: new Date(),
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
 * Admin or employee
 */
export const listLeaveTypes = async (req: Request, res: Response): Promise<Response | void> => {
  try {
    const raw = req.query.shift;
    const shift = typeof raw === 'string' ? raw.trim() : '';

    let q: FirebaseFirestore.Query = db.collection(COLL).where('active', '==', true);
    if (shift) q = q.where('shift', '==', shift);

    const snaps = await q.get();
    const out = snaps.docs.map((d) => d.data());
    return res.json(out);
  } catch (err) {
    console.error('[leave-types:list] error', err);
    return res.status(500).json({ error: 'Internal error' });
  }
};
