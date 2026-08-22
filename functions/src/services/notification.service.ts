import { FieldValue } from 'firebase-admin/firestore';
import { db, messaging } from '../config/firebase';
import { COLLECTIONS } from '../constants/collections';

export type NotificationType =
  | 'TASK_ASSIGNED'
  | 'TASK_COMPLETED'
  | 'LEAVE_REQUEST'
  | 'PERMISSION_REQUEST'
  | 'OVERTIME_REQUEST'
  | 'HALF_DAY_REQUEST'
  | 'COMP_OFF_REQUEST'
  | 'REQUEST_APPROVED'
  | 'REQUEST_REJECTED';

interface CreateAndSendParams {
  companyId: string;
  recipientUserId: string;
  actorUserId?: string | null;
  type: NotificationType;
  title: string;
  body: string;
  entityType: string;
  entityId: string;
  /** Extra navigation metadata only. Never put sensitive data here. */
  data?: Record<string, string>;
}

interface CreateAndSendResult {
  notificationId: string;
  sent: number;
  failed: number;
}

/**
 * Resolve the Firestore `users` document id (JWT userId) for an employee,
 * given their empid + companyId. Tasks store `assignedTo` as an empid, but
 * device registrations / notifications are keyed by userId, so this bridges
 * the two.
 */
export async function resolveUserIdByEmpid(
  companyId: string,
  empid: string
): Promise<string | null> {
  if (!companyId || !empid) return null;

  const snap = await db
    .collection(COLLECTIONS.USERS)
    .where('companyId', '==', companyId)
    .where('empid', '==', empid)
    .limit(1)
    .get();

  if (snap.empty) return null;
  return snap.docs[0].id;
}

/**
 * Creates a notification history record and attempts to push it to all
 * active devices registered for the recipient (within the same company).
 * Push delivery failures never throw — the caller's primary flow (e.g. task
 * creation) must not fail because a notification could not be delivered.
 */
export async function createAndSend(
  params: CreateAndSendParams
): Promise<CreateAndSendResult> {
  const {
    companyId,
    recipientUserId,
    actorUserId,
    type,
    title,
    body,
    entityType,
    entityId,
    data,
  } = params;

  const notifRef = db.collection(COLLECTIONS.NOTIFICATIONS).doc();
  const notificationId = notifRef.id;

  await notifRef.set({
    companyId,
    recipientUserId,
    actorUserId: actorUserId || null,
    type,
    title,
    body,
    entityType,
    entityId,
    isRead: false,
    pushStatus: 'pending',
    createdAt: FieldValue.serverTimestamp(),
    readAt: null,
  });

  try {
    // Multi-company isolation: only devices for this company + this user.
    const deviceSnap = await db
      .collection(COLLECTIONS.DEVICE_REGISTRATIONS)
      .where('companyId', '==', companyId)
      .where('userId', '==', recipientUserId)
      .where('isActive', '==', true)
      .get();

    console.log('TASK NOTIFICATION:', {
      taskId: entityId,
      companyId,
      recipientUserId,
      deviceCount: deviceSnap.size,
    });

    if (deviceSnap.empty) {
      await notifRef.update({ pushStatus: 'no_active_device' });
      return { notificationId, sent: 0, failed: 0 };
    }

    const tokens = deviceSnap.docs
      .map((d) => (d.data().fcmToken as string) || '')
      .filter((t) => t.trim().length > 0);

    if (!tokens.length) {
      await notifRef.update({ pushStatus: 'no_active_device' });
      return { notificationId, sent: 0, failed: 0 };
    }

    const response = await messaging.sendEachForMulticast({
      notification: { title, body },
      data: {
        type,
        entityType,
        entityId,
        notificationId,
        ...(data || {}),
      },
      tokens,
    });

    let successCount = 0;
    let failureCount = 0;
    const staleDocRefs: FirebaseFirestore.DocumentReference[] = [];

    response.responses.forEach((r, idx) => {
      if (r.success) {
        successCount++;
        return;
      }

      failureCount++;
      const code = r.error?.code || '';
      console.error(
        '[NotificationService] FCM send failed:',
        code,
        r.error?.message
      );

      if (
        code === 'messaging/invalid-registration-token' ||
        code === 'messaging/registration-token-not-registered'
      ) {
        staleDocRefs.push(deviceSnap.docs[idx].ref);
      }
    });

    if (staleDocRefs.length) {
      await Promise.all(
        staleDocRefs.map((ref) =>
          ref.update({
            isActive: false,
            updatedAt: FieldValue.serverTimestamp(),
          })
        )
      );
    }

    console.log('TASK NOTIFICATION RESULT:', {
      taskId: entityId,
      companyId,
      recipientUserId,
      deviceCount: tokens.length,
      successCount,
      failureCount,
    });

    await notifRef.update({
      pushStatus: successCount > 0 ? 'sent' : 'failed',
    });

    return { notificationId, sent: successCount, failed: failureCount };
  } catch (err: any) {
    console.error(
      '[NotificationService] createAndSend error:',
      err?.message || String(err)
    );
    try {
      await notifRef.update({ pushStatus: 'failed' });
    } catch {
      // best-effort only
    }
    return { notificationId, sent: 0, failed: 0 };
  }
}

/**
 * Fetch all admin users (role='admin' or 'super_admin') for a given company.
 * Used to notify all company admins when an employee submits a request.
 */
export async function getCompanyAdmins(
  companyId: string
): Promise<Array<{ userId: string; empid: string | null }>> {
  if (!companyId) return [];

  try {
    const adminSnap = await db
      .collection(COLLECTIONS.USERS)
      .where('companyId', '==', companyId)
      .where('role', 'in', ['admin', 'super_admin'])
      .get();

    console.log('[REQUEST ADMIN COUNT]', {
      companyId,
      count: adminSnap.size,
    });

    return adminSnap.docs.map((doc) => ({
      userId: doc.id,
      empid: doc.data().empid || null,
    }));
  } catch (err: any) {
    console.error(
      '[NotificationService] getCompanyAdmins error:',
      err?.message || String(err)
    );
    return [];
  }
}

/**
 * Send notification to all company admins when an employee submits a request.
 * Never throws - notification failures should not block request creation.
 */
export async function notifyCompanyAdminsOfRequest(params: {
  companyId: string;
  requestType: string;
  employeeId: string;
  employeeName: string;
  requestId: string;
  requestCategory?: string; // 'leave', 'permission', 'overtime', 'halfday', 'compoff'
}): Promise<{ sent: number; failed: number }> {
  const {
    companyId,
    requestType,
    employeeId,
    employeeName,
    requestId,
    requestCategory = 'leave',
  } = params;

  console.log('[REQUEST NOTIFICATION]', {
    type: requestType,
    companyId,
    employeeId,
    requestId,
  });

  try {
    const admins = await getCompanyAdmins(companyId);
    if (admins.length === 0) {
      console.log('[REQUEST NOTIFICATION] No admins found for company', companyId);
      return { sent: 0, failed: 0 };
    }

    console.log('[REQUEST ADMIN COUNT]', {
      companyId,
      count: admins.length,
    });

    // Determine notification type based on request category
    let notificationType: NotificationType = 'LEAVE_REQUEST';
    const categoryLower = requestCategory.toLowerCase();

    if (categoryLower.includes('permission')) {
      notificationType = 'PERMISSION_REQUEST';
    } else if (categoryLower.includes('overtime') || categoryLower.includes('over time')) {
      notificationType = 'OVERTIME_REQUEST';
    } else if (categoryLower.includes('half day') || categoryLower.includes('halfday')) {
      notificationType = 'HALF_DAY_REQUEST';
    } else if (categoryLower.includes('comp off') || categoryLower.includes('compoff')) {
      notificationType = 'COMP_OFF_REQUEST';
    }

    const title = `New ${requestType} Request`;
    const body = `${employeeName} (${employeeId}) submitted a ${requestType.toLowerCase()}.`;

    let totalSent = 0;
    let totalFailed = 0;

    // Send notification to each admin
    await Promise.all(
      admins.map(async (admin) => {
        try {
          console.log('[REQUEST FCM SEND]', {
            userId: admin.userId,
            tokenCount: 1,
          });

          const result = await createAndSend({
            companyId,
            recipientUserId: admin.userId,
            type: notificationType,
            title,
            body,
            entityType: requestCategory,
            entityId: requestId,
            data: {
              requestId,
              employeeId,
              requestType,
            },
          });

          totalSent += result.sent;
          totalFailed += result.failed;
        } catch (e: any) {
          totalFailed += 1;
          console.error(
            '[REQUEST NOTIFICATION] Failed to notify admin:',
            admin.userId,
            e?.message || String(e)
          );
        }
      })
    );

    console.log('[REQUEST NOTIFICATION RESULT]', {
      companyId,
      adminCount: admins.length,
      sent: totalSent,
      failed: totalFailed,
    });

    return { sent: totalSent, failed: totalFailed };
  } catch (err: any) {
    console.error(
      '[NotificationService] notifyCompanyAdminsOfRequest error:',
      err?.message || String(err)
    );
    return { sent: 0, failed: 0 };
  }
}

/**
 * Send notification to employee when their request is approved or rejected.
 * Never throws - notification failures should not block status update.
 */
export async function notifyEmployeeOfRequestUpdate(params: {
  companyId: string;
  employeeUserId: string;
  requestType: string;
  status: 'Approved' | 'Rejected';
  requestId: string;
  requestCategory?: string;
}): Promise<{ sent: number; failed: number }> {
  const {
    companyId,
    employeeUserId,
    requestType,
    status,
    requestId,
    requestCategory = 'leave',
  } = params;

  try {
    const notificationType: NotificationType =
      status === 'Approved' ? 'REQUEST_APPROVED' : 'REQUEST_REJECTED';

    const title = `${requestType} ${status}`;
    const body = `Your ${requestType.toLowerCase()} has been ${status.toLowerCase()}.`;

    console.log('[REQUEST UPDATE NOTIFICATION]', {
      companyId,
      employeeUserId,
      requestType,
      status,
      requestId,
    });

    console.log('[REQUEST FCM SEND]', {
      userId: employeeUserId,
      tokenCount: 1,
    });

    const result = await createAndSend({
      companyId,
      recipientUserId: employeeUserId,
      type: notificationType,
      title,
      body,
      entityType: requestCategory,
      entityId: requestId,
      data: {
        requestId,
        requestType,
        status,
      },
    });

    console.log('[REQUEST UPDATE NOTIFICATION RESULT]', {
      companyId,
      employeeUserId,
      sent: result.sent,
      failed: result.failed,
    });

    return { sent: result.sent, failed: result.failed };
  } catch (err: any) {
    console.error(
      '[NotificationService] notifyEmployeeOfRequestUpdate error:',
      err?.message || String(err)
    );
    return { sent: 0, failed: 0 };
  }
}
