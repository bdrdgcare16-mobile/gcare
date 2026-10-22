import { afterEach, beforeEach, describe, expect, it, jest } from '@jest/globals';
import { Timestamp } from 'firebase-admin/firestore';

const mockStore: Record<string, any> = {};
let mockId = 0;
let mockQueue = Promise.resolve();
const mockSend = jest.fn<(...args: any[]) => Promise<any>>();

jest.mock('../config/firebase', () => {
  const ref = (collection: string, id: string): any => ({ collection, id,
    get: async () => snapshot(ref(collection, id)),
    update: async (values: any) => { Object.assign(mockStore[`${collection}/${id}`], values); },
    set: async (values: any) => { mockStore[`${collection}/${id}`] = values; },
  });
  const snapshot = (r: any) => ({ ...r, exists: !!mockStore[`${r.collection}/${r.id}`], ref: r,
    data: () => mockStore[`${r.collection}/${r.id}`] });
  const query = (collection: string, filters: any[] = []): any => ({
    collection, filters,
    doc: (id = `auto-${++mockId}`) => ref(collection, id),
    where: (field: string, op: string, value: any) => query(collection, [...filters, [field, value, op]]),
    limit: () => query(collection, filters),
    orderBy: () => query(collection, filters),
    startAfter: () => query(collection, filters),
    get: async () => {
      const docs = Object.keys(mockStore)
        .filter(k => k.startsWith(`${collection}/`) && filters.every(([f, v, op]) => {
          const actual = mockStore[k][f];
          return op === '<=' ? actual != null && (actual.toMillis?.() ?? actual) <= (v.toMillis?.() ?? v) : actual === v;
        }))
        .map(k => snapshot(ref(collection, k.slice(collection.length + 1))));
      return { docs, empty: docs.length === 0, size: docs.length };
    },
  });
  return { messaging: { sendEachForMulticast: (...args: any[]) => mockSend(...args) }, db: {
    collection: (name: string) => query(name),
    runTransaction: (callback: any) => {
      const run = mockQueue.then(async () => {
        const writes: (() => void)[] = [];
        const tx = {
          get: async (r: any) => r.filters ? r.get() : snapshot(r),
          set: (r: any, data: any) => writes.push(() => {
            mockStore[`${r.collection}/${r.id}`] = { ...mockStore[`${r.collection}/${r.id}`], ...data };
          }),
          update: (r: any, data: any) => tx.set(r, data),
        };
        const result = await callback(tx);
        writes.forEach(write => write());
        return result;
      });
      mockQueue = run.then(() => undefined);
      return run;
    },
  } };
});

jest.mock('../controllers/trackingController', () => ({
  closeTrackingSession: jest.fn<() => Promise<any>>().mockResolvedValue({ closed: true }),
  appendTrackingEventInternal: jest.fn(),
  MAX_TRUSTED_ACCURACY_METERS: 50,
}));
jest.mock('./attendanceGeoPolicy', () => ({
  resolveAttendanceGeoPolicy: async () => ({ resolved: true, geofencingEnabled: false, legacyCompatibilityMode: false }),
}));
jest.mock('./usageService', () => ({ trackUsage: async () => undefined }));

import { checkIn, checkOut, getAllAttendance, getLiveAttendance } from '../controllers/attendanceController';
import { closeTrackingSession } from '../controllers/trackingController';
import { attendanceInstant, attendanceSessionFields, commitAttendanceCheckIn, completeAttendanceSession,
  employeeAttendance, isOpenAttendance, selectAttendance, attendanceDeadline, attendanceIsDue, expireAttendanceSession,
  reconcileEmployeeAttendance } from './attendanceSession';
import { processAttendanceExpiryEvent, expiryNotificationId } from './attendanceExpiryNotifications';
import { runAttendanceExpirySweep } from '../schedulers/attendanceExpiry';

const start = { date: '2026-10-21', checkIn: '22:00:00', checkInTsUtc: '2026-10-21T16:30:00.000Z' };
const end = { checkOut: '06:00:00', checkOutTsUtc: '2026-10-22T00:30:00.000Z', checkOutDate: '2026-10-22' };
const records = () => Object.keys(mockStore).filter(k => k.startsWith('attendance/')).map(k => mockStore[k]);
const seed = (id: string, data: any) => { mockStore[`attendance/${id}`] = { companyId: 'C1', empid: 'E1', ...data }; };

beforeEach(() => { Object.keys(mockStore).forEach(k => delete mockStore[k]); mockId = 0; mockQueue = Promise.resolve(); });

describe('overnight attendance sessions', () => {
  const response = () => {
    const res: any = { statusCode: 200, body: null };
    res.status = (code: number) => { res.statusCode = code; return res; };
    res.json = (body: any) => { res.body = body; return res; };
    return res;
  };
  const request = (): any => ({ user: { companyId: 'C1', empid: 'E1', role: 'employee' }, body: {}, query: {} });

  it('checkout API closes yesterday attendance and its original tracking session; history retains its date', async () => {
    jest.useFakeTimers().setSystemTime(new Date(end.checkOutTsUtc));
    try {
      seed('old', start);
      seed('foreign', { ...start, companyId: 'C2' });
      const res = response();
      await checkOut(request(), res);
      expect(res.statusCode).toBe(200);
      expect(res.body).toMatchObject({ date: start.date, workedSeconds: 28800, checkOutTsUtc: end.checkOutTsUtc });
      expect(mockStore['attendance/old'].date).toBe(start.date);
      expect(mockStore['attendance/foreign'].checkOut).toBeUndefined();
      expect(closeTrackingSession).toHaveBeenCalledWith({ companyId: 'C1', empid: 'E1', dateIso: start.date });
      const history = response();
      await getAllAttendance(request(), history);
      expect(history.body).toHaveLength(1);
      expect(history.body[0]).toMatchObject({ date: start.date, checkIn: '22:00:00', checkOut: '06:00:00' });
    } finally { jest.useRealTimers(); }
  });

  it('live API restores yesterday active session after midnight and exposes today eligibility', async () => {
    jest.useFakeTimers().setSystemTime(new Date(end.checkOutTsUtc));
    try {
      seed('old', start);
      mockStore['employees/emp'] = { companyId: 'C1', empid: 'E1', name: 'Employee', status: 'active' };
      const active = response();
      await getLiveAttendance(request(), active);
      expect(active.statusCode).toBe(200);
      expect(active.body[0]).toMatchObject({ date: start.date, checkInTsUtc: start.checkInTsUtc, checkOut: null, hasAttendanceToday: false });
      Object.assign(mockStore['attendance/old'], end);
      const completed = response();
      await getLiveAttendance(request(), completed);
      expect(completed.body[0]).toMatchObject({ date: start.date, workedSeconds: 28800, hasAttendanceToday: false });
    } finally { jest.useRealTimers(); }
  });
  it('API allows the next date check-in only after overnight checkout and rejects duplicates', async () => {
    jest.useFakeTimers().setSystemTime(new Date(start.checkInTsUtc));
    try {
      const req = request();
      req.body = { name: 'Employee', latitude: 12.97, longitude: 77.59, accuracy: 10 };
      const first = response();
      await checkIn(req, first);
      expect(first.statusCode).toBe(200);
      expect(first.body.date).toBe(start.date);
      jest.setSystemTime(new Date(end.checkOutTsUtc));
      const duplicate = response();
      await checkIn(req, duplicate);
      expect(duplicate.statusCode).toBe(409);
      const checkout = response();
      await checkOut(req, checkout);
      expect(checkout.body.workedSeconds).toBe(28800);
      jest.setSystemTime(new Date('2026-10-22T15:30:00Z'));
      const next = response();
      await checkIn(req, next);
      expect(next.statusCode).toBe(200);
      expect(next.body.date).toBe('2026-10-22');
      expect(records()).toHaveLength(2);
      const repeated = response();
      await checkIn(req, repeated);
      expect(repeated.statusCode).toBe(409);
    } finally { jest.useRealTimers(); }
  });

  it('API completes same-day attendance without changing its date', async () => {
    jest.useFakeTimers().setSystemTime(new Date('2026-10-21T03:30:00Z'));
    try {
      const req = request();
      req.body = { name: 'Employee', latitude: 12.97, longitude: 77.59, accuracy: 10 };
      await checkIn(req, response());
      jest.setSystemTime(new Date('2026-10-21T12:30:00Z'));
      const checkout = response();
      await checkOut(req, checkout);
      expect(checkout.statusCode).toBe(200);
      expect(checkout.body).toMatchObject({ date: start.date, workedSeconds: 32400, checkOutDate: start.date });
    } finally { jest.useRealTimers(); }
  });

  it('calculates same-day duration', () => {
    expect(attendanceSessionFields({ date: '2026-10-21', checkIn: '09:00:00', checkOut: '18:00:00' }).workedSeconds).toBe(32400);
  });

  it('keeps the original date and computes eight hours across midnight', () => {
    expect(attendanceSessionFields({ ...start, ...end })).toMatchObject({ date: '2026-10-21', workedSeconds: 28800,
      checkInTsUtc: start.checkInTsUtc, checkOutTsUtc: end.checkOutTsUtc });
  });

  it('restores an overnight active session after restart or midnight navigation', async () => {
    seed('old', start);
    const snap = await employeeAttendance('C1', 'E1').get();
    expect(selectAttendance(snap.docs, '2026-10-22')?.id).toBe('old');
    expect(selectAttendance((await employeeAttendance('C1', 'E1').get()).docs, '2026-10-22')?.data().date).toBe('2026-10-21');
  });

  it('checkout updates only the original document and preserves the check-in', async () => {
    seed('old', start);
    expect(await completeAttendanceSession('C1', 'E1', 'old', { ...end, workedSeconds: 28800 })).toBe(true);
    expect(records()).toEqual([{ companyId: 'C1', empid: 'E1', ...start, ...end, workedSeconds: 28800, sessionState: 'checked_out' }]);
    expect(records().filter(r => r.date === '2026-10-21')).toHaveLength(1);
    expect(records().filter(r => r.date === '2026-10-22')).toHaveLength(0);
  });

  it('allows a new current-date check-in after overnight checkout', async () => {
    seed('old', { ...start, ...end });
    expect(await commitAttendanceCheckIn('C1', 'E1', '2026-10-22', { checkIn: '21:00:00' })).toBe(true);
    expect(records()).toHaveLength(2);
    expect(selectAttendance((await employeeAttendance('C1', 'E1').get()).docs, '2026-10-22')?.data().date).toBe('2026-10-22');
  });

  it('blocks another check-in while yesterday remains active, including missing checkout fields', async () => {
    seed('old', start);
    expect(await commitAttendanceCheckIn('C1', 'E1', '2026-10-22', { checkIn: '21:00:00' })).toBe(false);
    expect(records()).toHaveLength(1);
  });

  it('blocks a second session on a date already completed', async () => {
    seed('old', { ...start, checkOut: '23:00:00' });
    expect(await commitAttendanceCheckIn('C1', 'E1', start.date, { checkIn: '23:30:00' })).toBe(false);
  });

  it('serializes simultaneous check-ins so only one succeeds', async () => {
    expect(await Promise.all([1, 2].map(() => commitAttendanceCheckIn('C1', 'E1', start.date, start))))
      .toEqual([true, false]);
    expect(records()).toHaveLength(1);
  });

  it('does not expose or modify another company or employee session', async () => {
    seed('other', { ...start, companyId: 'C2' });
    expect((await employeeAttendance('C1', 'E1').get()).docs).toHaveLength(0);
    expect(await completeAttendanceSession('C1', 'E1', 'other', end)).toBe(false);
    expect(await completeAttendanceSession('C2', 'E2', 'other', end)).toBe(false);
    expect(await commitAttendanceCheckIn('C1', 'E1', start.date, start)).toBe(true);
    expect(records()[0].checkOut).toBeUndefined();
  });

  it('never rewrites an already completed session on repeated checkout', async () => {
    seed('old', { ...start, ...end });
    expect(await completeAttendanceSession('C1', 'E1', 'old', { checkOut: '07:00:00' })).toBe(false);
    expect(records()[0].checkOut).toBe('06:00:00');
  });

  it('supports legacy HH:mm timestamps and infers overnight duration without migration', () => {
    expect(attendanceSessionFields({ date: start.date, checkIn: '22:00', checkOut: '06:00' }).workedSeconds).toBe(28800);
    expect(isOpenAttendance({ ...start, checkOut: null })).toBe(true);
    expect(attendanceInstant({ date: start.date, checkIn: 'bad' }, 'checkIn')).toBeNull();
    expect(attendanceInstant({ date: start.date, checkIn: '25:00:00' }, 'checkIn')).toBeNull();
  });

  it('rejects impossible legacy calendar dates instead of normalizing into another month', () => {
    expect(attendanceInstant({ date: '2026-02-31', checkIn: '09:00' }, 'checkIn')).toBeNull();
  });

  it('blocks a new check-in for a timestamp-only completed record on the same date', async () => {
    seed('old', { date: start.date, checkOutTsUtc: end.checkOutTsUtc });
    expect(await commitAttendanceCheckIn('C1', 'E1', start.date, start)).toBe(false);
    expect(records()[0].checkIn).toBeUndefined();
  });

  it('normalizes Firestore timestamps and preserves the original report date', () => {
    const fields = attendanceSessionFields({ date: start.date,
      checkInTsUtc: { toDate: () => new Date(start.checkInTsUtc) },
      checkOutTsUtc: { toDate: () => new Date(end.checkOutTsUtc) } });
    expect(fields).toMatchObject({ date: start.date, workedSeconds: 28800,
      checkInTsUtc: start.checkInTsUtc, checkOutTsUtc: end.checkOutTsUtc });
  });

  it('does not silently abandon stale open sessions or select between multiple open records', async () => {
    seed('old', start);
    expect(await commitAttendanceCheckIn('C1', 'E1', '2026-11-22', start)).toBe(false);
    seed('duplicate', { ...start, date: '2026-10-22' });
    expect(() => selectAttendance(Object.keys(mockStore).map(k => ({ data: () => mockStore[k] })), '2026-10-22')).toThrow('Multiple active');
  });

  it('restores a completed overnight session on its checkout date, but not subsequent days', async () => {
    seed('old', { ...start, ...end });
    const snap = await employeeAttendance('C1', 'E1').get();
    expect(selectAttendance(snap.docs, '2026-10-22')?.data().date).toBe('2026-10-21');
    expect(selectAttendance(snap.docs, '2026-10-23')).toBeUndefined();
  });
});

describe('24-hour attendance expiry', () => {
  const deadline = new Date('2026-10-22T16:30:00Z');
  const originalEnv = { ...process.env };
  const eligible = () => ({ ...start, name: 'Employee', sessionState: 'active', expiryPolicyVersion: 1,
    expiresAt: Timestamp.fromDate(deadline) });
  const notifications = () => Object.keys(mockStore).filter(k => k.startsWith('notifications/'));
  beforeEach(() => {
    process.env.ATTENDANCE_EXPIRY_ENABLED = 'true';
    process.env.ATTENDANCE_EXPIRY_EFFECTIVE_AT = '2026-10-20T00:00:00Z';
    process.env.ATTENDANCE_EXPIRY_COMPANIES = 'C1';
    mockSend.mockReset().mockResolvedValue({ responses: [{ success: true }] });
    jest.useFakeTimers().setSystemTime(deadline);
  });
  afterEach(() => { process.env = { ...originalEnv }; jest.useRealTimers(); });

  it('enrolls only new post-activation company sessions', async () => {
    expect(await commitAttendanceCheckIn('C1', 'E1', start.date, start)).toBe(true);
    expect(attendanceDeadline(records()[0])?.toISOString()).toBe(deadline.toISOString());
    expect(await commitAttendanceCheckIn('C2', 'E1', start.date, start)).toBe(true);
    expect(records()[1].expiryPolicyVersion).toBeUndefined();
    expect(attendanceDeadline({ ...eligible(), companyId: 'C1', checkInTsUtc: '2026-10-19T16:30:00Z' })).toBeNull();
  });

  it('remains active at 23h59m and expires exactly at 24h without checkout or paid duration', async () => {
    seed('old', eligible());
    expect(attendanceIsDue(mockStore['attendance/old'], new Date(deadline.getTime() - 60000))).toBe(false);
    expect(await expireAttendanceSession('C1', 'E1', 'old', new Date(deadline.getTime() - 1))).toBe(false);
    expect(await expireAttendanceSession('C1', 'E1', 'old', deadline)).toBe(true);
    expect(mockStore['attendance/old']).toMatchObject({ date: start.date, checkInTsUtc: start.checkInTsUtc, sessionState: 'auto_inactive' });
    expect(mockStore['attendance/old'].checkOutTsUtc).toBeUndefined();
    expect(attendanceSessionFields(mockStore['attendance/old'])).toMatchObject({ checkOut: null, workedSeconds: null });
    expect(await expireAttendanceSession('C1', 'E1', 'old')).toBe(false);
    expect(Object.keys(mockStore).filter(k => k.startsWith('attendanceExpiryEvents/'))).toHaveLength(1);
  });

  it('allows pre-expiry overnight checkout and never later expires it', async () => {
    seed('old', eligible());
    jest.setSystemTime(new Date(end.checkOutTsUtc));
    expect(await completeAttendanceSession('C1', 'E1', 'old', end)).toBe(true);
    jest.setSystemTime(deadline);
    expect(await expireAttendanceSession('C1', 'E1', 'old')).toBe(false);
    expect(mockStore['attendance/old'].sessionState).toBe('checked_out');
  });

  it('expiry wins a checkout race at the deadline, with a single durable event', async () => {
    seed('old', eligible());
    expect(await Promise.all([completeAttendanceSession('C1', 'E1', 'old', end),
      expireAttendanceSession('C1', 'E1', 'old')])).toEqual([false, false]);
    expect(mockStore['attendance/old'].sessionState).toBe('auto_inactive');
    expect(mockStore['attendance/old'].checkOut).toBeUndefined();
  });

  it('closes matching GPS history but never a different attendance identity', async () => {
    seed('old', eligible());
    const key = `tracking/C1_E1_${start.date}`;
    mockStore[key] = { companyId: 'C1', empid: 'E1', dateIso: start.date, attendanceId: 'old', pathMap: [{ lat: 1 }] };
    await expireAttendanceSession('C1', 'E1', 'old');
    expect(mockStore[key]).toMatchObject({ endedAt: deadline.toISOString(), pathMap: [{ lat: 1 }] });
    seed('old', eligible());
    mockStore[key] = { companyId: 'C1', empid: 'E1', dateIso: start.date, attendanceId: 'new' };
    await expireAttendanceSession('C1', 'E1', 'old');
    expect(mockStore[key].endedAt).toBeUndefined();
  });

  it('unblocks future check-in through request-time reconciliation', async () => {
    seed('old', eligible());
    expect(await commitAttendanceCheckIn('C1', 'E1', '2026-10-22',
      { date: '2026-10-22', checkIn: '22:00:00', checkInTsUtc: deadline.toISOString() })).toBe(true);
    expect(records()).toHaveLength(2);
    expect(records()[0].sessionState).toBe('auto_inactive');
    expect(records()[1].sessionState).toBe('active');
  });

  it('does not mutate historical, disabled, malformed, duplicate, or other-company sessions', async () => {
    seed('legacy', start);
    await reconcileEmployeeAttendance('C1', 'E1');
    expect(mockStore['attendance/legacy']).toEqual({ companyId: 'C1', empid: 'E1', ...start });
    seed('legacy', eligible());
    seed('duplicate', eligible());
    expect(await expireAttendanceSession('C1', 'E1', 'legacy')).toBe(false);
    expect(await expireAttendanceSession('C2', 'E1', 'legacy')).toBe(false);
    expect(attendanceDeadline({ ...eligible(), companyId: 'C1', expiresAt: 'bad' })).toBeNull();
    process.env.ATTENDANCE_EXPIRY_ENABLED = 'false';
    expect(await expireAttendanceSession('C1', 'E1', 'legacy')).toBe(false);
  });

  it('duplicate sweeps notify same-company admin only and retain an in-app record without FCM', async () => {
    seed('old', eligible());
    for (const role of ['admin', 'super_admin', 'company_admin', 'platform_admin', 'hr']) {
      mockStore[`users/${role}`] = { companyId: 'C1', role };
    }
    mockStore['users/foreign'] = { companyId: 'C2', role: 'admin' };
    await runAttendanceExpirySweep();
    await runAttendanceExpirySweep();
    expect(notifications()).toEqual([`notifications/${expiryNotificationId('old', 'admin')}`]);
    expect(mockStore[notifications()[0]]).toMatchObject({ pushStatus: 'no_active_device', title: 'Attendance Session Auto-Inactivated' });
    expect(mockSend).not.toHaveBeenCalled();
  });

  it('leases concurrent delivery and retries transient FCM failure without duplicate records', async () => {
    seed('old', eligible());
    mockStore['users/admin'] = { companyId: 'C1', role: 'admin' };
    mockStore['deviceRegistrations/device'] = { companyId: 'C1', userId: 'admin', isActive: true, fcmToken: 'test-token' };
    await expireAttendanceSession('C1', 'E1', 'old');
    const { db } = await import('../config/firebase');
    const ref = db.collection('attendanceExpiryEvents').doc('old');
    mockSend.mockRejectedValueOnce(new Error('transient'));
    await Promise.all([processAttendanceExpiryEvent(ref), processAttendanceExpiryEvent(ref)]);
    expect(notifications()).toHaveLength(1);
    jest.setSystemTime(new Date(deadline.getTime() + 120000));
    await processAttendanceExpiryEvent(ref);
    expect(notifications()).toHaveLength(1);
    expect(mockStore[notifications()[0]].pushStatus).toBe('sent');
    expect(mockSend).toHaveBeenCalledTimes(2);
  });
});
