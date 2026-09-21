import { Request, Response } from 'express';
import { FieldValue } from 'firebase-admin/firestore';
import { getDb } from '../config/firebase';
import {
  ORGANIZATION_POLICIES_COL,
  OrganizationPolicy,
} from '../models/organizationPolicy';
import {
  EMPLOYEE_POLICY_ACCEPTANCES_COL,
  EmployeePolicyAcceptance,
} from '../models/employeePolicyAcceptance';
import { errorResponse, successResponse } from '../common/response';

const USERS_COL = 'users';
const COMPANIES_COL = 'companyProfile';

type AuthUser = {
  userId?: string;
  email?: string;
  role?: string;
  empid?: string | null;
  companyId?: string | null;
};

/**
 * Verifies the caller is an active employee with an active organization.
 * Returns the employee's userId and organizationId on success, or null on failure.
 */
async function getAuthenticatedEmployee(
  req: Request,
  res: Response
): Promise<{ userId: string; organizationId: string } | null> {
  const user = req.user as AuthUser | undefined;
  if (!user) {
    errorResponse(res, 'Not authenticated', 401);
    return null;
  }

  const role = String(user.role || '').toLowerCase();
  if (role !== 'employee') {
    errorResponse(res, 'Not authorized', 403);
    return null;
  }

  const userId = String(user.userId || '').trim();
  const organizationId = String(user.companyId || '').trim();

  if (!userId || !organizationId) {
    errorResponse(res, 'Invalid account context', 403);
    return null;
  }

  // Verify employee is active
  const userSnap = await getDb().collection(USERS_COL).doc(userId).get();
  if (!userSnap.exists) {
    errorResponse(res, 'Invalid account context', 403);
    return null;
  }
  const userData = userSnap.data() as any;
  if (String(userData.status || '').toLowerCase() !== 'active') {
    errorResponse(res, 'Account is not active', 403);
    return null;
  }
  if (String(userData.companyId || '').trim() !== organizationId) {
    errorResponse(res, 'Invalid account context', 403);
    return null;
  }

  // Verify organization is active
  const orgSnap = await getDb().collection(COMPANIES_COL).doc(organizationId).get();
  if (!orgSnap.exists) {
    errorResponse(res, 'Invalid organization context', 403);
    return null;
  }
  const orgData = orgSnap.data() as any;
  if (String(orgData.status || '').toLowerCase() !== 'active') {
    errorResponse(res, 'Organization is not active', 403);
    return null;
  }

  return { userId, organizationId };
}

/**
 * Returns all active policies for an organization.
 */
async function getActivePolicies(
  organizationId: string
): Promise<OrganizationPolicy[]> {
  const snap = await getDb()
    .collection(ORGANIZATION_POLICIES_COL)
    .where('organizationId', '==', organizationId)
    .where('active', '==', true)
    .get();

  return snap.docs.map((d) => ({ id: d.id, ...d.data() }) as OrganizationPolicy);
}

/**
 * Returns the employee's acceptance records for the given policies.
 */
async function getEmployeeAcceptances(
  userId: string,
  organizationId: string
): Promise<EmployeePolicyAcceptance[]> {
  const snap = await getDb()
    .collection(EMPLOYEE_POLICY_ACCEPTANCES_COL)
    .where('userId', '==', userId)
    .where('organizationId', '==', organizationId)
    .get();

  return snap.docs.map(
    (d) => ({ id: d.id, ...d.data() }) as EmployeePolicyAcceptance
  );
}

/**
 * GET /api/organization/policies
 */
export const listOrganizationPolicies = async (
  req: Request,
  res: Response
): Promise<Response> => {
  try {
    const auth = await getAuthenticatedEmployee(req, res);
    if (!auth) return res;

    const { userId, organizationId } = auth;
    const policies = await getActivePolicies(organizationId);
    const acceptances = await getEmployeeAcceptances(userId, organizationId);

    const acceptedByKey = new Map<string, number>();
    for (const a of acceptances) {
      const key = `${a.policyId}:${a.policyVersion}`;
      acceptedByKey.set(key, a.policyVersion);
    }

    const result = policies.map((p) => ({
      policyId: p.policyId,
      type: p.type,
      title: p.title,
      description: p.description,
      version: p.version,
      content: p.content,
      documentUrl: p.documentUrl || null,
      publishedAt: p.publishedAt,
      required: p.required,
      requiresSeparateConsent: p.requiresSeparateConsent,
      accepted: acceptedByKey.get(`${p.policyId}:${p.version}`) === p.version,
      acceptedVersion: acceptedByKey.get(`${p.policyId}:${p.version}`) || null,
    }));

    return successResponse(res, { policies: result }, 'Policies retrieved');
  } catch (error: any) {
    console.error('listOrganizationPolicies error:', error);
    return errorResponse(res, 'Internal server error', 500);
  }
};

/**
 * GET /api/organization/policies/acceptance-status
 */
export const getPolicyAcceptanceStatus = async (
  req: Request,
  res: Response
): Promise<Response> => {
  try {
    const auth = await getAuthenticatedEmployee(req, res);
    if (!auth) return res;

    const { userId, organizationId } = auth;
    const policies = await getActivePolicies(organizationId);
    const acceptances = await getEmployeeAcceptances(userId, organizationId);

    const acceptedKeys = new Set(
      acceptances.map((a) => `${a.policyId}:${a.policyVersion}`)
    );

    const pendingRequired = policies
      .filter((p) => p.required && !acceptedKeys.has(`${p.policyId}:${p.version}`))
      .map((p) => ({
        policyId: p.policyId,
        title: p.title,
        version: p.version,
      }));

    const allAccepted = pendingRequired.length === 0;

    return successResponse(
      res,
      { allAccepted, pendingRequired },
      allAccepted ? 'All required policies accepted' : 'Policies pending acceptance'
    );
  } catch (error: any) {
    console.error('getPolicyAcceptanceStatus error:', error);
    return errorResponse(res, 'Internal server error', 500);
  }
};

/**
 * POST /api/organization/policies/accept
 */
export const acceptPolicyVersion = async (
  req: Request,
  res: Response
): Promise<Response> => {
  try {
    const auth = await getAuthenticatedEmployee(req, res);
    if (!auth) return res;

    const { userId, organizationId } = auth;
    const { policyId, policyVersion } = req.body || {};

    const normalizedPolicyId = String(policyId || '').trim();
    const normalizedVersion = Number(policyVersion);

    if (!normalizedPolicyId || !Number.isFinite(normalizedVersion) || normalizedVersion < 1) {
      return errorResponse(res, 'Invalid policy or version', 400);
    }

    const db = getDb();

    // Look up the current active version for this policy in this organization.
    const currentSnap = await db
      .collection(ORGANIZATION_POLICIES_COL)
      .where('organizationId', '==', organizationId)
      .where('policyId', '==', normalizedPolicyId)
      .where('active', '==', true)
      .limit(1)
      .get();

    if (currentSnap.empty) {
      return errorResponse(res, 'Invalid policy or version', 404);
    }

    const policyDoc = currentSnap.docs[0];
    const policy = policyDoc.data() as OrganizationPolicy;

    // The employee must accept the version they actually viewed.
    if (policy.version !== normalizedVersion) {
      return errorResponse(
        res,
        'A newer version of this policy has been published',
        409
      );
    }

    // Deterministic document ID makes concurrent duplicate writes atomic.
    const acceptanceDocId = `${userId}_${organizationId}_${normalizedPolicyId}_${normalizedVersion}`;
    const acceptanceRef = db
      .collection(EMPLOYEE_POLICY_ACCEPTANCES_COL)
      .doc(acceptanceDocId);

    const existing = await acceptanceRef.get();
    if (existing.exists) {
      return successResponse(
        res,
        {
          accepted: true,
          policyId: normalizedPolicyId,
          policyVersion: normalizedVersion,
          acceptedAt: existing.data()?.acceptedAt || null,
        },
        'Policy already accepted'
      );
    }

    const acceptanceData: Omit<EmployeePolicyAcceptance, 'acceptedAt'> & {
      acceptedAt: FirebaseFirestore.FieldValue;
    } = {
      userId,
      organizationId,
      policyId: normalizedPolicyId,
      policyVersion: normalizedVersion,
      contentHash: policy.contentHash,
      acceptedAt: FieldValue.serverTimestamp(),
      ipAddress: req.ip,
      userAgent: req.headers['user-agent'],
    };

    // create() fails atomically if the doc already exists, so concurrent
    // requests can never produce duplicate acceptance records.
    try {
      await acceptanceRef.create(acceptanceData);
    } catch (e: any) {
      if (e?.code === 6 || String(e?.message || '').includes('ALREADY_EXISTS')) {
        const snap = await acceptanceRef.get();
        return successResponse(
          res,
          {
            accepted: true,
            policyId: normalizedPolicyId,
            policyVersion: normalizedVersion,
            acceptedAt: snap.data()?.acceptedAt || null,
          },
          'Policy already accepted'
        );
      }
      throw e;
    }

    return successResponse(
      res,
      {
        accepted: true,
        policyId: normalizedPolicyId,
        policyVersion: normalizedVersion,
        acceptedAt: new Date(),
      },
      'Policy accepted'
    );
  } catch (error: any) {
    console.error('acceptPolicyVersion error:', error);
    return errorResponse(res, 'Internal server error', 500);
  }
};
