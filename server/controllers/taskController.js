
const { db } = require('../config/firebase');
const { uploadBufferToStorage, buildTaskPath } = require('../utils/storage');

// Compose a Firestore Task document
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
}) {
  const nowIso = new Date().toISOString();
  return {
    id,
    title: title?.trim() || fileMeta?.name || 'Task',
    description: (description || '').trim(),
    audience,                                    // "all" | "employee"
    assignedTo: audience === 'employee' ? (assignedTo || '').trim() : null,
    dueDate: dueDate || null,                    // "yyyy-MM-dd" or null
    kind: kind || 'Task',                        // e.g. "Task" | "DailyUpdate"
    file: fileMeta,                              // { name, size, contentType, url }
    status: 'assigned',
    createdBy: user?.uid || 'admin',
    createdAt: nowIso,
    updatedAt: nowIso,
  };
}

/** 🔊 Admin: upload one file → visible to ALL employees */
async function createBroadcastTask(req, res) {
  try {
    if (!req.file) return res.status(400).json({ error: 'file is required' });

    const { title = '', description = '', dueDate = null, kind = 'Task' } = req.body;

    const docRef = db.collection('tasks').doc();
    const destPath = buildTaskPath(docRef.id, req.file.originalname);
    const url = await uploadBufferToStorage(req.file, destPath);

    const fileMeta = {
      name: req.file.originalname,
      size: req.file.size,
      contentType: req.file.mimetype,
      url,
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
  } catch (e) {
    return res
      .status(500)
      .json({ error: 'Failed to upload broadcast task', details: e.message });
  }
}

/** 🎯 (Optional) Admin: upload one file → to ONE employee (empid) */
async function createSingleTask(req, res) {
  try {
    const {
      assignedTo = '',
      title = '',
      description = '',
      dueDate = null,
      kind = 'Task',
    } = req.body;

    if (!assignedTo.trim()) {
      return res.status(400).json({ error: 'assignedTo (empid) is required' });
    }
    if (!req.file) return res.status(400).json({ error: 'file is required' });

    const docRef = db.collection('tasks').doc();
    const destPath = buildTaskPath(docRef.id, req.file.originalname);
    const url = await uploadBufferToStorage(req.file, destPath);

    const fileMeta = {
      name: req.file.originalname,
      size: req.file.size,
      contentType: req.file.mimetype,
      url,
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
  } catch (e) {
    return res.status(500).json({ error: 'Failed to upload task', details: e.message });
  }
}

/**
 * 📜 List tasks
 * ✔️ Simplified: always return broadcasts only (audience='all')
 *    -> no composite index required
 */
async function listTasks(req, res) {
  try {
    const snap = await db
      .collection('tasks')
      .where('audience', '==', 'all')
      .orderBy('createdAt', 'desc')
      .get();

    return res.json(snap.docs.map((d) => d.data()));
  } catch (e) {
    return res.status(500).json({ error: 'Failed to fetch tasks', details: e.message });
  }
}

/** Get a single task by id */
async function getTask(req, res) {
  try {
    const doc = await db.collection('tasks').doc(req.params.id).get();
    if (!doc.exists) return res.status(404).json({ error: 'Not found' });
    res.json(doc.data());
  } catch (e) {
    res.status(500).json({ error: 'Failed to fetch task', details: e.message });
  }
}

module.exports = {
  createBroadcastTask,
  createSingleTask, // kept exported (even if you don't use it)
  listTasks,
  getTask,
};
