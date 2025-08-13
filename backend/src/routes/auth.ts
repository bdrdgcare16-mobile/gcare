import { Router, Request, Response, NextFunction } from 'express';
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

// Extend Request interface to include user
interface AuthenticatedRequest extends Request {
  user?: {
    userId: number;
    role: string;
  };
}

const router = Router();
const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'changeme';

// Input validation middleware
const validateEmail = (email: string) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

const validatePassword = (password: string) => {
  return password.length >= 6;
};

// Middleware to verify JWT token
const authenticateToken = (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, JWT_SECRET, (err: any, user: any) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
};

// Register
router.post('/register', async (req, res) => {
  try {
    const { 
      email, 
      password, 
      name, 
      role,
      phoneNumber,
      designation,
      department,
      gender,
      shiftTiming,
      reportingTo,
      dateOfJoining
    } = req.body;
    
    // Input validation
    if (!email || !password || !name || !role) {
      return res.status(400).json({ error: 'Email, password, name, and role are required' });
    }
    
    if (!validateEmail(email)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }
    
    if (!validatePassword(password)) {
      return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }
    
    if (!['ADMIN', 'EMPLOYEE'].includes(role)) {
      return res.status(400).json({ error: 'Invalid role. Must be ADMIN or EMPLOYEE' });
    }
    
    // Check if user already exists
    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) {
      return res.status(409).json({ error: 'Email already exists' });
    }
    
    // Hash password
    const hashed = await bcrypt.hash(password, parseInt(process.env.BCRYPT_ROUNDS || '10'));
    
    // Create user with all available details
    const user = await prisma.user.create({
      data: { 
        email, 
        password: hashed, 
        name, 
        role,
        phoneNumber: phoneNumber || null,
        designation: designation || null,
        department: department || null,
        gender: gender || null,
        shiftTiming: shiftTiming || '9:00 AM - 6:00 PM',
        reportingTo: reportingTo || null,
        dateOfJoining: dateOfJoining ? new Date(dateOfJoining) : new Date(),
      },
    });
    
    console.log(`✅ New user registered: ${user.name} (${user.email})`);
    
    res.status(201).json({ 
      message: 'User registered successfully',
      user: { 
        id: user.id, 
        email: user.email, 
        name: user.name, 
        role: user.role,
        phoneNumber: user.phoneNumber,
        designation: user.designation,
        department: user.department,
        gender: user.gender,
        shiftTiming: user.shiftTiming,
        reportingTo: user.reportingTo,
        dateOfJoining: user.dateOfJoining
      } 
    });
  } catch (err) {
    console.error('Registration error:', err);
    res.status(500).json({ error: 'Registration failed. Please try again.' });
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    // Input validation
    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }
    if (!validateEmail(email)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }
    // Find user
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    // For demo: accept any password or no password
    console.log(`✅ Login successful for: ${user.name} (${user.email})`);
    
    res.json({
      message: 'Login successful (demo mode)',
      token: 'demo_token_' + user.id,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        phoneNumber: user.phoneNumber,
        designation: user.designation,
        department: user.department,
        gender: user.gender,
        shiftTiming: user.shiftTiming,
        reportingTo: user.reportingTo,
        dateOfJoining: user.dateOfJoining
      }
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Login failed. Please try again.' });
  }
});

// Fetch all users (for debugging/demo)
router.get('/all-users', async (req, res) => {
  try {
    const users = await prisma.user.findMany();
    res.json(users);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// Get user profile
router.get('/profile', authenticateToken, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.userId;
    
    const user = await prisma.user.findUnique({ 
      where: { id: userId },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        phoneNumber: true,
        designation: true,
        department: true,
        gender: true,
        shiftTiming: true,
        reportingTo: true,
        dateOfJoining: true,
        createdAt: true,
        updatedAt: true
      }
    });
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json({ user });
  } catch (err) {
    console.error('Get profile error:', err);
    res.status(500).json({ error: 'Failed to get profile' });
  }
});

// Update user profile
router.put('/profile', authenticateToken, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.userId;
    const { 
      name, 
      phoneNumber, 
      designation, 
      department, 
      gender, 
      shiftTiming, 
      reportingTo 
    } = req.body;
    
    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: {
        name: name || undefined,
        phoneNumber: phoneNumber || undefined,
        designation: designation || undefined,
        department: department || undefined,
        gender: gender || undefined,
        shiftTiming: shiftTiming || undefined,
        reportingTo: reportingTo || undefined,
      },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        phoneNumber: true,
        designation: true,
        department: true,
        gender: true,
        shiftTiming: true,
        reportingTo: true,
        dateOfJoining: true,
        createdAt: true,
        updatedAt: true
      }
    });
    
    console.log(`✅ Profile updated for user: ${updatedUser.name} (${updatedUser.email})`);
    
    res.json({ 
      message: 'Profile updated successfully',
      user: updatedUser 
    });
  } catch (err) {
    console.error('Update profile error:', err);
    res.status(500).json({ error: 'Failed to update profile' });
  }
});

export default router; 