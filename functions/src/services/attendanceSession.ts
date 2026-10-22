import { db } from '../config/firebase';
import { FieldValue, Timestamp, Transaction, DocumentSnapshot } from 'firebase-admin/firestore';

export const employeeAttendance = (companyId: string, empid: string) =>
  db.collection('attendance').where('companyId', '==', companyId).where('empid', '==', empid);

export function expiryRollout() {
  const raw = process.env.ATTENDANCE_EXPIRY_EFFECTIVE_AT || '';
  const effectiveAt = /(?:Z|[+-]\d{2}:\d{2})$/.test(raw) ? Date.parse(raw) : NaN;
  const companies = [...new Set((process.env.ATTENDANCE_EXPIRY_COMPANIES || '').split(',').map(s => s.trim()).filter(Boolean))];
  return { enabled: process.env.ATTENDANCE_EXPIRY_ENABLED === 'true' && Number.isFinite(effectiveAt), effectiveAt, companies };
}

export const isOpenAttendance = (record: any): boolean =>
  !!(record.checkIn || record.checkInTsUtc) && !record.checkOut && !record.checkOutTsUtc &&
  !['checked_out', 'auto_inactive'].includes(record.sessionState);

export function attendanceInstant(record: any, field: 'checkIn' | 'checkOut'): Date | null {
  const raw = record[`${field}TsUtc`];
  const explicit = raw?.toDate ? raw.toDate() : raw ? new Date(raw) : null;
  if (explicit && Number.isFinite(explicit.getTime())) return explicit;
  const date = field === 'checkOut' ? record.checkOutDate || record.date : record.date;
  const time = record[field];
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date || '') ||
      !/^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/.test(time || '')) return null;
  const instant = new Date(`${date}T${time.length === 5 ? `${time}:00` : time}+05:30`);
  if (!Number.isFinite(instant.getTime()) ||
      new Date(instant.getTime() + 19800000).toISOString().slice(0, 10) !== date) return null;
  if (field === 'checkOut' && !record.checkOutDate) {
    const start = attendanceInstant(record, 'checkIn');
    if (start && instant < start) instant.setUTCDate(instant.getUTCDate() + 1);
  }
  return instant;
}

export function attendanceDeadline(record: any): Date | null {
  const config = expiryRollout();
  const start = attendanceInstant(record, 'checkIn');
  if (!config.enabled || !config.companies.includes(record.companyId) || record.expiryPolicyVersion !== 1 ||
      !start || start.getTime() < config.effectiveAt) return null;
  const raw = record.expiresAt;
  const stored = raw?.toDate ? raw.toDate() : raw ? new Date(raw) : null;
  const deadline = new Date(start.getTime() + 86400000);
  return stored && stored.getTime() === deadline.getTime() ? deadline : null;
}

export const attendanceIsDue = (record: any, now = new Date()) =>
  isOpenAttendance(record) && !!attendanceDeadline(record) && now.getTime() >= attendanceDeadline(record)!.getTime();

export function attendanceSessionFields(record: any) {
  const start = attendanceInstant(record, 'checkIn');
  const end = attendanceInstant(record, 'checkOut');
  const autoInactive = record.sessionState === 'auto_inactive';
  return {
    date: record.date,
    checkIn: record.checkIn || null,
    checkOut: autoInactive ? null : record.checkOut || null,
    checkInTsUtc: start?.toISOString() || null,
    checkOutTsUtc: autoInactive ? null : end?.toISOString() || null,
    checkOutDate: !autoInactive && end ? new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata' }).format(end) : null,
    workedSeconds: !autoInactive && start && end ? Math.max(0, Math.floor((end.getTime() - start.getTime()) / 1000)) : null,
    checkInSource: record.checkInSource || null,
    sessionState: record.sessionState || (end ? 'checked_out' : start ? 'active' : null),
    serverNowUtc: new Date().toISOString(),
    expiresAt: attendanceDeadline(record)?.toISOString() || null,
    autoInactiveAt: record.autoInactiveAt?.toDate?.().toISOString() || null,
    autoInactiveProcessedAt: record.autoInactiveProcessedAt?.toDate?.().toISOString() || null,
  };
}

export function selectAttendance(docs: any[], today: string) {
  const active = docs.filter(d => isOpenAttendance(d.data()));
  if (active.length > 1) throw new Error('Multiple active attendance sessions; administrator review required');
  return active[0] || docs.find(d => d.data().date === today) ||
    docs.filter(d => {
      const end = attendanceInstant(d.data(), 'checkOut') || d.data().autoInactiveAt?.toDate?.();
      return end && new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata' }).format(end) === today;
    }).sort((a, b) => {
      const instant = (d: any) => attendanceInstant(d.data(), 'checkOut') || d.data().autoInactiveAt?.toDate?.();
      return instant(b)!.getTime() - instant(a)!.getTime();
    })[0];
}

async function expireInTransaction(tx: Transaction, doc: DocumentSnapshot, now: Date): Promise<boolean> {
  const record = doc.data();
  if (!record || !attendanceIsDue(record, now)) return false;
  const { companyId, empid, date } = record;
  if (!companyId || !empid || !/^\d{4}-\d{2}-\d{2}$/.test(date || '')) return false;
  const sessions = await tx.get(employeeAttendance(companyId, empid));
  if (sessions.docs.filter(d => isOpenAttendance(d.data())).length !== 1) {
    console.warn('[ATTENDANCE EXPIRY] ambiguous sessions require review', { companyId, empid });
    return false;
  }
  const trackingRef = db.collection('tracking').doc(`${companyId}_${empid}_${date}`);
  const tracking = await tx.get(trackingRef);
  const lockRef = db.collection('attendanceSessionLocks').doc(encodeURIComponent(JSON.stringify([companyId, empid])));
  const lock = await tx.get(lockRef);
  const employees = await tx.get(db.collection('employees').where('companyId', '==', companyId).where('empid', '==', empid).limit(2));
  const deadline = attendanceDeadline(record)!;
  const eventRef = db.collection('attendanceExpiryEvents').doc(doc.id);
  const event = await tx.get(eventRef);
  tx.update(doc.ref, { sessionState: 'auto_inactive', autoInactiveAt: Timestamp.fromDate(deadline),
    autoInactiveProcessedAt: Timestamp.fromDate(now), updatedAt: FieldValue.serverTimestamp() });
  const t = tracking.data();
  if (t && t.companyId === companyId && t.empid === empid && t.dateIso === date && !t.endedAt &&
      (t.attendanceId === doc.id || (!t.attendanceId && lock.data()?.attendanceId === doc.id))) {
    tx.update(trackingRef, { endedAt: deadline.toISOString(), lastUpdateAt: now.toISOString(),
      interruption: FieldValue.delete(), gpsGap: FieldValue.delete(), closeReason: 'attendance_auto_inactive' });
  }
  if (lock.data()?.attendanceId === doc.id && employees.docs.length === 1) {
    tx.update(employees.docs[0].ref, { status: 'inactive', updatedAt: FieldValue.serverTimestamp() });
  }
  if (!event.exists) tx.set(eventRef, { companyId, empid, attendanceId: doc.id, name: record.name || empid,
    date, checkInTsUtc: attendanceInstant(record, 'checkIn')!.toISOString(), expiryAt: deadline.toISOString(),
    deliveryState: 'pending', nextAttemptAt: Timestamp.fromDate(now), attempts: 0 });
  return true;
}

export async function expireAttendanceSession(companyId: string, empid: string, id: string, now?: Date) {
  return db.runTransaction(async tx => {
    const doc = await tx.get(db.collection('attendance').doc(id));
    if (doc.data()?.companyId !== companyId || doc.data()?.empid !== empid) return false;
    return expireInTransaction(tx, doc, now || new Date());
  });
}

export async function reconcileEmployeeAttendance(companyId: string, empid: string) {
  if (!expiryRollout().enabled || !expiryRollout().companies.includes(companyId)) return;
  const records = await employeeAttendance(companyId, empid).get();
  const open = records.docs.filter(d => isOpenAttendance(d.data()));
  if (open.length > 1) {
    console.warn('[ATTENDANCE EXPIRY] multiple open sessions require review', { companyId, empid });
    return;
  }
  if (!open[0]) return;
  const record = open[0].data();
  const start = attendanceInstant(record, 'checkIn');
  if (!attendanceDeadline(record) && (!start || Date.now() - start.getTime() >= 86400000)) {
    console.warn('[ATTENDANCE EXPIRY] legacy or invalid session requires manual review', { companyId, empid, attendanceId: open[0].id });
    return;
  }
  if (attendanceIsDue(record)) await expireAttendanceSession(companyId, empid, open[0].id);
}

export async function completeAttendanceSession(companyId: string, empid: string, id: string, values: any) {
  const ref = db.collection('attendance').doc(id);
  return db.runTransaction(async tx => {
    const latest = await tx.get(ref);
    const record = latest.data();
    if (!record || record.companyId !== companyId || record.empid !== empid || !isOpenAttendance(record)) return false;
    if (attendanceIsDue(record)) {
      await expireInTransaction(tx, latest, new Date());
      return false;
    }
    tx.update(ref, { ...values, sessionState: 'checked_out' });
    return true;
  });
}

export async function commitAttendanceCheckIn(companyId: string, empid: string, date: string, values: any) {
  await reconcileEmployeeAttendance(companyId, empid);
  const lock = db.collection('attendanceSessionLocks').doc(encodeURIComponent(JSON.stringify([companyId, empid])));
  return db.runTransaction(async tx => {
    await tx.get(lock);
    const records = await tx.get(employeeAttendance(companyId, empid));
    if (records.docs.some(d => isOpenAttendance(d.data()) ||
        (d.data().date === date && (d.data().checkIn || d.data().checkInTsUtc || d.data().checkOut || d.data().checkOutTsUtc)))) return false;
    const existing = records.docs.find(d => d.data().date === date);
    const ref = existing?.ref || db.collection('attendance').doc();
    const start = attendanceInstant(values, 'checkIn');
    const config = expiryRollout();
    const eligible = config.enabled && config.companies.includes(companyId) && start && start.getTime() >= config.effectiveAt;
    tx.set(ref, { ...values, companyId, empid, date, sessionState: 'active',
      ...(eligible ? { expiryPolicyVersion: 1, expiresAt: Timestamp.fromMillis(start.getTime() + 86400000) } : {}) }, { merge: true });
    tx.set(lock, { companyId, empid, attendanceId: ref.id });
    return true;
  });
}
