// lib/functions/src/constants/disciplinary.ts
// Normalized dropdown values and status values for the Disciplinary Actions module.

export const DISCIPLINARY_STATUS = {
  DRAFT: 'draft',
  PENDING: 'pending',
  APPROVED: 'approved',
  REJECTED: 'rejected',
  CLOSED: 'closed',
} as const;

export type DisciplinaryStatus =
  | 'draft'
  | 'pending'
  | 'approved'
  | 'rejected'
  | 'closed';

export const VIOLATION_CATEGORIES = [
  'Attendance Violation',
  'Unauthorized Absence / Leave Violation',
  'Poor Performance',
  'Misconduct / Insubordination',
  'Workplace Behaviour Violation',
  'Company Policy / Code of Conduct Violation',
  'Confidentiality / Data Security Violation',
  'Fraud / Falsification / Theft',
  'Negligence / Safety Violation',
  'Other',
] as const;

export type ViolationCategory = typeof VIOLATION_CATEGORIES[number];

export const NOTICE_TYPES = [
  'Verbal Warning',
  'Written Warning',
  'Memo',
  'Warning Letter',
  'Show Cause Notice',
  'Explanation Letter Request',
  'Charge Memo',
  'Final Warning',
  'Suspension Notice',
  'Domestic Enquiry Notice',
  'Disciplinary Hearing Notice',
  'Termination Notice',
  'Other',
] as const;

export type NoticeType = typeof NOTICE_TYPES[number];

export const SEVERITY_LEVELS = [
  'Low',
  'Medium',
  'High',
  'Critical',
] as const;

export type Severity = typeof SEVERITY_LEVELS[number];

export const PROPOSED_DISCIPLINARY_ACTIONS = [
  'Counselling',
  'Verbal Warning',
  'Written Warning',
  'First Warning',
  'Second Warning',
  'Final Warning',
  'Formal Memo',
  'Show Cause Notice',
  'Explanation Required',
  'Performance Improvement Plan',
  'Mandatory Training',
  'Written Apology',
  'Transfer of Responsibility',
  'Change of Duties',
  'Removal of Certain Responsibilities',
  'Restriction of System Access',
  'Restriction of Company Asset Access',
  'Recovery of Company Property',
  'Suspension Pending Enquiry',
  'Suspension for Defined Period',
  'Domestic Enquiry',
  'Formal Disciplinary Hearing',
  'Final Warning with Monitoring Period',
  'Termination Recommendation',
  'Termination of Employment',
  'No Further Action',
  'Case Closed After Explanation',
  'Other',
] as const;

export type ProposedDisciplinaryAction =
  typeof PROPOSED_DISCIPLINARY_ACTIONS[number];

export const OTHER_OPTION = 'Other' as const;
