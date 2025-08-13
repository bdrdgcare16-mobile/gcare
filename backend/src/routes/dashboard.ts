import express from 'express';
import { PrismaClient } from '@prisma/client';

const router = express.Router();
const prisma = new PrismaClient();

// Get employee dashboard statistics
router.get('/employee-stats', async (req, res) => {
  try {
    // For now, return default data since we need user authentication
    // In a real app, you would get the user ID from the JWT token
    
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // Get today's tasks
    const todayTasks = await prisma.task.findMany({
      where: {
        createdAt: {
          gte: today,
          lt: tomorrow
        }
      },
      take: 5,
      orderBy: {
        createdAt: 'desc'
      }
    });

    // Get task statistics
    const totalTasks = await prisma.task.count();
    const completedTasks = await prisma.task.count({
      where: { status: 'COMPLETED' }
    });
    const pendingTasks = await prisma.task.count({
      where: { status: 'PENDING' }
    });

    // Get today's attendance
    const todayAttendance = await prisma.attendance.findFirst({
      where: {
        date: {
          gte: today,
          lt: tomorrow
        }
      },
      orderBy: {
        date: 'desc'
      }
    });

    res.json({
      success: true,
      userName: 'Employee', // This should come from user session
      shiftTiming: '9:00 AM - 6:00 PM',
      location: 'Office Location',
      todayTasks: todayTasks.map(task => ({
        title: task.title,
        status: task.status,
        description: task.description
      })),
      attendanceStatus: todayAttendance ? 'Checked In' : 'Not Checked In',
      checkInTime: todayAttendance?.checkIn,
      checkOutTime: todayAttendance?.checkOut,
      workDuration: todayAttendance ? 
        (todayAttendance.checkOut ? 
          (todayAttendance.checkOut.getTime() - todayAttendance.checkIn!.getTime()) / 1000 / 60 : 
          (Date.now() - todayAttendance.checkIn!.getTime()) / 1000 / 60) : 0,
      totalTasks,
      completedTasks,
      pendingTasks
    });
  } catch (error) {
    console.error('Error fetching employee dashboard stats:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching employee dashboard statistics'
    });
  }
});

// Get attendance statistics
router.get('/attendance/stats', async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const todayAttendance = await prisma.attendance.count({
      where: {
        date: {
          gte: today,
          lt: tomorrow
        }
      }
    });

    const present = await prisma.attendance.count({
      where: {
        date: {
          gte: today,
          lt: tomorrow
        },
        status: 'PRESENT'
      }
    });

    const absent = await prisma.attendance.count({
      where: {
        date: {
          gte: today,
          lt: tomorrow
        },
        status: 'ABSENT'
      }
    });

    const late = await prisma.attendance.count({
      where: {
        date: {
          gte: today,
          lt: tomorrow
        },
        status: 'LATE'
      }
    });

    res.json({
      success: true,
      todayAttendance,
      present,
      absent,
      late,
      workDuration: 0 // This should be calculated based on user's attendance
    });
  } catch (error) {
    console.error('Error fetching attendance stats:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching attendance statistics'
    });
  }
});

// Get task statistics
router.get('/tasks/stats', async (req, res) => {
  try {
    const totalTasks = await prisma.task.count();
    const completedTasks = await prisma.task.count({
      where: { status: 'COMPLETED' }
    });
    const pendingTasks = await prisma.task.count({
      where: { status: 'PENDING' }
    });
    const inProgressTasks = await prisma.task.count({
      where: { status: 'IN_PROGRESS' }
    });

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const todayTasks = await prisma.task.findMany({
      where: {
        createdAt: {
          gte: today,
          lt: tomorrow
        }
      },
      take: 5,
      orderBy: {
        createdAt: 'desc'
      }
    });

    res.json({
      success: true,
      totalTasks,
      completedTasks,
      pendingTasks,
      inProgressTasks,
      todayTasks: todayTasks.map(task => ({
        title: task.title,
        status: task.status,
        description: task.description
      }))
    });
  } catch (error) {
    console.error('Error fetching task stats:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching task statistics'
    });
  }
});

export default router; 