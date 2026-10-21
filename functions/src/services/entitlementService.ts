import { db } from '../config/firebase';
import {
  resolveEffectiveFeatures,
  isKnownFeature,
} from '../constants/features';

export const COMPANIES_COLLECTION = 'companies';

/**
 * Entitlement view of a `companies/<companyId>` document.
 *
 * Backward-compatibility contract (fail-closed on failures):
 *  - LEGACY: the company document EXISTS and `enabledFeatures` is absent /
 *    not an array → every feature is allowed, no user limit. This preserves
 *    existing production companies until the Platform Admin configures them.
 *  - LEGACY-PRE-ENTITLEMENT: no `companies/<id>` document exists, but the
 *    companyId is referenced by real tenant data (`employees` or `users`).
 *    Production companies created before the entitlement layer never got a
 *    document — treating them as missing would lock out every existing
 *    employee. They are treated as legacy until Platform Admin creates the
 *    document. Tenant isolation is unaffected: a fabricated companyId has
 *    no tenant data and is still denied.
 *  - MISSING: the company document does not exist AND no tenant data
 *    references the companyId → exists=false, isLegacy=false → feature
 *    checks DENY. Unknown tenants get nothing.
 *  - FAILED: Firestore/network/internal error → lookupFailed=true → feature
 *    checks must NOT grant access (callers return 503 or use the
 *    last-known-valid cache via getCompanyEntitlementSafe).
 *  - If `maxUsers` is absent/null/<=0, the user limit is unlimited.
 *  - If `status` is absent it is treated as 'active'. 'suspended' / 'inactive'
 *    block feature-gated APIs and employee creation.
 */
export interface CompanyEntitlement {
  companyId: string;
  exists: boolean;
  /** true => the Firestore lookup itself failed; never treat as legacy */
  lookupFailed: boolean;
  name: string | null;
  status: string; // 'active' | 'suspended' | 'inactive' (absent -> 'active')
  plan: string | null;
  /** null => legacy/unconfigured (all features allowed) */
  enabledFeatures: string[] | null;
  /** effective set incl. dependency closure; null => legacy (all allowed) */
  effectiveFeatures: Set<string> | null;
  /** null/<=0 => unlimited */
  maxUsers: number | null;
  isLegacy: boolean;
}

const EMPTY_ENTITLEMENT = (
  companyId: string,
  lookupFailed: boolean,
): CompanyEntitlement => ({
  companyId,
  exists: false,
  lookupFailed,
  name: null,
  status: 'active',
  plan: null,
  enabledFeatures: null,
  effectiveFeatures: null,
  maxUsers: null,
  isLegacy: false,
});

export async function getCompanyEntitlement(
  companyId: string,
): Promise<CompanyEntitlement> {
  const id = String(companyId || '').trim();

  if (!id) {
    return EMPTY_ENTITLEMENT(id, false);
  }

  let data: FirebaseFirestore.DocumentData | undefined;
  try {
    const snap = await db.collection(COMPANIES_COLLECTION).doc(id).get();
    data = snap.exists ? snap.data() : undefined;
  } catch (e) {
    // FAIL CLOSED: a lookup failure is never legacy access. Callers should
    // respond 503 ENTITLEMENT_UNAVAILABLE or use the last-known-valid cache.
    console.error('[entitlement] failed to load company', id, e);
    return EMPTY_ENTITLEMENT(id, true);
  }

  if (!data) {
    // No company document. Before denying, distinguish a genuinely unknown
    // tenant from a pre-entitlement production company: tenants created
    // before this layer have employees/users (and attendance, tasks, …)
    // referencing their companyId but never received a `companies` doc.
    // Regression: requireFeature() on every route returned
    // COMPANY_NOT_FOUND for all existing production employees because the
    // collection is empty in production. A companyId backed by real tenant
    // data is treated as legacy; anything else is still denied.
    let tenantKnown = false;
    try {
      const empSnap = await db
        .collection('employees')
        .where('companyId', '==', id)
        .limit(1)
        .get();
      if (!empSnap.empty) {
        tenantKnown = true;
      } else {
        const userSnap = await db
          .collection('users')
          .where('companyId', '==', id)
          .limit(1)
          .get();
        tenantKnown = !userSnap.empty;
      }
    } catch (e) {
      // FAIL CLOSED: the probe itself failing is a lookup failure, not a
      // missing tenant — callers respond 503 / use the last-good cache.
      console.error('[entitlement] legacy tenant probe failed', id, e);
      return EMPTY_ENTITLEMENT(id, true);
    }
    if (!tenantKnown) {
      return EMPTY_ENTITLEMENT(id, false);
    }
    return {
      companyId: id,
      exists: true,
      lookupFailed: false,
      name: null,
      status: 'active',
      plan: null,
      enabledFeatures: null,
      effectiveFeatures: null,
      maxUsers: null,
      isLegacy: true,
    };
  }

  const rawFeatures = data.enabledFeatures;
  const hasFeatureConfig = Array.isArray(rawFeatures);
  const enabledFeatures = hasFeatureConfig
    ? (rawFeatures as unknown[])
        .map((v) => String(v || '').trim().toLowerCase())
        .filter((v) => v.length > 0 && isKnownFeature(v))
    : null;

  const rawMax = Number(data.maxUsers);
  const maxUsers =
    hasFeatureConfig && Number.isFinite(rawMax) && rawMax > 0
      ? Math.floor(rawMax)
      : null;

  const rawStatus = String(data.status || '').trim().toLowerCase();
  const status = rawStatus === '' ? 'active' : rawStatus;

  return {
    companyId: id,
    exists: true,
    lookupFailed: false,
    name: data.name || data.companyName || null,
    status,
    plan: data.plan || null,
    enabledFeatures,
    effectiveFeatures:
      enabledFeatures === null ? null : resolveEffectiveFeatures(enabledFeatures),
    maxUsers,
    isLegacy: !hasFeatureConfig,
  };
}

/* ---------- Last-known-valid entitlement cache ---------- */

const ENT_CACHE_TTL_MS = 60_000; // 60s — rides out transient Firestore blips
const entitlementCache = new Map<
  string,
  { ent: CompanyEntitlement; at: number }
>();

/**
 * Entitlement lookup that fails closed but tolerates transient errors:
 * on a Firestore failure, returns the last successful entitlement for this
 * company if it is younger than the TTL; otherwise returns the failed result
 * (lookupFailed=true) so callers can respond 503.
 */
export async function getCompanyEntitlementSafe(
  companyId: string,
): Promise<CompanyEntitlement> {
  const ent = await getCompanyEntitlement(companyId);
  if (!ent.lookupFailed) {
    entitlementCache.set(ent.companyId, { ent, at: Date.now() });
    return ent;
  }
  const cached = entitlementCache.get(String(companyId || '').trim());
  if (cached && Date.now() - cached.at < ENT_CACHE_TTL_MS) {
    return cached.ent;
  }
  return ent;
}

/**
 * Whether a feature is usable for a company.
 * - Legacy/unconfigured companies (doc exists, no enabledFeatures) allow all.
 * - Missing companies and failed lookups DENY (fail closed).
 */
export function companyHasFeature(
  entitlement: CompanyEntitlement,
  feature: string,
): boolean {
  if (entitlement.lookupFailed) return false;
  if (!entitlement.exists) return false;
  if (entitlement.isLegacy) return true;
  if (!entitlement.effectiveFeatures) return true;
  return entitlement.effectiveFeatures.has(String(feature).toLowerCase());
}

/**
 * Count the current active users for a company.
 *
 * Counts the UNION of:
 *  - `employees` docs with companyId == X and status 'active' (or missing)
 *  - `users` docs with companyId == X, status 'active' (or missing),
 *    role != 'super_admin' / 'platform_admin' (platform admins are not
 *    tenant users)
 * deduplicated by normalized email (employee login-mirror users share the
 * employee's email, so they are counted once). Records without an email are
 * deduplicated by their document-scoped identity instead.
 */
export async function countActiveCompanyUsers(
  companyId: string,
): Promise<number> {
  const id = String(companyId || '').trim();
  if (!id) return 0;

  const isActive = (data: FirebaseFirestore.DocumentData): boolean => {
    const s = String(data.status ?? 'active')
      .trim()
      .toLowerCase();
    return s === '' || s === 'active';
  };

  const identityKey = (data: FirebaseFirestore.DocumentData, docId: string) => {
    const email = String(data.emailLower || data.email || '')
      .trim()
      .toLowerCase();
    if (email) return `email:${email}`;
    const empid = String(data.empid || data.empId || '').trim();
    if (empid) return `empid:${empid}`;
    return `doc:${docId}`;
  };

  const keys = new Set<string>();

  const empSnap = await db
    .collection('employees')
    .where('companyId', '==', id)
    .get();
  for (const d of empSnap.docs) {
    const data = d.data();
    if (isActive(data)) keys.add(identityKey(data, d.id));
  }

  const userSnap = await db
    .collection('users')
    .where('companyId', '==', id)
    .get();
  for (const d of userSnap.docs) {
    const data = d.data();
    if (!isActive(data)) continue;
    const role = String(data.role || 'employee').toLowerCase();
    if (role === 'super_admin' || role === 'platform_admin') {
      continue; // platform admins never count
    }
    keys.add(identityKey(data, d.id));
  }

  return keys.size;
}

export interface UserLimitResult {
  allowed: boolean;
  maxUsers: number | null;
  currentUsers: number;
  companyStatus: string;
  /** false => the company document does not exist */
  companyExists: boolean;
  /** true => the entitlement lookup failed; callers should return 503 */
  lookupFailed: boolean;
}

/**
 * Check whether a company may add one more user, based on its `maxUsers`
 * entitlement. Returns allowed=true for legacy/unlimited companies.
 * Fails closed: missing companies and lookup failures are never allowed.
 */
export async function checkUserLimit(
  companyId: string,
): Promise<UserLimitResult> {
  const ent = await getCompanyEntitlementSafe(companyId);

  if (ent.lookupFailed) {
    return {
      allowed: false,
      maxUsers: ent.maxUsers,
      currentUsers: 0,
      companyStatus: 'unavailable',
      companyExists: false,
      lookupFailed: true,
    };
  }

  if (!ent.exists || ent.status !== 'active') {
    return {
      allowed: false,
      maxUsers: ent.maxUsers,
      currentUsers: 0,
      companyStatus: ent.exists ? ent.status : 'missing',
      companyExists: ent.exists,
      lookupFailed: false,
    };
  }

  if (ent.maxUsers === null) {
    return {
      allowed: true,
      maxUsers: null,
      currentUsers: 0,
      companyStatus: ent.status,
      companyExists: true,
      lookupFailed: false,
    };
  }

  const currentUsers = await countActiveCompanyUsers(companyId);

  return {
    allowed: currentUsers < ent.maxUsers,
    maxUsers: ent.maxUsers,
    currentUsers,
    companyStatus: ent.status,
    companyExists: true,
    lookupFailed: false,
  };
}
