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
  startDate: string; // YYYY-MM-DD (inclusive)
  endDate: string;   // YYYY-MM-DD (inclusive)
  reason: string;
  status: LeaveStatus;
  session?: 'Morning' | 'Afternoon';
  duration?: number;               // hours (OT/Permission)
  attachmentUrl?: string;
  documentUrl?: string;
  imageUrl?: string;
  selectShift?: string | null;
  workedDate?: string;             // YYYY-MM-DD (reference day actually worked for Comp Off)
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
  requestedAt?: admin.firestore.Timestamp;
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
    // legacy fields:
    type,
    fromDate,
    toDate,
    selectDate,
    selectShift,
    startTime,
    endTime,
    documentUrl,
    imageUrl,
    workedDate,
  } = raw || {};

  if (!leaveType && type) leaveType = type;
  if (!leaveType || !VALID_TYPES.includes(leaveType)) return { error: 'Invalid or missing leaveType' };
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

  if (attachmentUrl) base.attachmentUrl = String(attachmentUrl);
  if (documentUrl)   base.documentUrl   = String(documentUrl);
  if (imageUrl)      base.imageUrl      = String(imageUrl);
  if (selectShift)   base.selectShift   = String(selectShift);

  // ---------------- Overtime / Permission Time ----------------
  if (leaveType === 'Overtime' || leaveType === 'Permission Time') {
    const date = toYMD(selectDate || startDate);
    if (!date) return { error: 'selectDate/startDate required for Overtime/Permission' };

    if (duration != null) {
      const d = Number(duration);
      if (!(d > 0)) return { error: 'duration must be > 0 (hours)' };
      base.duration = d;
    } else {
      if (!startTime || !endTime) return { error: 'startTime and endTime are required (or provide duration)' };
      const st = new Date(`${date}T${String(startTime).padStart(5, '0')}:00`);
      const et = new Date(`${date}T${String(endTime ).padStart(5, '0')}:00`);
      if (isNaN(st.getTime()) || isNaN(et.getTime()) || et <= st) return { error: 'Invalid startTime/endTime' };
      base.duration = (et.getTime() - st.getTime()) / 3600000;
    }

    base.startDate = date;
    base.endDate   = date;
    return { data: base };
  }

  // ---------------- Half-Day ----------------
  if (leaveType === 'Half-Day') {
    const date = toYMD(selectDate || startDate || fromDate);
    if (!date) return { error: 'selectDate/startDate/fromDate required for Half-Day' };

    const ses =
      'session' in (raw || {}) && session
        ? session
        : (String(selectShift || '').toLowerCase().includes('morning')
            ? 'Morning'
            : (String(selectShift || '').toLowerCase().includes('afternoon') ? 'Afternoon' : undefined));
    if (!ses) return { error: 'session is required for Half-Day (Morning/Afternoon)' };

    base.startDate = date;
    base.endDate   = date;
    base.session   = ses as 'Morning' | 'Afternoon';
    return { data: base };
  }

  // ---------------- Comp Off (single day on compensate date) ----------------
  if (leaveType === 'Comp Off') {
    const worked = toYMD(workedDate || startDate || fromDate); // past day worked
    // compensate/off day: allow selectDate, endDate, toDate, or explicit startDate
    const comp   = toYMD(endDate || toDate || selectDate || startDate);
    if (!worked) return { error: 'workedDate is required for Comp Off' };
    if (!comp)   return { error: 'compensate date is required for Comp Off' };

    base.startDate = comp;
    base.endDate   = comp; // single-day leave
    base.workedDate = worked;
    return { data: base };
  }

  // ---------------- Multi-day (Casual/Planned/Sick) ----------------
  const s = toYMD(startDate || fromDate);
  const e = toYMD(endDate   || toDate);
  const { start, end } = clampRange(s, e);
  if (!start || !end) return { error: 'Invalid startDate/endDate' };

  base.startDate = start;
  base.endDate   = end;
  return { data: base };
}

/* ============================== Controllers ============================== */

// CREATE — overlap check rewritten to avoid composite index
export const createLeaveRequest = async (req: Request, res: Response): Promise<Response> => {
  try {
    const currentUser = (req as any).user;

    // Resolve display name
    let empName = '';
    const empSnap = await db.collection('employees').where('empid', '==', currentUser.empid).limit(1).get();
    if (!empSnap.empty) {
      const e = empSnap.docs[0].data() as any;
      empName = [e.firstName, e.lastName].filter(Boolean).join(' ') || e.name || '';
    }
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

    // ---- Index-free overlap check (query by userId only; filter in memory) ----
    if (payload.leaveType !== 'Overtime' && payload.leaveType !== 'Permission Time') {
      const existing = await db.collection('leaves')
        .where('userId', '==', currentUser.userId)
        .get();

      const overlaps = existing.docs.some((d) => {
        const v = d.data() as any;
        if (!['Pending', 'Approved'].includes(String(v.status))) return false;
        const s = String(v.startDate || '');
        const e = String(v.endDate   || '');
        return s <= payload.endDate && e >= payload.startDate;
      });

      if (overlaps) {
        const msg = payload.leaveType === 'Comp Off'
          ? 'You already have a leave/comp-off on the selected compensate date'
          : 'You already have a leave request for the selected date range';
        return res.status(400).json({ error: msg });
      }
    }
    // --------------------------------------------------------------------------

    const ref  = await db.collection('leaves').add(payload);
    const snap = await ref.get();
    return res.status(201).json({ id: ref.id, ...snap.data() });
  } catch (error) {
    console.error('Error creating leave request:', error);
    return res.status(500).json({ error: 'Failed to create leave request' });
  }
};

// ADMIN: list with optional filters + naive pagination
export const getAllLeaveRequests = async (req: Request, res: Response): Promise<Response> => {
  try {
    const currentUser = (req as any).user;
    const { status, userId, startDate, endDate, page = '1', limit = '10' } = req.query;

    if (currentUser.role !== 'admin' && userId !== currentUser.userId) {
      return res.status(403).json({ error: 'Unauthorized to view these leave requests' });
    }

    let q: FirebaseFirestore.Query<FirebaseFirestore.DocumentData> = db.collection('leaves');
    if (status)  q = q.where('status', '==', status);
    if (userId)  q = q.where('userId', '==', userId);
    if (startDate && endDate) {
      q = q.where('startDate', '<=', String(endDate)).where('endDate', '>=', String(startDate));
    }

    const all = await q.get();
    const total = all.size;

    const pageNum = parseInt(String(page), 10);
    const limitNum = parseInt(String(limit), 10);
    const offset = Math.max(0, (pageNum - 1) * limitNum);

    const pageSnap = await q.offset(offset).limit(limitNum).get();

    return res.status(200).json({
      data: pageSnap.docs.map((d) => ({ id: d.id, ...d.data() })),
      pagination: { page: pageNum, limit: limitNum, total, pages: Math.ceil(total / limitNum) },
    });
  } catch (error) {
    console.error('Error fetching leave requests:', error);
    return res.status(500).json({ error: 'Failed to fetch leave requests' });
  }
};

// ME: list mine
export const getMyLeaveRequests = async (req: Request, res: Response): Promise<Response> => {
  try {
    const currentUser = (req as any).user;
    const { status, startDate, endDate } = req.query;

    let q: FirebaseFirestore.Query = db.collection('leaves').where('userId', '==', currentUser.userId);
    if (status) q = q.where('status', '==', status);
    if (startDate && endDate) {
      q = q.where('startDate', '<=', String(endDate)).where('endDate', '>=', String(startDate));
    }

    const snap = await q.get();
    return res.status(200).json(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
  } catch (error) {
    console.error('Error fetching my leave requests:', error);
    return res.status(500).json({ error: 'Failed to fetch your leave requests' });
  }
};

// GET by id
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

// UPDATE status (admin)
export const updateLeaveStatus = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;
    const currentUser = (req as any).user;

    if (currentUser.role !== 'admin') return res.status(403).json({ error: 'Unauthorized to update this leave request' });
    if (!['Approved', 'Rejected', 'Cancelled'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    const ref = db.collection('leaves').doc(id);
    const snap = await ref.get();
    if (!snap.exists) return res.status(404).json({ error: 'Leave request not found' });

    await ref.update({
      status,
      approverId: currentUser.userId,
      approverNotes: notes || undefined,
      updatedAt: admin.firestore.Timestamp.now(),
    } as Partial<LeaveRequest>);

    const updated = await ref.get();
    return res.status(200).json({ id: updated.id, ...updated.data() });
  } catch (error) {
    console.error('Error updating leave status:', error);
    return res.status(500).json({ error: 'Failed to update leave status' });
  }
};

// CANCEL (me/admin)
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

// Simple balance
export const getLeaveBalance = async (req: Request, res: Response): Promise<Response> => {
  try {
    const currentUser = (req as any).user;
    const empSnap = await db.collection('employees').where('empid', '==', currentUser.empid).limit(1).get();
    if (empSnap.empty) return res.status(404).json({ error: 'Employee not found' });

    const e = empSnap.docs[0].data() as any;
    const leaveBalance = {
      casualLeaves:  e.leaveBalance?.casualLeaves ?? 12,
      sickLeaves:    e.leaveBalance?.sickLeaves   ?? 12,
      plannedLeaves: e.leaveBalance?.plannedLeaves?? 10,
      compOff:       e.leaveBalance?.compOff      ?? 0,
    };
    return res.status(200).json(leaveBalance);
  } catch (error) {
    console.error('Error fetching leave balance:', error);
    return res.status(500).json({ error: 'Failed to fetch leave balance' });
  }
};

// Extras
export const getPendingLeaves = async (req: Request, res: Response): Promise<Response> => {
  try {
    const t = req.query.type ? String(req.query.type) : undefined;
    let q: FirebaseFirestore.Query = db.collection('leaves').where('status', '==', 'Pending');
    if (t) q = q.where('leaveType', '==', t);
    const snaps = await q.get();
    return res.json(snaps.docs.map((d) => ({ id: d.id, ...d.data() })));
  } catch (err) {
    console.error('getPendingLeaves error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

export const deleteLeave = async (req: Request, res: Response): Promise<Response> => {
  try {
    await db.collection('leaves').doc(req.params.id).delete();
    return res.json({ message: 'Request deleted' });
  } catch (err) {
    console.error('deleteLeave error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

// Leave Types Management
export const getLeaveTypes = async (req: Request, res: Response): Promise<Response> => {
  try {
    const snapshot = await db.collection('leave_types').get();
    const leaveTypes = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    return res.status(200).json({ status: 'success', data: leaveTypes });
  } catch (error) {
    console.error('Error getting leave types:', error);
    return res.status(500).json({ status: 'error', message: 'Failed to fetch leave types' });
  }
};

export const addLeaveType = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { type, shift, fromDate, toDate, allowedDays } = req.body;
    
    if (!type || !shift || !fromDate || !toDate) {
      return res.status(400).json({
        status: 'error',
        message: 'Missing required fields: type, shift, fromDate, toDate'
      });
    }

    const leaveTypeData = {
      type,
      shift,
      fromDate,
      toDate,
      allowedDays: allowedDays || 1,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    const docRef = await db.collection('leave_types').add(leaveTypeData);
    
    return res.status(201).json({
      status: 'success',
      message: 'Leave type added successfully',
      id: docRef.id
    });
  } catch (error) {
    console.error('Error adding leave type:', error);
    return res.status(500).json({ status: 'error', message: 'Failed to add leave type' });
  }
};

export const deleteLeaveType = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { type, shift, fromDate, toDate } = req.body;

    if (!type || !shift || !fromDate || !toDate) {
      return res.status(400).json({
        status: 'error',
        message: 'Missing required fields: type, shift, fromDate, toDate'
      });
    }

    // Query to find the matching leave type
    const leaveTypesRef = db.collection('leave_types');
    const snapshot = await leaveTypesRef
      .where('type', '==', type)
      .where('shift', '==', shift)
      .where('fromDate', '==', fromDate)
      .where('toDate', '==', toDate)
      .limit(1)
      .get();

    if (snapshot.empty) {
      return res.status(404).json({
        status: 'error',
        message: 'Leave type not found',
      });
    }

    // Delete the document
    const docId = snapshot.docs[0].id;
    await leaveTypesRef.doc(docId).delete();

    return res.status(200).json({
      status: 'success',
      message: 'Leave type deleted successfully',
    });
  } catch (error) {
    console.error('Error deleting leave type:', error);
    return res.status(500).json({
      status: 'error',
      message: 'Internal server error',
      error: error instanceof Error ? error.message : 'Unknown error',
    });
  }
};

// Aliases
export const createLeave   = createLeaveRequest;
export const getMyLeaves   = getMyLeaveRequests;
export const getAllLeaves  = getAllLeaveRequests;
export const getLeaveById  = getLeaveRequestById;
export const updateLeave   = updateLeaveStatus;
export const cancelLeave   = cancelLeaveRequest;
export const getLeaves     = getAllLeaves;
