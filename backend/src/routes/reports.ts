import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { startOfMonth, endOfMonth, startOfYear, endOfYear, format } from 'date-fns';

const router = Router();
const prisma = new PrismaClient();

// Get attendance report
router.get('/attendance', async (req, res) => {
  try {
    const { userId, month, year, type } = req.query;
    
    let startDate: Date;
    let endDate: Date;
    
    if (type === 'monthly') {
      startDate = startOfMonth(new Date(parseInt(year as string), parseInt(month as string) - 1));
      endDate = endOfMonth(new Date(parseInt(year as string), parseInt(month as string) - 1));
    } else {
      startDate = startOfYear(new Date(parseInt(year as string)));
      endDate = endOfYear(new Date(parseInt(year as string)));
    }

    const where: any = {
      date: {
        gte: startDate,
        lte: endDate
      }
    };

    if (userId) {
      where.userId = parseInt(userId as string);
    }

    const attendance = await prisma.attendance.findMany({
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

    // Calculate statistics
    const totalDays = attendance.length;
    const presentDays = attendance.filter(a => a.status === 'Present').length;
    const absentDays = attendance.filter(a => a.status === 'Absent').length;
    const lateDays = attendance.filter(a => a.status === 'Late').length;
    const attendanceRate = totalDays > 0 ? (presentDays / totalDays) * 100 : 0;

    res.json({
      attendance,
      statistics: {
        totalDays,
        presentDays,
        absentDays,
        lateDays,
        attendanceRate: Math.round(attendanceRate * 100) / 100
      },
      period: {
        startDate: format(startDate, 'yyyy-MM-dd'),
        endDate: format(endDate, 'yyyy-MM-dd'),
        type
      }
    });
  } catch (error) {
    console.error('Attendance report error:', error);
    res.status(500).json({ error: 'Failed to generate attendance report' });
  }
});

// Get payroll report
router.get('/payroll', async (req, res) => {
  try {
    const { userId, month, year } = req.query;
    
    const startDate = startOfMonth(new Date(parseInt(year as string), parseInt(month as string) - 1));
    const endDate = endOfMonth(new Date(parseInt(year as string), parseInt(month as string) - 1));

    const where: any = {
      month: parseInt(month as string),
      year: parseInt(year as string)
    };

    if (userId) {
      where.userId = parseInt(userId as string);
    }

    const payrolls = await prisma.payroll.findMany({
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
      orderBy: { createdAt: 'desc' }
    });

    // Calculate statistics
    const totalPayroll = payrolls.reduce((sum, p) => sum + p.amount, 0);
    const averageSalary = payrolls.length > 0 ? totalPayroll / payrolls.length : 0;
    const highestSalary = Math.max(...payrolls.map(p => p.amount));
    const lowestSalary = Math.min(...payrolls.map(p => p.amount));

    res.json({
      payrolls,
      statistics: {
        totalEmployees: payrolls.length,
        totalPayroll,
        averageSalary: Math.round(averageSalary * 100) / 100,
        highestSalary,
        lowestSalary
      },
      period: {
        month: parseInt(month as string),
        year: parseInt(year as string)
      }
    });
  } catch (error) {
    console.error('Payroll report error:', error);
    res.status(500).json({ error: 'Failed to generate payroll report' });
  }
});

// Get performance report
router.get('/performance', async (req, res) => {
  try {
    const { userId, month, year } = req.query;
    
    const startDate = startOfMonth(new Date(parseInt(year as string), parseInt(month as string) - 1));
    const endDate = endOfMonth(new Date(parseInt(year as string), parseInt(month as string) - 1));

    // Get tasks
    const taskWhere: any = {
      createdAt: {
        gte: startDate,
        lte: endDate
      }
    };

    if (userId) {
      taskWhere.userId = parseInt(userId as string);
    }

    const tasks = await prisma.task.findMany({
      where: taskWhere,
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

    // Get attendance
    const attendanceWhere: any = {
      date: {
        gte: startDate,
        lte: endDate
      }
    };

    if (userId) {
      attendanceWhere.userId = parseInt(userId as string);
    }

    const attendance = await prisma.attendance.findMany({
      where: attendanceWhere,
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

    // Calculate performance metrics
    const totalTasks = tasks.length;
    const completedTasks = tasks.filter(t => t.status === 'Completed').length;
    const pendingTasks = tasks.filter(t => t.status === 'Pending').length;
    const inProgressTasks = tasks.filter(t => t.status === 'In Progress').length;
    const taskCompletionRate = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;

    const totalAttendance = attendance.length;
    const presentDays = attendance.filter(a => a.status === 'Present').length;
    const attendanceRate = totalAttendance > 0 ? (presentDays / totalAttendance) * 100 : 0;

    res.json({
      tasks,
      attendance,
      performance: {
        taskMetrics: {
          totalTasks,
          completedTasks,
          pendingTasks,
          inProgressTasks,
          taskCompletionRate: Math.round(taskCompletionRate * 100) / 100
        },
        attendanceMetrics: {
          totalDays: totalAttendance,
          presentDays,
          attendanceRate: Math.round(attendanceRate * 100) / 100
        },
        overallScore: Math.round(((taskCompletionRate + attendanceRate) / 2) * 100) / 100
      },
      period: {
        startDate: format(startDate, 'yyyy-MM-dd'),
        endDate: format(endDate, 'yyyy-MM-dd')
      }
    });
  } catch (error) {
    console.error('Performance report error:', error);
    res.status(500).json({ error: 'Failed to generate performance report' });
  }
});

// Get leave report
router.get('/leave', async (req, res) => {
  try {
    const { userId, month, year } = req.query;
    
    const startDate = startOfMonth(new Date(parseInt(year as string), parseInt(month as string) - 1));
    const endDate = endOfMonth(new Date(parseInt(year as string), parseInt(month as string) - 1));

    const where: any = {
      startDate: {
        gte: startDate,
        lte: endDate
      }
    };

    if (userId) {
      where.userId = parseInt(userId as string);
    }

    const leaveRequests = await prisma.leaveRequest.findMany({
      where,
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true
          }
        },
        leaveType: true
      },
      orderBy: { createdAt: 'desc' }
    });

    // Calculate statistics
    const totalRequests = leaveRequests.length;
    const approvedRequests = leaveRequests.filter(l => l.status === 'Approved').length;
    const pendingRequests = leaveRequests.filter(l => l.status === 'Pending').length;
    const rejectedRequests = leaveRequests.filter(l => l.status === 'Rejected').length;
    const approvalRate = totalRequests > 0 ? (approvedRequests / totalRequests) * 100 : 0;

    // Group by leave type
    const leaveTypeStats = leaveRequests.reduce((acc, request) => {
      const type = request.leaveType.name;
      if (!acc[type]) {
        acc[type] = { count: 0, approved: 0, pending: 0, rejected: 0 };
      }
      acc[type].count++;
      if (request.status === 'Approved') acc[type].approved++;
      else if (request.status === 'Pending') acc[type].pending++;
      else if (request.status === 'Rejected') acc[type].rejected++;
      return acc;
    }, {} as any);

    res.json({
      leaveRequests,
      statistics: {
        totalRequests,
        approvedRequests,
        pendingRequests,
        rejectedRequests,
        approvalRate: Math.round(approvalRate * 100) / 100
      },
      leaveTypeStats,
      period: {
        startDate: format(startDate, 'yyyy-MM-dd'),
        endDate: format(endDate, 'yyyy-MM-dd')
      }
    });
  } catch (error) {
    console.error('Leave report error:', error);
    res.status(500).json({ error: 'Failed to generate leave report' });
  }
});

// Get dashboard summary
router.get('/dashboard', async (req, res) => {
  try {
    const today = new Date();
    const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
    const endOfMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0);

    // Get counts
    const totalEmployees = await prisma.user.count({ where: { role: 'EMPLOYEE' } });
    const activeEmployees = await prisma.user.count({ where: { role: 'EMPLOYEE' } });
    
    const todayAttendance = await prisma.attendance.count({
      where: {
        date: {
          gte: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
          lt: new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1)
        }
      }
    });

    const pendingLeaves = await prisma.leaveRequest.count({
      where: { status: 'Pending' }
    });

    const totalTasks = await prisma.task.count();
    const completedTasks = await prisma.task.count({
      where: { status: 'Completed' }
    });

    const totalPayroll = await prisma.payroll.aggregate({
      where: {
        month: today.getMonth() + 1,
        year: today.getFullYear()
      },
      _sum: { amount: true }
    });

    res.json({
      summary: {
        totalEmployees,
        activeEmployees,
        todayAttendance,
        pendingLeaves,
        totalTasks,
        completedTasks,
        totalPayroll: totalPayroll._sum.amount || 0
      },
      period: {
        currentMonth: format(today, 'MMMM yyyy'),
        today: format(today, 'yyyy-MM-dd')
      }
    });
  } catch (error) {
    console.error('Dashboard report error:', error);
    res.status(500).json({ error: 'Failed to generate dashboard report' });
  }
});

export default router; 