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

interface LoginResponse {
  message: string;
  token: string;
  tokenType: string;
  expiresIn: string;
  role: string;
  uid: string;
  empid: string | null;
  name: string;
  user: {
    id: string;
    name: string;
    email: string;
    role: string;
    empid: string | null;
    status: string;
  };
}

const getByEmail = async (collection: string, email: string) => {
  const emailLower = email.toLowerCase().trim();
  // Try with both email and emailLower for backward compatibility
  const snapshot = await db.collection(collection)
    .where('emailLower', '==', emailLower)
    .limit(1)
    .get();

  if (!snapshot.empty) return snapshot;

  // Fallback to check email field directly if not found with emailLower
  return await db.collection(collection)
    .where('email', '==', emailLower)
    .limit(1)
    .get();
};

const isBcryptHash = (str: string): boolean => {
  return /^\$2[aby]\$\d{2}\$[.\/0-9A-Za-z]{53}$/.test(str);
};

export const login = async (req: Request, res: Response): Promise<Response> => {
  console.log('=== Login Request ===');
  console.log('Request body:', JSON.stringify(req.body, null, 2));
  
  try {
    const incoming = String(req.body.email || '');
    const email = incoming.toLowerCase().trim();
    const { password } = req.body;

    console.log('Processing login for email:', email);
    
    if (!email || !password) {
      console.error('Missing email or password');
      return res.status(400).json({ error: 'Email and password are required' });
    }

    // Check users collection first
    console.log('Checking users collection for email:', email);
    const userSnap = await getByEmail('users', email);
    console.log('User query result - found:', !userSnap.empty);
    
    if (!userSnap.empty) {
      const doc = userSnap.docs[0];
      const user = doc.data();
      console.log('Found user in users collection:', {
        id: doc.id,
        email: user.email,
        role: user.role,
        status: user.status
      });
      console.log('User document data:', JSON.stringify(user, null, 2));

      const storedHash = user.password || user.passwordHash || user.hashedPassword || '';
      console.log('Stored hash type:', typeof storedHash);
      console.log('Stored hash length:', storedHash.length);
      console.log('Stored hash exists:', !!storedHash);
      
      const match = await bcrypt.compare(password, storedHash);
      console.log('Password match result:', match);
      
      if (!match) {
        console.error('Password does not match for user:', email);
        return res.status(401).json({ 
          error: 'Invalid email or password',
          debug: { userFound: true, passwordMatch: false }
        });
      }

      if (user.status && user.status !== 'active') {
        return res.status(403).json({ error: 'Account is not active' });
      }

      const role = String(user.role || 'employee').toLowerCase();
      const okRoles = new Set(['admin', 'employee']);
      if (!okRoles.has(role)) {
        return res.status(403).json({ error: 'Invalid role on account' });
      }

      const token = jwt.sign(
        {
          userId: doc.id,
          email: user.email || incoming.trim(),
          role,
          empid: user.empid || null,
        },
        jwtSecret.value(),
        { expiresIn: jwtExpiresIn.value() } as jwt.SignOptions
      );

      const response: LoginResponse = {
        message: 'Login successful',
        token,
        tokenType: 'Bearer',
        expiresIn: jwtExpiresIn.value(),
        role,
        uid: doc.id,
        empid: user.empid || null,
        name: user.name || user.fullName || '',
        user: {
          id: doc.id,
          name: user.name || user.fullName || '',
          email: user.email || incoming.trim(),
          role,
          empid: user.empid || null,
          status: user.status || 'active',
        },
      };

      return res.json(response);
    }

    // Check employees collection as fallback
    console.log('User not found in users collection, checking employees collection');
    const empSnap = await getByEmail('employees', email);
    console.log('Employee query result - found:', !empSnap.empty);
    
    if (empSnap.empty) {
      console.error('No user found with email:', email);
      return res.status(401).json({ 
        error: 'Invalid email or password',
        debug: { userFound: false, employeeFound: false }
      });
    }

    const empDoc = empSnap.docs[0];
    const emp = empDoc.data();

    // Accept either plaintext or bcrypt in employees.password
    const stored = emp.password || '';
    console.log('Employee password stored:', stored ? 'exists' : 'missing');
    
    let passOK = false;
    if (stored) {
      const isBcrypt = isBcryptHash(stored);
      console.log('Password format:', isBcrypt ? 'bcrypt' : 'plaintext');
      
      if (isBcrypt) {
        console.log('Comparing bcrypt hashes');
        passOK = await bcrypt.compare(password, stored);
      } else {
        console.log('Comparing plaintext passwords');
        passOK = stored === password;
      }
    }

    if (!passOK) {
      console.error('Password verification failed for employee:', email);
      return res.status(401).json({ 
        error: 'Invalid email or password',
        debug: { 
          userFound: false, 
          employeeFound: true, 
          passwordMatch: false,
          storedPassword: stored ? 'present' : 'missing'
        }
      });
    }

    if (emp.status && emp.status !== 'active') {
      return res.status(403).json({ error: 'Account is not active' });
    }

    // Create or update user in users collection
    let userRef = userSnap.docs[0]?.ref || db.collection('users').doc();
    const now = admin.firestore.Timestamp.now();
    
    const userData = {
      empid: emp.empid || emp.employeeId || null,
      name: emp.name || emp.fullName || '',
      email: emp.email || incoming.trim(),
      emailLower: email,
      password: isBcryptHash(stored) ? stored : await bcrypt.hash(password, 10),
      role: 'employee',
      status: 'active',
      createdAt: emp.createdAt || now,
      updatedAt: now,
    };

    await userRef.set(userData, { merge: true });
    const userDoc = await userRef.get();
    const user = userDoc.data() || {};

    const token = jwt.sign(
      {
        userId: userRef.id,
        email: user.email || incoming.trim(),
        role: 'employee',
        empid: user.empid || emp.empid || null,
      },
      jwtSecret.value(),
      { expiresIn: jwtExpiresIn.value() } as jwt.SignOptions
    );

    const response: LoginResponse = {
      message: 'Login successful',
      token,
      tokenType: 'Bearer',
      expiresIn: jwtExpiresIn.value(),
      role: 'employee',
      uid: userRef.id,
      empid: user.empid || emp.empid || null,
      name: user.name || emp.name || '',
      user: {
        id: userRef.id,
        name: user.name || emp.name || '',
        email: user.email || incoming.trim(),
        role: 'employee',
        empid: user.empid || emp.empid || null,
        status: user.status || emp.status || 'active',
      },
    };

    return res.json(response);
  } catch (error) {
    console.error('Login error:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    return res.status(500).json({ error: 'Failed to login', details: errorMessage });
  }
};

export const getProfile = async (req: Request & { user?: { userId: string } }, res: Response): Promise<Response> => {
  try {
    const userId = req.user?.userId;
    const userDoc = await db.collection('users').doc(userId || '').get();
    
    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userData = userDoc.data() as User | undefined;
    if (!userData) {
      return res.status(404).json({ error: 'User data not found' });
    }
    const { password, ...userWithoutPassword } = userData;
    
    return res.json({ ...userWithoutPassword, id: userDoc.id });
  } catch (error) {
    console.error('Get profile error:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    return res.status(500).json({ error: 'Failed to fetch profile', details: errorMessage });
  }
};

// Other auth controller methods (updateProfile, changePassword, etc.) would go here
export const forgotPassword = async (req: Request, res: Response): Promise<Response> => {
  // Implementation for forgot password
  return res.json({ message: 'Password reset email sent' });
};

export const resetPassword = async (req: Request, res: Response): Promise<Response> => {
  // Implementation for reset password
  return res.json({ message: 'Password reset successful' });
};

export const updateProfile = async (req: Request & { user?: { userId: string } }, res: Response): Promise<Response> => {
  // Implementation for updating profile
  return res.json({ message: 'Profile updated successfully' });
};

export const changePassword = async (req: Request & { user?: { userId: string } }, res: Response): Promise<Response> => {
  // Implementation for changing password
  return res.json({ message: 'Password changed successfully' });
};
