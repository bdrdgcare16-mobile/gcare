import { Request, Response, NextFunction } from 'express';

import { getDb } from '../config/firebase';

export const FEATURE_NOT_ENABLED = 'FEATURE_NOT_ENABLED';
export const ORGANIZATION_INACTIVE = 'ORGANIZATION_INACTIVE';

const COMPANY_PROFILE_COL = 'companyProfile';

// Shared gate core — see requireFeature / requireAnyFeature below.
const gateForFeatures = (features: string[]) => {
  return async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<Response | void> => {
    const denied = () =>
      res.status(403).json(
        features.length === 1
          ? { error: FEATURE_NOT_ENABLED, feature: features[0] }
          : { error: FEATURE_NOT_ENABLED, features },
      );
    try {
      const user = req.user;
      if (!user) {
        return res.status(401).json({ error: 'Not authenticated' });
      }
      if (user.role === 'platform_admin' || user.role === 'super_admin') {
        return next();
      }

      const companyId = String(user.companyId || '').trim();
      if (!companyId) {
        return denied();
      }

      const snap = await getDb()
        .collection(COMPANY_PROFILE_COL)
        .doc(companyId)
        .get();
      if (!snap.exists) {
        return denied();
      }

      const profile = (snap.data() ?? {}) as Record<string, unknown>;
      const status = String(profile.status ?? 'active')
        .trim()
        .toLowerCase();
      if (status !== 'active') {
        return res
          .status(403)
          .json({ error: ORGANIZATION_INACTIVE, features });
      }

      const enabled = profile.enabledFeatures;
      // Legacy organizations created before feature gating have no
      // enabledFeatures field — preserve their existing access.
      if (enabled === undefined || enabled === null) {
        return next();
      }
      if (
        Array.isArray(enabled) &&
        features.some((f) => enabled.includes(f))
      ) {
        return next();
      }

      return denied();
    } catch (err) {
      console.error('requireFeature error:', err);
      return res.status(500).json({ error: 'Internal server error' });
    }
  };
};

/**
 * Non-middleware feature check for use inside controllers/services.
 *
 * Returns true only when companyProfile/{companyId}.enabledFeatures is an
 * array containing [feature]. Unlike the middleware's legacy-allow rule,
 * an org whose profile predates feature gating (no enabledFeatures field)
 * returns FALSE — additive feature modules (e.g. geo_fence) must default
 * to disabled for existing organizations unless explicitly enabled.
 */
export async function isOrgFeatureEnabled(
  companyId: string,
  feature: string,
): Promise<boolean> {
  try {
    const snap = await getDb()
      .collection(COMPANY_PROFILE_COL)
      .doc(String(companyId))
      .get();
    if (!snap.exists) return false;
    const enabled = (snap.data() as Record<string, unknown> | undefined)
      ?.enabledFeatures;
    return Array.isArray(enabled) && enabled.includes(feature);
  } catch (err) {
    console.error('isOrgFeatureEnabled error:', err);
    return false;
  }
}

/**
 * Non-middleware check using the SAME semantics as the route middleware:
 * missing profile / inactive org → false; enabledFeatures absent → true
 * (legacy orgs predate gating); present → must contain the feature.
 *
 * Use inside controllers that serve multiple feature domains under one
 * mount (e.g. /attendance/approvals deciding on `leaves` records) where a
 * route-level gate cannot express the per-source requirement.
 */
export async function isOrgFeatureAllowed(
  companyId: string,
  feature: string,
): Promise<boolean> {
  try {
    const snap = await getDb()
      .collection(COMPANY_PROFILE_COL)
      .doc(String(companyId))
      .get();
    if (!snap.exists) return false;
    const profile = (snap.data() ?? {}) as Record<string, unknown>;
    const status = String(profile.status ?? 'active').trim().toLowerCase();
    if (status !== 'active') return false;
    const enabled = profile.enabledFeatures;
    if (enabled === undefined || enabled === null) return true;
    return Array.isArray(enabled) && enabled.includes(feature);
  } catch (err) {
    console.error('isOrgFeatureAllowed error:', err);
    return false;
  }
}

/**
 * requireFeature('<featureId>') — organization feature authorization.
 *
 * Runs AFTER authMiddleware. Reads the caller's companyId from the verified
 * JWT and checks the canonical companyProfile.enabledFeatures array written
 * at activation (3D-D). Nothing is trusted from the request body/headers.
 *
 *   - platform_admin / super_admin   → bypass (not organization-scoped)
 *   - missing JWT identity           → 401
 *   - missing companyId / profile    → 403 FEATURE_NOT_ENABLED
 *   - profile.status != 'active'     → 403 ORGANIZATION_INACTIVE
 *   - enabledFeatures absent         → allow (legacy orgs predate gating)
 *   - enabledFeatures present        → must contain the feature, else
 *                                      403 { error: FEATURE_NOT_ENABLED }
 */
export const requireFeature = (feature: string) => gateForFeatures([feature]);

/**
 * requireAnyFeature(['a','b']) — same contract as requireFeature but the
 * request passes when ANY listed feature is enabled. Used for shared
 * surfaces such as GET /attendance/live, which is reachable with either
 * `attendance` or `location_tracking`.
 */
export const requireAnyFeature = (features: string[]) =>
  gateForFeatures(features);
