import { Request, Response } from 'express';

import { db } from '../config/firebase';

import { trackUsage } from '../services/usageService';



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

  status: 'assigned';

  createdBy: string;

  createdAt: string; // ISO

  updatedAt: string; // ISO

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



/** Admin: create a broadcast task (no file)

 *  BACKWARD-COMPAT: also supports audience='employee' + assignedTo for single-employee create

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



    if (audience === 'employee') {

      if (!assignedTo) {

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

        audience: 'employee',

        assignedTo,

        companyId,

      });



      await docRef.set(data);

      await trackTaskUsage(req, {

        writeCount: 1,

        apiCalls: 1,

        taskUploadCount: 1,

      });

      return res.status(201).json(data);

    }



    const docRef = db.collection('tasks').doc();

    const data = makeTaskDoc({

      id: docRef.id,

      title,

      description,

      dueDate,

      kind,

      user: req.user as AuthUser | undefined,

      audience: 'all',

      companyId,

    });



    await docRef.set(data);

    await trackTaskUsage(req, {

      writeCount: 1,

      apiCalls: 1,

      taskUploadCount: 1,

    });

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

    

    // Track usage after successful task creation

    await trackTaskUsage(req, {

      writeCount: 1,

      apiCalls: 1,

      taskUploadCount: 1,

    });

    

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

 * 👤 User-merged list: broadcast + personal
 * - If empid is provided (query or token), return only tasks assigned to that empid.
 * - If empid is missing, still return ALL personal tasks for the same company.
 */

export async function listTasksForUser(req: Request, res: Response) {
  try {
    console.log('[TASKS USER] Request started');
    console.log('[TASKS USER] req.user =', JSON.stringify(req.user, null, 2));
    
    // Get user info from auth middleware
    const user = req.user as any;
    const companyId = user?.companyId;
    const empid = user?.empid;
    const role = user?.role;

    console.log('[TASKS USER] role =', role);
    console.log('[TASKS USER] empid =', empid);
    console.log('[TASKS USER] companyId =', companyId);

    if (!companyId) {
      console.log('[TASKS USER] Missing companyId, returning 401');
      return res.status(401).json({ error: 'Unauthorized: companyId missing in token' });
    }

    console.log('[TASKS USER] Fetching all tasks for companyId:', companyId);
    
    // Fetch all tasks for the company first
    const companyTasksSnapshot = await db
      .collection('tasks')
      .where('companyId', '==', companyId)
      .get();

    console.log('[TASKS USER] Found', companyTasksSnapshot.docs.length, 'total tasks for company');

    // Filter tasks in JavaScript (safer than complex Firestore queries)
    const filteredTasks = companyTasksSnapshot.docs
      .map(doc => {
        const data = doc.data();
        return {
          id: doc.id,
          companyId: data?.companyId || '',
          title: data?.title || '',
          description: data?.description || '',
          audience: data?.audience || 'all',
          assignedTo: data?.assignedTo || null,
          dueDate: data?.dueDate || null,
          kind: data?.kind || 'Task',
          status: data?.status || 'assigned',
          createdBy: data?.createdBy || '',
          createdAt: data?.createdAt || '',
          updatedAt: data?.updatedAt || '',
          file: data?.file || null, // Handle null file safely
        };
      })
      .filter(task => {
        // Filter for assigned status
        if (task.status !== 'assigned') {
          return false;
        }

        // Employee can see tasks if:
        // 1. audience is "all" (broadcast to all employees)
        // 2. audience is "employee" and assignedTo matches their empid
        // 3. audience is missing (treat as "all")
        const audience = (task.audience || 'all').toLowerCase();
        
        if (audience === 'all') {
          return true; // Anyone in company can see
        }
        
        if (audience === 'employee' && empid && task.assignedTo === empid) {
          return true; // Assigned specifically to this employee
        }
        
        return false; // Not visible to this employee
      });

    // Sort by createdAt (newest first)
    filteredTasks.sort((a, b) => {
      const aTime = a.createdAt ? new Date(a.createdAt).getTime() : 0;
      const bTime = b.createdAt ? new Date(b.createdAt).getTime() : 0;
      return bTime - aTime;
    });

    console.log('[TASKS USER] Filtered to', filteredTasks.length, 'tasks for employee');
    console.log('[TASKS USER] Returning tasks:', JSON.stringify(filteredTasks, null, 2));

    // Return 200 with filtered tasks (empty array if none)
    return res.status(200).json(filteredTasks);

  } catch (error: any) {
    console.error('[TASKS USER ERROR]', error);
    console.error('[TASKS USER ERROR MESSAGE:', error.message);
    console.error('[TASKS USER ERROR STACK:', error.stack);
    
    // Return 200 with empty array instead of 500
    return res.status(200).json([]);
  }
}

/**
 * Employee-only list:
 * - If empid is provided (query), returns tasks for that empid in the same company.
 * - If empid is missing, returns ALL employee tasks in the same company.
 */
export async function listEmployeeTasks(req: Request, res: Response) {
  try {
    const companyId = getReqCompanyId(req);

    if (!companyId) {
      return res.status(401).json({
        error: 'Unauthorized: companyId missing in token',
      });
    }

    const snap = await db
      .collection('tasks')
      .where('companyId', '==', companyId)
      .get();

    let items = snap.docs.map((d) => {
      const data = d.data();

      return {
        id: d.id,
        companyId: data.companyId || '',
        title: data.title || '',
        description: data.description || '',
        audience: data.audience || 'all',
        assignedTo: data.assignedTo || null,
        dueDate: data.dueDate || null,
        kind: data.kind || 'Task',
        status: data.status || 'assigned',
        createdBy: data.createdBy || '',
        createdAt: data.createdAt || '',
        updatedAt: data.updatedAt || '',
        file: data.file || null,
      };
    });

    // Filter only by status = "assigned"
    // Return all matching records including Task and DailyUpdate
    items = items.filter((task: any) => {
      return task.status === 'assigned';
    });

    items.sort((a: any, b: any) => {
      const ad = Date.parse(a?.createdAt || '') || 0;
      const bd = Date.parse(b?.createdAt || '') || 0;
      return bd - ad;
    });

    return res.status(200).json(items);
  } catch (e: any) {
    return res.status(500).json({
      error: 'Failed to fetch employee tasks',
      details: e?.message || String(e),
    });
  }
}


/** 🔎 Get a single task by id */

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



    return res.json(data);

  } catch (e: any) {

    return res.status(500).json({

      error: 'Failed to fetch task',

      details: e?.message ?? String(e),

    });

  }

}