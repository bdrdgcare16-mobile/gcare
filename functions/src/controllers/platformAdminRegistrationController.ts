// functions/src/controllers/platformAdminRegistrationController.ts

import { FieldValue } from 'firebase-admin/firestore';
import { Request, Response } from 'express';
import { getDb, getBucket } from '../config/firebase';
import { errorResponse, successResponse } from '../common/response';
import { normEmail } from '../common/utils';
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
  'activated',
]);

const MAX_PAGE_SIZE = 50;
const DEFAULT_PAGE_SIZE = 10;

/** The only status from which a review decision may be made (3D-C). */
const REVIEWABLE_STATUS: RegistrationStatus = 'pending_approval';

/** The only status from which activation may proceed (3D-D). */
const ACTIVATABLE_STATUS: RegistrationStatus = 'approved';

/** Canonical operational organization store — see companyController.ts.
 *  `users.companyId` equals this collection's doc id. The doc-id
 *  convention is the owning admin's emailLower (same as the self-serve
 *  profile path) so the existing `findProfileDoc` fast path
 *  (`doc(adminEmailLower)`) resolves activation-provisioned profiles
 *  without any changes. */
const COMPANY_PROFILE_COL = 'companyProfile';
const USERS_COL = 'users';
const EMPLOYEES_COL = 'employees';
/**
 * Founding organization admin's employee id. Empids are free-form and
 * unique per company (employeeController scopes the check by companyId);
 * 'ADMIN001' matches the established EMP###/ADMIN### convention and is
 * guaranteed free on a freshly provisioned organization.
 */
const ORG_ADMIN_EMPID = 'ADMIN001';

/** Organization codes follow the existing `SERV###` convention
 *  (functions/src/scripts/migrateOrganizationCodes.ts). A dedicated
 *  counter document under a backend-only collection is incremented
 *  inside the provisioning transaction, and each candidate is
 *  collision-checked against existing `companyProfile.code` values so
 *  codes written before the counter existed are skipped safely. */
const ORG_CODE_COUNTER_COL = 'meta';
const ORG_CODE_COUNTER_DOC = 'organizationCodeCounter';
const ORG_CODE_PREFIX = 'SERV';
const ORG_CODE_PAD = 3;
const MAX_CODE_ATTEMPTS = 32;

const formatOrgCode = (seq: number): string =>
  `${ORG_CODE_PREFIX}${String(seq).padStart(ORG_CODE_PAD, '0')}`;

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

/** Thrown inside the activation transaction when the doc has vanished. */
class ActivationNotFoundError extends Error {
  constructor() {
    super('Registration not found');
  }
}

/** Thrown inside the activation transaction on an invalid transition or
 *  a missing provisioning prerequisite — mapped to HTTP 409. */
class ActivationConflictError extends Error {}

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

/**
 * POST /platform-admin/registrations/:id/activate  (3D-D)
 *
 * approved → activated. This is the FIRST and ONLY point where
 * organization resources are provisioned:
 *
 *   1. organization code (SERV###, transaction-safe counter + collision
 *      probe against existing companyProfile.code values)
 *   2. canonical companyProfile document (doc id = the generated
 *      internal companyId `org-<registrationId>`; reuses a persisted
 *      approvedCompanyId on retry)
 *   3. employees membership record for the admin (seed convention:
 *      admins appear in both `users` and `employees`)
 *   4. the SAME applicant users/<applicantUid> doc promoted to role
 *      'admin' with companyId/organizationCode — no new Firebase user
 *   5. enabledFeatures = requestedFeatures (approval approves exactly
 *      the requested set; nothing outside it is ever enabled)
 *   6. registration → activated + organization_activated audit event
 *
 * Everything runs in ONE Firestore transaction, so a failure leaves no
 * partial state, concurrent activations serialize (the loser sees
 * 'activated' and returns idempotently), and all reads happen before
 * all writes. Request body fields (companyId, organizationCode, role,
 * adminUid, enabledFeatures, ...) are never read.
 */
export const activateRegistration = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const id = String(req.params.id || '').trim();
    if (!id) return errorResponse(res, 'Registration ID is required', 400);

    // Identity is server-derived only — never from the request body.
    const adminId = String(req.user?.userId ?? '');
    const adminEmail = String(req.user?.email ?? '');
    const adminRole = String(req.user?.role ?? '');
    if (!adminId || adminRole !== 'platform_admin') {
      return errorResponse(res, 'Forbidden', 403);
    }

    const db = getDb();
    const regRef = db.collection(ORGANIZATION_REGISTRATIONS_COL).doc(id);

    const outcome = await db.runTransaction(async (tx) => {
      const snap = await tx.get(regRef);
      if (!snap.exists) throw new ActivationNotFoundError();
      const cur = snap.data() as OrganizationRegistration;

      // Idempotent re-entry: the same call after a successful activation
      // returns the existing provisioning result without new writes.
      if (cur.status === 'activated') {
        return {
          alreadyActivated: true,
          companyId: String(cur.approvedCompanyId ?? ''),
          organizationCode: String(cur.organizationCode ?? ''),
          enabledFeatures: (cur.enabledFeatures ?? []).filter(
            (f) => typeof f === 'string',
          ) as string[],
        };
      }
      if (cur.status !== ACTIVATABLE_STATUS) {
        throw new ActivationConflictError(
          `Application cannot be activated from status '${cur.status}'`,
        );
      }

      const applicantUid = String(cur.applicantUid || '');
      if (!applicantUid) {
        throw new ActivationConflictError(
          'Approved application has no bound applicant account',
        );
      }
      const userRef = db.collection(USERS_COL).doc(applicantUid);
      const userSnap = await tx.get(userRef);
      if (!userSnap.exists) {
        throw new ActivationConflictError(
          'Bound applicant account is missing',
        );
      }
      const userData = (userSnap.data() ?? {}) as Record<string, unknown>;
      const applicantEmail = normEmail(
        String(userData.email || cur.applicantEmail || ''),
      );

      // Feature policy: approval approves the requested set, so
      // activation enables exactly it — deduplicated, never client-set.
      const enabledFeatures = [...new Set(cur.requestedFeatures ?? [])];

      // ── Reads (all Firestore transaction reads precede writes) ──
      let organizationCode = String(cur.organizationCode || '').trim();
      let companyId = String(cur.approvedCompanyId || '').trim();
      let counterNext: number | null = null;
      const counterRef = db
        .collection(ORG_CODE_COUNTER_COL)
        .doc(ORG_CODE_COUNTER_DOC);

      if (!organizationCode) {
        const counterSnap = await tx.get(counterRef);
        let seq = Number((counterSnap.data() as any)?.next ?? 1);
        for (let i = 0; i < MAX_CODE_ATTEMPTS; i++) {
          const candidate = formatOrgCode(seq);
          const clash = await tx.get(
            db
              .collection(COMPANY_PROFILE_COL)
              .where('code', '==', candidate)
              .limit(1),
          );
          if (clash.empty) {
            organizationCode = candidate;
            counterNext = seq + 1;
            break;
          }
          seq += 1;
        }
        if (!organizationCode) {
          throw new Error('Unable to allocate a unique organization code');
        }
      }

      if (!companyId) {
        // Backend-generated internal companyId for new organizations:
        // `org-<registrationId>` is deterministic per registration (an
        // activation retry produces the same value even before
        // approvedCompanyId is persisted), collision-free (registration
        // doc ids are unique), and never the admin email nor the
        // human-readable organizationCode.
        companyId = `org-${id}`;
      }
      let profileRef = db.collection(COMPANY_PROFILE_COL).doc(companyId);
      let profileSnap = await tx.get(profileRef);
      if (
        profileSnap.exists &&
        String((profileSnap.data() as any)?.registrationId || '') !== id
      ) {
        // Defensive: the candidate doc id is already owned by a
        // different organization — walk deterministic suffixed variants
        // so we never overwrite another company's profile. Unreachable
        // in practice for `org-<registrationId>` (registration ids are
        // unique); only relevant if approvedCompanyId was seeded
        // externally.
        let suffix = 2;
        for (;;) {
          const candidate = `org-${id}-${suffix++}`;
          const candidateRef = db
            .collection(COMPANY_PROFILE_COL)
            .doc(candidate);
          const candidateSnap = await tx.get(candidateRef);
          const sameReg =
            String((candidateSnap.data() as any)?.registrationId || '') ===
            id;
          if (!candidateSnap.exists || sameReg) {
            companyId = candidate;
            profileRef = candidateRef;
            profileSnap = candidateSnap;
            break;
          }
        }
      }
      const profileAlreadyProvisioned =
        profileSnap.exists &&
        String((profileSnap.data() as any)?.registrationId || '') === id;

      // ── Writes ──
      const adminDisplayName = String(
        cur.adminContact?.fullName || userData.name || '',
      ).trim();
      const companyName = String(cur.organization?.name || '').trim();
      const officialEmail =
        normEmail(String(cur.organization?.officialEmail || '')) ||
        applicantEmail;
      const phone = String(cur.organization?.contactNumber || '').trim();
      const designation = String(cur.adminContact?.designation || '').trim();

      if (!profileAlreadyProvisioned) {
        tx.set(profileRef, {
          id: companyId,
          adminEmail: applicantEmail,
          adminEmailLower: applicantEmail,
          companyName,
          email: officialEmail,
          emailLower: officialEmail,
          phone,
          website: String(cur.organization?.website || '').trim(),
          adminName: adminDisplayName,
          designation,
          code: organizationCode,
          status: 'active',
          filled: Boolean(
            companyName &&
              officialEmail &&
              phone &&
              adminDisplayName &&
              designation,
          ),
          enabledFeatures,
          registrationId: id,
          activatedBy: adminId,
          activatedAt: FieldValue.serverTimestamp(),
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });

        // Membership mirror — admins appear in `employees` too (see
        // seedMilestone2A.ts). Auto id; the transaction keeps this
        // write atomic with the rest, so retries cannot duplicate it.
        // empid/employeeId are REQUIRED by the canonical membership
        // contract: /attendance/live and pickEmpId() read them, and a
        // missing empid reaches Flutter as JSON null and crashes the
        // Admin dashboard record parser. Per-company uniqueness is all
        // that is required (employeeController scopes empid by
        // companyId), so the founding admin always takes ADMIN001.
        const employeeRef = db.collection(EMPLOYEES_COL).doc();
        tx.set(employeeRef, {
          email: applicantEmail,
          emailLower: applicantEmail,
          name: adminDisplayName,
          fullName: adminDisplayName,
          companyId,
          role: 'admin',
          status: 'active',
          empid: ORG_ADMIN_EMPID,
          employeeId: ORG_ADMIN_EMPID,
          organizationCode,
          registrationId: id,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }

      if (counterNext !== null) {
        tx.set(
          counterRef,
          {
            next: counterNext,
            lastIssuedCode: organizationCode,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }

      // Promote the SAME applicant account — same Firebase UID, email,
      // and user doc; only the role/company linkage changes. The empid
      // fields mirror the canonical users-doc shape (firebaseLogin
      // backfills them from employees by emailLower; we set them here so
      // the first login is already complete).
      tx.update(userRef, {
        role: 'admin',
        status: 'active',
        companyId,
        organizationCode,
        empid: ORG_ADMIN_EMPID,
        empId: ORG_ADMIN_EMPID,
        employeeId: ORG_ADMIN_EMPID,
        activatedRegistrationId: id,
        activatedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      tx.update(regRef, {
        status: 'activated',
        approvedCompanyId: companyId,
        organizationCode,
        approvedFeatures: enabledFeatures,
        enabledFeatures,
        activatedAt: FieldValue.serverTimestamp(),
        activatedBy: adminId,
        activatedByEmail: adminEmail,
        provisionedAdmin: {
          uid: applicantUid,
          email: applicantEmail,
          name: adminDisplayName,
        },
        auditTrail: FieldValue.arrayUnion({
          at: new Date(),
          action: 'organization_activated',
          actor: adminId,
          note:
            `approved -> activated by platform_admin; ` +
            `organizationCode=${organizationCode}; companyId=${companyId}; ` +
            `admin=${applicantEmail || applicantUid}`,
        }),
        updatedAt: FieldValue.serverTimestamp(),
      });

      return {
        alreadyActivated: false,
        companyId,
        organizationCode,
        enabledFeatures,
      };
    });

    return successResponse(
      res,
      {
        registrationId: id,
        status: 'activated',
        alreadyActivated: outcome.alreadyActivated,
        companyId: outcome.companyId,
        organizationCode: outcome.organizationCode,
        enabledFeatures: outcome.enabledFeatures,
      },
      outcome.alreadyActivated
        ? 'Organization already activated'
        : 'Organization activated',
    );
  } catch (err: any) {
    if (err instanceof ActivationNotFoundError) {
      return errorResponse(res, err.message, 404);
    }
    if (err instanceof ActivationConflictError) {
      return errorResponse(res, err.message, 409);
    }
    console.error('activate registration error:', err);
    return errorResponse(res, err.message || 'Internal server error', 500);
  }
};

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
    // Activation context for the Activated tab card.
    organizationCode: r.organizationCode ?? null,
    activatedAt: r.activatedAt ?? null,
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
    // Provisioning record (3D-D) — null until activation. The applicant
    // uid is intentionally omitted; reviewers see safe identity only.
    provisioning:
      r.status === 'activated'
        ? {
            companyId: r.approvedCompanyId ?? null,
            organizationCode: r.organizationCode ?? null,
            activatedAt: r.activatedAt ?? null,
            activatedByEmail: r.activatedByEmail ?? null,
            approvedFeatures: r.approvedFeatures ?? [],
            enabledFeatures: r.enabledFeatures ?? [],
            admin: r.provisionedAdmin
              ? {
                  email: r.provisionedAdmin.email,
                  name: r.provisionedAdmin.name,
                }
              : null,
          }
        : null,
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

/**
 * Lifecycle/reviewer events surfaced on the Platform Admin Audit / Review
 * History page (Milestone 3D-E). Deliberately a small, closed set — the
 * low-level applicant events already in auditTrail ('draft_created',
 * 'draft_updated', 'verified_<channel>', 'documents_uploaded:...') stay in
 * the per-application detail view only, matching the existing product
 * intent for that page (see detailProjection.auditTrail).
 *
 * previousStatus/newStatus reflect the fixed transitions this controller
 * (and organizationRegistrationController) already enforces for each
 * action — they are read off this table, never inferred per-event.
 */
const LIFECYCLE_EVENTS: Record<
  string,
  { label: string; previousStatus: RegistrationStatus | null; newStatus: RegistrationStatus }
> = {
  submitted: {
    label: 'Application Submitted',
    previousStatus: null,
    newStatus: 'pending_approval',
  },
  changes_requested: {
    label: 'Changes Requested',
    previousStatus: 'pending_approval',
    newStatus: 'changes_requested',
  },
  application_resubmitted: {
    label: 'Application Resubmitted',
    previousStatus: 'changes_requested',
    newStatus: 'pending_approval',
  },
  application_approved: {
    label: 'Application Approved',
    previousStatus: 'pending_approval',
    newStatus: 'approved',
  },
  application_rejected: {
    label: 'Application Rejected',
    previousStatus: 'pending_approval',
    newStatus: 'rejected',
  },
  organization_activated: {
    label: 'Organization Activated',
    previousStatus: 'approved',
    newStatus: 'activated',
  },
};

/** Bounds the number of registration docs scanned per audit-history
 *  request. auditTrail lives inline on each doc (no subcollection), so
 *  aggregating across applications means reading application docs
 *  directly; this cap keeps a single request cheap at current scale. */
const AUDIT_HISTORY_SCAN_LIMIT = 500;

/** Normalizes a stored timestamp (Date | Firestore Timestamp | {_seconds}
 *  map) to epoch millis for sorting/matching only — never returned as-is. */
function eventTimeMs(v: unknown): number {
  if (v instanceof Date) return v.getTime();
  if (v && typeof (v as any).toMillis === 'function') {
    return (v as any).toMillis();
  }
  const secs = (v as any)?._seconds ?? (v as any)?.seconds;
  if (typeof secs === 'number') return secs * 1000;
  return 0;
}

function decisionForAction(
  action: string,
): 'approved' | 'rejected' | 'changes_requested' | null {
  if (action === 'application_approved') return 'approved';
  if (action === 'application_rejected') return 'rejected';
  if (action === 'changes_requested') return 'changes_requested';
  return null;
}

/**
 * Resolves the reviewer's EMAIL (never uid) for a decision event by
 * matching decision type + closest decidedAt among the active `review`
 * and the archived `reviewHistory`. Returns null when no match exists
 * (e.g. legacy data) rather than guessing.
 */
function resolveReviewerEmail(
  r: OrganizationRegistration,
  action: string,
  atMs: number,
): string | null {
  const decision = decisionForAction(action);
  if (!decision) return null;
  const candidates: Array<{ email: string; atMs: number }> = [];
  if (r.review?.decision === decision) {
    candidates.push({
      email: r.review.reviewerEmail,
      atMs: eventTimeMs(r.review.decidedAt),
    });
  }
  for (const h of r.reviewHistory ?? []) {
    if (h.decision === decision) {
      candidates.push({ email: h.reviewerEmail, atMs: eventTimeMs(h.decidedAt) });
    }
  }
  if (!candidates.length) return null;
  candidates.sort((a, b) => Math.abs(a.atMs - atMs) - Math.abs(b.atMs - atMs));
  return candidates[0].email || null;
}

/**
 * Safe per-event projection for the audit-history feed. `atMs` is an
 * internal sort key only and is stripped before the response is sent.
 */
function buildRegistrationEvents(d: FirebaseFirestore.DocumentSnapshot) {
  const r = d.data() as OrganizationRegistration;
  const registrationId = d.id;
  const organizationName = r.organization?.name ?? '';
  const organizationCode = r.organizationCode ?? null;
  const applicantEmail = r.adminContact?.email ?? '';

  return (r.auditTrail ?? [])
    .filter((e) => Boolean(LIFECYCLE_EVENTS[e.action]))
    .map((e) => {
      const spec = LIFECYCLE_EVENTS[e.action];
      const atMs = eventTimeMs(e.at);
      const isApplicantAction =
        e.action === 'submitted' || e.action === 'application_resubmitted';

      const actorEmail =
        e.action === 'organization_activated'
          ? r.activatedByEmail ?? null
          : isApplicantAction
            ? applicantEmail || null
            : resolveReviewerEmail(r, e.action, atMs);

      return {
        atMs,
        registrationId,
        organizationName,
        // Organization code is only meaningful once activation has
        // happened — surfaced on that event, not every prior one.
        organizationCode:
          e.action === 'organization_activated' ? organizationCode : null,
        action: e.action,
        eventLabel: spec.label,
        previousStatus: spec.previousStatus,
        newStatus: spec.newStatus,
        actorEmail,
        actorRole: isApplicantAction ? 'Applicant' : 'Platform Admin',
        note: e.note ?? null,
        revision:
          e.action === 'application_resubmitted'
            ? (e as { revision?: number }).revision ?? r.resubmissionCount ?? null
            : null,
        changedFieldsCount:
          e.action === 'application_resubmitted'
            ? (r.changedFields ?? []).length
            : null,
        at: e.at,
      };
    });
}

/**
 * GET /platform-admin/registrations/audit-history  (Milestone 3D-E)
 *
 * Aggregates lifecycle/reviewer events across organization registrations
 * for the Audit / Review History page, reusing the SAME auditTrail /
 * reviewHistory / review / activation fields the detail endpoint already
 * exposes — no second audit system, no new storage.
 *
 * Query:
 *   action   (optional filter — one of LIFECYCLE_EVENTS' keys)
 *   search   (optional, matches organization name / registration id /
 *             organization code, case-insensitive)
 *   page     (1-based), pageSize (max 50)
 *
 * Newest-first by event timestamp. Response shape mirrors listRegistrations:
 * { events, page, pageSize, hasMore }.
 */
export const getAuditHistory = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const action = String(req.query.action ?? '').trim();
    if (action && !LIFECYCLE_EVENTS[action]) {
      return errorResponse(res, 'Invalid action filter', 400);
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

    const snap = await getDb()
      .collection(ORGANIZATION_REGISTRATIONS_COL)
      .orderBy('createdAt', 'desc')
      .limit(AUDIT_HISTORY_SCAN_LIMIT)
      .get();

    let events = snap.docs.flatMap((doc) => buildRegistrationEvents(doc));

    if (action) {
      events = events.filter((e) => e.action === action);
    }
    if (search) {
      events = events.filter(
        (e) =>
          e.organizationName.toLowerCase().includes(search) ||
          e.registrationId.toLowerCase().includes(search) ||
          (e.organizationCode ?? '').toLowerCase().includes(search),
      );
    }

    events.sort((a, b) => b.atMs - a.atMs);

    const total = events.length;
    const offset = (page - 1) * pageSize;
    const pageEvents = events
      .slice(offset, offset + pageSize)
      .map(({ atMs, ...rest }) => rest);

    return successResponse(
      res,
      {
        events: pageEvents,
        page,
        pageSize,
        hasMore: offset + pageSize < total,
      },
      'Audit history retrieved',
    );
  } catch (err: any) {
    console.error('getAuditHistory error:', err);
    return errorResponse(res, err.message || 'Internal server error', 500);
  }
};

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
