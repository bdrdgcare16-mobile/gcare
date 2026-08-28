// functions/src/models/disciplinaryActions.model.ts
import { DisciplinaryStatus } from '../constants/disciplinary';

export interface DisciplinaryActionHistory {
  status: DisciplinaryStatus;
  changedBy: string;
  changedByName: string;
  changedAt: Date;
  reason?: string | null;
  remarks?: string | null;
}

export interface DisciplinaryAction {
  id?: string;
  companyId: string;

  employeeId: string;
  employeeUid: string;
  employeeName: string;
  department: string;
  designation: string;
  reportingManager: string;
  issuedBy: string | null;

  violationCategory: string;
  otherViolationCategory: string | null;

  incidentDate: string;
  incidentTime: string | null;
  incidentLocation: string | null;
  incidentDescription: string;

  noticeType: string;
  otherNoticeType: string | null;

  severity: string;

  subject: string;
  reason: string;

  responseRequired: boolean;
  responseDueDate: string | null;

  proposedAction: string;
  otherProposedAction: string | null;

  finalAction: string | null;
  finalRemarks: string | null;

  effectiveFrom: string | null;
  effectiveUntil: string | null;

  attachmentUrl: string | null;

  status: DisciplinaryStatus;

  createdBy: string;
  createdByName: string;
  createdByRole: string;
  createdByDesignation: string;
  createdAt: Date;

  updatedBy: string | null;
  updatedAt: Date | null;

  submittedBy: string;
  submittedAt: Date;

  approvedBy: string | null;
  approvedByName: string | null;
  approvedAt: Date | null;

  rejectedBy: string | null;
  rejectedByName: string | null;
  rejectedAt: Date | null;
  rejectionReason: string | null;

  history?: DisciplinaryActionHistory[];
}
