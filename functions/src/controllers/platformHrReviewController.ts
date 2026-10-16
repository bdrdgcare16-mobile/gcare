// functions/src/controllers/platformHrReviewController.ts
// Platform Admin review of HR feature-access requests.
//
// Mounted under /api/platform — every route already passes
// authMiddleware + roleMiddleware(['platform_admin']) (see
// routes/platformRoutes.ts). HR, Company Admin and Employee tokens are
// rejected there before any handler runs.
//
// Hard rules enforced here:
//  - companyId / hrUserId / reviewedBy are NEVER taken from the body;
//    they come from the stored request doc and the authenticated caller.
//  - Approving a request NEVER writes companies.enabledFeatures.
//  - approvedFeatures is always a subset of the company's CURRENT
//    effective enabledFeatures (re-checked at approval time — a feature
//    removed by the Platform Admin after submission cannot be approved).
//  - The granted set is also mirrored onto users/<hrUserId>.approvedFeatures
//    so access is per-HR-user, not company-wide.
import { Request, Response } from 'express';
import { Timestamp } from 'firebase-admin/firestore';
import { db } from '../config/firebase';
import { COLLECTIONS } from '../constants/collections';
import { resolveEffectiveFeatures, FEATURE_CATALOG } from '../constants/features';
import { getCompanyEntitlement } from '../services/entitlementService';

const REQUESTS = COLLECTIONS.HR_FEATURE_REQUESTS;
const USERS = COLLECTIONS.USERS;
const COMPANIES = COLLECTIONS.COMPANIES;

const REVIEWABLE_STATUS = 'pending';
const LIST_STATUSES = new Set([
  'pending',
  'changes_requested',
  'approved',
  'rejected',
]);

const asIso = (v: unknown): string | null => {
  if (!v) return null;
  if (v instanceof Timestamp) return v.toDate().toISOString();
  if (v instanceof Date) return v.toISOString();
  const s = String(v);
  return s === 'null' ? null : s;
};

const asList = (v: unknown): string[] =>
  Array.isArray(v) ? v.map((e) => String(e)) : [];

/** Effective feature set the company currently has (dep closure applied;
 *  null stored list = legacy tenant → full catalog). */
function effectiveCompanyFeatures(enabled: string[] | null): Set<string> {
  if (enabled === null) {
    return new Set(FEATURE_CATALOG.map((f) => f.key));
  }
  return resolveEffectiveFeatures(enabled);
}

function serializeRequest(
  id: string,
  d: Record<string, unknown>,
  companyName?: string,
) {
  return {
    id,
    companyId: d.companyId ?? null,
    companyName: companyName ?? d.companyName ?? null,
    hrUserId: d.hrUserId ?? null,
    hrName: d.hrName ?? null,
    hrEmail: d.hrEmail ?? null,
    branch: d.branch ?? null,
    branchId: d.branchId ?? null,
    department: d.department ?? null,
    departmentId: d.departmentId ?? null,
    requestedFeatures: asList(d.requestedFeatures),
    approvedFeatures: asList(d.approvedFeatures),
    requestStatus: d.requestStatus ?? 'pending',
    reviewComment: d.reviewComment ?? null,
    requestedAt: asIso(d.requestedAt),
    createdAt: asIso(d.createdAt),
    updatedAt: asIso(d.updatedAt),
    reviewedAt: asIso(d.reviewedAt),
    reviewedBy: d.reviewedBy ?? null,
    reviewedByEmail: d.reviewedByEmail ?? null,
  };
}

// GET /api/platform/hr-feature-requests?status=&companyId=
// List HR feature requests for review. Defaults to all statuses;
// 'pending' is the primary review queue.
export const listHrFeatureRequests = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const status = String(req.query.status || '').trim().toLowerCase();
    const companyId = String(req.query.companyId || '').trim();

    let q: FirebaseFirestore.Query = db.collection(REQUESTS);
    if (status && LIST_STATUSES.has(status)) {
      q = q.where('requestStatus', '==', status);
    }
    if (companyId) {
      q = q.where('companyId', '==', companyId);
    }

    const snap = await q.get();

    // Resolve company display names in one pass.
    const companyIds = Array.from(
      new Set(
        snap.docs
          .map((d) => String((d.data() as any).companyId || ''))
          .filter((s) => s.length > 0),
      ),
    );
    const companyNames = new Map<string, string>();
    await Promise.all(
      companyIds.map(async (cid) => {
        try {
          const c = await db.collection(COMPANIES).doc(cid).get();
          const cd = c.data() || {};
          companyNames.set(cid, String(cd.name || cd.companyName || cid));
        } catch {
          companyNames.set(cid, cid);
        }
      }),
    );

    const requests = snap.docs
      .map((d) =>
        serializeRequest(
          d.id,
          d.data() as Record<string, unknown>,
          companyNames.get(String((d.data() as any).companyId || '')),
        ),
      )
      .sort((a, b) =>
        String(b.requestedAt || b.createdAt || '').localeCompare(
          String(a.requestedAt || a.createdAt || ''),
        ),
      );

    return res.status(200).json({ success: true, requests });
  } catch (e: any) {
    console.error('listHrFeatureRequests error:', e);
    return res
      .status(500)
      .json({ success: false, error: 'Failed to list HR feature requests' });
  }
};

// GET /api/platform/hr-feature-requests/:requestId
// Full request detail + the company's CURRENT enabledFeatures so the
// reviewer can compare "requested" vs "currently available".
export const getHrFeatureRequest = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const requestId = String(req.params.requestId || '').trim();
    const snap = await db.collection(REQUESTS).doc(requestId).get();
    if (!snap.exists) {
      return res
        .status(404)
        .json({ success: false, error: 'Feature request not found' });
    }
    const d = snap.data() as Record<string, unknown>;

    const companyId = String(d.companyId || '');
    let companyName: string | null = null;
    let companyFeatures: string[] = [];
    if (companyId) {
      const ent = await getCompanyEntitlement(companyId);
      if (ent.exists) {
        const c = await db.collection(COMPANIES).doc(companyId).get();
        const cd = c.data() || {};
        companyName = String(cd.name || cd.companyName || companyId);
        companyFeatures = Array.from(
          effectiveCompanyFeatures(ent.enabledFeatures),
        );
      }
    }

    // Enrich with the HR user's current record (branch/dept may have been
    // updated since the request was stored).
    const hrUserId = String(d.hrUserId || '');
    let hrUser: Record<string, unknown> | null = null;
    if (hrUserId) {
      const u = await db.collection(USERS).doc(hrUserId).get();
      if (u.exists) {
        const ud = u.data() as Record<string, unknown>;
        hrUser = {
          id: u.id,
          name: ud.name || ud.fullName || '',
          email: ud.email || '',
          status: ud.status || 'active',
          branch: ud.branch || ud.branchName || '',
          department: ud.department || ud.departmentName || '',
        };
      }
    }

    return res.status(200).json({
      success: true,
      request: serializeRequest(snap.id, d, companyName ?? undefined),
      company: {
        companyId,
        name: companyName,
        // Labels for the review UI come from the catalog on the client;
        // this is the authoritative current availability set.
        enabledFeatures: companyFeatures,
      },
      hrUser,
    });
  } catch (e: any) {
    console.error('getHrFeatureRequest error:', e);
    return res
      .status(500)
      .json({ success: false, error: 'Failed to load feature request' });
  }
};

type ReviewResult =
  | { ok: true; ref: FirebaseFirestore.DocumentReference; data: Record<string, unknown> }
  | { ok: false; res: Response };

/** Shared guard: doc must exist and be in 'pending' (reviewable) state. */
async function loadReviewable(
  req: Request,
  res: Response,
): Promise<ReviewResult> {
  const requestId = String(req.params.requestId || '').trim();
  const ref = db.collection(REQUESTS).doc(requestId);
  const snap = await ref.get();
  if (!snap.exists) {
    return {
      ok: false,
      res: res
        .status(404)
        .json({ success: false, error: 'Feature request not found' }),
    };
  }
  const data = snap.data() as Record<string, unknown>;
  const status = String(data.requestStatus || '').toLowerCase();
  if (status !== REVIEWABLE_STATUS) {
    return {
      ok: false,
      res: res.status(409).json({
        success: false,
        error: `Request is not pending review (current status: ${status || 'unknown'})`,
      }),
    };
  }
  return { ok: true, ref, data };
}

// POST /api/platform/hr-feature-requests/:requestId/approve
// Grants requestedFeatures to THIS HR user only. Re-validates against the
// company's CURRENT enabledFeatures — a feature removed by the Platform
// Admin after submission cannot be approved.
export const approveHrFeatureRequest = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const caller = (req as any).user;
    const loaded = await loadReviewable(req, res);
    if (!loaded.ok) return loaded.res;
    const { ref, data } = loaded;

    const companyId = String(data.companyId || '');
    const hrUserId = String(data.hrUserId || '');
    const requested = asList(data.requestedFeatures);

    const ent = await getCompanyEntitlement(companyId);
    if (ent.lookupFailed) {
      return res.status(503).json({
        success: false,
        error: 'Could not verify company entitlements. Please try again.',
      });
    }
    if (!ent.exists) {
      return res
        .status(404)
        .json({ success: false, error: 'Company no longer exists' });
    }

    const effective = effectiveCompanyFeatures(ent.enabledFeatures);
    const noLongerAvailable = requested.filter((f) => !effective.has(f));
    if (noLongerAvailable.length > 0) {
      return res.status(409).json({
        success: false,
        error:
          'Some requested features are no longer enabled for this company',
        noLongerAvailable,
      });
    }

    const now = Timestamp.now();
    await ref.update({
      requestStatus: 'approved',
      approvedFeatures: requested,
      reviewedBy: caller?.userId ?? null,
      reviewedByEmail: caller?.email ?? null,
      reviewedAt: now,
      updatedAt: now,
    });

    // Grant the approved set to this HR user only. The company document is
    // never touched — per-user access lives on the user record.
    if (hrUserId) {
      await db.collection(USERS).doc(hrUserId).set(
        {
          approvedFeatures: requested,
          featureRequestStatus: 'approved',
          updatedAt: new Date(),
        },
        { merge: true },
      );
    }

    const fresh = await ref.get();
    return res.status(200).json({
      success: true,
      request: serializeRequest(
        ref.id,
        fresh.data() as Record<string, unknown>,
      ),
      message: 'Feature request approved',
    });
  } catch (e: any) {
    console.error('approveHrFeatureRequest error:', e);
    return res
      .status(500)
      .json({ success: false, error: 'Failed to approve request' });
  }
};

// POST /api/platform/hr-feature-requests/:requestId/request-changes
// body: { reviewComment } — required. Returns the request to the HR user;
// no features are granted. HR may edit and resubmit (back to 'pending').
export const requestChangesHrFeatureRequest = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const caller = (req as any).user;
    const comment = String(req.body?.reviewComment || '').trim();
    if (!comment) {
      return res.status(400).json({
        success: false,
        error: 'reviewComment is required when requesting changes',
      });
    }

    const loaded = await loadReviewable(req, res);
    if (!loaded.ok) return loaded.res;
    const { ref } = loaded;

    const now = Timestamp.now();
    await ref.update({
      requestStatus: 'changes_requested',
      reviewComment: comment,
      reviewedBy: caller?.userId ?? null,
      reviewedByEmail: caller?.email ?? null,
      reviewedAt: now,
      updatedAt: now,
    });

    const fresh = await ref.get();
    return res.status(200).json({
      success: true,
      request: serializeRequest(
        ref.id,
        fresh.data() as Record<string, unknown>,
      ),
      message: 'Changes requested — the HR user can edit and resubmit',
    });
  } catch (e: any) {
    console.error('requestChangesHrFeatureRequest error:', e);
    return res
      .status(500)
      .json({ success: false, error: 'Failed to request changes' });
  }
};

// POST /api/platform/hr-feature-requests/:requestId/reject
// body: { reviewComment } — required. Grants nothing and clears any
// previously granted set on the user record.
export const rejectHrFeatureRequest = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const caller = (req as any).user;
    const comment = String(req.body?.reviewComment || '').trim();
    if (!comment) {
      return res.status(400).json({
        success: false,
        error: 'reviewComment is required when rejecting a request',
      });
    }

    const loaded = await loadReviewable(req, res);
    if (!loaded.ok) return loaded.res;
    const { ref, data } = loaded;

    const now = Timestamp.now();
    await ref.update({
      requestStatus: 'rejected',
      approvedFeatures: [],
      reviewComment: comment,
      reviewedBy: caller?.userId ?? null,
      reviewedByEmail: caller?.email ?? null,
      reviewedAt: now,
      updatedAt: now,
    });

    const hrUserId = String(data.hrUserId || '');
    if (hrUserId) {
      await db.collection(USERS).doc(hrUserId).set(
        {
          approvedFeatures: [],
          featureRequestStatus: 'rejected',
          updatedAt: new Date(),
        },
        { merge: true },
      );
    }

    const fresh = await ref.get();
    return res.status(200).json({
      success: true,
      request: serializeRequest(
        ref.id,
        fresh.data() as Record<string, unknown>,
      ),
      message: 'Feature request rejected',
    });
  } catch (e: any) {
    console.error('rejectHrFeatureRequest error:', e);
    return res
      .status(500)
      .json({ success: false, error: 'Failed to reject request' });
  }
};
