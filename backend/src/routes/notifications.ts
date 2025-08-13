import express from 'express';
import { PrismaClient } from '@prisma/client';

const router = express.Router();
const prisma = new PrismaClient();

// Get user notifications
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const notifications = await prisma.notification.findMany({
      where: {
        userId: parseInt(userId)
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    res.json({ success: true, data: notifications });
  } catch (error) {
    console.error('Get user notifications error:', error);
    res.status(500).json({ success: false, error: (error as any)?.message || 'Internal server error' });
  }
});

// Mark notification as read
router.put('/read/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const notification = await prisma.notification.update({
      where: { id: parseInt(id) },
      data: { read: true }
    });

    res.json({ success: true, data: notification });
  } catch (error) {
    console.error('Mark notification as read error:', error);
    res.status(500).json({ success: false, error: (error as any)?.message || 'Internal server error' });
  }
});

// Mark all notifications as read
router.put('/read-all/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    await prisma.notification.updateMany({
      where: {
        userId: parseInt(userId),
        read: false
      },
      data: { read: true }
    });

    res.json({ success: true, message: 'All notifications marked as read' });
  } catch (error) {
    console.error('Mark all notifications as read error:', error);
    res.status(500).json({ success: false, error: (error as any)?.message || 'Internal server error' });
  }
});

// Get unread notification count
router.get('/unread-count/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const count = await prisma.notification.count({
      where: {
        userId: parseInt(userId),
        read: false
      }
    });

    res.json({ success: true, count });
  } catch (error) {
    console.error('Get unread notification count error:', error);
    res.status(500).json({ success: false, error: (error as any)?.message || 'Internal server error' });
  }
});

// Create notification
router.post('/', async (req, res) => {
  try {
    const { userId, title, message, type } = req.body;
    
    const notification = await prisma.notification.create({
      data: {
        userId: parseInt(userId),
        title,
        message,
        type
      }
    });

    res.json({ success: true, data: notification });
  } catch (error) {
    console.error('Create notification error:', error);
    res.status(500).json({ success: false, error: (error as any)?.message || 'Internal server error' });
  }
});

export default router; 