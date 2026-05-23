import { Request, Response } from 'express';
import { db } from '../config/firebase';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { trackUsage } from '../services/usageService';

// Helper functions for request processing
const getReqCompanyId = (req: Request) => req.user?.companyId;
const getReqEmpId = (req: Request) => req.user?.empid || 'admin';

/* ============================== Helpers ============================== */

const EMP_COL       = 'employees';
const ATT_COL       = 'attendance';
const LEAVE_COL     = 'leaves';
const SHIFT_COL     = 'shifts';
const OFFICE_COL    = 'officeLocations';
const OTHER_LOC_COL = 'otherLocation'; // separate collection for other-location events

function pad2(n: number | string) { return String(n).padStart(2, '0'); }

// --- Time helpers (IST + UTC) ---
// Use Intl with Asia/Kolkata instead of adding 5.5h manually.
const IST_TZ = 'Asia/Kolkata';

function toYMD(d: Date = new Date()): string {
  const fmt = new Intl.DateTimeFormat('en-CA', {
    timeZone: IST_TZ,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  });
  return fmt.format(d); // YYYY-MM-DD
}

function nowTimeIST(): string {
  const parts = new Intl.DateTimeFormat('en-GB', {
    timeZone: IST_TZ,
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  })
    .formatToParts(new Date())
    .reduce<Record<string, string>>((acc, p) => {
      if (p.type !== 'literal') acc[p.type] = p.value;
      return acc;
    }, {});
  return `${parts.hour}:${parts.minute}:${parts.second}`; // HH:mm:ss
}

function nowUtcISO(): string {
  return new Date().toISOString(); // exact instant (UTC) for audits
}


/* ====== CHANGED: timezone-safe weekday detection for YYYY-MM-DD ======
   Avoid new Date('YYYY-MM-DD') which is parsed as UTC in Node.
   dayOfWeekFromYMD returns: 0=Sunday, 1=Monday, ..., 6=Saturday
*/
function dayOfWeekFromYMD(ymd: string): number {
  const y = parseInt(ymd.slice(0, 4), 10);
  const m = parseInt(ymd.slice(5, 7), 10);
  const d = parseInt(ymd.slice(8, 10), 10);
  let Y = y, M = m;
  if (M < 3) { M += 12; Y -= 1; }
  const K = Y % 100;
  const J = Math.floor(Y / 100);
  // Zeller’s congruence (Gregorian):
  // h = 0..6 => 0=Saturday,1=Sunday,2=Monday,...,6=Friday
  const h = (d + Math.floor((13 * (M + 1)) / 5) + K + Math.floor(K / 4) + Math.floor(J / 4) + 5 * J) % 7;
  // Convert to 0=Sunday..6=Saturday
  return (h + 6) % 7;
}
function isSunday(ymd: string) { return dayOfWeekFromYMD(ymd) === 0; } // <— callers unchanged

function isOpenShift(shiftName: string): boolean {
  const name = (shiftName || '').trim().toLowerCase();
  return name.includes('open');
}

function cmpHHMM(a?: string, b?: string) { return (a || '00:00') > (b || '00:00'); }

function midpointHHMM(start?: string, end?: string) {
  if (isOpenShift(start || '') || isOpenShift(end || '')) {
    return '00:00';
  }
  const [h1, m1] = (start || '00:00').split(':').map(Number);
  const [h2, m2] = (end   || '23:59').split(':').map(Number);
  const s1 = h1 * 3600 + m1 * 60, s2 = h2 * 3600 + m2 * 60;
  const mid = Math.floor((s1 + s2) / 2);
  const mh = Math.floor(mid / 3600), mm = Math.floor((mid % 3600) / 60);
  return `${pad2(mh)}:${pad2(mm)}`;
}

function toISO(v: any): string {
  try {
    if (!v) return '';
    if (typeof v === 'string') return v.slice(0, 10);
    if (v.toDate && typeof v.toDate === 'function') return v.toDate().toISOString().slice(0, 10);
    const d = new Date(v);
    return d.toISOString().slice(0, 10);
  } catch { return ''; }
}
function eachYMD(start: string, end: string) {
  const out: string[] = [];
  const d = new Date(start);
  for (;;) {
    const ymd = d.toISOString().slice(0, 10);
    out.push(ymd);
    if (ymd === end) break;
    d.setDate(d.getDate() + 1);
  }
  return out;
}

// project-level holiday set (optional)
const HOLIDAYS_SET = new Set<string>([]);

/* ==== tolerant helpers for emp id ==== */

const normStr = (s: any) => String(s ?? '').trim();
const lower = (s: string) => s.trim().toLowerCase();

/* ============ GEO helpers ============ */

// Haversine distance in meters
function haversineMeters(lat1?: number|null, lon1?: number|null, lat2?: number|null, lon2?: number|null) {
  if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) return null;
  const R = 6371000; // meters
  const toRad = (x: number) => (x * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return Math.round(R * c);
}

// find office by branch name (case-insensitive fallback)
async function findOfficeByBranchName(branchNameRaw: string, companyId?: string) {
  const branchName = normStr(branchNameRaw);
  if (!branchName) return null;

  // Try exact match on branchName with companyId filtering
  let exact = db.collection(OFFICE_COL).where('branchName', '==', branchName);
  if (companyId) exact = exact.where('companyId', '==', companyId);
  const exactSnap = await exact.limit(1).get();
  if (!exactSnap.empty) {
    const d = exactSnap.docs[0];
    return { id: d.id, ...d.data() } as any;
  }

  // Fallback: load a small page & do case-insensitive compare with companyId filtering
  let fallback = db.collection(OFFICE_COL).limit(50);
  if (companyId) fallback = fallback.where('companyId', '==', companyId);
  const snap = await fallback.get();
  for (const d of snap.docs) {
    const data = d.data() as any;
    const bn = normStr(data.branchName || data.name || '');
    if (lower(bn) === lower(branchName)) {
      return { id: d.id, ...data };
    }
  }
  return null;
}

/* ============================== NEW: Other Location capture ============================== */

type OtherLocEventType = 'check-in' | 'check-out';

async function createOtherLocationEvent(params: {
  empid: string;
  name: string;
  date: string;
  time: string;
  type: OtherLocEventType;
  branchName: string | null;
  companyId: string;

  // device coords at event time
  latitude: number | null;
  longitude: number | null;
  accuracy?: number | null;

  // expected (branch) snapshot
  expectedLatitude: number | null;
  expectedLongitude: number | null;
  expectedRadius: number | null;

  // computed deltas
  distanceFromBranch: number | null;
  withinRadius: boolean | null;

  // text reason
  otherLocation: string | null;
}) {
  const payload = {
    source: 'attendance' as const,
    approvalStatus: 'Pending',
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),

    empid: params.empid,
    name: params.name,
    date: params.date,
    time: params.time,
    type: params.type,
    branchName: params.branchName,
    companyId: params.companyId,

    // device
    latitude: params.latitude,
    longitude: params.longitude,
    accuracy: params.accuracy ?? null,

    // expected snapshot
    expectedLatitude: params.expectedLatitude,
    expectedLongitude: params.expectedLongitude,
    expectedRadius: params.expectedRadius,

    // deltas
    distanceFromBranch: params.distanceFromBranch,
    withinRadius: params.withinRadius,

    otherLocation: params.otherLocation,
  };
  await db.collection(OTHER_LOC_COL).add(payload as any);
}

/* ============================== Usage Tracking Helper ============================== */

async function trackAttendanceUsage(
  req: Request,
  updates: Record<string, number>
) {
  try {
    const user = (req as any).user;
    await trackUsage({
      companyId: user?.companyId || '',
      companyName: user?.companyName || '',
      plan: user?.plan || '',
      updates,
    });
  } catch (trackingError) {
    console.error('Usage tracking failed in attendance:', trackingError);
  }
}

/* ============================== Core attendance (string-time model) ============================== */

/** Get current user (from req.user) */
export const getCurrentUser = async (req: Request, res: Response) => {
  try {
    const companyId = getReqCompanyId(req);
    if (!companyId) {
      return res.status(403).json({ error: 'companyId missing in token' });
    }

    const empid = getReqEmpId(req);
    const snap = await db.collection(EMP_COL)
      .where('empid', '==', empid)
      .where('companyId', '==', companyId)
      .limit(1)
      .get();
    if (snap.empty) return res.status(404).json({ error: 'Employee not found' });
    const d = snap.docs[0].data();
    return res.json({
      empid: d.empid,
      name:  d.name,
      role:  (req as any).user?.role,
      shiftGroup: d.shiftGroup,
    });
  } catch (err: any) {
    console.error('getCurrentUser error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** POST /api/attendance/check-in */
export const checkIn = async (req: Request, res: Response) => {
  const companyId = getReqCompanyId(req);
  if (!companyId) {
    return res.status(403).json({ error: 'companyId missing in token' });
  }

  const empid    = getReqEmpId(req) || '';
  const name     = normStr((req.body as any)?.name);
  const location = normStr((req.body as any)?.location); // should be branch name

  // coordinates from app
  const checkInLatitude  = typeof (req.body as any)?.latitude  === 'number' ? (req.body as any).latitude  : null;
  const checkInLongitude = typeof (req.body as any)?.longitude === 'number' ? (req.body as any).longitude : null;
  const checkInAccuracy  = typeof (req.body as any)?.accuracy  === 'number' ? (req.body as any).accuracy  : null;
  const checkInSource    = normStr((req.body as any)?.source) || null; // manual/biometric

  // ===== NEW: Reason coming from client (dropdown) =====
  const reasonId        = normStr((req.body as any)?.reasonId) || null;
  const reasonText      = normStr((req.body as any)?.reasonText || (req.body as any)?.reason) || null;
  const reasonTypeId    = normStr((req.body as any)?.reasonTypeId) || null;
  const reasonTypeName  = normStr((req.body as any)?.reasonTypeName) || null;

  if (!empid || !name || !location) {
    return res.status(400).json({ error: 'empid, name and location are required' });
  }
  const today = toYMD(new Date());

  try {
    // 1) find/create today's doc
    const snap = await db.collection(ATT_COL)
      .where('empid', '==', empid)
      .where('date', '==', today)
      .where('companyId', '==', companyId)
      .limit(1)
      .get();

    const nowTime = nowTimeIST(); // HH:mm:ss (IST)

    // 2) figure out branch to compare against (prefer request, fallback employee.profile)
    let branchName = location;
    const empSnap = await db.collection(EMP_COL)
      .where('empid', '==', empid)
      .where('companyId', '==', companyId)
      .limit(1)
      .get();
    const empRow = empSnap.empty ? null : empSnap.docs[0].data();
    if (!branchName && (empRow as any)?.location) branchName = normStr((empRow as any).location);

    // 3) find office & compute distance
    let expectedLatitude: number | null = null;
    let expectedLongitude: number | null = null;
    let expectedRadius: number | null = null;
    let distanceFromBranch: number | null = null;
    let withinRadius: boolean | null = null;
    let otherLocation: string | null = null;

    const office = await findOfficeByBranchName(branchName, companyId);
    if (office) {
      expectedLatitude  = Number((office as any).latitude ?? 0) || 0;
      expectedLongitude = Number((office as any).longitude ?? 0) || 0;
      expectedRadius    = Number((office as any).radius ?? 0) || 0;

      distanceFromBranch = haversineMeters(
        checkInLatitude, checkInLongitude, expectedLatitude, expectedLongitude
      );

      if (distanceFromBranch != null && expectedRadius != null) {
        withinRadius = distanceFromBranch <= expectedRadius;
        if (!withinRadius) {
          otherLocation = `Outside radius by ${Math.max(0, distanceFromBranch - expectedRadius)} m`;
        }
      }
    } else {
      // branch not configured
      otherLocation = 'No matching branch in officeLocations';
    }

    // 4) write attendance record + capture other-location event when needed
    if (!snap.empty) {
      const doc = snap.docs[0];
      const data = doc.data();

      if (data.checkIn) {
        // still push/update reason if provided (no harm)
        if (reasonText) {
          await doc.ref.set({
            reason: reasonText,
            reasonId: reasonId || null,
            reasonTypeId: reasonTypeId || null,
            reasonTypeName: reasonTypeName || null,
            updatedAt:FieldValue.serverTimestamp(),
          }, { merge: true });
        }

        if (!empSnap.empty) {
          await empSnap.docs[0].ref.set(
            { status: 'active', updatedAt:FieldValue.serverTimestamp() },
            { merge: true }
          );
        }
        if (withinRadius === false || (otherLocation && otherLocation.trim() !== '')) {
          await createOtherLocationEvent({
            empid, name, date: today, time: nowTime, type: 'check-in',
            branchName,
            companyId,
            latitude: checkInLatitude, longitude: checkInLongitude, accuracy: checkInAccuracy,
            expectedLatitude, expectedLongitude, expectedRadius,
            distanceFromBranch, withinRadius, otherLocation
          });
        }
        return res.status(409).json({
          error: 'Already checked in today',
          code: 'ALREADY_CHECKED_IN',
          attendanceId: doc.id,
          record: { id: doc.id, ...data },
        });
      }

      await doc.ref.update({
        checkIn: nowTime,
        checkInTsUtc: nowUtcISO(),              // <<< AUDIT FIELD
        name,
        location: branchName,
        checkInLatitude,
        checkInLongitude,
        checkInAccuracy,
        checkInSource,
        branchName: branchName || null,
        expectedLatitude,
        expectedLongitude,
        expectedRadius,
        distanceFromBranch,
        withinRadius,
        otherLocation,
        // ===== NEW: persist reason to attendance =====
        ...(reasonText ? { reason: reasonText } : {}),
        ...(reasonId ? { reasonId } : {}),
        ...(reasonTypeId ? { reasonTypeId } : {}),
        ...(reasonTypeName ? { reasonTypeName } : {}),
        status: 'Present',
        approvalStatus: 'Pending',
        updatedAt:FieldValue.serverTimestamp(),
      });

      if (withinRadius === false || (otherLocation && otherLocation.trim() !== '')) {
        await createOtherLocationEvent({
          empid, name, date: today, time: nowTime, type: 'check-in',
          branchName,
          companyId,
          latitude: checkInLatitude, longitude: checkInLongitude, accuracy: checkInAccuracy,
          expectedLatitude, expectedLongitude, expectedRadius,
          distanceFromBranch, withinRadius, otherLocation
        });
      }

      if (!empSnap.empty) {
        await empSnap.docs[0].ref.update({
          status: 'active',
          updatedAt:FieldValue.serverTimestamp(),
        });
      }
      return res.json({ message: 'Check-in updated' });
    }

    // new record
    await db.collection(ATT_COL).add({
      empid,
      name,
      date: today,
      checkIn: nowTime,
      checkInTsUtc: nowUtcISO(),                // <<< AUDIT FIELD
      location: branchName,
      checkInLatitude,
      checkInLongitude,
      checkInAccuracy,
      checkInSource,
      branchName: branchName || null,
      expectedLatitude,
      expectedLongitude,
      expectedRadius,
      distanceFromBranch,
      withinRadius,
      otherLocation,
      // ===== NEW: persist reason to attendance =====
      ...(reasonText ? { reason: reasonText } : {}),
      ...(reasonId ? { reasonId } : {}),
      ...(reasonTypeId ? { reasonTypeId } : {}),
      ...(reasonTypeName ? { reasonTypeName } : {}),
      status: 'Present',
      approvalStatus: 'Pending',
      companyId,
      createdAt:FieldValue.serverTimestamp(),
      updatedAt:FieldValue.serverTimestamp(),
    });

    if (withinRadius === false || (otherLocation && otherLocation.trim() !== '')) {
      await createOtherLocationEvent({
        empid, name, date: today, time: nowTime, type: 'check-in',
        branchName,
        companyId,
        latitude: checkInLatitude, longitude: checkInLongitude, accuracy: checkInAccuracy,
        expectedLatitude, expectedLongitude, expectedRadius,
        distanceFromBranch, withinRadius, otherLocation
      });
    }

    if (!empSnap.empty) {
      await empSnap.docs[0].ref.update({
        status: 'active',
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    
    // Track usage after successful check-in
    await trackAttendanceUsage(req, {
      writeCount: 1,
      apiCalls: 1,
      attendanceCount: 1,
    });
    
    return res.json({ message: 'Checked-in successfully' });
  } catch (err: any) {
    console.error('checkIn error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** POST /api/attendance/check-out */
export const checkOut = async (req: Request, res: Response) => {
  const companyId = getReqCompanyId(req);
  if (!companyId) {
    return res.status(403).json({ error: 'companyId missing in token' });
  }

  const empid    = getReqEmpId(req) || '';
  const location = normStr((req.body as any)?.location);

  const checkOutLatitude  = typeof (req.body as any)?.latitude  === 'number' ? (req.body as any).latitude  : null;
  const checkOutLongitude = typeof (req.body as any)?.longitude === 'number' ? (req.body as any).longitude : null;
  const checkOutAccuracy  = typeof (req.body as any)?.accuracy  === 'number' ? (req.body as any).accuracy  : null;

  // ===== NEW: Reason coming from client (dropdown) for checkout as well =====
  const reasonId        = normStr((req.body as any)?.reasonId) || null;
  const reasonText      = normStr((req.body as any)?.reasonText || (req.body as any)?.reason) || null;
  const reasonTypeId    = normStr((req.body as any)?.reasonTypeId) || null;
  const reasonTypeName  = normStr((req.body as any)?.reasonTypeName) || null;

  if (!empid || !location) {
    return res.status(400).json({ error: 'empid and location are required' });
  }
  const today = toYMD(new Date());

  try {
    const snap = await db.collection(ATT_COL)
      .where('empid', '==', empid)
      .where('date', '==', today)
      .where('companyId', '==', companyId)
      .limit(1)
      .get();

    if (snap.empty) return res.status(400).json({ error: 'You need to check in first' });

    const doc = snap.docs[0];
    if (doc.data().checkOut) {
      // still allow saving/overriding reason if sent
      if (reasonText) {
        await doc.ref.set({
          reason: reasonText,
          reasonId: reasonId || null,
          reasonTypeId: reasonTypeId || null,
          reasonTypeName: reasonTypeName || null,
          updatedAt:FieldValue.serverTimestamp(),
        }, { merge: true });
      }
      return res.status(400).json({ error: 'Already checked out today' });
    }

    const current = doc.data() as any;
    const branchName = normStr(current.branchName || location || current.location || '');

    let expectedLatitude: number | null = current.expectedLatitude ?? null;
    let expectedLongitude: number | null = current.expectedLongitude ?? null;
    let expectedRadius: number | null = current.expectedRadius ?? null;

    if (expectedLatitude == null || expectedLongitude == null || expectedRadius == null) {
      const office = await findOfficeByBranchName(branchName, companyId);
      if (office) {
        expectedLatitude  = Number((office as any).latitude ?? 0) || 0;
        expectedLongitude = Number((office as any).longitude ?? 0) || 0;
        expectedRadius    = Number((office as any).radius ?? 0) || 0;
      }
    }

    const checkoutDistanceFromBranch = haversineMeters(checkOutLatitude, checkOutLongitude, expectedLatitude, expectedLongitude);
    const checkoutWithinRadius = (checkoutDistanceFromBranch != null && expectedRadius != null)
      ? checkoutDistanceFromBranch <= expectedRadius
      : null;

    const nowTime = nowTimeIST();

    await doc.ref.update({
      checkOut: nowTime,
      checkOutTsUtc: nowUtcISO(),               // <<< AUDIT FIELD
      location: branchName,
      checkOutLatitude,
      checkOutLongitude,
      checkOutAccuracy,
      branchName,
      expectedLatitude,
      expectedLongitude,
      expectedRadius,
      checkoutDistanceFromBranch,
      checkoutWithinRadius,
      // ===== NEW: persist reason to attendance on checkout as well =====
      ...(reasonText ? { reason: reasonText } : {}),
      ...(reasonId ? { reasonId } : {}),
      ...(reasonTypeId ? { reasonTypeId } : {}),
      ...(reasonTypeName ? { reasonTypeName } : {}),
      updatedAt: FieldValue.serverTimestamp(),
    });

    if (checkoutWithinRadius === false) {
      await createOtherLocationEvent({
        empid,
        name: normStr(current.name || ''),
        date: today,
        time: nowTime,
        type: 'check-out',
        branchName,
        companyId,
        latitude: checkOutLatitude,
        longitude: checkOutLongitude,
        accuracy: checkOutAccuracy,
        expectedLatitude,
        expectedLongitude,
        expectedRadius,
        distanceFromBranch: checkoutDistanceFromBranch,
        withinRadius: checkoutWithinRadius,
        otherLocation: `Outside radius by ${Math.max(0, (checkoutDistanceFromBranch ?? 0) - (expectedRadius ?? 0))} m`,
      });
    }

    const empSnap = await db.collection(EMP_COL).where('empid', '==', empid).where('companyId', '==', companyId).limit(1).get();
    if (!empSnap.empty) {
      await empSnap.docs[0].ref.update({
        status: 'inactive',
        updatedAt:FieldValue.serverTimestamp(),
      });
    }
    
    // Track usage after successful check-out
    await trackAttendanceUsage(req, {
      writeCount: 1,
      apiCalls: 1,
      attendanceCount: 1,
    });

    return res.json({ message: 'Checked-out & set inactive' });
  } catch (err: any) {
    console.error('checkOut error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** GET /api/attendance/live */
export const getLiveAttendance = async (req: Request, res: Response) => {
  const companyId = getReqCompanyId(req);
  if (!companyId) {
    return res.status(403).json({ error: 'companyId missing in token' });
  }

  const today = toYMD(new Date());
  const isAdmin = (req as any).user?.role === 'admin';

  try {
    let employees: any[] = [];
    if (isAdmin) {
      const empSnap = await db.collection(EMP_COL)
        .where('status', 'in', ['active', 'inactive'])
        .where('companyId', '==', companyId)
        .get();
      employees = empSnap.docs.map(d => d.data());
    } else {
      const empid = getReqEmpId(req);
      const empSnap = await db.collection(EMP_COL).where('empid', '==', empid).where('companyId', '==', companyId).limit(1).get();
      if (empSnap.empty) return res.json([]);
      employees = [empSnap.docs[0].data()];
    }

    const attSnap = await db.collection(ATT_COL).where('date', '==', today).where('companyId', '==', companyId).get();
    const attMap: Record<string, any> = Object.fromEntries(attSnap.docs.map(d => [d.data().empid, d.data()]));

    console.log('=== LIVE ATTENDANCE HALF-DAY DEBUG START ===');
    console.log('Today:', today);
    console.log('Company ID:', companyId);
    
    // Fetch all leaves to include pending Half-Day requests
    const leaveSnap = await db.collection(LEAVE_COL)
      .where('companyId', '==', companyId)
      .get();
    
    console.log('Total leaves fetched:', leaveSnap.size);
    
    const processedLeaves = leaveSnap.docs
      .map(d => d.data())
      .filter((l: any) => {
        const status = String(l.approvalStatus ?? l.status ?? 'Pending').toLowerCase();
        const type = String(l.type ?? l.leaveType ?? '').toLowerCase();
        const startDate = toISO(l.startDate || l.selectDate || l.requestDate || l.date);
        const endDate = toISO(l.endDate || l.startDate || l.selectDate || l.requestDate || l.date);
        
        console.log('=== LEAVE DOCUMENT DEBUG ===');
        console.log('Leave doc:', { 
          empid: l.empid, 
          type: l.type, 
          leaveType: l.leaveType, 
          status: l.status, 
          approvalStatus: l.approvalStatus,
          startDate, 
          endDate 
        });
        
        // Include approved leaves of any type
        const isApproved = status === 'approved';
        // Include pending Half-Day leave requests
        const isHalfDayPending = status === 'pending' && (type.includes('half') || type.includes('half day') || type.includes('half-day'));
        
        // Check if leave covers today
        const coversToday = startDate && endDate && startDate <= today && today <= endDate;
        
        if (isApproved && coversToday) {
          console.log('Approved leave covering today:', { empid: l.empid, type: l.type, leaveType: l.leaveType, startDate, endDate });
          return true;
        }
        if (isHalfDayPending && coversToday) {
          console.log('Pending Half-Day leave covering today:', { empid: l.empid, type: l.type, leaveType: l.leaveType, startDate, endDate });
          return true;
        }
        
        console.log('Leave excluded:', { isApproved, isHalfDayPending, coversToday });
        console.log('=== END LEAVE DOCUMENT DEBUG ===');
        return false;
      });
    
    console.log('Processed leaves count:', processedLeaves.length);
    
    // Separate regular leaves and Half-Day leaves
    const regularLeaves = processedLeaves.filter((l: any) => {
      const type = String(l.type ?? l.leaveType ?? '').toLowerCase();
      return !type.includes('half') && !type.includes('half day') && !type.includes('half-day');
    });
    
    const halfDayLeaves = processedLeaves.filter((l: any) => {
      const type = String(l.type ?? l.leaveType ?? '').toLowerCase();
      return type.includes('half') || type.includes('half day') || type.includes('half-day');
    });
    
    console.log('Regular leaves:', regularLeaves.length);
    console.log('Half-Day leaves:', halfDayLeaves.length);
    
    const leaveSet = new Set(regularLeaves.map((l: any) => (l as any).empid));
    const halfDayLeaveSet = new Set(halfDayLeaves.map((l: any) => (l as any).empid));

    const shiftsSnap = await db.collection(SHIFT_COL)
        .where('companyId', '==', companyId)
        .get();
    const shiftByGroup: Record<string, any> =
      Object.fromEntries(shiftsSnap.docs.map(d => [d.data().shiftname, d.data()]));

    const isHoliday = HOLIDAYS_SET.has(today);
    const isWeekOff = isSunday(today); // <— now IST-safe

    const result = employees.map(emp => {
      const empid = (emp as any).empid;
      const rec = attMap[empid];
      let status: string;
      let isLate = false, isEarly = false;

      let permissionCount = Array.isArray(rec?.permissionRequests)
        ? rec.permissionRequests.length
        : (rec?.permissionRequest ? 1 : 0);

      console.log('=== EMPLOYEE HALF-DAY DEBUG ===');
      console.log('Employee ID:', empid);
      console.log('Has Half-Day leave:', halfDayLeaveSet.has(empid));
      console.log('Has regular leave:', leaveSet.has(empid));
      console.log('Attendance record:', rec ? { checkIn: rec.checkIn, checkOut: rec.checkOut } : null);

      // Priority 1: Check for Half-Day leave requests (approved or pending)
      if (halfDayLeaveSet.has(empid)) {
        status = 'Half Day';
        console.log('Final status: Half Day (from leave request)');
      }
      // Priority 2: Holiday/WeekOff
      else if (isHoliday) {
        status = 'Holiday';
        console.log('Final status: Holiday');
      }
      else if (isWeekOff) {
        status = 'WeekOff';
        console.log('Final status: WeekOff');
      }
      // Priority 3: Regular leave
      else if (leaveSet.has(empid)) {
        status = 'Leave';
        console.log('Final status: Leave');
      }
      // Priority 4: Attendance-based calculation
      else if (rec?.checkIn) {
        status = 'Present';
        const shift = shiftByGroup[(emp as any).shiftGroup] || {};
        const start = shift.startTime || '09:00';
        const end   = shift.endTime   || '18:00';
        
        // Fixed: Proper DateTime comparison with grace period
        const graceMinutes = 5; // 5 minutes grace period
        const [startHour, startMinute] = start.split(':').map(Number);
        const [checkInHour, checkInMinute] = rec.checkIn.split(':').map(Number);
        
        // Create DateTime objects for today
        const now = new Date();
        const shiftStartDateTime = new Date(now.getFullYear(), now.getMonth(), now.getDate(), startHour, startMinute, 0);
        const shiftStartWithGrace = new Date(shiftStartDateTime.getTime() + graceMinutes * 60000);
        const checkInDateTime = new Date(now.getFullYear(), now.getMonth(), now.getDate(), checkInHour, checkInMinute, 0);
        
        // Debug logging
        console.log('LATE CHECK-IN DEBUG:', {
          empid: (emp as any).empid,
          shiftGroup: (emp as any).shiftGroup,
          shiftStartTime: start,
          checkInTime: rec.checkIn,
          graceMinutes,
          calculatedShiftStartDateTime: shiftStartDateTime.toISOString(),
          calculatedShiftStartWithGrace: shiftStartWithGrace.toISOString(),
          calculatedCheckInDateTime: checkInDateTime.toISOString(),
          isLateCheckIn: checkInDateTime > shiftStartWithGrace
        });
        
        // Check if this is Open Shift
        const employeeShiftGroup = (emp as any).shiftGroup;
        const isEmployeeOpenShift = isOpenShift(employeeShiftGroup);
        
        if (isEmployeeOpenShift) {
          // Open Shift employees are never late
          isLate = false;
          console.log('Open Shift employee - never marked as late:', { empid: (emp as any).empid, shiftGroup: employeeShiftGroup });
        } else {
          // Fixed Shift: Only mark as late if check-in is after shift start + grace period
          isLate = checkInDateTime > shiftStartWithGrace;
        }
        
        // Early checkout logic (unchanged)
        isEarly = rec.checkOut && rec.checkOut < end;
        console.log('Final status: Present (attendance-based)');
      } else {
        status = 'Absent';
        console.log('Final status: Absent');
      }

      // Fallback Half-Day calculation from attendance timing (only if no leave request)
      let isHalfDay = false;
      let halfDayReason = '';
      
      // Check if this is Open Shift
      const shiftGroup = (emp as any).shiftGroup || '';
      const shift = shiftByGroup[shiftGroup] || {};
      const isOS = isOpenShift(shiftGroup);
      
      console.log('OPEN SHIFT HALF-DAY DEBUG:', {
        empid: (emp as any).empid,
        shiftGroup: shiftGroup,
        isOpenShift: isOS,
        hasCheckIn: !!rec?.checkIn,
        hasCheckOut: !!rec?.checkOut,
        checkInTime: rec?.checkIn,
        checkOutTime: rec?.checkOut
      });
      
      if (halfDayLeaveSet.has(empid)) {
        // Half-Day from leave request takes priority
        isHalfDay = true;
        halfDayReason = 'Half Day from leave request';
        console.log('Half-Day determined from leave request');
      } else if (isOS) {
        // Open Shift: Only calculate half-day after both checkIn and checkOut are available
        if (rec?.checkIn && rec?.checkOut) {
          // Calculate worked duration in minutes
          const [checkInHour, checkInMinute] = rec.checkIn.split(':').map(Number);
          const [checkOutHour, checkOutMinute] = rec.checkOut.split(':').map(Number);
          
          const checkInDateTime = new Date();
          checkInDateTime.setHours(checkInHour, checkInMinute, 0, 0);
          
          const checkOutDateTime = new Date();
          checkOutDateTime.setHours(checkOutHour, checkOutMinute, 0, 0);
          
          // Handle overnight check-out (if checkOut is earlier than checkIn, assume next day)
          if (checkOutDateTime < checkInDateTime) {
            checkOutDateTime.setDate(checkOutDateTime.getDate() + 1);
          }
          
          const workedDurationMinutes = (checkOutDateTime.getTime() - checkInDateTime.getTime()) / (1000 * 60);
          
          console.log('OPEN SHIFT WORKED DURATION DEBUG:', {
            empid: (emp as any).empid,
            checkInTime: rec.checkIn,
            checkOutTime: rec.checkOut,
            workedDurationMinutes: workedDurationMinutes,
            threshold: 300 // 5 hours = 300 minutes
          });
          
          if (workedDurationMinutes < 300) {
            isHalfDay = true;
            halfDayReason = 'Worked less than 5 hours in Open Shift';
            console.log('Open Shift Half-Day: Worked less than 5 hours');
          } else {
            isHalfDay = false;
            halfDayReason = 'Worked 5+ hours in Open Shift';
            console.log('Open Shift Full Day: Worked 5+ hours');
          }
        } else {
          // Open Shift but missing checkIn or checkOut - don't mark half-day yet
          isHalfDay = false;
          halfDayReason = 'Open Shift - waiting for both checkIn and checkOut';
          console.log('Open Shift - not calculating half-day yet, missing checkIn or checkOut');
        }
      } else if (status === 'Present' && shiftByGroup[(emp as any).shiftGroup] && !isOpenShift(shiftGroup)) {
        // Fixed Shift: Apply existing logic (only for non-Open Shift)
        const [h1, m1] = (shift.startTime || '09:00').split(':').map(Number);
        const [h2, m2] = (shift.endTime   || '18:00').split(':').map(Number);
        const midSec = ((h1 * 3600 + m1 * 60) + (h2 * 3600 + m2 * 60)) / 2;
        const inSec = rec && rec.checkIn
          ? rec.checkIn.split(':').reduce((a: number, v: string, i: number) => a + (+v) * (i === 0 ? 3600 : 60), 0)
          : 0;
        isHalfDay = inSec > midSec;
        halfDayReason = isHalfDay ? 'Fixed Shift - checked in after midpoint' : 'Fixed Shift - checked in before midpoint';
        console.log('Fixed Shift Half-Day determined from attendance timing:', { inSec, midSec, isHalfDay });
      }
      
      console.log('FINAL HALF-DAY RESULT:', {
        empid: (emp as any).empid,
        isHalfDay: isHalfDay,
        halfDayReason: halfDayReason
      });
      
      console.log('=== END EMPLOYEE HALF-DAY DEBUG ===');

      return {
        empid:          (emp as any).empid,
        name:           (emp as any).name,
        shiftGroup:     (emp as any).shiftGroup,
        date:           today,
        status,
        checkIn:        rec?.checkIn || null,
        checkOut:       rec?.checkOut || null,
        late:           isLate,
        early:          isEarly,
        permissionCount,
        leave:          status === 'Leave',
        holiday:        status === 'Holiday',
        weekOff:        status === 'WeekOff',
        halfDay:        isHalfDay,
        branchName:                 rec?.branchName ?? null,
        withinRadius:               rec?.withinRadius ?? null,
        distanceFromBranch:         rec?.distanceFromBranch ?? null,
        checkoutWithinRadius:       rec?.checkoutWithinRadius ?? null,
        checkoutDistanceFromBranch: rec?.checkoutDistanceFromBranch ?? null,
      };
    });

    console.log('=== LIVE ATTENDANCE HALF-DAY DEBUG END ===');
    console.log('Total employees processed:', result.length);
    console.log('Half-Day employees:', result.filter((r: any) => r.halfDay).length);

    // Track usage after successful live attendance read
    await trackAttendanceUsage(req, {
      readCount: 1,
      apiCalls: 1,
    });
    
    return res.json(result);
  } catch (err: any) {
    console.error('getLiveAttendance error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** Admin: list all attendance records */
export const getAllAttendance = async (req: Request, res: Response) => {
  const companyId = getReqCompanyId(req);
  if (!companyId) {
    return res.status(403).json({ error: 'companyId missing in token' });
  }

  try {
    const snap = await db.collection(ATT_COL).where('companyId', '==', companyId).get();
    const records = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    return res.json(records);
  } catch (err: any) {
    console.error('getAllAttendance error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** GET /api/attendance/employee/:empid */
export const getEmployeeAttendance = async (req: Request, res: Response) => {
  const companyId = getReqCompanyId(req);
  if (!companyId) {
    return res.status(403).json({ error: 'companyId missing in token' });
  }

  const { empid } = req.params;
  try {
    const snap = await db.collection(ATT_COL)
      .where('empid', '==', empid)
      .where('companyId', '==', companyId)
      .orderBy('date', 'desc').get();
    const records = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    return res.json(records);
  } catch (err: any) {
    console.error('getEmployeeAttendance error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** Admin: approve/reject an attendance row by document id */
export const approveAttendance = async (req: Request, res: Response) => {
  const companyId = getReqCompanyId(req);
  if (!companyId) {
    return res.status(403).json({ error: 'companyId missing in token' });
  }

  const { id, status } = req.body as { id: string; status: 'Approved' | 'Rejected' | string };
  try {
    // Load the document first to verify companyId
    const doc = await db.collection(ATT_COL).doc(id).get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Attendance record not found' });
    }
    
    const docData = doc.data();
    if (docData?.companyId !== companyId) {
      return res.status(403).json({ error: 'Access denied: companyId mismatch' });
    }

    await doc.ref.update({
      approvalStatus: status,
      updatedAt:FieldValue.serverTimestamp(),
    });
    return res.json({ message: `Attendance ${String(status).toLowerCase()} successfully` });
  } catch (err: any) {
    console.error('approveAttendance error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** GET /api/attendance/roster?date=YYYY-MM-DD */
export const getDailyRoster = async (req: Request, res: Response) => {
  const companyId = getReqCompanyId(req);
  if (!companyId) {
    return res.status(403).json({ error: 'companyId missing in token' });
  }

  const date = String(req.query.date || '');
  if (!date) return res.status(400).json({ error: 'Missing ?date=YYYY-MM-DD' });

  try {
    const empSnap = await db.collection(EMP_COL).where('companyId', '==', companyId).get();
    const employees = empSnap.docs.map(d => d.data());

    const attSnap = await db.collection(ATT_COL).where('date', '==', date).where('companyId', '==', companyId).get();
    const attByEmp: Record<string, any> = Object
    .fromEntries(attSnap.docs.map(d => [d.data().empid, d.data()]));

    const roster = employees.map((emp: any) => {
      const rec = attByEmp[emp.empid];
      let raw = 'Absent';
      if (rec?.approvalStatus === 'Approved' && !rec.checkIn) raw = 'Leave';
      else if (rec?.checkIn) raw = rec.checkIn > '09:00' ? 'Late' : 'Present';
      return {
        empid:      emp.empid,
        name:       emp.name || '',
        shiftGroup: emp.shiftGroup,
        status:     (raw === 'Present' || raw === 'Late') ? 'active' : 'inactive',
      };
    });

    return res.json(roster);
  } catch (err: any) {
    console.error('getDailyRoster error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** GET /api/attendance/range-summary?start=YYYY-MM-DD&end=YYYY-MM-DD */
export const getRangeSummary = async (req: Request, res: Response) => {
  console.log('=== RANGE SUMMARY DEBUG START ===');
  console.log('req.user:', req.user);
  
  const companyId = getReqCompanyId(req);
  console.log('companyId:', companyId);
  
  if (!companyId) {
    console.log('ERROR: companyId missing in token');
    return res.status(403).json({ error: 'companyId missing in token' });
  }

  try {
    const start = String(req.query.start || '').slice(0, 10);
    const end   = String(req.query.end   || '').slice(0, 10);
    console.log('Query params - start:', start, 'end:', end);
    
    if (!start || !end) {
      console.log('ERROR: Missing start or end date');
      return res.status(400).json({ error: 'Provide ?start=YYYY-MM-DD&end=YYYY-MM-DD' });
    }
    
    // Validate date format and range
    try {
      const startDate = new Date(start);
      const endDate = new Date(end);
      if (isNaN(startDate.getTime()) || isNaN(endDate.getTime())) {
        console.log('ERROR: Invalid date format');
        return res.status(400).json({ error: 'Invalid date format. Use YYYY-MM-DD' });
      }
      if (endDate < startDate) {
        console.log('ERROR: End date before start date');
        return res.status(400).json({ error: 'End date must be after start date' });
      }
    } catch (dateErr) {
      console.log('ERROR: Date parsing error:', dateErr);
      return res.status(400).json({ error: 'Invalid date format. Use YYYY-MM-DD' });
    }

    console.log('Fetching employees...');
    const empSnap = await db.collection(EMP_COL)
      .where('status', '==', 'active')
      .where('companyId', '==', companyId)
      .get();
    
    console.log('Employee snapshot size:', empSnap.size);
    const employees = empSnap.docs.map(d => {
      const data = d.data();
      console.log('Employee doc:', { empid: data.empid, name: data.name, status: data.status });
      return data;
    });

    const activeEmployees = employees.filter((e: any) =>
      String(e.status || '').toLowerCase() === 'active'
    ).length;
    console.log('Active employees count:', activeEmployees);

    console.log('Fetching shifts...');
    const shiftsSnap = await db.collection(SHIFT_COL)
      .where('companyId', '==', companyId)
      .get();
    
    console.log('Shifts snapshot size:', shiftsSnap.size);
    const shiftByGroup: Record<string, any> = {};
    shiftsSnap.docs.forEach(d => {
      const data = d.data();
      const group = data.group || 'unknown';
      shiftByGroup[group] = data;
      console.log('Shift doc:', { group, startTime: data.startTime, endTime: data.endTime });
    });

    console.log('Fetching attendance records...');
    const attSnap = await db.collection(ATT_COL)
      .where('companyId', '==', companyId)
      .where('date', '>=', start)
      .where('date', '<=', end)
      .get();
    
    console.log('Attendance snapshot size:', attSnap.size);
    const attByEmpDate: Record<string, any> = {};
    attSnap.forEach(doc => { 
      const a = doc.data();
      const key = `${a.empid || 'unknown'}|${a.date || 'unknown'}`;
      attByEmpDate[key] = { id: doc.id, ...a };
    });

    console.log('Fetching all leaves (including pending Half-Day requests)...');
    let leavesSnap;
    try {
      // Fetch all leaves to include pending Half-Day requests
      leavesSnap = await db.collection(LEAVE_COL).get();
    } catch (leaveErr) {
      console.log('Warning: Failed to fetch leaves:', leaveErr);
      leavesSnap = await db.collection(LEAVE_COL).get();
    }
    
    console.log('Leaves snapshot size:', leavesSnap.size);
    const allLeaves = leavesSnap.docs
      .map(d => d.data())
      .filter((L: any) => {
        const status = String(L.approvalStatus ?? L.status ?? 'Pending').toLowerCase();
        const type = String(L.type ?? '').toLowerCase();
        
        // Include approved leaves of any type
        const isApproved = status === 'approved';
        // Include pending Half-Day leave requests
        const isHalfDayPending = status === 'pending' && (type.includes('half') || type.includes('half day') || type.includes('half-day'));
        
        if (isApproved) {
          console.log('Approved leave:', { empid: L.empid, type: L.type, startDate: L.startDate, endDate: L.endDate });
        }
        if (isHalfDayPending) {
          console.log('Pending Half-Day leave:', { empid: L.empid, type: L.type, startDate: L.startDate, endDate: L.endDate });
        }
        
        return isApproved || isHalfDayPending;
      })
      .map((L: any) => ({
        empid: L.empid || '',
        type: String(L.type || ''),
        start: toISO(L.startDate || L.selectDate || L.date),
        end:   toISO(L.endDate   || L.selectDate || L.date || L.startDate),
      }))
      .filter((L: any) => L.empid && L.start); // Ensure valid data

    console.log('All leaves count (including pending Half-Day):', allLeaves.length);

    const leaveDays = new Set<string>();
    let onLeaveCount = 0;
    for (const L of allLeaves) {
      if (!L.start) continue;
      const s = L.start, e = L.end || L.start;
      if (e < start || s > end) continue;
      
      try {
        const dateRange = eachYMD((s < start ? start : s), (e > end ? end : e));
        for (const d of dateRange) {
          leaveDays.add(`${L.empid}|${d}`);
          onLeaveCount++;
        }
      } catch (dateErr) {
        console.log('Error processing leave date range:', { L, dateErr });
      }
    }
    console.log('Leave days count:', onLeaveCount);

    let checkedIn = 0, absent = 0, lateIn = 0, earlyOut = 0, halfDay = 0, presentApproved = 0, holiday = 0, weekOff = 0;
    const rows: any[] = [];
    
    try {
      const dates = eachYMD(start, end);
      console.log('Processing', dates.length, 'days from', start, 'to', end);

      for (const ymd of dates) {
        const isHoliday = HOLIDAYS_SET.has(ymd);
        const isWO = isSunday(ymd);
        if (isHoliday) holiday++;
        if (isWO) weekOff++;

        for (const emp of employees) {
          try {
            const empid = (emp as any).empid || 'unknown';
            const key = `${empid}|${ymd}`;
            const att = attByEmpDate[key] || null;
            const shiftGroup = (emp as any).shiftGroup || 'default';
            const shift = shiftByGroup[shiftGroup] || { startTime: '09:00', endTime: '18:00' };
            const startT = shift.startTime || '09:00';
            const endT   = shift.endTime   || '18:00';
            const mid    = midpointHHMM(startT, endT);

            let status = 'Absent';
            let isLate = false, isEarly = false;

            if (isHoliday) {
              status = 'Holiday';
            } else if (isWO) {
              status = 'WeekOff';
            } else if (leaveDays.has(key)) {
              console.log('=== HALF-DAY LEAVE DEBUG ===');
              console.log('Employee ID:', empid);
              console.log('Date:', ymd);
              console.log('Leave days key found:', key);
              
              const matchingLeave = allLeaves.find((l: any) =>
                l.empid === empid && l.start <= ymd && ymd <= (l.end || l.start)
              );
              
              console.log('Matching leave:', matchingLeave ? {
                empid: matchingLeave.empid,
                type: matchingLeave.type,
                start: matchingLeave.start,
                end: matchingLeave.end
              } : null);
              
              status = matchingLeave && matchingLeave.type.toLowerCase().includes('half') ? 'Half Day' : 'On Leave';
              console.log('Final status from leave:', status);
              
              if (status === 'Half Day') {
                halfDay++;
                console.log('Half-Day count incremented:', halfDay);
              }
              console.log('=== END HALF-DAY LEAVE DEBUG ===');
            } else if (att?.checkIn) {
              checkedIn++;
              status = 'Present';
              
              try {
                if (cmpHHMM(att.checkIn, startT)) { isLate = true; lateIn++; }
                if (att.checkOut && !cmpHHMM(att.checkOut, endT)) { isEarly = true; earlyOut++; }
                
                // Fixed: Handle Open Shift half-day logic properly
                const isOS = isOpenShift(shiftGroup);
                console.log('MONTHLY SUMMARY OPEN SHIFT DEBUG:', {
                  empid: empid,
                  shiftGroup: shiftGroup,
                  isOpenShift: isOS,
                  checkIn: att.checkIn,
                  checkOut: att.checkOut,
                  mid: mid
                });
                
                if (isOS) {
                  // Open Shift: Only calculate half-day after both checkIn and checkOut are available
                  if (att.checkIn && att.checkOut) {
                    // Calculate worked duration in minutes
                    const [checkInHour, checkInMinute] = att.checkIn.split(':').map(Number);
                    const [checkOutHour, checkOutMinute] = att.checkOut.split(':').map(Number);
                    
                    const checkInDateTime = new Date();
                    checkInDateTime.setHours(checkInHour, checkInMinute, 0, 0);
                    
                    const checkOutDateTime = new Date();
                    checkOutDateTime.setHours(checkOutHour, checkOutMinute, 0, 0);
                    
                    // Handle overnight check-out
                    if (checkOutDateTime < checkInDateTime) {
                      checkOutDateTime.setDate(checkOutDateTime.getDate() + 1);
                    }
                    
                    const workedDurationMinutes = (checkOutDateTime.getTime() - checkInDateTime.getTime()) / (1000 * 60);
                    
                    console.log('MONTHLY SUMMARY OPEN SHIFT WORKED DURATION:', {
                      empid: empid,
                      workedDurationMinutes: workedDurationMinutes,
                      threshold: 300
                    });
                    
                    if (workedDurationMinutes < 300) {
                      status = 'Half Day';
                      halfDay++;
                      console.log('Monthly Summary: Open Shift Half-Day - worked less than 5 hours');
                    } else {
                      console.log('Monthly Summary: Open Shift Full Day - worked 5+ hours');
                    }
                  } else {
                    console.log('Monthly Summary: Open Shift - waiting for both checkIn and checkOut');
                  }
                } else if (!isOpenShift(shiftGroup)) {
                  // Fixed Shift: Apply existing midpoint logic (only for non-Open Shift)
                  if (cmpHHMM(att.checkIn, mid)) { 
                    status = 'Half Day'; 
                    halfDay++; 
                    console.log('Monthly Summary: Fixed Shift Half-Day - checked in after midpoint');
                  }
                }
                
                if (String(att.approvalStatus || '').toLowerCase() === 'approved') presentApproved++;
              } catch (timeErr) {
                console.log('Error processing time comparison:', { att, timeErr });
              }
            } else {
              absent++;
            }

            rows.push({
              employeeId: empid,
              employeeName: (emp as any).name || '',
              shift: (emp as any).shift || (emp as any).shiftGroup || '',
              date: ymd,
              checkIn: att?.checkIn || '-',
              checkOut: att?.checkOut || '-',
              department: (emp as any).dept || (emp as any).department || '',
              attendance: status,
              workedHours: att?.workedHours ? String(att.workedHours) : '-',
              late: isLate,
              early: isEarly,
              approval: att?.approvalStatus || 'Pending',
            });
          } catch (empErr) {
            console.log('Error processing employee:', { emp: (emp as any).empid, ymd, empErr });
            // Continue with next employee
          }
        }
      }
    } catch (dateRangeErr) {
      console.log('Error processing date range:', dateRangeErr);
      return res.status(500).json({ error: 'Failed to process date range: ' + String(dateRangeErr) });
    }

    console.log('Final counts:', {
      activeEmployees,
      onLeave: onLeaveCount,
      checkedIn,
      absent,
      lateCheckIn: lateIn,
      earlyCheckOut: earlyOut,
      halfDay,
      present: presentApproved,
      holiday,
      weekOff,
      totalRows: rows.length
    });

    const response = {
      counts: {
        activeEmployees,
        onLeave: onLeaveCount,
        checkedIn,
        absent,
        lateCheckIn: lateIn,
        earlyCheckOut: earlyOut,
        halfDay,
        present: presentApproved,
        holiday,
        weekOff,
      },
      rows,
    };

    console.log('=== RANGE SUMMARY DEBUG END ===');
    return res.json(response);
  } catch (err: any) {
    console.error('=== RANGE SUMMARY ERROR ===');
    console.error('getRangeSummary error:', err);
    console.error('Error stack:', err.stack);
    console.error('Request details:', {
      query: req.query,
      user: req.user,
      companyId: companyId
    });
    
    // Return a more specific error message
    const errorMessage = err.message || 'Unknown error occurred';
    return res.status(500).json({ 
      error: errorMessage,
      details: 'Failed to generate range summary. Check server logs for details.'
    });
  }
};
/** POST /api/attendance/approvals/decision */
export const decideApproval = async (req: Request, res: Response) => {
  try {
    const companyId = (req as any).user?.companyId;
    if (!companyId) {
      return res.status(403).json({ error: 'companyId missing in token' });
    }

    const { source, attendanceId, leaveId, empid, date, status, remarks, id, requestId } = req.body || {};
    const clean = normStr(status);
    if (!['Approved', 'Rejected'].includes(clean)) {
      return res.status(400).json({ error: 'status must be Approved or Rejected' });
    }
    if (!source || !['attendance', 'leaves'].includes(source)) {
      return res.status(400).json({ error: 'source must be attendance or leaves' });
    }

    const genericId = String(id || requestId || '');

    if (source === 'attendance') {
      if (attendanceId) {
        const doc = await db.collection(ATT_COL).doc(String(attendanceId)).get();
        if (!doc.exists) {
          return res.status(404).json({ error: 'Attendance record not found' });
        }
        
        const docData = doc.data();
        if (docData?.companyId !== companyId) {
          return res.status(403).json({ error: 'Access denied: companyId mismatch' });
        }

        await doc.ref.update({
            approvalStatus: clean,
            status: clean,
            decisionBy: (req as any).user?.empid || 'admin',
            decisionAt: FieldValue.serverTimestamp(),
            decisionRemarks: remarks || null,
            updatedAt: FieldValue.serverTimestamp(),
       });
        return res.json({ message: `Attendance ${clean.toLowerCase()} successfully` });
      }

      if (genericId) {
        const attRef = db.collection(ATT_COL).doc(genericId);
        const attDoc = await attRef.get();
        if (attDoc.exists) {
          const attData = attDoc.data();
          if (attData?.companyId !== companyId) {
            return res.status(403).json({ error: 'Access denied: companyId mismatch' });
          }
          
          await attRef.update({
            approvalStatus: clean,
            decisionBy: (req as any).user?.empid || 'admin',
            decisionAt: FieldValue.serverTimestamp(),
            decisionRemarks: remarks || null,
          });
          return res.json({ message: `Attendance ${clean.toLowerCase()} successfully` });
        }

        const olRef = db.collection(OTHER_LOC_COL).doc(genericId);
        const olDoc = await olRef.get();
        if (olDoc.exists) {
          const olData = olDoc.data();
          if (olData?.companyId !== companyId) {
            return res.status(403).json({ error: 'Access denied: companyId mismatch' });
          }
          
          await olRef.update({
            approvalStatus: clean,
            decisionBy: (req as any).user?.empid || 'admin',
            decisionAt: FieldValue.serverTimestamp(),
            decisionRemarks: remarks || null,
            updatedAt: FieldValue.serverTimestamp(),
          });
          return res.json({ message: `Other-location ${clean.toLowerCase()} successfully` });
        }
      }

      if (empid && date) {
        const q = await db.collection(ATT_COL)
          .where('empid', '==', empid)
          .where('date', '==', date)
          .where('companyId', '==', companyId)
          .limit(1).get();
        if (q.empty) return res.status(404).json({ error: 'Attendance record not found' });

        await q.docs[0].ref.update({
          approvalStatus: clean,
          decisionBy: (req as any).user?.empid || 'admin',
          decisionAt: FieldValue.serverTimestamp(),
          decisionRemarks: remarks || null,
        });
        return res.json({ message: `Attendance ${clean.toLowerCase()} successfully` });
      }

      return res.status(400).json({ error: 'attendanceId or (id/requestId) or (empid & date) required' });
    }

    if (!leaveId) return res.status(400).json({ error: 'leaveId required' });
      
    const leaveDoc = await db.collection(LEAVE_COL).doc(String(leaveId)).get();
    if (!leaveDoc.exists) {
      return res.status(404).json({ error: 'Leave record not found' });
    }
      
    const leaveData = leaveDoc.data();
    if (leaveData?.companyId !== companyId) {
      return res.status(403).json({ error: 'Access denied: companyId mismatch' });
    }
      
    await leaveDoc.ref.update({
         approvalStatus: clean,
         status: clean,
         decisionBy: (req as any).user?.empid || 'admin',
         decisionAt: FieldValue.serverTimestamp(),
         decisionRemarks: remarks || null,
         updatedAt: FieldValue.serverTimestamp(),
   });
    return res.json({ message: `Leave ${clean.toLowerCase()} successfully` });
  } catch (err: any) {
    console.error('decideApproval error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/* ============================== NEW: Other Location routes (optional) ============================== */

/** GET /api/attendance/other-location?status=Pending|Approved|Rejected|All&start=YYYY-MM-DD&end=YYYY-MM-DD */
export const listOtherLocationEvents = async (req: Request, res: Response) => {
  const companyId = (req as any).user?.companyId;
  if (!companyId) {
    return res.status(403).json({ error: 'companyId missing in token' });
  }

  try {
    const statusRaw = normStr(req.query.status || 'All');
    const want = statusRaw.toLowerCase();
    const start = (String(req.query.start || '').slice(0, 10)) || null;
    const end   = (String(req.query.end   || '').slice(0, 10)) || null;

    let ref: any = db.collection(OTHER_LOC_COL).where('companyId', '==', companyId);
    if (want !== 'all') ref = ref.where('approvalStatus', '==', statusRaw);
    if (start) ref = ref.where('date', '>=', start);
    if (end)   ref = ref.where('date', '<=', end);

    const snap = await ref.get();
    const rows = snap.docs.map((d: any) => ({ id: d.id, ...d.data() }));

    rows.sort((a: any, b: any) =>
      String(b.date || '').localeCompare(String(a.date || '')) ||
      String(b.time || '').localeCompare(String(a.time || ''))
    );

    return res.json(rows);
  } catch (err: any) {
    console.error('listOtherLocationEvents error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** POST /api/attendance/other-location/decision */
export const decideOtherLocationEvent = async (req: Request, res: Response) => {
  const companyId = (req as any).user?.companyId;
  if (!companyId) {
    return res.status(403).json({ error: 'companyId missing in token' });
  }

  const { requestId, source, status, remarks } = req.body;
  
  if (!requestId || !status) {
    return res.status(400).json({ error: 'requestId and status required' });
  }

  const normalizedStatus = normStr(status).toLowerCase();
  if (normalizedStatus !== 'approved' && normalizedStatus !== 'rejected') {
    return res.status(400).json({ error: 'status must be approved or rejected' });
  }

  try {
    let docRef: any;
    
    if (source === 'other_location') {
      docRef = db.collection(OTHER_LOC_COL).doc(requestId);
    } else {
      docRef = db.collection(ATT_COL).doc(requestId);
    }

    const doc = await docRef.get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Request not found' });
    }

    const updateData: any = {
      approvalStatus: normalizedStatus,
      decisionRemarks: remarks || '',
      decisionAt: FieldValue.serverTimestamp(),
    };

    if (source === 'other_location') {
      updateData.status = normalizedStatus;
    }

    await docRef.update(updateData);

    console.log('OTHER LOCATION DECISION UPDATED:', {
      requestId,
      source,
      status: normalizedStatus,
      remarks,
      updatedAt: new Date().toISOString(),
    });

    return res.status(200).json({
      success: true,
      requestId,
      status: normalizedStatus,
      message: 'Request updated successfully'
    });
  } catch (error: any) {
    console.error('OTHER LOCATION DECISION ERROR:', error);
    return res.status(500).json({
      error: 'Failed to update request',
      message: error?.message || 'Unknown error'
    });
  }
};


/** PATCH /api/attendance/approvals/:requestId/payroll-status */
export const updatePayrollStatus = async (req: Request, res: Response) => {
  const companyId = (req as any).user?.companyId;
  if (!companyId) {
    return res.status(403).json({ error: 'companyId missing in token' });
  }

  const { requestId } = req.params as any;
  const { payrollStatus, source } = req.body as any;

  if (!requestId || !payrollStatus || !source) {
    return res.status(400).json({ error: 'requestId, payrollStatus, and source required' });
  }

  const normalizedPayrollStatus = normStr(payrollStatus).toLowerCase();
  if (normalizedPayrollStatus !== 'paid' && normalizedPayrollStatus !== 'unpaid') {
    return res.status(400).json({ error: 'payrollStatus must be paid or unpaid' });
  }

  try {
    let docRef: any;
    
    if (source === 'leaves') {
      docRef = db.collection('leaves').doc(requestId);
    } else if (source === 'attendance') {
      docRef = db.collection('attendance').doc(requestId);
    } else {
      return res.status(400).json({ error: 'source must be leaves or attendance' });
    }

    const doc = await docRef.get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Request not found' });
    }

    // Verify company isolation
    const docData = doc.data() as any;
    if (docData.companyId !== companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const updateData: any = {
      payrollStatus: normalizedPayrollStatus,
      payrollUpdatedAt: FieldValue.serverTimestamp(),
      payrollUpdatedBy: (req as any).user?.empid || 'admin',
    };

    await docRef.update(updateData);

    console.log('PAYROLL STATUS UPDATED:', {
      requestId,
      source,
      payrollStatus: normalizedPayrollStatus,
      updatedAt: new Date().toISOString(),
      updatedBy: (req as any).user?.empid || 'admin',
    });

    return res.status(200).json({
      success: true,
      requestId,
      payrollStatus: normalizedPayrollStatus,
      message: 'Payroll status updated successfully'
    });
  } catch (error: any) {
    console.error('PAYROLL STATUS UPDATE ERROR:', error);
    return res.status(500).json({
      error: 'Failed to update payroll status',
      message: error?.message || 'Unknown error'
    });
  }
};

/** GET /api/attendance/my-requests */
/** GET /api/attendance/approvals */
export const listApprovalRequests = async (req: Request, res: Response) => {
  console.log('RUNTIME APPROVALS HANDLER HIT');
  
  const companyId = getReqCompanyId(req);
  if (!companyId) {
    console.log('INSIDE listApprovalRequests FUNCTION');
    return res.status(403).json({ error: 'companyId missing in token' });
  }

  // Handle status query parameter
  const statusRaw = normStr(req.query.status || 'All');
  const wantStatus = statusRaw.toLowerCase(); // pending|approved|rejected|all
  console.log("====== APPROVAL DEBUG START ======");
  console.log("ROUTE companyId =", companyId);
  console.log("STATUS FILTER =", wantStatus);

  try {
    const out: any[] = [];

    // ---------- Attendance (Late check in/out) ----------
    const attSnap = await db.collection('attendance').get();
    
    // Get all shifts for comparison
    const shiftsSnap = await db.collection('shifts').get();
    const shiftByGroup: Record<string, any> = {};
    shiftsSnap.forEach((d) => {
      const s = d.data();
      shiftByGroup[(s as any).shiftname] = s;
    });

    // Process attendance documents in parallel with employee data fetching
    const attendancePromises = attSnap.docs.map(async (doc) => {
      const a = doc.data() as any;
      
      // Company isolation filter
      if (a.companyId !== companyId) return null;
      
      // Status filtering - only include records matching the requested status
      const currentStatus = normStr(a.approvalStatus || 'Pending').toLowerCase();
      if (wantStatus !== 'all' && currentStatus !== wantStatus) return null;
      
      const shift = shiftByGroup[a.shiftGroup] || {};
      const startTime = shift.startTime || '09:00';
      const endTime = shift.endTime || '18:00';

      let subType: string | null = null;
      
      // Fixed: Proper DateTime comparison for late check-in with grace period
      if (a.checkIn) {
        const graceMinutes = 5; // 5 minutes grace period
        const [startHour, startMinute] = startTime.split(':').map(Number);
        const [checkInHour, checkInMinute] = a.checkIn.split(':').map(Number);
        
        // Create DateTime objects for the attendance date
        const attendanceDate = new Date(a.date || Date.now());
        const shiftStartDateTime = new Date(attendanceDate.getFullYear(), attendanceDate.getMonth(), attendanceDate.getDate(), startHour, startMinute, 0);
        const shiftStartWithGrace = new Date(shiftStartDateTime.getTime() + graceMinutes * 60000);
        const checkInDateTime = new Date(attendanceDate.getFullYear(), attendanceDate.getMonth(), attendanceDate.getDate(), checkInHour, checkInMinute, 0);
        
        // Debug logging
        console.log('APPROVAL REQUEST LATE CHECK-IN DEBUG:', {
          empid: a.empid,
          shiftGroup: a.shiftGroup,
          shiftStartTime: startTime,
          checkInTime: a.checkIn,
          attendanceDate: a.date,
          graceMinutes,
          calculatedShiftStartDateTime: shiftStartDateTime.toISOString(),
          calculatedShiftStartWithGrace: shiftStartWithGrace.toISOString(),
          calculatedCheckInDateTime: checkInDateTime.toISOString(),
          isLateCheckIn: checkInDateTime > shiftStartWithGrace
        });
        
        // Only mark as late if check-in is after shift start + grace period
        if (checkInDateTime > shiftStartWithGrace) {
          subType = 'Late check in';
        }
      }
      
      if (a.checkOut && a.checkOut < endTime) subType = 'Early check out';
      
      if (!subType) return null;

      console.log('Raw attendance document:', {
        docId: doc.id,
        empid: a.empid,
        name: a.name,
        shiftGroup: a.shiftGroup,
        department: a.department,
        branchName: a.branchName,
        location: a.location
      });

      // Fetch employee data to get department and branchName
      let employeeDepartment = '';
      let employeeShift = '';
      let employeeBranchName = '';
      
      try {
        const empSnap = await db
          .collection('employees')
          .where('companyId', '==', companyId)
          .where('empid', '==', a.empid)
          .limit(1)
          .get();
        
        if (!empSnap.empty) {
          const empData = empSnap.docs[0].data();
          employeeDepartment = empData?.dept || '';
          employeeShift = empData?.shiftGroup || a.shiftGroup || '';
          employeeBranchName = empData?.location || empData?.branchName || '';
          console.log('Matched employee document:', {
            empid: a.empid,
            department: employeeDepartment,
            shift: employeeShift,
            branchName: employeeBranchName,
            rawEmployeeData: {
              dept: empData?.dept,
              shiftGroup: empData?.shiftGroup,
              location: empData?.location,
              branchName: empData?.branchName
            }
          });
        } else {
          console.log('No employee document found for empid:', a.empid);
          // Use attendance data as fallback
          employeeShift = a.shiftGroup || '';
        }
      } catch (empError) {
        console.error('Error fetching employee data for empid', a.empid, ':', empError);
        employeeShift = a.shiftGroup || '';
      }

      console.log('Found attendance request:', {
        empid: a.empid,
        type: subType,
        date: a.date,
        checkIn: a.checkIn,
        checkOut: a.checkOut
      });

      return {
        source: 'attendance',
        requestId: doc.id,
        type: subType,
        empid: a.empid,
        name: a.name || '',
        department: employeeDepartment,
        shift: employeeShift,
        shiftGroup: employeeShift,
        requestTime: subType === 'Late check in' ? a.checkIn || '' : a.checkOut || '',
        requestDate: a.date || '',
        reason: a.reason || '-',
        location: a.location || '-',
        latitude: subType === 'Late check in' ? a.checkInLatitude ?? null : a.checkOutLatitude ?? null,
        longitude: subType === 'Late check in' ? a.checkInLongitude ?? null : a.checkOutLongitude ?? null,
        branchName: employeeBranchName,
        status: a.approvalStatus || 'Pending'
      };
    });

    // Wait for all attendance processing to complete
    const attendanceResults = await Promise.all(attendancePromises);
    
    // Filter out null results and add to output
    attendanceResults.forEach(result => {
      if (result) {
        out.push(result);
        console.log('Final attendance API response item:', result);
      }
    });

    // ---------- Leaves ----------
    const leaveSnap = await db.collection('leaves').get();

    // Process leave documents in parallel with employee data fetching
    const leavePromises = leaveSnap.docs.map(async (doc) => {
      console.log("Leave Doc ID:", doc.id);
      console.log("Leave companyId:", doc.data().companyId);
      console.log("Admin companyId:", companyId);

      const leave = doc.data();

      // Company isolation filter
      if (leave.companyId !== companyId) return null;

      // Status filtering for leaves
      const leaveStatus = normStr(leave.approvalStatus || leave.status || 'Pending').toLowerCase();
      if (wantStatus !== 'all' && leaveStatus !== wantStatus) return null;

      console.log("Matched Leave:", leave.name, leave.companyId);

      // Fetch employee data to get department, shift and location info
      let employeeDepartment = '';
      let employeeShift = '';
      let employeeShiftGroup = '';
      let employeeLocation = '';
      let branchName = '';

      try {
        const empSnap = await db
          .collection('employees')
          .where('companyId', '==', companyId)
          .where('empid', '==', leave.empid)
          .limit(1)
          .get();
        
        if (!empSnap.empty) {
          const empData = empSnap.docs[0].data();
          employeeDepartment = empData?.dept || '';
          employeeShift = empData?.shift || empData?.shiftGroup || '';
          employeeShiftGroup = empData?.shiftGroup || empData?.shift || '';
          employeeLocation = empData?.location || '';
          branchName = empData?.branchName || empData?.branchLocation || empData?.location || '';
          
          console.log('=== LEAVE ENRICHMENT DEBUG ===');
          console.log('Leave empid:', leave.empid);
          console.log('Matched employee document:', {
            empid: leave.empid,
            department: employeeDepartment,
            shift: employeeShift,
            shiftGroup: employeeShiftGroup,
            branchName: branchName,
            location: employeeLocation,
            rawEmployeeData: {
              dept: empData?.dept,
              shift: empData?.shift,
              shiftGroup: empData?.shiftGroup,
              branchName: empData?.branchName,
              branchLocation: empData?.branchLocation,
              location: empData?.location
            }
          });
          console.log('Resolved department:', employeeDepartment);
          console.log('Resolved shift:', employeeShift);
          console.log('Resolved branchName:', branchName);
        } else {
          console.log('=== LEAVE ENRICHMENT DEBUG ===');
          console.log('Leave empid:', leave.empid);
          console.log('No employee document found for empid:', leave.empid);
        }
      } catch (empError) {
        console.error('=== LEAVE ENRICHMENT DEBUG ===');
        console.log('Leave empid:', leave.empid);
        console.error('Error fetching employee data for empid', leave.empid, ':', empError);
      }

      // Extract request time from leave document
      let requestTime = '';
      if (leave.requestedAt) {
        const requestedDate = leave.requestedAt.toDate();
        requestTime = requestedDate.toTimeString().substring(0, 5); // HH:MM format
      }

      // Determine the correct type based on leave type
      let requestType = 'Leave Type';
      const leaveTypeRaw = leave.leaveType || leave.type || '';
      const lt = normStr(leaveTypeRaw).toLowerCase();
      
      if (lt.includes('permission')) {
        requestType = 'Permission';
      } else if (lt.includes('over') && lt.includes('time')) {
        requestType = 'Over Time';
      } else if (lt.includes('half') && lt.includes('day')) {
        requestType = 'Half Day Leave';
      } else if (lt.includes('comp') && lt.includes('off')) {
        requestType = 'Comp Off';
      }
      // Note: Late check in/out should come from attendance collection, not leaves collection

      console.log('Leave request type determination:', {
        leaveTypeRaw,
        normalized: lt,
        determinedType: requestType
      });

      return {
        source: 'leaves',
        requestId: doc.id,
        type: requestType,
        empid: leave.empid || '',
        name: leave.name || '',
        department: employeeDepartment,
        shift: employeeShift,
        shiftGroup: employeeShiftGroup,
        requestTime: requestTime,
        requestDate: leave.startDate || '',
        reason: leave.reason || '',
        location: employeeLocation || leave.location || '',
        latitude: null,
        longitude: null,
        branchName: branchName,
        status: leave.approvalStatus || leave.status || 'Pending'
      };
    });

    // Wait for all leave processing to complete
    const leaveResults = await Promise.all(leavePromises);
    
    // Filter out null results and add to output
    leaveResults.forEach(result => {
      if (result) {
        out.push(result);
        console.log('Final leave API response item:', result);
      }
    });

    // Count attendance vs leave items for debugging
    const attendanceCount = out.filter(item => item.source === 'attendance').length;
    const leaveCount = out.filter(item => item.source === 'leaves').length;
    
    console.log('=== BACKEND RESPONSE DEBUG ===');
    console.log('Total items returned:', out.length);
    console.log('Attendance items:', attendanceCount);
    console.log('Leave items:', leaveCount);
    console.log('Attendance sources:', out.filter(item => item.source === 'attendance').map(item => item.type));
    console.log('Leave sources:', out.filter(item => item.source === 'leaves').map(item => item.type));
    console.log('=== END BACKEND DEBUG ===');

    console.log('[approvals] final rows =', out);

    out.sort((a, b) =>
      `${b.requestDate || ''} ${b.requestTime || ''}`.localeCompare(
        `${a.requestDate || ''} ${a.requestTime || ''}`
      )
    );

    console.log("Final Approval Count:", out.length);
    console.log("Final Data:", out);

    return res.json(out);
  } catch (err: any) {
    console.error('listApprovalRequests error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** GET /api/attendance/my-requests */
export const listMyRequests = async (req: Request, res: Response) => {
  const companyId = getReqCompanyId(req);
  if (!companyId) {
    return res.status(403).json({ error: 'companyId missing in token' });
  }

  try {
    const empid = getReqEmpId(req);
    if (!empid) return res.status(401).json({ message: 'Unauthorized' });

    const statusQ = normStr(req.query.status || 'All');
    const wantStatus = statusQ.toLowerCase();
    const start = String(req.query.start || '').slice(0, 10);
    const end = String(req.query.end || '').slice(0, 10);
    const singleDay = !!(start && end && start === end);

    const shiftsSnap = await db.collection(SHIFT_COL).get();
    const shiftByGroup: Record<string, any> = {};
    shiftsSnap.forEach((d) => {
      const s = d.data();
      shiftByGroup[(s as any).shiftname] = s;
    });

    let emp: any = null;
    const eSnap = await db
      .collection(EMP_COL)
      .where('empid', '==', empid)
      .where('companyId', '==', companyId)
      .limit(1)
      .get();
    if (!eSnap.empty) emp = eSnap.docs[0].data();

    const out: any[] = [];

    let attRef: FirebaseFirestore.Query = db
      .collection(ATT_COL)
      .where('empid', '==', empid)
      .where('companyId', '==', companyId);
    if (start) attRef = attRef.where('date', '>=', start);
    if (end) attRef = attRef.where('date', '<=', end);

    const attSnap = await attRef.get();

    attSnap.forEach((doc) => {
      const a = doc.data() as any;

      const sNorm = normStr(a.approvalStatus || 'Pending').toLowerCase();
      if (wantStatus !== 'all' && sNorm !== wantStatus) return;
      if (singleDay && a.date !== start) return;

      const shift = shiftByGroup[emp?.shiftGroup] || {};
      const startTime = shift.startTime || '09:00';
      const endTime = shift.endTime || '18:00';

      let subType: string | null = null;
      
      // Fixed: Proper DateTime comparison for late check-in with grace period
      if (a.checkIn) {
        const graceMinutes = 5; // 5 minutes grace period
        const [startHour, startMinute] = startTime.split(':').map(Number);
        const [checkInHour, checkInMinute] = a.checkIn.split(':').map(Number);
        
        // Create DateTime objects for the attendance date
        const attendanceDate = new Date(a.date || Date.now());
        const shiftStartDateTime = new Date(attendanceDate.getFullYear(), attendanceDate.getMonth(), attendanceDate.getDate(), startHour, startMinute, 0);
        const shiftStartWithGrace = new Date(shiftStartDateTime.getTime() + graceMinutes * 60000);
        const checkInDateTime = new Date(attendanceDate.getFullYear(), attendanceDate.getMonth(), attendanceDate.getDate(), checkInHour, checkInMinute, 0);
        
        // Debug logging
        console.log('MY-REQUESTS LATE CHECK-IN DEBUG:', {
          empid: a.empid,
          shiftGroup: emp?.shiftGroup,
          shiftStartTime: startTime,
          checkInTime: a.checkIn,
          attendanceDate: a.date,
          graceMinutes,
          calculatedShiftStartDateTime: shiftStartDateTime.toISOString(),
          calculatedShiftStartWithGrace: shiftStartWithGrace.toISOString(),
          calculatedCheckInDateTime: checkInDateTime.toISOString(),
          isLateCheckIn: checkInDateTime > shiftStartWithGrace
        });
        
        // Only mark as late if check-in is after shift start + grace period
        if (checkInDateTime > shiftStartWithGrace) {
          subType = 'Late check in';
        }
      }
      
      if (a.checkOut && a.checkOut < endTime) subType = 'Early check out';
      
      if (!subType) return;

      out.push({
        source: 'attendance',
        requestId: doc.id,
        type: subType,
        empid: a.empid,
        name: a.name || emp?.name || '',
        requestDate: a.date || '',
        requestTime:
          subType === 'Late check in' ? a.checkIn || '' : a.checkOut || '',
        reason: a.reason || '-',
        location: a.location || '-',
        latitude:
          subType === 'Late check in'
            ? a.checkInLatitude ?? null
            : a.checkOutLatitude ?? null,
        longitude:
          subType === 'Late check in'
            ? a.checkInLongitude ?? null
            : a.checkOutLongitude ?? null,
        status: a.approvalStatus || 'Pending',
      });
    });

    const leaveSnap = await db
      .collection(LEAVE_COL)
      .where('empid', '==', empid)
      .where('companyId', '==', companyId)
      .get();

    leaveSnap.forEach((doc) => {
      const L = doc.data() as any;
      const sNorm = normStr(L.approvalStatus ?? L.status ?? 'Pending').toLowerCase();
      if (wantStatus !== 'all' && sNorm !== wantStatus) return;

      const dStart = toISO(L.startDate || L.date || L.selectDate);
      const dEnd = toISO(L.endDate || dStart);

      if (singleDay) {
        if (!(dStart && start >= dStart && start <= (dEnd || dStart))) return;
      } else {
        if (start && dEnd && dEnd < start) return;
        if (end && dStart && dStart > end) return;
      }

      const leaveTypeRaw = L.leaveType || L.type;
      let friendlyType = 'Leave Type';
      const lt = normStr(leaveTypeRaw).toLowerCase();
      if (lt.includes('permission')) friendlyType = 'Permission';
      else if (lt.includes('over') && lt.includes('time')) friendlyType = 'Over Time';
      else if (lt.includes('half') && lt.includes('day')) friendlyType = 'Half Day Leave';
      else if (lt.includes('comp') && lt.includes('off')) friendlyType = 'Comp Off';
      // Check if this is actually an attendance subtype (late check in/out)
      else if (lt.includes('late') || lt.includes('early')) {
        // Preserve the original attendance subtype
        if (lt.includes('late') && lt.includes('check') && lt.includes('in')) {
          friendlyType = 'Late check in';
        } else if (lt.includes('early') && lt.includes('check') && lt.includes('out')) {
          friendlyType = 'Early check out';
        }
      }

      out.push({
        source: 'leaves',
        requestId: doc.id,
        type: friendlyType,
        empid: L.empid,
        name: L.name || '',
        requestDate: dStart || '',
        requestTime: L.time || '',
        reason: L.reason || '-',
        location: L.location || '-',
        latitude: L.latitude || null,
        longitude: L.longitude || null,
        status: L.approvalStatus ?? L.status ?? 'Pending',
      });
    });

    out.sort((a, b) =>
      String(b.requestDate || '').localeCompare(String(a.requestDate || ''))
    );

    return res.json(out);
  } catch (err: any) {
    console.error('listMyRequests error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** GET /api/attendance/request-details?id=DOC_ID&src=attendance|leaves|otherLocation */
export const getRequestDetails = async (req: Request, res: Response) => {
  const companyId = getReqCompanyId(req);
  if (!companyId) {
    return res.status(403).json({ error: 'companyId missing in token' });
  }

  try {
    const id = String(req.query.id || '').trim();
    const src = String(req.query.src || '').trim();

    if (!id) {
      return res.status(400).json({ error: 'id is required' });
    }

    if (!src) {
      return res.status(400).json({ error: 'src is required' });
    }

    let collectionName = '';

    if (src === 'attendance') {
      collectionName = ATT_COL;
    } else if (src === 'leaves') {
      collectionName = LEAVE_COL;
    } else if (src === 'otherLocation') {
      collectionName = OTHER_LOC_COL;
    } else {
      return res.status(400).json({ error: 'Invalid src value' });
    }

    const docSnap = await db.collection(collectionName).doc(id).get();

    if (!docSnap.exists) {
      return res.status(404).json({ error: 'Request not found' });
    }

    const data = docSnap.data();

    if (data?.companyId !== companyId) {
      return res.status(403).json({ error: 'Access denied: companyId mismatch' });
    }

    return res.json({
      source: src,
      requestId: docSnap.id,
      ...data,
    });
  } catch (err: any) {
    console.error('getRequestDetails error:', err);
    return res.status(500).json({ error: err.message });
  }
};

export const getMonthlySummary = async (req: Request, res: Response) => {
  console.log("[ MONTHLY] params:", req.params);
  console.log("[MONTHLY] user:", req.user);

  const companyId = req.user?.companyId;

  if (!companyId) {
    return res.status(401).json({
      error: "Unauthorized: companyId missing",
    });
  }

  const { empid, year, month } = req.params as any;

  if (!empid || !year || !month) {
    return res.status(400).json({
      error: "empid, year and month required",
    });
  }

  const yearNumber = Number(year);
  const monthNumber = Number(month);

  if (
    Number.isNaN(yearNumber) ||
    Number.isNaN(monthNumber) ||
    monthNumber < 1 ||
    monthNumber > 12
  ) {
    return res.status(400).json({
      error: "Invalid year or month",
    });
  }

  const safeMonth = String(monthNumber).padStart(2, "0");
  const lastDayOfMonth = new Date(yearNumber, monthNumber, 0).getDate();

  const startDate = `${yearNumber}-${safeMonth}-01`;
  const endDate = `${yearNumber}-${safeMonth}-${String(lastDayOfMonth).padStart(
    2,
    "0"
  )}`;

  const today = new Date();
  const todayYear = today.getFullYear();
  const todayMonth = today.getMonth() + 1;
  const todayDate = today.getDate();

  let absentGenerationEndDate = endDate;

  if (yearNumber === todayYear && monthNumber === todayMonth) {
    absentGenerationEndDate = `${yearNumber}-${safeMonth}-${String(
      todayDate
    ).padStart(2, "0")}`;
  }

  if (
    yearNumber > todayYear ||
    (yearNumber === todayYear && monthNumber > todayMonth)
  ) {
    absentGenerationEndDate = "";
  }

  console.log("[MONTHLY] date range:", startDate, endDate);

  const normalizeTime = (time?: string | null): string | null => {
    if (!time || typeof time !== "string") {
      return null;
    }

    const trimmedTime = time.trim();

    if (
      trimmedTime === "" ||
      trimmedTime === "-" ||
      trimmedTime.toLowerCase() === "null"
    ) {
      return null;
    }

    const parts = trimmedTime.split(":");

    if (parts.length < 2) {
      return null;
    }

    const hour = parts[0].padStart(2, "0");
    const minute = parts[1].padStart(2, "0");

    return `${hour}:${minute}`;
  };

  const buildDateTime = (date: string, time: string): Date | null => {
    if (!date || !time) {
      return null;
    }

    const dateTime = new Date(`${date}T${time}:00`);

    if (Number.isNaN(dateTime.getTime())) {
      return null;
    }

    return dateTime;
  };

  const getNormalizedString = (value: any): string => {
    return value?.toString().toLowerCase().trim() || "";
  };

  const isPermissionLeaveType = (leaveType: any): boolean => {
    const normalizedLeaveType = getNormalizedString(leaveType);

    return (
      normalizedLeaveType === "permission" ||
      normalizedLeaveType === "permission time" ||
      normalizedLeaveType.includes("permission")
    );
  };

  try {
    const attendanceSnap = await db
      .collection("attendance")
      .where("companyId", "==", companyId)
      .where("empid", "==", empid)
      .where("date", ">=", startDate)
      .where("date", "<=", endDate)
      .get();

    const leavesSnap = await db
      .collection("leaves")
      .where("companyId", "==", companyId)
      .where("empid", "==", empid)
      .where("startDate", ">=", startDate)
      .where("startDate", "<=", endDate)
      .get();

    // ✅ Fetch employee shift group and matching shift timing
    let employeeShiftGroup = "";
    let employeeShiftStartTime: string | null = null;
    let employeeShiftEndTime: string | null = null;

    const employeeSnap = await db
      .collection("employees")
      .where("companyId", "==", companyId)
      .where("empid", "==", empid)
      .limit(1)
      .get();

    if (!employeeSnap.empty) {
      const employeeData = employeeSnap.docs[0].data() as any;

      employeeShiftGroup = (
        employeeData.shiftGroup ||
        employeeData.shiftName ||
        employeeData.shiftname ||
        ""
      )
        .toString()
        .trim();

      console.log(
        `[MONTHLY SHIFT] Employee: ${empid}, ShiftGroup: ${employeeShiftGroup}`
      );
    } else {
      console.log(
        `[MONTHLY SHIFT] No employee found for empid: ${empid}, companyId: ${companyId}`
      );
    }

    if (employeeShiftGroup) {
      let shiftSnap = await db
        .collection("shifts")
        .where("companyId", "==", companyId)
        .where("name", "==", employeeShiftGroup)
        .limit(1)
        .get();

      if (shiftSnap.empty) {
        shiftSnap = await db
          .collection("shifts")
          .where("companyId", "==", companyId)
          .where("shiftname", "==", employeeShiftGroup)
          .limit(1)
          .get();
      }

      if (!shiftSnap.empty) {
        const shiftData = shiftSnap.docs[0].data() as any;

        employeeShiftStartTime = normalizeTime(
          shiftData.startTime ||
            shiftData.shiftStartTime ||
            shiftData.workStartTime
        );

        employeeShiftEndTime = normalizeTime(
          shiftData.endTime ||
            shiftData.shiftEndTime ||
            shiftData.workEndTime
        );

        console.log(
          `[MONTHLY SHIFT] Matched shift: ${employeeShiftGroup}, Start: ${employeeShiftStartTime}, End: ${employeeShiftEndTime}`
        );
      } else {
        console.log(
          `[MONTHLY SHIFT] No matching shift found for ${employeeShiftGroup}, using fallback time`
        );
      }
    }

    const approvedPermissionByDate: Record<string, number> = {};
    const permissionLeaveDetailsByDate: Record<string, any[]> = {};
    const approvedLeaveByDate: Record<string, any[]> = {};

    leavesSnap.docs.forEach((leaveDoc) => {
      const leave = leaveDoc.data() as any;

      const leaveStartDate = leave.startDate;
      const leaveEndDate = leave.endDate || leave.startDate;
      const leaveType = leave.leaveType;
      const approvalStatus = getNormalizedString(leave.approvalStatus);
      const status = getNormalizedString(leave.status);

      const isApproved =
        approvalStatus === "approved" || status === "approved";

      const isPermission = isPermissionLeaveType(leaveType);
      const isRegularLeave = !isPermission && isApproved;

      if (leaveStartDate && isPermission && isApproved) {
        const duration =
          typeof leave.duration === "number" && leave.duration > 0
            ? leave.duration
            : 1;

        approvedPermissionByDate[leaveStartDate] =
          (approvedPermissionByDate[leaveStartDate] || 0) + duration;

        if (!permissionLeaveDetailsByDate[leaveStartDate]) {
          permissionLeaveDetailsByDate[leaveStartDate] = [];
        }

        permissionLeaveDetailsByDate[leaveStartDate].push({
          id: leaveDoc.id,
          leaveType: leave.leaveType,
          approvalStatus: leave.approvalStatus,
          duration,
          startDate: leave.startDate,
          endDate: leave.endDate,
          reason: leave.reason || null,
        });

        console.log(
          `[MONTHLY PERMISSION] Employee: ${empid}, Date: ${leaveStartDate}, LeaveType: ${leave.leaveType}, ApprovalStatus: ${leave.approvalStatus}, Duration: ${duration}`
        );
      }

      if (isRegularLeave) {
        const start = new Date(leaveStartDate);
        const end = new Date(leaveEndDate);

        for (
          let date = new Date(start);
          date <= end;
          date.setDate(date.getDate() + 1)
        ) {
          const dateStr = date.toISOString().split("T")[0];

          if (!approvedLeaveByDate[dateStr]) {
            approvedLeaveByDate[dateStr] = [];
          }

          approvedLeaveByDate[dateStr].push({
            id: leaveDoc.id,
            leaveType: leave.leaveType,
            approvalStatus: leave.approvalStatus,
            duration: 1,
            startDate: leave.startDate,
            endDate: leave.endDate,
            reason: leave.reason || null,
          });

          console.log(
            `[MONTHLY LEAVE] Employee: ${empid}, Date: ${dateStr}, LeaveType: ${leave.leaveType}, ApprovalStatus: ${leave.approvalStatus}`
          );
        }
      }
    });

    const attendanceDates = new Set<string>();

    const data = attendanceSnap.docs.map((doc) => {
      const attendanceDoc = doc.data() as any;

      let isLate = false;
      let isEarly = false;

      const date = attendanceDoc.date;
      attendanceDates.add(date);

      const checkIn = normalizeTime(attendanceDoc.checkIn);
      const checkOut = normalizeTime(attendanceDoc.checkOut);

      // ✅ Updated shift timing logic:
      // 1. Use shift time saved in attendance document if available.
      // 2. If missing, use employee's assigned shift from shifts collection.
      // 3. Only then use fallback 09:00 / 18:00.
      const shiftStart =
        normalizeTime(
          attendanceDoc.shiftStartTime ||
            attendanceDoc.shiftGroup?.startTime ||
            attendanceDoc.shift?.startTime
        ) ||
        employeeShiftStartTime ||
        "09:00";

      const shiftEnd =
        normalizeTime(
          attendanceDoc.shiftEndTime ||
            attendanceDoc.shiftGroup?.endTime ||
            attendanceDoc.shift?.endTime
        ) ||
        employeeShiftEndTime ||
        "18:00";

      if (date && checkIn && shiftStart) {
        const checkInTime = buildDateTime(date, checkIn);
        const shiftStartTime = buildDateTime(date, shiftStart);

        if (checkInTime && shiftStartTime) {
          const gracePeriod = 5 * 60 * 1000;

          isLate =
            checkInTime.getTime() > shiftStartTime.getTime() + gracePeriod;
        }
      }

      if (date && checkOut && shiftEnd) {
        const checkOutTime = buildDateTime(date, checkOut);
        const shiftEndTime = buildDateTime(date, shiftEnd);

        if (checkOutTime && shiftEndTime) {
          isEarly = checkOutTime.getTime() < shiftEndTime.getTime();
        }
      }

      const permissionCount = approvedPermissionByDate[date] || 0;
      const isPermission = permissionCount > 0;

      const leaveDetails = approvedLeaveByDate[date] || [];
      const isLeave = leaveDetails.length > 0;
      const leaveCount = leaveDetails.length;

      const isAbsent =
        !isPermission && !isLeave && (!checkIn || checkIn === "null");

      return {
        id: doc.id,
        ...attendanceDoc,
        shiftStartTime: shiftStart,
        shiftEndTime: shiftEnd,
        isLate,
        isEarly,
        isAbsent,
        isLeave,
        isPermission,
        permissionCount,
        leaveCount,
        leaveType: isLeave ? leaveDetails[0]?.leaveType : null,
        permissionLeaves: permissionLeaveDetailsByDate[date] || [],
        leaveDetails: leaveDetails,
      };
    });

    Object.keys(approvedPermissionByDate).forEach((permissionDate) => {
      if (!attendanceDates.has(permissionDate)) {
        data.push({
          id: `permission-${empid}-${permissionDate}`,
          empid,
          companyId,
          date: permissionDate,
          status: "Permission",
          attendanceStatus: "Permission",
          checkIn: null,
          checkOut: null,
          shiftStartTime: employeeShiftStartTime || "09:00",
          shiftEndTime: employeeShiftEndTime || "18:00",
          isLate: false,
          isEarly: false,
          isAbsent: false,
          isLeave: false,
          isPermission: true,
          permissionCount: approvedPermissionByDate[permissionDate],
          leaveCount: 0,
          leaveType: null,
          permissionLeaves: permissionLeaveDetailsByDate[permissionDate] || [],
          leaveDetails: [],
        });

        console.log(
          `[MONTHLY PERMISSION ONLY] Employee: ${empid}, Date: ${permissionDate}, PermissionCount: ${approvedPermissionByDate[permissionDate]}`
        );
      }
    });

    Object.keys(approvedLeaveByDate).forEach((leaveDate) => {
      if (
        !attendanceDates.has(leaveDate) &&
        !approvedPermissionByDate[leaveDate]
      ) {
        const leaveDetails = approvedLeaveByDate[leaveDate];

        data.push({
          id: `leave-${empid}-${leaveDate}`,
          empid,
          companyId,
          date: leaveDate,
          status: "Leave",
          attendanceStatus: "Leave",
          checkIn: null,
          checkOut: null,
          shiftStartTime: employeeShiftStartTime || "09:00",
          shiftEndTime: employeeShiftEndTime || "18:00",
          isLate: false,
          isEarly: false,
          isAbsent: false,
          isLeave: true,
          isPermission: false,
          permissionCount: 0,
          leaveCount: leaveDetails.length,
          leaveType: leaveDetails[0]?.leaveType || "Leave",
          permissionLeaves: [],
          leaveDetails: leaveDetails,
        });

        console.log(
          `[MONTHLY LEAVE ONLY] Employee: ${empid}, Date: ${leaveDate}, LeaveType: ${leaveDetails[0]?.leaveType}, LeaveCount: ${leaveDetails.length}`
        );
      }
    });

    const generateWorkingDays = (start: string, end: string): string[] => {
      const workingDays: string[] = [];
      const startDate = new Date(start);
      const endDate = new Date(end);

      for (
        let date = new Date(startDate);
        date <= endDate;
        date.setDate(date.getDate() + 1)
      ) {
        const dayOfWeek = date.getDay();

        if (dayOfWeek !== 0) {
          workingDays.push(date.toISOString().split("T")[0]);
        }
      }

      return workingDays;
    };

    const allWorkingDays = absentGenerationEndDate
      ? generateWorkingDays(startDate, absentGenerationEndDate)
      : [];

    const totalWorkingDays = allWorkingDays.length;

    allWorkingDays.forEach((workingDate) => {
      if (
        !attendanceDates.has(workingDate) &&
        !approvedLeaveByDate[workingDate] &&
        !approvedPermissionByDate[workingDate]
      ) {
        data.push({
          id: `absent-${empid}-${workingDate}`,
          empid,
          companyId,
          date: workingDate,
          status: "Absent",
          attendanceStatus: "Absent",
          checkIn: null,
          checkOut: null,
          shiftStartTime: employeeShiftStartTime || "09:00",
          shiftEndTime: employeeShiftEndTime || "18:00",
          isLate: false,
          isEarly: false,
          isAbsent: true,
          isLeave: false,
          isPermission: false,
          permissionCount: 0,
          leaveCount: 0,
          leaveType: null,
          permissionLeaves: [],
          leaveDetails: [],
        });

        console.log(
          `[MONTHLY ABSENT] Employee: ${empid}, Date: ${workingDate}, Status: Absent`
        );
      }
    });

    data.sort((a: any, b: any) => {
      return a.date.localeCompare(b.date);
    });

    const lateDates = new Set<string>();
    const earlyDates = new Set<string>();

    data.forEach((item: any) => {
      if (item.isLate && item.date) {
        lateDates.add(item.date);
      }

      if (item.isEarly && item.date) {
        earlyDates.add(item.date);
      }
    });

    const totalLate = lateDates.size;
    const totalEarly = earlyDates.size;

    const totalPermission = data.reduce(
      (total: number, item: any) => total + (item.permissionCount || 0),
      0
    );

    const totalLeave = data.filter((item: any) => item.isLeave).length;
    const totalAbsent = data.filter((item: any) => item.isAbsent).length;
    const totalPresent = data.filter(
      (item: any) => !item.isAbsent && !item.isLeave && !item.isPermission
    ).length;

    console.log(
      `[MONTHLY] Employee: ${empid}, Total Working Days: ${totalWorkingDays}, Records: ${data.length}, Present: ${totalPresent}, Absent: ${totalAbsent}, Leave: ${totalLeave}, Late: ${totalLate}, Early: ${totalEarly}, Permission: ${totalPermission}`
    );

    return res.status(200).json(data);
  } catch (error: any) {
    console.error("[MONTHLY] ERROR:", error);

    return res.status(500).json({
      error: "Failed to fetch monthly attendance",
      message: error?.message || "Unknown error",
    });
  }
};