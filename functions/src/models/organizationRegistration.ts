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
  | 'rejected';

/** Statuses that still allow the applicant to keep editing. */
export const EDITABLE_STATUSES: ReadonlySet<RegistrationStatus> = new Set([
  'draft',
  'changes_requested',
]);

/** Terminal-ish statuses where the resume credential is revoked. */
export const RESUME_REVOKED_STATUSES: ReadonlySet<RegistrationStatus> =
  new Set(['pending_approval', 'approved', 'rejected']);

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
  verification: { emailVerified: boolean; mobileVerified: boolean };
  documents: Record<string, unknown>;
  auditTrail: Array<{
    at: FirebaseFirestore.FieldValue | Date;
    action: string;
    actor?: string;
    note?: string;
  }>;
  organizationCode?: string;
  approvedCompanyId?: string;
  createdAt: FirebaseFirestore.FieldValue | Date;
  updatedAt: FirebaseFirestore.FieldValue | Date;
  expiresAt: Date;
}
