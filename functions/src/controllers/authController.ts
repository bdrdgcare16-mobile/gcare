import { Request, Response } from 'express';
import * as bcrypt from 'bcryptjs';
import { v4 as uuidv4 } from 'uuid';
import { rotatePassword } from '../services/passwordService';
import { successResponse, errorResponse } from "../common/response";
import { issueToken, getJwtExpires } from "../common/auth.utils";
import { okRoles } from "../common/constants";
import { normEmail } from "../common/utils";
import { isBcryptHash } from "../common/password.utils";
import { pickEmpId } from "../common/user.utils";

import { getDb, getAdminAuth, checkFirestoreAccess } from '../config/firebase';
import { type DocumentSnapshot } from 'firebase-admin/firestore';
import {
  getCompanyProfileByCode,
  normalizeOrgCode,
} from './companyController';

// ── Config ───────────────────────────────────────────────────────────────────
const JWT_EXPIRES = getJwtExpires();

const USERS_COL = 'users';
const EMPS_COL = 'employees';

// Roles permitted to complete Firebase login and receive a SERV JWT.
// 'platform_admin' is the browser Portal reviewer role (Milestone 3D-B);
// it is intentionally absent from okRoles so it can never be assigned
// through the user-management APIs — only seeded/provisioned server-side.
const LOGIN_ROLES = new Set([
  'employee',
  'admin',
  'super_admin',
  'platform_admin',
  'org_applicant',
]);

// Optional: where the Firebase hosted reset flow should land after completion
function getResetContinueUrl(): string {
  const configured = process.env.RESET_CONTINUE_URL?.trim();
  if (configured) {
    return configured;
  }

  if (process.env.FUNCTIONS_EMULATOR === 'true') {
    return 'http://localhost:3000/reset-done';
  }

  throw new Error('RESET_CONTINUE_URL is required');
}

// *** Web API key used only for server-side Firebase fallback ***
function getFirebaseWebApiKey(): string {
  const key = (process.env.APP_FIREBASE_WEB_API_KEY || '').trim();

  if (!/^AIza[0-9A-Za-z_\-]{10,}$/.test(key)) {
    console.warn(
      'APP_FIREBASE_WEB_API_KEY looks invalid or missing (pattern check failed).'
    );
  }

  console.log('[env] WEB_API_KEY configured:', key ? 'YES' : 'MISSING');
  return key;
}

// ── Optional mailer ──────────────────────────────────────────────────────────
let nodemailer: any = null;
try {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  nodemailer = require('nodemailer');
} catch {
  /* optional */
}

function makeTransport() {
  if (!nodemailer) return null;
  if (
    !process.env.SMTP_HOST ||
    !process.env.SMTP_USER ||
    !process.env.SMTP_PASS
  ) {
    return null;
  }

  return nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT || 587),
    secure: false,
    auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
  });
}
const mailer = makeTransport();

// ── Helpers ──────────────────────────────────────────────────────────────────
const sanitizeUser = (id: string, data: any) => {
  const { password, passwordHash, hashedPassword, ...rest } = data || {};
  return { id, ...rest };
};

async function getByEmail(colName: string, emailLower: string) {
  let snap = await getDb()
    .collection(colName)
    .where('emailLower', '==', emailLower)
    .limit(1)
    .get();
  if (!snap.empty) return snap;

  snap = await getDb()
    .collection(colName)
    .where('email', '==', emailLower)
    .limit(1)
    .get();
  if (!snap.empty) return snap;

  return null as any;
}

async function getUserDocByEmailAny(
  emailLower: string
): Promise<DocumentSnapshot | null> {
  let snap = await getDb()
    .collection(USERS_COL)
    .where('emailLower', '==', emailLower)
    .limit(1)
    .get();
  if (!snap.empty) return snap.docs[0];

  snap = await getDb()
    .collection(USERS_COL)
    .where('email', '==', emailLower)
    .limit(1)
    .get();
  if (!snap.empty) return snap.docs[0];

  return null;
}

/** Server-side fallback check against Firebase after hosted reset */
async function verifyWithFirebase(
  email: string,
  password: string
): Promise<boolean> {
  const apiKey = getFirebaseWebApiKey();
  if (!/^AIza/.test(apiKey)) {
    console.error('APP_FIREBASE_WEB_API_KEY invalid or missing at runtime');
    return false;
  }

  const url = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`;

  try {
    const resp = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    });

    if (!resp.ok) {
      const text = await resp.text().catch(() => '');
      console.warn('verifyWithFirebase failed:', resp.status, text);
      return false;
    }

    const data: any = await resp.json();
    return !!data?.idToken;
  } catch (e) {
    console.error('verifyWithFirebase error:', e);
    return false;
  }
}

// ── Controllers ──────────────────────────────────────────────────────────────

// POST /api/auth/register
export const register = async (req: Request, res: Response): Promise<Response> => {
  try {
    let {
      empid,
      name,
      email,
      password,
      role = 'employee',
      status = 'active',
      companyId,
    } = req.body || {};

    email = normEmail(email || '');
    empid = String(empid || '').trim();
    name = String(name || '').trim();
    role = String(role || 'employee').trim().toLowerCase();
    status = String(status || 'active').trim().toLowerCase();
    companyId = String(companyId || '').trim();

    if (!name || !email || !password) {
      return errorResponse(res, 'Name, email and password are required', 400);
    }

    if (!companyId) {
      return errorResponse(res, 'companyId is required', 400);
    }

    if (!okRoles.has(role)) {
      return errorResponse(res, 'Role must be "employee" or "admin"', 400);
    }

    const byEmail = await getDb()
      .collection(USERS_COL)
      .where('emailLower', '==', email)
      .limit(1)
      .get();

    if (!byEmail.empty) {
      return errorResponse(res, 'Email is already in use', 400);
    }

    if (empid) {
      const byEmp = await getDb()
        .collection(USERS_COL)
        .where('empid', '==', empid)
        .limit(1)
        .get();

      if (!byEmp.empty) {
        return errorResponse(res, 'Employee ID already exists', 400);
      }
    }

    const hash = await bcrypt.hash(password, 10);
    const now = new Date();
    const userId = uuidv4();

    await getDb().collection(USERS_COL).doc(userId).set({
      empid: empid || null,
      empId: empid || null,
      name,
      email,
      emailLower: email,
      password: hash,
      passwordHash: hash,
      hashedPassword: hash,
      role,
      status,
      companyId,
      createdAt: now,
      updatedAt: now,
    });

    const token = issueToken({
      userId,
      email,
      role,
      empid: empid || null,
      companyId,
    });

    return successResponse(
      res,
      {
        id: userId,
        name,
        email,
        role,
        empid: empid || null,
        companyId,
        status,
        token,
        tokenType: 'Bearer',
        expiresIn: JWT_EXPIRES,
      },
      'User registered successfully',
      201
    );
  } catch (error) {
    console.error('Registration error:', error);
    return errorResponse(res, 'Failed to register user', 500);
  }
};

// POST /api/auth/login
export const login = async (req: Request, res: Response): Promise<Response> => {
  try {
    const incoming = String(req.body.email || '');
    const email = normEmail(incoming);
    const { password } = req.body;

    if (!email || !password) {
      return errorResponse(res, 'Email and password are required', 400);
    }

    const userSnap = await getByEmail(USERS_COL, email);
    console.log('[login] users query completed. empty =', !userSnap || userSnap.empty);

    if (userSnap && !userSnap.empty) {
      const doc = userSnap.docs[0];
      const user: any = doc.data();

      const companyId = String(user.companyId || '').trim() || null;

      if (!companyId) {
        return errorResponse(res, 'companyId missing on user account', 403);
      }

      const storedHash =
        user.password || user.passwordHash || user.hashedPassword || '';

      let match = false;

      if (storedHash) {
        try {
          match = await bcrypt.compare(password, storedHash);
        } catch {}
      }

      if (!match) {
        const ok = await verifyWithFirebase(email, password);
        if (!ok) {
          return errorResponse(res, 'Invalid email or password', 401);
        }

        try {
          await rotatePassword({
            db: getDb(),
            userId: doc.id,
            oldHash: storedHash || null,
            newPlainPassword: password,
            source: 'firebase_reset',
            keepLast: 5,
          });
        } catch (e) {
          console.warn('Password rotate failed:', e instanceof Error ? e.name : 'Unknown');
        }

        match = true;
      }

      if (user.status && user.status !== 'active') {
        return errorResponse(res, 'Account is not active', 403);
      }

      const role = String(user.role || 'employee').toLowerCase();
      if (!LOGIN_ROLES.has(role)) {
        return errorResponse(res, 'Invalid role on account', 403);
      }

      let userEmpid = pickEmpId(user);
      if (!userEmpid) {
        const empQ = await getDb()
          .collection(EMPS_COL)
          .where('emailLower', '==', email)
          .limit(1)
          .get();

        if (!empQ.empty) {
          userEmpid = pickEmpId(empQ.docs[0].data());
          if (userEmpid) {
            await doc.ref.set(
              { empid: userEmpid, empId: userEmpid, updatedAt: new Date() },
              { merge: true }
            );
          }
        }
      }

      const token = issueToken({
        userId: doc.id,
        email: user.email || incoming.trim(),
        role,
        empid: userEmpid || null,
        companyId,
      });

      return successResponse(
        res,
        {
          token,
          tokenType: 'Bearer',
          expiresIn: JWT_EXPIRES,
          role,
          uid: doc.id,
          empid: userEmpid || null,
          companyId,
          name: user.name || user.fullName || '',
          user: {
            id: doc.id,
            name: user.name || user.fullName || '',
            email: user.email || incoming.trim(),
            role,
            empid: userEmpid || null,
            empId: userEmpid || null,
            companyId,
            status: user.status || 'active',
          },
        },
        'Login successful'
      );
    }

    console.log('[login] checking employees fallback');
    const empSnap = await getByEmail(EMPS_COL, email);
    if (!empSnap || empSnap.empty) {
      return errorResponse(res, 'Invalid email or password', 401);
    }

    const empDoc = empSnap.docs[0];
    const emp: any = empDoc.data();
    const employeeCompanyId = String(emp.companyId || '').trim() || null;

    if (!employeeCompanyId) {
      return errorResponse(res, 'companyId missing on employee record', 403);
    }

    const stored = emp.password || '';
    let passOK = false;

    if (stored) {
      passOK = isBcryptHash(stored)
        ? await bcrypt.compare(password, stored)
        : stored === password;
    }

    if (!passOK) {
      const ok = await verifyWithFirebase(email, password);
      if (!ok) {
        return errorResponse(res, 'Invalid email or password', 401);
      }
    }

    if (emp.status && emp.status !== 'active') {
      return errorResponse(res, 'Account is not active', 403);
    }

    let mirror = await getByEmail(USERS_COL, email);
    let mirrorDoc: DocumentSnapshot | null = null;

    if (mirror && !mirror.empty) {
      const existingMirrorDoc = mirror.docs[0];
      const mirrorData = existingMirrorDoc.data() as any;

      if (!mirrorData.companyId && employeeCompanyId) {
        await existingMirrorDoc.ref.set(
          { companyId: employeeCompanyId, updatedAt: new Date() },
          { merge: true }
        );
      }

      if (!passOK) {
        try {
          const prev =
            (existingMirrorDoc.get('password') ||
              existingMirrorDoc.get('passwordHash') ||
              existingMirrorDoc.get('hashedPassword') ||
              null) as string | null;

          await rotatePassword({
            db: getDb(),
            userId: existingMirrorDoc.id,
            oldHash: prev,
            newPlainPassword: password,
            source: 'firebase_reset',
            keepLast: 5,
          });
        } catch (e) {
          console.warn('rotatePassword failed (EMPLOYEES existing mirror):', e);
        }
      }

      mirrorDoc = existingMirrorDoc;
    } else {
      const hash = isBcryptHash(stored) ? stored : await bcrypt.hash(password, 10);
      const now = new Date();
      const empIdVal = pickEmpId(emp);

      const ref = await getDb().collection(USERS_COL).add({
        empid: empIdVal || null,
        empId: empIdVal || null,
        name: emp.name || emp.fullName || '',
        email: emp.email || incoming.trim(),
        emailLower: email,
        password: hash,
        passwordHash: hash,
        hashedPassword: hash,
        role: 'employee',
        status: 'active',
        companyId: employeeCompanyId,
        createdAt: now,
        updatedAt: now,
        authSource: !passOK ? 'firebase' : 'local',
      });

      mirrorDoc = await ref.get();
    }

    if (!mirrorDoc) {
      return errorResponse(res, 'Failed to create or load employee login account', 500);
    }
    

    const u = mirrorDoc.data() as any;
    const finalEmpid = pickEmpId(u) || pickEmpId(emp);
    const finalCompanyId =
      String(u.companyId || employeeCompanyId || '').trim() || null;

    if (!finalCompanyId) {
      return errorResponse(res, 'companyId missing on employee login account', 403);
    }

    const token = issueToken({
      userId: mirrorDoc.id,
      email: u.email || incoming.trim(),
      role: 'employee',
      empid: finalEmpid || null,
      companyId: finalCompanyId,
    });

    return successResponse(
      res,
      {
        token,
        tokenType: 'Bearer',
        expiresIn: JWT_EXPIRES,
        role: 'employee',
        uid: mirrorDoc.id,
        empid: finalEmpid || null,
        companyId: finalCompanyId,
        name: u.name || emp.name || '',
        user: {
          id: mirrorDoc.id,
          name: u.name || emp.name || '',
          email: u.email || incoming.trim(),
          role: 'employee',
          empid: finalEmpid || null,
          empId: finalEmpid || null,
          companyId: finalCompanyId,
          status: u.status || emp.status || 'active',
        },
      },
      'Login successful'
    );
  } catch (error: any) {
    console.error('Login error full:', error);
    console.error('Login error message:', error?.message);
    console.error('Login error stack:', error?.stack);

    return errorResponse(
      res,
      error?.message || 'Failed to login',
      500
    );
  }
};

// GET /api/auth/me
export const getMe = async (req: Request, res: Response): Promise<Response> => {
  try {
    const userId = (req as any).user?.userId;
    const email = normEmail((req as any).user?.email || '');

    if (!userId && !email) {
      return errorResponse(res, 'Unauthorized', 401);
    }

    // One-time Firestore connectivity check
    await checkFirestoreAccess();

    let doc: DocumentSnapshot | null = null;

    if (userId) {
      console.log(`[FIRESTORE ACCESS] collection=users, docId=${String(userId).substring(0, 12)}...`);
      const d = await getDb().collection(USERS_COL).doc(userId).get();
      if (d.exists) doc = d;
    }

    if (!doc && email) {
      console.log(`[FIRESTORE ACCESS] collection=users, query by email`);
      const q = await getDb()
        .collection(USERS_COL)
        .where('emailLower', '==', email)
        .limit(1)
        .get();
      if (!q.empty) doc = q.docs[0];
    }

    if (doc) {
      const user = sanitizeUser(doc.id, doc.data());
      const eid =
        (user as any).empid ??
        (user as any).empId ??
        (user as any).employeeId ??
        null;

      if (eid && !(user as any).empid) (user as any).empid = eid;
      if (eid && !(user as any).empId) (user as any).empId = eid;

      if ((user as any).empid) {
        const empSnap = await getDb()
          .collection(EMPS_COL)
          .where('empid', '==', (user as any).empid)
          .limit(1)
          .get();

        if (!empSnap.empty) {
          const emp = empSnap.docs[0].data();
          delete (emp as any).password;
          (user as any).employeeProfile = emp;
        }
      }

      return successResponse(res, user, 'User profile fetched');
    }

    if (email) {
      const empSnap = await getDb()
        .collection(EMPS_COL)
        .where('emailLower', '==', email)
        .limit(1)
        .get();

      if (!empSnap.empty) {
        const eDoc = empSnap.docs[0];
        const emp = eDoc.data() as any;
        delete emp.password;
        const eid = pickEmpId(emp);
        const employeeCompanyId = String(emp.companyId || '').trim() || null;

        return successResponse(
          res,
          {
            id: eDoc.id,
            email,
            role: 'employee',
            empid: eid || null,
            empId: eid || null,
            companyId: employeeCompanyId,
            name: emp.name || emp.fullName || '',
            employeeProfile: emp,
          },
          'User profile fetched'
        );
      }
    }

    return errorResponse(res, 'User not found', 404);
  } catch (err: any) {
    const code = err?.code || 'unknown';
    const message = err?.message || 'Internal server error';

    // Firestore permission errors are controlled – return a clear message
    // instead of an unhandled internal failure.
    if (code === 7 || message.includes('PERMISSION_DENIED')) {
      console.error(
        `[getMe] Firestore access denied: code=${code}, message=${message}`
      );
      return errorResponse(
        res,
        'Database access error. Please contact support if this persists.',
        503
      );
    }

    console.error('getMe error:', err);
    return errorResponse(res, 'Internal server error', 500);
  }
};

// POST /api/auth/change-password  { newPassword }
export const changePassword = async (req: Request, res: Response): Promise<Response> => {
  try {
    const userId = (req as any).user?.userId;
    const tokenEmail = normEmail((req as any).user?.email || '');
    const newPassword = String(req.body?.newPassword || '').trim();

    if (!userId || !newPassword) {
      return errorResponse(res, 'newPassword and token are required', 400);
    }

    if (newPassword.length < 8) {
      return errorResponse(res, 'Password must be at least 8 characters', 400);
    }

    const userDoc = await getDb().collection(USERS_COL).doc(userId).get();
    if (!userDoc.exists) {
      return errorResponse(res, 'User not found', 404);
    }

    const user = userDoc.data() as any;
    const emailLower = normEmail(user.emailLower || user.email || tokenEmail);

    if (!emailLower) {
      return errorResponse(res, 'Account email missing on user document', 500);
    }

    try {
      const fbUser = await getAdminAuth().getUserByEmail(emailLower);
      await getAdminAuth().updateUser(fbUser.uid, { password: newPassword });
    } catch (e) {
      console.warn('Firebase Auth update by email failed:', e);
      return errorResponse(res, 'Failed to update password in Firebase Auth', 500);
    }

    const prevHash =
      user.password || user.passwordHash || user.hashedPassword || null;

    await rotatePassword({
      db: getDb(),
      userId,
      oldHash: prevHash,
      newPlainPassword: newPassword,
      source: 'self_change',
      keepLast: 5,
    });

    await userDoc.ref.set(
      { authSource: 'local', mustChangePassword: false, updatedAt: new Date() },
      { merge: true }
    );

    return successResponse(res, null, 'Password changed successfully');
  } catch (err) {
    console.error('changePassword error:', err);
    return errorResponse(res, 'Internal server error', 500);
  }
};

// POST /api/auth/admin/create-employee-login  { empid, email?, password? }
export const createEmployeeLogin = async (
  req: Request,
  res: Response
): Promise<Response> => {
  try {
    let { empid, email, password } = req.body || {};
    empid = String(empid || '').trim();
    email = normEmail(email || '');

    if (!empid) {
      return errorResponse(res, 'empid is required', 400);
    }

    const empQ = await getDb()
      .collection(EMPS_COL)
      .where('empid', '==', empid)
      .limit(1)
      .get();

    if (empQ.empty) {
      return errorResponse(res, 'Employee not found', 404);
    }

    const emp = empQ.docs[0].data() as any;
    const companyId = String(emp.companyId || '').trim();

    if (!companyId) {
      return errorResponse(res, 'companyId missing on employee record', 400);
    }

    const name = String(emp.name || emp.fullName || '').trim();

    if (!email) email = normEmail(emp.email || '');
    if (!email) {
      return errorResponse(res, 'email is required (not found on employee record)', 400);
    }

    const existsByEmail = await getDb()
      .collection(USERS_COL)
      .where('emailLower', '==', email)
      .limit(1)
      .get();

    if (!existsByEmail.empty) {
      return errorResponse(res, 'Login already exists for this email', 409);
    }

    const existsByEmpid = await getDb()
      .collection(USERS_COL)
      .where('empid', '==', empid)
      .limit(1)
      .get();

    if (!existsByEmpid.empty) {
      return errorResponse(res, 'Login already exists for this empid', 409);
    }

    const tempPassword = `${empid}@123`;
    const finalPassword = String(password || tempPassword);
    const hash = await bcrypt.hash(finalPassword, 10);
    const now = new Date();

    const docRef = await getDb().collection(USERS_COL).add({
      empid,
      empId: empid,
      name,
      email,
      emailLower: email,
      password: hash,
      passwordHash: hash,
      hashedPassword: hash,
      role: 'employee',
      status: 'active',
      companyId,
      mustChangePassword: !password,
      createdAt: now,
      updatedAt: now,
    });

    return successResponse(
      res,
      {
        userId: docRef.id,
        tempPassword: !password ? tempPassword : undefined,
      },
      'Login enabled for employee'
    );
  } catch (err) {
    console.error('createEmployeeLogin error:', err);
    return errorResponse(res, 'Internal server error', 500);
  }
};

// POST /api/auth/admin/backfill-employee-logins
export const backfillEmployeesToUsers = async (
  req: Request,
  res: Response
): Promise<Response> => {
  try {
    const empSnap = await getDb().collection(EMPS_COL).get();
    const created: any[] = [];
    const updatedEmp: any[] = [];

    for (const d of empSnap.docs) {
      const e = d.data() as any;
      const empidRaw = pickEmpId(e);
      const empid = empidRaw ? String(empidRaw) : '';
      const emailLower = normEmail(e.email || '');
      const name = String(e.name || e.fullName || '').trim();
      const companyId = String(e.companyId || '').trim();

      if (!empid || !emailLower) {
        await d.ref.set({ emailLower }, { merge: true });
        continue;
      }

      if (!companyId) {
        await d.ref.set({ emailLower }, { merge: true });
        continue;
      }

      if (!e.emailLower || e.emailLower !== emailLower) {
        await d.ref.set({ emailLower }, { merge: true });
        updatedEmp.push({ empid, emailLower });
      }

      const exists = await getDb()
        .collection(USERS_COL)
        .where('emailLower', '==', emailLower)
        .limit(1)
        .get();

      if (!exists.empty) continue;

      const existsEmp = await getDb()
        .collection(USERS_COL)
        .where('empid', '==', empid)
        .limit(1)
        .get();

      if (!existsEmp.empty) continue;

      const temp = `${empid}@123`;
      const hash = await bcrypt.hash(temp, 10);
      const now = new Date();

      const ref = await getDb().collection(USERS_COL).add({
        empid,
        empId: empid,
        name,
        email: e.email || emailLower,
        emailLower,
        password: hash,
        passwordHash: hash,
        hashedPassword: hash,
        role: 'employee',
        status: 'active',
        companyId,
        mustChangePassword: true,
        createdAt: now,
        updatedAt: now,
      });

      created.push({
        userId: ref.id,
        empid,
        email: e.email || emailLower,
        tempPassword: temp,
      });
    }

    return successResponse(
      res,
      {
        createdCount: created.length,
        normalizedEmployees: updatedEmp.length,
        created,
      },
      'Backfill complete'
    );
  } catch (error: any) {
    console.error('backfillEmployeesToUsers error full:', error);
    console.error('backfillEmployeesToUsers error message:', error?.message);
    console.error('backfillEmployeesToUsers error stack:', error?.stack);

    return errorResponse(
      res,
      error?.message || 'Failed to backfill employees',
      500
    );
  }
};

// POST /api/auth/forgot-password/request-link  { email }
export const requestPasswordResetLink = async (
  req: Request,
  res: Response
): Promise<Response> => {
  try {
    const email = normEmail(req.body.email || '');
    if (!email) {
      return errorResponse(res, 'Email is required', 400);
    }

    const userDoc = await getUserDocByEmailAny(email);
    if (!userDoc) {
      const empQ = await getDb()
        .collection(EMPS_COL)
        .where('emailLower', '==', email)
        .limit(1)
        .get();

      if (empQ.empty) {
        return errorResponse(res, 'User not found', 404);
      }
    }

    const link = await getAdminAuth().generatePasswordResetLink(email, {
      url: getResetContinueUrl(),
      handleCodeInApp: true,
    });

    if (mailer) {
      const from =
        process.env.SMTP_FROM || `SERV App <${process.env.SMTP_USER}>`;

      await mailer.sendMail({
        from,
        to: email,
        subject: 'Reset your SERV password',
        html: `
          <p>Hello,</p>
          <p>Follow this link to reset your SERV password for <b>${email}</b>:</p>
          <p><a href="${link}">Reset your password</a></p>
          <p>If you didn’t ask to reset your password, you can ignore this email.</p>
          <p>Thanks,<br/>Your SERV team</p>
        `,
        text: `Reset your password: ${link}`,
      });

      return successResponse(res, null, 'Reset email sent');
    }

    return successResponse(
      res,
      { link },
      'Mailer not configured; use link directly'
    );
  } catch (err: any) {
    console.error('requestPasswordResetLink error:', err);
    return errorResponse(res, err.message || 'Internal server error', 500);
  }
};

// POST /api/auth/forgot-password { email, newPassword }
export const forgotPassword = async (
  req: Request,
  res: Response
): Promise<Response> => {
  if (!req.body?.email || !req.body?.newPassword) {
    return errorResponse(
      res,
      'Provide email and newPassword or use /forgot-password/request-link.',
      400
    );
  }

  return changePassword(req, res);
};

// Simple profile endpoints
export const getProfile = async (
  req: Request & { user?: { userId: string } },
  res: Response
) => getMe(req as any, res);

export const updateProfile = async (
  _req: Request & { user?: { userId: string } },
  res: Response
) => successResponse(res, null, 'Profile updated successfully');

export const createPrivilegedUser = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const { name, email, password, role, companyId } = req.body || {};

    const userName = String(name || '').trim();
    const userEmail = normEmail(email || '');
    const userPassword = String(password || '');
    const userRole = String(role || '').trim().toLowerCase();
    const userCompanyId = String(companyId || '').trim();

    if (!userName || !userEmail || !userPassword || !userCompanyId) {
      return errorResponse(res, 'Name, email, password and companyId are required', 400);
    }

    if (
      userRole !== 'employee' &&
      userRole !== 'admin' &&
      userRole !== 'super_admin'
    ) {
      return errorResponse(res, 'Invalid role', 400);
    }

    const caller = (req as any).user;
    const callerRole = String(caller?.role || '').toLowerCase();
    const callerCompanyId = String(caller?.companyId || '').trim();

    if (callerRole !== 'admin' && callerRole !== 'super_admin') {
      return errorResponse(res, 'Not authorized', 403);
    }

    if (!callerCompanyId || callerCompanyId !== userCompanyId) {
      return errorResponse(res, 'Company context mismatch', 403);
    }

    if (userRole === 'super_admin' && callerRole !== 'admin' && callerRole !== 'super_admin') {
      return errorResponse(res, 'Not authorized to create super_admin', 403);
    }

    const byEmail = await getByEmail(USERS_COL, userEmail);
    if (byEmail && !byEmail.empty) {
      return errorResponse(res, 'Email is already in use', 400);
    }

    const hash = await bcrypt.hash(userPassword, 10);
    const now = new Date();
    const userId = uuidv4();

    await getDb().collection(USERS_COL).doc(userId).set({
      empid: null,
      empId: null,
      name: userName,
      email: userEmail,
      emailLower: userEmail,
      password: hash,
      passwordHash: hash,
      hashedPassword: hash,
      role: userRole,
      status: 'active',
      companyId: userCompanyId,
      createdAt: now,
      updatedAt: now,
    });

    return successResponse(
      res,
      {
        id: userId,
        name: userName,
        email: userEmail,
        role: userRole,
        companyId: userCompanyId,
        status: 'active',
      },
      'Privileged user created',
    );
  } catch (error: any) {
    console.error('createPrivilegedUser error:', error);
    return errorResponse(
      res,
      error?.message || 'Failed to create user',
      500,
    );
  }
};

// ── Employee organization validation helpers ─────────────────────────────────

/**
 * Validates an organization code + employee email without receiving a password.
 * Used by the Flutter employee login flow to confirm the employee is eligible to
 * authenticate before invoking Firebase Authentication.
 */
export const employeeLoginValidate = async (
  req: Request,
  res: Response
): Promise<Response> => {
  try {
    const organizationCode = normalizeOrgCode(req.body?.organizationCode);
    const email = normEmail(req.body?.email);

    if (!organizationCode || !email) {
      return errorResponse(
        res,
        'Organization code and email are required',
        400,
      );
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return errorResponse(res, 'Enter a valid email address', 400);
    }

    const companySnap = await getCompanyProfileByCode(organizationCode);
    if (!companySnap) {
      return errorResponse(res, 'Invalid organization or email', 401);
    }

    const company = companySnap.data() || {};
    const companyStatus = String(company.status || 'active').trim().toLowerCase();
    if (companyStatus !== 'active') {
      return errorResponse(res, 'Invalid organization or email', 401);
    }

    const companyId = String(companySnap.id).trim();

    const userSnap = await getByEmail(USERS_COL, email);
    let user: any = null;

    if (userSnap && !userSnap.empty) {
      user = userSnap.docs[0].data();
    } else {
      const empSnap = await getByEmail(EMPS_COL, email);
      if (empSnap && !empSnap.empty) {
        user = empSnap.docs[0].data();
      }
    }

    if (!user) {
      return errorResponse(res, 'Invalid organization or email', 401);
    }

    const role = String(user.role || '').trim().toLowerCase();
    if (role !== 'employee') {
      return errorResponse(res, 'Invalid organization or email', 401);
    }

    const status = String(user.status || 'active').trim().toLowerCase();
    if (status !== 'active') {
      return errorResponse(res, 'Invalid organization or email', 401);
    }

    const userCompanyId = String(user.companyId || '').trim();
    if (!userCompanyId || userCompanyId !== companyId) {
      return errorResponse(res, 'Invalid organization or email', 401);
    }

    return successResponse(
      res,
      {
        email: user.email || email,
        companyId,
        organizationCode,
        canProceed: true,
      },
      'Employee validated successfully',
    );
  } catch (error: any) {
    console.error('employeeLoginValidate error:', error);
    return errorResponse(res, 'Internal server error', 500);
  }
};

/**
 * Validates organization constraints for the employee login context.
 * Called after a user/employee record has been located and before a JWT is
 * issued. Enforces: organization code exists, organization is active, user is
 * an employee, user account is active, user's companyId matches the code.
 */
async function validateEmployeeOrganization(
  req: Request,
  userCompanyId: string,
  userRole: string,
  userStatus: string
): Promise<{ ok: true } | { ok: false; message: string }> {
  const loginContext = String(req.body?.loginContext || '').trim().toLowerCase();
  const organizationCode = normalizeOrgCode(req.body?.organizationCode);

  if (loginContext !== 'employee' || !organizationCode) {
    return { ok: true };
  }

  const companySnap = await getCompanyProfileByCode(organizationCode);
  if (!companySnap) {
    return { ok: false, message: 'Invalid organization or email' };
  }

  const company: any = companySnap.data() || {};
  const status = String(company.status || 'active').trim().toLowerCase();
  if (status !== 'active') {
    return { ok: false, message: 'Invalid organization or email' };
  }

  const codeCompanyId = String(companySnap.id).trim();
  if (!codeCompanyId || codeCompanyId !== userCompanyId.trim()) {
    return { ok: false, message: 'Invalid organization or email' };
  }

  if (userRole !== 'employee') {
    return { ok: false, message: 'Invalid organization or email' };
  }

  if (userStatus !== 'active') {
    return { ok: false, message: 'Invalid organization or email' };
  }

  return { ok: true };
}

export const firebaseLogin = async (
  req: Request,
  res: Response
): Promise<Response> => {
  try {
    console.log('FIREBASE LOGIN START');

    const authHeader = String(req.headers.authorization || '');
    const idToken = authHeader.startsWith('Bearer ')
      ? authHeader.slice(7).trim()
      : String(req.body.idToken || '');

    if (!idToken) {
      console.warn('FIREBASE LOGIN: no ID token provided');
      return errorResponse(res, 'Firebase ID token required', 400);
    }

    // Safe token diagnostics – never log the full token
    console.log(
      `[FIREBASE LOGIN] token received: length=${idToken.length}, ` +
        `prefix=${idToken.substring(0, 20)}..., ` +
        `source=${authHeader.startsWith('Bearer ') ? 'Authorization header' : 'body'}`
    );

    let decoded: any;
    try {
      decoded = await getAdminAuth().verifyIdToken(idToken);
      console.log(
        `[FIREBASE TOKEN VERIFIED] aud=${decoded.aud}, ` +
          `email=${decoded.email || 'N/A'}, uid=${decoded.uid || 'N/A'}`
      );
    } catch (e: any) {
      console.warn(
        `[FIREBASE TOKEN VERIFY FAILED] code=${e.code || 'unknown'}, ` +
          `message=${e.message || 'N/A'}`
      );
      return errorResponse(res, 'Invalid or expired Firebase token', 401);
    }

    const email = normEmail(decoded.email || '');
    if (!email) {
      return errorResponse(res, 'Firebase token does not contain an email', 401);
    }

    // One-time Firestore connectivity check
    await checkFirestoreAccess();

    const userSnap = await getByEmail(USERS_COL, email);

    if (userSnap && !userSnap.empty) {
      const doc = userSnap.docs[0];
      const user: any = doc.data();

      const companyId = String(user.companyId || '').trim() || null;
      if (!companyId) {
        return errorResponse(res, 'companyId missing on user account', 403);
      }

      if (user.status && user.status !== 'active') {
        return errorResponse(res, 'Account is not active', 403);
      }

      const role = String(user.role || 'employee').toLowerCase();
      if (!LOGIN_ROLES.has(role)) {
        return errorResponse(res, 'Invalid role on account', 403);
      }

      const orgValidation = await validateEmployeeOrganization(
        req,
        companyId,
        role,
        user.status || 'active',
      );
      if (!orgValidation.ok) {
        return errorResponse(res, orgValidation.message, 401);
      }

      let userEmpid = pickEmpId(user);
      if (!userEmpid) {
        const empQ = await getDb()
          .collection(EMPS_COL)
          .where('emailLower', '==', email)
          .limit(1)
          .get();

        if (!empQ.empty) {
          userEmpid = pickEmpId(empQ.docs[0].data());
          if (userEmpid) {
            await doc.ref.set(
              { empid: userEmpid, empId: userEmpid, updatedAt: new Date() },
              { merge: true }
            );
          }
        }
      }

      await doc.ref.set(
        {
          authSource: 'firebase',
          lastFirebaseAuthAt: new Date(),
          updatedAt: new Date(),
        },
        { merge: true }
      );

      const token = issueToken({
        userId: doc.id,
        email: user.email || email,
        role,
        empid: userEmpid || null,
        companyId,
      });

      console.log('SERV USER FOUND');
      console.log('SERV JWT ISSUED');
      console.log('FIREBASE LOGIN SUCCESS');

      return successResponse(
        res,
        {
          token,
          tokenType: 'Bearer',
          expiresIn: JWT_EXPIRES,
          role,
          uid: doc.id,
          empid: userEmpid || null,
          companyId,
          name: user.name || user.fullName || '',
          user: {
            id: doc.id,
            name: user.name || user.fullName || '',
            email: user.email || email,
            role,
            empid: userEmpid || null,
            empId: userEmpid || null,
            companyId,
            status: user.status || 'active',
          },
        },
        'Login successful'
      );
    }

    console.log('checking employees fallback');
    const empSnap = await getByEmail(EMPS_COL, email);
    if (!empSnap || empSnap.empty) {
      return errorResponse(res, 'Invalid email or password', 401);
    }

    const empDoc = empSnap.docs[0];
    const emp: any = empDoc.data();
    const employeeCompanyId = String(emp.companyId || '').trim() || null;

    if (!employeeCompanyId) {
      return errorResponse(res, 'companyId missing on employee record', 403);
    }

    if (emp.status && emp.status !== 'active') {
      return errorResponse(res, 'Account is not active', 403);
    }

    const orgValidation = await validateEmployeeOrganization(
      req,
      employeeCompanyId,
      'employee',
      emp.status || 'active',
    );
    if (!orgValidation.ok) {
      return errorResponse(res, orgValidation.message, 401);
    }

    const empIdVal = pickEmpId(emp);
    const finalEmpid = empIdVal || null;
    const finalCompanyId = employeeCompanyId;
    const name = String(emp.name || emp.fullName || '').trim();
    const now = new Date();

    const ref = await getDb().collection(USERS_COL).add({
      empid: finalEmpid,
      empId: finalEmpid,
      name,
      email,
      emailLower: email,
      role: 'employee',
      status: 'active',
      companyId: finalCompanyId,
      authSource: 'firebase',
      lastFirebaseAuthAt: now,
      createdAt: now,
      updatedAt: now,
    });

    const token = issueToken({
      userId: ref.id,
      email,
      role: 'employee',
      empid: finalEmpid,
      companyId: finalCompanyId,
    });

    console.log('SERV USER FOUND (employees fallback)');
    console.log('SERV JWT ISSUED');
    console.log('FIREBASE LOGIN SUCCESS');

    return successResponse(
      res,
      {
        token,
        tokenType: 'Bearer',
        expiresIn: JWT_EXPIRES,
        role: 'employee',
        uid: ref.id,
        empid: finalEmpid,
        companyId: finalCompanyId,
        name,
        user: {
          id: ref.id,
          name,
          email,
          role: 'employee',
          empid: finalEmpid,
          empId: finalEmpid,
          companyId: finalCompanyId,
          status: 'active',
        },
      },
      'Login successful'
    );
  } catch (error: any) {
    const errCode = error?.code || 'unknown';
    const errMsg = error?.message || 'Internal server error';

    // Firestore permission errors – controlled 503
    if (errCode === 7 || errMsg.includes('PERMISSION_DENIED')) {
      console.error(
        `[FIREBASE LOGIN FAILED] Firestore access denied: code=${errCode}, message=${errMsg}`
      );
      return errorResponse(
        res,
        'Database access error. Please contact support if this persists.',
        503
      );
    }

    console.error('FIREBASE LOGIN FAILED:', error?.message || error);
    return errorResponse(res, 'Internal server error', 500);
  }
};

export const resetPassword = async () => {
  /* unused */
};

/**
 * POST /auth/register-applicant — Firebase-Auth-backed self-registration
 * for organization applicants (3D-C follow-up).
 *
 * The caller first signs in / creates an account via Firebase Auth on the
 * client, then sends the Firebase ID token here. The server:
 *   1. verifies the ID token (identity is NEVER taken from the body);
 *   2. looks up the SERV users doc by email;
 *      - existing org_applicant -> re-issue JWT (idempotent);
 *      - existing other role    -> 409 (prevents account takeover);
 *   3. creates users/{firebaseUid} with role=org_applicant and the
 *      'platform' sentinel companyId — required non-empty by firebaseLogin,
 *      but grants NO organization/admin access;
 *   4. issues a SERV JWT scoped to role=org_applicant.
 *
 * No organization, company, or admin account is created here.
 */
export const registerApplicant = async (
  req: Request,
  res: Response
): Promise<Response | void> => {
  try {
    if (!checkFirestoreAccess()) {
      return errorResponse(res, 'Database unavailable', 503);
    }
    const idToken = String(req.body?.idToken || '').trim();
    if (!idToken) {
      return errorResponse(res, 'idToken is required', 400);
    }

    let decoded: any;
    try {
      decoded = await getAdminAuth().verifyIdToken(idToken);
    } catch (err: any) {
      console.warn('[register-applicant] invalid idToken', {
        code: err?.code || 'unknown',
      });
      return errorResponse(res, 'Invalid Firebase credential', 401);
    }

    const emailLower = normEmail(decoded.email || '');
    if (!emailLower) {
      return errorResponse(
        res,
        'Email authentication is required for organization registration',
        400
      );
    }
    const firebaseUid = String(decoded.uid || '');

    let snap = await getByEmail(USERS_COL, emailLower);
    if (snap && !snap.empty) {
      const doc = snap.docs[0];
      const user: any = doc.data();
      const role = String(user.role || '').toLowerCase();
      if (role !== 'org_applicant') {
        return errorResponse(
          res,
          'An account with this email already exists with a different role. Please sign in instead.',
          409
        );
      }
      if (String(user.status || '').toLowerCase() !== 'active') {
        return errorResponse(res, 'Account is not active', 403);
      }
      const token = issueToken({
        userId: doc.id,
        email: user.email || emailLower,
        role: 'org_applicant',
        empid: user.empid || null,
        companyId: String(user.companyId || 'platform'),
      });
      return successResponse(
        res,
        {
          token,
          tokenType: 'Bearer',
          expiresIn: JWT_EXPIRES,
          role: 'org_applicant',
          uid: doc.id,
          companyId: String(user.companyId || 'platform'),
          name: user.name || user.fullName || '',
          user: {
            id: doc.id,
            name: user.name || user.fullName || '',
            email: user.email || emailLower,
            role: 'org_applicant',
            companyId: String(user.companyId || 'platform'),
            status: user.status || 'active',
          },
        },
        'Applicant session restored'
      );
    }

    // New applicant — create the restricted users document.
    const displayName = String(
      decoded.name || emailLower.split('@')[0]
    ).trim();
    const docRef = getDb().collection(USERS_COL).doc(firebaseUid);
    await docRef.set({
      email: emailLower,
      emailLower,
      name: displayName,
      fullName: displayName,
      role: 'org_applicant',
      status: 'active',
      companyId: 'platform',
      authSource: 'firebase',
      applicantAuthUid: firebaseUid,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    snap = null;

    const token = issueToken({
      userId: firebaseUid,
      email: emailLower,
      role: 'org_applicant',
      empid: null,
      companyId: 'platform',
    });
    return successResponse(
      res,
      {
        token,
        tokenType: 'Bearer',
        expiresIn: JWT_EXPIRES,
        role: 'org_applicant',
        uid: firebaseUid,
        companyId: 'platform',
        name: displayName,
        user: {
          id: firebaseUid,
          name: displayName,
          email: emailLower,
          role: 'org_applicant',
          companyId: 'platform',
          status: 'active',
        },
      },
      'Applicant account created',
      201
    );
  } catch (error: any) {
    console.error('REGISTER APPLICANT FAILED:', error?.message || error);
    return errorResponse(res, 'Internal server error', 500);
  }
};