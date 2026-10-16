// functions/src/controllers/hrRequestController.ts
// HR feature-access requests.
//
// Data separation model (do NOT collapse these):
//   companies.enabledFeatures        — company-level features chosen by the
//                                      Platform Admin ("companyAvailableFeatures")
//   hrFeatureRequests.requestedFeatures — per-HR subset requested by the HR user
//   hrFeatureRequests.approvedFeatures  — per-HR subset approved by the Platform
//                                      Admin; the ONLY source of HR dashboard
//                                      module visibility (Phase 5)
//
// Approving a request must NEVER write back to companies.enabledFeatures.
import { Request, Response } from "express";
import { db } from "../config/firebase";
import { COLLECTIONS } from "../constants/collections";
import {
  FEATURE_CATALOG,
  resolveEffectiveFeatures,
  validateFeatureSelection,
} from "../constants/features";
import { getCompanyEntitlement } from "../services/entitlementService";

const HR_REQUESTS = COLLECTIONS.HR_FEATURE_REQUESTS;
const USERS = COLLECTIONS.USERS;

export const HR_REQUEST_STATUSES = [
  "draft",
  "pending",
  "changes_requested",
  "approved",
  "rejected",
] as const;
export type HrRequestStatus = (typeof HR_REQUEST_STATUSES)[number];

/** One active request per HR user (per company). */
const requestDocId = (companyId: string, hrUserId: string) =>
  `${companyId}__${hrUserId}`;

/**
 * Effective feature set a company actually has:
 * null enabledFeatures = legacy/unconfigured company → full catalog.
 * Otherwise dependency closure over the stored list, matching
 * companyHasFeature()/requireFeature semantics.
 */
function effectiveCompanyFeatures(enabled: string[] | null): Set<string> {
  if (enabled === null) return new Set(FEATURE_CATALOG.map((f) => f.key));
  return resolveEffectiveFeatures(enabled);
}

async function loadHrUser(userId: string) {
  const snap = await db.collection(USERS).doc(userId).get();
  return snap.exists ? (snap.data() as Record<string, unknown>) : null;
}

function serializeRequest(id: string, data: Record<string, unknown>) {
  return {
    id,
    companyId: data.companyId ?? null,
    hrUserId: data.hrUserId ?? null,
    hrEmail: data.hrEmail ?? null,
    hrName: data.hrName ?? null,
    branch: data.branch ?? null,
    branchId: data.branchId ?? null,
    department: data.department ?? null,
    departmentId: data.departmentId ?? null,
    requestedFeatures: Array.isArray(data.requestedFeatures)
      ? data.requestedFeatures
      : [],
    approvedFeatures: Array.isArray(data.approvedFeatures)
      ? data.approvedFeatures
      : [],
    requestStatus: data.requestStatus ?? "pending",
    reviewComment: data.reviewComment ?? null,
    requestedAt: data.requestedAt ?? null,
    createdAt: data.createdAt ?? null,
    updatedAt: data.updatedAt ?? null,
    reviewedAt: data.reviewedAt ?? null,
    reviewedBy: data.reviewedBy ?? null,
  };
}

// GET /api/hr/features/available
// The Platform Admin-selected company features the HR user may request.
// Features not enabled for the company are NOT returned (hidden, not
// disabled) per the feature-selection rule.
export const getAvailableFeatures = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const caller = (req as any).user;
    const companyId = String(caller?.companyId || "").trim();
    if (!companyId) {
      return res.status(403).json({ error: "No company context on token" });
    }

    const ent = await getCompanyEntitlement(companyId);
    if (ent.lookupFailed) {
      return res.status(503).json({
        error: "Could not verify company entitlements. Please try again.",
      });
    }
    if (!ent.exists) {
      return res.status(403).json({ error: "Unknown company" });
    }

    const effective = effectiveCompanyFeatures(ent.enabledFeatures);
    const features = FEATURE_CATALOG.filter((f) => effective.has(f.key)).map(
      (f) => ({ key: f.key, label: f.label, requires: f.requires }),
    );

    return res.status(200).json({
      success: true,
      companyId,
      features,
    });
  } catch (e: any) {
    console.error("getAvailableFeatures error:", e);
    return res
      .status(500)
      .json({ error: e.message || "failed to load available features" });
  }
};

// GET /api/hr/feature-request
// The HR user's own request (latest state) + their branch/department from
// the users doc so the selection page can prefill.
export const getMyFeatureRequest = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const caller = (req as any).user;
    const companyId = String(caller?.companyId || "").trim();
    const hrUserId = String(caller?.userId || "").trim();
    if (!companyId || !hrUserId) {
      return res.status(403).json({ error: "No company context on token" });
    }

    const [reqSnap, hrDoc] = await Promise.all([
      db.collection(HR_REQUESTS).doc(requestDocId(companyId, hrUserId)).get(),
      loadHrUser(hrUserId),
    ]);

    const request = reqSnap.exists
      ? serializeRequest(reqSnap.id, reqSnap.data() as Record<string, unknown>)
      : null;

    return res.status(200).json({
      success: true,
      request,
      hr: {
        name: String(hrDoc?.name || hrDoc?.fullName || ""),
        email: String(hrDoc?.email || caller?.email || ""),
        branch: String(hrDoc?.branch || hrDoc?.branchName || ""),
        department: String(hrDoc?.department || hrDoc?.departmentName || ""),
      },
    });
  } catch (e: any) {
    console.error("getMyFeatureRequest error:", e);
    return res
      .status(500)
      .json({ error: e.message || "failed to load feature request" });
  }
};

// POST /api/hr/feature-request
// body: { requestedFeatures: string[], branch?, branchId?, department?, departmentId? }
//
// Creates the request (status 'pending') or resubmits a 'changes_requested'
// request. companyId/hrUserId always come from the authenticated JWT —
// never from the request body.
export const submitFeatureRequest = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const caller = (req as any).user;
    const companyId = String(caller?.companyId || "").trim();
    const hrUserId = String(caller?.userId || "").trim();
    if (!companyId || !hrUserId) {
      return res.status(403).json({ error: "No company context on token" });
    }

    const hrDoc = await loadHrUser(hrUserId);
    if (!hrDoc || String(hrDoc.role || "").toLowerCase() !== "hr") {
      return res.status(403).json({ error: "Not an HR account" });
    }

    // Branch/department: caller may adjust them on the form; fall back to
    // the values the Company Admin assigned at HR creation.
    const branch = String(
      req.body?.branch ?? hrDoc.branch ?? hrDoc.branchName ?? "",
    ).trim();
    const branchId = String(
      req.body?.branchId ?? hrDoc.branchId ?? "",
    ).trim();
    const department = String(
      req.body?.department ?? hrDoc.department ?? hrDoc.departmentName ?? "",
    ).trim();
    const departmentId = String(
      req.body?.departmentId ?? hrDoc.departmentId ?? "",
    ).trim();
    if (!branch || !department) {
      return res
        .status(400)
        .json({ error: "branch and department are required" });
    }

    // Validate against the catalog (unknown keys, dependency violations).
    const validation = validateFeatureSelection(req.body?.requestedFeatures);
    if (validation.features.length === 0) {
      return res
        .status(400)
        .json({ error: "requestedFeatures must be a non-empty array" });
    }
    if (!validation.ok) {
      return res.status(400).json({
        error: "Invalid feature selection",
        unknown: validation.unknown,
        missingDeps: validation.missingDeps,
      });
    }

    // Subset check: every requested feature must be enabled for the company.
    const ent = await getCompanyEntitlement(companyId);
    if (ent.lookupFailed) {
      return res.status(503).json({
        error: "Could not verify company entitlements. Please try again.",
      });
    }
    if (!ent.exists) {
      return res.status(403).json({ error: "Unknown company" });
    }
    const effective = effectiveCompanyFeatures(ent.enabledFeatures);
    const outsideCompany = validation.features.filter((f) => !effective.has(f));
    if (outsideCompany.length > 0) {
      return res.status(403).json({
        error: "Requested features are not enabled for your company",
        notEnabled: outsideCompany,
      });
    }

    const docId = requestDocId(companyId, hrUserId);
    const docRef = db.collection(HR_REQUESTS).doc(docId);
    const existing = await docRef.get();

    if (existing.exists) {
      const status = String(
        (existing.data() as any)?.requestStatus || "",
      ).toLowerCase();
      if (status === "pending") {
        return res
          .status(409)
          .json({ error: "A pending feature request already exists" });
      }
      if (status === "approved") {
        return res
          .status(409)
          .json({ error: "Your feature request has already been approved" });
      }
      if (status === "rejected") {
        return res.status(409).json({
          error:
            "Your feature request was rejected. Contact your Platform Admin.",
        });
      }
      // 'changes_requested' (or 'draft') → resubmission allowed.
    }

    const now = new Date();
    const doc: Record<string, unknown> = {
      companyId,
      hrUserId,
      hrEmail: String(hrDoc.email || caller?.email || ""),
      hrName: String(hrDoc.name || hrDoc.fullName || ""),
      branch,
      department,
      requestedFeatures: validation.features,
      requestStatus: "pending",
      requestedAt: now,
      updatedAt: now,
    };
    if (branchId) doc.branchId = branchId;
    if (departmentId) doc.departmentId = departmentId;

    if (existing.exists) {
      const prev = existing.data() as Record<string, unknown>;
      // Preserve the audit trail of the last review and any previously
      // approved features (changes_requested always has [] anyway).
      doc.approvedFeatures = Array.isArray(prev.approvedFeatures)
        ? prev.approvedFeatures
        : [];
      doc.reviewComment = prev.reviewComment ?? null;
      doc.reviewedAt = prev.reviewedAt ?? null;
      doc.reviewedBy = prev.reviewedBy ?? null;
      doc.createdAt = prev.createdAt ?? now;
    } else {
      doc.approvedFeatures = [];
      doc.reviewComment = null;
      doc.reviewedAt = null;
      doc.reviewedBy = null;
      doc.createdAt = now;
    }

    await docRef.set(doc);

    return res.status(existing.exists ? 200 : 201).json({
      success: true,
      request: serializeRequest(docId, doc),
      message: existing.exists
        ? "Feature request resubmitted for review"
        : "Feature request submitted for review",
    });
  } catch (e: any) {
    console.error("submitFeatureRequest error:", e);
    return res
      .status(500)
      .json({ error: e.message || "failed to submit feature request" });
  }
};

// GET /api/hr/features/approved
// The HR user's individual approved feature set — read from
// users/<hrUserId>.approvedFeatures (the authorization source of truth
// written by the Platform Admin on approval). hrUserId comes from the
// JWT, never from the request.
//
//   approvedFeatures    — the stored approved set (what the admin granted)
//   accessibleFeatures  — approved + dependency closure; this is what the
//                         backend will actually allow and what the HR
//                         dashboard should render.
export const getApprovedFeatures = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const caller = (req as any).user;
    const hrUserId = String(caller?.userId || "").trim();
    if (!hrUserId) {
      return res.status(403).json({ error: "No user context on token" });
    }

    const hrDoc = await loadHrUser(hrUserId);
    const stored = hrDoc && Array.isArray(hrDoc.approvedFeatures)
      ? (hrDoc.approvedFeatures as unknown[]).map((f) => String(f))
      : [];

    return res.status(200).json({
      success: true,
      approvedFeatures: stored,
      accessibleFeatures: Array.from(resolveEffectiveFeatures(stored)),
    });
  } catch (e: any) {
    console.error("getApprovedFeatures error:", e);
    return res
      .status(500)
      .json({ error: e.message || "failed to load approved features" });
  }
};

// GET /api/hr/modules/:feature
// Feature-gated HR module endpoint — requireHrFeature(req.params.feature)
// has already verified the caller is an HR user whose approvedFeatures
// cover this key. Returns the module descriptor; per-module data endpoints
// hang off this same guard in later work.
export const getHrModule = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  const key = String(req.params.feature || "").toLowerCase();
  const def = FEATURE_CATALOG.find((f) => f.key === key);
  if (!def) {
    return res.status(400).json({ error: "Unknown feature" });
  }
  return res.status(200).json({
    success: true,
    module: {
      key: def.key,
      label: def.label,
      requires: def.requires,
    },
  });
};
