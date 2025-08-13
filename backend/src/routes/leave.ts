import express from 'express';
import { PrismaClient } from '@prisma/client';
import WebSocketManager from '../websocket';

const router = express.Router();
const prisma = new PrismaClient();

let wsManager: WebSocketManager | null = null;
export function setWebSocketManager(manager: WebSocketManager) {
  wsManager = manager;
}

// Get all leave requests (Admin)
router.get('/', async (req, res) => {
  try {
    const leaveRequests = await prisma.leaveRequest.findMany({
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            department: true
          }
        },
        leaveType: true
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    res.json({ success: true, data: leaveRequests });
  } catch (error) {
    console.error('GET / error:', error);
    res.status(500).json({ success: false, error: (error as any)?.message || 'Internal server error' });
  }
});

// Get user's leave requests
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const leaveRequests = await prisma.leaveRequest.findMany({
      where: {
        userId: parseInt(userId)
      },
      include: {
        leaveType: true
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    res.json({ success: true, data: leaveRequests });
  } catch (error) {
    console.error('GET / error:', error);
    res.status(500).json({ success: false, error: (error as any)?.message || 'Internal server error' });
  }
});

// Create leave request (Employee)
router.post('/', async (req, res) => {
  try {
    const { userId, leaveTypeId, startDate, endDate, reason } = req.body;
    
    const leaveRequest = await prisma.leaveRequest.create({
      data: {
        userId: parseInt(userId),
        leaveTypeId: parseInt(leaveTypeId),
        startDate: new Date(startDate),
        endDate: new Date(endDate),
        reason,
        status: 'PENDING'
      },
      include: {
        leaveType: true,
        user: {
          select: {
            name: true,
            email: true
          }
        }
      }
    });

    // Create notification for admin
    await prisma.notification.create({
      data: {
        userId: 1, // Default admin
        title: 'Leave Request Pending',
        message: `${leaveRequest.user.name} has requested ${leaveRequest.leaveType.name}`,
        type: 'LEAVE'
      }
    });

    // Realtime: notify admins and the user
    if (wsManager) {
      wsManager.sendToRole('ADMIN', 'notification', {
        type: 'leave',
        message: `${leaveRequest.user.name} requested ${leaveRequest.leaveType.name}`,
        leaveRequest,
        timestamp: new Date().toISOString(),
      });
      wsManager.sendNotification(leaveRequest.userId, {
        type: 'leave',
        message: `Leave request submitted: ${leaveRequest.leaveType.name}`,
        leaveRequest,
        timestamp: new Date().toISOString(),
      });
      wsManager.broadcast('leave_request_updated', { requestId: leaveRequest.id, status: leaveRequest.status, leaveRequest });
    }

    res.json({ success: true, data: leaveRequest });
  } catch (error) {
    console.error('GET / error:', error);
    res.status(500).json({ success: false, error: (error as any)?.message || 'Internal server error' });
  }
});

// Approve/Reject leave request (Admin)
router.put('/:id/approve', async (req, res) => {
  try {
    const { id } = req.params;
    const { status, approvedBy } = req.body;
    
    const leaveRequest = await prisma.leaveRequest.update({
      where: { id: parseInt(id) },
      data: {
        status,
        approvedBy: parseInt(approvedBy),
        approvedAt: new Date()
      },
      include: {
        leaveType: true,
        user: {
          select: {
            name: true,
            email: true
          }
        }
      }
    });

    // Create notification for employee
    await prisma.notification.create({
      data: {
        userId: leaveRequest.userId,
        title: 'Leave Request Updated',
        message: `Your ${leaveRequest.leaveType.name} request has been ${status.toLowerCase()}`,
        type: 'LEAVE'
      }
    });

    // Realtime: notify employee and admins
    if (wsManager) {
      wsManager.sendNotification(leaveRequest.userId, {
        type: 'leave',
        message: `Your ${leaveRequest.leaveType.name} request has been ${status.toLowerCase()}`,
        leaveRequest,
        timestamp: new Date().toISOString(),
      });
      wsManager.sendToRole('ADMIN', 'notification', {
        type: 'leave',
        message: `Leave request for ${leaveRequest.user.name} ${status.toLowerCase()}`,
        leaveRequest,
        timestamp: new Date().toISOString(),
      });
      wsManager.broadcast('leave_request_updated', { requestId: leaveRequest.id, status: leaveRequest.status, leaveRequest });
    }

    res.json({ success: true, data: leaveRequest });
  } catch (error) {
    console.error('GET / error:', error);
    res.status(500).json({ success: false, error: (error as any)?.message || 'Internal server error' });
  }
});

// Get leave types
router.get('/types', async (req, res) => {
  try {
    const leaveTypes = await prisma.leaveType.findMany();
    res.json({ success: true, data: leaveTypes });
  } catch (error) {
    console.error('GET / error:', error);
    res.status(500).json({ success: false, error: (error as any)?.message || 'Internal server error' });
  }
});

// Get leave statistics
router.get('/stats/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const stats = await prisma.leaveRequest.groupBy({
      by: ['status'],
      where: {
        userId: parseInt(userId)
      },
      _count: {
        status: true
      }
    });

    res.json({ success: true, data: stats });
  } catch (error) {
    console.error('GET / error:', error);
    res.status(500).json({ success: false, error: (error as any)?.message || 'Internal server error' });
  }
});

// Delete leave request
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    await prisma.leaveRequest.delete({
      where: { id: parseInt(id) }
    });

    res.json({ success: true, message: 'Leave request deleted successfully' });
  } catch (error) {
    console.error('GET / error:', error);
    res.status(500).json({ success: false, error: (error as any)?.message || 'Internal server error' });
  }
});

export default router; 