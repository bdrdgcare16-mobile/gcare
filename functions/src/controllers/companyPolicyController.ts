// functions/src/controllers/companyPolicyController.ts
// HR-owned company policy (draft → publish, versioned).
//
// Data model — versioned so a published policy is never lost while a new
// draft is being edited (Phase 6 employee acknowledgement relies on
// "latest published version" always being retrievable):
//
//   companyPolicies/<companyId>                 meta doc:
//     { companyId, latestPublishedVersion, draftVersion,
//       createdAt, updatedAt }
//
//   companyPolicies/<companyId>/versions/<n>    version doc:
//     { companyId, version, title, content,
//       status: 'draft' | 'published',
//       createdBy, createdByEmail, updatedBy, updatedByEmail,
//       publishedBy, publishedByEmail,
//       createdAt, updatedAt, publishedAt }
//
// Rules:
//  - companyId / user identity always come from the authenticated JWT —
//    never from body or query.
//  - Saving a draft never increments the version.
//  - Editing after publish creates version n+1 as a NEW draft; the
//    previous published version stays intact until the draft is published.
//  - Only a draft can be published; publish is transactional.
//  - This is entirely independent of companies.enabledFeatures and
//    users/<hrUserId>.approvedFeatures — policy publish does NOT grant
//    any feature access.
import { Request, Response } from "express";
import { Timestamp } from "firebase-admin/firestore";
import { db } from "../config/firebase";
import { COLLECTIONS } from "../constants/collections";

const POLICIES = COLLECTIONS.COMPANY_POLICIES;

const policyMetaRef = (companyId: string) =>
  db.collection(POLICIES).doc(companyId);

const versionRef = (companyId: string, version: number) =>
  policyMetaRef(companyId).collection("versions").doc(String(version));

const asIso = (v: unknown): string | null => {
  if (!v) return null;
  if (v instanceof Timestamp) return v.toDate().toISOString();
  if (v instanceof Date) return v.toISOString();
  return String(v);
};

function serializeVersion(d: Record<string, unknown>) {
  return {
    version: d.version ?? null,
    title: d.title ?? "",
    content: d.content ?? "",
    status: d.status ?? "draft",
    createdBy: d.createdBy ?? null,
    createdByEmail: d.createdByEmail ?? null,
    updatedBy: d.updatedBy ?? null,
    updatedByEmail: d.updatedByEmail ?? null,
    publishedBy: d.publishedBy ?? null,
    publishedByEmail: d.publishedByEmail ?? null,
    createdAt: asIso(d.createdAt),
    updatedAt: asIso(d.updatedAt),
    publishedAt: asIso(d.publishedAt),
  };
}

const callerIdentity = (req: Request) => {
  const u = (req as any).user;
  return {
    companyId: String(u?.companyId || "").trim(),
    userId: String(u?.userId || "").trim(),
    email: String(u?.email || "").trim(),
  };
};

// GET /api/hr/company-policy
// Returns the HR user's working copy: the draft when one exists, else the
// latest published version. `hasPublished` tells the client whether the
// policy gate (published policy required) is satisfied.
export const getCompanyPolicy = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const { companyId } = callerIdentity(req);
    if (!companyId) {
      return res.status(403).json({ error: "No company context on token" });
    }

    const metaSnap = await policyMetaRef(companyId).get();
    const meta = metaSnap.exists ? metaSnap.data() || {} : {};
    const draftVersion = Number(meta.draftVersion) || null;
    const latestPublished = Number(meta.latestPublishedVersion) || null;

    let policy: Record<string, unknown> | null = null;
    const versionToRead = draftVersion ?? latestPublished;
    if (versionToRead != null) {
      const vSnap = await versionRef(companyId, versionToRead).get();
      if (vSnap.exists) {
        policy = serializeVersion(vSnap.data() as Record<string, unknown>);
      }
    }

    return res.status(200).json({
      success: true,
      policy,
      hasPublished: latestPublished != null,
      latestPublishedVersion: latestPublished,
    });
  } catch (e: any) {
    console.error("getCompanyPolicy error:", e);
    return res
      .status(500)
      .json({ error: e.message || "failed to load company policy" });
  }
};

// POST /api/hr/company-policy
// body: { title, content }
//  - no policy yet            → creates version 1 draft
//  - draft exists             → updates that draft in place (no version bump)
//  - published, no draft      → creates version n+1 draft; published untouched
export const saveCompanyPolicy = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const { companyId, userId, email } = callerIdentity(req);
    if (!companyId) {
      return res.status(403).json({ error: "No company context on token" });
    }

    const title = String(req.body?.title || "").trim();
    const content = String(req.body?.content || "").trim();
    if (!title || !content) {
      return res
        .status(400)
        .json({ error: "title and content are required" });
    }

    const result = await db.runTransaction(async (tx) => {
      const metaRef = policyMetaRef(companyId);
      const metaSnap = await tx.get(metaRef);
      const meta = metaSnap.exists ? metaSnap.data() || {} : {};
      const now = Timestamp.now();
      const draftVersion = Number(meta.draftVersion) || null;
      const latestPublished = Number(meta.latestPublishedVersion) || null;

      if (draftVersion != null) {
        // Update the existing draft in place — no version increment.
        const vRef = versionRef(companyId, draftVersion);
        tx.update(vRef, {
          title,
          content,
          updatedBy: userId,
          updatedByEmail: email,
          updatedAt: now,
        });
        tx.set(metaRef, { updatedAt: now }, { merge: true });
        return { version: draftVersion, created: false };
      }

      const newVersion = (latestPublished ?? 0) + 1;
      const vRef = versionRef(companyId, newVersion);
      tx.set(vRef, {
        companyId,
        version: newVersion,
        title,
        content,
        status: "draft",
        createdBy: userId,
        createdByEmail: email,
        updatedBy: userId,
        updatedByEmail: email,
        publishedBy: null,
        publishedByEmail: null,
        createdAt: now,
        updatedAt: now,
        publishedAt: null,
      });
      tx.set(
        metaRef,
        {
          companyId,
          draftVersion: newVersion,
          latestPublishedVersion: latestPublished,
          createdAt: meta.createdAt ?? now,
          updatedAt: now,
        },
        { merge: true },
      );
      return { version: newVersion, created: true };
    });

    const vSnap = await versionRef(companyId, result.version).get();
    return res.status(result.created ? 201 : 200).json({
      success: true,
      policy: serializeVersion(vSnap.data() as Record<string, unknown>),
      message: "Draft saved",
    });
  } catch (e: any) {
    console.error("saveCompanyPolicy error:", e);
    return res
      .status(500)
      .json({ error: e.message || "failed to save company policy" });
  }
};

// POST /api/hr/company-policy/publish
// Publishes the current draft. Transactional so concurrent publishes
// can't race version numbers.
export const publishCompanyPolicy = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const { companyId, userId, email } = callerIdentity(req);
    if (!companyId) {
      return res.status(403).json({ error: "No company context on token" });
    }

    const outcome = await db.runTransaction(async (tx) => {
      const metaRef = policyMetaRef(companyId);
      const metaSnap = await tx.get(metaRef);
      if (!metaSnap.exists) {
        return { code: 404 as const };
      }
      const meta = metaSnap.data() || {};
      const draftVersion = Number(meta.draftVersion) || null;
      if (draftVersion == null) {
        // Policy exists but nothing is drafted — nothing to publish.
        return { code: 409 as const };
      }

      const vRef = versionRef(companyId, draftVersion);
      const vSnap = await tx.get(vRef);
      if (!vSnap.exists) {
        return { code: 404 as const };
      }
      const v = vSnap.data() as Record<string, unknown>;
      if (v.status === "published") {
        return { code: 409 as const };
      }
      if (!String(v.title || "").trim() || !String(v.content || "").trim()) {
        return { code: 400 as const };
      }

      const now = Timestamp.now();
      tx.update(vRef, {
        status: "published",
        publishedBy: userId,
        publishedByEmail: email,
        publishedAt: now,
        updatedAt: now,
      });
      tx.set(
        metaRef,
        {
          latestPublishedVersion: draftVersion,
          draftVersion: null,
          updatedAt: now,
        },
        { merge: true },
      );
      return { code: 200 as const, version: draftVersion };
    });

    if (outcome.code === 404) {
      return res.status(404).json({ error: "No policy draft to publish" });
    }
    if (outcome.code === 409) {
      return res
        .status(409)
        .json({ error: "Policy is already published — no draft to publish" });
    }
    if (outcome.code === 400) {
      return res
        .status(400)
        .json({ error: "Policy title and content must not be empty" });
    }

    const vSnap = await versionRef(companyId, outcome.version!).get();
    return res.status(200).json({
      success: true,
      policy: serializeVersion(vSnap.data() as Record<string, unknown>),
      message: "Policy published",
    });
  } catch (e: any) {
    console.error("publishCompanyPolicy error:", e);
    return res
      .status(500)
      .json({ error: e.message || "failed to publish company policy" });
  }
};
