import { Timestamp } from 'firebase-admin/firestore';

export interface EmployeePolicyAcceptance {
  id?: string;
  userId: string;
  organizationId: string;
  policyId: string;
  policyVersion: number;
  contentHash: string;
  acceptedAt: Timestamp;
  ipAddress?: string;
  userAgent?: string;
  revokedAt?: Timestamp | null;
  revocationReason?: string;
}

export const EMPLOYEE_POLICY_ACCEPTANCES_COL = 'employeePolicyAcceptances';
