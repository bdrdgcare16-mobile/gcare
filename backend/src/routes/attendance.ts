import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import WebSocketManager from '../websocket';

// Get the WebSocket instance
let wsManager: WebSocketManager | null = null;

// Function to get WebSocket manager instance
function getWebSocketManager() {
  if (!wsManager) {
    // This will be set from the main index.ts file
    console.warn('WebSocket manager not initialized');
  }
  return wsManager;
}

// Function to set WebSocket manager instance
export function setWebSocketManager(manager: WebSocketManager) {
  wsManager = manager;
}

const router = Router();
const prisma = new PrismaClient();

// Get all attendance records (for admin)
router.get('/', async (req, res) => {
  try {
    const { date, status } = req.query;
    let where: any = {};
    
    if (date) {
      const targetDate = new Date(date as string);
      targetDate.setHours(0, 0, 0, 0);
      where.date = {
        gte: targetDate,
        lt: new Date(targetDate.getTime() + 24 * 60 * 60 * 1000)
      };
    }
    
    if (status) {
      where.status = status;
    }

    const records = await prisma.attendance.findMany({
      where,
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true
          }
        }
      },
      orderBy: { date: 'desc' }
    });
    
    res.json(records);
  } catch (error) {
    console.error('Error fetching attendance:', error);
    res.status(500).json({ error: 'Failed to fetch attendance records' });
  }
});

// Get attendance by user (for employees)
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { startDate, endDate } = req.query;
    
    let where: any = { userId: Number(userId) };
    
    if (startDate && endDate) {
      where.date = {
        gte: new Date(startDate as string),
        lte: new Date(endDate as string)
      };
    }

    const records = await prisma.attendance.findMany({
      where,
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true
          }
        }
      },
      orderBy: { date: 'desc' }
    });
    
    res.json(records);
  } catch (error) {
    console.error('Error fetching user attendance:', error);
    res.status(500).json({ error: 'Failed to fetch user attendance' });
  }
});

// Get today's attendance for user
router.get('/user/:userId/today', async (req, res) => {
  try {
    const { userId } = req.params;
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const record = await prisma.attendance.findFirst({
      where: {
        userId: Number(userId),
        date: {
          gte: today,
          lt: new Date(today.getTime() + 24 * 60 * 60 * 1000)
        }
      },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true
          }
        }
      }
    });
    
    res.json(record);
  } catch (error) {
    console.error('Error fetching today\'s attendance:', error);
    res.status(500).json({ error: 'Failed to fetch today\'s attendance' });
  }
});

// Check in endpoint with face recognition
router.post('/checkin', async (req, res) => {
  try {
    const { userId, timestamp, faceVerified } = req.body;
    
    if (!userId) {
      return res.status(400).json({ error: 'User ID is required' });
    }

    // Validate user exists
    const user = await prisma.user.findUnique({
      where: { id: Number(userId) }
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Check if attendance already exists for today
    const existingAttendance = await prisma.attendance.findFirst({
      where: {
        userId: Number(userId),
        date: {
          gte: today,
          lt: new Date(today.getTime() + 24 * 60 * 60 * 1000)
        }
      }
    });

    let attendanceRecord;

    if (existingAttendance) {
      if (existingAttendance.checkIn) {
        return res.status(400).json({ error: 'Already checked in today' });
      }
      
      // Update existing record
      attendanceRecord = await prisma.attendance.update({
        where: { id: existingAttendance.id },
        data: {
          checkIn: timestamp ? new Date(timestamp) : new Date(),
          status: 'PRESENT'
        },
        include: {
          user: {
            select: {
              id: true,
              name: true,
              email: true
            }
          }
        }
      });
    } else {
      // Create new record
      attendanceRecord = await prisma.attendance.create({
        data: {
          userId: Number(userId),
          date: today,
          checkIn: timestamp ? new Date(timestamp) : new Date(),
          status: 'PRESENT'
        },
        include: {
          user: {
            select: {
              id: true,
              name: true,
              email: true
            }
          }
        }
      });
    }

    // Send real-time notification to admin
    const wsManager = getWebSocketManager();
    if (wsManager) {
      wsManager.sendToRole('ADMIN', 'notification', {
        type: 'attendance',
        message: `${user.name} checked in`,
        attendance: attendanceRecord,
        timestamp: new Date()
      });
    }

    res.status(200).json({
      success: true,
      message: 'Check-in successful',
      attendance: attendanceRecord
    });
  } catch (error) {
    console.error('Check-in error:', error);
    res.status(500).json({ error: 'Failed to check in' });
  }
});

// Check out endpoint
router.post('/checkout', async (req, res) => {
  try {
    const { userId, timestamp } = req.body;
    
    if (!userId) {
      return res.status(400).json({ error: 'User ID is required' });
    }

    // Validate user exists
    const user = await prisma.user.findUnique({
      where: { id: Number(userId) }
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Find today's attendance record
    const attendance = await prisma.attendance.findFirst({
      where: {
        userId: Number(userId),
        date: {
          gte: today,
          lt: new Date(today.getTime() + 24 * 60 * 60 * 1000)
        }
      }
    });

    if (!attendance) {
      return res.status(404).json({ error: 'No check-in record found for today' });
    }

    if (!attendance.checkIn) {
      return res.status(400).json({ error: 'Must check in before checking out' });
    }

    if (attendance.checkOut) {
      return res.status(400).json({ error: 'Already checked out today' });
    }

    // Update check-out time
    const updatedAttendance = await prisma.attendance.update({
      where: { id: attendance.id },
      data: {
        checkOut: timestamp ? new Date(timestamp) : new Date(),
        status: 'CHECKED_OUT'
      },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true
          }
        }
      }
    });

    // Send real-time notification to admin
    const wsManager = getWebSocketManager();
    if (wsManager) {
      wsManager.sendToRole('ADMIN', 'notification', {
        type: 'attendance',
        message: `${user.name} checked out`,
        attendance: updatedAttendance,
        timestamp: new Date()
      });
    }

    res.status(200).json({
      success: true,
      message: 'Check-out successful',
      attendance: updatedAttendance
    });
  } catch (error) {
    console.error('Check-out error:', error);
    res.status(500).json({ error: 'Failed to check out' });
  }
});

// Get attendance statistics (for admin dashboard)
router.get('/stats/overview', async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const totalEmployees = await prisma.user.count({ where: { role: 'EMPLOYEE' } });
    const presentToday = await prisma.attendance.count({
      where: {
        date: {
          gte: today,
          lt: new Date(today.getTime() + 24 * 60 * 60 * 1000)
        },
        status: 'PRESENT'
      }
    });
    const absentToday = totalEmployees - presentToday;

    res.json({
      totalEmployees,
      presentToday,
      absentToday,
      attendanceRate: totalEmployees > 0 ? (presentToday / totalEmployees) * 100 : 0
    });
  } catch (error) {
    console.error('Error fetching attendance stats:', error);
    res.status(500).json({ error: 'Failed to fetch attendance statistics' });
  }
});

export default router; 