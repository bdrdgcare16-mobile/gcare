// functions/src/controllers/platformAdminRegistrationController.ts

import { FieldValue } from 'firebase-admin/firestore';
import { Request, Response } from 'express';
import { getDb, getBucket } from '../config/firebase';
import { errorResponse, successResponse } from '../common/response';
import {
  captureChangeRequestBaseline,
  ORGANIZATION_REGISTRATIONS_COL,
  OrganizationRegistration,
  REGISTRATION_DOC_FIELDS,
  RegistrationStatus,
} from '../models/organizationRegistration';

/**
 * Platform Admin review API for organization registrations.
 *
 * Every handler here assumes authMiddleware + roleMiddleware(['platform_admin'])
 * have already run (see platformAdminRegistrationRoutes). The applicant
 * resume credential is a random token, not a JWT, so it can never satisfy
 * authMiddleware — resume holders cannot reach these endpoints.
 *
 * Milestone 3D-C adds review DECISIONS (approve / reject / request-changes).
 * Approval means REVIEW APPROVED ONLY — it never creates an organization
 * code, companyProfile, company, Admin account, or enables features.
 * Reviewer identity is always derived from req.user (the authenticated
 * JWT) — request bodies can carry comments/reasons, never identity or role.
 */

const VALID_STATUSES: ReadonlySet<string> = new Set<RegistrationStatus>([
  'draft',
  'submitted',
  'pending_verification',
  'pending_approval',
  'changes_requested',
  'approved',
  'rejected',
]);

const MAX_PAGE_SIZE = 50;
const DEFAULT_PAGE_SIZE = 10;

/** The only status from which a review decision may be made (3D-C). */
const REVIEWABLE_STATUS: RegistrationStatus = 'pending_approval';

/** Thrown inside the review transaction when the doc has vanished. */
class ReviewNotFoundError extends Error {
  constructor() {
    super('Registration not found');
  }
}

/** Thrown inside the review transaction on an invalid/already-made
 *  transition — mapped to HTTP 409 so the second of two concurrent
 *  reviewers always loses cleanly. */
class ReviewConflictError extends Error {
  constructor(public readonly currentStatus: string) {
    super(
      `Application cannot be reviewed from status '${currentStatus}'`,
    );
  }
}

interface ReviewDecisionSpec {
  action: 'approve' | 'reject' | 'request-changes';
  newStatus: RegistrationStatus;
  auditEvent: string;
  /** Body field that must be non-empty for this action, if any. */
  requiredField?: 'reason' | 'message';
}

const REVIEW_DECISIONS: Record<string, ReviewDecisionSpec> = {
  approve: {
    action: 'approve',
    newStatus: 'approved',
    auditEvent: 'application_approved',
  },
  reject: {
    action: 'reject',
    newStatus: 'rejected',
    auditEvent: 'application_rejected',
    requiredField: 'reason',
  },
  'request-changes': {
    action: 'request-changes',
    newStatus: 'changes_requested',
    auditEvent: 'changes_requested',
    requiredField: 'message',
  },
};

/**
 * Reads ONLY the free-text inputs a reviewer is allowed to send. Role and
 * reviewer identity come exclusively from the JWT — they are never read
 * from the request body.
 */
function reviewBody(
  req: Request,
  spec: ReviewDecisionSpec,
): { text: string } | { error: string } {
  const body = (req.body ?? {}) as Record<string, unknown>;
  const text = String(
    body[spec.requiredField ?? 'comment'] ?? body.comment ?? '',
  ).trim();
  if (spec.requiredField && !text) {
    const label =
      spec.requiredField === 'reason'
        ? 'A rejection reason is required'
        : 'A message describing the required changes is required';
    return { error: label };
  }
  if (text.length > 4000) {
    return { error: 'Review text is too long (max 4000 characters)' };
  }
  return { text };
}

/**
 * POST approve / reject / request-changes — the shared decision handler.
 *
 * The whole decision runs in one Firestore transaction: the doc is
 * re-read inside it, so a stale or concurrent reviewer sees the persisted
 * status and gets 409 — two reviewers can never record conflicting
 * decisions, and the audit entry is appended exactly once.
 */
async function applyReviewDecision(
  req: Request,
  res: Response,
  spec: ReviewDecisionSpec,
): Promise<Response> {
  try {
    const id = String(req.params.id || '').trim();
    if (!id) return errorResponse(res, 'Registration ID is required', 400);

    const parsed = reviewBody(req, spec);
    if ('error' in parsed) return errorResponse(res, parsed.error, 400);
    const { text } = parsed;

    // Identity is server-derived only.
    const reviewerId = String(req.user?.userId ?? '');
    const reviewerEmail = String(req.user?.email ?? '');
    const reviewerRole = String(req.user?.role ?? '');
    if (!reviewerId || reviewerRole !== 'platform_admin') {
      return errorResponse(res, 'Forbidden', 403);
    }

    const docRef = getDb().collection(ORGANIZATION_REGISTRATIONS_COL).doc(id);

    await getDb().runTransaction(async (tx) => {
      const snap = await tx.get(docRef);
      if (!snap.exists) throw new ReviewNotFoundError();
      const cur = snap.data() as OrganizationRegistration;
      if (cur.status !== REVIEWABLE_STATUS) {
        throw new ReviewConflictError(cur.status);
      }

      const review: OrganizationRegistration['review'] = {
        reviewerId,
        reviewerEmail,
        decidedAt: FieldValue.serverTimestamp(),
        decision: spec.newStatus as 'approved' | 'rejected' | 'changes_requested',
        ...(text ? { note: text } : {}),
        ...(spec.requiredField === 'reason' ? { reasons: [text] } : {}),
      };

      tx.update(docRef, {
        status: spec.newStatus,
        reviewedAt: FieldValue.serverTimestamp(),
        reviewedBy: reviewerId,
        reviewerRole,
        review,
        // Capture a sanitized baseline for the resubmission diff. Each
        // request-changes cycle refreshes it, so the next diff compares
        // against THIS request's snapshot (revision 2 → 3 keeps working).
        ...(spec.action === 'request-changes'
          ? { changeRequestBaseline: captureChangeRequestBaseline(cur) }
          : {}),
        ...(spec.requiredField === 'reason'
          ? { reviewReason: text }
          : spec.requiredField === 'message'
            ? { changeRequestMessage: text }
            : spec.action === 'approve' && text
              ? { reviewComment: text }
              : {}),
        auditTrail: FieldValue.arrayUnion({
          at: new Date(),
          action: spec.auditEvent,
          actor: reviewerId,
          note: text || `${spec.action} by platform_admin`,
        }),
        updatedAt: FieldValue.serverTimestamp(),
      });
    });

    return successResponse(
      res,
      {
        registrationId: id,
        status: spec.newStatus,
        decision: spec.newStatus,
      },
      spec.action === 'approve'
        ? 'Application approved'
        : spec.action === 'reject'
          ? 'Application rejected'
          : 'Changes requested',
    );
  } catch (err: any) {
    if (err instanceof ReviewNotFoundError) {
      return errorResponse(res, err.message, 404);
    }
    if (err instanceof ReviewConflictError) {
      return errorResponse(res, err.message, 409);
    }
    console.error(`${spec.action} registration error:`, err);
    return errorResponse(res, err.message || 'Internal server error', 500);
  }
}

/** POST /platform-admin/registrations/:id/approve */
export const approveRegistration = async (
  req: Request,
  res: Response,
): Promise<Response> => applyReviewDecision(req, res, REVIEW_DECISIONS.approve);

/** POST /platform-admin/registrations/:id/reject */
export const rejectRegistration = async (
  req: Request,
  res: Response,
): Promise<Response> => applyReviewDecision(req, res, REVIEW_DECISIONS.reject);

/** POST /platform-admin/registrations/:id/request-changes */
export const requestRegistrationChanges = async (
  req: Request,
  res: Response,
): Promise<Response> =>
  applyReviewDecision(req, res, REVIEW_DECISIONS['request-changes']);

function storageGuardError(): string | null {
  // Never let a DEV/emulator request fall through to the real bucket.
  if (
    process.env.FUNCTIONS_EMULATOR === 'true' &&
    !process.env.STORAGE_EMULATOR_HOST &&
    !process.env.FIREBASE_STORAGE_EMULATOR_HOST
  ) {
    return 'Storage emulator is not running — DEV document access is blocked';
  }
  return null;
}

/** List projection — summary fields only, no credentials or internals. */
function listItem(d: FirebaseFirestore.DocumentSnapshot) {
  const r = d.data() as OrganizationRegistration;
  return {
    registrationId: d.id,
    status: r.status,
    organizationName: r.organization?.name ?? '',
    organizationType: r.organization?.type ?? '',
    adminContact: {
      fullName: r.adminContact?.fullName ?? '',
      designation: r.adminContact?.designation ?? '',
      email: r.adminContact?.email ?? '',
      mobile: r.adminContact?.mobile ?? '',
    },
    // Requested features only — nothing approved or enabled exists yet.
    requestedFeatures: r.requestedFeatures ?? [],
    submittedAt: r.submittedAt ?? null,
    // Resubmission context for the list card (RESUBMITTED • REVISION n).
    resubmissionCount: r.resubmissionCount ?? 0,
    resubmittedAt: r.resubmittedAt ?? null,
    changedFieldsCount: (r.changedFields ?? []).length,
    createdAt: r.createdAt ?? null,
  };
}

/**
 * Detail projection — the full application minus anything a reviewer must
 * never see. `resumeTokenHash`, `storagePath` internals and OTP state are
 * excluded; documents are fetched byte-wise through the document endpoint.
 */
function detailProjection(d: FirebaseFirestore.DocumentSnapshot) {
  const r = d.data() as OrganizationRegistration;
  return {
    registrationId: d.id,
    status: r.status,
    organization: r.organization,
    requestedFeatures: r.requestedFeatures ?? [],
    adminContact: r.adminContact
      ? {
          fullName: r.adminContact.fullName,
          designation: r.adminContact.designation,
          email: r.adminContact.email,
          mobile: r.adminContact.mobile,
        }
      : null,
    verification: r.verification ?? {},
    documents: Object.fromEntries(
      Object.entries(r.documents ?? {}).map(([k, v]) => [
        k,
        {
          field: v.field,
          originalName: v.originalName,
          contentType: v.contentType,
          size: v.size,
          uploadedAt: v.uploadedAt,
        },
      ]),
    ),
    currentStep: r.currentStep,
    maxCompletedStep: r.maxCompletedStep,
    submittedAt: r.submittedAt ?? null,
    declarationAccepted: r.declarationAccepted ?? false,
    declarationAcceptedAt: r.declarationAcceptedAt ?? null,
    resubmissionCount: r.resubmissionCount ?? 0,
    resubmittedAt: r.resubmittedAt ?? null,
    // Server-computed diff vs the request-changes baseline — labels and
    // reviewable values only; no storage paths or credential material.
    changedFields: (r.changedFields ?? []).map((c) => ({
      field: c.field,
      label: c.label,
      changeType: c.changeType,
      oldValue: c.oldValue ?? null,
      newValue: c.newValue ?? null,
      added: c.added ?? [],
      removed: c.removed ?? [],
    })),
    review: r.review ?? null,
    // Prior decisions archived on resubmission — history is never lost.
    reviewHistory: (r.reviewHistory ?? []).map((h) => ({
      decision: h.decision,
      reasons: h.reasons ?? [],
      note: h.note ?? null,
      decidedAt: h.decidedAt ?? null,
      reviewerEmail: h.reviewerEmail ?? '',
    })),
    organizationCode: r.organizationCode ?? null,
    auditTrail: (r.auditTrail ?? []).map((e) => ({
      at: e.at,
      action: e.action,
      actor: e.actor ?? '',
      note: e.note ?? '',
    })),
    createdAt: r.createdAt ?? null,
    updatedAt: r.updatedAt ?? null,
  };
}

const VALID_SORTS: ReadonlySet<string> = new Set([
  'createdAt',
  'submittedAt',
]);

/**
 * GET /platform-admin/registrations
 * Query:
 *   status   (optional filter)
 *   search   (optional organization-name prefix, case-insensitive)
 *   sort     'createdAt' (default) | 'submittedAt' — both DESC
 *   page     (1-based), pageSize (max 50)
 *
 * Default ordering is createdAt desc so unsubmitted drafts are listed too
 * (submittedAt is absent on drafts and would silently exclude them).
 * While searching, ordering is by organization.nameLower ASC (Firestore
 * requires ordering by the range field) — the sort param is ignored.
 */
export const listRegistrations = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const status = String(req.query.status ?? '').trim();
    if (status && !VALID_STATUSES.has(status)) {
      return errorResponse(res, 'Invalid status filter', 400);
    }
    const sort = String(req.query.sort ?? 'createdAt').trim();
    if (!VALID_SORTS.has(sort)) {
      return errorResponse(res, 'Invalid sort field', 400);
    }
    const search = String(req.query.search ?? '')
      .trim()
      .toLowerCase()
      .slice(0, 80);

    const page = Math.max(1, Math.floor(Number(req.query.page) || 1));
    const pageSize = Math.min(
      MAX_PAGE_SIZE,
      Math.max(1, Math.floor(Number(req.query.pageSize) || DEFAULT_PAGE_SIZE)),
    );

    let query: FirebaseFirestore.Query = getDb().collection(
      ORGANIZATION_REGISTRATIONS_COL,
    );
    if (status) {
      query = query.where('status', '==', status);
    }
    if (search) {
      // Organization name prefix search. Composite index required when
      // combined with status: (status ASC, organization.nameLower ASC).
      query = query
        .where('organization.nameLower', '>=', search)
        .where('organization.nameLower', '<=', `${search}\uf8ff`)
        .orderBy('organization.nameLower');
    } else {
      // Composite index required when combined with status:
      // (status ASC, <sort> DESC).
      query = query.orderBy(sort, 'desc');
    }

    // Fetch one extra row to determine whether a next page exists without
    // needing a separate count() aggregation query.
    const snap = await query
      .offset((page - 1) * pageSize)
      .limit(pageSize + 1)
      .get();

    const items = snap.docs.slice(0, pageSize).map(listItem);
    return successResponse(
      res,
      {
        registrations: items,
        page,
        pageSize,
        hasMore: snap.docs.length > pageSize,
      },
      'Registrations retrieved',
    );
  } catch (err: any) {
    console.error('listRegistrations error:', err);
    return errorResponse(res, err.message || 'Internal server error', 500);
  }
};

/**
 * GET /platform-admin/registrations/:id
 * Full application detail for the reviewer — read-only.
 */
export const getRegistrationForReview = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const id = String(req.params.id || '').trim();
    if (!id) return errorResponse(res, 'Registration ID is required', 400);

    const doc = await getDb()
      .collection(ORGANIZATION_REGISTRATIONS_COL)
      .doc(id)
      .get();
    if (!doc.exists) {
      return errorResponse(res, 'Registration not found', 404);
    }
    return successResponse(
      res,
      { registration: detailProjection(doc) },
      'Registration retrieved',
    );
  } catch (err: any) {
    console.error('getRegistrationForReview error:', err);
    return errorResponse(res, err.message || 'Internal server error', 500);
  }
};

/**
 * GET /platform-admin/registrations/:id/documents/:field
 * Streams a private registration document through the backend. The storage
 * path is resolved from server-side metadata — the client supplies only the
 * document field name, so arbitrary paths can never be requested. No public
 * URLs or signed URLs are generated (the emulator lacks signing credentials).
 */
export const getRegistrationDocumentForReview = async (
  req: Request,
  res: Response,
): Promise<Response | void> => {
  try {
    const guard = storageGuardError();
    if (guard) return errorResponse(res, guard, 503);

    const id = String(req.params.id || '').trim();
    const field = String(req.params.field || '').trim();
    if (!id) return errorResponse(res, 'Registration ID is required', 400);
    if (!REGISTRATION_DOC_FIELDS.has(field)) {
      return errorResponse(res, 'Unknown document field', 400);
    }

    const doc = await getDb()
      .collection(ORGANIZATION_REGISTRATIONS_COL)
      .doc(id)
      .get();
    if (!doc.exists) {
      return errorResponse(res, 'Registration not found', 404);
    }

    const meta = (doc.data() as OrganizationRegistration).documents?.[field];
    if (!meta) return errorResponse(res, 'Document not found', 404);

    const [bytes] = await getBucket().file(meta.storagePath).download();
    res.setHeader(
      'Content-Type',
      meta.contentType || 'application/octet-stream',
    );
    res.setHeader(
      'Content-Disposition',
      `inline; filename="${meta.originalName}"`,
    );
    res.setHeader('Cache-Control', 'private, no-store');
    res.send(bytes);
    return res;
  } catch (err: any) {
    console.error('getRegistrationDocumentForReview error:', err);
    return errorResponse(res, err.message || 'Internal server error', 500);
  }
};
