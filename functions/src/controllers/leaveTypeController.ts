import { Request, Response } from 'express';
import * as admin from 'firebase-admin';

const db = admin.firestore();

interface LeaveType {
  id?: string;
  type: string;
  description?: string;
  allowedDays: number;
  carryForward: boolean;
  maxCarryForwardDays?: number;
  requiresApproval: boolean;
  documentRequired: boolean;
  active: boolean;
  color?: string;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
  createdBy: string;
  updatedBy: string;
}

/**
 * Create a new leave type (Admin only)
 */
export const createLeaveType = async (req: Request, res: Response): Promise<Response> => {
  try {
    const currentUser = (req as any).user;
    const {
      type,
      description = '',
      allowedDays,
      carryForward = false,
      maxCarryForwardDays = 0,
      requiresApproval = true,
      documentRequired = false,
      active = true,
      color = '#3b82f6' // Default blue color
    } = req.body;

    // Validate required fields
    if (!type || typeof allowedDays === 'undefined') {
      return res.status(400).json({ error: 'Type and allowedDays are required' });
    }

    // Check if leave type already exists (case-insensitive)
    const existingType = await db
      .collection('leaveTypes')
      .where('type', '==', type)
      .limit(1)
      .get();

    if (!existingType.empty) {
      return res.status(409).json({ error: 'Leave type already exists' });
    }

    const now = admin.firestore.Timestamp.now();
    const leaveTypeData: Omit<LeaveType, 'id'> = {
      type,
      description,
      allowedDays: Number(allowedDays),
      carryForward,
      maxCarryForwardDays: carryForward ? Number(maxCarryForwardDays) : 0,
      requiresApproval,
      documentRequired,
      active,
      color,
      createdAt: now,
      updatedAt: now,
      createdBy: currentUser.userId,
      updatedBy: currentUser.userId,
    };

    const leaveTypeRef = await db.collection('leaveTypes').add(leaveTypeData);
    const leaveType = { id: leaveTypeRef.id, ...leaveTypeData };

    return res.status(201).json(leaveType);
  } catch (error) {
    console.error('Error creating leave type:', error);
    return res.status(500).json({ error: 'Failed to create leave type' });
  }
};

/**
 * List all active leave types
 */
export const listLeaveTypes = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { activeOnly = 'true' } = req.query;
    const showActiveOnly = activeOnly === 'true';

    let query = db.collection('leaveTypes');
    
    // Filter by active status if needed
    if (showActiveOnly) {
      query = query.where('active', '==', true) as any;
    }

    const snapshot = await query.orderBy('type').get();
    
    const leaveTypes = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      // Normalize fields
      allowedDays: Number(doc.data().allowedDays) || 0,
      maxCarryForwardDays: Number(doc.data().maxCarryForwardDays) || 0,
      active: doc.data().active !== false,
      // Ensure we don't expose internal fields
    }));

    return res.status(200).json(leaveTypes);
  } catch (error) {
    console.error('Error listing leave types:', error);
    return res.status(500).json({ error: 'Failed to fetch leave types' });
  }
};

/**
 * Update a leave type (Admin only)
 */
export const updateLeaveType = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { id } = req.params;
    const currentUser = (req as any).user;
    const {
      type,
      description,
      allowedDays,
      carryForward,
      maxCarryForwardDays,
      requiresApproval,
      documentRequired,
      active,
      color
    } = req.body;

    const leaveTypeRef = db.collection('leaveTypes').doc(id);
    const doc = await leaveTypeRef.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Leave type not found' });
    }

    const updates: Partial<LeaveType> = {
      updatedAt: admin.firestore.Timestamp.now(),
      updatedBy: currentUser.userId,
    };

    // Only update fields that are provided in the request
    if (type) updates.type = type;
    if (description !== undefined) updates.description = description;
    if (allowedDays !== undefined) updates.allowedDays = Number(allowedDays);
    if (carryForward !== undefined) updates.carryForward = carryForward;
    if (maxCarryForwardDays !== undefined) updates.maxCarryForwardDays = Number(maxCarryForwardDays);
    if (requiresApproval !== undefined) updates.requiresApproval = requiresApproval;
    if (documentRequired !== undefined) updates.documentRequired = documentRequired;
    if (active !== undefined) updates.active = active;
    if (color) updates.color = color;

    await leaveTypeRef.update(updates);
    const updatedDoc = await leaveTypeRef.get();

    return res.status(200).json({
      id: updatedDoc.id,
      ...updatedDoc.data(),
    });
  } catch (error) {
    console.error('Error updating leave type:', error);
    return res.status(500).json({ error: 'Failed to update leave type' });
  }
};

/**
 * Delete a leave type (Admin only)
 */
export const deleteLeaveType = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { id } = req.params;
    
    // Check if there are any leave requests associated with this type
    const leaveRequests = await db
      .collection('leaves')
      .where('leaveTypeId', '==', id)
      .limit(1)
      .get();

    if (!leaveRequests.empty) {
      return res.status(400).json({ 
        error: 'Cannot delete leave type with associated leave requests' 
      });
    }

    await db.collection('leaveTypes').doc(id).delete();
    
    return res.status(200).json({ message: 'Leave type deleted successfully' });
  } catch (error) {
    console.error('Error deleting leave type:', error);
    return res.status(500).json({ error: 'Failed to delete leave type' });
  }
};

/**
 * Get leave type by ID
 */
export const getLeaveTypeById = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { id } = req.params;
    
    const doc = await db.collection('leaveTypes').doc(id).get();
    
    if (!doc.exists) {
      return res.status(404).json({ error: 'Leave type not found' });
    }
    
    const leaveType = {
      id: doc.id,
      ...doc.data(),
      // Normalize fields
      allowedDays: Number(doc.data()?.allowedDays) || 0,
      maxCarryForwardDays: Number(doc.data()?.maxCarryForwardDays) || 0,
      active: doc.data()?.active !== false,
    };
    
    return res.status(200).json(leaveType);
  } catch (error) {
    console.error('Error fetching leave type:', error);
    return res.status(500).json({ error: 'Failed to fetch leave type' });
  }
};
