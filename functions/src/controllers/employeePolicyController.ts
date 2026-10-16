// functions/src/controllers/employeePolicyController.ts
// Employee-facing company policy read + acknowledgement (Phase 6).
//
// The versioned policy store lives in companyPolicies/<companyId>/versions/<n>
// with the company's meta doc tracking latestPublishedVersion (see
// companyPolicyController.ts). Employees only ever see the version that
// meta.latestPublishedVersion points to — never a draft.
//
// Acknowledgements live in:
//   policyAcknowledgements/<companyId>_<userId>_<policyVersion>
// where userId is the authenticated users/<docId> — the same identity the
// JWT carries and every other middleware authorizes on. companyId and
// userId come from the JWT only; body/query identity fields are ignored.
import { Request, Response } from "express";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "../config/firebase";
import { COLLECTIONS } from "../constants/collections";

const POLICIES = COLLECTIONS.COMPANY_POLICIES;
const ACKS = COLLECTIONS.POLICY_ACKNOWLEDGEMENTS;

const policyMetaRef = (companyId: string) =>
  db.collection(POLICIES).doc(companyId);

const versionRef = (companyId: string, version: number) =>
  policyMetaRef(companyId).collection("versions").doc(String(version));

const ackRef = (companyId: string, userId: string, version: number) =>
  db.collection(ACKS).doc(`${companyId}_${userId}_${version}`);

const asIso = (v: unknown): string | null => {
  if (!v) return null;
  if (v instanceof Timestamp) return v.toDate().toISOString();
  if (v instanceof Date) return v.toISOString();
  return String(v);
};

const callerIdentity = (req: Request) => {
  const u = (req as any).user;
  return {
    companyId: String(u?.companyId || "").trim(),
    userId: String(u?.userId || "").trim(),
  };
};

// Reads meta.latestPublishedVersion, then the corresponding version doc.
// Returns the published version number, or null when nothing usable exists.
async function latestPublishedVersion(
  companyId: string,
): Promise<{ version: number; data: Record<string, unknown> } | null> {
  const metaSnap = await policyMetaRef(companyId).get();
  if (!metaSnap.exists) return null;
  const latest = Number(metaSnap.data()?.latestPublishedVersion) || null;
  if (latest == null) return null;

  const vSnap = await versionRef(companyId, latest).get();
  if (!vSnap.exists) return null;
  const data = vSnap.data() as Record<string, unknown>;
  // Defensive: only a published version may be shown to employees, even if
  // meta were ever to point at a draft.
  if (data.status !== "published") return null;
  return { version: latest, data };
}

// GET /api/employee/company-policy
// Returns the latest published policy plus whether THIS employee has
// acknowledged exactly that version.
export const getEmployeeCompanyPolicy = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const { companyId, userId } = callerIdentity(req);
    if (!companyId || !userId) {
      return res.status(403).json({ error: "No company context on token" });
    }

    const published = await latestPublishedVersion(companyId);
    if (!published) {
      return res.status(200).json({
        success: true,
        hasPublishedPolicy: false,
        policy: null,
        acknowledged: true,
      });
    }

    const ackSnap = await ackRef(companyId, userId, published.version).get();
    const acknowledged =
      ackSnap.exists && ackSnap.data()?.acknowledged === true;

    return res.status(200).json({
      success: true,
      hasPublishedPolicy: true,
      policy: {
        version: published.data.version ?? published.version,
        title: published.data.title ?? "",
        content: published.data.content ?? "",
        publishedAt: asIso(published.data.publishedAt),
      },
      acknowledged,
    });
  } catch (e: any) {
    console.error("getEmployeeCompanyPolicy error:", e);
    return res
      .status(500)
      .json({ error: e.message || "failed to load company policy" });
  }
};

// POST /api/employee/company-policy/acknowledge
// body: { policyVersion } — must equal meta.latestPublishedVersion.
// Acknowledging an older published version or a draft is rejected.
export const acknowledgeCompanyPolicy = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const { companyId, userId } = callerIdentity(req);
    if (!companyId || !userId) {
      return res.status(403).json({ error: "No company context on token" });
    }

    const requested = Number(req.body?.policyVersion);
    if (!Number.isInteger(requested) || requested <= 0) {
      return res
        .status(400)
        .json({ error: "policyVersion must be a positive integer" });
    }

    const published = await latestPublishedVersion(companyId);
    if (!published) {
      return res
        .status(404)
        .json({ error: "No published policy to acknowledge" });
    }
    if (requested !== published.version) {
      return res.status(409).json({
        error: "This policy version is no longer current",
        latestPublishedVersion: published.version,
      });
    }

    const ref = ackRef(companyId, userId, published.version);
    const already = await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (snap.exists) return true;
      tx.set(ref, {
        companyId,
        employeeId: userId,
        policyVersion: published.version,
        acknowledged: true,
        acknowledgedBy: userId,
        acknowledgedAt: FieldValue.serverTimestamp(),
      });
      return false;
    });

    return res.status(already ? 200 : 201).json({
      success: true,
      acknowledged: true,
      policyVersion: published.version,
      alreadyAcknowledged: already,
    });
  } catch (e: any) {
    console.error("acknowledgeCompanyPolicy error:", e);
    return res
      .status(500)
      .json({ error: e.message || "failed to acknowledge company policy" });
  }
};
