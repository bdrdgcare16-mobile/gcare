import { Request, Response } from 'express';
import * as admin from 'firebase-admin';
import * as bcrypt from 'bcryptjs';
import * as jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { defineString } from 'firebase-functions/params';

const db = admin.firestore();

// Define parameters
const jwtSecret = defineString('JWT_SECRET', { default: 'your-default-jwt-secret' });
const jwtExpiresIn = defineString('JWT_EXPIRES_IN', { default: '24h' });

interface User {
  id: string;
  email: string;
  password: string;
  name: string;
  role: string;
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
}

export const register = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { email, password, name, role = 'user' } = req.body;

    // Validate input
    if (!email || !password || !name) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Check if user already exists
    const userSnapshot = await db.collection('users').where('email', '==', email).get();
    if (!userSnapshot.empty) {
      return res.status(400).json({ error: 'User already exists' });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Create user
    const userId = uuidv4();
    const newUser: Omit<User, 'id'> = {
      email,
      password: hashedPassword,
      name,
      role,
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    };

    await db.collection('users').doc(userId).set(newUser);

    // Generate JWT token
    const token = jwt.sign(
      { userId, email, role },
      jwtSecret.value(),
      { expiresIn: jwtExpiresIn.value() } as jwt.SignOptions
    );

    // Return user data (excluding password)
    const { password: _, ...userData } = newUser;
    return res.status(201).json({ ...userData, id: userId, token });
  } catch (error) {
    console.error('Registration error:', error);
    return res.status(500).json({ error: 'Failed to register user' });
  }
};

export const login = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { email, password } = req.body;

    // Validate input
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    // Find user
    const userSnapshot = await db.collection('users').where('email', '==', email).limit(1).get();
    if (userSnapshot.empty) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const userDoc = userSnapshot.docs[0];
    const userData = userDoc.data() as User;

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, userData.password);
    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { userId: userDoc.id, email: userData.email, role: userData.role },
      jwtSecret.value(),
      { expiresIn: jwtExpiresIn.value() } as jwt.SignOptions
    );

    // Return user data (excluding password)
    const { password: _, ...userWithoutPassword } = userData;
    return res.json({ ...userWithoutPassword, id: userDoc.id, token });
  } catch (error) {
    console.error('Login error:', error);
    return res.status(500).json({ error: 'Failed to login' });
  }
};

export const getProfile = async (req: Request & { user?: any }, res: Response): Promise<Response | void> => {
  try {
    const userId = req.user.userId;
    const userDoc = await db.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userData = userDoc.data() as User;
    const { password, ...userWithoutPassword } = userData;
    
    res.json({ ...userWithoutPassword, id: userDoc.id });
  } catch (error) {
    console.error('Get profile error:', error);
    return res.status(500).json({ error: 'Failed to fetch profile' });
  }
};

// Other auth controller methods (updateProfile, changePassword, etc.) would go here
export const forgotPassword = async (req: Request, res: Response) => {
  // Implementation for forgot password
  res.json({ message: 'Password reset email sent' });
};

export const resetPassword = async (req: Request, res: Response) => {
  // Implementation for reset password
  res.json({ message: 'Password reset successful' });
};

export const updateProfile = async (req: any, res: Response) => {
  // Implementation for updating profile
  res.json({ message: 'Profile updated successfully' });
};

export const changePassword = async (req: any, res: Response) => {
  // Implementation for changing password
  res.json({ message: 'Password changed successfully' });
};
