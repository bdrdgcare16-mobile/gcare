import { FieldValue } from 'firebase-admin/firestore';
import { db, messaging } from '../config/firebase';
import { COLLECTIONS } from '../constants/collections';
import { gpsConfirmedOffThisSession } from '../common/utils';

export type NotificationType =
  | 'ATTENDANCE_AUTO_INACTIVATED'
  | 'TASK_ASSIGNED'
  | 'TASK_COMPLETED'
  | 'LEAVE_REQUEST'
  | 'PERMISSION_REQUEST'
  | 'OVERTIME_REQUEST'
  | 'HALF_DAY_REQUEST'
  | 'COMP_OFF_REQUEST'
  | 'REQUEST_APPROVED'
  | 'REQUEST_REJECTED'
  | 'LOCATION_DISABLED'
  | 'LOCATION_ENABLED'
  | 'PERMISSION_REVOKED'
  | 'SUSPICIOUS_LOCATION'
  | 'TRACKING_INTERRUPTED'
  | 'TRACKING_RECOVERED'
  | 'TRACKING_GPS_DELAYED'
  | 'TRACKING_GPS_RECOVERED';

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
    // Persist the navigation metadata too: the admin history screen needs
    // it (empid/dateIso) and the pendingAdminNotify reconciliation uses
    // data.eventTs as the exact dedupe key.
    data: data || {},
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
 * Fetch admin users for a given company.
 * Default role set is ['admin', 'super_admin'] (request submissions and
 * suspicious-location alerts keep that behavior). Tracking-alert callers
 * pass ['admin'] so GPS/heartbeat notifications reach tenant admins only.
 */
export async function getCompanyAdmins(
  companyId: string,
  roles: string[] = ['admin', 'super_admin']
): Promise<Array<{ userId: string; empid: string | null }>> {
  if (!companyId || roles.length === 0) return [];

  try {
    const adminSnap = await db
      .collection(COLLECTIONS.USERS)
      .where('companyId', '==', companyId)
      .where('role', 'in', roles)
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
 * Notify tenant admins (role 'admin' only) of the employee's own company
 * when GPS is switched off or back on during active tracking.
 * Company isolation is inherited from getCompanyAdmins + createAndSend
 * (both filter strictly by companyId). Never throws.
 */
export async function notifyCompanyAdminsOfTrackingEvent(params: {
  companyId: string;
  empid: string;
  employeeName: string;
  eventType: 'location_disabled' | 'location_enabled' | 'permission_revoked';
  eventTs: string;
  dateIso: string;
}): Promise<{ sent: number; failed: number; records: number }> {
  const { companyId, empid, employeeName, eventType, eventTs, dateIso } = params;

  try {
    const admins = await getCompanyAdmins(companyId, ['admin']);
    if (admins.length === 0) {
      console.log('[TRACKING NOTIFICATION] No admins for company', companyId);
      return { sent: 0, failed: 0, records: 0 };
    }

    const off = eventType === 'location_disabled';
    const revoked = eventType === 'permission_revoked';
    const type: NotificationType = revoked
      ? 'PERMISSION_REVOKED'
      : (off ? 'LOCATION_DISABLED' : 'LOCATION_ENABLED');
    const title = revoked
      ? 'Location Permission Revoked'
      : (off ? 'Employee GPS Turned Off' : 'Employee GPS Restored');
    const body = revoked
      ? `Location permission was revoked for ${employeeName} (${empid}) during tracking at ${eventTs}.`
      : off
        ? `${employeeName} (${empid}) turned OFF location services during tracking at ${eventTs}.`
        : `${employeeName} (${empid}) turned location services back ON at ${eventTs}.`;
    const entityId = `${empid}_${dateIso}`;

    let totalSent = 0;
    let totalFailed = 0;
    let records = 0;

    await Promise.all(
      admins.map(async (admin) => {
        try {
          const result = await createAndSend({
            companyId,
            recipientUserId: admin.userId,
            type,
            title,
            body,
            entityType: 'tracking_event',
            entityId,
            data: { empid, eventType, eventTs, dateIso },
          });
          // A notification record now exists regardless of push outcome -
          // callers use `records` to know the in-app history was written.
          records++;
          totalSent += result.sent;
          totalFailed += result.failed;
        } catch (e: any) {
          totalFailed += 1;
          console.error('[TRACKING NOTIFICATION] Failed admin notify:',
            admin.userId, e?.message || String(e));
        }
      })
    );

    console.log('[TRACKING NOTIFICATION RESULT]', {
      companyId, empid, eventType, adminCount: admins.length,
      sent: totalSent, failed: totalFailed, records,
    });
    return { sent: totalSent, failed: totalFailed, records };
  } catch (err: any) {
    console.error('[TRACKING NOTIFICATION] error:', err?.message || String(err));
    return { sent: 0, failed: 0, records: 0 };
  }
}

/**
 * Notify tenant admins (role 'admin' only) when a stored tracking point
 * was flagged as suspicious (mock provider, impossible speed, replay).
 * The caller dedupes per flag kind per session, so a persistent spoofer
 * produces one alert per anomaly class - not one per point. Wording is
 * deliberately factual: flags are evidence for review, never an
 * accusation of fraud. Never throws.
 */
export async function notifyCompanyAdminsOfSuspiciousLocation(params: {
  companyId: string;
  empid: string;
  employeeName: string;
  flags: string[];
  eventTs: string;
  dateIso: string;
}): Promise<{ sent: number; failed: number; records: number }> {
  const { companyId, empid, employeeName, flags, eventTs, dateIso } = params;
  if (!flags.length) return { sent: 0, failed: 0, records: 0 };

  try {
    const admins = await getCompanyAdmins(companyId, ['admin']);
    if (admins.length === 0) {
      console.log('[SUSPICIOUS NOTIFY] No admins for company', companyId);
      return { sent: 0, failed: 0, records: 0 };
    }

    const title = 'Suspicious Location Flagged';
    const body =
      `${employeeName} (${empid}): tracking point flagged for review ` +
      `(${flags.join(', ')}) at ${eventTs}.`;
    const entityId = `${empid}_${dateIso}`;

    let totalSent = 0;
    let totalFailed = 0;
    let records = 0;

    await Promise.all(
      admins.map(async (admin) => {
        try {
          const result = await createAndSend({
            companyId,
            recipientUserId: admin.userId,
            type: 'SUSPICIOUS_LOCATION',
            title,
            body,
            entityType: 'tracking_event',
            entityId,
            data: { empid, eventType: 'suspicious_location', eventTs, dateIso },
          });
          records++;
          totalSent += result.sent;
          totalFailed += result.failed;
        } catch (e: any) {
          totalFailed += 1;
          console.error('[SUSPICIOUS NOTIFY] Failed admin notify:',
            admin.userId, e?.message || String(e));
        }
      })
    );

    console.log('[SUSPICIOUS NOTIFY RESULT]', {
      companyId, empid, flags, adminCount: admins.length,
      sent: totalSent, failed: totalFailed, records,
    });
    return { sent: totalSent, failed: totalFailed, records };
  } catch (err: any) {
    console.error('[SUSPICIOUS NOTIFY] error:', err?.message || String(err));
    return { sent: 0, failed: 0, records: 0 };
  }
}

/**
 * Notify tenant admins (role 'admin' only — super_admin / platform_admin
 * and other roles are excluded) when a live tracking session misses
 * location updates past the heartbeat threshold ("Tracking Interrupted"),
 * or when contact resumes after an alerted interruption ("Tracking
 * Resumed").
 *
 * Wording deliberately avoids asserting a cause: a gap can mean Doze,
 * airplane mode, dead battery, app swipe-kill, force-stop, or a network
 * outage - the message only reports that updates stopped/resumed.
 * Company isolation inherited from getCompanyAdmins + createAndSend.
 * Never throws.
 */
export async function notifyCompanyAdminsOfTrackingInterruption(params: {
  companyId: string;
  empid: string;
  employeeName: string;
  /** interrupted/recovered = device-contact gaps; gps_delayed/gps_recovered
   *  = device alive but producing no valid GPS fix. */
  kind: 'interrupted' | 'recovered' | 'gps_delayed' | 'gps_recovered';
  /** ISO timestamp - interruption: last contact; recovered: resume time. */
  sinceTs: string;
  dateIso: string;
}): Promise<{ sent: number; failed: number; records: number }> {
  const { companyId, empid, employeeName, kind, sinceTs, dateIso } = params;

  try {
    // Tracking/GPS alerts go to tenant admins only — never super_admin,
    // platform_admin, or any other role.
    const admins = await getCompanyAdmins(companyId, ['admin']);
    if (admins.length === 0) {
      console.log('[HEARTBEAT NOTIFY] No admins for company', companyId);
      return { sent: 0, failed: 0, records: 0 };
    }

    const gpsGap = kind === 'gps_delayed' || kind === 'gps_recovered';
    const type: NotificationType =
      kind === 'interrupted' ? 'TRACKING_INTERRUPTED'
      : kind === 'recovered' ? 'TRACKING_RECOVERED'
      : kind === 'gps_delayed' ? 'TRACKING_GPS_DELAYED'
      : 'TRACKING_GPS_RECOVERED';
    const title =
      kind === 'interrupted' ? 'Tracking Interrupted'
      : kind === 'recovered' ? 'Tracking Resumed'
      : kind === 'gps_delayed' ? 'GPS Updates Delayed'
      : 'GPS Updates Recovered';
    const body =
      kind === 'interrupted'
        ? `Location updates missing for ${employeeName} (${empid}) since ${sinceTs}. ` +
          'The app may be closed, offline, out of battery, or GPS may be off.'
      : kind === 'recovered'
        ? `${employeeName} (${empid}) location updates resumed at ${sinceTs}.`
      : kind === 'gps_delayed'
        ? `${employeeName} (${empid}) has no valid GPS fix since ${sinceTs}, ` +
          'but the tracking service is still running. GPS may be obstructed, ' +
          'unavailable, or unable to get a lock.'
        : `${employeeName} (${empid}) GPS fixes resumed at ${sinceTs}.`;
    const entityId = gpsGap
      ? `${empid}_${dateIso}_gps` : `${empid}_${dateIso}`;

    let totalSent = 0;
    let totalFailed = 0;
    let records = 0;

    await Promise.all(
      admins.map(async (admin) => {
        try {
          const result = await createAndSend({
            companyId,
            recipientUserId: admin.userId,
            type,
            title,
            body,
            entityType: 'tracking_heartbeat',
            entityId,
            data: { empid, kind, sinceTs, dateIso },
          });
          records++;
          totalSent += result.sent;
          totalFailed += result.failed;
        } catch (e: any) {
          totalFailed += 1;
          console.error('[HEARTBEAT NOTIFY] Failed admin notify:',
            admin.userId, e?.message || String(e));
        }
      })
    );

    console.log('[HEARTBEAT NOTIFY RESULT]', {
      companyId, empid, kind, adminCount: admins.length,
      sent: totalSent, failed: totalFailed, records,
    });
    return { sent: totalSent, failed: totalFailed, records };
  } catch (err: any) {
    console.error('[HEARTBEAT NOTIFY] error:', err?.message || String(err));
    return { sent: 0, failed: 0, records: 0 };
  }
}

/**
 * Reconciliation sweep for tracking sessions whose admin notification never
 * materialized. POST /tracking/event flags a doc with pendingAdminNotify
 * (boolean) + pendingAdminNotifyEvent (details) ONLY when zero notification
 * records were created (sent=0 && failed=0), so a sweep can never duplicate
 * an existing record - it additionally dedupes on (type, entityId,
 * data.eventTs) before notifying. Bounded per call so it can run lazily
 * inside GET /notifications without unbounded latency; leftover flags are
 * picked up by the next sweep. Never throws.
 */
export async function reconcilePendingAdminNotifies(
  companyId: string,
  { limit = 25 }: { limit?: number } = {},
): Promise<{ scanned: number; notified: number; cleared: number }> {
  const out = { scanned: 0, notified: 0, cleared: 0 };
  if (!companyId) return out;

  let snap;
  try {
    snap = await db
      .collection('tracking')
      .where('companyId', '==', companyId)
      .where('pendingAdminNotify', '==', true)
      .limit(limit)
      .get();
  } catch (err: any) {
    console.error('[RECONCILE NOTIFY] query failed:', err?.message || String(err));
    return out;
  }

  out.scanned = snap.size;
  const clearFlags = (ref: FirebaseFirestore.DocumentReference) =>
    ref.update({
      pendingAdminNotify: FieldValue.delete(),
      pendingAdminNotifyEvent: FieldValue.delete(),
    });

  for (const docSnap of snap.docs) {
    try {
      // A closed session must never emit a delayed GPS-off alert - the
      // admin already knows tracking ended; the pending flag is stale.
      if (docSnap.data()?.endedAt != null) {
        await clearFlags(docSnap.ref);
        out.cleared++;
        continue;
      }

      const evt = docSnap.data()?.pendingAdminNotifyEvent;
      const empid = String(evt?.empid ?? docSnap.data()?.empid ?? '').trim();
      const dateIso = String(evt?.dateIso ?? docSnap.data()?.dateIso ?? '').trim();
      const rawType = String(evt?.type ?? '');
      const type = rawType === 'location_enabled' || rawType === 'permission_revoked'
        ? rawType : 'location_disabled';
      const ts = String(evt?.ts ?? '');

      if (!empid || !dateIso || !ts) {
        // Flag with no usable event payload - clear it, there is nothing to send.
        await clearFlags(docSnap.ref);
        out.cleared++;
        continue;
      }

      // A 'restored' retry is only notify-worthy when THIS session holds
      // a recorded GPS-OFF event - same rule as trackingAddEvent. Stale
      // flags predating the gate (or queued from a previous session) are
      // cleared, never delivered.
      if (type === 'location_enabled' &&
          !gpsConfirmedOffThisSession(docSnap.data())) {
        await clearFlags(docSnap.ref);
        out.cleared++;
        continue;
      }

      // Exact dedupe: a notification record already covering THIS event
      // (same employee+day entityId and same event timestamp) means a
      // previous send did land - just clear the stale flag.
      const entityId = `${empid}_${dateIso}`;
      const notifType: NotificationType =
        type === 'permission_revoked' ? 'PERMISSION_REVOKED'
          : type === 'location_disabled' ? 'LOCATION_DISABLED' : 'LOCATION_ENABLED';
      const existing = await db
        .collection(COLLECTIONS.NOTIFICATIONS)
        .where('companyId', '==', companyId)
        .where('entityType', '==', 'tracking_event')
        .where('entityId', '==', entityId)
        .where('type', '==', notifType)
        .get();
      const alreadyNotified = existing.docs.some(
        (n) => (n.data() as any)?.data?.eventTs === ts,
      );

      if (alreadyNotified) {
        await clearFlags(docSnap.ref);
        out.cleared++;
        continue;
      }

      let employeeName = empid;
      try {
        const empSnap = await db
          .collection(COLLECTIONS.EMPLOYEES)
          .where('companyId', '==', companyId)
          .where('empid', '==', empid)
          .limit(1)
          .get();
        const n = empSnap.docs[0]?.data()?.name;
        if (n) employeeName = String(n);
      } catch (_) { /* name lookup is best-effort */ }

      const result = await notifyCompanyAdminsOfTrackingEvent({
        companyId,
        empid,
        employeeName,
        eventType: type,
        eventTs: ts,
        dateIso,
      });
      // records>0 means notification history exists now (push outcome is
      // irrelevant to history); 0 means still no admins - keep the flag so
      // a later sweep retries after an admin is onboarded.
      if (result.records > 0) {
        await clearFlags(docSnap.ref);
        out.notified++;
      }
    } catch (err: any) {
      console.error(
        '[RECONCILE NOTIFY] doc failed (kept for next sweep):',
        docSnap.id,
        err?.message || String(err),
      );
    }
  }

  if (out.scanned) {
    console.log('[RECONCILE NOTIFY]', { companyId, ...out });
  }
  return out;
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
