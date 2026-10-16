import { Request, Response } from 'express';
import * as bcrypt from 'bcryptjs';
import { v4 as uuidv4 } from 'uuid';
import { Timestamp } from 'firebase-admin/firestore';
import { auth, db } from '../config/firebase';
import { normEmail } from '../common/utils';
import {
  COMPANIES_COLLECTION,
  countActiveCompanyUsers,
  getCompanyEntitlement,
} from '../services/entitlementService';
import {
  FEATURE_CATALOG,
  resolveEffectiveFeatures,
  validateFeatureSelection,
} from '../constants/features';

const USERS_COL = 'users';
const COMPANY_ID_PATTERN = /^[A-Za-z0-9_-]{2,32}$/;

interface CompanyWriteFields {
  companyId: string;
  name: string;
  companyName: string;
  adminName?: string;
  adminEmail?: string;
  adminPhone?: string;
  maxUsers?: number | null;
  enabledFeatures?: string[];
  status: string;
  plan?: string | null;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  createdBy?: string;
  updatedBy?: string;
}

const normalizeCompanyId = (v: unknown): string =>
  String(v || '').trim().toUpperCase();

const normalizeStatus = (v: unknown): string | null => {
  const s = String(v || '').trim().toLowerCase();
  return ['active', 'suspended', 'inactive'].includes(s) ? s : null;
};

const badRequest = (res: Response, message: string, extra: object = {}) =>
  res.status(400).json({ success: false, error: message, ...extra });

/** GET /api/platform/features — catalog + dependency map for the admin UI */
export const listFeatureCatalog = async (
  _req: Request,
  res: Response,
): Promise<Response> => {
  return res.status(200).json({
    success: true,
    features: FEATURE_CATALOG,
  });
};

/** GET /api/platform/companies — list all tenants with usage counts */
export const listCompanies = async (
  _req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const snap = await db.collection(COMPANIES_COLLECTION).get();

    const companies = await Promise.all(
      snap.docs.map(async (doc) => {
        const d = doc.data();
        const ent = await getCompanyEntitlement(doc.id);
        const currentUsers = await countActiveCompanyUsers(doc.id);

        return {
          companyId: doc.id,
          name: d.name || d.companyName || '',
          companyName: d.companyName || d.name || '',
          adminName: d.adminName || '',
          adminEmail: d.adminEmail || '',
          adminPhone: d.adminPhone || '',
          status: d.status || 'active',
          plan: d.plan || null,
          maxUsers: ent.maxUsers,
          enabledFeatures: ent.enabledFeatures,
          effectiveFeatures: ent.effectiveFeatures
            ? Array.from(ent.effectiveFeatures)
            : null,
          isLegacy: ent.isLegacy,
          currentUsers,
          createdAt: d.createdAt || null,
          updatedAt: d.updatedAt || null,
        };
      }),
    );

    return res.status(200).json({ success: true, companies });
  } catch (e) {
    console.error('listCompanies error:', e);
    return res
      .status(500)
      .json({ success: false, error: 'Failed to list companies' });
  }
};

/** GET /api/platform/companies/:companyId */
export const getCompany = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const companyId = normalizeCompanyId(req.params.companyId);
    const ent = await getCompanyEntitlement(companyId);

    if (!ent.exists) {
      return res
        .status(404)
        .json({ success: false, error: 'Company not found' });
    }

    const snap = await db.collection(COMPANIES_COLLECTION).doc(companyId).get();
    const d = snap.data() || {};
    const currentUsers = await countActiveCompanyUsers(companyId);

    return res.status(200).json({
      success: true,
      company: {
        companyId,
        name: d.name || d.companyName || '',
        companyName: d.companyName || d.name || '',
        adminName: d.adminName || '',
        adminEmail: d.adminEmail || '',
        adminPhone: d.adminPhone || '',
        status: d.status || 'active',
        plan: d.plan || null,
        maxUsers: ent.maxUsers,
        enabledFeatures: ent.enabledFeatures,
        effectiveFeatures: ent.effectiveFeatures
          ? Array.from(ent.effectiveFeatures)
          : null,
        isLegacy: ent.isLegacy,
        currentUsers,
        createdAt: d.createdAt || null,
        updatedAt: d.updatedAt || null,
      },
    });
  } catch (e) {
    console.error('getCompany error:', e);
    return res
      .status(500)
      .json({ success: false, error: 'Failed to fetch company' });
  }
};

/**
 * POST /api/platform/companies
 * Body: {
 *   companyId, companyName, adminName, adminEmail, adminPhone, adminPassword,
 *   maxUsers?, enabledFeatures?
 * }
 *
 * Creates the tenant document AND the client admin login account:
 * a Firebase Auth user (so the Flutter Firebase sign-in works) plus a
 * `users` document with role 'company_admin' bound to the new companyId.
 */
export const createCompany = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const caller = req.user;
    const {
      companyName,
      adminName,
      adminPhone,
      adminPassword,
      status,
      plan,
    } = req.body || {};

    const companyId = normalizeCompanyId(req.body?.companyId);
    const name = String(companyName || '').trim();
    const aName = String(adminName || '').trim();
    const aEmail = normEmail(req.body?.adminEmail || '');
    const aPhone = String(adminPhone || '').trim();
    const aPassword = String(adminPassword || '');
    const normalizedStatus = normalizeStatus(status) || 'active';

    if (!COMPANY_ID_PATTERN.test(companyId)) {
      return badRequest(
        res,
        'companyId must be 2-32 chars: letters, digits, "-" or "_"',
      );
    }
    if (!name) return badRequest(res, 'companyName is required');
    if (!aName) return badRequest(res, 'adminName is required');
    if (!aEmail) return badRequest(res, 'adminEmail is required');
    if (!aPassword || aPassword.length < 6) {
      return badRequest(res, 'adminPassword must be at least 6 characters');
    }

    // maxUsers: optional; must be a positive integer when provided
    let maxUsers: number | null = null;
    if (req.body?.maxUsers !== undefined && req.body?.maxUsers !== null) {
      const m = Number(req.body.maxUsers);
      if (!Number.isFinite(m) || m <= 0) {
        return badRequest(res, 'maxUsers must be a positive number');
      }
      maxUsers = Math.floor(m);
    }

    // enabledFeatures: optional; validated against catalog + dependencies
    let enabledFeatures: string[] | undefined;
    if (req.body?.enabledFeatures !== undefined) {
      const v = validateFeatureSelection(req.body.enabledFeatures);
      if (!v.ok) {
        return badRequest(res, 'Invalid feature selection', {
          unknown: v.unknown,
          missingDependencies: v.missingDeps,
        });
      }
      enabledFeatures = v.features;
    } else {
      // Default: a newly onboarded company gets the full catalog unless the
      // platform admin explicitly narrows it.
      enabledFeatures = FEATURE_CATALOG.map((f) => f.key);
    }

    const companyRef = db.collection(COMPANIES_COLLECTION).doc(companyId);
    const existing = await companyRef.get();
    if (existing.exists) {
      return res
        .status(409)
        .json({ success: false, error: 'companyId already exists' });
    }

    // Reject if a user account already exists for the admin email
    const userByEmail = await db
      .collection(USERS_COL)
      .where('emailLower', '==', aEmail)
      .limit(1)
      .get();
    if (!userByEmail.empty) {
      return res.status(409).json({
        success: false,
        error: 'A user account already exists for adminEmail',
      });
    }

    // Create (or reuse) the Firebase Auth account so the Flutter
    // FirebaseAuth sign-in step works for this client admin.
    let firebaseUid: string | null = null;
    try {
      const fbUser = await auth.createUser({
        email: aEmail,
        password: aPassword,
        displayName: aName,
      });
      firebaseUid = fbUser.uid;
    } catch (e: any) {
      if (e?.code === 'auth/email-already-exists') {
        const fbUser = await auth.getUserByEmail(aEmail);
        firebaseUid = fbUser.uid;
        // Keep Firebase password in sync with the credentials being issued
        await auth.updateUser(fbUser.uid, { password: aPassword });
      } else {
        console.error('createCompany: Firebase user creation failed:', e);
        return res.status(502).json({
          success: false,
          error: 'Failed to create Firebase Auth account for client admin',
        });
      }
    }

    const now = Timestamp.now();
    const companyDoc: CompanyWriteFields = {
      companyId,
      name,
      companyName: name,
      adminName: aName,
      adminEmail: aEmail,
      adminPhone: aPhone,
      status: normalizedStatus,
      maxUsers,
      enabledFeatures,
      plan: plan ? String(plan) : null,
      createdAt: now,
      updatedAt: now,
      createdBy: caller?.userId,
      updatedBy: caller?.userId,
    };

    await companyRef.set(companyDoc);

    const hash = await bcrypt.hash(aPassword, 10);
    const userId = uuidv4();
    await db.collection(USERS_COL).doc(userId).set({
      name: aName,
      email: aEmail,
      emailLower: aEmail,
      phone: aPhone || null,
      password: hash,
      passwordHash: hash,
      hashedPassword: hash,
      role: 'company_admin',
      status: 'active',
      companyId,
      firebaseUid,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    return res.status(201).json({
      success: true,
      company: {
        companyId,
        companyName: name,
        maxUsers,
        enabledFeatures,
        effectiveFeatures: Array.from(
          resolveEffectiveFeatures(enabledFeatures),
        ),
        status: normalizedStatus,
      },
      admin: {
        userId,
        firebaseUid,
        email: aEmail,
        role: 'company_admin',
      },
      message: 'Company and client admin created successfully',
    });
  } catch (e: any) {
    console.error('createCompany error:', e);
    return res.status(500).json({
      success: false,
      error: e?.message || 'Failed to create company',
    });
  }
};

/**
 * PATCH /api/platform/companies/:companyId
 * Whitelisted fields only: companyName, adminName, adminPhone, maxUsers,
 * enabledFeatures, status, plan. companyId itself is immutable.
 */
export const updateCompany = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const caller = req.user;
    const companyId = normalizeCompanyId(req.params.companyId);
    const companyRef = db.collection(COMPANIES_COLLECTION).doc(companyId);
    const snap = await companyRef.get();

    if (!snap.exists) {
      return res
        .status(404)
        .json({ success: false, error: 'Company not found' });
    }

    const updates: Record<string, unknown> = {
      updatedAt: Timestamp.now(),
      updatedBy: caller?.userId,
    };

    if (req.body?.companyName !== undefined) {
      const n = String(req.body.companyName || '').trim();
      if (!n) return badRequest(res, 'companyName cannot be empty');
      updates.companyName = n;
      updates.name = n;
    }
    if (req.body?.adminName !== undefined) {
      updates.adminName = String(req.body.adminName || '').trim();
    }
    if (req.body?.adminPhone !== undefined) {
      updates.adminPhone = String(req.body.adminPhone || '').trim();
    }
    if (req.body?.plan !== undefined) {
      updates.plan = req.body.plan === null ? null : String(req.body.plan);
    }

    if (req.body?.maxUsers !== undefined) {
      if (req.body.maxUsers === null || req.body.maxUsers === '') {
        updates.maxUsers = null; // unlimited
      } else {
        const m = Number(req.body.maxUsers);
        if (!Number.isFinite(m) || m <= 0) {
          return badRequest(res, 'maxUsers must be a positive number or null');
        }
        updates.maxUsers = Math.floor(m);
      }
    }

    if (req.body?.enabledFeatures !== undefined) {
      const v = validateFeatureSelection(req.body.enabledFeatures);
      if (!v.ok) {
        return badRequest(res, 'Invalid feature selection', {
          unknown: v.unknown,
          missingDependencies: v.missingDeps,
        });
      }
      updates.enabledFeatures = v.features;
    }

    if (req.body?.status !== undefined) {
      const s = normalizeStatus(req.body.status);
      if (!s) {
        return badRequest(
          res,
          'status must be one of: active, suspended, inactive',
        );
      }
      updates.status = s;
    }

    await companyRef.update(updates);

    const ent = await getCompanyEntitlement(companyId);
    const currentUsers = await countActiveCompanyUsers(companyId);

    return res.status(200).json({
      success: true,
      company: {
        companyId,
        status: ent.status,
        maxUsers: ent.maxUsers,
        enabledFeatures: ent.enabledFeatures,
        effectiveFeatures: ent.effectiveFeatures
          ? Array.from(ent.effectiveFeatures)
          : null,
        currentUsers,
      },
      message: 'Company updated successfully',
    });
  } catch (e: any) {
    console.error('updateCompany error:', e);
    return res.status(500).json({
      success: false,
      error: e?.message || 'Failed to update company',
    });
  }
};
