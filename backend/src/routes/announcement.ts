import express from 'express';
import { PrismaClient } from '@prisma/client';

const router = express.Router();
const prisma = new PrismaClient();

// Get all announcements
router.get('/', async (req, res) => {
  try {
    const announcements = await prisma.announcement.findMany({
      orderBy: {
        createdAt: 'desc'
      }
    });
    res.json(announcements);
  } catch (error) {
    console.error('Error fetching announcements:', error);
    res.status(500).json({ error: 'Failed to fetch announcements' });
  }
});

// Get latest announcements (for employee dashboard)
router.get('/latest', async (req, res) => {
  try {
    const announcements = await prisma.announcement.findMany({
      take: 5,
      orderBy: {
        createdAt: 'desc'
      }
    });
    res.json(announcements);
  } catch (error) {
    console.error('Error fetching latest announcements:', error);
    res.status(500).json({ error: 'Failed to fetch latest announcements' });
  }
});

// Create announcement
router.post('/', async (req, res) => {
  const { title, content } = req.body;
  
  if (!title || !content) {
    return res.status(400).json({ error: 'Title and content are required' });
  }
  
  try {
    const announcement = await prisma.announcement.create({
      data: {
        title,
        content,
      }
    });
    
    // Broadcast to all connected clients via WebSocket
    // This will be handled by the WebSocket manager
    
    res.status(201).json({
      success: true,
      announcement,
      message: 'Announcement created successfully'
    });
  } catch (error) {
    console.error('Error creating announcement:', error);
    res.status(500).json({ error: 'Failed to create announcement' });
  }
});

// Update announcement
router.put('/:id', async (req, res) => {
  const { id } = req.params;
  const { title, content, priority, isPinned } = req.body;
  
  try {
    const announcement = await prisma.announcement.update({
      where: { id: parseInt(id) },
      data: {
        title,
        content,
        priority,
        isPinned,
        updatedAt: new Date()
      }
    });
    
    res.json({
      success: true,
      announcement,
      message: 'Announcement updated successfully'
    });
  } catch (error) {
    console.error('Error updating announcement:', error);
    res.status(500).json({ error: 'Failed to update announcement' });
  }
});

// Delete announcement
router.delete('/:id', async (req, res) => {
  const { id } = req.params;
  
  try {
    await prisma.announcement.delete({
      where: { id: parseInt(id) }
    });
    
    res.json({
      success: true,
      message: 'Announcement deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting announcement:', error);
    res.status(500).json({ error: 'Failed to delete announcement' });
  }
});

// Get announcement by ID
router.get('/:id', async (req, res) => {
  const { id } = req.params;
  
  try {
    const announcement = await prisma.announcement.findUnique({
      where: { id: parseInt(id) }
    });
    
    if (!announcement) {
      return res.status(404).json({ error: 'Announcement not found' });
    }
    
    res.json(announcement);
  } catch (error) {
    console.error('Error fetching announcement:', error);
    res.status(500).json({ error: 'Failed to fetch announcement' });
  }
});

export default router; 