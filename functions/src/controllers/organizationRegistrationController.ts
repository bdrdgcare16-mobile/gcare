// functions/src/controllers/organizationRegistrationController.ts

import { Request, Response } from 'express';
import { createHash, randomBytes, timingSafeEqual } from 'crypto';
import { v4 as uuidv4 } from 'uuid';
import { FieldValue } from 'firebase-admin/firestore';
import { getDb, getBucket } from '../config/firebase';
import { errorResponse, successResponse } from '../common/response';
import {
  CANONICAL_FEATURES,
  CLIENT_FORBIDDEN_FIELDS,
  computeChangedFields,
  EDITABLE_STATUSES,
  ORGANIZATION_REGISTRATIONS_COL,
  OrganizationRegistration,
  RegistrationDocumentMeta,
  REGISTRATION_DOC_FIELDS,
  REGISTRATION_DRAFT_TTL_MS,
  REQUIRED_DOC_FIELDS,
  RESUME_REVOKED_STATUSES,
  SUBMITTABLE_STATUSES,
} from '../models/organizationRegistration';
import {
  channelDestination,
  clearOtp,
  confirmOtp,
  issueOtp,
  OtpError,
  requiredChannels,
  VerificationChannel,
  VERIFICATION_CHANNELS,
} from '../services/registrationVerificationService';
import {
  sendEmailOtp,
  sendSmsOtp,
} from '../services/registrationDeliveryService';
import * as path from 'path';

const RESUME_HEADER = 'x-registration-resume-token';

// ── Resume credential ────────────────────────────────────────────────────────
//
// The registration document ID alone never grants access. A 256-bit random
// resume token is issued once at draft creation; only its SHA-256 hash is
// stored. The token is returned exactly once, sent via the
// `x-registration-resume-token` header on subsequent requests, and is never
// logged.

function hashResumeToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}

function tokensEqual(a: string, b: string): boolean {
  const ab = Buffer.from(a, 'utf8');
  const bb = Buffer.from(b, 'utf8');
  return ab.length === bb.length && timingSafeEqual(ab, bb);
}

function getResumeToken(req: Request): string {
  return String(req.header(RESUME_HEADER) || '').trim();
}

// ── Validation ───────────────────────────────────────────────────────────────

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const WEBSITE_RE = /^(https?:\/\/)?[\w-]+(\.[\w-]+)+(\/.*)?$/;
// Organization contact numbers may be landlines (STD codes, punctuation).
const CONTACT_RE = /^[+0-9][0-9\s\-()]{6,19}$/;
// Authorized HR/Admin mobile: Indian 10-digit mobile format.
const MOBILE_RE = /^[6-9][0-9]{9}$/;
const REPEATED_DIGIT_RE = /^(\d)\1{9}$/;

const norm = (v: unknown): string => String(v ?? '').trim();

function validateOrganization(
  raw: any,
  { partial = false }: { partial?: boolean } = {},
): {
  errors: string[];
  value?: Omit<OrganizationRegistration['organization'], 'nameLower' | 'officialEmailLower'>;
} {
  const errors: string[] = [];
  const o = raw || {};

  const name = norm(o.name);
  const type = norm(o.type);
  const industry = norm(o.industry);
  const address = norm(o.registeredAddress);
  const officialEmail = norm(o.officialEmail).toLowerCase();
  const contactNumber = norm(o.contactNumber);
  const website = norm(o.website);
  const gstNumber = norm(o.gstNumber);
  const cinNumber = norm(o.cinNumber);

  // In partial (draft) mode, required-field completeness is enforced only
  // at submission; here provided values must still be well-formed.
  if (!partial) {
    if (!name) errors.push('organization.name is required');
    if (!type) errors.push('organization.type is required');
    if (!industry) errors.push('organization.industry is required');
    if (!address) errors.push('organization.registeredAddress is required');
    if (!officialEmail) {
      errors.push('organization.officialEmail must be a valid email address');
    }
    if (!contactNumber) {
      errors.push('organization.contactNumber is not a valid contact number');
    }
  }

  const employeeCount =
    o.employeeCount === '' || o.employeeCount === undefined
      ? 0
      : Number(o.employeeCount);
  if (!Number.isInteger(employeeCount) || employeeCount < 0) {
    errors.push('organization.employeeCount must be a non-negative integer');
  }
  const branchCount =
    o.branchCount === '' || o.branchCount === undefined
      ? 0
      : Number(o.branchCount);
  if (!Number.isInteger(branchCount) || branchCount < 0) {
    errors.push('organization.branchCount must be a non-negative integer');
  }

  if (officialEmail && !EMAIL_RE.test(officialEmail)) {
    errors.push('organization.officialEmail must be a valid email address');
  }
  if (contactNumber && !CONTACT_RE.test(contactNumber)) {
    errors.push('organization.contactNumber is not a valid contact number');
  }
  if (website && !WEBSITE_RE.test(website)) {
    errors.push('organization.website is not a valid URL');
  }

  if (errors.length) return { errors };

  return {
    errors,
    value: {
      name,
      type,
      industry,
      employeeCount,
      branchCount,
      registeredAddress: address,
      officialEmail,
      contactNumber,
      ...(website ? { website } : {}),
      ...(gstNumber ? { gstNumber } : {}),
      ...(cinNumber ? { cinNumber } : {}),
    },
  };
}

function validateAdminContact(
  raw: any,
  { partial = false }: { partial?: boolean } = {},
): {
  errors: string[];
  value?: Omit<OrganizationRegistration['adminContact'], 'emailLower'>;
} {
  const errors: string[] = [];
  const a = raw || {};

  const fullName = norm(a.fullName);
  const designation = norm(a.designation);
  const email = norm(a.email).toLowerCase();
  const mobile = norm(a.mobile);

  if (!partial) {
    if (!fullName) errors.push('adminContact.fullName is required');
    if (!designation) errors.push('adminContact.designation is required');
    if (!email) {
      errors.push('adminContact.email must be a valid email address');
    }
    if (!mobile) {
      errors.push('adminContact.mobile must be a valid 10-digit mobile number');
    }
  }

  if (email && !EMAIL_RE.test(email)) {
    errors.push('adminContact.email must be a valid email address');
  }
  // A provided mobile must satisfy the Indian 10-digit format.
  if (mobile && (!MOBILE_RE.test(mobile) || REPEATED_DIGIT_RE.test(mobile))) {
    errors.push('adminContact.mobile must be a valid 10-digit mobile number');
  }

  if (errors.length) return { errors };
  return { errors, value: { fullName, designation, email, mobile } };
}

function validateRequestedFeatures(raw: any): {
  errors: string[];
  value: string[];
} {
  if (raw === undefined || raw === null) return { errors: [], value: [] };
  if (!Array.isArray(raw)) {
    return { errors: ['requestedFeatures must be an array'], value: [] };
  }
  const ids = raw.map((f) => norm(f));
  const invalid = ids.filter((id) => !CANONICAL_FEATURES.has(id));
  if (invalid.length) {
    return {
      errors: [`Unknown feature IDs: ${invalid.join(', ')}`],
      value: [],
    };
  }
  return { errors: [], value: [...new Set(ids)] };
}

function validateStep(
  raw: any,
  name: string,
  min = 0,
): { errors: string[]; value: number } {
  const n = Number(raw ?? min);
  // Steps: 0 organization, 1 features, 2 admin contact, 3 verification,
  // 4 documents, 5 review & submit.
  if (!Number.isInteger(n) || n < min || n > 5) {
    return {
      errors: [`${name} must be an integer between ${min} and 5`],
      value: min,
    };
  }
  return { errors: [], value: n };
}

/** Any client-supplied approval/control field is rejected outright. */
function forbiddenFieldErrors(body: any): string[] {
  if (!body || typeof body !== 'object') return [];
  return Object.keys(body).filter((k) => CLIENT_FORBIDDEN_FIELDS.has(k))
    .map((k) => `Field '${k}' cannot be set by the applicant`);
}

// ── Credential check ─────────────────────────────────────────────────────────

/**
 * Applicant credential check (3D-C follow-up).
 *
 * A registration bound to an authenticated applicant accepts EITHER:
 *   - the applicant's own SERV JWT (authoritative — issued from verified
 *     Firebase identity; works across devices without a resume token), or
 *   - the device-local resume token (legacy fallback).
 *
 * An authenticated caller whose identity does NOT match the binding is
 * rejected with 403 outright — even when they also present a valid resume
 * token. Legacy unbound drafts remain token-only.
 *
 * Returns true when authorized; otherwise writes the error response.
 */
function checkApplicantCredential(
  req: Request,
  res: Response,
  data: OrganizationRegistration,
): boolean {
  const boundUid = String(data.applicantUid || '');
  const boundEmail = String(data.applicantEmail || '').toLowerCase();
  const user = req.user;
  if (user && boundUid) {
    const uidMatch = String(user.userId) === boundUid;
    const emailMatch =
      !!boundEmail && String(user.email || '').toLowerCase() === boundEmail;
    if (uidMatch || emailMatch) return true;
    errorResponse(
      res,
      'This application belongs to a different applicant account',
      403,
    );
    return false;
  }
  const presented = getResumeToken(req);
  const storedHash = String(data.resumeTokenHash || '');
  if (
    !presented ||
    !storedHash ||
    !tokensEqual(hashResumeToken(presented), storedHash)
  ) {
    errorResponse(res, 'Invalid resume credential', 401);
    return false;
  }
  return true;
}

/**
 * Loads a registration by ID and verifies the presented resume token.
 * Returns the Firestore doc on success, or null after sending the response.
 */
async function loadAuthorizedRegistration(
  req: Request,
  res: Response,
  options: { allowSubmitted?: boolean } = {},
): Promise<FirebaseFirestore.DocumentSnapshot | null> {
  const id = String(req.params.id || '').trim();
  if (!id) {
    errorResponse(res, 'Registration ID is required', 400);
    return null;
  }

  const doc = await getDb()
    .collection(ORGANIZATION_REGISTRATIONS_COL)
    .doc(id)
    .get();

  if (!doc.exists) {
    errorResponse(res, 'Registration not found', 404);
    return null;
  }

  const data = doc.data() as OrganizationRegistration;

  const expiresAt =
    data.expiresAt instanceof Date
      ? data.expiresAt
      : (data.expiresAt as any)?.toDate?.() ?? null;
  if (expiresAt && expiresAt.getTime() < Date.now()) {
    errorResponse(res, 'This registration draft has expired', 410);
    return null;
  }

  if (!options.allowSubmitted && RESUME_REVOKED_STATUSES.has(data.status)) {
    // Once submitted/approved/rejected, drafts are no longer editable or
    // resumable — the status endpoint remains available.
    errorResponse(res, 'Registration no longer accepts changes', 403);
    return null;
  }

  if (!checkApplicantCredential(req, res, data)) return null;

  return doc;
}

/** Public projection — never includes resumeTokenHash or audit internals. */
function publicDraft(doc: FirebaseFirestore.DocumentSnapshot) {
  const d = doc.data() as OrganizationRegistration;
  return {
    registrationId: doc.id,
    status: d.status,
    organization: d.organization,
    requestedFeatures: d.requestedFeatures,
    adminContact: d.adminContact,
    currentStep: d.currentStep,
    maxCompletedStep: d.maxCompletedStep,
    verification: d.verification ?? {},
    documents: Object.fromEntries(
      Object.entries(d.documents ?? {}).map(([k, v]) => [
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
  };
}

// ── Handlers ─────────────────────────────────────────────────────────────────

/**
 * POST /org-registration/draft
 * Creates a new draft application. Issues the resume token ONCE.
 *
 * 3D-C follow-up: requires an authenticated org_applicant. The
 * application is bound to the verified JWT identity
 * (applicantUid/applicantEmail) — the request body can never set those.
 * If the applicant already owns an active application, it is returned
 * instead of creating a duplicate.
 */
export const createRegistrationDraft = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const applicant = req.user;
    if (!applicant) {
      return errorResponse(res, 'Applicant sign-in is required', 401);
    }
    if (String(applicant.role || '').toLowerCase() !== 'org_applicant') {
      return errorResponse(
        res,
        'Only an organization applicant may create an application',
        403,
      );
    }

    const forbidden = forbiddenFieldErrors(req.body);
    if (forbidden.length) return errorResponse(res, forbidden.join('; '), 400);

    // Draft mode: provided values are validated; required-field completeness
    // is enforced at submission, not during incremental drafting.
    const orgCheck = validateOrganization(req.body?.organization, {
      partial: true,
    });
    const adminCheck = validateAdminContact(req.body?.adminContact, {
      partial: true,
    });
    const featuresCheck = validateRequestedFeatures(
      req.body?.requestedFeatures,
    );
    const stepCheck = validateStep(req.body?.currentStep, 'currentStep');
    const maxStepCheck = validateStep(
      req.body?.maxCompletedStep ?? -1,
      'maxCompletedStep',
      -1,
    );

    const errors = [
      ...orgCheck.errors,
      ...adminCheck.errors,
      ...featuresCheck.errors,
      ...stepCheck.errors,
      ...maxStepCheck.errors,
    ];
    if (errors.length) return errorResponse(res, errors.join('; '), 400);

    const org = orgCheck.value!;
    const admin = adminCheck.value!;
    const nameLower = org.name.toLowerCase();
    const emailLower = org.officialEmail.toLowerCase();
    const adminEmailLower = admin.email.toLowerCase();

    // Duplicate identity rule: the organization's official email is the
    // dedup key at draft stage. Organization NAME alone is not an identity —
    // distinct organizations can legitimately share a name, so name
    // collisions are resolved at platform-admin review, not here.
    const col = getDb().collection(ORGANIZATION_REGISTRATIONS_COL);

    // One ACTIVE application per applicant — if one exists (in any
    // non-terminal state), return it so the client can resume instead of
    // creating a duplicate. The resume token is intentionally NOT
    // re-issued — the bound JWT already authorizes access.
    const owned = await col
      .where('applicantUid', '==', String(applicant.userId))
      .get();
    const active = owned.docs.find((d) => {
      const s = (d.data() as OrganizationRegistration).status;
      return s !== 'rejected' && s !== 'approved' && s !== 'activated';
    });
    if (active) {
      const ad = active.data() as OrganizationRegistration;
      return successResponse(
        res,
        {
          registrationId: active.id,
          status: ad.status,
          currentStep: ad.currentStep,
          alreadyExists: true,
        },
        'Existing application found',
        200,
      );
    }

    if (emailLower) {
      const dup = await col
        .where('organization.officialEmailLower', '==', emailLower)
        .get();
      const conflict = dup.docs.find((d) => {
        const s = (d.data() as OrganizationRegistration).status;
        return s !== 'rejected' && s !== 'approved';
      });
      if (conflict) {
        return errorResponse(
          res,
          'An application already exists for this organization email',
          409,
        );
      }
    }

    const id = uuidv4();
    const resumeToken = randomBytes(32).toString('base64url');
    const expiresAt = new Date(Date.now() + REGISTRATION_DRAFT_TTL_MS);

    const record: OrganizationRegistration = {
      applicationId: id,
      status: 'draft',
      organization: { ...org, nameLower, officialEmailLower: emailLower },
      requestedFeatures: featuresCheck.value,
      adminContact: { ...admin, emailLower: adminEmailLower },
      currentStep: stepCheck.value,
      maxCompletedStep: maxStepCheck.value,
      resumeTokenHash: hashResumeToken(resumeToken),
      applicantUid: String(applicant.userId),
      applicantEmail: String(applicant.email || '').toLowerCase(),
      verification: {
        orgEmail: { verified: false, target: '' },
        adminEmail: { verified: false, target: '' },
        adminMobile: { verified: false, target: '' },
      },
      documents: {},
      auditTrail: [
        // serverTimestamp() is not allowed inside arrays — use a Date.
        { at: new Date(), action: 'draft_created', actor: 'applicant' },
      ],
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      expiresAt,
    };

    await col.doc(id).set(record);

    return successResponse(
      res,
      {
        registrationId: id,
        resumeToken, // returned exactly once — the client must store it
        status: 'draft',
        currentStep: record.currentStep,
      },
      'Draft created',
      201,
    );
  } catch (err: any) {
    console.error('createRegistrationDraft error:', err);
    return errorResponse(res, err.message || 'Internal server error', 500);
  }
};

/**
 * GET /org-registration/draft/:id
 * Header: x-registration-resume-token
 */
export const getRegistrationDraft = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const doc = await loadAuthorizedRegistration(req, res);
    if (!doc) return res;
    return successResponse(res, publicDraft(doc), 'Draft retrieved');
  } catch (err: any) {
    console.error('getRegistrationDraft error:', err);
    return errorResponse(res, err.message || 'Internal server error', 500);
  }
};

/**
 * PATCH /org-registration/draft/:id
 * Header: x-registration-resume-token
 * Updates editable fields only; ignores nothing silently — control fields
 * are rejected, unknown top-level fields are ignored.
 */
export const updateRegistrationDraft = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const doc = await loadAuthorizedRegistration(req, res);
    if (!doc) return res;

    const data = doc.data() as OrganizationRegistration;
    if (!EDITABLE_STATUSES.has(data.status)) {
      return errorResponse(res, 'Registration no longer accepts changes', 403);
    }

    const forbidden = forbiddenFieldErrors(req.body);
    if (forbidden.length) return errorResponse(res, forbidden.join('; '), 400);

    const updates: Record<string, unknown> = {
      updatedAt: FieldValue.serverTimestamp(),
    };
    const errors: string[] = [];

    if (req.body?.organization !== undefined) {
      const check = validateOrganization(req.body.organization, {
        partial: true,
      });
      errors.push(...check.errors);
      if (check.value) {
        const newEmailLower = check.value.officialEmail.toLowerCase();
        const currentEmailLower =
          data.organization?.officialEmailLower ?? '';
        // A PATCH may not claim an official email already used by another
        // in-flight application — same identity rule as draft creation.
        if (newEmailLower && newEmailLower !== currentEmailLower) {
          const dup = await getDb()
            .collection(ORGANIZATION_REGISTRATIONS_COL)
            .where('organization.officialEmailLower', '==', newEmailLower)
            .get();
          const conflict = dup.docs.find((d) => {
            if (d.id === doc.id) return false;
            const s = (d.data() as OrganizationRegistration).status;
            return s !== 'rejected' && s !== 'approved';
          });
          if (conflict) {
            return errorResponse(
              res,
              'An application already exists for this organization email',
              409,
            );
          }
        }
        updates['organization'] = {
          ...check.value,
          nameLower: check.value.name.toLowerCase(),
          officialEmailLower: check.value.officialEmail.toLowerCase(),
        };
      }
    }
    if (req.body?.adminContact !== undefined) {
      const check = validateAdminContact(req.body.adminContact, {
        partial: true,
      });
      errors.push(...check.errors);
      if (check.value) {
        updates['adminContact'] = {
          ...check.value,
          emailLower: check.value.email.toLowerCase(),
        };
      }
    }
    if (req.body?.requestedFeatures !== undefined) {
      const check = validateRequestedFeatures(req.body.requestedFeatures);
      errors.push(...check.errors);
      if (!check.errors.length) {
        updates['requestedFeatures'] = check.value;
      }
    }
    // Changing a contact invalidates its prior verification — the applicant
    // must re-verify the new address/number. Outstanding OTPs are cleared.
    if (updates['organization']) {
      const nextOrg = updates['organization'] as any;
      if (
        (nextOrg.officialEmailLower ?? '') !==
        (data.organization?.officialEmailLower ?? '')
      ) {
        updates['verification.orgEmail'] = {
          verified: false,
          target: '',
          verifiedAt: null,
        };
        await clearOtp(doc.id, 'orgEmail');
      }
    }
    if (updates['adminContact']) {
      const nextAdmin = updates['adminContact'] as any;
      if (
        (nextAdmin.emailLower ?? '') !== (data.adminContact?.emailLower ?? '')
      ) {
        updates['verification.adminEmail'] = {
          verified: false,
          target: '',
          verifiedAt: null,
        };
        await clearOtp(doc.id, 'adminEmail');
      }
      if ((nextAdmin.mobile ?? '') !== (data.adminContact?.mobile ?? '')) {
        updates['verification.adminMobile'] = {
          verified: false,
          target: '',
          verifiedAt: null,
        };
        await clearOtp(doc.id, 'adminMobile');
      }
    }

    if (req.body?.currentStep !== undefined) {
      const check = validateStep(req.body.currentStep, 'currentStep');
      errors.push(...check.errors);
      if (!check.errors.length) updates['currentStep'] = check.value;
    }
    if (req.body?.maxCompletedStep !== undefined) {
      const check = validateStep(
        req.body.maxCompletedStep,
        'maxCompletedStep',
        -1,
      );
      errors.push(...check.errors);
      if (!check.errors.length) {
        updates['maxCompletedStep'] = check.value;
      }
    }

    if (errors.length) return errorResponse(res, errors.join('; '), 400);

    updates['auditTrail'] = FieldValue.arrayUnion({
      at: new Date(),
      action: 'draft_updated',
      actor: 'applicant',
    });

    await doc.ref.update(updates);
    return successResponse(res, { registrationId: doc.id }, 'Draft updated');
  } catch (err: any) {
    console.error('updateRegistrationDraft error:', err);
    return errorResponse(res, err.message || 'Internal server error', 500);
  }
};

/**
 * GET /org-registration/status/:id
 * Header: x-registration-resume-token — status is also credential-gated.
 */
export const getRegistrationStatus = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const doc = await loadAuthorizedRegistration(req, res, {
      allowSubmitted: true,
    });
    if (!doc) return res;
    const d = doc.data() as OrganizationRegistration;
    return successResponse(res, {
      registrationId: doc.id,
      status: d.status,
      currentStep: d.currentStep,
      organizationName: d.organization?.name ?? '',
      organizationCode: d.organizationCode ?? null,
      submittedAt: d.submittedAt ?? null,
      review: d.review
        ? {
            decision: d.review.decision,
            reasons: d.review.reasons ?? [],
            // The reviewer message (rejection reason / requested changes)
            // is intended for the applicant — never reviewer identity.
            note: d.review.note ?? null,
          }
        : null,
    }, 'Status retrieved');
  } catch (err: any) {
    console.error('getRegistrationStatus error:', err);
    return errorResponse(res, err.message || 'Internal server error', 500);
  }
};

/** Status conflict on submit — mapped to HTTP 409. */
class SubmissionConflictError extends Error {
  constructor(public readonly currentStatus: string) {
    super(`Application cannot be submitted from status '${currentStatus}'`);
  }
}

/** Authenticated caller is not the bound applicant — mapped to HTTP 403. */
class ApplicantOwnershipError extends Error {
  constructor() {
    super('This application belongs to a different applicant account');
  }
}

/**
 * POST /org-registration/submit
 * Header: x-registration-resume-token
 * Body: { registrationId, declarationAccepted: true }
 *
 * Transitions draft|changes_requested → pending_approval. The transition is
 * a Firestore transaction so concurrent submits can't double-write the audit
 * trail — a repeat submission returns the persisted status idempotently.
 *
 * Submission NEVER provisions an organization, Admin account, org code, or
 * feature enablement — those happen in the platform-admin approval flow.
 */
export const submitRegistration = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const id = String(req.body?.registrationId || '').trim();
    if (!id) return errorResponse(res, 'registrationId is required', 400);

    // The applicant must confirm the review declaration on every submission.
    if (req.body?.declarationAccepted !== true) {
      return errorResponse(
        res,
        'You must review the application and accept the declaration before submitting',
        400,
      );
    }

    const docRef = getDb()
      .collection(ORGANIZATION_REGISTRATIONS_COL)
      .doc(id);
    const doc = await docRef.get();
    if (!doc.exists) return errorResponse(res, 'Registration not found', 404);

    const data = doc.data() as OrganizationRegistration;
    if (!checkApplicantCredential(req, res, data)) return res;

    // ── Full server-side completeness gate ──────────────────────────────
    // Stored data is revalidated in non-partial mode — the client wizard's
    // checks are a convenience, never the authority.
    const missing: string[] = [];

    const orgCheck = validateOrganization(data.organization);
    if (orgCheck.errors.length) {
      missing.push(...orgCheck.errors.map((e) => `organization: ${e}`));
    }
    const adminCheck = validateAdminContact(data.adminContact);
    if (adminCheck.errors.length) {
      missing.push(...adminCheck.errors.map((e) => `adminContact: ${e}`));
    }
    const featuresCheck = validateRequestedFeatures(data.requestedFeatures);
    if (featuresCheck.errors.length) {
      missing.push(...featuresCheck.errors);
    }

    const channelLabels: Record<VerificationChannel, string> = {
      orgEmail: 'organization email verification',
      adminEmail: 'admin email verification',
      adminMobile: 'mobile verification',
    };
    for (const ch of requiredChannels(data)) {
      if (!data.verification?.[ch]?.verified) {
        missing.push(channelLabels[ch]);
      }
    }
    const docs = data.documents || {};
    const missingDocs = [...REQUIRED_DOC_FIELDS].filter((f) => !docs[f]);
    // GST certificate is required only when a GST number was provided.
    if (
      String(data.organization?.gstNumber || '').trim() &&
      !docs['gstCertificate']
    ) {
      missingDocs.push('gstCertificate');
    }
    if (missingDocs.length) {
      missing.push(`documents: ${missingDocs.join(', ')}`);
    }

    if (missing.length) {
      return errorResponse(
        res,
        `Application is incomplete: ${missing.join(', ')} required before submission`,
        400,
      );
    }

    // ── Atomic, idempotent transition ───────────────────────────────────
    const outcome = await getDb().runTransaction(async (tx) => {
      const snap = await tx.get(docRef);
      if (!snap.exists) throw new Error('Registration not found');
      const cur = snap.data() as OrganizationRegistration;

      // Already submitted — idempotent success, no duplicate audit event.
      if (cur.status === 'pending_approval') {
        return { already: true as const, submittedAt: cur.submittedAt ?? null };
      }
      if (!SUBMITTABLE_STATUSES.has(cur.status)) {
        throw new SubmissionConflictError(cur.status);
      }

      // Identity re-verified INSIDE the transaction: a bound application
      // can only be resubmitted by its owning applicant. Unbound legacy
      // drafts were already authorized by the resume credential above.
      const boundUid = String(cur.applicantUid || '');
      if (boundUid && req.user) {
        const uidMatch = String(req.user.userId) === boundUid;
        const emailMatch =
          !!cur.applicantEmail &&
          String(req.user.email || '').toLowerCase() ===
            cur.applicantEmail.toLowerCase();
        if (!uidMatch && !emailMatch) throw new ApplicantOwnershipError();
      }

      const resubmission = cur.status === 'changes_requested';
      const revision = (cur.resubmissionCount ?? 0) + 1;
      // Compare the corrected application against the baseline captured
      // when changes were requested. Only changed entries are stored —
      // the reviewer sees exactly what the applicant edited.
      const changedFields = resubmission
        ? computeChangedFields(
            cur.changeRequestBaseline ?? {
              organization: {},
              requestedFeatures: [],
              adminContact: {},
              verification: {},
              documents: {},
              capturedAt: new Date(0),
            },
            cur,
          )
        : undefined;
      tx.update(docRef, {
        status: 'pending_approval',
        submittedAt: FieldValue.serverTimestamp(),
        ...(resubmission
          ? { resubmittedAt: FieldValue.serverTimestamp() }
          : {}),
        ...(changedFields !== undefined ? { changedFields } : {}),
        declarationAccepted: true,
        declarationAcceptedAt: FieldValue.serverTimestamp(),
        resubmissionCount: FieldValue.increment(resubmission ? 1 : 0),
        // Archive the outgoing review decision — history is never lost.
        ...(resubmission && cur.review
          ? { reviewHistory: FieldValue.arrayUnion(cur.review) }
          : {}),
        auditTrail: FieldValue.arrayUnion({
          at: new Date(),
          action: resubmission ? 'application_resubmitted' : 'submitted',
          actor: String(req.user?.userId || 'applicant'),
          note: resubmission
            ? `changes_requested -> pending_approval (revision ${revision})`
            : 'submitted for review',
          ...(resubmission ? { revision } : {}),
        }),
        updatedAt: FieldValue.serverTimestamp(),
      });
      return { already: false as const };
    });

    return successResponse(
      res,
      {
        registrationId: id,
        status: 'pending_approval',
        ...(outcome.already
          ? { submittedAt: outcome.submittedAt, alreadySubmitted: true }
          : {}),
      },
      outcome.already
        ? 'Application is already submitted for review'
        : 'Application submitted for review',
    );
  } catch (err: any) {
    if (err instanceof SubmissionConflictError) {
      return errorResponse(res, err.message, 409);
    }
    if (err instanceof ApplicantOwnershipError) {
      return errorResponse(res, err.message, 403);
    }
    console.error('submitRegistration error:', err);
    return errorResponse(res, err.message || 'Internal server error', 500);
  }
};

// -- Verification (OTP) -------------------------------------------------------

/**
 * POST /org-registration/verify/request
 * Header: x-registration-resume-token; body: { registrationId, channel }
 * channel: orgEmail | adminEmail | adminMobile
 */
export const requestRegistrationVerification = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const id = String(req.body?.registrationId || '').trim();
    const channel = String(req.body?.channel || '').trim();
    if (!id) return errorResponse(res, 'registrationId is required', 400);
    if (!VERIFICATION_CHANNELS.has(channel)) {
      return errorResponse(res, 'Invalid verification channel', 400);
    }

    const doc = await getDb()
      .collection(ORGANIZATION_REGISTRATIONS_COL)
      .doc(id)
      .get();
    if (!doc.exists) return errorResponse(res, 'Registration not found', 404);

    const data = doc.data() as OrganizationRegistration;
    if (!checkApplicantCredential(req, res, data)) return res;
    if (!EDITABLE_STATUSES.has(data.status)) {
      return errorResponse(res, 'Registration no longer accepts changes', 403);
    }

    const ch = channel as VerificationChannel;
    if (!requiredChannels(data).includes(ch)) {
      return errorResponse(res, 'This channel does not require verification', 400);
    }
    const destination = channelDestination(data, ch);
    const state = data.verification?.[ch];
    if (state?.verified && state?.target === destination) {
      return successResponse(res, { channel: ch }, 'Already verified');
    }

    const { code } = await issueOtp(id, ch, destination);

    const delivery =
      ch === 'adminMobile'
        ? await sendSmsOtp(destination, code)
        : await sendEmailOtp(destination, code);

    if (delivery.mode === 'unavailable') {
      // No provider configured and not in the emulator � nothing to send.
      return errorResponse(
        res,
        'Verification delivery is not configured on this server',
        503,
      );
    }

    return successResponse(
      res,
      {
        channel: ch,
        delivered: delivery.mode === 'smtp' ? 'email' : 'dev',
        // devCode is populated ONLY in emulator mode � never in production.
        ...(delivery.devCode ? { devCode: delivery.devCode } : {}),
      },
      'Verification code sent',
    );
  } catch (err: any) {
    if (err instanceof OtpError) {
      return errorResponse(res, err.message, err.status);
    }
    console.error('requestRegistrationVerification error:', err);
    return errorResponse(res, err.message || 'Internal server error', 500);
  }
};

/**
 * POST /org-registration/verify/confirm
 * Header: x-registration-resume-token; body: { registrationId, channel, code }
 */
export const confirmRegistrationVerification = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const id = String(req.body?.registrationId || '').trim();
    const channel = String(req.body?.channel || '').trim();
    const code = String(req.body?.code || '').trim();
    if (!id) return errorResponse(res, 'registrationId is required', 400);
    if (!VERIFICATION_CHANNELS.has(channel)) {
      return errorResponse(res, 'Invalid verification channel', 400);
    }
    if (!/^\d{6}$/.test(code)) {
      return errorResponse(res, 'Enter the 6-digit code', 400);
    }

    const doc = await getDb()
      .collection(ORGANIZATION_REGISTRATIONS_COL)
      .doc(id)
      .get();
    if (!doc.exists) return errorResponse(res, 'Registration not found', 404);

    const data = doc.data() as OrganizationRegistration;
    if (!checkApplicantCredential(req, res, data)) return res;

    const ch = channel as VerificationChannel;
    // A successfully-used OTP can never be reused — even a retry of the
    // same code is rejected. The client learns the verified state from
    // the draft's verification map, not by replaying confirm.
    await confirmOtp(id, ch, code);
    return successResponse(res, { channel: ch }, 'Verified');
  } catch (err: any) {
    if (err instanceof OtpError) {
      return errorResponse(res, err.message, err.status);
    }
    console.error('confirmRegistrationVerification error:', err);
    return errorResponse(res, err.message || 'Internal server error', 500);
  }
};

// -- Organization documents ---------------------------------------------------

const PNG_MAGIC = Buffer.from([0x89, 0x50, 0x4e, 0x47]);
const JPG_MAGIC = Buffer.from([0xff, 0xd8, 0xff]);

/** Validates actual file content � not the client-supplied mimetype. */
function sniffContentType(buf: Buffer): string | null {
  if (!buf || buf.length < 5) return null;
  if (buf.subarray(0, 4).equals(PNG_MAGIC)) return 'image/png';
  if (buf.subarray(0, 3).equals(JPG_MAGIC)) return 'image/jpeg';
  if (buf.subarray(0, 5).toString('latin1') === '%PDF-') return 'application/pdf';
  return null;
}

function safeFilename(name: string): string {
  const base = path.basename(name).replace(/[^A-Za-z0-9._-]/g, '_');
  return base.slice(0, 80) || 'document';
}

function storageGuardError(): string | null {
  // Never let a DEV/emulator request fall through to the real bucket.
  if (
    process.env.FUNCTIONS_EMULATOR === 'true' &&
    !process.env.STORAGE_EMULATOR_HOST &&
    !process.env.FIREBASE_STORAGE_EMULATOR_HOST
  ) {
    return 'Storage emulator is not running � DEV uploads are blocked';
  }
  return null;
}

/**
 * POST /org-registration/documents
 * Header: x-registration-resume-token
 * Multipart: registrationId + file fields (registrationCertificate,
 * gstCertificate, authorizationLetter, adminIdProof).
 * Requires all required verification channels to be verified first.
 */
export const uploadRegistrationDocuments = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const guard = storageGuardError();
    if (guard) return errorResponse(res, guard, 503);

    const id = String(req.body?.registrationId || '').trim();
    if (!id) return errorResponse(res, 'registrationId is required', 400);

    const doc = await getDb()
      .collection(ORGANIZATION_REGISTRATIONS_COL)
      .doc(id)
      .get();
    if (!doc.exists) return errorResponse(res, 'Registration not found', 404);

    const data = doc.data() as OrganizationRegistration;
    if (!checkApplicantCredential(req, res, data)) return res;
    if (!EDITABLE_STATUSES.has(data.status)) {
      return errorResponse(res, 'Registration no longer accepts changes', 403);
    }

    // Documents only after the required contacts are verified.
    const unverified = requiredChannels(data).filter(
      (c) => !data.verification?.[c]?.verified,
    );
    if (unverified.length) {
      return errorResponse(
        res,
        'Contact verification is required before uploading documents',
        403,
      );
    }

    // Minimal uploaded-file shape — avoids depending on Express.Multer
    // namespace types, which are not auto-loaded by this tsconfig.
    type UploadedFile = {
      fieldname: string;
      originalname: string;
      mimetype: string;
      buffer: Buffer;
      size: number;
    };
    const files = ((req as any).files || {}) as Record<string, UploadedFile[]>;
    const fieldNames = Object.keys(files);
    if (!fieldNames.length) {
      return errorResponse(res, 'No document files were provided', 400);
    }

    const bucket = getBucket();
    const updates: Record<string, unknown> = {
      updatedAt: FieldValue.serverTimestamp(),
    };
    const uploaded: string[] = [];

    for (const field of fieldNames) {
      if (!REGISTRATION_DOC_FIELDS.has(field)) {
        return errorResponse(res, `Unknown document field '${field}'`, 400);
      }
      const file = files[field][0];
      const detected = sniffContentType(file.buffer);
      if (!detected) {
        return errorResponse(
          res,
          `File '${field}' is not a valid PDF, JPG, or PNG`,
          400,
        );
      }
      const objectPath =
        `org-registrations/${id}/${field}/` +
        `${Date.now()}_${safeFilename(file.originalname)}`;
      await bucket.file(objectPath).save(file.buffer, {
        metadata: { contentType: detected },
      });
      const meta: RegistrationDocumentMeta = {
        field,
        storagePath: objectPath,
        originalName: safeFilename(file.originalname),
        contentType: detected,
        size: file.size,
        uploadedAt: new Date(),
      };
      updates[`documents.${field}`] = meta;
      uploaded.push(field);
    }

    updates['auditTrail'] = FieldValue.arrayUnion({
      at: new Date(),
      action: `documents_uploaded:${uploaded.join(',')}`,
      actor: 'applicant',
    });

    await doc.ref.update(updates);
    return successResponse(res, { uploaded }, 'Documents uploaded');
  } catch (err: any) {
    console.error('uploadRegistrationDocuments error:', err);
    return errorResponse(res, err.message || 'Internal server error', 500);
  }
};

/**
 * GET /org-registration/documents/:id
 * Header: x-registration-resume-token � returns document metadata.
 */
export const listRegistrationDocuments = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  const doc = await loadAuthorizedRegistration(req, res);
  if (!doc) return res;
  const d = doc.data() as OrganizationRegistration;
  return successResponse(res, {
    documents: Object.fromEntries(
      Object.entries(d.documents ?? {}).map(([k, v]) => [
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
  }, 'Documents retrieved');
};

/**
 * GET /org-registration/documents/:id/:field/url
 * Header: x-registration-resume-token � short-lived signed URL.
 */
export const getRegistrationDocument = async (
  req: Request,
  res: Response,
): Promise<Response | void> => {
  try {
    const guard = storageGuardError();
    if (guard) return errorResponse(res, guard, 503);

    const doc = await loadAuthorizedRegistration(req, res);
    if (!doc) return res;
    const field = String(req.params.field || '').trim();
    if (!REGISTRATION_DOC_FIELDS.has(field)) {
      return errorResponse(res, 'Unknown document field', 400);
    }
    const meta = (doc.data() as OrganizationRegistration).documents?.[field];
    if (!meta) return errorResponse(res, 'Document not found', 404);

    // Stream bytes through the backend — no signed URLs, no public objects.
    // (Signed URLs also require a client_email that ADC doesn't provide.)
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
    console.error('getRegistrationDocument error:', err);
    return errorResponse(res, err.message || 'Internal server error', 500);
  }
};

/**
 * GET /org-registration/mine
 * authMiddleware + roleMiddleware(['org_applicant'])
 *
 * Server-side resolution of the caller's current application — the source
 * of truth for post-login routing (replaces local resume-token state).
 * Returns the NEWEST application when more than one exists (a superseded
 * rejected application never hides an active one).
 */
export const getMyRegistration = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const uid = String(req.user?.userId || '');
    const email = String(req.user?.email || '').toLowerCase();
    const col = getDb().collection(ORGANIZATION_REGISTRATIONS_COL);
    const snap = await col.where('applicantUid', '==', uid).get();
    const docs = [...snap.docs];
    if (!docs.length && email) {
      const byEmail = await col.where('applicantEmail', '==', email).get();
      docs.push(...byEmail.docs);
    }
    if (!docs.length) {
      return successResponse(res, { application: null }, 'No application found');
    }
    docs.sort((a, b) => createdAtMillis(b) - createdAtMillis(a));
    const doc = docs[0];
    const d = doc.data() as OrganizationRegistration;
    return successResponse(
      res,
      {
        application: {
          registrationId: doc.id,
          status: d.status,
          currentStep: d.currentStep,
          maxCompletedStep: d.maxCompletedStep,
          organizationName: d.organization?.name ?? '',
          submittedAt: d.submittedAt ?? null,
          review: d.review
            ? {
                decision: d.review.decision,
                reasons: d.review.reasons ?? [],
                note: d.review.note ?? null,
              }
            : null,
        },
      },
      'Application resolved',
    );
  } catch (err: any) {
    console.error('getMyRegistration error:', err);
    return errorResponse(res, err.message || 'Internal server error', 500);
  }
};

function createdAtMillis(doc: FirebaseFirestore.DocumentSnapshot): number {
  const c = (doc.data() as any)?.createdAt;
  if (c instanceof Date) return c.getTime();
  return c?.toDate?.()?.getTime?.() ?? 0;
}
