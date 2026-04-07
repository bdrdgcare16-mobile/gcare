import { Request, Response } from 'express';
import { db } from '../config/firebase';
import { v4 as uuidv4 } from 'uuid';
import { Timestamp } from 'firebase-admin/firestore';



type Shift = {
  id: string;
  name: string;
  startTime: string; // "HH:mm"
  endTime: string;   // "HH:mm"
  shiftname: string;
  createdAt: Timestamp | Date;
  updatedAt: Timestamp | Date;
};

/**
 * Create a new shift template
 * POST /api/shifts
 */
export const createShift = async (req: Request, res: Response): Promise<Response> => {
  try {
    // Basic validation
    const { name, startTime, endTime, shiftname } = (req.body || {}) as Partial<Shift>;

    if (!name || !startTime || !endTime || !shiftname) {
      return res
        .status(400)
        .json({ error: 'name, startTime, endTime and shiftname are required' });
    }
    const existing = await db
    .collection('shifts')
    .where('name','==',name)
    .where('shiftname','==',shiftname)
    .limit(1)
    .get()

    if(!existing.empty){
      return res.status(400).json({
        error:'Shift already exists'
      })
    }
    const id = uuidv4();
    const now = Timestamp.now();

    const payload: Shift = {
      id,
      name: String(name),
      startTime: String(startTime),
      endTime: String(endTime),
      shiftname: String(shiftname),
      createdAt: now,
      updatedAt: now,
    };

    await db.collection('shifts').doc(id).set(payload);
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

  const limit = Number(req.query.limit) || 50;

  const snap = await db
    .collection('shifts')
    .orderBy('createdAt', 'desc')
    .limit(limit)
    .get();

    const shifts = snap.docs.map((d) => d.data());

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

    const doc = await db.collection('shifts').doc(id).get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Shift template not found' });
    }
    return res.json(doc.data());
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
    const updates = {
      ...req.body,
      updatedAt: Timestamp.now(),
    };

    const ref = db.collection('shifts').doc(id);
    const doc = await ref.get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Shift template not found' });
    }

    await ref.update(updates);
    return res.json({ id, ...updates });
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

    const ref = db.collection('shifts').doc(id);
    const doc = await ref.get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Shift template not found' });
    }

    await ref.delete();
    return res.json({ message: 'Shift template deleted' });
  } catch (err) {
    console.error('deleteShift error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};
