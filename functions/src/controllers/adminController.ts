// functions/src/controllers/adminController.ts
import { Request, Response } from "express";
import bcrypt from "bcryptjs";
import * as crypto from "crypto";
import { v4 as uuidv4 } from "uuid";
import { auth, db } from '../config/firebase';
import { trackUsage } from '../services/usageService';
import { checkUserLimit } from '../services/entitlementService';
import { normEmail } from '../common/utils';
const USERS = "users"; // ← change if your collection name is different

/* ============================== Usage Tracking Helper ============================== */

async function trackAdminUsage(
  req: Request,
  updates: Record<string, number>
) {
  try {
    const user = (req as any).user;
    await trackUsage({
      companyId: user?.companyId || '',
      companyName: user?.companyName || '',
      plan: user?.plan || '',
      updates,
    });
  } catch (trackingError) {
    console.error('Usage tracking failed in admin:', trackingError);
  }
}

// POST /api/admin/create
// body: { email, password, name? }
// Creates an additional admin bound to the CALLER's company — never an
// unscoped/company-less admin. Tenant limits are enforced.
export async function createAdmin(req: Request, res: Response) {
  try {
    const { email, password, name = "" } = req.body || {};
    if (!email || !password) {
      return res.status(400).json({ error: "email and password are required" });
    }

    const caller = (req as any).user;
    const companyId = String(caller?.companyId || '').trim();
    if (!companyId) {
      return res.status(403).json({ error: "No company context on token" });
    }

    // Company must exist, be active, and be under its maxUsers cap
    // (fail closed on lookup errors / unknown companies).
    const limit = await checkUserLimit(companyId);
    if (limit.lookupFailed) {
      return res.status(503).json({ error: "Could not verify company entitlements. Please try again." });
    }
    if (!limit.companyExists) {
      return res.status(403).json({ error: "Unknown company" });
    }
    if (!limit.allowed) {
      return res.status(403).json({
        error: limit.companyStatus !== 'active'
          ? "This company account is not active."
          : "Maximum user limit reached for this company.",
      });
    }

    // check duplicate
    const emailLower = email.toLowerCase();
    const snap = await db.collection(USERS).where("email", "==", emailLower).limit(1).get();
    if (!snap.empty) {
      return res.status(409).json({ error: "user already exists" });
    }

    const hash = await bcrypt.hash(password, 10);
    const doc = {
      email: emailLower,
      emailLower,
      password: hash,
      name,
      role: "admin",
      status: "active",
      companyId,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    const ref = await db.collection(USERS).add(doc);

    // Track usage after successful admin creation
    await trackAdminUsage(req, {
      writeCount: 1,
      apiCalls: 1,
    });

    return res.status(201).json({ id: ref.id, ...doc });
  } catch (e: any) {
    return res.status(500).json({ error: e.message || "failed to create admin" });
  }
}

// POST /api/admin/promote
// body: { email }  -> sets role = "admin"
export async function promoteToAdmin(req: Request, res: Response) {
  try {
    const { email } = req.body || {};
    if (!email) return res.status(400).json({ error: "email is required" });

    const q = await db.collection(USERS).where("email", "==", email.toLowerCase()).limit(1).get();
    if (q.empty) return res.status(404).json({ error: "user not found" });

    const docRef = q.docs[0].ref;
    await docRef.update({ role: "admin", updatedAt: new Date().toISOString() });

    // Track usage after successful admin promotion
    await trackAdminUsage(req, {
      writeCount: 1,
      apiCalls: 1,
    });

    return res.json({ ok: true });
  } catch (e: any) {
    return res.status(500).json({ error: e.message || "failed to promote user" });
  }
}

// POST /api/admin/hr-users
// body: { name, email, password?, phone?, branch, branchId?, department, departmentId? }
// Creates an HR user bound to the CALLER's company. HR users are tenant users
// (role 'hr') — they never receive company-admin or platform-admin
// privileges. Tenant maxUsers limit is enforced (fail closed).
export async function createHrUser(req: Request, res: Response) {
  try {
    const caller = (req as any).user;
    const companyId = String(caller?.companyId || '').trim();
    if (!companyId) {
      return res.status(403).json({ error: "No company context on token" });
    }

    const name = String(req.body?.name || '').trim();
    const email = normEmail(req.body?.email || '');
    const phone = String(req.body?.phone || '').trim();
    const branch = String(req.body?.branch ?? req.body?.branchName ?? '').trim();
    const branchId = String(req.body?.branchId || '').trim();
    const department = String(
      req.body?.department ?? req.body?.departmentName ?? ''
    ).trim();
    const departmentId = String(req.body?.departmentId || '').trim();
    const providedPassword = String(req.body?.password || '');

    if (!name || !email || !branch || !department) {
      return res.status(400).json({
        error: "name, email, branch and department are required",
      });
    }
    if (providedPassword && providedPassword.length < 6) {
      return res
        .status(400)
        .json({ error: "password must be at least 6 characters" });
    }

    // Company must exist, be active, and be under its maxUsers cap
    // (fail closed on lookup errors / unknown companies).
    const limit = await checkUserLimit(companyId);
    if (limit.lookupFailed) {
      return res.status(503).json({
        error: "Could not verify company entitlements. Please try again.",
      });
    }
    if (!limit.companyExists) {
      return res.status(403).json({ error: "Unknown company" });
    }
    if (!limit.allowed) {
      return res.status(403).json({
        error:
          limit.companyStatus !== 'active'
            ? "This company account is not active."
            : "Maximum user limit reached for this company.",
      });
    }

    // check duplicate login
    const byEmail = await db
      .collection(USERS)
      .where("emailLower", "==", email)
      .limit(1)
      .get();
    if (!byEmail.empty) {
      return res.status(409).json({ error: "user already exists" });
    }

    // Random temporary password when the admin did not set one — returned
    // once so credentials can be shared with the HR user; mustChangePassword
    // forces a rotation on first login.
    const tempPassword = `Serv-${crypto.randomBytes(6).toString('hex')}`;
    const finalPassword = providedPassword || tempPassword;

    // Firebase Auth account so the Flutter Firebase sign-in works.
    let firebaseUid: string | null = null;
    try {
      const fbUser = await auth.createUser({
        email,
        password: finalPassword,
        displayName: name,
      });
      firebaseUid = fbUser.uid;
    } catch (e: any) {
      if (e?.code === 'auth/email-already-exists') {
        const fbUser = await auth.getUserByEmail(email);
        firebaseUid = fbUser.uid;
        // Keep Firebase password in sync with the credentials being issued
        await auth.updateUser(fbUser.uid, { password: finalPassword });
      } else {
        console.error('createHrUser: Firebase user creation failed:', e);
        return res.status(502).json({
          error: "Failed to create Firebase Auth account for HR user",
        });
      }
    }

    const hash = await bcrypt.hash(finalPassword, 10);
    const now = new Date();
    const userId = uuidv4();

    const doc: Record<string, unknown> = {
      name,
      email,
      emailLower: email,
      phone: phone || null,
      password: hash,
      passwordHash: hash,
      hashedPassword: hash,
      role: "hr",
      status: "active",
      companyId,
      branch,
      department,
      firebaseUid,
      mustChangePassword: !providedPassword,
      createdBy: caller?.userId || null,
      createdAt: now,
      updatedAt: now,
    };
    if (branchId) doc.branchId = branchId;
    if (departmentId) doc.departmentId = departmentId;

    await db.collection(USERS).doc(userId).set(doc);

    // Track usage after successful HR user creation
    await trackAdminUsage(req, {
      writeCount: 1,
      apiCalls: 1,
    });

    return res.status(201).json({
      success: true,
      hrUser: {
        userId,
        firebaseUid,
        name,
        email,
        role: "hr",
        status: "active",
        companyId,
        branch,
        department,
      },
      tempPassword: !providedPassword ? tempPassword : undefined,
      message: "HR user created successfully",
    });
  } catch (e: any) {
    console.error('createHrUser error:', e);
    return res
      .status(500)
      .json({ error: e.message || "failed to create HR user" });
  }
}

// GET /api/admin/hr-users
// Lists the HR users belonging to the CALLER's company.
export async function listHrUsers(req: Request, res: Response) {
  try {
    const caller = (req as any).user;
    const companyId = String(caller?.companyId || '').trim();
    if (!companyId) {
      return res.status(403).json({ error: "No company context on token" });
    }

    const snap = await db
      .collection(USERS)
      .where("companyId", "==", companyId)
      .where("role", "==", "hr")
      .get();

    const hrUsers = snap.docs
      .map((d) => {
        const u = d.data() as any;
        return {
          id: d.id,
          name: u.name || u.fullName || '',
          email: u.email || '',
          role: u.role || 'hr',
          status: u.status || 'active',
          companyId: u.companyId || '',
          branch: u.branch || u.branchName || '',
          branchId: u.branchId || null,
          department: u.department || u.departmentName || '',
          departmentId: u.departmentId || null,
          mustChangePassword: u.mustChangePassword === true,
          createdAt: u.createdAt || null,
        };
      })
      .sort((a, b) => a.name.localeCompare(b.name));

    await trackAdminUsage(req, {
      readCount: 1,
      apiCalls: 1,
    });

    return res.status(200).json({ success: true, hrUsers });
  } catch (e: any) {
    console.error('listHrUsers error:', e);
    return res
      .status(500)
      .json({ error: e.message || "failed to list HR users" });
  }
}

/**
 * Load an HR user doc owned by the caller's company. Returns null (after
 * writing the error response) when the doc is missing, not an hr, or
 * belongs to another company — cross-tenant access yields 403 without
 * revealing whether the user exists.
 */
async function findOwnedHrUser(
  req: Request,
  res: Response,
  userId: string,
): Promise<FirebaseFirestore.DocumentSnapshot | null> {
  const companyId = String((req as any).user?.companyId || '').trim();
  if (!companyId) {
    res.status(403).json({ error: "No company context on token" });
    return null;
  }
  const snap = await db.collection(USERS).doc(userId).get();
  if (!snap.exists || (snap.data() as any)?.role !== 'hr') {
    res.status(404).json({ error: "HR user not found" });
    return null;
  }
  if (String((snap.data() as any)?.companyId || '') !== companyId) {
    res.status(403).json({ error: "Access denied" });
    return null;
  }
  return snap;
}

// PUT /api/admin/hr-users/:userId
// Updates an HR user's profile fields. Identity/tenant/entitlement fields
// (email, companyId, role, password, approvedFeatures) are immutable
// through this endpoint — feature approval stays with Platform Admin and
// credentials are handled by the password-reset flow.
export async function updateHrUser(req: Request, res: Response) {
  try {
    const doc = await findOwnedHrUser(req, res, String(req.params.userId));
    if (!doc) return;

    const ALLOWED = [
      'name',
      'phone',
      'branch',
      'branchId',
      'department',
      'departmentId',
      'status',
    ] as const;
    const updates: Record<string, unknown> = {};
    for (const key of ALLOWED) {
      if (req.body && req.body[key] !== undefined) {
        updates[key] = req.body[key];
      }
    }
    if (
      updates.status !== undefined &&
      !['active', 'inactive'].includes(String(updates.status))
    ) {
      return res.status(400).json({ error: "status must be active|inactive" });
    }
    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ error: "Nothing to update" });
    }

    await doc.ref.update({ ...updates, updatedAt: new Date() });

    await trackAdminUsage(req, { writeCount: 1, apiCalls: 1 });
    const fresh = await doc.ref.get();
    const u = fresh.data() as any;
    return res.status(200).json({
      success: true,
      hrUser: {
        userId: doc.id,
        name: u.name || '',
        email: u.email || '',
        role: u.role || 'hr',
        status: u.status || 'active',
        companyId: u.companyId || '',
        branch: u.branch || '',
        department: u.department || '',
      },
      message: "HR user updated successfully",
    });
  } catch (e: any) {
    console.error('updateHrUser error:', e);
    return res
      .status(500)
      .json({ error: e.message || "failed to update HR user" });
  }
}

// DELETE /api/admin/hr-users/:userId
// Soft-delete: flips status to 'inactive' and disables the Firebase Auth
// identity — the record (and its approvedFeatures/audit history) is kept
// for referential integrity, never hard-deleted.
export async function deactivateHrUser(req: Request, res: Response) {
  try {
    const doc = await findOwnedHrUser(req, res, String(req.params.userId));
    if (!doc) return;

    const data = doc.data() as any;
    await doc.ref.update({
      status: 'inactive',
      deactivatedAt: new Date(),
      deactivatedBy: (req as any).user?.userId || null,
      updatedAt: new Date(),
    });

    // Disable the Firebase identity when present — non-fatal since the
    // users.status check already blocks login.
    const uid = data?.firebaseUid;
    if (uid) {
      try {
        await auth.updateUser(String(uid), { disabled: true });
      } catch (e) {
        console.error('deactivateHrUser: Firebase disable failed:', e);
      }
    }

    await trackAdminUsage(req, { writeCount: 1, apiCalls: 1 });
    return res.status(200).json({
      success: true,
      userId: doc.id,
      status: 'inactive',
      message: "HR user deactivated",
    });
  } catch (e: any) {
    console.error('deactivateHrUser error:', e);
    return res
      .status(500)
      .json({ error: e.message || "failed to deactivate HR user" });
  }
}
