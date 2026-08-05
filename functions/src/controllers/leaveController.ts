import { Request, Response } from 'express';
import { db } from '../config/firebase';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { trackUsage } from '../services/usageService';

/* ============================== Types ============================== */

type LeaveType = string;

type LeaveStatus = 'Pending' | 'Approved' | 'Rejected' | 'Cancelled';

interface LeaveRequest {
  id?: string;
  companyId: string;
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
  workedDate?: string;             // YYYY-MM-DD
  createdAt: Timestamp;
  updatedAt: Timestamp;
  requestedAt?: Timestamp;
  approverId?: string;
  approverNotes?: string;
}

/* ============================== Helpers ============================== */


function getReqCompanyId(req: Request): string | null {
  const companyId = String((req as any).user?.companyId || '').trim();
  return companyId || null;
}

function getReqActorId(req: Request): string | null {
  const user = (req as any).user || {};
  return String(user.userId || user.uid || '').trim() || null;
}

function getReqRole(req: Request): string {
  return String((req as any).user?.role || '').trim().toLowerCase();
}

function isAdmin(req: Request): boolean {
  return getReqRole(req) === 'admin';
}

/* ============================== Usage Tracking Helper ============================== */

async function trackLeaveUsage(
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
    console.error('Usage tracking failed in leave:', trackingError);
  }
}

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
  empName: string,
  companyId: string
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
  if (!leaveType || typeof leaveType !== 'string') {
    return { error: 'Invalid or missing leaveType' };
  }

  // Trim whitespace and validate leaveType
  const trimmedLeaveType = String(leaveType).trim();
  if (!trimmedLeaveType) {
    return { error: 'Invalid or missing leaveType' };
  }

  if (!reason) {
    return { error: 'Missing reason' };
  }

  const nowTs = Timestamp.now();

  const base: Omit<LeaveRequest, 'id'> = {
    companyId,
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
  if (documentUrl) base.documentUrl = String(documentUrl);
  if (imageUrl) base.imageUrl = String(imageUrl);
  if (selectShift) base.selectShift = String(selectShift);

  // Overtime / Permission Time
  if (leaveType === 'Overtime' || leaveType === 'Permission Time') {
    const date = toYMD(selectDate || startDate);
    if (!date) {
      return { error: 'selectDate/startDate required for Overtime/Permission' };
    }

    if (duration != null) {
      const d = Number(duration);
      if (!(d > 0)) {
        return { error: 'duration must be > 0 (hours)' };
      }
      base.duration = d;
    } else {
      if (!startTime || !endTime) {
        return { error: 'startTime and endTime are required (or provide duration)' };
      }

      const st = new Date(`${date}T${String(startTime).padStart(5, '0')}:00`);
      const et = new Date(`${date}T${String(endTime).padStart(5, '0')}:00`);

      if (isNaN(st.getTime()) || isNaN(et.getTime()) || et <= st) {
        return { error: 'Invalid startTime/endTime' };
      }

      base.duration = (et.getTime() - st.getTime()) / 3600000;
    }

    base.startDate = date;
    base.endDate = date;
    return { data: base };
  }

  // Half-Day
  if (leaveType === 'Half-Day') {
    const date = toYMD(selectDate || startDate || fromDate);
    if (!date) {
      return { error: 'selectDate/startDate/fromDate required for Half-Day' };
    }

    const ses =
      'session' in (raw || {}) && session
        ? session
        : String(selectShift || '').toLowerCase().includes('morning')
          ? 'Morning'
          : String(selectShift || '').toLowerCase().includes('afternoon')
            ? 'Afternoon'
            : undefined;

    if (!ses) {
      return { error: 'session is required for Half-Day (Morning/Afternoon)' };
    }

    base.startDate = date;
    base.endDate = date;
    base.session = ses as 'Morning' | 'Afternoon';
    return { data: base };
  }

  // Comp Off
  if (leaveType === 'Comp Off') {
    const worked = toYMD(workedDate || startDate || fromDate);
    const comp = toYMD(endDate || toDate || selectDate || startDate);

    if (!worked) {
      return { error: 'workedDate is required for Comp Off' };
    }

    if (!comp) {
      return { error: 'compensate date is required for Comp Off' };
    }

    base.startDate = comp;
    base.endDate = comp;
    base.workedDate = worked;
    return { data: base };
  }

  // Casual / Planned / Sick
  const s = toYMD(startDate || fromDate);
  const e = toYMD(endDate || toDate);
  const { start, end } = clampRange(s, e);

  if (!start || !end) {
    return { error: 'Invalid startDate/endDate' };
  }

  base.startDate = start;
  base.endDate = end;
  return { data: base };
}

function mapTypeQueryToLeaveType(q?: string): LeaveType | null {
  if (!q) return null;
  const t = String(q).trim().toLowerCase();

  if (t === 'leave:overtime' || t === 'overtime' || t === 'over time') {
    return 'Overtime';
  }
  if (t === 'leave:permission' || t === 'permission' || t === 'permission time') {
    return 'Permission Time';
  }
  if (t === 'leave:halfday' || t === 'half day' || t === 'half-day' || t === 'halfday') {
    return 'Half-Day';
  }
  if (t === 'leave:compoff' || t === 'comp off' || t === 'comp-off' || t === 'compoff') {
    return 'Comp Off';
  }

  return null;
}

/* ============================== Controllers ============================== */

export const createLeaveRequest = async (req: Request, res: Response): Promise<Response> => {
  try {
    const currentUser = (req as any).user;
    const companyId = getReqCompanyId(req);

    if (!currentUser?.userId || !currentUser?.empid || !companyId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    let empName = '';

    const empSnap = await db
      .collection('employees')
      .where('companyId', '==', companyId)
      .where('empid', '==', currentUser.empid)
      .limit(1)
      .get();

    if (!empSnap.empty) {
      const e = empSnap.docs[0].data() as any;
      empName = [e.firstName, e.lastName].filter(Boolean).join(' ') || e.name || '';
    }

    if (!empName) {
      const usr = await db.collection('users').doc(currentUser.userId).get();
      if (usr.exists) {
        const u = usr.data() as any;
        if (u?.companyId === companyId) {
          empName = u.name || `${u.firstName ?? ''} ${u.lastName ?? ''}`.trim();
        }
      }
    }

    const norm = normalizeCreatePayload(currentUser, req.body, empName || 'Employee', companyId);
    if (norm.error) {
      return res.status(400).json({ error: norm.error });
    }

    const payload = norm.data!;

    if (payload.leaveType !== 'Overtime' && payload.leaveType !== 'Permission Time') {
      const existing = await db.collection('leaves')
        .where('companyId', '==', companyId)
        .where('userId', '==', currentUser.userId)
        .where('status', 'in', ['Pending', 'Approved'])
        .get();

      const overlaps = existing.docs.some((d) => {
        const v = d.data() as any;
        if (!['Pending', 'Approved'].includes(String(v.status))) return false;
        const s = String(v.startDate || '');
        const e = String(v.endDate || '');
        return s <= payload.endDate && e >= payload.startDate;
      });

      if (overlaps) {
        const msg =
          payload.leaveType === 'Comp Off'
            ? 'You have already applied for leave/comp-off on the selected date.'
            : 'You already have a leave request for the selected date range.';
        return res.status(200).json({ message: msg });
      }
    }

    const ref = await db.collection('leaves').add(payload);
    const snap = await ref.get();

    // Track usage after successful leave creation
    await trackLeaveUsage(req, {
      writeCount: 1,
      apiCalls: 1,
      leaveCount: 1,
    });

    return res.status(201).json({ id: ref.id, ...snap.data() });
  } catch (error) {
    console.error('Error creating leave request:', error);
    return res.status(500).json({ error: 'Failed to create leave request' });
  }
};

export const getAllLeaveRequests = async (req: Request, res: Response): Promise<Response> => {
  try {
    const currentUser = (req as any).user;
    const companyId = getReqCompanyId(req);
    const { status, userId, startDate, endDate, page = '1', limit = '10', type } = req.query;

    if (!companyId || !currentUser?.userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const requestedUserId = String(userId || '').trim();

    if (!isAdmin(req) && requestedUserId && requestedUserId !== currentUser.userId) {
      return res.status(403).json({ error: 'Unauthorized to view these leave requests' });
    }

    let q: FirebaseFirestore.Query<FirebaseFirestore.DocumentData> = db
      .collection('leaves')
      .where('companyId', '==', companyId);

    if (status) {
      q = q.where('status', '==', String(status));
    }

    if (isAdmin(req)) {
      if (requestedUserId) {
        q = q.where('userId', '==', requestedUserId);
      }
    } else {
      q = q.where('userId', '==', currentUser.userId);
    }

    if (startDate && endDate) {
      q = q
        .where('startDate', '<=', String(endDate))
        .where('endDate', '>=', String(startDate));
    }

    const leaveTypeFilter = mapTypeQueryToLeaveType(type as string | undefined);
    if (leaveTypeFilter) {
      q = q.where('leaveType', '==', leaveTypeFilter);
    }

    const pageNum = Math.max(parseInt(String(page), 10) || 1, 1);
    const limitNum = Math.min(Math.max(parseInt(String(limit), 10) || 10, 1), 100);

    const pageSnap = await q
      .orderBy('createdAt', 'desc')
      .limit(limitNum)
      .get();

    // Track usage after successful leave read
    await trackLeaveUsage(req, {
      readCount: 1,
      apiCalls: 1,
    });

    return res.status(200).json({
      data: pageSnap.docs.map((d) => ({ id: d.id, ...d.data() })),
      pagination: {
        page: pageNum,
        limit: limitNum,
        hasMore: pageSnap.size === limitNum,
      },
    });
  } catch (error) {
    console.error('Error fetching leave requests:', error);
    return res.status(500).json({
      error: 'Failed to fetch leave requests',
      details: error instanceof Error ? error.message : 'Unknown error',
    });
  }
};

export const getPendingLeaves = async (req: Request, res: Response): Promise<Response> => {
  try {
    const companyId = getReqCompanyId(req);
    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const t = req.query.type ? String(req.query.type) : undefined;

    let q: FirebaseFirestore.Query = db
      .collection('leaves')
      .where('companyId', '==', companyId)
      .where('status', '==', 'Pending');

    if (t) {
      const mappedType = mapTypeQueryToLeaveType(t) || t;
      q = q.where('leaveType', '==', mappedType);
    }

    const snapshot = await q
      .orderBy('createdAt', 'desc')
      .limit(100)
      .get();

    const pendingLeaves = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

    // Track usage after successful pending leaves read
    await trackLeaveUsage(req, {
      readCount: 1,
      apiCalls: 1,
    });

    return res.status(200).json(pendingLeaves);
  } catch (error) {
    console.error('Error fetching pending leaves:', error);
    return res.status(500).json({
      error: 'Failed to fetch pending leaves',
      details: error instanceof Error ? error.message : 'Unknown error',
    });
  }
};

export const getLeaveBalance = async (req: Request, res: Response): Promise<Response> => {
  try {
    const currentUser = (req as any).user;
    const companyId = getReqCompanyId(req);

    if (!currentUser?.empid || !companyId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const empSnap = await db
      .collection('employees')
      .where('companyId', '==', companyId)
      .where('empid', '==', currentUser.empid)
      .limit(1)
      .get();

    if (empSnap.empty) {
      return res.status(404).json({ error: 'Employee not found' });
    }

    const employee = empSnap.docs[0].data() as any;

    // Track usage after successful leave balance read
    await trackLeaveUsage(req, {
      readCount: 1,
      apiCalls: 1,
    });

    return res.status(200).json({
      casualLeave: employee.casualLeave || 0,
      plannedLeave: employee.plannedLeave || 0,
      sickLeave: employee.sickLeave || 0,
    });
  } catch (error) {
    console.error('Error fetching leave balance:', error);
    return res.status(500).json({
      error: 'Failed to fetch leave balance',
      details: error instanceof Error ? error.message : 'Unknown error',
    });
  }
};

export function getLeaveRequestById(id: string) {
  return db.collection('leaves').doc(id).get();
}

export const updateLeaveStatus = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { id } = req.params;
    const { status, notes, leavePayType } = req.body;
    const companyId = getReqCompanyId(req);
    const actorId = getReqActorId(req);

    if (!companyId || !actorId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    if (!isAdmin(req)) {
      return res.status(403).json({ error: 'Only admin can update leave status' });
    }

    if (!['Approved', 'Rejected', 'Cancelled'].includes(String(status))) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    const leaveRef = db.collection('leaves').doc(id);
    const leaveDoc = await leaveRef.get();

    if (!leaveDoc.exists) {
      return res.status(404).json({ error: 'Leave request not found' });
    }

    const leaveData = leaveDoc.data() as any;

    if (leaveData?.companyId !== companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Determine if request requires paid/unpaid classification based on stored type
    // Read the canonical request category from Firestore document
    const rawType = leaveData.type ?? leaveData.category ?? leaveData.requestType ?? '';
    const normalizedType = typeof rawType === 'string' ? rawType.trim().toLowerCase() : '';
    const isLeaveRequest = normalizedType === 'leave type';

    // Validate leavePayType based on status and request type
    const cleanStatus = String(status) as LeaveStatus;
    const cleanLeavePayType = leavePayType ? String(leavePayType).toLowerCase() : null;

    if (cleanStatus === 'Approved' && isLeaveRequest) {
      if (cleanLeavePayType !== 'paid' && cleanLeavePayType !== 'unpaid') {
        return res.status(400).json({
          error: 'Paid or unpaid classification is required for Leave Type requests.'
        });
      }
    }

    const updateData: any = {
      status: cleanStatus,
      approvalStatus: cleanStatus,
      approverId: actorId,
      approverNotes: notes ? String(notes) : '',
      decisionBy: actorId,
      decisionAt: FieldValue.serverTimestamp(),
      decisionRemarks: notes ? String(notes) : null,
      updatedAt: FieldValue.serverTimestamp(),
    };

    // Set or clear leavePayType based on status and request type
    if (cleanStatus === 'Approved') {
      if (isLeaveRequest) {
        updateData.leavePayType = cleanLeavePayType; // 'paid' or 'unpaid'
      } else {
        // Non-leave requests do not require classification
        updateData.leavePayType = null;
      }
    } else if (cleanStatus === 'Rejected' || cleanStatus === 'Cancelled') {
      updateData.leavePayType = null;
    }

    await leaveRef.update(updateData);

    // Track usage after successful leave status update
    await trackLeaveUsage(req, {
      writeCount: 1,
      apiCalls: 1,
    });

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error('Error updating leave status:', error);
    return res.status(500).json({
      error: 'Failed to update leave status',
      details: error instanceof Error ? error.message : 'Unknown error',
    });
  }
};

export const cancelLeaveRequest = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { id } = req.params;
    const currentUser = (req as any).user;
    const companyId = getReqCompanyId(req);
    const actorId = getReqActorId(req);
    const { reason } = req.body;

    if (!companyId || !actorId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const leaveRef = db.collection('leaves').doc(id);
    const leaveDoc = await leaveRef.get();

    if (!leaveDoc.exists) {
      return res.status(404).json({ error: 'Leave request not found' });
    }

    const leaveData = leaveDoc.data() as any;

    if (leaveData?.companyId !== companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    if (!isAdmin(req) && leaveData?.userId !== currentUser.userId) {
      return res.status(403).json({ error: 'Not authorized to cancel this leave' });
    }

    if (leaveData?.status !== 'Pending') {
      return res.status(400).json({ error: 'Only pending leave requests can be cancelled' });
    }

    await leaveRef.update({
      status: 'Cancelled',
      cancelledAt: FieldValue.serverTimestamp(),
      cancelledBy: actorId,
      cancelReason: reason ? String(reason) : '',
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Track usage after successful leave cancellation
    await trackLeaveUsage(req, {
      writeCount: 1,
      apiCalls: 1,
    });

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error('Error cancelling leave request:', error);
    return res.status(500).json({
      error: 'Failed to cancel leave request',
      details: error instanceof Error ? error.message : 'Unknown error',
    });
  }
};

export const deleteLeave = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { id } = req.params;
    const companyId = getReqCompanyId(req);

    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    if (!isAdmin(req)) {
      return res.status(403).json({ error: 'Only admin can delete leave requests' });
    }

    const leaveRef = db.collection('leaves').doc(id);
    const leaveDoc = await leaveRef.get();

    if (!leaveDoc.exists) {
      return res.status(404).json({ error: 'Leave request not found' });
    }

    const leaveData = leaveDoc.data() as any;

    if (leaveData?.companyId !== companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    await leaveRef.delete();

    // Track usage after successful leave deletion
    await trackLeaveUsage(req, {
      deleteCount: 1,
      apiCalls: 1,
    });

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error('Error deleting leave request:', error);
    return res.status(500).json({
      error: 'Failed to delete leave request',
      details: error instanceof Error ? error.message : 'Unknown error',
    });
  }
};