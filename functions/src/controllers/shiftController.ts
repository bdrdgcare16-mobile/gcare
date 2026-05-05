import { Request, Response } from 'express';
import { db } from '../config/firebase';
import { v4 as uuidv4 } from 'uuid';
import { Timestamp } from 'firebase-admin/firestore';
import { trackUsage } from '../services/usageService';

type Shift = {
  id: string;
  name: string;
  startTime: string; // "HH:mm"
  endTime: string;   // "HH:mm"
  shiftname: string;
  companyId: string;
  createdBy?: string;
  createdAt: Timestamp | Date;
  updatedAt: Timestamp | Date;
};

type AuthUser = {
  userId?: string;
  uid?: string;
  email?: string | null;
  role?: string | null;
  companyId?: string | null;
};

function getReqUser(req: Request): AuthUser {
  return ((req as any).user || {}) as AuthUser;
}

function getReqCompanyId(req: Request): string | null {
  return String(getReqUser(req)?.companyId || '').trim() || null;
}

function getReqActorId(req: Request): string | null {
  const user = getReqUser(req);
  return String(user.userId || user.uid || '').trim() || null;
}

/* ============================== Usage Tracking Helper ============================== */

async function trackShiftUsage(
  req: Request,
  updates: Record<string, number>
) {
  try {
    const user = getReqUser(req);
    await trackUsage({
      companyId: user?.companyId || '',
      companyName: (req as any).user?.companyName || '',
      plan: (req as any).user?.plan || '',
      updates,
    });
  } catch (trackingError) {
    console.error('Usage tracking failed in shift:', trackingError);
  }
}

/**
 * Create a new shift template
 * POST /api/shifts
 */
export const createShift = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { name, startTime, endTime, shiftname } = (req.body || {}) as Partial<Shift>;

    const companyId = getReqCompanyId(req);
    const actorId = getReqActorId(req);

    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized: missing companyId' });
    }

    if (!name || !startTime || !endTime || !shiftname) {
      return res
        .status(400)
        .json({ error: 'name, startTime, endTime and shiftname are required' });
    }

    const existing = await db
      .collection('shifts')
      .where('companyId', '==', companyId)
      .where('name', '==', String(name))
      .where('shiftname', '==', String(shiftname))
      .limit(1)
      .get();

    if (!existing.empty) {
      return res.status(400).json({
        error: 'Shift already exists for this company'
      });
    }

    const id = uuidv4();
    const now = Timestamp.now();

    const payload: Shift = {
      id,
      name: String(name),
      startTime: String(startTime),
      endTime: String(endTime),
      shiftname: String(shiftname),
      companyId,
      createdBy: actorId || '',
      createdAt: now,
      updatedAt: now,
    };

    await db.collection('shifts').doc(id).set(payload);

    // Track usage after successful shift creation
    await trackShiftUsage(req, {
      writeCount: 1,
      apiCalls: 1,
    });

    return res.status(201).json(payload);
  } catch (err) {
    console.error('createShift error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

/**
 * List all shift templates
 * GET /api/shifts
 */
export const getAllShifts = async (req: Request, res: Response): Promise<Response> => {
  try {
    const companyId = getReqCompanyId(req);

    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized: missing companyId' });
    }

    const limit = Number(req.query.limit) || 50;

    const snap = await db
      .collection('shifts')
      .where('companyId', '==', companyId)
      .orderBy('createdAt', 'desc')
      .limit(limit)
      .get();

    const shifts = snap.docs.map((d) => d.data());

    // Track usage after successful shifts read
    await trackShiftUsage(req, {
      readCount: 1,
      apiCalls: 1,
    });

    return res.json(shifts);
  } catch (err) {
    console.error('getAllShifts error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

/**
 * Get a single shift by UUID
 * GET /api/shifts/:id
 */
export const getShiftById = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { id } = req.params;
    const companyId = getReqCompanyId(req);

    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized: missing companyId' });
    }

    const doc = await db.collection('shifts').doc(id).get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Shift template not found' });
    }

    const data = doc.data() as Shift;

    if (data.companyId !== companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Track usage after successful shift read
    await trackShiftUsage(req, {
      readCount: 1,
      apiCalls: 1,
    });

    return res.json(data);
  } catch (err) {
    console.error('getShiftById error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

/**
 * Update a shift template
 * PUT /api/shifts/:id
 */
export const updateShift = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { id } = req.params;
    const companyId = getReqCompanyId(req);

    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized: missing companyId' });
    }

    const ref = db.collection('shifts').doc(id);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Shift template not found' });
    }

    const existingData = doc.data() as Shift;

    if (existingData.companyId !== companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const updates = {
      ...req.body,
      companyId: existingData.companyId, // prevent overwrite
      updatedAt: Timestamp.now(),
    };

    await ref.update(updates);

    // Track usage after successful shift update
    await trackShiftUsage(req, {
      writeCount: 1,
      apiCalls: 1,
    });

    return res.json({ ...existingData, ...updates });
  } catch (err) {
    console.error('updateShift error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

/**
 * Delete a shift template
 * DELETE /api/shifts/:id
 */
export const deleteShift = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { id } = req.params;
    const companyId = getReqCompanyId(req);

    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized: missing companyId' });
    }

    const ref = db.collection('shifts').doc(id);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Shift template not found' });
    }

    const data = doc.data() as Shift;

    if (data.companyId !== companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    await ref.delete();

    // Track usage after successful shift deletion
    await trackShiftUsage(req, {
      deleteCount: 1,
      apiCalls: 1,
    });

    return res.json({ message: 'Shift template deleted' });
  } catch (err) {
    console.error('deleteShift error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};