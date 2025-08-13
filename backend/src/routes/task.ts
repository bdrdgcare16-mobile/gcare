import express from 'express';
import { PrismaClient } from '@prisma/client';
import WebSocketManager from '../websocket';

const router = express.Router();
const prisma = new PrismaClient();

let wsManager: WebSocketManager | null = null;
export function setWebSocketManager(manager: WebSocketManager) {
  wsManager = manager;
}

// Get all tasks (Admin)
router.get('/', async (req, res) => {
  try {
    const tasks = await prisma.task.findMany({
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

    res.json({ success: true, data: tasks });
  } catch (error) {
    console.error('GET / error:', error);
    res.status(500).json({ success: false, error: (error as any)?.message || 'Internal server error' });
  }
});

// Get user tasks
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const tasks = await prisma.task.findMany({
      where: {
        userId: parseInt(userId)
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    res.json({ success: true, data: tasks });
  } catch (error) {
    console.error('GET / error:', error);
    res.status(500).json({ success: false, error: (error as any)?.message || 'Internal server error' });
  }
});

// Create task (Admin assigns to employee)
router.post('/', async (req, res) => {
  try {
    const { userId, title, description, priority, dueDate, assignedBy } = req.body;
    
    const task = await prisma.task.create({
      data: {
        userId: parseInt(userId),
        title,
        description,
        priority: priority || 'MEDIUM',
        dueDate: dueDate ? new Date(dueDate) : null,
        assignedBy: parseInt(assignedBy),
        status: 'PENDING'
      }
    });

    // Create notification for employee
    await prisma.notification.create({
      data: {
        userId: parseInt(userId),
        title: 'New Task Assigned',
        message: `You have been assigned: ${title}`,
        type: 'TASK'
      }
    });

    // Realtime: notify the assigned user and admins
    if (wsManager) {
      wsManager.sendNotification(parseInt(userId), {
        type: 'task',
        message: `You have been assigned: ${title}`,
        task,
        timestamp: new Date().toISOString(),
      });
      wsManager.sendToRole('ADMIN', 'notification', {
        type: 'task',
        message: `Task assigned to user ${userId}: ${title}`,
        task,
        timestamp: new Date().toISOString(),
      });
      wsManager.broadcast('task_updated', { taskId: task.id, status: task.status, task });
    }

    res.json({ success: true, data: task });
  } catch (error) {
    console.error('GET / error:', error);
    res.status(500).json({ success: false, error: (error as any)?.message || 'Internal server error' });
  }
});

// Update task status (Employee)
router.put('/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    
    const task = await prisma.task.update({
      where: { id: parseInt(id) },
      data: {
        status,
        completedAt: status === 'COMPLETED' ? new Date() : null
      }
    });

    // Create notification for admin
    await prisma.notification.create({
      data: {
        userId: task.assignedBy || 1,
        title: 'Task Status Updated',
        message: `Task "${task.title}" has been updated to ${status}`,
        type: 'TASK'
      }
    });

    // Realtime: notify assignee and admins
    if (wsManager) {
      wsManager.sendNotification(task.userId, {
        type: 'task',
        message: `Task "${task.title}" status updated to ${status}`,
        task,
        timestamp: new Date().toISOString(),
      });
      wsManager.sendToRole('ADMIN', 'notification', {
        type: 'task',
        message: `Task "${task.title}" has been updated to ${status}`,
        task,
        timestamp: new Date().toISOString(),
      });
      wsManager.broadcast('task_updated', { taskId: task.id, status: task.status, task });
    }

    res.json({ success: true, data: task });
  } catch (error) {
    console.error('GET / error:', error);
    res.status(500).json({ success: false, error: (error as any)?.message || 'Internal server error' });
  }
});

// Update task (Admin)
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, priority, dueDate, status } = req.body;
    
    const task = await prisma.task.update({
      where: { id: parseInt(id) },
      data: {
        title,
        description,
        priority,
        dueDate: dueDate ? new Date(dueDate) : null,
        status,
        completedAt: status === 'COMPLETED' ? new Date() : null
      }
    });

    res.json({ success: true, data: task });
  } catch (error) {
    console.error('GET / error:', error);
    res.status(500).json({ success: false, error: (error as any)?.message || 'Internal server error' });
  }
});

// Delete task
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    await prisma.task.delete({
      where: { id: parseInt(id) }
    });

    res.json({ success: true, message: 'Task deleted successfully' });
  } catch (error) {
    console.error('GET / error:', error);
    res.status(500).json({ success: false, error: (error as any)?.message || 'Internal server error' });
  }
});

// Get task statistics
router.get('/stats/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const stats = await prisma.task.groupBy({
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

export default router; 