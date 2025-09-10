import { Request, Response } from 'express';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/* ============================== Types ============================== */

type LeaveType =
  | 'Casual Leave'
  | 'Planned Leave'
  | 'Sick Leave'
  | 'Half-Day'
  | 'Overtime'
  | 'Permission Time'
  | 'Comp Off';

type LeaveStatus = 'Pending' | 'Approved' | 'Rejected' | 'Cancelled';

interface LeaveRequest {
  id?: string;
  userId: string;
  empid: string;
  name: string;
  leaveType: LeaveType;
  startDate: string; // YYYY-MM-DD
  endDate: string;   // YYYY-MM-DD
  reason: string;
  status: LeaveStatus;
  // Optional/conditional
  session?: 'Morning' | 'Afternoon'; // Half-day
  duration?: number; // hours (Overtime/Permission Time)
  attachmentUrl?: string; // generic attachment
  documentUrl?: string;   // compatibility
  imageUrl?: string;      // compatibility
  selectShift?: string | null; // compatibility/metadata
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
  requestedAt?: admin.firestore.Timestamp; // compatibility
  // For audit/approvals
  approverId?: string;
  approverNotes?: string;
}

/* ============================== Helpers ============================== */

const VALID_TYPES: LeaveType[] = [
  'Casual Leave',
  'Planned Leave',
  'Sick Leave',
  'Half-Day',
  'Overtime',
  'Permission Time',
  'Comp Off',
];

const toYMD = (v: any): string => {
  if (!v) return '';
  if (typeof v === 'string') {
    // Accept "YYYY-MM-DD" or ISO; normalize to Y-M-D
    try {
      if (/^\d{4}-\d{2}-\d{2}$/.test(v)) return v;
      return new Date(v).toISOString().slice(0, 10);
    } catch {
      return '';
    }
  }
  try {
    return new Date(v).toISOString().slice(0, 10);
  } catch {
    return '';
  }
};

const clampRange = (start: string, end: string): { start: string; end: string } => {
  const s = toYMD(start);
  const e = toYMD(end);
  if (!s || !e) return { start: '', end: '' };
  if (new Date(e) < new Date(s)) return { start: '', end: '' };
  return { start: s, end: e };
};

/**
 * Normalize incoming body supporting BOTH:
 *  - new TS shape (leaveType/startDate/endDate/session/duration/attachmentUrl)
 *  - old JS shape (type/fromDate/toDate/selectDate/selectShift/startTime/endTime/documentUrl/imageUrl)
 */
function normalizeCreatePayload(
  currentUser: any,
  raw: any,
  empName: string
): { data?: Omit<LeaveRequest, 'id'>; error?: string } {
  let {
    leaveType,
    startDate,
    endDate,
    reason,
    session,
    duration,
    attachmentUrl,
    // compatibility fields:
    type,
    fromDate,
    toDate,
    selectDate,
    selectShift,
    startTime,
    endTime,
    documentUrl,
    imageUrl,
  } = raw || {};

  // Map legacy 'type' to 'leaveType'
  if (!leaveType && type) leaveType = type;

  if (!leaveType || !VALID_TYPES.includes(leaveType)) {
    return { error: 'Invalid or missing leaveType' };
  }
  if (!reason) return { error: 'Missing reason' };

  const nowTs = admin.firestore.Timestamp.now();
  const base: Omit<LeaveRequest, 'id'> = {
    userId: currentUser.userId,
    empid: currentUser.empid,
    name: empName,
    leaveType,
    startDate: '',
    endDate: '',
    reason: String(reason),
    status: 'Pending',
    createdAt: nowTs,
    updatedAt: nowTs,
    requestedAt: nowTs,
  };

  // Attachments (any provided is kept)
  if (attachmentUrl) base.attachmentUrl = String(attachmentUrl);
  if (documentUrl) base.documentUrl = String(documentUrl);
  if (imageUrl) base.imageUrl = String(imageUrl);
  if (selectShift) base.selectShift = String(selectShift);

  // Branch by leave type
  if (leaveType === 'Overtime' || leaveType === 'Permission Time') {
    // Expect selectDate + startTime + endTime OR startDate==endDate + duration
    const date = toYMD(selectDate || startDate);
    if (!date) return { error: 'selectDate/startDate required for Overtime/Permission' };

    // Prefer explicit duration if provided
    if (duration != null) {
      const dur = Number(duration);
      if (!(dur > 0)) return { error: 'duration must be > 0 (hours)' };
      base.duration = dur;
    } else {
      if (!startTime || !endTime) {
        return { error: 'startTime and endTime are required (or provide duration)' };
      }
      // naive diff in hours
      const start = new Date(`${date}T${String(startTime).padStart(5, '0')}:00`);
      const end = new Date(`${date}T${String(endTime).padStart(5, '0')}:00`);
      if (isNaN(start.getTime()) || isNaN(end.getTime()) || end <= start) {
        return { error: 'Invalid startTime/endTime' };
      }
      base.duration = (end.getTime() - start.getTime()) / 3600000;
    }

    base.startDate = date;
    base.endDate = date;
    return { data: base };
  }

  if (leaveType === 'Half-Day') {
    const date = toYMD(selectDate || startDate || fromDate);
    if (!date) return { error: 'selectDate/startDate/fromDate required for Half-Day' };

    const ses =
      session ||
      ((String(selectShift || '').toLowerCase().includes('morning') ? 'Morning' : undefined) ??
        (String(selectShift || '').toLowerCase().includes('afternoon') ? 'Afternoon' : undefined));
    if (!ses) return { error: 'session is required for Half-Day (Morning/Afternoon)' };

    base.startDate = date;
    base.endDate = date;
    base.session = ses as 'Morning' | 'Afternoon';
    return { data: base };
  }

  // Multi-day (Casual/Planned/Sick/Comp Off)
  const s = toYMD(startDate || fromDate);
  const e = toYMD(endDate || toDate);
  const { start, end } = clampRange(s, e);
  if (!start || !end) return { error: 'Invalid startDate/endDate' };

  base.startDate = start;
  base.endDate = end;
  return { data: base };
}

/* ============================== Controllers ============================== */

// Create (compat + new)
export const createLeaveRequest = async (req: Request, res: Response): Promise<Response> => {
  try {
    const currentUser = (req as any).user;

    // Resolve employee display name
    let empName = '';
    // Try employees (empid)
    const empSnap = await db.collection('employees').where('empid', '==', currentUser.empid).limit(1).get();
    if (!empSnap.empty) {
      const e = empSnap.docs[0].data() as any;
      empName = [e.firstName, e.lastName].filter(Boolean).join(' ') || e.name || '';
    }
    // Fallback to users doc (legacy)
    if (!empName) {
      const usr = await db.collection('users').doc(currentUser.userId).get();
      if (usr.exists) {
        const u = usr.data() as any;
        empName = u.name || `${u.firstName ?? ''} ${u.lastName ?? ''}`.trim();
      }
    }

    const norm = normalizeCreatePayload(currentUser, req.body, empName || 'Employee');
    if (norm.error) return res.status(400).json({ error: norm.error });

    const payload = norm.data!;

    // Overlap check only for full-day and half-day (skip OT/Permission)
    if (payload.leaveType !== 'Overtime' && payload.leaveType !== 'Permission Time') {
      const overlap = await db
        .collection('leaves')
        .where('userId', '==', currentUser.userId)
        .where('status', 'in', ['Pending', 'Approved'])
        .where('startDate', '<=', payload.endDate)
        .where('endDate', '>=', payload.startDate)
        .get();
      if (!overlap.empty) {
        return res.status(400).json({ error: 'You already have a leave request for the selected date range' });
      }
    }

    const ref = await db.collection('leaves').add(payload);
    const snap = await ref.get();
    return res.status(201).json({ id: ref.id, ...snap.data() });
  } catch (error) {
    console.error('Error creating leave request:', error);
    return res.status(500).json({ error: 'Failed to create leave request' });
  }
};

// Get all (admin) with filters + pagination
export const getAllLeaveRequests = async (req: Request, res: Response): Promise<Response> => {
  try {
    const currentUser = (req as any).user;
    const { status, userId, startDate, endDate, page = '1', limit = '10' } = req.query;

    if (currentUser.role !== 'admin' && userId !== currentUser.userId) {
      return res.status(403).json({ error: 'Unauthorized to view these leave requests' });
    }

    let query: FirebaseFirestore.Query<FirebaseFirestore.DocumentData> = db.collection('leaves');

    if (status) query = query.where('status', '==', status);
    if (userId) query = query.where('userId', '==', userId);

    if (startDate && endDate) {
      query = query.where('startDate', '<=', String(endDate)).where('endDate', '>=', String(startDate));
    }

    // Total
    const all = await query.get();
    const total = all.size;

    // Page
    const pageNum = parseInt(String(page), 10);
    const limitNum = parseInt(String(limit), 10);
    const offset = Math.max(0, (pageNum - 1) * limitNum);

    const pageSnap = await query.orderBy('createdAt', 'desc').offset(offset).limit(limitNum).get();

    return res.status(200).json({
      data: pageSnap.docs.map((d) => ({ id: d.id, ...d.data() })),
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        pages: Math.ceil(total / limitNum),
      },
    });
  } catch (error) {
    console.error('Error fetching leave requests:', error);
    return res.status(500).json({ error: 'Failed to fetch leave requests' });
  }
};

// Current user's list
export const getMyLeaveRequests = async (req: Request, res: Response): Promise<Response> => {
  try {
    const currentUser = (req as any).user;
    const { status, startDate, endDate } = req.query;

    let query: FirebaseFirestore.Query = db.collection('leaves').where('userId', '==', currentUser.userId);
    if (status) query = query.where('status', '==', status);
    if (startDate && endDate) {
      query = query.where('startDate', '<=', String(endDate)).where('endDate', '>=', String(startDate));
    }

    const snap = await query.orderBy('createdAt', 'desc').get();
    return res.status(200).json(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
  } catch (error) {
    console.error('Error fetching my leave requests:', error);
    return res.status(500).json({ error: 'Failed to fetch your leave requests' });
  }
};

// Single by id (requester/admin/approver)
export const getLeaveRequestById = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { id } = req.params;
    const currentUser = (req as any).user;

    const doc = await db.collection('leaves').doc(id).get();
    if (!doc.exists) return res.status(404).json({ error: 'Leave request not found' });

    const data = doc.data() as LeaveRequest;
    if (
      data.userId !== currentUser.userId &&
      currentUser.role !== 'admin' &&
      data.approverId !== currentUser.userId
    ) {
      return res.status(403).json({ error: 'Unauthorized to view this leave request' });
    }

    return res.status(200).json({ id: doc.id, ...data });
  } catch (error) {
    console.error('Error fetching leave request:', error);
    return res.status(500).json({ error: 'Failed to fetch leave request' });
  }
};

// Approve/Reject/Cancel (admin)
export const updateLeaveStatus = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;
    const currentUser = (req as any).user;

    if (currentUser.role !== 'admin') {
      return res.status(403).json({ error: 'Unauthorized to update this leave request' });
    }

    if (!['Approved', 'Rejected', 'Cancelled'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    const ref = db.collection('leaves').doc(id);
    const snap = await ref.get();
    if (!snap.exists) return res.status(404).json({ error: 'Leave request not found' });

    const data = snap.data() as LeaveRequest;
    if (data.status === 'Cancelled') {
      return res.status(400).json({ error: 'Cannot update a cancelled leave request' });
    }

    const updates: Partial<LeaveRequest> = {
      status,
      approverId: currentUser.userId,
      approverNotes: notes || undefined,
      updatedAt: admin.firestore.Timestamp.now(),
    };

    await ref.update(updates);
    const updated = await ref.get();
    return res.status(200).json({ id: updated.id, ...updated.data() });
  } catch (error) {
    console.error('Error updating leave status:', error);
    return res.status(500).json({ error: 'Failed to update leave status' });
  }
};

// Cancel (requester or admin)
export const cancelLeaveRequest = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { id } = req.params;
    const currentUser = (req as any).user;

    const ref = db.collection('leaves').doc(id);
    const snap = await ref.get();
    if (!snap.exists) return res.status(404).json({ error: 'Leave request not found' });

    const data = snap.data() as LeaveRequest;
    if (data.userId !== currentUser.userId && currentUser.role !== 'admin') {
      return res.status(403).json({ error: 'Unauthorized to cancel this leave request' });
    }
    if (data.status !== 'Pending') {
      return res.status(400).json({ error: 'Only pending leave requests can be cancelled' });
    }

    await ref.update({ status: 'Cancelled', updatedAt: admin.firestore.Timestamp.now() });
    const updated = await ref.get();
    return res.status(200).json({ id: updated.id, ...updated.data() });
  } catch (error) {
    console.error('Error cancelling leave request:', error);
    return res.status(500).json({ error: 'Failed to cancel leave request' });
  }
};

// Leave balance (simple example)
export const getLeaveBalance = async (req: Request, res: Response): Promise<Response> => {
  try {
    const currentUser = (req as any).user;
    const empSnap = await db.collection('employees').where('empid', '==', currentUser.empid).limit(1).get();
    if (empSnap.empty) return res.status(404).json({ error: 'Employee not found' });

    const e = empSnap.docs[0].data() as any;
    const leaveBalance = {
      casualLeaves: e.leaveBalance?.casualLeaves ?? 12,
      sickLeaves: e.leaveBalance?.sickLeaves ?? 12,
      plannedLeaves: e.leaveBalance?.plannedLeaves ?? 10,
      compOff: e.leaveBalance?.compOff ?? 0,
    };
    return res.status(200).json(leaveBalance);
  } catch (error) {
    console.error('Error fetching leave balance:', error);
    return res.status(500).json({ error: 'Failed to fetch leave balance' });
  }
};

/* ============================== Extra endpoints for backward-compat ============================== */

// GET /api/leaves/pending?type=...
export const getPendingLeaves = async (req: Request, res: Response): Promise<Response> => {
  try {
    const t = req.query.type ? String(req.query.type) : undefined;
    let q: FirebaseFirestore.Query = db.collection('leaves').where('status', '==', 'Pending');
    if (t) q = q.where('leaveType', '==', t);
    const snaps = await q.orderBy('createdAt', 'desc').get();
    return res.json(snaps.docs.map((d) => ({ id: d.id, ...d.data() })));
  } catch (err) {
    console.error('getPendingLeaves error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

// DELETE /api/leaves/:id (admin)
export const deleteLeave = async (req: Request, res: Response): Promise<Response> => {
  try {
    await db.collection('leaves').doc(req.params.id).delete();
    return res.json({ message: 'Request deleted' });
  } catch (err) {
    console.error('deleteLeave error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

/* Aliases to match old JS controller names (optional) */
export const createLeave = createLeaveRequest;
export const getMyLeaves = getMyLeaveRequests;
export const getAllLeaves = getAllLeaveRequests;
export const getLeaveById = getLeaveRequestById;
export const updateLeave = updateLeaveStatus;
