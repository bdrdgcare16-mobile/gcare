import { Request, Response } from 'express';

import { db } from '../config/firebase';

import { trackUsage } from '../services/usageService';

import { createAndSend, resolveUserIdByEmpid } from '../services/notification.service';

import { COLLECTIONS } from '../constants/collections';

import { uploadTaskProofToFirebase, getTaskProofSignedUrl } from '../services/taskProofUpload.service';



// Re-export the user type for consistency with auth middleware

export type AuthUser = {

  userId: string;

  email: string;

  role: string;

  empid?: string | null;

  uid?: string; // backward compatibility

  companyId?: string | null; // ✅ added for multi-company isolation

};



type Audience = 'all' | 'employee';



interface TaskDoc {

  id: string;

  companyId: string;

  title: string;

  description: string;

  audience: Audience;

  assignedTo: string | null; // empid when audience='employee'

  dueDate: string | null;    // yyyy-MM-dd or ISO string

  kind: string;              // "Task" | "DailyUpdate" | etc.

  file: null;                // always null now

  status: 'assigned' | 'completed';

  createdBy: string;

  createdAt: string; // ISO

  updatedAt: string; // ISO

  // Completion fields (only present once status === 'completed')

  completedAt?: string | null;

  completedBy?: string | null; // userId of the employee who completed it

  completionNote?: string | null;

  proofFileUrl?: string | null;

}

interface TaskAssignmentDoc {
  id: string;
  companyId: string;
  taskId: string;
  employeeId: string; // empid
  status: 'assigned' | 'completed';
  assignedAt: string; // ISO
  completedAt?: string | null;
  completedBy?: string | null; // userId
  completionNote?: string | null;
  proofFileUrl?: string | null;
  createdAt: string;
  updatedAt: string;
}

function makeTaskAssignmentDoc({
  id,
  companyId,
  taskId,
  employeeId,
  user,
}: {
  id: string;
  companyId: string;
  taskId: string;
  employeeId: string;
  user?: AuthUser;
}): TaskAssignmentDoc {
  const nowIso = new Date().toISOString();
  return {
    id,
    companyId,
    taskId,
    employeeId: employeeId.trim(),
    status: 'assigned',
    assignedAt: nowIso,
    completedAt: null,
    completedBy: null,
    completionNote: null,
    proofFileUrl: null,
    createdAt: nowIso,
    updatedAt: nowIso,
  };
}

/**
 * Creates per-employee task assignments.
 * - audience='employee' -> one assignment for the provided empid
 * - audience='all' -> one assignment for every active employee in the company
 */
async function createAssignmentsForTask(
  req: Request,
  task: TaskDoc,
  options: { audience: Audience; assignedTo?: string | null }
): Promise<void> {
  const { audience, assignedTo } = options;
  const nowIso = new Date().toISOString();

  let employeeIds: string[] = [];

  if (audience === 'employee' && assignedTo) {
    employeeIds = [assignedTo.trim()];
  } else if (audience === 'all') {
    const employeeSnap = await db
      .collection(COLLECTIONS.USERS)
      .where('companyId', '==', task.companyId)
      .where('role', '==', 'employee')
      .get();
    employeeIds = employeeSnap.docs
      .map((doc) => (doc.data()?.empid || '').toString().trim())
      .filter((e) => e);
  }

  if (employeeIds.length === 0) return;

  // Firestore batches are limited to 500 operations; split into chunks if needed
  const CHUNK = 450;
  for (let i = 0; i < employeeIds.length; i += CHUNK) {
    const chunk = employeeIds.slice(i, i + CHUNK);
    const batch = db.batch();

    for (const empid of chunk) {
      const assignmentRef = db.collection(COLLECTIONS.TASK_ASSIGNMENTS).doc();
      const assignment = makeTaskAssignmentDoc({
        id: assignmentRef.id,
        companyId: task.companyId,
        taskId: task.id,
        employeeId: empid,
        user: req.user as AuthUser | undefined,
      });
      batch.set(assignmentRef, {
        ...assignment,
        createdAt: nowIso,
        updatedAt: nowIso,
      });
    }

    await batch.commit();
  }
}



function toIsoOrNull(v?: string | null): string | null {

  if (!v) return null;

  const s = String(v).trim();

  if (!s) return null;

  if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;

  const d = new Date(s);

  return isNaN(d.getTime()) ? null : d.toISOString();

}



function makeTaskDoc({

  id,

  title,

  description,

  dueDate,

  kind,

  user,

  audience,

  assignedTo,

  companyId,

}: {

  id: string;

  title?: string;

  description?: string;

  dueDate?: string | null;

  kind?: string;

  user?: AuthUser;

  audience: Audience;

  assignedTo?: string | null;

  companyId: string;

}): TaskDoc {

  const nowIso = new Date().toISOString();

  return {

    id,

    companyId,

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



function getReqCompanyId(req: Request): string | null {

  const companyId = ((req.user as AuthUser | undefined)?.companyId || '').trim();

  return companyId || null;

}



/* ============================== Usage Tracking Helper ============================== */



/**
 * Sends a TASK_ASSIGNED push notification to the employee(s) a task was just
 * assigned to. Never throws — a failure here must not fail task creation.
 *
 * Case 1: audience='employee' -> notify only the assigned employee
 * Case 2: audience='all' -> notify all employees in the same company
 */
async function notifyTaskAssigned(req: Request, task: TaskDoc) {
  try {
    console.log("========== TASK NOTIFICATION START ==========");
    console.log("TASK ID:", task.id);
    console.log("TASK TITLE:", task.title);
    console.log("AUDIENCE:", task.audience);
    console.log("COMPANY ID:", task.companyId);

    const actorUserId = (req.user as AuthUser | undefined)?.userId || null;

    // Case 1: audience='employee' -> notify only the assigned employee
    if (task.audience === 'employee' && task.assignedTo) {
      const recipientUserId = await resolveUserIdByEmpid(
        task.companyId,
        task.assignedTo
      );

      if (!recipientUserId) {
        console.log(
          'TASK NOTIFICATION: no user found for empid',
          task.assignedTo,
          'in company',
          task.companyId
        );
        return;
      }

      await createAndSend({
        companyId: task.companyId,
        recipientUserId,
        actorUserId,
        type: 'TASK_ASSIGNED',
        title: 'New Task Assigned',
        body: `A new task "${task.title}" has been assigned to you.`,
        entityType: 'task',
        entityId: task.id,
      });
      return;
    }

    // Case 2: audience='all' -> notify all employees in the same company
    if (task.audience === 'all') {
      console.log('[ALL EMPLOYEE NOTIFY] Started');

      const employeesSnapshot = await db
        .collection('users')
        .where('companyId', '==', task.companyId)
        .get();

      console.log('[ALL EMPLOYEE NOTIFY] Users found:', employeesSnapshot.size);

      const employeeSnap = await db
        .collection(COLLECTIONS.USERS)
        .where('companyId', '==', task.companyId)
        .where('role', '==', 'employee')
        .get();

      console.log('[TASK ASSIGNED ALL DEBUG] employees fetched count:', employeeSnap.size);

      if (employeeSnap.empty) {
        console.log('[TASK ASSIGNED ALL DEBUG] no employees found in company');
        console.log('[TASK ASSIGNED ALL DEBUG] ========== END ==========');
        return;
      }

      const userIds = employeeSnap.docs.map(doc => doc.id);

      let totalSent = 0;
      let totalFailed = 0;
      let totalDevices = 0;

      // Send notification to each employee
      await Promise.all(
        userIds.map(async (userId) => {
          try {
            // Check device registrations for this user
            const deviceSnap = await db
              .collection(COLLECTIONS.DEVICE_REGISTRATIONS)
              .where('companyId', '==', task.companyId)
              .where('userId', '==', userId)
              .where('isActive', '==', true)
              .get();

            console.log(`[TASK ASSIGNED ALL DEBUG] device count: ${deviceSnap.size}`);
            totalDevices += deviceSnap.size;

            const result = await createAndSend({
              companyId: task.companyId,
              recipientUserId: userId,
              actorUserId,
              type: 'TASK_ASSIGNED',
              title: 'New Task Assigned',
              body: `"${task.title}" has been assigned to you`,
              entityType: 'task',
              entityId: task.id,
            });
            totalSent += result.sent;
            totalFailed += result.failed;
            console.log(`[TASK ASSIGNED ALL DEBUG] FCM result - sent: ${result.sent}, failed: ${result.failed}`);
          } catch (e: any) {
            totalFailed += 1;
            console.error(
              '[TASK ASSIGNED ALL DEBUG] failed to notify user:',
              e?.message || String(e)
            );
          }
        })
      );

      console.log('[TASK ASSIGNED ALL DEBUG] total devices found:', totalDevices);
      console.log('[TASK ASSIGNED ALL DEBUG] FCM send result - sent:', totalSent, 'failed:', totalFailed);
      console.log('[TASK ASSIGNED ALL DEBUG] ========== END ==========');
    }
  } catch (e: any) {
    console.error('[notifyTaskAssigned] failed:', e?.message || String(e));
  }
}

/**
 * Notifies every admin in the same company that an employee completed an
 * assigned task and uploaded proof. Never throws — a failure here must not
 * fail the task completion response.
 */
async function notifyTaskCompleted(
  req: Request,
  task: TaskDoc,
  empid: string
) {
  try {
    const companyId = task.companyId;
    const actorUserId = (req.user as AuthUser | undefined)?.userId || null;

    // Query for both admin and super_admin roles in the same company
    const adminSnap = await db
      .collection(COLLECTIONS.USERS)
      .where('companyId', '==', companyId)
      .where('role', 'in', ['admin', 'super_admin'])
      .get();

    console.log('[TASK-NOTIFY] companyId:', companyId);
    console.log('[TASK-NOTIFY] empid:', empid);
    console.log('[TASK-NOTIFY] admins found:', adminSnap.size);

    if (adminSnap.empty) {
      return;
    }

    console.log('[TASK-NOTIFY] sending task completion notification');

    const title = 'Task Completed';
    // Conditionally include "and uploaded proof" only when proof was actually attached
    const body = task.title
      ? `${empid} completed "${task.title}"${task.proofFileUrl ? ' and uploaded proof.' : '.'}`
      : `${empid} completed the assigned task${task.proofFileUrl ? ' and uploaded proof.' : '.'}`;

    let sent = 0;
    let failed = 0;

    await Promise.all(
      adminSnap.docs.map(async (adminDoc) => {
        try {
          const result = await createAndSend({
            companyId,
            recipientUserId: adminDoc.id,
            actorUserId,
            type: 'TASK_COMPLETED',
            title,
            body,
            entityType: 'task',
            entityId: task.id,
            data: {
              taskId: task.id,
              employeeId: actorUserId || '',
              empid,
            },
          });
          sent += result.sent;
          failed += result.failed;
        } catch (e: any) {
          failed += 1;
          console.error(
            '[TASK-NOTIFY] failed to notify admin:',
            e?.message || String(e)
          );
        }
      })
    );

    console.log('[TASK-NOTIFY] sent:', sent);
    console.log('[TASK-NOTIFY] failed:', failed);
  } catch (e: any) {
    console.error('[TASK-NOTIFY] notifyTaskCompleted error:', e?.message || String(e));
  }
}

async function trackTaskUsage(

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

    console.error('Usage tracking failed in task:', trackingError);

  }

}



/**
 * Admin: create a task and one assignment per affected employee.
 * - audience='all' creates one task doc and one taskAssignment for every employee.
 * - audience='employee' creates one task doc and one taskAssignment for the selected employee.
 */
export async function createBroadcastTask(req: Request, res: Response) {
  try {
    const companyId = getReqCompanyId(req);
    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized: companyId missing in token' });
    }

    const {
      title = '',
      description = '',
      dueDate = null,
      kind = 'Task',
      audience: rawAudience,
      assignedTo: rawAssignedTo,
    } = (req.body ?? {}) as {
      title?: string;
      description?: string;
      dueDate?: string | null;
      kind?: string;
      audience?: string;
      assignedTo?: string;
    };

    if (!description || !String(description).trim()) {
      return res.status(400).json({ error: 'description is required' });
    }

    const audience = (rawAudience || 'all').toString().toLowerCase().trim() as Audience;
    const assignedTo = (rawAssignedTo || '').toString().trim();

    if (audience === 'employee' && !assignedTo) {
      return res.status(400).json({ error: 'assignedTo (empid) is required when audience="employee"' });
    }

    const docRef = db.collection('tasks').doc();
    const data = makeTaskDoc({
      id: docRef.id,
      title,
      description,
      dueDate,
      kind,
      user: req.user as AuthUser | undefined,
      audience,
      assignedTo: audience === 'employee' ? assignedTo : null,
      companyId,
    });

    await docRef.set(data);
    await createAssignmentsForTask(req, data, { audience, assignedTo });

    await trackTaskUsage(req, {
      writeCount: 1,
      apiCalls: 1,
      taskUploadCount: 1,
    });

    await notifyTaskAssigned(req, data);

    return res.status(201).json(data);
  } catch (e: any) {
    return res
      .status(500)
      .json({ error: 'Failed to create broadcast task', details: e?.message || String(e) });
  }
}



/** 🎯 Admin: create a task for ONE employee (no file) */
export async function createSingleTask(req: Request, res: Response) {
  try {
    const companyId = getReqCompanyId(req);
    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized: companyId missing in token' });
    }

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

    if (!assignedTo || !assignedTo.trim()) {
      return res.status(400).json({ error: 'assignedTo (empid) is required' });
    }

    if (!description || !String(description).trim()) {
      return res.status(400).json({ error: 'description is required' });
    }

    const docRef = db.collection('tasks').doc();
    const data = makeTaskDoc({
      id: docRef.id,
      title,
      description,
      dueDate,
      kind,
      user: req.user as AuthUser | undefined,
      audience: 'employee',
      assignedTo,
      companyId,
    });

    await docRef.set(data);
    await createAssignmentsForTask(req, data, { audience: 'employee', assignedTo });

    await trackTaskUsage(req, {
      writeCount: 1,
      apiCalls: 1,
      taskUploadCount: 1,
    });

    await notifyTaskAssigned(req, data);

    return res.status(201).json(data);
  } catch (e: any) {
    return res
      .status(500)
      .json({ error: 'Failed to create task', details: e?.message || String(e) });
  }
}



/** Employee self-post: create Daily Update for the logged-in user */

export async function createDailyUpdateForSelf(req: Request, res: Response) {

  try {

    const user = req.user as AuthUser | undefined;

    const companyId = getReqCompanyId(req);



    if (!companyId) {

      return res.status(401).json({ error: 'Unauthorized: companyId missing in token' });

    }



    const empid = (user?.empid || '').trim();

    if (!empid) {

      return res.status(400).json({ error: 'empid missing on user token' });

    }



    const {

      description = '',

      title = 'Daily Update',

      dueDate = null,

    } = (req.body ?? {}) as {

      description?: string;

      title?: string;

      dueDate?: string | null;

    };



    if (!description || !String(description).trim()) {

      return res.status(400).json({ error: 'description is required' });

    }



    const docRef = db.collection('tasks').doc();



    const data = makeTaskDoc({

      id: docRef.id,

      title,

      description,

      dueDate,

      kind: 'DailyUpdate',

      user,

      audience: 'employee',

      assignedTo: empid,

      companyId,

    });



    await docRef.set(data);

    

    // Track usage after successful daily update creation

    await trackTaskUsage(req, {

      writeCount: 1,

      apiCalls: 1,

      taskUploadCount: 1,

    });

    

    return res.status(201).json(data);

  } catch (e: any) {

    return res

      .status(500)

      .json({ error: 'Failed to create daily update', details: e?.message || String(e) });

  }

}



/**

 * 👤 User-merged list: return the logged-in employee's own task assignments.
 * Each employee now sees their independent status (assigned / completed).
 * Legacy tasks without an assignment document are shown as 'assigned'.
 */

export async function listTasksForUser(req: Request, res: Response) {
  try {
    const user = req.user as any;
    const companyId = user?.companyId;
    const empid = user?.empid;
    const statusFilter = (req.query.status as string) || 'assigned';

    console.log('[TASKS USER] statusFilter =', statusFilter);

    if (!companyId || !empid) {
      return res.status(401).json({ error: 'Unauthorized: companyId or empid missing in token' });
    }

    // 1) Fetch all company tasks (for metadata and visibility) and this employee's assignments
    const [companyTasksSnapshot, assignmentSnapshot] = await Promise.all([
      db.collection('tasks').where('companyId', '==', companyId).get(),
      db
        .collection(COLLECTIONS.TASK_ASSIGNMENTS)
        .where('companyId', '==', companyId)
        .where('employeeId', '==', empid)
        .get(),
    ]);

    const taskMap = new Map<string, any>();
    companyTasksSnapshot.docs.forEach(doc => {
      taskMap.set(doc.id, { id: doc.id, ...doc.data() });
    });

    const result: any[] = [];

    // Track all task IDs for which this employee has *any* assignment so the
    // legacy fallback below does not treat an existing completed assignment as
    // an unassigned (legacy) task and show it again under the Assigned tab.
    const employeeAssignmentTaskIds = new Set<string>(
      assignmentSnapshot.docs.map(doc => (doc.data() as any).taskId)
    );

    // 2) Build list from the employee's assignments, merging in task metadata
    assignmentSnapshot.docs.forEach(doc => {
      const assignment = { id: doc.id, ...doc.data() } as any;
      const task = taskMap.get(assignment.taskId);
      if (!task) return;

      if (statusFilter !== 'all' && assignment.status !== statusFilter) {
        return;
      }

      result.push({
        ...task,
        assignmentId: assignment.id,
        status: assignment.status,
        assignedAt: assignment.assignedAt || null,
        completedAt: assignment.completedAt || null,
        completedBy: assignment.completedBy || null,
        completionNote: assignment.completionNote || null,
        proofFileUrl: assignment.proofFileUrl || null,
        updatedAt: assignment.updatedAt || null,
      });
    });

    // 3) Backward-compat: show legacy tasks the employee can see but doesn't have an assignment for yet.
    //    They are treated as 'assigned' (one employee's existing completion should NOT mark them for everyone).
    companyTasksSnapshot.docs.forEach(doc => {
      const task = { id: doc.id, ...doc.data() } as any;
      const audience = (task.audience || 'all').toLowerCase();
      const isVisible =
        audience === 'all' ||
        (audience === 'employee' && task.assignedTo === empid);
      const alreadyIncluded = result.some(r => r.id === task.id);
      const hasAssignment = employeeAssignmentTaskIds.has(task.id);

      if (isVisible && !alreadyIncluded && !hasAssignment) {
        if (statusFilter !== 'all' && statusFilter !== 'assigned') return;
        result.push({
          ...task,
          status: 'assigned',
          completedAt: null,
          completedBy: null,
          completionNote: null,
          proofFileUrl: null,
        });
      }
    });

    result.sort((a, b) => {
      const aTime = a.createdAt ? new Date(a.createdAt).getTime() : 0;
      const bTime = b.createdAt ? new Date(b.createdAt).getTime() : 0;
      return bTime - aTime;
    });

    console.log('[TASKS USER] Filtered to', result.length, 'tasks for employee');

    return res.status(200).json(result);

  } catch (error: any) {
    console.error('[TASKS USER ERROR] Failed to fetch tasks');
    return res.status(500).json({
      error: 'Failed to fetch tasks for user',
      details: error?.message || String(error),
    });
  }
}

/**
 * Admin-only list: Returns ALL tasks for the admin's company, including
 * per-employee assignment progress and an overall derived status.
 */
export async function listEmployeeTasks(req: Request, res: Response) {
  try {
    const companyId = getReqCompanyId(req);


    if (!companyId) {
      return res.status(401).json({
        error: 'Unauthorized: companyId missing in token',
      });
    }

    const [taskSnap, assignmentSnap] = await Promise.all([
      db.collection('tasks').where('companyId', '==', companyId).get(),
      db.collection(COLLECTIONS.TASK_ASSIGNMENTS).where('companyId', '==', companyId).get(),
    ]);

    const assignmentsByTask = new Map<string, any[]>();
    assignmentSnap.docs.forEach(d => {
      const a = { id: d.id, ...d.data() } as any;
      if (!assignmentsByTask.has(a.taskId)) {
        assignmentsByTask.set(a.taskId, []);
      }
      assignmentsByTask.get(a.taskId)!.push(a);
    });

    const items = taskSnap.docs.map((d) => {
      const task = { id: d.id, ...d.data() } as any;
      const taskAssignments = assignmentsByTask.get(d.id) || [];
      const total = taskAssignments.length;
      const completed = taskAssignments.filter((a: any) => a.status === 'completed').length;

      let overallStatus = 'assigned';
      if (total > 0) {
        if (completed === 0) overallStatus = 'assigned';
        else if (completed === total) overallStatus = 'completed';
        else overallStatus = 'in_progress';
      }

      return {
        ...task,
        status: overallStatus,
        completedCount: completed,
        totalAssignments: total,
        assignments: taskAssignments,
      };
    });

    items.sort((a: any, b: any) => {
      const ad = Date.parse(a?.createdAt || '') || 0;
      const bd = Date.parse(b?.createdAt || '') || 0;
      return bd - ad;
    });

    console.log('[ADMIN TASKS] Returning tasks:', items.length);

    return res.status(200).json(items);
  } catch (e: any) {
    console.error('[ADMIN TASKS ERROR] Failed to fetch admin tasks');
    return res.status(500).json({
      error: 'Failed to fetch employee tasks',
      details: e?.message || String(e),
    });
  }
}


/** 🔎 Get a single task by id (with per-employee status for employees) */
export async function getTask(req: Request, res: Response): Promise<Response> {
  try {
    const companyId = getReqCompanyId(req);
    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized: companyId missing in token' });
    }

    const id = (req.params.id || '').trim();
    if (!id) {
      return res.status(400).json({ error: 'id is required' });
    }

    const snap = await db.collection('tasks').doc(id).get();
    if (!snap.exists) {
      return res.status(404).json({ error: 'Not found' });
    }

    const data = snap.data();
    if (!data || data.companyId !== companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const currentUser = req.user as AuthUser | undefined;
    const isAuthorizedAdmin =
      currentUser?.role === 'admin' || currentUser?.role === 'super_admin';
    const audience = (data.audience || 'all').toString().toLowerCase();
    const isAssignedEmployee =
      audience === 'employee' &&
      !!currentUser?.empid &&
      data.assignedTo === currentUser.empid;
    const isBroadcastToCompany = audience !== 'employee';

    if (!isAuthorizedAdmin && !isAssignedEmployee && !isBroadcastToCompany) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // For employees, merge in their own assignment status
    if (!isAuthorizedAdmin && currentUser?.empid) {
      const empid = currentUser.empid;
      const assignmentSnap = await db
        .collection(COLLECTIONS.TASK_ASSIGNMENTS)
        .where('companyId', '==', companyId)
        .where('taskId', '==', id)
        .where('employeeId', '==', empid)
        .limit(1)
        .get();

      if (!assignmentSnap.empty) {
        const a = { id: assignmentSnap.docs[0].id, ...assignmentSnap.docs[0].data() } as any;
        return res.json({
          ...data,
          status: a.status,
          assignmentId: a.id,
          assignedAt: a.assignedAt || null,
          completedAt: a.completedAt || null,
          completedBy: a.completedBy || null,
          completionNote: a.completionNote || null,
          proofFileUrl: a.proofFileUrl || null,
        });
      }

      // Legacy task without an assignment - shown as assigned to this employee
      return res.json({
        ...data,
        status: 'assigned',
        completedAt: null,
        completedBy: null,
        completionNote: null,
        proofFileUrl: null,
      });
    }

    return res.json(data);

  } catch (e: any) {
    return res.status(500).json({
      error: 'Failed to fetch task',
      details: e?.message ?? String(e),
    });
  }
}

/**
 * 🔗 Admin: Get signed URL for an employee's task proof file.
 * Accepts an optional ?empid= query; otherwise returns the first completed
 * assignment's proof for the task.
 */
export async function getTaskProofUrl(req: Request, res: Response): Promise<Response> {
  try {
    const companyId = getReqCompanyId(req);

    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized: companyId missing in token' });
    }

    const taskId = (req.params.id || '').trim();
    if (!taskId) {
      return res.status(400).json({ error: 'Task ID is required' });
    }

    const empid = ((req.query.empid as string) || '').trim();

    // Verify the task exists and belongs to the admin's company
    const snap = await db.collection('tasks').doc(taskId).get();
    if (!snap.exists) {
      return res.status(404).json({ error: 'Task not found' });
    }

    const data = snap.data();
    if (!data || data.companyId !== companyId) {
      console.log('[TASK PROOF URL] Access denied: company mismatch');
      return res.status(403).json({ error: 'Access denied' });
    }

    // Find the assignment that carries the proof file
    let query = db
      .collection(COLLECTIONS.TASK_ASSIGNMENTS)
      .where('companyId', '==', companyId)
      .where('taskId', '==', taskId)
      .where('status', '==', 'completed');

    if (empid) {
      query = query.where('employeeId', '==', empid);
    }

    const assignmentSnap = await query.limit(1).get();
    if (assignmentSnap.empty) {
      return res.status(404).json({ error: 'No proof file attached for this employee' });
    }

    const proofFileUrl = assignmentSnap.docs[0].data().proofFileUrl;
    if (!proofFileUrl) {
      return res.status(404).json({ error: 'No proof file attached' });
    }

    console.log('[TASK PROOF URL] Generating signed URL');
    const signedUrl = await getTaskProofSignedUrl(proofFileUrl);
    console.log('[TASK PROOF URL] Signed URL generated successfully');

    return res.status(200).json({
      success: true,
      url: signedUrl,
    });
  } catch (e: any) {
    console.error('[TASK PROOF URL ERROR] Failed to generate signed URL');
    return res.status(500).json({
      error: 'Failed to generate proof URL',
      details: e?.message ?? String(e),
    });
  }
}

/**
 * ✅ Employee: mark an assigned task as completed, optionally attaching a
 * proof file. This now updates the per-employee task assignment instead of
 * the shared task document. On success it notifies same-company admins.
 * Notification failures never fail this endpoint's response.
 */
export async function completeTask(req: Request, res: Response): Promise<Response> {
  try {
    console.log('[COMPLETE-TASK] Content-Type:', req.headers['content-type']);
    console.log('[COMPLETE-TASK] Request file:', req.file ? 'File present' : 'No file');

    const user = req.user as AuthUser | undefined;
    const companyId = getReqCompanyId(req);

    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized: companyId missing in token' });
    }

    const empid = (user?.empid || '').trim();
    if (!empid) {
      return res.status(400).json({ error: 'empid missing on user token' });
    }

    const id = (req.params.id || '').trim();
    if (!id) {
      return res.status(400).json({ error: 'id is required' });
    }

    const taskRef = db.collection('tasks').doc(id);
    const taskSnap = await taskRef.get();

    if (!taskSnap.exists) {
      return res.status(404).json({ error: 'Not found' });
    }

    const task = { id, ...(taskSnap.data() as Omit<TaskDoc, 'id'>) };

    if (task.companyId !== companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Authorization: employee can complete task if:
    // 1. audience='employee' and assignedTo matches their empid (individual task)
    // 2. audience='all' and companyId matches their company (broadcast task)
    const isIndividualTask =
      task.audience === 'employee' &&
      task.assignedTo === empid;

    const isBroadcastTask =
      task.audience === 'all' &&
      task.companyId === companyId;

    if (!isIndividualTask && !isBroadcastTask) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Locate (or create on-the-fly for legacy tasks) this employee's assignment
    const assignmentQuery = await db
      .collection(COLLECTIONS.TASK_ASSIGNMENTS)
      .where('companyId', '==', companyId)
      .where('taskId', '==', id)
      .where('employeeId', '==', empid)
      .limit(1)
      .get();

    let assignmentRef: FirebaseFirestore.DocumentReference;
    let assignment: TaskAssignmentDoc;
    const nowIso = new Date().toISOString();

    if (assignmentQuery.empty) {
      // Backward-compat: old tasks that don't have an assignment document yet
      assignmentRef = db.collection(COLLECTIONS.TASK_ASSIGNMENTS).doc();
      assignment = makeTaskAssignmentDoc({
        id: assignmentRef.id,
        companyId,
        taskId: id,
        employeeId: empid,
        user,
      });
    } else {
      const doc = assignmentQuery.docs[0];
      assignmentRef = doc.ref;
      assignment = { id: doc.id, ...(doc.data() as Omit<TaskAssignmentDoc, 'id'>) };
    }

    // Prevent duplicate completion: don't overwrite completedAt, completedBy,
    // completionNote, or proofFileUrl for an already completed assignment.
    if (assignment.status === 'completed') {
      return res.status(400).json({
        error: 'This task has already been completed.',
        assignmentId: assignment.id,
        status: 'completed',
      });
    }

    // Handle both JSON and multipart requests
    const { description = '' } = (req.body ?? {}) as { description?: string };

    let proofFileUrl: string | null = null;
    if (req.file) {
      console.log('[COMPLETE-TASK] Starting task proof upload');
      try {
        // Store proof under task/employee path to keep employee uploads separate
        proofFileUrl = await uploadTaskProofToFirebase(req.file, `${id}/${empid}`);
        console.log('[COMPLETE-TASK] Task proof upload successful');
      } catch (uploadError: any) {
        console.error('[COMPLETE-TASK] Task proof upload error occurred');
        throw uploadError;
      }
    }

    assignment.status = 'completed';
    assignment.completedAt = nowIso;
    assignment.completedBy = user?.userId || null;
    assignment.completionNote = (description || '').toString().trim() || null;
    assignment.proofFileUrl = proofFileUrl;
    assignment.updatedAt = nowIso;

    // 1) Save completion to the per-employee assignment first.
    await assignmentRef.set(assignment, { merge: true });

    console.log('[TASK-NOTIFY] completion save success');

    // 2) Notify admins with a TaskDoc-shaped payload (title/proofFileUrl used in message).
    try {
      const notifyPayload: TaskDoc = {
        ...task,
        proofFileUrl: proofFileUrl ?? undefined,
      };
      await notifyTaskCompleted(req, notifyPayload, empid);
    } catch (e: any) {
      console.error('[TASK-NOTIFY] unexpected error occurred');
    }

    return res.status(200).json(assignment);
  } catch (e: any) {
    return res.status(500).json({
      error: 'Failed to complete task',
      details: e?.message || String(e),
    });
  }
}