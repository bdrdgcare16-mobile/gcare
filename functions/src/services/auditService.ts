import { FieldValue } from 'firebase-admin/firestore';
import { getDb } from '../config/firebase';
import { COLLECTIONS } from '../constants/collections';

export interface AuditEvent {
  actorId: string;
  actorName?: string | null;
  actorEmail?: string | null;
  companyId: string;
  action: string;
  module?: string;
  resourceType: string;
  resourceId: string;
  employeeId?: string | null;
  employeeName?: string | null;
  before: Record<string, unknown> | null;
  after: Record<string, unknown> | null;
  metadata?: Record<string, unknown> | null;
}

export function appendAuditEvent(
  transaction: FirebaseFirestore.Transaction,
  event: AuditEvent,
): void {
  const ref = getDb().collection(COLLECTIONS.AUDIT_LOGS).doc();
  transaction.create(ref, {
    ...event,
    timestamp: FieldValue.serverTimestamp(),
  });
}

export interface AuditActor {
  actorId: string;
  actorName: string | null;
  actorEmail: string | null;
}

export interface RequestDecisionAuditInput {
  resourceId: string;
  requestType: string;
  employeeId?: string | null;
  employeeName?: string | null;
  beforeStatus: string;
  afterStatus: string;
  remarks?: string | null;
}

/**
 * Maps a leave/request document to a human-readable request category.
 * Shared by approval controllers so audit labels stay consistent.
 */
export function requestTypeFromLeaveDoc(
  data: FirebaseFirestore.DocumentData | undefined,
): string {
  const lt = String(
    data?.leaveType ?? data?.type ?? data?.category ?? data?.requestType ?? '',
  )
    .trim()
    .toLowerCase();
  if (lt.includes('permission')) return 'Permission';
  if (lt.includes('over') && lt.includes('time')) return 'Over Time';
  if (lt.includes('half') && lt.includes('day')) return 'Half Day Leave';
  if (lt.includes('comp') && lt.includes('off')) return 'Comp Off';
  return 'Leave';
}

/**
 * Writes a REQUEST_APPROVED / REQUEST_REJECTED event after a decision has
 * already succeeded. Non-transactional: the decision endpoints perform
 * plain document updates, so the event is appended immediately after the
 * business write. Never throws — an audit failure must not fail the
 * already-successful decision.
 */
export async function logRequestDecisionAudit(
  user: { userId?: string; email?: string; companyId?: string | null },
  input: RequestDecisionAuditInput,
): Promise<void> {
  try {
    const companyId = String(user?.companyId ?? '').trim();
    if (!companyId) return;
    const actor = await resolveAuditActor(user);
    const approved =
      String(input.afterStatus).toLowerCase() === 'approved';
    await getDb()
      .collection(COLLECTIONS.AUDIT_LOGS)
      .add({
        action: approved ? 'REQUEST_APPROVED' : 'REQUEST_REJECTED',
        module: 'approvals',
        actorId: actor.actorId,
        actorName: actor.actorName,
        actorEmail: actor.actorEmail,
        companyId,
        resourceType: 'request',
        resourceId: input.resourceId,
        employeeId: input.employeeId ?? null,
        employeeName: input.employeeName ?? null,
        requestType: input.requestType,
        before: { status: input.beforeStatus },
        after: { status: input.afterStatus },
        metadata: input.remarks ? { remarks: input.remarks } : null,
        timestamp: FieldValue.serverTimestamp(),
      });
  } catch (error) {
    console.error('[AUDIT] request decision log failed:', error);
  }
}

const readTrimmedField = (
  data: FirebaseFirestore.DocumentData | undefined,
  field: string,
): string | null => {
  if (!data) return null;
  for (const [key, value] of Object.entries(data)) {
    if (key.trim() === field) {
      const text = String(value ?? '').trim();
      return text || null;
    }
  }
  return null;
};

/**
 * Resolves the authenticated actor's readable identity from the same-company
 * users record. Falls back to the verified JWT email; never throws, so a
 * missing display name does not block the audited business operation.
 */
export async function resolveAuditActor(user: {
  userId?: string;
  email?: string;
  companyId?: string | null;
}): Promise<AuditActor> {
  const actorId = String(user?.userId ?? '').trim() || 'unknown';
  const companyId = String(user?.companyId ?? '').trim();
  const actorEmail = String(user?.email ?? '').trim().toLowerCase() || null;
  let actorName: string | null = null;

  try {
    if (actorId !== 'unknown' && companyId) {
      const snap = await getDb().collection(COLLECTIONS.USERS).doc(actorId).get();
      if (snap.exists) {
        const data = snap.data();
        if (readTrimmedField(data, 'companyId') === companyId) {
          const fullName = [readTrimmedField(data, 'firstName'), readTrimmedField(data, 'lastName')]
            .filter(Boolean)
            .join(' ');
          actorName = readTrimmedField(data, 'name') ??
            readTrimmedField(data, 'adminName') ??
            (fullName || null);
        }
      }
    }
  } catch (error) {
    console.error('[AUDIT] Actor name resolution failed:', error);
  }

  return { actorId, actorName, actorEmail };
}
