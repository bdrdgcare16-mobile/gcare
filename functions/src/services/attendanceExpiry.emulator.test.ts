import { Timestamp } from 'firebase-admin/firestore';
import { randomUUID } from 'crypto';

const run = process.env.ATTENDANCE_EXPIRY_EMULATOR_TESTS === 'true';
const suite = run ? describe : describe.skip;

suite('attendance expiry Firestore emulator concurrency', () => {
  let db: FirebaseFirestore.Firestore;
  let service: typeof import('./attendanceSession');
  let notifications: typeof import('./attendanceExpiryNotifications');
  const companyId = `expiry-test-${randomUUID()}`;
  const originalEnv = { ...process.env };
  beforeAll(async () => {
    if (!/^127\.0\.0\.1:\d+$/.test(process.env.FIRESTORE_EMULATOR_HOST || '') ||
        process.env.GCLOUD_PROJECT !== 'demo-serv-attendance') throw new Error('Local demo emulator required');
    process.env.ATTENDANCE_EXPIRY_ENABLED = 'true';
    process.env.ATTENDANCE_EXPIRY_EFFECTIVE_AT = new Date(Date.now() - 3 * 86400000).toISOString();
    process.env.ATTENDANCE_EXPIRY_COMPANIES = companyId;
    db = (await import('../config/firebase')).db;
    service = await import('./attendanceSession');
    notifications = await import('./attendanceExpiryNotifications');
  });
  afterAll(async () => {
    if (db) await db.terminate();
    process.env = { ...originalEnv };
  });

  async function seed(ageMs: number) {
    const id = randomUUID();
    const empid = `employee-${id}`;
    const start = new Date(Date.now() - ageMs);
    const date = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata' }).format(start);
    const ref = db.collection('attendance').doc(id);
    const tracking = db.collection('tracking').doc(`${companyId}_${empid}_${date}`);
    await ref.set({ companyId, empid, name: 'Emulator Employee', date, checkIn: '09:00:00', checkInTsUtc: start.toISOString(),
      sessionState: 'active', expiryPolicyVersion: 1, expiresAt: Timestamp.fromMillis(start.getTime() + 86400000) });
    await tracking.set({ companyId, empid, dateIso: date, attendanceId: id, endedAt: null, pathMap: [{ lat: 1, lng: 2 }] });
    return { id, empid, date, ref, tracking };
  }

  it('permits 23h59m checkout and makes duplicate expiry attempts no-ops', async () => {
    const session = await seed(86340000);
    expect(await service.completeAttendanceSession(companyId, session.empid, session.id,
      { checkOut: '08:59:00', checkOutTsUtc: new Date().toISOString() })).toBe(true);
    expect(await service.expireAttendanceSession(companyId, session.empid, session.id,
      new Date(Date.now() + 60000))).toBe(false);
    expect((await session.ref.get()).data()?.sessionState).toBe('checked_out');
  }, 30000);

  it('serializes checkout and simultaneous expiry at 24h, preserving tracking history', async () => {
    const session = await seed(86401000);
    const outcomes = await Promise.all([
      service.completeAttendanceSession(companyId, session.empid, session.id, { checkOutTsUtc: new Date().toISOString() }),
      ...Array.from({ length: 5 }, () => service.expireAttendanceSession(companyId, session.empid, session.id)),
    ]);
    expect(outcomes[0]).toBe(false);
    const record = (await session.ref.get()).data()!;
    expect(record.sessionState).toBe('auto_inactive');
    expect(record.date).toBe(session.date);
    expect(record.checkOutTsUtc).toBeUndefined();
    const tracking = (await session.tracking.get()).data()!;
    expect(tracking.endedAt).toBeTruthy();
    expect(tracking.pathMap).toEqual([{ lat: 1, lng: 2 }]);
    expect((await db.collection('attendanceExpiryEvents').doc(session.id).get()).exists).toBe(true);
    const today = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata' }).format(new Date());
    expect(await service.commitAttendanceCheckIn(companyId, session.empid, today,
      { date: today, checkIn: '09:00:00', checkInTsUtc: new Date().toISOString() })).toBe(true);
  }, 60000);

  it('persists pagination past ineligible rows without modifying those records', async () => {
    const invalidRefs = [db.collection('attendance').doc(randomUUID()), db.collection('attendance').doc(randomUUID())];
    for (const ref of invalidRefs) await ref.set({ companyId, empid: ref.id, date: '2020-01-01',
      checkIn: '09:00:00', sessionState: 'active', expiresAt: Timestamp.fromMillis(Date.now() - 2 * 86400000) });
    const valid = await seed(86401000);
    const { runAttendanceExpirySweep } = await import('../schedulers/attendanceExpiry');
    const first = await runAttendanceExpirySweep(new Date(), { batchSize: 2, maxPages: 1 });
    expect(first.backlog).toBe(true);
    expect((await valid.ref.get()).data()?.sessionState).toBe('active');
    await runAttendanceExpirySweep(new Date(), { batchSize: 2, maxPages: 1 });
    expect((await valid.ref.get()).data()?.sessionState).toBe('auto_inactive');
    for (const ref of invalidRefs) expect((await ref.get()).data()?.sessionState).toBe('active');
  }, 60000);

  it('overlapping scheduler executions produce one transition and event', async () => {
    const session = await seed(86401000);
    const { runAttendanceExpirySweep } = await import('../schedulers/attendanceExpiry');
    await Promise.all([runAttendanceExpirySweep(), runAttendanceExpirySweep()]);
    expect((await session.ref.get()).data()?.sessionState).toBe('auto_inactive');
    const events = await db.collection('attendanceExpiryEvents').where('companyId', '==', companyId)
      .where('attendanceId', '==', session.id).get();
    expect(events.docs).toHaveLength(1);
  }, 60000);

  it('creates only one admin notification under concurrent outbox delivery', async () => {
    const session = await seed(86401000);
    const adminId = `admin-${randomUUID()}`;
    await db.collection('users').doc(adminId).set({ companyId, role: 'admin' });
    await db.collection('users').doc(`excluded-${randomUUID()}`).set({ companyId, role: 'super_admin' });
    await service.expireAttendanceSession(companyId, session.empid, session.id);
    const event = db.collection('attendanceExpiryEvents').doc(session.id);
    await Promise.all(Array.from({ length: 5 }, () => notifications.processAttendanceExpiryEvent(event)));
    const rows = await db.collection('notifications').where('companyId', '==', companyId).where('entityId', '==', session.id).get();
    expect(rows.docs).toHaveLength(1);
    expect(rows.docs[0].data()).toMatchObject({ recipientUserId: adminId, pushStatus: 'no_active_device' });
  }, 60000);
});
