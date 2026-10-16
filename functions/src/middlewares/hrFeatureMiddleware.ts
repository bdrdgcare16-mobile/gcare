// functions/src/middlewares/hrFeatureMiddleware.ts
// HR-level feature authorization.
//
// This is intentionally separate from featureMiddleware.requireFeature:
//   - requireFeature(key)       gates TENANT access  → companies.enabledFeatures
//   - requireHrFeature(key)     gates HR USER access → users/<hrUserId>.approvedFeatures
//
// An HR user gets access ONLY to features the Platform Admin approved on
// their individual feature request. Being enabled for the company, being
// in the catalog, being requested, or being visible in Flutter is never
// sufficient — the users/<hrUserId>.approvedFeatures doc is the sole
// source of truth. Dependency semantics reuse the shared catalog:
// approve 'tracking' and 'attendance' is implied (resolveEffectiveFeatures),
// matching company-level behavior.
import { Request, Response, NextFunction } from "express";
import { db } from "../config/firebase";
import { COLLECTIONS } from "../constants/collections";
import {
  isKnownFeature,
  resolveEffectiveFeatures,
} from "../constants/features";

const USERS = COLLECTIONS.USERS;

export type HrFeatureKey = string | ((req: Request) => string);

/**
 * Load the HR user's effective approved feature set.
 * Returns null when the user record is missing — fail closed.
 */
async function loadApprovedFeatures(userId: string): Promise<Set<string> | null> {
  const snap = await db.collection(USERS).doc(userId).get();
  if (!snap.exists) return null;
  const raw = (snap.data() as any)?.approvedFeatures;
  const list = Array.isArray(raw) ? raw.map((f) => String(f)) : [];
  return resolveEffectiveFeatures(list);
}

/**
 * requireHrFeature('payroll') or requireHrFeature(req => req.params.feature)
 *
 * Requires: authenticated (req.user), role === 'hr', companyId present,
 * and the feature present in the HR user's approvedFeatures (with the
 * shared dependency closure applied).
 */
export const requireHrFeature = (key: HrFeatureKey) => {
  return async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<Response | void> => {
    try {
      const user = (req as any).user;
      if (!user) {
        return res.status(401).json({ error: "Not authenticated" });
      }
      if (String(user.role || "").toLowerCase() !== "hr") {
        return res.status(403).json({ error: "HR role required" });
      }
      if (!String(user.companyId || "").trim()) {
        return res.status(403).json({ error: "No company context on token" });
      }

      const featureKey = String(
        typeof key === "function" ? key(req) : key,
      ).toLowerCase();
      if (!isKnownFeature(featureKey)) {
        return res.status(400).json({ error: "Unknown feature" });
      }

      const approved = await loadApprovedFeatures(String(user.userId));
      if (approved === null) {
        return res.status(403).json({ error: "HR account not found" });
      }
      if (!approved.has(featureKey)) {
        return res.status(403).json({
          error: "Feature not approved for this HR user",
          feature: featureKey,
        });
      }

      next();
    } catch (e: any) {
      console.error("requireHrFeature error:", e);
      return res
        .status(500)
        .json({ error: e.message || "feature authorization failed" });
    }
  };
};

export type HrFeatureKeys = string[] | ((req: Request) => string[]);

/**
 * Applies the HR approved-feature check ONLY to callers whose role is 'hr'.
 * Admin, employee and platform roles pass straight through — their existing
 * role middleware continues to authorize them. Use this on routes shared
 * between admin and HR pages so an HR token needs role 'hr' + a companyId +
 * at least one of `keys` inside users/<hrUserId>.approvedFeatures
 * (dependency closure applied). Non-HR behaviour is never changed.
 */
export const hrFeatureGate = (keys: HrFeatureKeys) => {
  return async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<Response | void> => {
    try {
      const user = (req as any).user;
      if (!user) {
        return res.status(401).json({ error: "Not authenticated" });
      }
      if (String(user.role || "").toLowerCase() !== "hr") {
        return next();
      }
      if (!String(user.companyId || "").trim()) {
        return res.status(403).json({ error: "No company context on token" });
      }

      const rawKeys =
        typeof keys === "function" ? keys(req) : keys;
      const list = (Array.isArray(rawKeys) ? rawKeys : [rawKeys])
        .map((k) => String(k).trim().toLowerCase())
        .filter(Boolean);

      if (list.length === 0 || list.some((k) => !isKnownFeature(k))) {
        return res.status(400).json({ error: "Unknown feature" });
      }

      const approved = await loadApprovedFeatures(String(user.userId));
      if (approved === null) {
        return res.status(403).json({ error: "HR account not found" });
      }
      if (!list.some((k) => approved.has(k))) {
        return res.status(403).json({
          error: "Feature not approved for this HR user",
          feature: list.join("|"),
        });
      }

      next();
    } catch (e: any) {
      console.error("hrFeatureGate error:", e);
      return res
        .status(500)
        .json({ error: e.message || "feature authorization failed" });
    }
  };
};
