import express from 'express';
import { PrismaClient } from '@prisma/client';

const router = express.Router();
const prisma = new PrismaClient();

// Get dashboard statistics
router.get('/dashboard-stats', async (req, res) => {
  try {
    // Get total employees (users with EMPLOYEE role)
    const totalEmployees = await prisma.user.count({
      where: { role: 'EMPLOYEE' }
    });

    // Get total admins
    const totalAdmins = await prisma.user.count({
      where: { role: 'ADMIN' }
    });

    // Get pending leave requests
    const pendingLeaves = await prisma.leaveRequest.count({
      where: { status: 'PENDING' }
    });

    // Get today's attendance
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

    // Get total payroll amount (sum of all payroll records)
    const payrollResult = await prisma.payroll.aggregate({
      _sum: {
        amount: true
      }
    });
    const totalPayroll = payrollResult._sum.amount || 0;

    // Get total announcements
    const announcements = await prisma.announcement.count();

    res.json({
      success: true,
      totalEmployees,
      activeEmployees: totalEmployees, // Assuming all employees are active
      pendingLeaves,
      todayAttendance,
      totalPayroll,
      announcements,
      totalUsers: totalEmployees + totalAdmins
    });
  } catch (error) {
    console.error('Error fetching dashboard stats:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching dashboard statistics'
    });
  }
});

// Get user statistics
router.get('/user-stats', async (req, res) => {
  try {
    const totalUsers = await prisma.user.count();
    const employees = await prisma.user.count({
      where: { role: 'EMPLOYEE' }
    });
    const admins = await prisma.user.count({
      where: { role: 'ADMIN' }
    });

    res.json({
      success: true,
      totalUsers,
      employees,
      admins
    });
  } catch (error) {
    console.error('Error fetching user stats:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching user statistics'
    });
  }
});

// Get attendance statistics
router.get('/attendance-stats', async (req, res) => {
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
      late
    });
  } catch (error) {
    console.error('Error fetching attendance stats:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching attendance statistics'
    });
  }
});

// Get leave request statistics
router.get('/leave-stats', async (req, res) => {
  try {
    const pendingLeaves = await prisma.leaveRequest.count({
      where: { status: 'PENDING' }
    });

    const approvedLeaves = await prisma.leaveRequest.count({
      where: { status: 'APPROVED' }
    });

    const rejectedLeaves = await prisma.leaveRequest.count({
      where: { status: 'REJECTED' }
    });

    const totalRequests = await prisma.leaveRequest.count();

    res.json({
      success: true,
      pendingLeaves,
      approvedLeaves,
      rejectedLeaves,
      totalRequests
    });
  } catch (error) {
    console.error('Error fetching leave stats:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching leave statistics'
    });
  }
});

export default router; 