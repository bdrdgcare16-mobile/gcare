// functions/src/validators/disciplinaryActions.validator.ts
import { Request } from 'express';
import {
  DISCIPLINARY_STATUS,
  VIOLATION_CATEGORIES,
  NOTICE_TYPES,
  SEVERITY_LEVELS,
  PROPOSED_DISCIPLINARY_ACTIONS,
  OTHER_OPTION,
} from '../constants/disciplinary';

const isEmpty = (value: any): boolean =>
  value === undefined || value === null || String(value).trim() === '';

const isValidDate = (value: string): boolean => {
  if (isEmpty(value)) return false;
  const d = new Date(value);
  return !isNaN(d.getTime());
};

export const validateDisciplinaryAction = (req: Request): string[] => {
  const errors: string[] = [];
  const body = req.body || {};

  const requiredFields = [
    'employeeId',
    'reportingManager',
    'issuedBy',
    'violationCategory',
    'incidentDate',
    'incidentDescription',
    'noticeType',
    'severity',
    'subject',
    'reason',
    'proposedAction',
  ];

  for (const field of requiredFields) {
    if (isEmpty(body[field])) {
      errors.push(`${field} is required`);
    }
  }

  // Employee ID must not be trusted for company mapping; that is enforced
  // in the service layer. Here we just ensure it is present.
  if (!isEmpty(body.employeeId) && String(body.employeeId).trim().length < 1) {
    errors.push('employeeId is invalid');
  }

  // Violation category must be one of the allowed values
  if (
    !isEmpty(body.violationCategory) &&
    !VIOLATION_CATEGORIES.includes(body.violationCategory)
  ) {
    errors.push('Invalid violation category');
  }

  if (
    body.violationCategory === OTHER_OPTION &&
    isEmpty(body.otherViolationCategory)
  ) {
    errors.push('otherViolationCategory is required when category is Other');
  }

  // Incident date validation
  if (!isEmpty(body.incidentDate) && !isValidDate(body.incidentDate)) {
    errors.push('incidentDate must be a valid date');
  }

  // Notice type validation
  if (
    !isEmpty(body.noticeType) &&
    !NOTICE_TYPES.includes(body.noticeType)
  ) {
    errors.push('Invalid notice type');
  }

  if (
    body.noticeType === OTHER_OPTION &&
    isEmpty(body.otherNoticeType)
  ) {
    errors.push('otherNoticeType is required when notice type is Other');
  }

  // Severity validation
  if (
    !isEmpty(body.severity) &&
    !SEVERITY_LEVELS.includes(body.severity)
  ) {
    errors.push('Invalid severity');
  }

  // Proposed action validation
  if (
    !isEmpty(body.proposedAction) &&
    !PROPOSED_DISCIPLINARY_ACTIONS.includes(body.proposedAction)
  ) {
    errors.push('Invalid proposed disciplinary action');
  }

  if (
    body.proposedAction === OTHER_OPTION &&
    isEmpty(body.otherProposedAction)
  ) {
    errors.push('otherProposedAction is required when proposed action is Other');
  }

  // Response required validation
  if (body.responseRequired === true || body.responseRequired === 'true' ||
      body.responseRequired === 'yes' || body.responseRequired === 'Yes') {
    if (isEmpty(body.responseDueDate)) {
      errors.push('responseDueDate is required when response is required');
    } else if (!isValidDate(body.responseDueDate)) {
      errors.push('responseDueDate must be a valid date');
    }
  }

  // Effective dates validation (if provided)
  if (!isEmpty(body.effectiveFrom) && !isValidDate(body.effectiveFrom)) {
    errors.push('effectiveFrom must be a valid date');
  }

  if (!isEmpty(body.effectiveUntil) && !isValidDate(body.effectiveUntil)) {
    errors.push('effectiveUntil must be a valid date');
  }

  if (
    !isEmpty(body.effectiveFrom) &&
    !isEmpty(body.effectiveUntil)
  ) {
    const from = new Date(body.effectiveFrom).getTime();
    const until = new Date(body.effectiveUntil).getTime();
    if (until < from) {
      errors.push('effectiveUntil cannot be earlier than effectiveFrom');
    }
  }

  return errors;
};

export const validateRejectDisciplinaryAction = (req: Request): string[] => {
  const errors: string[] = [];
  const body = req.body || {};

  if (isEmpty(body.rejectionReason)) {
    errors.push('rejectionReason is required');
  }

  return errors;
};

export const isValidStatusTransition = (
  current: string,
  next: string
): boolean => {
  const transitions: Record<string, string[]> = {
    [DISCIPLINARY_STATUS.DRAFT]: [DISCIPLINARY_STATUS.PENDING],
    [DISCIPLINARY_STATUS.PENDING]: [
      DISCIPLINARY_STATUS.APPROVED,
      DISCIPLINARY_STATUS.REJECTED,
    ],
    [DISCIPLINARY_STATUS.REJECTED]: [
      DISCIPLINARY_STATUS.PENDING,
      DISCIPLINARY_STATUS.CLOSED,
    ],
    [DISCIPLINARY_STATUS.APPROVED]: [DISCIPLINARY_STATUS.CLOSED],
    [DISCIPLINARY_STATUS.CLOSED]: [],
  };

  return (transitions[current] || []).includes(next);
};
