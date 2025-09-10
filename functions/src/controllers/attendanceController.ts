import { Request, Response } from 'express';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/* ============================== Helpers ============================== */

const EMP_COL   = 'employees';
const ATT_COL   = 'attendance';
const LEAVE_COL = 'leaves';
const SHIFT_COL = 'shifts';

function pad2(n: number | string) { return String(n).padStart(2, '0'); }

function toYMD(d: Date = new Date()): string {
  // IST helper (kept from your Node version)
  const ist = new Date(d.getTime() + 5.5 * 60 * 60 * 1000);
  return ist.toISOString().slice(0, 10);
}

function daysInMonth(year: number, month: number) { // month: 1..12
  return new Date(year, month, 0).getDate();
}

function isSunday(ymd: string) { return new Date(ymd).getDay() === 0; }

function cmpHHMM(a?: string, b?: string) {
  return (a || '00:00') > (b || '00:00');
}

function midpointHHMM(start?: string, end?: string) {
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

// Maintain a project-level holiday set if you have one; placeholder here.
const HOLIDAYS_SET = new Set<string>([]);

/* ============================== Normalizers (Approvals) ============================== */

const norm = (s: any) => String(s || '').trim().toLowerCase();

const normalizeType = (s: any) => {
  const t = norm(s).replace(/\s+/g, ' ');
  if (!t || t === 'all' || t === 'type') return 'all';

  // attendance buckets
  if (t.includes('late')  && t.includes('check') && t.includes('in'))  return 'late check in';
  if (t.includes('early') && t.includes('check') && t.includes('out')) return 'early check out';
  if (t.includes('late')  && t.includes('check') && t.includes('out')) return 'late check out';

  // leave buckets
  if (t.includes('permission'))                 return 'permission';
  if (t.includes('over') && t.includes('time')) return 'over time';
  if (t.includes('half') && t.includes('day'))  return 'half day leave';
  if (t.includes('comp') && t.includes('off'))  return 'comp off';
  if (t.includes('leave'))                      return 'leave type';

  return t;
};

const mapLeaveType = (txt: any) => {
  const t = norm(txt);
  if (t.includes('permission')) return 'Permission';
  if (t.includes('over') && t.includes('time')) return 'Over Time';
  if (t.includes('half') && t.includes('day'))  return 'Half Day Leave';
  if (t.includes('comp') && t.includes('off'))  return 'Comp Off';
  return 'Leave Type';
};

const overlaps = (aStart?: string | null, aEnd?: string | null, bStart?: string | null, bEnd?: string | null) => {
  if (!aStart && !aEnd) return true;
  const A1 = aStart || '0000-01-01';
  const A2 = aEnd   || '9999-12-31';
  const B1 = bStart || bEnd || '';
  const B2 = bEnd   || bStart || '';
  if (!B1) return true;
  return (B1 <= A2) && (B2 >= A1);
};

/* ============================== Core attendance (string-time model) ============================== */

/** Get current user (from req.user) */
export const getCurrentUser = async (req: Request, res: Response) => {
  try {
    const empid = (req as any).user?.empid;
    const snap = await db.collection(EMP_COL).where('empid', '==', empid).limit(1).get();
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

/** POST /api/attendance/check-in (string HH:mm:ss) */
export const checkIn = async (req: Request, res: Response) => {
  const { empid, name, location } = req.body as { empid: string; name: string; location: string };
  if (!empid || !name || !location) {
    return res.status(400).json({ error: 'empid, name and location are required' });
  }
  const today = new Date().toISOString().slice(0, 10);

  try {
    const snap = await db.collection(ATT_COL)
      .where('empid', '==', empid)
      .where('date', '==', today)
      .get();

    const nowTime = new Date().toLocaleTimeString('en-GB'); // HH:mm:ss

    if (!snap.empty) {
      const doc = snap.docs[0];
      if (doc.data().checkIn) {
        return res.status(400).json({ error: 'Already checked in today' });
      }
      await doc.ref.update({
        checkIn:        nowTime,
        location,
        status:         'Present',
        approvalStatus: 'Pending',
        updatedAt:      admin.firestore.FieldValue.serverTimestamp(),
      });
      return res.json({ message: 'Check-in updated' });
    }

    await db.collection(ATT_COL).add({
      empid,
      name,
      date:           today,
      checkIn:        nowTime,
      location,
      status:         'Present',
      approvalStatus: 'Pending',
      createdAt:      admin.firestore.FieldValue.serverTimestamp(),
      updatedAt:      admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.json({ message: 'Checked-in successfully' });
  } catch (err: any) {
    console.error('checkIn error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** POST /api/attendance/check-out (string HH:mm:ss) */
export const checkOut = async (req: Request, res: Response) => {
  const { empid, location } = req.body as { empid: string; location: string };
  if (!empid || !location) {
    return res.status(400).json({ error: 'empid and location are required' });
  }
  const today = new Date().toISOString().slice(0, 10);

  try {
    const snap = await db.collection(ATT_COL)
      .where('empid', '==', empid)
      .where('date', '==', today)
      .get();

    if (snap.empty) {
      return res.status(400).json({ error: 'You need to check in first' });
    }

    const doc = snap.docs[0];
    if (doc.data().checkOut) {
      return res.status(400).json({ error: 'Already checked out today' });
    }

    await doc.ref.update({
      checkOut:  new Date().toLocaleTimeString('en-GB'),
      location,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // mark employee inactive on checkout
    const empSnap = await db.collection(EMP_COL).where('empid', '==', empid).limit(1).get();
    if (!empSnap.empty) {
      await empSnap.docs[0].ref.update({
        status:    'inactive',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return res.json({ message: 'Checked-out & set inactive' });
  } catch (err: any) {
    console.error('checkOut error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** GET /api/attendance/live */
export const getLiveAttendance = async (req: Request, res: Response) => {
  const today = new Date().toISOString().slice(0, 10);
  const isAdmin = (req as any).user?.role === 'admin';

  try {
    // a) employees
    let employees: any[] = [];
    if (isAdmin) {
      const empSnap = await db.collection(EMP_COL).get();
      employees = empSnap.docs.map(d => d.data());
    } else {
      const empSnap = await db.collection(EMP_COL)
        .where('empid', '==', (req as any).user?.empid)
        .limit(1).get();
      if (empSnap.empty) return res.json([]);
      employees = [empSnap.docs[0].data()];
    }

    // b) today's attendance
    const attSnap = await db.collection(ATT_COL).where('date', '==', today).get();
    const attMap: Record<string, any> = Object.fromEntries(attSnap.docs.map(d => [d.data().empid, d.data()]));

    // c) approved leaves overlapping today
    const leaveSnap = await db.collection(LEAVE_COL)
      .where('approvalStatus', '==', 'Approved')
      .where('startDate', '<=', today)
      .get();
    const validLeaves = leaveSnap.docs
      .map(d => d.data())
      .filter(l => (toISO(l.endDate) || toISO(l.startDate)) >= today)
      .map(l => l.empid);
    const leaveSet = new Set(validLeaves);

    // d) shifts
    const shiftsSnap = await db.collection(SHIFT_COL).get();
    const shiftByGroup: Record<string, any> =
      Object.fromEntries(shiftsSnap.docs.map(d => [d.data().group, d.data()]));

    // e) holiday/weekoff
    const isHoliday = HOLIDAYS_SET.has(today);
    const isWeekOff = isSunday(today);

    const result = employees.map(emp => {
      const rec = attMap[emp.empid];
      let status: string;
      let isLate = false, isEarly = false;

      let permissionCount = Array.isArray(rec?.permissionRequests)
        ? rec.permissionRequests.length
        : (rec?.permissionRequest ? 1 : 0);

      if (isHoliday) status = 'Holiday';
      else if (isWeekOff) status = 'WeekOff';
      else if (leaveSet.has(emp.empid)) status = 'Leave';
      else if (rec?.checkIn) {
        status = 'Present';
        const shift = shiftByGroup[emp.shiftGroup] || {};
        const start = shift.startTime || '09:00';
        const end   = shift.endTime   || '18:00';
        isLate  = rec.checkIn  > start;
        isEarly = rec.checkOut && rec.checkOut < end;
      } else {
        status = 'Absent';
      }

      // half-day heuristic
      let isHalfDay = false;
      if (status === 'Present' && shiftByGroup[emp.shiftGroup]) {
        const [h1, m1] = (shiftByGroup[emp.shiftGroup].startTime || '09:00').split(':').map(Number);
        const [h2, m2] = (shiftByGroup[emp.shiftGroup].endTime   || '18:00').split(':').map(Number);
        const midSec = ((h1 * 3600 + m1 * 60) + (h2 * 3600 + m2 * 60)) / 2;
        const inSec = rec && rec.checkIn
          ? rec.checkIn.split(':').reduce((a: number, v: string, i: number) => a + (+v) * (i === 0 ? 3600 : 60), 0)
          : 0;
        isHalfDay = inSec > midSec;
      }

      return {
        empid:          emp.empid,
        name:           emp.name,
        shiftGroup:     emp.shiftGroup,
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
      };
    });

    return res.json(result);
  } catch (err: any) {
    console.error('getLiveAttendance error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** GET /api/attendance/employee/:empid */
export const getEmployeeAttendance = async (req: Request, res: Response) => {
  const { empid } = req.params;
  try {
    const snap = await db.collection(ATT_COL)
      .where('empid', '==', empid)
      .orderBy('date', 'desc').get();
    const records = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    return res.json(records);
  } catch (err: any) {
    console.error('getEmployeeAttendance error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** Admin: list all attendance records */
export const getAllAttendance = async (_req: Request, res: Response) => {
  try {
    const snap = await db.collection(ATT_COL).get();
    const records = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    return res.json(records);
  } catch (err: any) {
    console.error('getAllAttendance error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** Admin: approve/reject an attendance row by document id */
export const approveAttendance = async (req: Request, res: Response) => {
  const { id, status } = req.body as { id: string; status: 'Approved' | 'Rejected' | string };
  try {
    await db.collection(ATT_COL).doc(id).update({
      approvalStatus: status,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return res.json({ message: `Attendance ${String(status).toLowerCase()} successfully` });
  } catch (err: any) {
    console.error('approveAttendance error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** GET /api/attendance/monthly/:empid/:year/:month */
export const getMonthlySummary = async (req: Request, res: Response) => {
  const { empid, year, month } = req.params as any;
  try {
    const snap = await db.collection(ATT_COL)
      .where('empid', '==', empid)
      .where('date', '>=', `${year}-${month}-01`)
      .where('date', '<=', `${year}-${month}-31`)
      .get();
    const records = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    return res.json(records);
  } catch (err: any) {
    console.error('getMonthlySummary error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** GET /api/attendance/roster?date=YYYY-MM-DD */
export const getDailyRoster = async (req: Request, res: Response) => {
  const date = String(req.query.date || '');
  if (!date) return res.status(400).json({ error: 'Missing ?date=YYYY-MM-DD' });

  try {
    const empSnap = await db.collection(EMP_COL).get();
    const employees = empSnap.docs.map(d => d.data());

    const attSnap = await db.collection(ATT_COL).where('date', '==', date).get();
    const attByEmp: Record<string, any> = Object.fromEntries(attSnap.docs.map(d => [d.data().empid, d.data()]));

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
  try {
    const start = String(req.query.start || '').slice(0, 10);
    const end   = String(req.query.end   || '').slice(0, 10);
    if (!start || !end || new Date(end) < new Date(start)) {
      return res.status(400).json({ error: 'Provide ?start=YYYY-MM-DD&end=YYYY-MM-DD' });
    }

    const empSnap = await db.collection(EMP_COL).get();
    const employees = empSnap.docs.map(d => d.data());

    const activeEmployees = employees.filter((e: any) =>
      String(e.status || '').toLowerCase() === 'active'
    ).length;

    const shiftsSnap = await db.collection(SHIFT_COL).get();
    const shiftByGroup: Record<string, any> =
      Object.fromEntries(shiftsSnap.docs.map(d => [d.data().group, d.data()]));

    const attSnap = await db.collection(ATT_COL)
      .where('date', '>=', start).where('date', '<=', end).get();
    const attByEmpDate: Record<string, any> = {};
    attSnap.forEach(doc => { const a = doc.data(); attByEmpDate[`${a.empid}|${a.date}`] = { id: doc.id, ...a }; });

    const leavesSnap = await db.collection(LEAVE_COL).get();
    const approvedLeaves = leavesSnap.docs
      .map(d => d.data())
      .filter((L: any) => String(L.approvalStatus ?? L.status ?? 'Pending').toLowerCase() === 'approved')
      .map((L: any) => ({
        empid: L.empid,
        type: String(L.type || ''),
        start: toISO(L.startDate || L.selectDate || L.date),
        end:   toISO(L.endDate   || L.selectDate || L.date || L.startDate),
      }));

    const leaveDays = new Set<string>();
    let onLeaveCount = 0;
    for (const L of approvedLeaves) {
      if (!L.start) continue;
      const s = L.start, e = L.end || L.start;
      if (e < start || s > end) continue;
      for (const d of eachYMD((s < start ? start : s), (e > end ? end : e))) {
        leaveDays.add(`${L.empid}|${d}`); onLeaveCount++;
      }
    }

    let checkedIn = 0, absent = 0, lateIn = 0, earlyOut = 0, halfDay = 0, presentApproved = 0, holiday = 0, weekOff = 0;
    const rows: any[] = [];
    const dates = eachYMD(start, end);

    for (const ymd of dates) {
      const isHoliday = HOLIDAYS_SET.has(ymd);
      const isWO = isSunday(ymd);
      if (isHoliday) holiday++;
      if (isWO) weekOff++;

      for (const emp of employees) {
        const key   = `${emp.empid}|${ymd}`;
        const att   = attByEmpDate[key] || null;
        const shift = shiftByGroup[emp.shiftGroup] || { startTime: '09:00', endTime: '18:00' };
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
          status = approvedLeaves.find(l =>
            l.empid === emp.empid && l.start <= ymd && ymd <= (l.end || l.start) && l.type.toLowerCase().includes('half')
          ) ? 'Half Day' : 'On Leave';
          if (status === 'Half Day') halfDay++;
        } else if (att?.checkIn) {
          checkedIn++;
          status = 'Present';
          if (cmpHHMM(att.checkIn, startT)) { isLate = true; lateIn++; }
          if (att.checkOut && !cmpHHMM(att.checkOut, endT)) { isEarly = true; earlyOut++; }
          if (cmpHHMM(att.checkIn, mid)) { status = 'Half Day'; halfDay++; }
          if (String(att.approvalStatus || '').toLowerCase() === 'approved') presentApproved++;
        } else {
          absent++;
        }

        rows.push({
          employeeId:  emp.empid,
          employeeName: emp.name || '',
          shift:       emp.shift || emp.shiftGroup || '',
          date:        ymd,
          checkIn:     att?.checkIn || '-',
          checkOut:    att?.checkOut || '-',
          department:  emp.dept || emp.department || '',
          attendance:  status,
          workedHours: att?.workedHours ? String(att.workedHours) : '-',
          late:        isLate,
          early:       isEarly,
          approval:    att?.approvalStatus || 'Pending',
        });
      }
    }

    return res.json({
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
    });
  } catch (err: any) {
    console.error('getRangeSummary error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** GET /api/attendance/month-view/:empid/:year/:month */
export const getMonthView = async (req: Request, res: Response) => {
  try {
    const { empid, year, month } = req.params as any;
    const y = parseInt(year, 10);
    const m = parseInt(month, 10);
    if (!empid || !y || !m) return res.status(400).json({ error: 'Bad params' });

    const first = `${year}-${month}-01`;
    const last  = `${year}-${month}-${pad2(daysInMonth(y, m))}`;

    const empSnap = await db.collection(EMP_COL).where('empid', '==', empid).limit(1).get();
    if (empSnap.empty) return res.status(404).json({ error: 'Employee not found' });
    const emp = empSnap.docs[0].data();

    const shiftSnap = await db.collection(SHIFT_COL).where('group', '==', emp.shiftGroup).limit(1).get();
    const shift = shiftSnap.empty ? {} : shiftSnap.docs[0].data();
    const shiftStart = shift.startTime || '09:00';
    const shiftEnd   = shift.endTime   || '18:00';
    const mid        = midpointHHMM(shiftStart, shiftEnd);

    const attSnap = await db.collection(ATT_COL)
      .where('empid', '==', empid)
      .where('date', '>=', first)
      .where('date', '<=', last)
      .get();
    const attByDate: Record<string, any> = Object.fromEntries(attSnap.docs.map(d => [d.data().date, d.data()]));

    const leavesSnap = await db.collection(LEAVE_COL).where('empid', '==', empid).get();

    const rangeLeaves: Array<{ start: string; end: string; isHalf: boolean }> = [];
    let permissionCount = 0;

    leavesSnap.forEach(doc => {
      const l = doc.data();
      const type = String(l.type || '').toLowerCase();
      const sdStr = toISO(l.startDate || l.selectDate || l.date);
      const edStr = toISO(l.endDate   || l.selectDate || l.date || l.startDate);

      if (type.includes('permission')) {
        if ((sdStr && sdStr >= first && sdStr <= last) ||
            (edStr && edStr >= first && edStr <= last)) {
          permissionCount += 1;
        }
        return;
      }
      if (!sdStr) return;

      const start = sdStr;
      const end   = edStr || sdStr;
      if (end < first || start > last) return;

      rangeLeaves.push({ start, end, isHalf: type.includes('half') });
    });

    const holidaySet = new Set<string>(HOLIDAYS_SET);

    const dayStatuses: Record<string, string> = {};
    let present = 0, absent = 0, leave = 0, holiday = 0, weekOff = 0, halfDay = 0, late = 0, early = 0;

    const today = toYMD(new Date());
    const stopAt = (year === today.slice(0, 4) && month === today.slice(5, 7)) ? today : last;

    for (let d = 1; d <= daysInMonth(y, m); d++) {
      const ymd = `${year}-${month}-${pad2(d)}`;
      if (ymd > stopAt) continue;

      let status: string;

      if (holidaySet.has(ymd)) {
        status = 'Holiday'; holiday++;
      } else if (isSunday(ymd)) {
        status = 'WeekOff'; weekOff++;
      } else {
        const lv = rangeLeaves.find(L => L.start <= ymd && ymd <= L.end);
        if (lv) {
          if (lv.isHalf) { status = 'HalfDay'; halfDay++; }
          else           { status = 'Leave';   leave++;   }
        } else {
          const rec = attByDate[ymd];
          if (rec && rec.checkIn) {
            status = 'Present'; present++;
            if (cmpHHMM(rec.checkIn, shiftStart)) late++;
            if (rec.checkOut && !cmpHHMM(rec.checkOut, shiftEnd)) early++;
            if (cmpHHMM(rec.checkIn, mid)) {
              status = 'HalfDay';
              halfDay++;
              present--;
            }
          } else {
            status = 'Absent'; absent++;
          }
        }
      }

      dayStatuses[ymd] = status;
    }

    return res.json({
      empid,
      month: `${year}-${month}`,
      shift: { group: emp.shiftGroup, startTime: shiftStart, endTime: shiftEnd, midpoint: mid },
      dayStatuses,
      totals: { present, absent, leave, holiday, weekOff, halfDay },
      extras: { lateCheckin: late, earlyCheckout: early, permissionCount },
    });
  } catch (err: any) {
    console.error('getMonthView error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/* ============================== Approvals & My Requests ============================== */

/** GET /api/attendance/approvals */
export const listApprovalRequests = async (req: Request, res: Response) => {
  try {
    const typeFilter   = normalizeType(req.query.type || 'All');
    const statusRaw    = String(req.query.status || 'Pending').trim();
    const statusWanted = norm(statusRaw); // pending|approved|rejected|all
    const start        = (String(req.query.start || '').slice(0, 10)) || null;
    const end          = (String(req.query.end   || '').slice(0, 10)) || null;

    // preload employees & shifts
    const empSnap = await db.collection(EMP_COL).get();
    const empById: Record<string, any> = Object.fromEntries(
      empSnap.docs.map(d => [d.data().empid, d.data()])
    );
    const shiftSnap = await db.collection(SHIFT_COL).get();
    const shiftByGroup: Record<string, any> = Object.fromEntries(
      shiftSnap.docs.map(d => [d.data().group, d.data()])
    );

    const out: any[] = [];

    // A) Attendance requests
    let attRef: FirebaseFirestore.Query = db.collection(ATT_COL);
    if (statusWanted !== 'all') attRef = attRef.where('approvalStatus', '==', statusRaw);
    if (start) attRef = attRef.where('date', '>=', start);
    if (end)   attRef = attRef.where('date', '<=', end);

    const attSnap = await attRef.get();
    attSnap.forEach(doc => {
      const a = doc.data() as any;
      const emp = empById[a.empid] || {};
      const shift = shiftByGroup[emp.shiftGroup] || {};
      const startTime = shift.startTime || '09:00';
      const endTime   = shift.endTime   || '18:00';

      let subType: string | null = null;
      if (a.checkIn  && a.checkIn  > startTime) subType = 'Late check in';
      if (a.checkOut && a.checkOut < endTime)   subType = 'Early check out';
      else if (a.checkOut && a.checkOut > endTime) subType = 'Late check out';
      if (!subType) return;
      if (typeFilter !== 'all' && normalizeType(subType) !== typeFilter) return;

      out.push({
        source: 'attendance',
        requestId: doc.id,
        type: subType,
        empid: a.empid,
        name: emp.name || a.name || '',
        department: emp.dept || emp.department || '',
        shift: emp.shift || shift.shift || null,
        shiftGroup: emp.shiftGroup || '',
        requestTime: subType === 'Late check in' ? (a.checkIn || '') : (a.checkOut || ''),
        requestDate: a.date,
        reason: a.reason || '-',
        location: a.location || '-',
        latitude: a.latitude || null,
        longitude: a.longitude || null,
        status: a.approvalStatus || 'Pending',
      });
    });

    // B) Leave requests
    const leaveSnap = await db.collection(LEAVE_COL).get();
    leaveSnap.forEach(doc => {
      const L = doc.data() as any;
      const emp = empById[L.empid] || {};

      const sNorm = norm(L.approvalStatus ?? L.status ?? 'Pending');
      if (statusWanted !== 'all' && sNorm !== statusWanted) return;

      const friendlyType = mapLeaveType(L.type);
      const dStart = toISO(L.startDate || L.date || L.selectDate);
      const dEnd   = toISO(L.endDate   || dStart);
      if (!overlaps(start, end, dStart, dEnd)) return;
      if (typeFilter !== 'all' && normalizeType(friendlyType) !== typeFilter) return;

      out.push({
        source: 'leaves',
        requestId: doc.id,
        type: friendlyType,
        empid: L.empid,
        name: emp.name || L.name || '',
        department: emp.dept || emp.department || L.department || '',
        shift: emp.shift || null,
        shiftGroup: emp.shiftGroup || '',
        requestTime: L.time || L.requestTime || '',
        requestDate: dStart || '',
        reason: L.reason || '-',
        location: L.location || '-',
        latitude: L.latitude || null,
        longitude: L.longitude || null,
        status: L.approvalStatus ?? L.status ?? 'Pending',
      });
    });

    out.sort((a, b) => String(b.requestDate || '').localeCompare(String(a.requestDate || '')));
    return res.json(out);
  } catch (err: any) {
    console.error('listApprovalRequests error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** Alias used by your router for /api/attendance/approvals */
export const listApprovals = (req: Request, res: Response) => listApprovalRequests(req, res);

/** POST /api/attendance/approvals/decision */
export const decideApproval = async (req: Request, res: Response) => {
  try {
    const { source, attendanceId, leaveId, empid, date, status, remarks } = req.body || {};
    const clean = String(status || '').trim();
    if (!['Approved', 'Rejected'].includes(clean)) {
      return res.status(400).json({ error: 'status must be Approved or Rejected' });
    }
    if (!source || !['attendance', 'leaves'].includes(source)) {
      return res.status(400).json({ error: 'source must be attendance or leaves' });
    }

    if (source === 'attendance') {
      let docRef: FirebaseFirestore.DocumentReference | null = null;
      if (attendanceId) {
        docRef = db.collection(ATT_COL).doc(attendanceId);
      } else if (empid && date) {
        const q = await db.collection(ATT_COL)
          .where('empid', '==', empid)
          .where('date', '==', date)
          .limit(1).get();
        if (q.empty) return res.status(404).json({ error: 'Attendance record not found' });
        docRef = q.docs[0].ref;
      } else {
        return res.status(400).json({ error: 'attendanceId or (empid & date) required' });
      }

      await (docRef as any).update({
        approvalStatus: clean,
        decisionBy: (req as any).user?.empid || null,
        decisionAt: admin.firestore.FieldValue.serverTimestamp(),
        decisionRemarks: remarks || null,
      });
      return res.json({ message: `Attendance ${clean.toLowerCase()} successfully` });
    }

    if (!leaveId) return res.status(400).json({ error: 'leaveId required' });
    await db.collection(LEAVE_COL).doc(leaveId).update({
      approvalStatus: clean,
      decisionBy: (req as any).user?.empid || null,
      decisionAt: admin.firestore.FieldValue.serverTimestamp(),
      decisionRemarks: remarks || null,
    });
    return res.json({ message: `Leave ${clean.toLowerCase()} successfully` });
  } catch (err: any) {
    console.error('decideApproval error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** GET /api/attendance/my-requests */
export const listMyRequests = async (req: Request, res: Response) => {
  try {
    const empid = (req as any).user?.empid;
    if (!empid) return res.status(401).json({ message: 'Unauthorized' });

    const statusQ = String(req.query.status || 'All');
    const wantStatus = statusQ.trim().toLowerCase();
    const start = (String(req.query.start || '').slice(0, 10));
    const end   = (String(req.query.end   || '').slice(0, 10));
    const singleDay = !!(start && end && start === end);

    // preload shifts (attendance subtype)
    const shiftsSnap = await db.collection(SHIFT_COL).get();
    const shiftByGroup: Record<string, any> = {};
    shiftsSnap.forEach(d => { const s = d.data(); shiftByGroup[s.group] = s; });

    // employee
    let emp: any = null;
    const eSnap = await db.collection(EMP_COL).where('empid', '==', empid).limit(1).get();
    if (!eSnap.empty) emp = eSnap.docs[0].data();

    const out: any[] = [];

    // A) Attendance items
    let attRef: FirebaseFirestore.Query = db.collection(ATT_COL).where('empid', '==', empid);
    if (start) attRef = attRef.where('date', '>=', start);
    if (end)   attRef = attRef.where('date', '<=', end);
    const attSnap = await attRef.get();

    attSnap.forEach(doc => {
      const a = doc.data() as any;

      const sNorm = String(a.approvalStatus || 'Pending').toLowerCase();
      if (wantStatus !== 'all' && sNorm !== wantStatus) return;
      if (singleDay && a.date !== start) return;

      const shift = shiftByGroup[emp?.shiftGroup] || {};
      const startTime = shift.startTime || '09:00';
      const endTime   = shift.endTime   || '18:00';

      let subType: string | null = null;
      if (a.checkIn  && a.checkIn  > startTime) subType = 'Late check in';
      else if (a.checkOut && a.checkOut < endTime) subType = 'Early check out';
      else if (a.checkOut && a.checkOut > endTime) subType = 'Late check out';

      out.push({
        source: 'attendance',
        requestId: doc.id,
        type: subType || 'Attendance',
        empid: a.empid,
        name: a.name || '',
        requestDate: a.date,
        requestTime:
          subType === 'Late check in' ? (a.checkIn || '') :
          (subType === 'Late check out' || subType === 'Early check out') ? (a.checkOut || '') : '',
        reason: a.reason || '-',
        location: a.location || '-',
        latitude: a.latitude || null,
        longitude: a.longitude || null,
        status: a.approvalStatus || 'Pending',
      });
    });

    // B) Leaves
    const leaveSnap = await db.collection(LEAVE_COL).where('empid', '==', empid).get();

    leaveSnap.forEach(doc => {
      const L = doc.data() as any;
      const sNorm = String(L.approvalStatus ?? L.status ?? 'Pending').toLowerCase();
      if (wantStatus !== 'all' && sNorm !== wantStatus) return;

      const dStart = toISO(L.startDate || L.date || L.selectDate);
      const dEnd   = toISO(L.endDate   || dStart);

      if (singleDay) {
        if (!(dStart && start >= dStart && start <= (dEnd || dStart))) return;
      } else {
        if (start && dEnd   && dEnd   < start) return;
        if (end   && dStart && dStart > end)   return;
      }

      out.push({
        source: 'leaves',
        requestId: doc.id,
        type: mapLeaveType(L.type),
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

    out.sort((a, b) => String(b.requestDate || '').localeCompare(String(a.requestDate || '')));
    return res.json(out);
  } catch (err: any) {
    console.error('listMyRequests error:', err);
    return res.status(500).json({ error: err.message });
  }
};
