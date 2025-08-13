import express from 'express';
import { PrismaClient } from '@prisma/client';

const router = express.Router();
const prisma = new PrismaClient();

// Submit check-in request (Employee)
router.post('/request', async (req, res) => {
  try {
    const { userId, checkInTime, reason } = req.body;
    
    const checkInRequest = await prisma.checkInRequest.create({
      data: {
        userId: parseInt(userId),
        date: new Date(),
        checkInTime: new Date(checkInTime),
        reason: reason || 'Late arrival',
        status: 'PENDING'
      }
    });

    // Create notification for admin
    await prisma.notification.create({
      data: {
        userId: 1, // Default admin
        title: 'Check-in Request Pending',
        message: `Employee has submitted a late check-in request`,
        type: 'ATTENDANCE'
      }
    });

    res.json({ success: true, data: checkInRequest });
  } catch (error) {
    console.error('POST /request error:', error);
    res.status(500).json({ success: false, error: (error as any)?.message || 'Internal server error' });
  }
});

// Get check-in requests (Admin)
router.get('/requests', async (req, res) => {
  try {
    const requests = await prisma.checkInRequest.findMany({
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            department: true
          }
        }
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    res.json({ success: true, data: requests });
  } catch (error) {
    console.error('POST /request error:', error);
    res.status(500).json({ success: false, error: (error as any)?.message || 'Internal server error' });
  }
});

// Approve/Reject check-in request (Admin)
router.put('/request/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { status, approvedBy } = req.body;

    const request = await prisma.checkInRequest.update({
      where: { id: parseInt(id) },
      data: {
        status,
        approvedBy: parseInt(approvedBy),
        approvedAt: new Date()
      }
    });

    // Create notification for employee
    await prisma.notification.create({
      data: {
        userId: request.userId,
        title: 'Check-in Request Updated',
        message: `Your check-in request has been ${status.toLowerCase()}`,
        type: 'ATTENDANCE'
      }
    });

    res.json({ success: true, data: request });
  } catch (error) {
    console.error('POST /request error:', error);
    res.status(500).json({ success: false, error: (error as any)?.message || 'Internal server error' });
  }
});

// Get employee's check-in requests
router.get('/employee/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const requests = await prisma.checkInRequest.findMany({
      where: {
        userId: parseInt(userId)
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    res.json({ success: true, data: requests });
  } catch (error) {
    console.error('POST /request error:', error);
    res.status(500).json({ success: false, error: (error as any)?.message || 'Internal server error' });
  }
});

export default router; 