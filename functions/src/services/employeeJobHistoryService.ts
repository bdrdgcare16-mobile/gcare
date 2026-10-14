import { FieldValue } from 'firebase-admin/firestore';
import { getDb } from '../config/firebase';
import { appendAuditEvent } from './auditService';

type JobHistoryEventType =
  | 'JOINED'
  | 'TRANSFERRED'
  | 'DEPARTMENT_CHANGED'
  | 'DESIGNATION_CHANGED'
  | 'PROMOTED'
  | 'COST_CENTER_CHANGED'
  | 'MANAGER_CHANGED'
  | 'EMPLOYMENT_CHANGED';

type JobHistoryParams = {
  transaction: FirebaseFirestore.Transaction;
  companyId: string;
  employeeId: string;
  empid: string;
  changedBy: string;
  eventTypeOverride?: 'PROMOTED';
  before: Record<string, unknown> | null;
  after: Record<string, unknown>;
};

const changeGroups: Array<{ eventType: JobHistoryEventType; fields: string[] }> = [
  { eventType: 'TRANSFERRED', fields: ['branchId', 'location'] },
  { eventType: 'DEPARTMENT_CHANGED', fields: ['departmentId', 'dept'] },
  { eventType: 'DESIGNATION_CHANGED', fields: ['designationId', 'designation'] },
  { eventType: 'COST_CENTER_CHANGED', fields: ['costCenterId'] },
  { eventType: 'MANAGER_CHANGED', fields: ['reportingManagerId'] },
  {
    eventType: 'EMPLOYMENT_CHANGED',
    fields: ['employmentType', 'joiningDate', 'probationStartDate', 'probationEndDate', 'probationStatus'],
  },
];

export function recordEmployeeJobHistory(params: JobHistoryParams): void {
  const historyRef = getDb()
    .collection('employees')
    .doc(params.employeeId)
    .collection('jobHistory');
  const events: Array<{
    eventType: JobHistoryEventType;
    before: Record<string, unknown> | null;
    after: Record<string, unknown>;
    effectiveDate: string;
  }> = [];

  if (!params.before) {
    const joiningDate = String(params.after.joiningDate ?? '').trim();
    if (!joiningDate) return;
    const after: Record<string, unknown> = {};
    for (const field of changeGroups.flatMap((group) => group.fields)) {
      if (params.after[field] !== undefined && params.after[field] !== null) {
        after[field] = params.after[field];
      }
    }
    events.push({
      eventType: 'JOINED',
      before: null,
      after,
      effectiveDate: joiningDate,
    });
  } else {
    for (const group of changeGroups) {
      const before: Record<string, unknown> = {};
      const after: Record<string, unknown> = {};
      for (const field of group.fields) {
        const previous = params.before[field] ?? null;
        const next = params.after[field] ?? null;
        if (JSON.stringify(previous) === JSON.stringify(next)) continue;
        before[field] = previous;
        after[field] = next;
      }
      if (Object.keys(after).length) {
        events.push({
          eventType: group.eventType === 'DESIGNATION_CHANGED' && params.eventTypeOverride
            ? params.eventTypeOverride
            : group.eventType,
          before,
          after,
          effectiveDate: new Date().toISOString().slice(0, 10),
        });
      }
    }
  }

  for (const event of events) {
    const record = {
      companyId: params.companyId,
      employeeId: params.employeeId,
      empid: params.empid,
      eventType: event.eventType,
      effectiveDate: event.effectiveDate,
      before: event.before,
      after: event.after,
      changedBy: params.changedBy,
      createdAt: FieldValue.serverTimestamp(),
    };
    params.transaction.create(historyRef.doc(), record);
    appendAuditEvent(params.transaction, {
      actorId: params.changedBy,
      companyId: params.companyId,
      action: `employee.${event.eventType.toLowerCase()}`,
      resourceType: 'employee',
      resourceId: params.employeeId,
      before: event.before,
      after: event.after,
    });
  }
}
