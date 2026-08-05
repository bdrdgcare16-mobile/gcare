import { Request, Response, NextFunction } from 'express';
import * as jwt from 'jsonwebtoken';
import { db } from '../config/firebase';

function getJwtSecret(): string {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    throw new Error('JWT_SECRET environment variable is required.');
  }
  return secret;
}

declare global {
  namespace Express {
    interface Request {
      user?: {
        userId: string;
        email: string;
        role: string;
        empid?: string | null;
        companyId?: string | null;
        companyName?: string | null;
        plan?: string | null;
      };
    }
  }
}

interface JwtPayload {
  userId?: string;
  uid?: string;
  email?: string;
  role?: string;
  userRole?: string;
  type?: string;
  isAdmin?: boolean;
  empid?: string | null;
  companyId?: string | null;
  iat?: number;
  exp?: number;
  [key: string]: any;
}

function getToken(req: Request): string | null {
  const h = (req.headers.authorization || req.headers.Authorization || '') as string;

  if (typeof h === 'string') {
    const [scheme, token] = h.split(' ');
    if (scheme && token && /^Bearer$/i.test(scheme)) return token.trim();
  }

  if (req.headers['x-access-token']) {
    return String(req.headers['x-access-token']).trim();
  }

  return null;
}

export const authMiddleware = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<Response | void> => {
  try {
    const token = getToken(req);

    if (!token) {
      console.error('JWT verification failed: No token provided');
      return res.status(401).json({ message: 'No token provided' });
    }

    return new Promise((resolve) => {
      jwt.verify(token, getJwtSecret(), async (err: any, decoded: any) => {
        if (err) {
          console.error('JWT verification failed', {
            name: err?.name,
            message: err?.message,
            hasToken: Boolean(token),
            tokenLength: token?.length ?? 0,
          });
          const statusCode = err?.name === 'TokenExpiredError' ? 401 : 403;
          const message = err?.name === 'TokenExpiredError' ? 'Session expired.' : 'Invalid or expired token';
          res.status(statusCode).json({ message });
          return resolve();
        }

        const jwtPayload = decoded as JwtPayload;

        try {
          // Security: Removed sensitive JWT payload logging

          // Normalize role field from various possible JWT field names
          let normalizedRole = 'employee'; // default
          if (jwtPayload.role) {
            normalizedRole = String(jwtPayload.role).toLowerCase();
          } else if (jwtPayload.userRole) {
            normalizedRole = String(jwtPayload.userRole).toLowerCase();
          } else if (jwtPayload.type) {
            normalizedRole = String(jwtPayload.type).toLowerCase();
          } else if (jwtPayload.isAdmin === true) {
            normalizedRole = 'admin';
          }

          // Normalize userId field
          const normalizedUserId = jwtPayload.userId || jwtPayload.uid || 'unknown';

          // Safe logging: non-sensitive data only
          console.log('[verifyToken] Authentication successful - role:', normalizedRole);
          console.log('[verifyToken] User ID exists:', !!normalizedUserId);
          console.log('[verifyToken] Company ID exists:', !!jwtPayload.companyId);
          console.log('[verifyToken] Empid exists:', !!jwtPayload.empid);

          // Initialize base user data
          let companyName: string | null = null;
          let plan: string | null = null;

          // Fetch companyName and plan from Firestore if companyId is available
          if (jwtPayload.companyId) {
            try {
              const companyDoc = await db.collection('companies').doc(jwtPayload.companyId).get();
              if (companyDoc.exists) {
                const companyData = companyDoc.data();
                companyName = companyData?.name || null;
                plan = companyData?.plan || null;
                console.log('[verifyToken] Company data fetched successfully');
              }
            } catch (fetchError) {
              console.error('[verifyToken] Error fetching company data:', fetchError);
              // Continue without company data - don't block authentication
            }
          }

          req.user = {
            userId: String(normalizedUserId),
            email: String(jwtPayload.email || ''),
            role: normalizedRole,
            empid: jwtPayload.empid ?? null,
            companyId: jwtPayload.companyId ?? null,
            companyName: companyName,
            plan: plan,
          };

          console.log('[verifyToken] User authentication completed');
          next();
          resolve();
        } catch (error) {
          console.error('Auth middleware error:', error);
          res.status(500).json({ message: 'Internal server error' });
          resolve();
        }
      });
    });
  } catch (error) {
    console.error('Auth middleware error:', error);
    res.status(401).json({ error: 'Invalid or expired token' });
  }
};

export const roleMiddleware = (roles: string[]) => {
  return (req: Request, res: Response, next: NextFunction): Response | void => {
    if (!req.user) {
      return res.status(401).json({ error: 'Not authenticated' });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Not authorized' });
    }

    next();
  };
};

export const verifyToken = authMiddleware;

export const isAdmin = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  console.log('[isAdmin] Checking admin access - role:', req.user?.role);
  
  return roleMiddleware(['admin'])(req, res, next);
};

export const isAdminOrEmployee = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  console.log('[isAdminOrEmployee] Checking admin or employee access - role:', req.user?.role);
  
  return roleMiddleware(['admin', 'employee'])(req, res, next);
};