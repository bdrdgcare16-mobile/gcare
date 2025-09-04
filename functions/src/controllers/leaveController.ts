import { Request, Response } from 'express';
import * as admin from 'firebase-admin';
// Import statements

const db = admin.firestore();

// Types for TypeScript
type LeaveType = 'Casual Leave' | 'Planned Leave' | 'Sick Leave' | 'Half-Day' | 'Overtime' | 'Permission Time' | 'Comp Off';
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
  session?: 'Morning' | 'Afternoon'; // For half-day leaves
  duration?: number; // In hours, for overtime/permission
  attachmentUrl?: string;
  approverId?: string;
  approverNotes?: string;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}

// Create a new leave request
export const createLeaveRequest = async (req: Request, res: Response): Promise<Response> => {
  try {
    const currentUser = (req as any).user;
    const {
      leaveType,
      startDate,
      endDate,
      reason,
      session,
      duration,
      attachmentUrl
    } = req.body;

    // Validate required fields
    if (!leaveType || !startDate || !endDate || !reason) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Validate leave type
    const validLeaveTypes: LeaveType[] = [
      'Casual Leave', 'Planned Leave', 'Sick Leave', 
      'Half-Day', 'Overtime', 'Permission Time', 'Comp Off'
    ];
    
    if (!validLeaveTypes.includes(leaveType)) {
      return res.status(400).json({ error: 'Invalid leave type' });
    }

    // For half-day leave, session is required
    if (leaveType === 'Half-Day' && !session) {
      return res.status(400).json({ error: 'Session is required for half-day leave' });
    }

    // For overtime/permission, duration is required
    if ((leaveType === 'Overtime' || leaveType === 'Permission Time') && !duration) {
      return res.status(400).json({ 
        error: 'Duration is required for overtime/permission requests' 
      });
    }

    // Check for overlapping leave requests
    const overlappingLeaves = await db
      .collection('leaves')
      .where('userId', '==', currentUser.userId)
      .where('status', 'in', ['Pending', 'Approved'])
      .where('startDate', '<=', endDate)
      .where('endDate', '>=', startDate)
      .get();

    if (!overlappingLeaves.empty) {
      return res.status(400).json({ 
        error: 'You already have a leave request for the selected date range' 
      });
    }

    // Get employee details
    const employeeDoc = await db.collection('employees')
      .where('empid', '==', currentUser.empid)
      .limit(1)
      .get();

    if (employeeDoc.empty) {
      return res.status(404).json({ error: 'Employee not found' });
    }

    const employeeData = employeeDoc.docs[0].data();
    const now = admin.firestore.Timestamp.now();

    // Create leave request
    const leaveRequest: Omit<LeaveRequest, 'id'> = {
      userId: currentUser.userId,
      empid: currentUser.empid,
      name: `${employeeData.firstName} ${employeeData.lastName}`,
      leaveType,
      startDate,
      endDate,
      reason,
      status: 'Pending',
      session: leaveType === 'Half-Day' ? session : undefined,
      duration: ['Overtime', 'Permission Time'].includes(leaveType) ? Number(duration) : undefined,
      attachmentUrl: attachmentUrl || undefined,
      createdAt: now,
      updatedAt: now,
    };

    const leaveRef = await db.collection('leaves').add(leaveRequest);
    const leaveData = await leaveRef.get();

    return res.status(201).json({
      id: leaveRef.id,
      ...leaveData.data()
    });
  } catch (error) {
    console.error('Error creating leave request:', error);
    return res.status(500).json({ error: 'Failed to create leave request' });
  }
};

// Get all leave requests (admin)
export const getAllLeaveRequests = async (req: Request, res: Response): Promise<Response> => {
  try {
    const currentUser = (req as any).user;
    const { status, userId, startDate, endDate, page = '1', limit = '10' } = req.query;
    
    // Only admin can view all leave requests
    if (currentUser.role !== 'admin' && userId !== currentUser.userId) {
      return res.status(403).json({ error: 'Unauthorized to view these leave requests' });
    }

    let query: FirebaseFirestore.Query<FirebaseFirestore.DocumentData> = db.collection('leaves');
    
    // Apply filters
    if (status) {
      query = query.where('status', '==', status);
    }
    
    if (userId) {
      query = query.where('userId', '==', userId);
    }
    
    if (startDate && endDate) {
      query = query
        .where('startDate', '<=', endDate as string)
        .where('endDate', '>=', startDate as string);
    }

    // Get total count for pagination
    const snapshot = await query.get();
    const total = snapshot.size;
    const pageNum = parseInt(page as string, 10);
    const limitNum = parseInt(limit as string, 10);
    const offset = (pageNum - 1) * limitNum;

    // Apply pagination
    const leaveRequests = await query
      .orderBy('createdAt', 'desc')
      .offset(offset)
      .limit(limitNum)
      .get();

    const result = {
      data: leaveRequests.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })),
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        pages: Math.ceil(total / limitNum)
      }
    };

    return res.status(200).json(result);
  } catch (error) {
    console.error('Error fetching leave requests:', error);
    return res.status(500).json({ error: 'Failed to fetch leave requests' });
  }
};

// Get leave requests for the current user
export const getMyLeaveRequests = async (req: Request, res: Response): Promise<Response> => {
  try {
    const currentUser = (req as any).user;
    const { status, startDate, endDate } = req.query;
    
    let query = db.collection('leaves')
      .where('userId', '==', currentUser.userId);
    
    // Apply status filter if provided
    if (status) {
      query = query.where('status', '==', status);
    }
    
    // Apply date range filter if provided
    if (startDate && endDate) {
      query = query
        .where('startDate', '<=', endDate as string)
        .where('endDate', '>=', startDate as string);
    }
    
    const snapshot = await query
      .orderBy('createdAt', 'desc')
      .get();
    
    const leaveRequests = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
    return res.status(200).json(leaveRequests);
  } catch (error) {
    console.error('Error fetching my leave requests:', error);
    return res.status(500).json({ error: 'Failed to fetch your leave requests' });
  }
};

// Get a single leave request by ID
export const getLeaveRequestById = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { id } = req.params;
    const currentUser = (req as any).user;
    
    const doc = await db.collection('leaves').doc(id).get();
    
    if (!doc.exists) {
      return res.status(404).json({ error: 'Leave request not found' });
    }
    
    const leaveRequest = doc.data() as LeaveRequest;
    
    // Only the requester, admin, or assigned approver can view the request
    if (
      leaveRequest.userId !== currentUser.userId && 
      currentUser.role !== 'admin' &&
      leaveRequest.approverId !== currentUser.userId
    ) {
      return res.status(403).json({ error: 'Unauthorized to view this leave request' });
    }
    
    return res.status(200).json({
      id: doc.id,
      ...leaveRequest
    });
  } catch (error) {
    console.error('Error fetching leave request:', error);
    return res.status(500).json({ error: 'Failed to fetch leave request' });
  }
};

// Update leave request status (approve/reject)
export const updateLeaveStatus = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;
    const currentUser = (req as any).user;
    
    // Only admin or assigned approver can update status
    if (currentUser.role !== 'admin') {
      return res.status(403).json({ error: 'Unauthorized to update this leave request' });
    }
    
    // Validate status
    if (!['Approved', 'Rejected', 'Cancelled'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }
    
    const leaveRef = db.collection('leaves').doc(id);
    const doc = await leaveRef.get();
    
    if (!doc.exists) {
      return res.status(404).json({ error: 'Leave request not found' });
    }
    
    const leaveRequest = doc.data() as LeaveRequest;
    
    // Check if the leave can be updated
    if (leaveRequest.status === 'Cancelled') {
      return res.status(400).json({ error: 'Cannot update a cancelled leave request' });
    }
    
    // Update the leave request
    const updates: Partial<LeaveRequest> = {
      status,
      approverId: currentUser.userId,
      approverNotes: notes || undefined,
      updatedAt: admin.firestore.Timestamp.now()
    };
    
    await leaveRef.update(updates);
    
    // Get the updated leave request
    const updatedDoc = await leaveRef.get();
    
    // TODO: Send notification to the employee about the status update
    
    return res.status(200).json({
      id: updatedDoc.id,
      ...updatedDoc.data()
    });
  } catch (error) {
    console.error('Error updating leave status:', error);
    return res.status(500).json({ error: 'Failed to update leave status' });
  }
};

// Cancel a leave request
export const cancelLeaveRequest = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { id } = req.params;
    const currentUser = (req as any).user;
    
    const leaveRef = db.collection('leaves').doc(id);
    const doc = await leaveRef.get();
    
    if (!doc.exists) {
      return res.status(404).json({ error: 'Leave request not found' });
    }
    
    const leaveRequest = doc.data() as LeaveRequest;
    
    // Only the requester or admin can cancel the request
    if (leaveRequest.userId !== currentUser.userId && currentUser.role !== 'admin') {
      return res.status(403).json({ error: 'Unauthorized to cancel this leave request' });
    }
    
    // Check if the leave can be cancelled
    if (leaveRequest.status !== 'Pending') {
      return res.status(400).json({ 
        error: 'Only pending leave requests can be cancelled' 
      });
    }
    
    // Update the leave request status to Cancelled
    await leaveRef.update({
      status: 'Cancelled',
      updatedAt: admin.firestore.Timestamp.now()
    });
    
    // Get the updated leave request
    const updatedDoc = await leaveRef.get();
    
    return res.status(200).json({
      id: updatedDoc.id,
      ...updatedDoc.data()
    });
  } catch (error) {
    console.error('Error cancelling leave request:', error);
    return res.status(500).json({ error: 'Failed to cancel leave request' });
  }
};

// Get leave balance for the current user
export const getLeaveBalance = async (req: Request, res: Response): Promise<Response> => {
  try {
    const currentUser = (req as any).user;
    
    // Get employee's leave balance from the database
    const employeeDoc = await db.collection('employees')
      .where('empid', '==', currentUser.empid)
      .limit(1)
      .get();
    
    if (employeeDoc.empty) {
      return res.status(404).json({ error: 'Employee not found' });
    }
    
    const employeeData = employeeDoc.docs[0].data();
    
    // Default leave balances (can be customized based on your requirements)
    const leaveBalance = {
      casualLeaves: employeeData.leaveBalance?.casualLeaves || 12,
      sickLeaves: employeeData.leaveBalance?.sickLeaves || 12,
      plannedLeaves: employeeData.leaveBalance?.plannedLeaves || 10,
      compOff: employeeData.leaveBalance?.compOff || 0,
      // Add more leave types as needed
    };
    
    return res.status(200).json(leaveBalance);
  } catch (error) {
    console.error('Error fetching leave balance:', error);
    return res.status(500).json({ error: 'Failed to fetch leave balance' });
  }
};
