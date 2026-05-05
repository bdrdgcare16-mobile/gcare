import { Request, Response } from 'express';
import path from 'path';
import fs from 'fs';
import { randomUUID } from 'crypto';
import { trackUsage } from '../services/usageService';

// Helper to safely trim fields
const getTrim = (obj: any, key: string): string =>
  (obj?.[key] ?? '').toString().trim();

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

type UploadedFile = {
  name: string;
  mv: (dest: string, cb?: (err?: any) => void) => void;
};

type AuthUser = {
  userId?: string;
  uid?: string;
  companyId?: string | null;
  role?: string | null;
};

// Helpers
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

const pickFirst = <T>(f: T | T[] | undefined | null): T | null =>
  (Array.isArray(f) ? f[0] : f) || null;

const moveFile = (file: UploadedFile, dest: string) =>
  new Promise<void>((resolve, reject) => {
    file.mv(dest, (err) => (err ? reject(err) : resolve()));
  });

/* ============================== Usage Tracking Helper ============================== */

async function trackEventUsage(
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
    console.error('Usage tracking failed in event:', trackingError);
  }
}

/* ================= CREATE EVENT ================= */

export const createEvent = async (req: Request, res: Response): Promise<Response> => {
  try {
    const db = (req.app.locals as any).db;

    const companyId = getReqCompanyId(req);
    const actorId = getReqActorId(req);

    if (!companyId || !actorId) {
      return res.status(401).json({ error: 'Unauthorized: companyId or actorId missing' });
    }

    const title = getTrim(req.body, 'title');
    const description = getTrim(req.body, 'description');
    const location = getTrim(req.body, 'location');
    const fromDate = getTrim(req.body, 'fromDate');
    const toDate = getTrim(req.body, 'toDate');

    if (!title || !description || !location || !fromDate || !toDate) {
      return res.status(400).json({
        error: 'title, description, location, fromDate, and toDate are required'
      });
    }

    let imageUrl: string | null = null;
    let fileUrl: string | null = null;

    const files: any = (req as any).files;

    if (files?.image) {
      const image = pickFirst<UploadedFile>(files.image);
      if (image) {
        const name = `${randomUUID()}${path.extname(image.name)}`;
        const dest = path.join(uploadsDir, name);
        await moveFile(image, dest);
        imageUrl = `/uploads/${name}`;
      }
    }

    if (files?.file) {
      const file = pickFirst<UploadedFile>(files.file);
      if (file) {
        const name = `${randomUUID()}${path.extname(file.name)}`;
        const dest = path.join(uploadsDir, name);
        await moveFile(file, dest);
        fileUrl = `/uploads/${name}`;
      }
    }

    const doc = {
      companyId,
      title,
      description,
      location,
      fromDate,
      toDate,
      imageUrl,
      fileUrl,
      createdAt: new Date(),
      createdBy: actorId,
    };

    const ref = await db.collection('events').add(doc);

    // Track usage after successful event creation
    const updates: Record<string, number> = {
      writeCount: 1,
      apiCalls: 1,
    };
    
    // Track file uploads if present
    if (imageUrl) {
      updates.fileUploadCount = 1;
      updates.eventUploadCount = 1;
    }
    if (fileUrl) {
      updates.fileUploadCount = (updates.fileUploadCount || 0) + 1;
      updates.eventUploadCount = (updates.eventUploadCount || 0) + 1;
    }
    
    await trackEventUsage(req, updates);

    return res.status(201).json({
      message: 'Event created successfully',
      event: {
        id: ref.id,
        ...doc,
      },
    });
  } catch (err: any) {
    console.error('createEvent error:', err);
    return res.status(500).json({ error: err.message || 'Internal server error' });
  }
};

/* ================= GET ALL EVENTS ================= */

export const getAllEvents = async (req: Request, res: Response): Promise<Response> => {
  try {
    const db = (req.app.locals as any).db;
    const companyId = getReqCompanyId(req);

    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized: companyId missing' });
    }

    const snap = await db
      .collection('events')
      .where('companyId', '==', companyId)
      .orderBy('createdAt', 'desc')
      .get();

    const data = snap.docs.map((d: any) => ({
      id: d.id,
      ...d.data(),
    }));

    // Track usage after successful events read
    await trackEventUsage(req, {
      readCount: 1,
      apiCalls: 1,
    });

    return res.status(200).json({
      message: 'Events fetched successfully',
      events: data,
    });
  } catch (err: any) {
    console.error('getAllEvents error:', err);
    return res.status(500).json({ error: err.message || 'Internal server error' });
  }
};

/* ================= GET EVENT BY ID ================= */

export const getEventById = async (req: Request, res: Response): Promise<Response> => {
  try {
    const db = (req.app.locals as any).db;
    const companyId = getReqCompanyId(req);
    const { id } = req.params;

    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized: companyId missing' });
    }

    const doc = await db.collection('events').doc(id).get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Event not found' });
    }

    const data = doc.data() as any;

    if (data.companyId !== companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Track usage after successful event read
    await trackEventUsage(req, {
      readCount: 1,
      apiCalls: 1,
    });

    return res.status(200).json({
      message: 'Event fetched successfully',
      event: {
        id: doc.id,
        ...data,
      },
    });
  } catch (err: any) {
    console.error('getEventById error:', err);
    return res.status(500).json({ error: err.message || 'Internal server error' });
  }
};

/* ================= UPDATE EVENT ================= */

export const updateEvent = async (req: Request, res: Response): Promise<Response> => {
  try {
    const db = (req.app.locals as any).db;
    const companyId = getReqCompanyId(req);
    const { id } = req.params;

    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized: companyId missing' });
    }

    const ref = db.collection('events').doc(id);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Event not found' });
    }

    const existingData = doc.data() as any;

    if (existingData.companyId !== companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const updateData: any = {
      updatedAt: new Date(),
    };

    if (req.body.title !== undefined) updateData.title = getTrim(req.body, 'title');
    if (req.body.description !== undefined) updateData.description = getTrim(req.body, 'description');
    if (req.body.location !== undefined) updateData.location = getTrim(req.body, 'location');
    if (req.body.fromDate !== undefined) updateData.fromDate = getTrim(req.body, 'fromDate');
    if (req.body.toDate !== undefined) updateData.toDate = getTrim(req.body, 'toDate');

    await ref.update(updateData);

    // Track usage after successful event update
    await trackEventUsage(req, {
      writeCount: 1,
      apiCalls: 1,
    });

    return res.status(200).json({ message: 'Event updated successfully' });
  } catch (err: any) {
    console.error('updateEvent error:', err);
    return res.status(500).json({ error: err.message || 'Internal server error' });
  }
};

/* ================= DELETE EVENT ================= */

export const deleteEvent = async (req: Request, res: Response): Promise<Response> => {
  try {
    const db = (req.app.locals as any).db;
    const companyId = getReqCompanyId(req);
    const { id } = req.params;

    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized: companyId missing' });
    }

    const ref = db.collection('events').doc(id);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Event not found' });
    }

    const data = doc.data() as any;

    if (data.companyId !== companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    await ref.delete();

    // Track usage after successful event deletion
    await trackEventUsage(req, {
      deleteCount: 1,
      apiCalls: 1,
    });

    return res.status(200).json({ message: 'Event deleted successfully' });
  } catch (err: any) {
    console.error('deleteEvent error:', err);
    return res.status(500).json({ error: err.message || 'Internal server error' });
  }
};