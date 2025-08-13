import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const router = Router();
const prisma = new PrismaClient();

// Create new employee
router.post('/employees', async (req, res) => {
  try {
    const { name, email, password } = req.body;
    
    // Input validation
    if (!email || !password || !name) {
      return res.status(400).json({ error: 'Name, email and password are required' });
    }
    
    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }
    
    // Validate password length
    if (password.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }
    
    // Check if user already exists
    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) {
      return res.status(409).json({ error: 'Email already exists' });
    }
    
    // Hash password
    const hashedPassword = await bcrypt.hash(password, parseInt(process.env.BCRYPT_ROUNDS || '10'));
    
    // Create employee
    const employee = await prisma.user.create({
      data: {
        email,
        password: hashedPassword,
        name,
        role: 'EMPLOYEE',
      },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        createdAt: true,
      },
    });
    
    res.status(201).json({ 
      message: 'Employee created successfully',
      employee 
    });
  } catch (err) {
    console.error('Create employee error:', err);
    res.status(500).json({ error: 'Failed to create employee. Please try again.' });
  }
});

// Get all employees
router.get('/employees', async (req, res) => {
  try {
    const employees = await prisma.user.findMany({
      where: { role: 'EMPLOYEE' },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        createdAt: true,
      },
      orderBy: { createdAt: 'desc' },
    });
    
    res.json({ employees });
  } catch (err) {
    console.error('Get employees error:', err);
    res.status(500).json({ error: 'Failed to fetch employees.' });
  }
});

// Get employee by ID
router.get('/employees/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const employee = await prisma.user.findFirst({
      where: { 
        id: parseInt(id),
        role: 'EMPLOYEE' 
      },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        createdAt: true,
      },
    });
    
    if (!employee) {
      return res.status(404).json({ error: 'Employee not found' });
    }
    
    res.json({ employee });
  } catch (err) {
    console.error('Get employee error:', err);
    res.status(500).json({ error: 'Failed to fetch employee.' });
  }
});

export default router; 