import { onSchedule } from 'firebase-functions/v2/scheduler';
import { Timestamp, FieldPath } from 'firebase-admin/firestore';
import { db } from '../config/firebase';
import { expireAttendanceSession, expiryRollout } from '../services/attendanceSession';
import { processAttendanceExpiryEvent } from '../services/attendanceExpiryNotifications';

export async function runAttendanceExpirySweep(now = new Date(), opts: { batchSize?: number; maxPages?: number } = {}) {
  const batchSize = Math.max(1, Math.min(100, opts.batchSize || 100));
  const maxPages = Math.max(1, Math.min(5, opts.maxPages || 5));
  const config = expiryRollout();
  const result = { scanned: 0, expired: 0, delivered: 0, errors: 0, backlog: false };
  if (!config.enabled) return result;
  const stopAt = Date.now() + 420000;
  companies: for (const companyId of config.companies) {
    const progress = db.collection('attendanceExpirySweepState').doc(encodeURIComponent(companyId));
    let cursor = (await progress.get()).data()?.cursor;
    for (let page = 0; page < maxPages; page++) {
      let query = db.collection('attendance').where('companyId', '==', companyId)
        .where('sessionState', '==', 'active').where('expiresAt', '<=', Timestamp.fromDate(now))
        .orderBy('expiresAt').orderBy(FieldPath.documentId()).limit(batchSize);
      if (cursor) query = query.startAfter(cursor.expiresAt, cursor.id);
      const records = await query.get();
      for (const record of records.docs) {
        if (Date.now() >= stopAt) { result.backlog = true; break companies; }
        result.scanned++;
        try {
          if (await expireAttendanceSession(companyId, record.data().empid, record.id)) result.expired++;
        } catch (error) {
          result.errors++;
          console.error('[ATTENDANCE EXPIRY] transition failed', { companyId, attendanceId: record.id, error });
        }
      }
      const last = records.docs[records.docs.length - 1];
      cursor = records.size === batchSize ? { expiresAt: last.data().expiresAt, id: last.id } : null;
      await progress.set({ cursor });
      if (records.size < batchSize) break;
      if (page === maxPages - 1) result.backlog = true;
    }
    const events = await db.collection('attendanceExpiryEvents').where('companyId', '==', companyId)
      .where('deliveryState', '==', 'pending').where('nextAttemptAt', '<=', Timestamp.fromDate(now))
      .orderBy('nextAttemptAt').limit(25).get();
    for (const event of events.docs) {
      if (Date.now() >= stopAt) { result.backlog = true; break companies; }
      try {
        if (await processAttendanceExpiryEvent(event.ref)) result.delivered++;
      } catch (error) {
        result.errors++;
        console.error('[ATTENDANCE EXPIRY] delivery failed', { companyId, eventId: event.id, error });
      }
    }
    if (events.size === 25) result.backlog = true;
  }
  console.info('[ATTENDANCE EXPIRY] sweep', result);
  return result;
}

export const attendanceExpiryMonitor = onSchedule({ schedule: '* * * * *', timeZone: 'Asia/Kolkata',
  region: 'us-central1', retryCount: 3, timeoutSeconds: 540, maxInstances: 1 }, async () => {
  await runAttendanceExpirySweep();
});
