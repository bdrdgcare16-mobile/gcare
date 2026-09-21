// functions/src/controllers/organizationRegistrationController.ts

import { Request, Response } from 'express';
import { createHash, randomBytes, timingSafeEqual } from 'crypto';
import { v4 as uuidv4 } from 'uuid';
import { FieldValue } from 'firebase-admin/firestore';
import { getDb } from '../config/firebase';
import { errorResponse, successResponse } from '../common/response';
import {
  CANONICAL_FEATURES,
  CLIENT_FORBIDDEN_FIELDS,
  EDITABLE_STATUSES,
  ORGANIZATION_REGISTRATIONS_COL,
  OrganizationRegistration,
  REGISTRATION_DRAFT_TTL_MS,
  RESUME_REVOKED_STATUSES,
} from '../models/organizationRegistration';

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
  if (!Number.isInteger(n) || n < min || n > 3) {
    return {
      errors: [`${name} must be an integer between ${min} and 3`],
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

  const presented = getResumeToken(req);
  const storedHash = String(data.resumeTokenHash || '');
  if (
    !presented ||
    !storedHash ||
    !tokensEqual(hashResumeToken(presented), storedHash)
  ) {
    errorResponse(res, 'Invalid resume credential', 401);
    return null;
  }

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
  };
}

// ── Handlers ─────────────────────────────────────────────────────────────────

/**
 * POST /org-registration/draft
 * Creates a new draft application. Issues the resume token ONCE.
 */
export const createRegistrationDraft = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
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
      verification: { emailVerified: false, mobileVerified: false },
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
      organizationCode: d.organizationCode ?? null,
    }, 'Status retrieved');
  } catch (err: any) {
    console.error('getRegistrationStatus error:', err);
    return errorResponse(res, err.message || 'Internal server error', 500);
  }
};

/**
 * POST /org-registration/submit
 * Header: x-registration-resume-token; body: { registrationId }
 *
 * Completeness gate: verification and document stages (Milestone 3C) must
 * be satisfied before an application can enter pending_approval. Until those
 * stages exist, every submission is honestly rejected — no fake success.
 */
export const submitRegistration = async (
  req: Request,
  res: Response,
): Promise<Response> => {
  try {
    const id = String(req.body?.registrationId || '').trim();
    if (!id) return errorResponse(res, 'registrationId is required', 400);

    const doc = await getDb()
      .collection(ORGANIZATION_REGISTRATIONS_COL)
      .doc(id)
      .get();
    if (!doc.exists) return errorResponse(res, 'Registration not found', 404);

    const data = doc.data() as OrganizationRegistration;
    const presented = getResumeToken(req);
    if (
      !presented ||
      !tokensEqual(hashResumeToken(presented), String(data.resumeTokenHash || ''))
    ) {
      return errorResponse(res, 'Invalid resume credential', 401);
    }

    const missing: string[] = [];
    if (!data.verification?.emailVerified) {
      missing.push('email verification');
    }
    if (!data.verification?.mobileVerified) {
      missing.push('mobile verification');
    }
    const docs = data.documents || {};
    if (Object.keys(docs).length === 0) {
      missing.push('required documents');
    }

    if (missing.length) {
      return errorResponse(
        res,
        `Application is incomplete: ${missing.join(', ')} required before submission`,
        400,
      );
    }

    // Future: transition to pending_approval inside the 3C/3D flow.
    return errorResponse(res, 'Submission is not yet available', 400);
  } catch (err: any) {
    console.error('submitRegistration error:', err);
    return errorResponse(res, err.message || 'Internal server error', 500);
  }
};
