import { Request, Response } from 'express';
import * as admin from 'firebase-admin';
// Import statements

const db = admin.firestore();

interface AttendanceRecord {
  id?: string;
  empid: string;
  name: string;
  date: string; // YYYY-MM-DD
  checkIn: admin.firestore.Timestamp;
  checkOut?: admin.firestore.Timestamp;
  location: string;
  status: 'present' | 'absent' | 'half-day' | 'holiday' | 'weekend' | 'on-leave';
  totalHours?: number;
  lateMinutes?: number;
  earlyLeaveMinutes?: number;
  notes?: string;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
  createdBy: string;
  updatedBy: string;
}

interface CheckInRequest {
  empid: string;
  name: string;
  location: string;
  notes?: string;
}

interface CheckOutRequest {
  empid: string;
  location: string;
  notes?: string;
}

// Check-in an employee
export const checkIn = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { empid, name, location, notes } = req.body as CheckInRequest;
    const currentUser = (req as any).user;

    // Validate required fields
    if (!empid || !name || !location) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Check if user is authorized
    if (currentUser.role !== 'admin' && currentUser.userId !== empid) {
      return res.status(403).json({ error: 'Unauthorized to check in for this employee' });
    }

    const now = admin.firestore.Timestamp.now();
    const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD

    // Check if already checked in today
    const existingCheckIn = await db
      .collection('attendance')
      .where('empid', '==', empid)
      .where('date', '==', today)
      .where('checkOut', '==', null)
      .limit(1)
      .get();

    if (!existingCheckIn.empty) {
      return res.status(400).json({ error: 'Already checked in for today' });
    }

    // Create attendance record
    const attendanceData: Omit<AttendanceRecord, 'id'> = {
      empid,
      name,
      date: today,
      checkIn: now,
      location,
      status: 'present',
      notes: notes || '',
      createdAt: now,
      updatedAt: now,
      createdBy: currentUser.userId,
      updatedBy: currentUser.userId,
    };

    const attendanceRef = await db.collection('attendance').add(attendanceData);
    const attendance = { id: attendanceRef.id, ...attendanceData };

    return res.status(201).json({
      message: 'Checked in successfully',
      attendance,
    });
  } catch (error) {
    console.error('Error during check-in:', error);
    return res.status(500).json({ error: 'Failed to process check-in' });
  }
};

// Check-out an employee
export const checkOut = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { empid, location, notes } = req.body as CheckOutRequest;
    const currentUser = (req as any).user;

    // Validate required fields
    if (!empid || !location) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Check if user is authorized
    if (currentUser.role !== 'admin' && currentUser.userId !== empid) {
      return res.status(403).json({ error: 'Unauthorized to check out for this employee' });
    }

    const now = admin.firestore.Timestamp.now();
    const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD

    // Find today's check-in record
    const checkInQuery = await db
      .collection('attendance')
      .where('empid', '==', empid)
      .where('date', '==', today)
      .where('checkOut', '==', null)
      .limit(1)
      .get();

    if (checkInQuery.empty) {
      return res.status(400).json({ error: 'No active check-in found for today' });
    }

    const doc = checkInQuery.docs[0];
    const checkInData = doc.data() as AttendanceRecord;
    
    // Calculate total hours worked
    const checkInTime = checkInData.checkIn.toDate();
    const checkOutTime = now.toDate();
    const diffMs = checkOutTime.getTime() - checkInTime.getTime();
    const totalHours = parseFloat((diffMs / (1000 * 60 * 60)).toFixed(2));

    // Update attendance record
    const updateData: Partial<AttendanceRecord> = {
      checkOut: now,
      totalHours,
      updatedAt: now,
      updatedBy: currentUser.userId,
    };

    if (notes) {
      updateData.notes = notes;
    }

    await doc.ref.update(updateData);

    // Get updated record
    const updatedDoc = await doc.ref.get();
    const attendance = { id: updatedDoc.id, ...updatedDoc.data() };

    return res.status(200).json({
      message: 'Checked out successfully',
      attendance,
    });
  } catch (error) {
    console.error('Error during check-out:', error);
    return res.status(500).json({ error: 'Failed to process check-out' });
  }
};

// Get attendance for a specific employee
export const getEmployeeAttendance = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { empid } = req.params;
    const { startDate, endDate } = req.query;
    const currentUser = (req as any).user;

    // Check if user is authorized
    if (currentUser.role !== 'admin' && currentUser.userId !== empid) {
      return res.status(403).json({ error: 'Unauthorized to view this attendance' });
    }

    let query = db
      .collection('attendance')
      .where('empid', '==', empid)
      .orderBy('date', 'desc');

    // Apply date range filter if provided
    if (startDate && endDate) {
      query = query
        .where('date', '>=', startDate as string)
        .where('date', '<=', endDate as string);
    }

    const snapshot = await query.get();
    const attendance = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));

    return res.status(200).json(attendance);
  } catch (error) {
    console.error('Error fetching attendance:', error);
    return res.status(500).json({ error: 'Failed to fetch attendance records' });
  }
};

// Get current status of an employee
export const getCurrentStatus = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { empid } = req.params;
    const currentUser = (req as any).user;

    // Check if user is authorized
    if (currentUser.role !== 'admin' && currentUser.userId !== empid) {
      return res.status(403).json({ error: 'Unauthorized to view this status' });
    }

    const today = new Date().toISOString().split('T')[0];
    
    // Check for today's attendance
    const attendanceQuery = await db
      .collection('attendance')
      .where('empid', '==', empid)
      .where('date', '==', today)
      .orderBy('checkIn', 'desc')
      .limit(1)
      .get();

    if (attendanceQuery.empty) {
      return res.status(200).json({
        status: 'not_checked_in',
        message: 'Not checked in today',
      });
    }

    const attendance = attendanceQuery.docs[0].data() as AttendanceRecord;
    
    if (attendance.checkOut) {
      return res.status(200).json({
        status: 'checked_out',
        message: 'Checked out for the day',
        lastCheckOut: attendance.checkOut,
      });
    }

    return res.status(200).json({
      status: 'checked_in',
      message: 'Currently checked in',
      checkInTime: attendance.checkIn,
      duration: attendance.totalHours || 0,
    });
  } catch (error) {
    console.error('Error fetching current status:', error);
    return res.status(500).json({ error: 'Failed to fetch current status' });
  }
};

// Get attendance summary for an employee
export const getAttendanceSummary = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { empid } = req.params;
    const { month, year } = req.query;
    const currentUser = (req as any).user;

    // Check if user is authorized
    if (currentUser.role !== 'admin' && currentUser.userId !== empid) {
      return res.status(403).json({ error: 'Unauthorized to view this summary' });
    }

    // Default to current month and year if not provided
    const currentDate = new Date();
    const targetMonth = month ? parseInt(month as string, 10) - 1 : currentDate.getMonth();
    const targetYear = year ? parseInt(year as string, 10) : currentDate.getFullYear();
    
    // Calculate start and end dates for the month
    const startDate = new Date(targetYear, targetMonth, 1);
    const endDate = new Date(targetYear, targetMonth + 1, 0);
    
    const startDateStr = startDate.toISOString().split('T')[0];
    const endDateStr = endDate.toISOString().split('T')[0];

    // Get all attendance records for the month
    const snapshot = await db
      .collection('attendance')
      .where('empid', '==', empid)
      .where('date', '>=', startDateStr)
      .where('date', '<=', endDateStr)
      .get();

    // Calculate summary
    let presentDays = 0;
    let totalHours = 0;
    let lateDays = 0;
    let earlyLeaveDays = 0;

    snapshot.forEach(doc => {
      const record = doc.data() as AttendanceRecord;
      if (record.status === 'present') {
        presentDays++;
      }
      if (record.totalHours) {
        totalHours += record.totalHours;
      }
      if (record.lateMinutes && record.lateMinutes > 0) {
        lateDays++;
      }
      if (record.earlyLeaveMinutes && record.earlyLeaveMinutes > 0) {
        earlyLeaveDays++;
      }
    });

    const totalDays = endDate.getDate();
    const absentDays = totalDays - presentDays; // This is a simplified calculation

    return res.status(200).json({
      empid,
      month: targetMonth + 1,
      year: targetYear,
      presentDays,
      absentDays,
      totalHours,
      lateDays,
      earlyLeaveDays,
      averageHoursPerDay: presentDays > 0 ? parseFloat((totalHours / presentDays).toFixed(2)) : 0,
    });
  } catch (error) {
    console.error('Error fetching attendance summary:', error);
    return res.status(500).json({ error: 'Failed to fetch attendance summary' });
  }
};
