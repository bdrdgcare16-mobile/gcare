import { Request, Response } from 'express';
import * as admin from 'firebase-admin';
// Import statements

const db = admin.firestore();

interface Employee {
  id?: string;
  empid: string;
  name: string;
  email: string;
  phone?: string;
  location?: string;
  dept?: string;
  designation?: string;
  shiftGroup?: string;
  status: 'active' | 'inactive';
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
  createdBy: string;
  updatedBy: string;
}

// Create a new employee
export const createEmployee = async (req: Request, res: Response): Promise<Response> => {
  try {
    const {
      empid,
      name,
      email,
      phone,
      location,
      dept,
      designation,
      shiftGroup,
      status = 'active',
    } = req.body;

    // Validate required fields
    if (!empid || !name || !email) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Check if employee with same empid or email already exists
    const existingEmployee = await db
      .collection('employees')
      .where('empid', '==', empid)
      .limit(1)
      .get();

    if (!existingEmployee.empty) {
      return res.status(409).json({ error: 'Employee with this ID already exists' });
    }

    const existingEmail = await db
      .collection('employees')
      .where('email', '==', email.toLowerCase())
      .limit(1)
      .get();

    if (!existingEmail.empty) {
      return res.status(409).json({ error: 'Employee with this email already exists' });
    }

    // Get current user ID from request (set by auth middleware)
    const currentUserId = (req as any).user?.userId;
    if (!currentUserId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const now = admin.firestore.Timestamp.now();
    const employeeData: Employee = {
      empid,
      name,
      email: email.toLowerCase(),
      phone,
      location,
      dept,
      designation,
      shiftGroup,
      status: status as 'active' | 'inactive',
      createdAt: now,
      updatedAt: now,
      createdBy: currentUserId,
      updatedBy: currentUserId,
    };

    const employeeRef = await db.collection('employees').add(employeeData);
    const employee = { id: employeeRef.id, ...employeeData };

    return res.status(201).json(employee);
  } catch (error) {
    console.error('Error creating employee:', error);
    return res.status(500).json({ error: 'Failed to create employee' });
  }
};

// Get all employees
export const getEmployees = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { status, search, page = 1, limit = 10 } = req.query;
    const pageNumber = parseInt(page as string, 10);
    const limitNumber = parseInt(limit as string, 10);
    const offset = (pageNumber - 1) * limitNumber;

    let query: FirebaseFirestore.Query<FirebaseFirestore.DocumentData> = db.collection('employees');

    // Apply filters
    if (status === 'active' || status === 'inactive') {
      query = query.where('status', '==', status);
    }

    if (search) {
      const searchStr = (search as string).toLowerCase();
      query = query.where('searchKeywords', 'array-contains', searchStr);
    }

    // Get total count for pagination
    const snapshot = await query.get();
    const total = snapshot.size;

    // Apply pagination
    const employeesSnapshot = await query
      .orderBy('createdAt', 'desc')
      .offset(offset)
      .limit(limitNumber)
      .get();

    const employees = employeesSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));

    return res.status(200).json({
      data: employees,
      pagination: {
        page: pageNumber,
        limit: limitNumber,
        total,
        pages: Math.ceil(total / limitNumber),
      },
    });
  } catch (error) {
    console.error('Error fetching employees:', error);
    return res.status(500).json({ error: 'Failed to fetch employees' });
  }
};

// Get employee by ID
export const getEmployeeById = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { id } = req.params;

    const doc = await db.collection('employees').doc(id).get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Employee not found' });
    }

    const employee = { id: doc.id, ...doc.data() };
    return res.status(200).json(employee);
  } catch (error) {
    console.error('Error fetching employee:', error);
    return res.status(500).json({ error: 'Failed to fetch employee' });
  }
};

// Update employee
export const updateEmployee = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { id } = req.params;
    const updates = req.body;

    // Get current user ID from request (set by auth middleware)
    const currentUserId = (req as any).user?.userId;
    if (!currentUserId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const employeeRef = db.collection('employees').doc(id);
    const doc = await employeeRef.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Employee not found' });
    }

    // Remove fields that shouldn't be updated
    const { id: _, createdAt, createdBy, ...safeUpdates } = updates;

    await employeeRef.update({
      ...safeUpdates,
      updatedAt: admin.firestore.Timestamp.now(),
      updatedBy: currentUserId,
    });

    const updatedDoc = await employeeRef.get();
    const employee = { id: updatedDoc.id, ...updatedDoc.data() };

    return res.status(200).json(employee);
  } catch (error) {
    console.error('Error updating employee:', error);
    return res.status(500).json({ error: 'Failed to update employee' });
  }
};

// Delete employee
export const deleteEmployee = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { id } = req.params;

    // In a real application, you might want to soft delete instead
    await db.collection('employees').doc(id).delete();

    return res.status(200).json({ message: 'Employee deleted successfully' });
  } catch (error) {
    console.error('Error deleting employee:', error);
    return res.status(500).json({ error: 'Failed to delete employee' });
  }
};
