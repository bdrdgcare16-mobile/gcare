import { Timestamp, FieldValue, DocumentReference } from 'firebase-admin/firestore';
import { db, messaging } from '../config/firebase';
import { COLLECTIONS } from '../constants/collections';
import { randomUUID, createHash } from 'crypto';

export const expiryNotificationId = (attendanceId: string, userId: string) =>
  `attendance_expiry_${createHash('sha256').update(JSON.stringify([attendanceId, userId])).digest('hex')}`;

async function deliver(event: any, user: FirebaseFirestore.QueryDocumentSnapshot) {
  const ref = db.collection(COLLECTIONS.NOTIFICATIONS).doc(expiryNotificationId(event.attendanceId, user.id));
  const title = 'Attendance Session Auto-Inactivated';
  const start = new Intl.DateTimeFormat('en-IN', { timeZone: 'Asia/Kolkata', dateStyle: 'medium', timeStyle: 'medium' })
    .format(new Date(event.checkInTsUtc));
  const body = `${event.name} (${event.empid}), check-in ${start} IST (attendance date ${event.date}): ` +
    'session auto-inactivated after 24 elapsed hours without checkout.';
  const permitted = await db.runTransaction(async tx => {
    const current = await tx.get(user.ref);
    const notification = await tx.get(ref);
    if (current.data()?.companyId !== event.companyId || current.data()?.role !== 'admin') return false;
    if (!notification.exists) tx.set(ref, { companyId: event.companyId, recipientUserId: user.id,
      actorUserId: null, type: 'ATTENDANCE_AUTO_INACTIVATED', title, body, entityType: 'attendance_expiry',
      entityId: event.attendanceId, data: { empid: event.empid, dateIso: event.date },
      isRead: false, readAt: null, createdAt: FieldValue.serverTimestamp(), pushStatus: 'pending' });
    return true;
  });
  if (!permitted) return;
  const previous = (await ref.get()).data()!;
  if (['sent', 'no_active_device'].includes(previous.pushStatus)) return;
  const devices = await db.collection(COLLECTIONS.DEVICE_REGISTRATIONS)
    .where('companyId', '==', event.companyId).where('userId', '==', user.id).where('isActive', '==', true).get();
  const pendingIds: string[] | undefined = previous.pendingDeviceIds;
  const eligible = devices.docs.filter(d => typeof d.data().fcmToken === 'string' && d.data().fcmToken.trim() &&
    (!pendingIds || pendingIds.includes(d.id)));
  if (!eligible.length) {
    await ref.update({ pushStatus: 'no_active_device', pendingDeviceIds: [] });
    return;
  }
  let remaining = eligible.map(d => d.id);
  let successCount = previous.pushSuccessCount || 0;
  await ref.update({ pendingDeviceIds: remaining });
  for (let offset = 0; offset < eligible.length; offset += 500) {
    const currentUser = (await user.ref.get()).data();
    if (currentUser?.companyId !== event.companyId || currentUser?.role !== 'admin') return;
    const batch = eligible.slice(offset, offset + 500);
    const response = await messaging.sendEachForMulticast({ notification: { title, body },
      data: { type: 'ATTENDANCE_AUTO_INACTIVATED', entityType: 'attendance_expiry', entityId: event.attendanceId,
        notificationId: ref.id, empid: event.empid, dateIso: event.date },
      android: { notification: { tag: ref.id } }, apns: { headers: { 'apns-collapse-id': ref.id.slice(-64) } },
      tokens: batch.map(d => d.data().fcmToken) });
    for (let i = 0; i < batch.length; i++) {
      const result = response.responses[i];
      const invalid = ['messaging/invalid-registration-token', 'messaging/registration-token-not-registered'].includes(result.error?.code || '');
      if (result.success) successCount++;
      if (result.success || invalid) remaining = remaining.filter(id => id !== batch[i].id);
      if (invalid) await batch[i].ref.update({ isActive: false, updatedAt: FieldValue.serverTimestamp() });
    }
    await ref.update({ pendingDeviceIds: remaining, pushSuccessCount: successCount,
      pushStatus: remaining.length ? 'pending' : successCount ? 'sent' : 'no_active_device' });
  }
  if (remaining.length) throw new Error('Attendance expiry push delivery requires retry');
}

export async function processAttendanceExpiryEvent(ref: DocumentReference, now = new Date()): Promise<boolean> {
  const claim = randomUUID();
  const event = await db.runTransaction(async tx => {
    const snapshot = await tx.get(ref);
    const data = snapshot.data();
    if (!data || data.deliveryState !== 'pending' || data.nextAttemptAt.toMillis() > now.getTime()) return null;
    tx.update(ref, { claim, attempts: (data.attempts || 0) + 1,
      nextAttemptAt: Timestamp.fromMillis(now.getTime() + 600000) });
    return data;
  });
  if (!event) return false;
  try {
    const admins = await db.collection(COLLECTIONS.USERS).where('companyId', '==', event.companyId).where('role', '==', 'admin').get();
    for (const admin of admins.docs) await deliver(event, admin);
    await db.runTransaction(async tx => {
      const latest = await tx.get(ref);
      if (latest.data()?.claim === claim) tx.update(ref, { deliveryState: 'delivered', deliveredAt: FieldValue.serverTimestamp() });
    });
    return true;
  } catch (error) {
    await db.runTransaction(async tx => {
      const latest = await tx.get(ref);
      if (latest.data()?.claim === claim) tx.update(ref, {
        nextAttemptAt: Timestamp.fromMillis(Date.now() + Math.min(3600000, 60000 * 2 ** Math.min(event.attempts || 0, 6))),
      });
    });
    console.error('[ATTENDANCE EXPIRY] notification retry scheduled', { eventId: ref.id, error });
    return false;
  }
}
