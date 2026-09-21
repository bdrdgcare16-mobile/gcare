import { Timestamp } from 'firebase-admin/firestore';

export type OrganizationPolicyType =
  | 'attendance'
  | 'leave'
  | 'code_of_conduct'
  | 'work_location'
  | 'payroll'
  | 'location_tracking_consent'
  | 'biometric_consent';

export interface OrganizationPolicy {
  id?: string;
  organizationId: string;
  policyId: string;
  type: OrganizationPolicyType;
  title: string;
  description: string;
  version: number;
  content: string;
  documentUrl?: string;
  publishedAt: Timestamp;
  active: boolean;
  required: boolean;
  requiresSeparateConsent: boolean;
  contentHash: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export const ORGANIZATION_POLICIES_COL = 'organizationPolicies';

export const VALID_POLICY_TYPES: ReadonlySet<string> = new Set([
  'attendance',
  'leave',
  'code_of_conduct',
  'work_location',
  'payroll',
  'location_tracking_consent',
  'biometric_consent',
]);

export const SEPARATE_CONSENT_TYPES: ReadonlySet<string> = new Set([
  'location_tracking_consent',
  'biometric_consent',
]);
