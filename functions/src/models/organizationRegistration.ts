// functions/src/models/organizationRegistration.ts

/**
 * Organization registration application model.
 *
 * Registration applications live in `organizationRegistrations`, completely
 * separate from the operational `companyProfile` collection. A draft or
 * submitted application never creates an organization or Admin account —
 * that happens only inside the platform-admin approval transaction
 * (Milestone 3D).
 */

export const ORGANIZATION_REGISTRATIONS_COL = 'organizationRegistrations';

/** Application lifecycle — distinct from operational org status. */
export type RegistrationStatus =
  | 'draft'
  | 'submitted'
  | 'pending_verification'
  | 'pending_approval'
  | 'changes_requested'
  | 'approved'
  | 'rejected'
  // Reserved for the post-approval provisioning milestone: the
  // organization was activated and the applicant's Admin access enabled.
  // 'approved' alone NEVER implies activation.
  | 'activated';

/** Statuses that still allow the applicant to keep editing. */
export const EDITABLE_STATUSES: ReadonlySet<RegistrationStatus> = new Set([
  'draft',
  'changes_requested',
]);

/** Terminal-ish statuses where the resume credential is revoked. */
export const RESUME_REVOKED_STATUSES: ReadonlySet<RegistrationStatus> =
  new Set([
    'submitted',
    'pending_verification',
    'pending_approval',
    'approved',
    'rejected',
    'activated',
  ]);

/** Statuses from which an applicant may submit / resubmit. */
export const SUBMITTABLE_STATUSES: ReadonlySet<RegistrationStatus> = new Set([
  'draft',
  'changes_requested',
]);

/** Draft expiry — resume credential stops working after this. */
export const REGISTRATION_DRAFT_TTL_MS = 30 * 24 * 60 * 60 * 1000;

/**
 * Canonical requested-feature catalog. These IDs mirror the Flutter
 * `kSelectableFeatures` list; the platform admin maps requested →
 * approved → enabled during review. Requesting a feature never activates it.
 */
export const CANONICAL_FEATURES: ReadonlySet<string> = new Set([
  'employee_master',
  'organization_structure',
  'users_and_roles',
  'attendance',
  'location_tracking',
  'tasks',
  'shifts',
  'leave_management',
  'payroll',
  'recruitment',
  'performance',
  'reporting',
]);

/** Fields the applicant may never set — server/platform controlled. */
export const CLIENT_FORBIDDEN_FIELDS: ReadonlySet<string> = new Set([
  'status',
  'approvedFeatures',
  'enabledFeatures',
  'organizationCode',
  'review',
  'verification',
  'documents',
  'auditTrail',
  'applicantFingerprint',
  'approvedCompanyId',
  // Applicant identity is bound server-side from the verified JWT —
  // never accepted from the request body.
  'applicantUid',
  'applicantEmail',
  // Review-context internals — server-written only. The applicant must
  // never be able to spoof the change baseline or the computed diff.
  'changeRequestBaseline',
  'changedFields',
]);

export interface RegistrationOrganization {
  name: string;
  nameLower: string;
  type: string;
  industry: string;
  employeeCount: number;
  branchCount: number;
  registeredAddress: string;
  officialEmail: string;
  officialEmailLower: string;
  contactNumber: string;
  website?: string;
  gstNumber?: string;
  cinNumber?: string;
}

export interface RegistrationAdminContact {
  fullName: string;
  designation: string;
  email: string;
  emailLower: string;
  mobile: string;
}

/** Verification state for one contact channel (server-controlled). */
export interface ChannelVerification {
  verified: boolean;
  /** The verified destination (email/phone) — stamped server-side. */
  target: string;
  verifiedAt?: FirebaseFirestore.FieldValue | Date | null;
}

export interface RegistrationVerification {
  orgEmail: ChannelVerification;
  adminEmail: ChannelVerification;
  adminMobile: ChannelVerification;
}

/** Registration document categories the applicant can upload. */
export const REGISTRATION_DOC_FIELDS: ReadonlySet<string> = new Set([
  'registrationCertificate',
  'gstCertificate',
  'authorizationLetter',
  'adminIdProof',
]);

/** Document categories required before submission. GST is conditional
 *  (required only when the organization supplied a GST number). */
export const REQUIRED_DOC_FIELDS: ReadonlySet<string> = new Set([
  'registrationCertificate',
  'authorizationLetter',
  'adminIdProof',
]);

export interface RegistrationDocumentMeta {
  field: string;
  storagePath: string;
  originalName: string;
  contentType: string;
  size: number;
  uploadedAt: FirebaseFirestore.FieldValue | Date;
}

// ─── Resubmission review context (change diff) ────────────────────────────
//
// When Platform Admin requests changes, a sanitized BASELINE snapshot of
// the application is captured. On resubmission the corrected application
// is compared against it server-side, producing `changedFields` for the
// reviewer. The baseline never contains credentials, OTP state, resume
// token material, or storage paths — only reviewable registration fields.

/** One entry in the server-computed resubmission diff. */
export interface ChangedField {
  /** Dotted path, e.g. 'organization.employeeCount'. */
  field: string;
  /** Human label for the reviewer UI. */
  label: string;
  changeType: 'modified' | 'added' | 'removed' | 'replaced';
  /** Scalar old/new values (reviewable fields only — never paths/keys). */
  oldValue?: string;
  newValue?: string;
  /** Set membership changes (requestedFeatures). */
  added?: string[];
  removed?: string[];
}

/** Sanitized point-in-time snapshot captured on 'Request Changes'. */
export interface ChangeRequestBaseline {
  organization: Record<string, unknown>;
  requestedFeatures: string[];
  adminContact: Record<string, unknown>;
  /** Verification STATUSES only — no OTP codes or session material. */
  verification: Record<string, { verified: boolean }>;
  /** Document METADATA only — storagePath is deliberately excluded. */
  documents: Record<
    string,
    {
      originalName?: string;
      size?: number;
      contentType?: string;
      uploadedAt?: string;
    }
  >;
  capturedAt: Date;
}

/** Organization fields a reviewer may compare (derived keys excluded). */
const ORG_BASELINE_FIELDS: Record<string, string> = {
  name: 'Organization Name',
  type: 'Organization Type',
  industry: 'Industry',
  employeeCount: 'Employees',
  branchCount: 'Branches',
  registeredAddress: 'Registered Address',
  officialEmail: 'Official Email',
  contactNumber: 'Contact Number',
  website: 'Website',
  gstNumber: 'GST Number',
  cinNumber: 'CIN Number',
};

const ADMIN_BASELINE_FIELDS: Record<string, string> = {
  fullName: 'HR/Admin Name',
  designation: 'Designation',
  email: 'Admin Email',
  mobile: 'Admin Mobile',
};

const VERIFICATION_BASELINE_FIELDS: Record<string, string> = {
  orgEmail: 'Organization Email Verification',
  adminEmail: 'Admin Email Verification',
  adminMobile: 'Admin Mobile Verification',
};

const DOCUMENT_BASELINE_LABELS: Record<string, string> = {
  registrationCertificate: 'Registration Certificate',
  gstCertificate: 'GST Certificate',
  authorizationLetter: 'Authorization Letter',
  adminIdProof: 'Admin ID Proof',
};

/** Normalizes a stored timestamp (Date | Timestamp | string) for
 *  metadata comparison. */
function docTimeKey(v: unknown): string {
  if (v == null) return '';
  if (v instanceof Date) return v.toISOString();
  const s = (v as { _seconds?: number })._seconds;
  if (typeof s === 'number') return `s${s}`;
  const secs = (v as { seconds?: number }).seconds;
  if (typeof secs === 'number') return `s${secs}`;
  return String(v);
}

/** Captures the sanitized baseline — whitelist only, never secrets. */
export function captureChangeRequestBaseline(
  r: OrganizationRegistration,
): ChangeRequestBaseline {
  const organization: Record<string, unknown> = {};
  for (const k of Object.keys(ORG_BASELINE_FIELDS)) {
    organization[k] = (r.organization as any)?.[k];
  }
  const adminContact: Record<string, unknown> = {};
  for (const k of Object.keys(ADMIN_BASELINE_FIELDS)) {
    adminContact[k] = (r.adminContact as any)?.[k];
  }
  const verification: Record<string, { verified: boolean }> = {};
  const ver = r.verification as unknown as
    | Record<string, ChannelVerification>
    | undefined;
  for (const k of Object.keys(VERIFICATION_BASELINE_FIELDS)) {
    verification[k] = { verified: ver?.[k]?.verified === true };
  }
  const documents: ChangeRequestBaseline['documents'] = {};
  for (const [field, meta] of Object.entries(r.documents ?? {})) {
    documents[field] = {
      originalName: meta?.originalName,
      size: meta?.size,
      contentType: meta?.contentType,
      uploadedAt: docTimeKey(meta?.uploadedAt),
    };
  }
  return {
    organization,
    requestedFeatures: [...(r.requestedFeatures ?? [])],
    adminContact,
    verification,
    documents,
    capturedAt: new Date(),
  };
}

/**
 * Compares a corrected application against the request-changes baseline.
 * Returns ONLY changed entries — unchanged fields are never emitted.
 */
export function computeChangedFields(
  baseline: ChangeRequestBaseline,
  r: OrganizationRegistration,
): ChangedField[] {
  const out: ChangedField[] = [];

  for (const [k, label] of Object.entries(ORG_BASELINE_FIELDS)) {
    const oldV = baseline.organization?.[k];
    const newV = (r.organization as any)?.[k];
    if (String(oldV ?? '') !== String(newV ?? '')) {
      out.push({
        field: `organization.${k}`,
        label,
        changeType: 'modified',
        oldValue: oldV == null || oldV === '' ? '—' : String(oldV),
        newValue: newV == null || newV === '' ? '—' : String(newV),
      });
    }
  }

  for (const [k, label] of Object.entries(ADMIN_BASELINE_FIELDS)) {
    const oldV = baseline.adminContact?.[k];
    const newV = (r.adminContact as any)?.[k];
    if (String(oldV ?? '') !== String(newV ?? '')) {
      out.push({
        field: `adminContact.${k}`,
        label,
        changeType: 'modified',
        oldValue: oldV == null || oldV === '' ? '—' : String(oldV),
        newValue: newV == null || newV === '' ? '—' : String(newV),
      });
    }
  }

  const oldF = new Set(baseline.requestedFeatures ?? []);
  const newF = new Set(r.requestedFeatures ?? []);
  const added = [...newF].filter((f) => !oldF.has(f));
  const removed = [...oldF].filter((f) => !newF.has(f));
  if (added.length || removed.length) {
    out.push({
      field: 'requestedFeatures',
      label: 'Requested Features',
      changeType: 'modified',
      ...(added.length ? { added } : {}),
      ...(removed.length ? { removed } : {}),
    });
  }

  const curVer = r.verification as unknown as
    | Record<string, ChannelVerification>
    | undefined;
  for (const [k, label] of Object.entries(VERIFICATION_BASELINE_FIELDS)) {
    const was = baseline.verification?.[k]?.verified === true;
    const is = curVer?.[k]?.verified === true;
    if (was !== is) {
      out.push({
        field: `verification.${k}`,
        label,
        changeType: 'modified',
        oldValue: was ? 'Verified' : 'Not verified',
        newValue: is ? 'Verified' : 'Not verified',
      });
    }
  }

  const docFields = new Set([
    ...Object.keys(baseline.documents ?? {}),
    ...Object.keys(r.documents ?? {}),
  ]);
  for (const field of docFields) {
    const label = DOCUMENT_BASELINE_LABELS[field] ?? field;
    const oldDoc = baseline.documents?.[field];
    const newMeta = r.documents?.[field];
    const newDoc = newMeta
      ? {
          originalName: newMeta.originalName,
          size: newMeta.size,
          contentType: newMeta.contentType,
          uploadedAt: docTimeKey(newMeta.uploadedAt),
        }
      : undefined;
    if (!oldDoc && newDoc) {
      out.push({
        field: `documents.${field}`,
        label,
        changeType: 'added',
        newValue: newDoc.originalName || 'uploaded',
      });
    } else if (oldDoc && !newDoc) {
      out.push({
        field: `documents.${field}`,
        label,
        changeType: 'removed',
        oldValue: oldDoc.originalName || 'removed',
      });
    } else if (
      oldDoc &&
      newDoc &&
      (oldDoc.originalName !== newDoc.originalName ||
        oldDoc.size !== newDoc.size ||
        oldDoc.contentType !== newDoc.contentType ||
        oldDoc.uploadedAt !== newDoc.uploadedAt)
    ) {
      out.push({
        field: `documents.${field}`,
        label,
        changeType: 'replaced',
        oldValue: oldDoc.originalName ?? '',
        newValue: newDoc.originalName ?? '',
      });
    }
  }

  return out;
}

export interface OrganizationRegistration {
  applicationId: string;
  status: RegistrationStatus;
  organization: RegistrationOrganization;
  requestedFeatures: string[];
  adminContact: RegistrationAdminContact;
  currentStep: number;
  maxCompletedStep: number;
  /** SHA-256 hex of the resume token. The token itself is never stored. */
  resumeTokenHash: string;
  /**
   * Authenticated applicant binding (3D-C follow-up). Stamped at draft
   * creation from the verified JWT — the request body cannot set them.
   * The resume token stays as a device-local fallback credential.
   */
  applicantUid?: string;
  applicantEmail?: string;
  verification: RegistrationVerification;
  documents: Record<string, RegistrationDocumentMeta>;
  auditTrail: Array<{
    at: FirebaseFirestore.FieldValue | Date;
    action: string;
    actor?: string;
    note?: string;
  }>;
  /** Set once when the application enters pending_approval (server time). */
  submittedAt?: FirebaseFirestore.FieldValue | Date;
  /** Applicant confirmed the review declaration at submit time. */
  declarationAccepted?: boolean;
  declarationAcceptedAt?: FirebaseFirestore.FieldValue | Date;
  /** Number of changes_requested → pending_approval resubmissions. */
  resubmissionCount?: number;
  /** Server timestamp of the most recent resubmission. */
  resubmittedAt?: FirebaseFirestore.FieldValue | Date;
  /**
   * Prior review decisions, archived (never overwritten) when a
   * changes_requested application is resubmitted. `review` holds only the
   * ACTIVE decision; history lives here and in auditTrail.
   */
  reviewHistory?: Array<{
    reviewerId: string;
    reviewerEmail: string;
    decidedAt: FirebaseFirestore.FieldValue | Date;
    decision: 'approved' | 'rejected' | 'changes_requested';
    reasons?: string[];
    note?: string;
  }>;
  /** Sanitized snapshot captured when changes were requested — the
   *  server-side baseline for the resubmission diff. Never client-set. */
  changeRequestBaseline?: ChangeRequestBaseline;
  /** Server-computed diff of the latest resubmission (vs baseline). */
  changedFields?: ChangedField[];
  /** Platform-admin review record (3D-B/C — server-written only). */
  review?: {
    reviewerId: string;
    reviewerEmail: string;
    decidedAt: FirebaseFirestore.FieldValue | Date;
    decision: 'approved' | 'rejected' | 'changes_requested';
    reasons?: string[];
    note?: string;
  };
  organizationCode?: string;
  approvedCompanyId?: string;
  createdAt: FirebaseFirestore.FieldValue | Date;
  updatedAt: FirebaseFirestore.FieldValue | Date;
  expiresAt: Date;
}
