"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createBroadcastTask = createBroadcastTask;
exports.createSingleTask = createSingleTask;
exports.createDailyUpdateForSelf = createDailyUpdateForSelf;
exports.listTasks = listTasks;
exports.listTasksForUser = listTasksForUser;
exports.listEmployeeTasks = listEmployeeTasks;
exports.getTask = getTask;
const firebase_1 = require("../config/firebase");
function toIsoOrNull(v) {
    if (!v)
        return null;
    const s = String(v).trim();
    if (!s)
        return null;
    if (/^\d{4}-\d{2}-\d{2}$/.test(s))
        return s;
    const d = new Date(s);
    return isNaN(d.getTime()) ? null : d.toISOString();
}
function makeTaskDoc({ id, title, description, dueDate, kind, user, audience, assignedTo, }) {
    const nowIso = new Date().toISOString();
    return {
        id,
        title: (title ?? 'Task').trim() || 'Task',
        description: (description ?? '').trim(),
        audience,
        assignedTo: audience === 'employee' ? (assignedTo || '').trim() : null,
        dueDate: toIsoOrNull(dueDate),
        kind: (kind ?? 'Task').trim() || 'Task',
        file: null,
        status: 'assigned',
        createdBy: user?.userId || user?.uid || 'admin',
        createdAt: nowIso,
        updatedAt: nowIso,
    };
}
/** 🔊 Admin: create a broadcast task (no file)
 *  ✅ BACKWARD-COMPAT: also supports audience='employee' + assignedTo for single-employee create
 */
async function createBroadcastTask(req, res) {
    try {
        const { title = '', description = '', dueDate = null, kind = 'Task', audience: rawAudience, // <-- NEW (optional)
        assignedTo: rawAssignedTo, // <-- NEW (optional)
         } = (req.body ?? {});
        if (!description || !String(description).trim()) {
            return res.status(400).json({ error: 'description is required' });
        }
        // 🟣 NEW: If audience='employee' and assignedTo present, treat as single-employee task
        const audience = (rawAudience || 'all').toString().toLowerCase().trim();
        const assignedTo = (rawAssignedTo || '').toString().trim();
        if (audience === 'employee') {
            if (!assignedTo) {
                return res.status(400).json({ error: 'assignedTo (empid) is required when audience="employee"' });
            }
            const docRef = firebase_1.db.collection('tasks').doc();
            const data = makeTaskDoc({
                id: docRef.id,
                title,
                description,
                dueDate,
                kind,
                user: req.user,
                audience: 'employee',
                assignedTo,
            });
            await docRef.set(data);
            return res.status(201).json(data);
        }
        // Default behavior: broadcast to all
        const docRef = firebase_1.db.collection('tasks').doc();
        const data = makeTaskDoc({
            id: docRef.id,
            title,
            description,
            dueDate,
            kind,
            user: req.user,
            audience: 'all',
        });
        await docRef.set(data);
        return res.status(201).json(data);
    }
    catch (e) {
        return res
            .status(500)
            .json({ error: 'Failed to create broadcast task', details: e?.message || String(e) });
    }
}
/** 🎯 Admin: create a task for ONE employee (no file) */
async function createSingleTask(req, res) {
    try {
        const { assignedTo = '', title = '', description = '', dueDate = null, kind = 'Task', } = (req.body ?? {});
        if (!assignedTo || !assignedTo.trim()) {
            return res.status(400).json({ error: 'assignedTo (empid) is required' });
        }
        if (!description || !String(description).trim()) {
            return res.status(400).json({ error: 'description is required' });
        }
        const docRef = firebase_1.db.collection('tasks').doc();
        const data = makeTaskDoc({
            id: docRef.id,
            title,
            description,
            dueDate,
            kind,
            user: req.user,
            audience: 'employee',
            assignedTo,
        });
        await docRef.set(data);
        return res.status(201).json(data);
    }
    catch (e) {
        return res
            .status(500)
            .json({ error: 'Failed to create task', details: e?.message || String(e) });
    }
}
/** ✍️ Employee self-post: create Daily Update for the logged-in user */
async function createDailyUpdateForSelf(req, res) {
    try {
        const user = req.user;
        const empid = (user?.empid || '').trim();
        if (!empid) {
            return res.status(400).json({ error: 'empid missing on user token' });
        }
        const { description = '', title = 'Daily Update', dueDate = null, } = (req.body ?? {});
        if (!description || !String(description).trim()) {
            return res.status(400).json({ error: 'description is required' });
        }
        const docRef = firebase_1.db.collection('tasks').doc();
        const data = makeTaskDoc({
            id: docRef.id,
            title,
            description,
            dueDate,
            kind: 'DailyUpdate',
            user,
            audience: 'employee',
            assignedTo: empid, // from token
        });
        await docRef.set(data);
        return res.status(201).json(data);
    }
    catch (e) {
        return res
            .status(500)
            .json({ error: 'Failed to create daily update', details: e?.message || String(e) });
    }
}
/** 📜 Admin/broadcast list (audience='all' only) */
async function listTasks(_req, res) {
    try {
        const snap = await firebase_1.db
            .collection('tasks')
            .where('audience', '==', 'all')
            .orderBy('createdAt', 'desc')
            .get();
        return res.json(snap.docs.map((d) => d.data()));
    }
    catch (e) {
        return res.status(500).json({ error: 'Failed to fetch tasks', details: e?.message || String(e) });
    }
}
/**
 * 👤 User-merged list: broadcast + personal
 * - If empid is provided (query or token), return only tasks assigned to that empid.
 * - If empid is missing, still return ALL personal tasks (audience='employee').
 */
async function listTasksForUser(req, res) {
    try {
        const authUser = req.user;
        const qEmp = (req.query.empid || authUser?.empid || '').trim();
        // Broadcast query (always)
        const qBroadcast = firebase_1.db
            .collection('tasks')
            .where('audience', '==', 'all')
            .orderBy('createdAt', 'desc')
            .get();
        // Personal query
        let personalQuery = firebase_1.db
            .collection('tasks')
            .where('audience', '==', 'employee');
        // Filter by empid when provided; otherwise return all employee tasks
        if (qEmp) {
            personalQuery = personalQuery.where('assignedTo', '==', qEmp);
        }
        const qPersonal = personalQuery.orderBy('createdAt', 'desc').get();
        const [broadSnap, personalSnap] = await Promise.all([qBroadcast, qPersonal]);
        const all = [
            ...broadSnap.docs.map((d) => d.data()),
            ...personalSnap.docs.map((d) => d.data()),
        ];
        // Sort newest first
        all.sort((a, b) => {
            const ad = Date.parse(a?.createdAt || '') || 0;
            const bd = Date.parse(b?.createdAt || '') || 0;
            return bd - ad;
        });
        return res.json(all);
    }
    catch (e) {
        return res
            .status(500)
            .json({ error: 'Failed to fetch tasks for user', details: e?.message || String(e) });
    }
}
/**
 * 🧑‍💼 Employee-only list:
 * - If empid is provided (query), returns tasks for that empid.
 * - If empid is missing, returns ALL employee tasks (no broadcasts).
 */
async function listEmployeeTasks(req, res) {
    try {
        const qEmp = (String(req.query.empid || '')).trim();
        let query = firebase_1.db.collection('tasks').where('audience', '==', 'employee');
        if (qEmp) {
            query = query.where('assignedTo', '==', qEmp);
        }
        const snap = await query.orderBy('createdAt', 'desc').get();
        const items = snap.docs.map((d) => d.data());
        items.sort((a, b) => {
            const ad = Date.parse(a?.createdAt || '') || 0;
            const bd = Date.parse(b?.createdAt || '') || 0;
            return bd - ad;
        });
        return res.json(items);
    }
    catch (e) {
        return res.status(500).json({
            error: 'Failed to fetch employee tasks',
            details: e?.message || String(e),
        });
    }
}
/** 🔎 Get a single task by id */
async function getTask(req, res) {
    try {
        const id = (req.params.id || '').trim();
        if (!id)
            return res.status(400).json({ error: 'id is required' });
        const snap = await firebase_1.db.collection('tasks').doc(id).get();
        if (!snap.exists)
            return res.status(404).json({ error: 'Not found' });
        return res.json(snap.data());
    }
    catch (e) {
        return res.status(500).json({
            error: 'Failed to fetch task',
            details: e?.message ?? String(e),
        });
    }
}
//# sourceMappingURL=taskController.js.map