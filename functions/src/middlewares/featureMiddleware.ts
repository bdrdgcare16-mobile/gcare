import { Request, Response, NextFunction } from 'express';

import {
  getCompanyEntitlementSafe,
  companyHasFeature,
} from '../services/entitlementService';
import { featureLabel } from '../constants/features';
import { db } from '../config/firebase';

/**
 * Last-resort tenant resolution for requests that carry no companyId but do
 * carry an empid (e.g. GET /api/overtime?empid=...).
 * Returns null when no employee record matches.
 */
async function resolveCompanyIdByEmpid(empid: string): Promise<string | null> {
  const snap = await db
    .collection('employees')
    .where('empid', '==', String(empid).trim())
    .limit(1)
    .get();
  if (snap.empty) return null;
  return String(snap.docs[0].data()?.companyId || '').trim() || null;
}

/**
 * Tenant feature entitlement enforcement — FAIL CLOSED.
 *
 * Usage:
 *   router.get('/payroll', verifyToken, requireFeature('payroll'), handler);
 *
 * Behaviour:
 *  - `platform_admin` (platform admin) is never tenant-gated; legacy
 *    `super_admin` tokens are also exempt.
 *  - When the request is authenticated, the companyId comes ONLY from the
 *    verified JWT (`req.user.companyId`) — never from the request body/query.
 *  - For legacy routes that predated authMiddleware, the companyId may be
 *    taken from `req.body.companyId`/`req.query.companyId` ONLY to load that
 *    company's entitlement document; the entitlement itself is always read
 *    from the trusted `companies` collection on the backend.
 *  - LEGACY company (doc exists, enabledFeatures absent): all features.
 *  - MISSING company doc: 403 — unknown tenants get nothing.
 *  - LOOKUP FAILURE (Firestore error/timeout): 503 ENTITLEMENT_UNAVAILABLE,
 *    unless a fresh last-known-valid cached entitlement exists (60s TTL).
 *  - Companies with status 'suspended' or 'inactive': 403 COMPANY_NOT_ACTIVE.
 */
export const requireFeature = (feature: string) => {
  const featureKey = String(feature || '').trim().toLowerCase();

  return async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<Response | void> => {
    try {
      const role = String(req.user?.role || '').toLowerCase();
      if (role === 'platform_admin' || role === 'super_admin') {
        return next();
      }

      // companyId from authenticated context first; fall back to the
      // request payload only for routes that historically ran without
      // authMiddleware. The entitlement data itself is always server-side.
      let companyId = String(
        req.user?.companyId ??
          req.body?.companyId ??
          req.query?.companyId ??
          '',
      ).trim();

      if (!companyId) {
        const empid = String(
          req.query?.empid ?? req.body?.empid ?? req.params?.empid ?? '',
        ).trim();
        if (empid) {
          companyId = (await resolveCompanyIdByEmpid(empid)) || '';
        }
      }

      if (!companyId) {
        // No tenant context at all — deny rather than silently allow.
        return res.status(403).json({
          error: 'COMPANY_CONTEXT_REQUIRED',
          message: 'No company context could be resolved for this request.',
        });
      }

      const ent = await getCompanyEntitlementSafe(companyId);

      if (ent.lookupFailed) {
        return res.status(503).json({
          error: 'ENTITLEMENT_UNAVAILABLE',
          message:
            'Could not verify company entitlements. Please try again.',
        });
      }

      if (!ent.exists) {
        return res.status(403).json({
          error: 'COMPANY_NOT_FOUND',
          message: 'Unknown company.',
        });
      }

      if (ent.status !== 'active') {
        return res.status(403).json({
          error: 'COMPANY_NOT_ACTIVE',
          message: 'This company account is not active.',
        });
      }

      if (!companyHasFeature(ent, featureKey)) {
        return res.status(403).json({
          error: 'FEATURE_NOT_ENABLED',
          message: `${featureLabel(featureKey)} is not enabled for this company.`,
        });
      }

      return next();
    } catch (e) {
      // FAIL CLOSED: unexpected errors must never silently grant access.
      console.error('[requireFeature] error:', e);
      return res.status(503).json({
        error: 'ENTITLEMENT_UNAVAILABLE',
        message: 'Could not verify company entitlements. Please try again.',
      });
    }
  };
};
