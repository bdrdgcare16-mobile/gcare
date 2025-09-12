import { Request, Response } from 'express';
import { db } from '../config/firebase';
import { uploadBufferToStorage } from '../utils/storage';

// Re-export the user type for consistency with auth middleware
export type AuthUser = {
  userId: string;
  email: string;
  role: string;
  empid?: string | null;
  uid?: string; // For backward compatibility
};

type Audience = 'all' | 'employee';

interface FileMeta {
  name: string;
  size: number;
  contentType: string;
  url: string;
}

interface TaskDoc {
  id: string;
  title: string;
  description: string;
  audience: Audience;
  assignedTo: string | null; // empid when audience='employee'
  dueDate: string | null;    // yyyy-MM-dd or null
  kind: string;              // "Task" | "DailyUpdate" | etc
  file: FileMeta | null;
  status: 'assigned';
  createdBy: string;
  createdAt: string; // ISO
  updatedAt: string; // ISO
}

function makeTaskDoc({
  id,
  title,
  description,
  dueDate,
  kind,
  fileMeta,
  user,
  audience,
  assignedTo,
}: {
  id: string;
  title?: string;
  description?: string;
  dueDate?: string | null;
  kind?: string;
  fileMeta?: FileMeta | null;
  user?: AuthUser;
  audience: Audience;
  assignedTo?: string | null;
}): TaskDoc {
  const nowIso = new Date().toISOString();
  return {
    id,
    title: title?.trim() || fileMeta?.name || 'Task',
    description: (description || '').trim(),
    audience,
    assignedTo: audience === 'employee' ? (assignedTo || '').trim() : null,
    dueDate: dueDate || null,
    kind: kind || 'Task',
    file: fileMeta ?? null,
    status: 'assigned',
    createdBy: user?.userId || user?.uid || 'admin',
    createdAt: nowIso,
    updatedAt: nowIso,
  };
}

/** 🔊 Admin: upload one file → visible to ALL employees */
export async function createBroadcastTask(req: Request, res: Response) {
  try {
    if (!req.file) return res.status(400).json({ error: 'file is required' });

    const { title = '', description = '', dueDate = null, kind = 'Task' } = (req.body ?? {}) as {
      title?: string;
      description?: string;
      dueDate?: string | null;
      kind?: string;
    };

    const docRef = db.collection('tasks').doc();
    const uploadResult = await uploadBufferToStorage(
      req.file.buffer,
      req.file.originalname,
      req.file.mimetype,
      `tasks/${docRef.id}`
    );

    const fileMeta: FileMeta = {
      name: req.file.originalname,
      size: req.file.size,
      contentType: req.file.mimetype,
      url: uploadResult.url,
    };

    const data = makeTaskDoc({
      id: docRef.id,
      title,
      description,
      dueDate,
      kind,
      fileMeta,
      user: req.user,
      audience: 'all',
    });

    await docRef.set(data);
    return res.status(201).json(data);
  } catch (e: any) {
    return res
      .status(500)
      .json({ error: 'Failed to upload broadcast task', details: e?.message || String(e) });
  }
}

/** 🎯 Admin: upload one file → to ONE employee (empid) */
export async function createSingleTask(req: Request, res: Response) {
  try {
    const {
      assignedTo = '',
      title = '',
      description = '',
      dueDate = null,
      kind = 'Task',
    } = (req.body ?? {}) as {
      assignedTo?: string;
      title?: string;
      description?: string;
      dueDate?: string | null;
      kind?: string;
    };

    if (!assignedTo.trim()) {
      return res.status(400).json({ error: 'assignedTo (empid) is required' });
    }
    if (!req.file) return res.status(400).json({ error: 'file is required' });

    const docRef = db.collection('tasks').doc();
    const uploadResult = await uploadBufferToStorage(
      req.file.buffer,
      req.file.originalname,
      req.file.mimetype,
      `tasks/${docRef.id}`
    );

    const fileMeta: FileMeta = {
      name: req.file.originalname,
      size: req.file.size,
      contentType: req.file.mimetype,
      url: uploadResult.url,
    };

    const data = makeTaskDoc({
      id: docRef.id,
      title,
      description,
      dueDate,
      kind,
      fileMeta,
      user: req.user,
      audience: 'employee',
      assignedTo,
    });

    await docRef.set(data);
    return res.status(201).json(data);
  } catch (e: any) {
    return res.status(500).json({ error: 'Failed to upload task', details: e?.message || String(e) });
  }
}

/**
 * 📜 List tasks
 * – Simplified to broadcasts only (audience='all') to avoid composite indexes.
 * – If you want per-employee later, add a separate endpoint.
 */
export async function listTasks(_req: Request, res: Response) {
  try {
    const snap = await db
      .collection('tasks')
      .where('audience', '==', 'all')
      .orderBy('createdAt', 'desc')
      .get();

    return res.json(snap.docs.map((d) => d.data()));
  } catch (e: any) {
    return res.status(500).json({ error: 'Failed to fetch tasks', details: e?.message || String(e) });
  }
}

/** Get a single task by id */
export async function getTask(req: Request, res: Response): Promise<Response> {
  try {
    const doc = await db.collection('tasks').doc(req.params.id).get();
    if (!doc.exists) return res.status(404).json({ error: 'Not found' });
    return res.json(doc.data());
  } catch (e: any) {
    return res.status(500).json({ error: 'Failed to fetch task', details: e?.message || String(e) });
  }
}
