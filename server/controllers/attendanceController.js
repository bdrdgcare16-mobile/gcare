
// // // // // // const admin = require('firebase-admin');
// // // // // // const db = require('../config/firebase').db;

// // // // // // const EMP_COL   = 'employees';
// // // // // // const ATT_COL   = 'attendance';
// // // // // // const LEAVE_COL = 'leaves';
// // // // // // const SHIFT_COL = 'shifts';

// // // // // // /**
// // // // // //  * Placeholder - load actual holiday/weekoff rules if you have them
// // // // // //  */
// // // // // // async function loadHolidaysAndWeekOffs(date) {
// // // // // //   return {
// // // // // //     holidays: new Set(),   // e.g. new Set(['2025-07-25'])
// // // // // //     weekOffs: new Set()    // e.g. new Set(['2025-07-27'])
// // // // // //   };
// // // // // // }

// // // // // // // ---------- small utils ----------
// // // // // // function toYMD(d = new Date()) {
// // // // // //   const ist = new Date(d.getTime() + 5.5 * 60 * 60 * 1000);
// // // // // //   return ist.toISOString().slice(0, 10);
// // // // // // }
// // // // // // function pad2(n){ return String(n).padStart(2,'0'); }
// // // // // // function daysInMonth(year, month){ return new Date(year, month, 0).getDate(); } // month: 1..12
// // // // // // function isSunday(ymd){ return new Date(ymd).getDay() === 0; } // 0=Sun
// // // // // // function cmpHHMM(a,b){ return (a||'00:00') > (b||'00:00'); }
// // // // // // function midpointHHMM(start, end){
// // // // // //   const [h1,m1] = (start||'00:00').split(':').map(Number);
// // // // // //   const [h2,m2] = (end  ||'23:59').split(':').map(Number);
// // // // // //   const s1 = h1*3600+m1*60, s2 = h2*3600+m2*60;
// // // // // //   const mid = Math.floor((s1+s2)/2);
// // // // // //   const mh = Math.floor(mid/3600), mm = Math.floor((mid%3600)/60);
// // // // // //   return `${pad2(mh)}:${pad2(mm)}`;
// // // // // // }

// // // // // // // NOTE: replace with real holidays if you have them
// // // // // // const HOLIDAYS_SET = new Set([
// // // // // //   // '2025-01-01', '2025-01-15', ...
// // // // // // ]);

// // // // // // // ===================== EXISTING HANDLERS (kept) =====================

// // // // // // // 0) Get current user’s empid, name & role
// // // // // // exports.getCurrentUser = async (req, res) => {
// // // // // //   try {
// // // // // //     const empid = req.user.empid;
// // // // // //     const snap = await db.collection(EMP_COL)
// // // // // //       .where('empid', '==', empid)
// // // // // //       .limit(1).get();

// // // // // //     if (snap.empty) {
// // // // // //       return res.status(404).json({ error: 'Employee not found' });
// // // // // //     }
// // // // // //     const d = snap.docs[0].data();
// // // // // //     return res.json({
// // // // // //       empid: d.empid,
// // // // // //       name:  d.name,
// // // // // //       role:  req.user.role,
// // // // // //       shiftGroup: d.shiftGroup
// // // // // //     });
// // // // // //   } catch (err) {
// // // // // //     console.error('getCurrentUser error:', err);
// // // // // //     return res.status(500).json({ error: err.message });
// // // // // //   }
// // // // // // };

// // // // // // // 1) Check-in
// // // // // // exports.checkIn = async (req, res) => {
// // // // // //   const { empid, name, location } = req.body;
// // // // // //   if (!empid || !name || !location) {
// // // // // //      return res.status(400).json({ error: 'empid, name and location are required' });
// // // // // //   }
// // // // // //   const today = new Date().toISOString().slice(0, 10);
// // // // // //   try {
// // // // // //     const snap = await db.collection(ATT_COL)
// // // // // //       .where('empid','==',empid)
// // // // // //       .where('date','==',today)
// // // // // //       .get();

// // // // // //     if (!snap.empty) {
// // // // // //       const doc = snap.docs[0];
// // // // // //       if (doc.data().checkIn) {
// // // // // //         return res.status(400).json({ error:'Already checked in today' });
// // // // // //       }
// // // // // //       await doc.ref.update({
// // // // // //         checkIn:        new Date().toLocaleTimeString('en-GB'),
// // // // // //         location,
// // // // // //         status:         'Present',
// // // // // //         approvalStatus: 'Pending',
// // // // // //         updatedAt:      admin.firestore.FieldValue.serverTimestamp()
// // // // // //       });
// // // // // //       return res.json({ message:'Check-in updated' });
// // // // // //     }

// // // // // //     await db.collection(ATT_COL).add({
// // // // // //       empid,
// // // // // //       name,
// // // // // //       date:           today,
// // // // // //       checkIn:        new Date().toLocaleTimeString('en-GB'),
// // // // // //       location,
// // // // // //       status:         'Present',
// // // // // //       approvalStatus: 'Pending',
// // // // // //       createdAt:      admin.firestore.FieldValue.serverTimestamp(),
// // // // // //       updatedAt:      admin.firestore.FieldValue.serverTimestamp()
// // // // // //     });
// // // // // //     return res.json({ message:'Checked-in successfully' });

// // // // // //   } catch (err) {
// // // // // //     console.error('checkIn error:', err);
// // // // // //     return res.status(500).json({ error: err.message });
// // // // // //   }
// // // // // // };

// // // // // // // 2) Check-out
// // // // // // exports.checkOut = async (req, res) => {
// // // // // //   const { empid, location } = req.body;
// // // // // //   if (!empid || !location) {
// // // // // //     return res.status(400).json({ error: 'empid and location are required' });
// // // // // //   }
// // // // // //   const today = new Date().toISOString().slice(0, 10);
// // // // // //   try {
// // // // // //     const snap = await db.collection(ATT_COL)
// // // // // //       .where('empid','==',empid)
// // // // // //       .where('date','==',today)
// // // // // //       .get();
// // // // // //     if (snap.empty) {
// // // // // //       return res.status(400).json({ error:'You need to check in first' });
// // // // // //     }
// // // // // //     const doc = snap.docs[0];
// // // // // //     if (doc.data().checkOut) {
// // // // // //       return res.status(400).json({ error:'Already checked out today' });
// // // // // //     }
// // // // // //     await doc.ref.update({
// // // // // //       checkOut:   new Date().toLocaleTimeString('en-GB'),
// // // // // //       location,
// // // // // //       updatedAt:  admin.firestore.FieldValue.serverTimestamp()
// // // // // //     });

// // // // // //     // mark employee inactive on checkout
// // // // // //     const empSnap = await db.collection(EMP_COL)
// // // // // //       .where('empid','==',empid)
// // // // // //       .limit(1).get();
// // // // // //     if (!empSnap.empty) {
// // // // // //       await empSnap.docs[0].ref.update({
// // // // // //         status:    'inactive',
// // // // // //         updatedAt: admin.firestore.FieldValue.serverTimestamp()
// // // // // //       });
// // // // // //     }

// // // // // //     return res.json({ message:'Checked-out & set inactive' });
// // // // // //   } catch (err) {
// // // // // //     console.error('checkOut error:', err);
// // // // // //     return res.status(500).json({ error: err.message });
// // // // // //   }
// // // // // // };

// // // // // // // 3) Live Attendance
// // // // // // exports.getLiveAttendance = async (req, res) => {
// // // // // //   const today = new Date().toISOString().slice(0, 10);
// // // // // //   const isAdmin = req.user.role === 'admin';

// // // // // //   try {
// // // // // //     // a) Load employees (all for admin, or just self for user)
// // // // // //     let employees;
// // // // // //     if (isAdmin) {
// // // // // //       const empSnap = await db.collection(EMP_COL).get();
// // // // // //       employees = empSnap.docs.map(d => d.data());
// // // // // //     } else {
// // // // // //       const empSnap = await db.collection(EMP_COL)
// // // // // //         .where('empid','==',req.user.empid)
// // // // // //         .limit(1).get();
// // // // // //       if (empSnap.empty) return res.json([]);
// // // // // //       employees = [empSnap.docs[0].data()];
// // // // // //     }

// // // // // //     // b) Build employee → attendance map
// // // // // //     const attSnap = await db.collection(ATT_COL)
// // // // // //       .where('date','==',today)
// // // // // //       .get();
// // // // // //     const attMap = Object.fromEntries(
// // // // // //       attSnap.docs.map(d => [d.data().empid, d.data()])
// // // // // //     );

// // // // // //     // c) Load approved leaves
// // // // // //     const leaveSnap = await db.collection(LEAVE_COL)
// // // // // //       .where('approvalStatus','==','Approved')
// // // // // //       .where('startDate','<=',today)
// // // // // //       .get();
// // // // // //     const validLeaves = leaveSnap.docs
// // // // // //       .map(d=>d.data())
// // // // // //       .filter(l=>l.endDate>=today)
// // // // // //       .map(l=>l.empid);
// // // // // //     const leaveSet = new Set(validLeaves);

// // // // // //     // d) Holidays & weekOffs
// // // // // //     const { holidays, weekOffs } = await loadHolidaysAndWeekOffs(today);

// // // // // //     // e) Load shifts (for checking late/early)
// // // // // //     const shiftsSnap = await db.collection(SHIFT_COL).get();
// // // // // //     const shiftByGroup = Object.fromEntries(
// // // // // //       shiftsSnap.docs.map(d=>[d.data().group, d.data()])
// // // // // //     );

// // // // // //     // f) Build response
// // // // // //     const result = employees.map(emp => {
// // // // // //       const rec = attMap[emp.empid];
// // // // // //       let status, isLate=false, isEarly=false;
// // // // // //       let permissionCount = Array.isArray(rec?.permissionRequests)
// // // // // //         ? rec.permissionRequests.length
// // // // // //         : (rec?.permissionRequest?1:0);
// // // // // //       let isLeave = leaveSet.has(emp.empid);
// // // // // //       let isHoliday = holidays.has(today);
// // // // // //       let isWeekOff = weekOffs.has(today);

// // // // // //       if (isHoliday)      status='Holiday';
// // // // // //       else if (isWeekOff) status='WeekOff';
// // // // // //       else if (isLeave)   status='Leave';
// // // // // //       else if (rec?.checkIn) {
// // // // // //         status='Present';
// // // // // //         const shift = shiftByGroup[emp.shiftGroup] || {};
// // // // // //         const start = shift.startTime || '00:00';
// // // // // //         const end   = shift.endTime   || '23:59';
// // // // // //         isLate  = rec.checkIn  > start;
// // // // // //         isEarly = rec.checkOut && rec.checkOut < end;
// // // // // //       } else {
// // // // // //         status='Absent';
// // // // // //       }

// // // // // //       // half-day if Present but checkIn after half of shift
// // // // // //       let isHalfDay = false;
// // // // // //       if (status==='Present' && shiftByGroup[emp.shiftGroup]) {
// // // // // //         const [h1,m1] = shiftByGroup[emp.shiftGroup].startTime.split(':').map(Number);
// // // // // //         const [h2,m2] = shiftByGroup[emp.shiftGroup].endTime.split(':').map(Number);
// // // // // //         const midSec = ((h1*3600+m1*60)+(h2*3600+m2*60))/2;
// // // // // //         const inSec  = rec && rec.checkIn
// // // // // //           ? rec.checkIn.split(':').reduce((a,v,i)=> a + v*(i===0?3600:60),0)
// // // // // //           : 0;
// // // // // //         isHalfDay = inSec > midSec;
// // // // // //       }

// // // // // //       return {
// // // // // //         empid:          emp.empid,
// // // // // //         name:           emp.name,
// // // // // //         shiftGroup:     emp.shiftGroup,
// // // // // //         date:           today,
// // // // // //         status,
// // // // // //         checkIn:        rec?.checkIn  || null,
// // // // // //         checkOut:       rec?.checkOut || null,
// // // // // //         late:           isLate,
// // // // // //         early:          isEarly,
// // // // // //         permissionCount,
// // // // // //         leave:          status==='Leave',
// // // // // //         holiday:        status==='Holiday',
// // // // // //         weekOff:        status==='WeekOff',
// // // // // //         halfDay:        isHalfDay
// // // // // //       };
// // // // // //     });

// // // // // //     return res.json(result);

// // // // // //   } catch (err) {
// // // // // //     console.error('getLiveAttendance error:', err);
// // // // // //     return res.status(500).json({ error: err.message });
// // // // // //   }
// // // // // // };

// // // // // // // 4) Employee’s full history
// // // // // // exports.getEmployeeAttendance = async (req, res) => {
// // // // // //   const { empid } = req.params;
// // // // // //   try {
// // // // // //     const snap = await db.collection(ATT_COL)
// // // // // //       .where('empid','==',empid)
// // // // // //       .orderBy('date','desc').get();
// // // // // //     const records = snap.docs.map(d=>({ id:d.id, ...d.data() }));
// // // // // //     return res.json(records);
// // // // // //   } catch (err) {
// // // // // //     console.error('getEmployeeAttendance error:', err);
// // // // // //     return res.status(500).json({ error: err.message });
// // // // // //   }
// // // // // // };

// // // // // // // 5) All records (admin only)
// // // // // // exports.getAllAttendance = async (req, res) => {
// // // // // //   try {
// // // // // //     const snap = await db.collection(ATT_COL).get();
// // // // // //     const records = snap.docs.map(d=>({ id:d.id, ...d.data() }));
// // // // // //     return res.json(records);
// // // // // //   } catch (err) {
// // // // // //     console.error('getAllAttendance error:', err);
// // // // // //     return res.status(500).json({ error: err.message });
// // // // // //   }
// // // // // // };

// // // // // // // 6) Approve / Reject
// // // // // // exports.approveAttendance = async (req, res) => {
// // // // // //   const { id, status } = req.body;
// // // // // //   try {
// // // // // //     await db.collection(ATT_COL).doc(id).update({
// // // // // //       approvalStatus: status,
// // // // // //       updatedAt:      admin.firestore.FieldValue.serverTimestamp()
// // // // // //     });
// // // // // //     return res.json({ message:`Attendance ${status.toLowerCase()} successfully` });
// // // // // //   } catch (err) {
// // // // // //     console.error('approveAttendance error:', err);
// // // // // //     return res.status(500).json({ error: err.message });
// // // // // //   }
// // // // // // };

// // // // // // // 7) Monthly summary (simple list)
// // // // // // exports.getMonthlySummary = async (req, res) => {
// // // // // //   const { empid, year, month } = req.params;
// // // // // //   try {
// // // // // //     const snap = await db.collection(ATT_COL)
// // // // // //       .where('empid','==',empid)
// // // // // //       .where('date','>=',`${year}-${month}-01`)
// // // // // //       .where('date','<=',`${year}-${month}-31`)
// // // // // //       .get();
// // // // // //     const records = snap.docs.map(d=>({ id:d.id, ...d.data() }));
// // // // // //     return res.json(records);
// // // // // //   } catch (err) {
// // // // // //     console.error('getMonthlySummary error:', err);
// // // // // //     return res.status(500).json({ error: err.message });
// // // // // //   }
// // // // // // };

// // // // // // // 8) Daily roster (admin only)
// // // // // // exports.getDailyRoster = async (req, res) => {
// // // // // //   const date = req.query.date;
// // // // // //   if (!date) {
// // // // // //     return res.status(400).json({ error:'Missing ?date=YYYY-MM-DD' });
// // // // // //   }
// // // // // //   try {
// // // // // //     const empSnap = await db.collection(EMP_COL).get();
// // // // // //     const employees = empSnap.docs.map(d=>d.data());

// // // // // //     const attSnap = await db.collection(ATT_COL)
// // // // // //       .where('date','==',date).get();
// // // // // //     const attByEmp = Object.fromEntries(
// // // // // //       attSnap.docs.map(d=>[d.data().empid,d.data()])
// // // // // //     );

// // // // // //     const roster = employees.map(emp => {
// // // // // //       const rec = attByEmp[emp.empid];
// // // // // //       let raw = 'Absent';
// // // // // //       if (rec?.approvalStatus==='Approved' && !rec.checkIn) raw='Leave';
// // // // // //       else if (rec?.checkIn) raw = rec.checkIn > '09:00' ? 'Late':'Present';

// // // // // //       return {
// // // // // //         empid:      emp.empid,
// // // // // //         name:       emp.name,
// // // // // //         shiftGroup: emp.shiftGroup,
// // // // // //         status:     (raw==='Present'||raw==='Late') ? 'active':'inactive'
// // // // // //       };
// // // // // //     });
// // // // // //     return res.json(roster);

// // // // // //   } catch (err) {
// // // // // //     console.error('getDailyRoster error:', err);
// // // // // //     return res.status(500).json({ error: err.message });
// // // // // //   }
// // // // // // };

// // // // // // // ===================== NEW: MONTH-VIEW AGGREGATOR (fixed) =====================
// // // // // // /**
// // // // // //  * GET /api/attendance/month-view/:empid/:year/:month
// // // // // //  * Returns:
// // // // // //  *  - dayStatuses: { 'YYYY-MM-DD': 'Present'|'Absent'|'Leave'|'Holiday'|'WeekOff'|'HalfDay' }
// // // // // //  *  - totals: { present, absent, leave, holiday, weekOff, halfDay }
// // // // // //  *  - extras: { lateCheckin, earlyCheckout, permissionCount }
// // // // // //  *  Uses precedence: Holiday > WeekOff > Leave > Present > Absent
// // // // // //  *  HalfDay is either explicit half-day leave or check-in after shift midpoint.
// // // // // //  *  Counts only up to today for the current month (future dates ignored).
// // // // // //  */
// // // // // // exports.getMonthView = async (req, res) => {
// // // // // //   try {
// // // // // //     const { empid, year, month } = req.params;   // month = '08', year = '2025'
// // // // // //     const y = parseInt(year, 10);
// // // // // //     const m = parseInt(month, 10);               // 1..12
// // // // // //     if (!empid || !y || !m) {
// // // // // //       return res.status(400).json({ error: 'Bad params' });
// // // // // //     }

// // // // // //     const first = `${year}-${month}-01`;
// // // // // //     const last  = `${year}-${month}-${pad2(daysInMonth(y, m))}`;

// // // // // //     // Helpers to normalize leave dates
// // // // // //     const toISODate = (v) => {
// // // // // //       try {
// // // // // //         if (!v) return '';
// // // // // //         if (typeof v === 'string') return v.slice(0, 10);
// // // // // //         if (v.toDate && typeof v.toDate === 'function') {
// // // // // //           return v.toDate().toISOString().slice(0, 10);
// // // // // //         }
// // // // // //         const d = new Date(v);
// // // // // //         if (!Number.isNaN(d.getTime())) return d.toISOString().slice(0, 10);
// // // // // //       } catch (_) {}
// // // // // //       return '';
// // // // // //     };
// // // // // //     const isApproved = (l) => {
// // // // // //       const s = String(l.approvalStatus || l.status || '').trim().toLowerCase();
// // // // // //       return s === 'approved';
// // // // // //     };

// // // // // //     // Load employee & shift
// // // // // //     const empSnap = await db.collection(EMP_COL).where('empid','==',empid).limit(1).get();
// // // // // //     if (empSnap.empty) return res.status(404).json({ error:'Employee not found' });
// // // // // //     const emp = empSnap.docs[0].data();

// // // // // //     const shiftSnap = await db.collection(SHIFT_COL).where('group','==',emp.shiftGroup).limit(1).get();
// // // // // //     const shift = shiftSnap.empty ? {} : shiftSnap.docs[0].data();
// // // // // //     const shiftStart = shift.startTime || '09:00';
// // // // // //     const shiftEnd   = shift.endTime   || '18:00';
// // // // // //     const mid        = midpointHHMM(shiftStart, shiftEnd);

// // // // // //     // Attendance for month
// // // // // //     const attSnap = await db.collection(ATT_COL)
// // // // // //       .where('empid','==',empid)
// // // // // //       .where('date','>=',first)
// // // // // //       .where('date','<=',last)
// // // // // //       .get();
// // // // // //     const attByDate = Object.fromEntries(attSnap.docs.map(d => [d.data().date, d.data()]));

// // // // // //     // Leaves (Approved only), normalize date range
// // // // // //     const leavesSnap = await db.collection(LEAVE_COL).where('empid','==',empid).get();

// // // // // //     const rangeLeaves = [];   // [{start:'YYYY-MM-DD', end:'YYYY-MM-DD', isHalf:boolean}]
// // // // // //     let permissionCount = 0;  // approved "permission time" in window

// // // // // //     leavesSnap.forEach(doc => {
// // // // // //       const l = doc.data();
// // // // // //       if (!isApproved(l)) return;

// // // // // //       const type = String(l.type || '').toLowerCase();

// // // // // //       // Normalize dates (any one of these may be present)
// // // // // //       const sdStr = toISODate(l.startDate || l.selectDate || l.date);
// // // // // //       const edStr = toISODate(l.endDate   || l.selectDate || l.date || l.startDate);

// // // // // //       if (type.includes('permission')) {
// // // // // //         // Count approved permission-time inside month window
// // // // // //         if ((sdStr && sdStr >= first && sdStr <= last) ||
// // // // // //             (edStr && edStr >= first && edStr <= last)) {
// // // // // //           permissionCount += 1;
// // // // // //         }
// // // // // //         return; // do not mark day as Leave
// // // // // //       }

// // // // // //       if (!sdStr) return;          // must have at least a start day
// // // // // //       const start = sdStr;
// // // // // //       const end   = edStr || sdStr;

// // // // // //       // Skip if fully outside month
// // // // // //       if (end < first || start > last) return;

// // // // // //       rangeLeaves.push({ start, end, isHalf: type.includes('half') });
// // // // // //     });

// // // // // //     // Optional holiday set
// // // // // //     const holidaySet = new Set(HOLIDAYS_SET);

// // // // // //     // Build day-by-day statuses
// // // // // //     const dayStatuses = {};
// // // // // //     let present=0, absent=0, leave=0, holiday=0, weekOff=0, halfDay=0, late=0, early=0;

// // // // // //     const todayYMD = toYMD(new Date());
// // // // // //     const stopAt = (year === todayYMD.slice(0,4) && month === todayYMD.slice(5,7))
// // // // // //       ? todayYMD
// // // // // //       : last;

// // // // // //     for (let d=1; d<=daysInMonth(y,m); d++){
// // // // // //       const ymd = `${year}-${month}-${pad2(d)}`;
// // // // // //       if (ymd > stopAt) continue;

// // // // // //       let status;

// // // // // //       if (holidaySet.has(ymd)) {
// // // // // //         status = 'Holiday'; holiday++;
// // // // // //       } else if (isSunday(ymd)) {
// // // // // //         status = 'WeekOff'; weekOff++;
// // // // // //       } else {
// // // // // //         // Approved leave?
// // // // // //         const lv = rangeLeaves.find(l => l.start <= ymd && ymd <= l.end);
// // // // // //         if (lv) {
// // // // // //           if (lv.isHalf) { status = 'HalfDay'; halfDay++; }
// // // // // //           else           { status = 'Leave';   leave++;   }
// // // // // //         } else {
// // // // // //           const rec = attByDate[ymd];
// // // // // //           if (rec && rec.checkIn) {
// // // // // //             status = 'Present'; present++;

// // // // // //             if (cmpHHMM(rec.checkIn, shiftStart)) late++;
// // // // // //             if (rec.checkOut && !cmpHHMM(rec.checkOut, shiftEnd)) early++;

// // // // // //             // Half-day if checked in after midpoint
// // // // // //             if (cmpHHMM(rec.checkIn, mid)) {
// // // // // //               status = 'HalfDay';
// // // // // //               halfDay++;
// // // // // //               present--; // convert that present day into half-day
// // // // // //             }
// // // // // //           } else {
// // // // // //             status = 'Absent'; absent++;
// // // // // //           }
// // // // // //         }
// // // // // //       }

// // // // // //       dayStatuses[ymd] = status;
// // // // // //     }

// // // // // //     return res.json({
// // // // // //       empid,
// // // // // //       month: `${year}-${month}`,
// // // // // //       shift: { group: emp.shiftGroup, startTime: shiftStart, endTime: shiftEnd, midpoint: mid },
// // // // // //       dayStatuses,
// // // // // //       totals: { present, absent, leave, holiday, weekOff, halfDay },
// // // // // //       extras: { lateCheckin: late, earlyCheckout: early, permissionCount }
// // // // // //     });

// // // // // //   } catch (err) {
// // // // // //     console.error('getMonthView error:', err);
// // // // // //     return res.status(500).json({ error: err.message });
// // // // // //   }
// // // // // // };
// // // // // const admin = require('firebase-admin');
// // // // // const db = require('../config/firebase').db;

// // // // // const EMP_COL   = 'employees';
// // // // // const ATT_COL   = 'attendance';
// // // // // const LEAVE_COL = 'leaves';
// // // // // const SHIFT_COL = 'shifts';

// // // // // /**
// // // // //  * Placeholder - load actual holiday/weekoff rules if you have them
// // // // //  */
// // // // // async function loadHolidaysAndWeekOffs(date) {
// // // // //   return {
// // // // //     holidays: new Set(),   // e.g. new Set(['2025-07-25'])
// // // // //     weekOffs: new Set()    // e.g. new Set(['2025-07-27'])
// // // // //   };
// // // // // }

// // // // // // ---------- small utils ----------
// // // // // function toYMD(d = new Date()) {
// // // // //   const ist = new Date(d.getTime() + 5.5 * 60 * 60 * 1000);
// // // // //   return ist.toISOString().slice(0, 10);
// // // // // }
// // // // // function pad2(n){ return String(n).padStart(2,'0'); }
// // // // // function daysInMonth(year, month){ return new Date(year, month, 0).getDate(); } // month: 1..12
// // // // // function isSunday(ymd){ return new Date(ymd).getDay() === 0; } // 0=Sun
// // // // // function cmpHHMM(a,b){ return (a||'00:00') > (b||'00:00'); }
// // // // // function midpointHHMM(start, end){
// // // // //   const [h1,m1] = (start||'00:00').split(':').map(Number);
// // // // //   const [h2,m2] = (end  ||'23:59').split(':').map(Number);
// // // // //   const s1 = h1*3600+m1*60, s2 = h2*3600+m2*60;
// // // // //   const mid = Math.floor((s1+s2)/2);
// // // // //   const mh = Math.floor(mid/3600), mm = Math.floor((mid%3600)/60);
// // // // //   return `${pad2(mh)}:${pad2(mm)}`;
// // // // // }

// // // // // // NOTE: replace with real holidays if you have them
// // // // // const HOLIDAYS_SET = new Set([
// // // // //   // '2025-01-01', '2025-01-15', ...
// // // // // ]);

// // // // // // ===================== EXISTING HANDLERS (kept) =====================

// // // // // // 0) Get current user’s empid, name & role
// // // // // exports.getCurrentUser = async (req, res) => {
// // // // //   try {
// // // // //     const empid = req.user.empid;
// // // // //     const snap = await db.collection(EMP_COL)
// // // // //       .where('empid', '==', empid)
// // // // //       .limit(1).get();

// // // // //     if (snap.empty) {
// // // // //       return res.status(404).json({ error: 'Employee not found' });
// // // // //     }
// // // // //     const d = snap.docs[0].data();
// // // // //     return res.json({
// // // // //       empid: d.empid,
// // // // //       name:  d.name,
// // // // //       role:  req.user.role,
// // // // //       shiftGroup: d.shiftGroup
// // // // //     });
// // // // //   } catch (err) {
// // // // //     console.error('getCurrentUser error:', err);
// // // // //     return res.status(500).json({ error: err.message });
// // // // //   }
// // // // // };

// // // // // // 1) Check-in
// // // // // exports.checkIn = async (req, res) => {
// // // // //   const { empid, name, location } = req.body;
// // // // //   if (!empid || !name || !location) {
// // // // //      return res.status(400).json({ error: 'empid, name and location are required' });
// // // // //   }
// // // // //   const today = new Date().toISOString().slice(0, 10);
// // // // //   try {
// // // // //     const snap = await db.collection(ATT_COL)
// // // // //       .where('empid','==',empid)
// // // // //       .where('date','==',today)
// // // // //       .get();

// // // // //     if (!snap.empty) {
// // // // //       const doc = snap.docs[0];
// // // // //       if (doc.data().checkIn) {
// // // // //         return res.status(400).json({ error:'Already checked in today' });
// // // // //       }
// // // // //       await doc.ref.update({
// // // // //         checkIn:        new Date().toLocaleTimeString('en-GB'),
// // // // //         location,
// // // // //         status:         'Present',
// // // // //         approvalStatus: 'Pending',
// // // // //         updatedAt:      admin.firestore.FieldValue.serverTimestamp()
// // // // //       });
// // // // //       return res.json({ message:'Check-in updated' });
// // // // //     }

// // // // //     await db.collection(ATT_COL).add({
// // // // //       empid,
// // // // //       name,
// // // // //       date:           today,
// // // // //       checkIn:        new Date().toLocaleTimeString('en-GB'),
// // // // //       location,
// // // // //       status:         'Present',
// // // // //       approvalStatus: 'Pending',
// // // // //       createdAt:      admin.firestore.FieldValue.serverTimestamp(),
// // // // //       updatedAt:      admin.firestore.FieldValue.serverTimestamp()
// // // // //     });
// // // // //     return res.json({ message:'Checked-in successfully' });

// // // // //   } catch (err) {
// // // // //     console.error('checkIn error:', err);
// // // // //     return res.status(500).json({ error: err.message });
// // // // //   }
// // // // // };

// // // // // // 2) Check-out
// // // // // exports.checkOut = async (req, res) => {
// // // // //   const { empid, location } = req.body;
// // // // //   if (!empid || !location) {
// // // // //     return res.status(400).json({ error: 'empid and location are required' });
// // // // //   }
// // // // //   const today = new Date().toISOString().slice(0, 10);
// // // // //   try {
// // // // //     const snap = await db.collection(ATT_COL)
// // // // //       .where('empid','==',empid)
// // // // //       .where('date','==',today)
// // // // //       .get();
// // // // //     if (snap.empty) {
// // // // //       return res.status(400).json({ error:'You need to check in first' });
// // // // //     }
// // // // //     const doc = snap.docs[0];
// // // // //     if (doc.data().checkOut) {
// // // // //       return res.status(400).json({ error:'Already checked out today' });
// // // // //     }
// // // // //     await doc.ref.update({
// // // // //       checkOut:   new Date().toLocaleTimeString('en-GB'),
// // // // //       location,
// // // // //       updatedAt:  admin.firestore.FieldValue.serverTimestamp()
// // // // //     });

// // // // //     // mark employee inactive on checkout
// // // // //     const empSnap = await db.collection(EMP_COL)
// // // // //       .where('empid','==',empid)
// // // // //       .limit(1).get();
// // // // //     if (!empSnap.empty) {
// // // // //       await empSnap.docs[0].ref.update({
// // // // //         status:    'inactive',
// // // // //         updatedAt: admin.firestore.FieldValue.serverTimestamp()
// // // // //       });
// // // // //     }

// // // // //     return res.json({ message:'Checked-out & set inactive' });
// // // // //   } catch (err) {
// // // // //     console.error('checkOut error:', err);
// // // // //     return res.status(500).json({ error: err.message });
// // // // //   }
// // // // // };

// // // // // // 3) Live Attendance
// // // // // exports.getLiveAttendance = async (req, res) => {
// // // // //   const today = new Date().toISOString().slice(0, 10);
// // // // //   const isAdmin = req.user.role === 'admin';

// // // // //   try {
// // // // //     // a) Load employees (all for admin, or just self for user)
// // // // //     let employees;
// // // // //     if (isAdmin) {
// // // // //       const empSnap = await db.collection(EMP_COL).get();
// // // // //       employees = empSnap.docs.map(d => d.data());
// // // // //     } else {
// // // // //       const empSnap = await db.collection(EMP_COL)
// // // // //         .where('empid','==',req.user.empid)
// // // // //         .limit(1).get();
// // // // //       if (empSnap.empty) return res.json([]);
// // // // //       employees = [empSnap.docs[0].data()];
// // // // //     }

// // // // //     // b) Build employee → attendance map
// // // // //     const attSnap = await db.collection(ATT_COL)
// // // // //       .where('date','==',today)
// // // // //       .get();
// // // // //     const attMap = Object.fromEntries(
// // // // //       attSnap.docs.map(d => [d.data().empid, d.data()])
// // // // //     );

// // // // //     // c) Load approved leaves
// // // // //     const leaveSnap = await db.collection(LEAVE_COL)
// // // // //       .where('approvalStatus','==','Approved')
// // // // //       .where('startDate','<=',today)
// // // // //       .get();
// // // // //     const validLeaves = leaveSnap.docs
// // // // //       .map(d=>d.data())
// // // // //       .filter(l=>l.endDate>=today)
// // // // //       .map(l=>l.empid);
// // // // //     const leaveSet = new Set(validLeaves);

// // // // //     // d) Holidays & weekOffs
// // // // //     const { holidays, weekOffs } = await loadHolidaysAndWeekOffs(today);

// // // // //     // e) Load shifts (for checking late/early)
// // // // //     const shiftsSnap = await db.collection(SHIFT_COL).get();
// // // // //     const shiftByGroup = Object.fromEntries(
// // // // //       shiftsSnap.docs.map(d=>[d.data().group, d.data()])
// // // // //     );

// // // // //     // f) Build response
// // // // //     const result = employees.map(emp => {
// // // // //       const rec = attMap[emp.empid];
// // // // //       let status, isLate=false, isEarly=false;
// // // // //       let permissionCount = Array.isArray(rec?.permissionRequests)
// // // // //         ? rec.permissionRequests.length
// // // // //         : (rec?.permissionRequest?1:0);
// // // // //       let isLeave = leaveSet.has(emp.empid);
// // // // //       let isHoliday = holidays.has(today);
// // // // //       let isWeekOff = weekOffs.has(today);

// // // // //       if (isHoliday)      status='Holiday';
// // // // //       else if (isWeekOff) status='WeekOff';
// // // // //       else if (isLeave)   status='Leave';
// // // // //       else if (rec?.checkIn) {
// // // // //         status='Present';
// // // // //         const shift = shiftByGroup[emp.shiftGroup] || {};
// // // // //         const start = shift.startTime || '00:00';
// // // // //         const end   = shift.endTime   || '23:59';
// // // // //         isLate  = rec.checkIn  > start;
// // // // //         isEarly = rec.checkOut && rec.checkOut < end;
// // // // //       } else {
// // // // //         status='Absent';
// // // // //       }

// // // // //       // half-day if Present but checkIn after half of shift
// // // // //       let isHalfDay = false;
// // // // //       if (status==='Present' && shiftByGroup[emp.shiftGroup]) {
// // // // //         const [h1,m1] = shiftByGroup[emp.shiftGroup].startTime.split(':').map(Number);
// // // // //         const [h2,m2] = shiftByGroup[emp.shiftGroup].endTime.split(':').map(Number);
// // // // //         const midSec = ((h1*3600+m1*60)+(h2*3600+m2*60))/2;
// // // // //         const inSec  = rec && rec.checkIn
// // // // //           ? rec.checkIn.split(':').reduce((a,v,i)=> a + v*(i===0?3600:60),0)
// // // // //           : 0;
// // // // //         isHalfDay = inSec > midSec;
// // // // //       }

// // // // //       return {
// // // // //         empid:          emp.empid,
// // // // //         name:           emp.name,
// // // // //         shiftGroup:     emp.shiftGroup,
// // // // //         date:           today,
// // // // //         status,
// // // // //         checkIn:        rec?.checkIn  || null,
// // // // //         checkOut:       rec?.checkOut || null,
// // // // //         late:           isLate,
// // // // //         early:          isEarly,
// // // // //         permissionCount,
// // // // //         leave:          status==='Leave',
// // // // //         holiday:        status==='Holiday',
// // // // //         weekOff:        status==='WeekOff',
// // // // //         halfDay:        isHalfDay
// // // // //       };
// // // // //     });

// // // // //     return res.json(result);

// // // // //   } catch (err) {
// // // // //     console.error('getLiveAttendance error:', err);
// // // // //     return res.status(500).json({ error: err.message });
// // // // //   }
// // // // // };

// // // // // // 4) Employee’s full history
// // // // // exports.getEmployeeAttendance = async (req, res) => {
// // // // //   const { empid } = req.params;
// // // // //   try {
// // // // //     const snap = await db.collection(ATT_COL)
// // // // //       .where('empid','==',empid)
// // // // //       .orderBy('date','desc').get();
// // // // //     const records = snap.docs.map(d=>({ id:d.id, ...d.data() }));
// // // // //     return res.json(records);
// // // // //   } catch (err) {
// // // // //     console.error('getEmployeeAttendance error:', err);
// // // // //     return res.status(500).json({ error: err.message });
// // // // //   }
// // // // // };

// // // // // // 5) All records (admin only)
// // // // // exports.getAllAttendance = async (req, res) => {
// // // // //   try {
// // // // //     const snap = await db.collection(ATT_COL).get();
// // // // //     const records = snap.docs.map(d=>({ id:d.id, ...d.data() }));
// // // // //     return res.json(records);
// // // // //   } catch (err) {
// // // // //     console.error('getAllAttendance error:', err);
// // // // //     return res.status(500).json({ error: err.message });
// // // // //   }
// // // // // };

// // // // // // 6) Approve / Reject
// // // // // exports.approveAttendance = async (req, res) => {
// // // // //   const { id, status } = req.body;
// // // // //   try {
// // // // //     await db.collection(ATT_COL).doc(id).update({
// // // // //       approvalStatus: status,
// // // // //       updatedAt:      admin.firestore.FieldValue.serverTimestamp()
// // // // //     });
// // // // //     return res.json({ message:`Attendance ${status.toLowerCase()} successfully` });
// // // // //   } catch (err) {
// // // // //     console.error('approveAttendance error:', err);
// // // // //     return res.status(500).json({ error: err.message });
// // // // //   }
// // // // // };

// // // // // // 7) Monthly summary (simple list)
// // // // // exports.getMonthlySummary = async (req, res) => {
// // // // //   const { empid, year, month } = req.params;
// // // // //   try {
// // // // //     const snap = await db.collection(ATT_COL)
// // // // //       .where('empid','==',empid)
// // // // //       .where('date','>=',`${year}-${month}-01`)
// // // // //       .where('date','<=',`${year}-${month}-31`)
// // // // //       .get();
// // // // //     const records = snap.docs.map(d=>({ id:d.id, ...d.data() }));
// // // // //     return res.json(records);
// // // // //   } catch (err) {
// // // // //     console.error('getMonthlySummary error:', err);
// // // // //     return res.status(500).json({ error: err.message });
// // // // //   }
// // // // // };

// // // // // // 8) Daily roster (admin only)
// // // // // exports.getDailyRoster = async (req, res) => {
// // // // //   const date = req.query.date;
// // // // //   if (!date) {
// // // // //     return res.status(400).json({ error:'Missing ?date=YYYY-MM-DD' });
// // // // //   }
// // // // //   try {
// // // // //     const empSnap = await db.collection(EMP_COL).get();
// // // // //     const employees = empSnap.docs.map(d=>d.data());

// // // // //     const attSnap = await db.collection(ATT_COL)
// // // // //       .where('date','==',date).get();
// // // // //     const attByEmp = Object.fromEntries(
// // // // //       attSnap.docs.map(d=>[d.data().empid,d.data()])
// // // // //     );

// // // // //     const roster = employees.map(emp => {
// // // // //       const rec = attByEmp[emp.empid];
// // // // //       let raw = 'Absent';
// // // // //       if (rec?.approvalStatus==='Approved' && !rec.checkIn) raw='Leave';
// // // // //       else if (rec?.checkIn) raw = rec.checkIn > '09:00' ? 'Late':'Present';

// // // // //       return {
// // // // //         empid:      emp.empid,
// // // // //         name:       emp.name,
// // // // //         shiftGroup: emp.shiftGroup,
// // // // //         status:     (raw==='Present'||raw==='Late') ? 'active':'inactive'
// // // // //       };
// // // // //     });
// // // // //     return res.json(roster);

// // // // //   } catch (err) {
// // // // //     console.error('getDailyRoster error:', err);
// // // // //     return res.status(500).json({ error: err.message });
// // // // //   }
// // // // // };

// // // // // // ===================== NEW: MONTH-VIEW AGGREGATOR (fixed) =====================
// // // // // /**
// // // // //  * GET /api/attendance/month-view/:empid/:year/:month
// // // // //  * Returns:
// // // // //  *  - dayStatuses: { 'YYYY-MM-DD': 'Present'|'Absent'|'Leave'|'Holiday'|'WeekOff'|'HalfDay' }
// // // // //  *  - totals: { present, absent, leave, holiday, weekOff, halfDay }
// // // // //  *  - extras: { lateCheckin, earlyCheckout, permissionCount }
// // // // //  *  Uses precedence: Holiday > WeekOff > Leave > Present > Absent
// // // // //  *  HalfDay is either explicit half-day leave or check-in after shift midpoint.
// // // // //  *  Counts only up to today for the current month (future dates ignored).
// // // // //  */
// // // // // exports.getMonthView = async (req, res) => {
// // // // //   try {
// // // // //     const { empid, year, month } = req.params;   // month = '08', year = '2025'
// // // // //     const y = parseInt(year, 10);
// // // // //     const m = parseInt(month, 10);               // 1..12
// // // // //     if (!empid || !y || !m) {
// // // // //       return res.status(400).json({ error: 'Bad params' });
// // // // //     }

// // // // //     const first = `${year}-${month}-01`;
// // // // //     const last  = `${year}-${month}-${pad2(daysInMonth(y, m))}`;

// // // // //     // Helpers to normalize leave dates
// // // // //     const toISODate = (v) => {
// // // // //       try {
// // // // //         if (!v) return '';
// // // // //         if (typeof v === 'string') return v.slice(0, 10);
// // // // //         if (v.toDate && typeof v.toDate === 'function') {
// // // // //           return v.toDate().toISOString().slice(0, 10);
// // // // //         }
// // // // //         const d = new Date(v);
// // // // //         if (!Number.isNaN(d.getTime())) return d.toISOString().slice(0, 10);
// // // // //       } catch (_) {}
// // // // //       return '';
// // // // //     };
// // // // //     const isApproved = (l) => {
// // // // //       const s = String(l.approvalStatus || l.status || '').trim().toLowerCase();
// // // // //       return s === 'approved';
// // // // //     };

// // // // //     // Load employee & shift
// // // // //     const empSnap = await db.collection(EMP_COL).where('empid','==',empid).limit(1).get();
// // // // //     if (empSnap.empty) return res.status(404).json({ error:'Employee not found' });
// // // // //     const emp = empSnap.docs[0].data();

// // // // //     const shiftSnap = await db.collection(SHIFT_COL).where('group','==',emp.shiftGroup).limit(1).get();
// // // // //     const shift = shiftSnap.empty ? {} : shiftSnap.docs[0].data();
// // // // //     const shiftStart = shift.startTime || '09:00';
// // // // //     const shiftEnd   = shift.endTime   || '18:00';
// // // // //     const mid        = midpointHHMM(shiftStart, shiftEnd);

// // // // //     // Attendance for month
// // // // //     const attSnap = await db.collection(ATT_COL)
// // // // //       .where('empid','==',empid)
// // // // //       .where('date','>=',first)
// // // // //       .where('date','<=',last)
// // // // //       .get();
// // // // //     const attByDate = Object.fromEntries(attSnap.docs.map(d => [d.data().date, d.data()]));

// // // // //     // Leaves (Approved only), normalize date range
// // // // //     const leavesSnap = await db.collection(LEAVE_COL).where('empid','==',empid).get();

// // // // //     const rangeLeaves = [];   // [{start:'YYYY-MM-DD', end:'YYYY-MM-DD', isHalf:boolean}]
// // // // //     let permissionCount = 0;  // approved "permission time" in window

// // // // //     leavesSnap.forEach(doc => {
// // // // //       const l = doc.data();
// // // // //       if (!isApproved(l)) return;

// // // // //       const type = String(l.type || '').toLowerCase();

// // // // //       // Normalize dates (any one of these may be present)
// // // // //       const sdStr = toISODate(l.startDate || l.selectDate || l.date);
// // // // //       const edStr = toISODate(l.endDate   || l.selectDate || l.date || l.startDate);

// // // // //       if (type.includes('permission')) {
// // // // //         // Count approved permission-time inside month window
// // // // //         if ((sdStr && sdStr >= first && sdStr <= last) ||
// // // // //             (edStr && edStr >= first && edStr <= last)) {
// // // // //           permissionCount += 1;
// // // // //         }
// // // // //         return; // do not mark day as Leave
// // // // //       }

// // // // //       if (!sdStr) return;          // must have at least a start day
// // // // //       const start = sdStr;
// // // // //       const end   = edStr || sdStr;

// // // // //       // Skip if fully outside month
// // // // //       if (end < first || start > last) return;

// // // // //       rangeLeaves.push({ start, end, isHalf: type.includes('half') });
// // // // //     });

// // // // //     // Optional holiday set
// // // // //     const holidaySet = new Set(HOLIDAYS_SET);

// // // // //     // Build day-by-day statuses
// // // // //     const dayStatuses = {};
// // // // //     let present=0, absent=0, leave=0, holiday=0, weekOff=0, halfDay=0, late=0, early=0;

// // // // //     const todayYMD = toYMD(new Date());
// // // // //     const stopAt = (year === todayYMD.slice(0,4) && month === todayYMD.slice(5,7))
// // // // //       ? todayYMD
// // // // //       : last;

// // // // //     for (let d=1; d<=daysInMonth(y,m); d++){
// // // // //       const ymd = `${year}-${month}-${pad2(d)}`;
// // // // //       if (ymd > stopAt) continue;

// // // // //       let status;

// // // // //       if (holidaySet.has(ymd)) {
// // // // //         status = 'Holiday'; holiday++;
// // // // //       } else if (isSunday(ymd)) {
// // // // //         status = 'WeekOff'; weekOff++;
// // // // //       } else {
// // // // //         // Approved leave?
// // // // //         const lv = rangeLeaves.find(l => l.start <= ymd && ymd <= l.end);
// // // // //         if (lv) {
// // // // //           if (lv.isHalf) { status = 'HalfDay'; halfDay++; }
// // // // //           else           { status = 'Leave';   leave++;   }
// // // // //         } else {
// // // // //           const rec = attByDate[ymd];
// // // // //           if (rec && rec.checkIn) {
// // // // //             status = 'Present'; present++;

// // // // //             if (cmpHHMM(rec.checkIn, shiftStart)) late++;
// // // // //             if (rec.checkOut && !cmpHHMM(rec.checkOut, shiftEnd)) early++;

// // // // //             // Half-day if checked in after midpoint
// // // // //             if (cmpHHMM(rec.checkIn, mid)) {
// // // // //               status = 'HalfDay';
// // // // //               halfDay++;
// // // // //               present--; // convert that present day into half-day
// // // // //             }
// // // // //           } else {
// // // // //             status = 'Absent'; absent++;
// // // // //           }
// // // // //         }
// // // // //       }

// // // // //       dayStatuses[ymd] = status;
// // // // //     }

// // // // //     return res.json({
// // // // //       empid,
// // // // //       month: `${year}-${month}`,
// // // // //       shift: { group: emp.shiftGroup, startTime: shiftStart, endTime: shiftEnd, midpoint: mid },
// // // // //       dayStatuses,
// // // // //       totals: { present, absent, leave, holiday, weekOff, halfDay },
// // // // //       extras: { lateCheckin: late, earlyCheckout: early, permissionCount }
// // // // //     });

// // // // //   } catch (err) {
// // // // //     console.error('getMonthView error:', err);
// // // // //     return res.status(500).json({ error: err.message });
// // // // //   }
// // // // // };

// // // // // // ===================== NEW: ADMIN APPROVAL LIST & DECISION =====================

// // // // // /**
// // // // //  * GET /api/attendance/approvals?type=Late%20check%20in|Late%20check%20out|Leave%20Type|Permission|Over%20Time|Half%20Day%20Leave|Comp%20Off|All&status=Pending|Approved|Rejected&start=YYYY-MM-DD&end=YYYY-MM-DD
// // // // //  * Lists normalized approval cards across attendance (late in/out) and leaves.
// // // // //  * Does NOT change any existing handlers.
// // // // //  */
// // // // // // ===================== NEW: ADMIN APPROVAL LIST & DECISION =====================

// // // // // /**
// // // // //  * GET /api/attendance/approvals?type=Late%20check%20in|Late%20check%20out|Leave%20Type|Permission|Over%20Time|Half%20Day%20Leave|Comp%20Off|All&status=Pending|Approved|Rejected|All&start=YYYY-MM-DD&end=YYYY-MM-DD
// // // // //  * Lists normalized approval cards across attendance (late in/out) and leaves.
// // // // //  * Only this handler is changed; others remain intact for integration.
// // // // //  */
// // // // // exports.listApprovalRequests = async (req, res) => {
// // // // //   try {
// // // // //     const typeQRaw = String(req.query.type || 'All');
// // // // //     const typeQ    = typeQRaw.toLowerCase();
// // // // //     const statusQ  = String(req.query.status || 'Pending');
// // // // //     const statusWanted = statusQ.toLowerCase();
// // // // //     const start    = req.query.start || null;   // YYYY-MM-DD
// // // // //     const end      = req.query.end   || null;   // YYYY-MM-DD

// // // // //     // load employees → quick lookups for name/dept/shiftGroup
// // // // //     const empSnap = await db.collection(EMP_COL).get();
// // // // //     const empById = {};
// // // // //     empSnap.forEach(d => { const e = d.data(); empById[e.empid] = e; });

// // // // //     // load shifts by group (for start/end inference on attendance)
// // // // //     const shiftsSnap  = await db.collection(SHIFT_COL).get();
// // // // //     const shiftByGroup = {};
// // // // //     shiftsSnap.forEach(d => { const s = d.data(); shiftByGroup[s.group] = s; });

// // // // //     const out = [];

// // // // //     // ---------- helpers ----------
// // // // //     const toISO = (v) => {
// // // // //       try {
// // // // //         if (!v) return '';
// // // // //         if (typeof v === 'string') return v.slice(0, 10);
// // // // //         if (v.toDate && typeof v.toDate === 'function') return v.toDate().toISOString().slice(0, 10);
// // // // //         const d = new Date(v); return d.toISOString().slice(0, 10);
// // // // //       } catch { return ''; }
// // // // //     };
// // // // //     const overlaps = (aStart, aEnd, bStart, bEnd) => {
// // // // //       if (!aStart && !aEnd) return true; // no filter → always ok
// // // // //       const A1 = aStart || '0000-01-01';
// // // // //       const A2 = aEnd   || '9999-12-31';
// // // // //       const B1 = bStart || bEnd || '';
// // // // //       const B2 = bEnd   || bStart || '';
// // // // //       if (!B1) return true; // leave has no date → include
// // // // //       return (B1 <= A2) && (B2 >= A1);
// // // // //     };
// // // // //     const mapLeaveType = (txt) => {
// // // // //       const t = String(txt || '').toLowerCase();
// // // // //       if (t.includes('permission')) return 'Permission';
// // // // //       if (t.includes('over'))       return 'Over Time';
// // // // //       if (t.includes('half'))       return 'Half Day Leave';
// // // // //       if (t.includes('comp'))       return 'Comp Off';
// // // // //       return 'Leave Type';
// // // // //     };

// // // // //     // ----- A) Attendance: late check in / late check out -----
// // // // //     let attRef = db.collection(ATT_COL);
// // // // //     if (statusWanted !== 'all') attRef = attRef.where('approvalStatus', '==', statusQ);
// // // // //     if (start) attRef = attRef.where('date', '>=', start);
// // // // //     if (end)   attRef = attRef.where('date', '<=', end);

// // // // //     const attSnap = await attRef.get();
// // // // //     attSnap.forEach(doc => {
// // // // //       const a = doc.data();
// // // // //       const emp   = empById[a.empid] || {};
// // // // //       const shift = shiftByGroup[emp.shiftGroup] || {};
// // // // //       const startTime = shift.startTime || '09:00';
// // // // //       const endTime   = shift.endTime   || '18:00';

// // // // //       let subType = null;
// // // // //       if (a.checkIn  && a.checkIn  > startTime) subType = 'late check in';
// // // // //       else if (a.checkOut && a.checkOut > endTime) subType = 'late check out';

// // // // //       if (!subType) return; // ignore normal attendance
// // // // //       if (typeQ !== 'all' && typeQ !== subType) return;

// // // // //       out.push({
// // // // //         source: 'attendance',
// // // // //         requestId: doc.id,
// // // // //         type: subType === 'late check in' ? 'Late check in' : 'Late check out',
// // // // //         empid: a.empid,
// // // // //         name: emp.name || a.name || '',
// // // // //         department: emp.dept || emp.department || '',
// // // // //         shift: emp.shift || shift.shift || null,
// // // // //         shiftGroup: emp.shiftGroup || '',
// // // // //         requestTime: subType === 'late check in' ? (a.checkIn || '') : (a.checkOut || ''),
// // // // //         requestDate: a.date,
// // // // //         reason: '-', // static for now
// // // // //         location: a.location || '-',
// // // // //         latitude: a.latitude || null,
// // // // //         longitude: a.longitude || null,
// // // // //         status: a.approvalStatus || 'Pending',
// // // // //       });
// // // // //     });

// // // // //     // ----- B) Leaves: Leave Type / Permission / Over Time / Half Day Leave / Comp Off -----
// // // // //     // Fetch all leaves and filter locally so we can normalize status (approvalStatus | status, any casing)
// // // // //     const leaveSnap = await db.collection(LEAVE_COL).get();

// // // // //     leaveSnap.forEach(doc => {
// // // // //       const L   = doc.data();
// // // // //       const emp = empById[L.empid] || {};

// // // // //       // normalize status; default Pending
// // // // //       const sNorm = String(L.approvalStatus ?? L.status ?? 'Pending').toLowerCase();
// // // // //       if (statusWanted !== 'all' && sNorm !== statusWanted) return;

// // // // //       const friendlyType = mapLeaveType(L.type);
// // // // //       if (typeQ !== 'all' && typeQ !== friendlyType.toLowerCase()) return;

// // // // //       // normalize date range and respect ?start/?end overlap if provided
// // // // //       const dStart = toISO(L.startDate || L.date || L.selectDate);
// // // // //       const dEnd   = toISO(L.endDate   || dStart);
// // // // //       if (!overlaps(start, end, dStart, dEnd)) return;

// // // // //       out.push({
// // // // //         source: 'leaves',
// // // // //         requestId: doc.id,
// // // // //         type: friendlyType,
// // // // //         empid: L.empid,
// // // // //         name: emp.name || L.name || '',
// // // // //         department: emp.dept || emp.department || L.department || '',
// // // // //         shift: emp.shift || null,
// // // // //         shiftGroup: emp.shiftGroup || '',
// // // // //         requestTime: L.time || L.requestTime || '',
// // // // //         requestDate: dStart || '',          // primary day shown on card
// // // // //         reason: L.reason || '-',
// // // // //         location: L.location || '-',
// // // // //         latitude: L.latitude || null,
// // // // //         longitude: L.longitude || null,
// // // // //         status: L.approvalStatus ?? L.status ?? 'Pending',
// // // // //       });
// // // // //     });

// // // // //     // newest first by requestDate if present
// // // // //     out.sort((a, b) => String(b.requestDate || '').localeCompare(String(a.requestDate || '')));

// // // // //     return res.json(out);
// // // // //   } catch (err) {
// // // // //     console.error('listApprovalRequests error:', err);
// // // // //     return res.status(500).json({ error: err.message });
// // // // //   }
// // // // // };


// // // // // /**
// // // // //  * POST /api/attendance/approvals/decision
// // // // //  * Body:
// // // // //  *  {
// // // // //  *    "source": "attendance" | "leaves",
// // // // //  *    // attendance:
// // // // //  *    "attendanceId": "docId"  OR  ("empid": "...", "date": "YYYY-MM-DD"),
// // // // //  *    // leaves:
// // // // //  *    "leaveId": "docId",
// // // // //  *    "status": "Approved" | "Rejected",
// // // // //  *    "remarks": "optional"
// // // // //  *  }
// // // // //  * Updates approvalStatus at the correct collection without touching other handlers.
// // // // //  */
// // // // // exports.decideApproval = async (req, res) => {
// // // // //   try {
// // // // //     const { source, attendanceId, leaveId, empid, date, status, remarks } = req.body || {};
// // // // //     const clean = String(status || '').trim();
// // // // //     if (!['Approved','Rejected'].includes(clean)) {
// // // // //       return res.status(400).json({ error: 'status must be Approved or Rejected' });
// // // // //     }
// // // // //     if (!source || !['attendance','leaves'].includes(source)) {
// // // // //       return res.status(400).json({ error: 'source must be attendance or leaves' });
// // // // //     }

// // // // //     if (source === 'attendance') {
// // // // //       let docRef = null;

// // // // //       if (attendanceId) {
// // // // //         docRef = db.collection(ATT_COL).doc(attendanceId);
// // // // //       } else if (empid && date) {
// // // // //         const q = await db.collection(ATT_COL)
// // // // //           .where('empid','==',empid)
// // // // //           .where('date','==',date)
// // // // //           .limit(1).get();
// // // // //         if (q.empty) return res.status(404).json({ error: 'Attendance record not found' });
// // // // //         docRef = q.docs[0].ref;
// // // // //       } else {
// // // // //         return res.status(400).json({ error: 'attendanceId or (empid & date) required' });
// // // // //       }

// // // // //       await docRef.update({
// // // // //         approvalStatus: clean,
// // // // //         decisionBy: req.user?.empid || null,
// // // // //         decisionAt: admin.firestore.FieldValue.serverTimestamp(),
// // // // //         decisionRemarks: remarks || null
// // // // //       });
// // // // //       return res.json({ message: `Attendance ${clean.toLowerCase()} successfully` });
// // // // //     }

// // // // //     // leaves
// // // // //     if (!leaveId) return res.status(400).json({ error: 'leaveId required' });
// // // // //     await db.collection(LEAVE_COL).doc(leaveId).update({
// // // // //       approvalStatus: clean,
// // // // //       decisionBy: req.user?.empid || null,
// // // // //       decisionAt: admin.firestore.FieldValue.serverTimestamp(),
// // // // //       decisionRemarks: remarks || null
// // // // //     });
// // // // //     return res.json({ message: `Leave ${clean.toLowerCase()} successfully` });

// // // // //   } catch (err) {
// // // // //     console.error('decideApproval error:', err);
// // // // //     return res.status(500).json({ error: err.message });
// // // // //   }
// // // // // };
// // // // const admin = require('firebase-admin');
// // // // const db = require('../config/firebase').db;

// // // // const EMP_COL   = 'employees';
// // // // const ATT_COL   = 'attendance';
// // // // const LEAVE_COL = 'leaves';
// // // // const SHIFT_COL = 'shifts';

// // // // /**
// // // //  * Placeholder - load actual holiday/weekoff rules if you have them
// // // //  */
// // // // async function loadHolidaysAndWeekOffs(date) {
// // // //   return {
// // // //     holidays: new Set(),   // e.g. new Set(['2025-07-25'])
// // // //     weekOffs: new Set()    // e.g. new Set(['2025-07-27'])
// // // //   };
// // // // }

// // // // // ---------- small utils ----------
// // // // function toYMD(d = new Date()) {
// // // //   const ist = new Date(d.getTime() + 5.5 * 60 * 60 * 1000);
// // // //   return ist.toISOString().slice(0, 10);
// // // // }
// // // // function pad2(n){ return String(n).padStart(2,'0'); }
// // // // function daysInMonth(year, month){ return new Date(year, month, 0).getDate(); } // month: 1..12
// // // // function isSunday(ymd){ return new Date(ymd).getDay() === 0; } // 0=Sun
// // // // function cmpHHMM(a,b){ return (a||'00:00') > (b||'00:00'); }
// // // // function midpointHHMM(start, end){
// // // //   const [h1,m1] = (start||'00:00').split(':').map(Number);
// // // //   const [h2,m2] = (end  ||'23:59').split(':').map(Number);
// // // //   const s1 = h1*3600+m1*60, s2 = h2*3600+m2*60;
// // // //   const mid = Math.floor((s1+s2)/2);
// // // //   const mh = Math.floor(mid/3600), mm = Math.floor((mid%3600)/60);
// // // //   return `${pad2(mh)}:${pad2(mm)}`;
// // // // }
// // // // function toISO(v){
// // // //   try{
// // // //     if(!v) return '';
// // // //     if (typeof v === 'string') return v.slice(0,10);
// // // //     if (v.toDate && typeof v.toDate === 'function') return v.toDate().toISOString().slice(0,10);
// // // //     const d = new Date(v); return d.toISOString().slice(0,10);
// // // //   }catch{ return ''; }
// // // // }
// // // // function eachYMD(start,end){
// // // //   const out=[]; const d=new Date(start);
// // // //   for(;;){ const ymd=d.toISOString().slice(0,10); out.push(ymd); if(ymd===end) break; d.setDate(d.getDate()+1); }
// // // //   return out;
// // // // }

// // // // // NOTE: replace with real holidays if you have them
// // // // const HOLIDAYS_SET = new Set([
// // // //   // '2025-01-01', '2025-01-15', ...
// // // // ]);

// // // // // ===================== EXISTING HANDLERS (kept) =====================

// // // // // 0) Get current user’s empid, name & role
// // // // exports.getCurrentUser = async (req, res) => {
// // // //   try {
// // // //     const empid = req.user.empid;
// // // //     const snap = await db.collection(EMP_COL)
// // // //       .where('empid', '==', empid)
// // // //       .limit(1).get();

// // // //     if (snap.empty) {
// // // //       return res.status(404).json({ error: 'Employee not found' });
// // // //     }
// // // //     const d = snap.docs[0].data();
// // // //     return res.json({
// // // //       empid: d.empid,
// // // //       name:  d.name,
// // // //       role:  req.user.role,
// // // //       shiftGroup: d.shiftGroup
// // // //     });
// // // //   } catch (err) {
// // // //     console.error('getCurrentUser error:', err);
// // // //     return res.status(500).json({ error: err.message });
// // // //   }
// // // // };

// // // // // 1) Check-in
// // // // exports.checkIn = async (req, res) => {
// // // //   const { empid, name, location } = req.body;
// // // //   if (!empid || !name || !location) {
// // // //      return res.status(400).json({ error: 'empid, name and location are required' });
// // // //   }
// // // //   const today = new Date().toISOString().slice(0, 10);
// // // //   try {
// // // //     const snap = await db.collection(ATT_COL)
// // // //       .where('empid','==',empid)
// // // //       .where('date','==',today)
// // // //       .get();

// // // //     if (!snap.empty) {
// // // //       const doc = snap.docs[0];
// // // //       if (doc.data().checkIn) {
// // // //         return res.status(400).json({ error:'Already checked in today' });
// // // //       }
// // // //       await doc.ref.update({
// // // //         checkIn:        new Date().toLocaleTimeString('en-GB'),
// // // //         location,
// // // //         status:         'Present',
// // // //         approvalStatus: 'Pending',
// // // //         updatedAt:      admin.firestore.FieldValue.serverTimestamp()
// // // //       });
// // // //       return res.json({ message:'Check-in updated' });
// // // //     }

// // // //     await db.collection(ATT_COL).add({
// // // //       empid,
// // // //       name,
// // // //       date:           today,
// // // //       checkIn:        new Date().toLocaleTimeString('en-GB'),
// // // //       location,
// // // //       status:         'Present',
// // // //       approvalStatus: 'Pending',
// // // //       createdAt:      admin.firestore.FieldValue.serverTimestamp(),
// // // //       updatedAt:      admin.firestore.FieldValue.serverTimestamp()
// // // //     });
// // // //     return res.json({ message:'Checked-in successfully' });

// // // //   } catch (err) {
// // // //     console.error('checkIn error:', err);
// // // //     return res.status(500).json({ error: err.message });
// // // //   }
// // // // };

// // // // // 2) Check-out
// // // // exports.checkOut = async (req, res) => {
// // // //   const { empid, location } = req.body;
// // // //   if (!empid || !location) {
// // // //     return res.status(400).json({ error: 'empid and location are required' });
// // // //   }
// // // //   const today = new Date().toISOString().slice(0, 10);
// // // //   try {
// // // //     const snap = await db.collection(ATT_COL)
// // // //       .where('empid','==',empid)
// // // //       .where('date','==',today)
// // // //       .get();
// // // //     if (snap.empty) {
// // // //       return res.status(400).json({ error:'You need to check in first' });
// // // //     }
// // // //     const doc = snap.docs[0];
// // // //     if (doc.data().checkOut) {
// // // //       return res.status(400).json({ error:'Already checked out today' });
// // // //     }
// // // //     await doc.ref.update({
// // // //       checkOut:   new Date().toLocaleTimeString('en-GB'),
// // // //       location,
// // // //       updatedAt:  admin.firestore.FieldValue.serverTimestamp()
// // // //     });

// // // //     // mark employee inactive on checkout
// // // //     const empSnap = await db.collection(EMP_COL)
// // // //       .where('empid','==',empid)
// // // //       .limit(1).get();
// // // //     if (!empSnap.empty) {
// // // //       await empSnap.docs[0].ref.update({
// // // //         status:    'inactive',
// // // //         updatedAt: admin.firestore.FieldValue.serverTimestamp()
// // // //       });
// // // //     }

// // // //     return res.json({ message:'Checked-out & set inactive' });
// // // //   } catch (err) {
// // // //     console.error('checkOut error:', err);
// // // //     return res.status(500).json({ error: err.message });
// // // //   }
// // // // };

// // // // // 3) Live Attendance
// // // // exports.getLiveAttendance = async (req, res) => {
// // // //   const today = new Date().toISOString().slice(0, 10);
// // // //   const isAdmin = req.user.role === 'admin';

// // // //   try {
// // // //     // a) Load employees (all for admin, or just self for user)
// // // //     let employees;
// // // //     if (isAdmin) {
// // // //       const empSnap = await db.collection(EMP_COL).get();
// // // //       employees = empSnap.docs.map(d => d.data());
// // // //     } else {
// // // //       const empSnap = await db.collection(EMP_COL)
// // // //         .where('empid','==',req.user.empid)
// // // //         .limit(1).get();
// // // //       if (empSnap.empty) return res.json([]);
// // // //       employees = [empSnap.docs[0].data()];
// // // //     }

// // // //     // b) Build employee → attendance map
// // // //     const attSnap = await db.collection(ATT_COL)
// // // //       .where('date','==',today)
// // // //       .get();
// // // //     const attMap = Object.fromEntries(
// // // //       attSnap.docs.map(d => [d.data().empid, d.data()])
// // // //     );

// // // //     // c) Load approved leaves
// // // //     const leaveSnap = await db.collection(LEAVE_COL)
// // // //       .where('approvalStatus','==','Approved')
// // // //       .where('startDate','<=',today)
// // // //       .get();
// // // //     const validLeaves = leaveSnap.docs
// // // //       .map(d=>d.data())
// // // //       .filter(l=>l.endDate>=today)
// // // //       .map(l=>l.empid);
// // // //     const leaveSet = new Set(validLeaves);

// // // //     // d) Holidays & weekOffs
// // // //     const { holidays, weekOffs } = await loadHolidaysAndWeekOffs(today);

// // // //     // e) Load shifts (for checking late/early)
// // // //     const shiftsSnap = await db.collection(SHIFT_COL).get();
// // // //     const shiftByGroup = Object.fromEntries(
// // // //       shiftsSnap.docs.map(d=>[d.data().group, d.data()])
// // // //     );

// // // //     // f) Build response
// // // //     const result = employees.map(emp => {
// // // //       const rec = attMap[emp.empid];
// // // //       let status, isLate=false, isEarly=false;
// // // //       let permissionCount = Array.isArray(rec?.permissionRequests)
// // // //         ? rec.permissionRequests.length
// // // //         : (rec?.permissionRequest?1:0);
// // // //       let isLeave = leaveSet.has(emp.empid);
// // // //       let isHoliday = holidays.has(today);
// // // //       let isWeekOff = weekOffs.has(today);

// // // //       if (isHoliday)      status='Holiday';
// // // //       else if (isWeekOff) status='WeekOff';
// // // //       else if (isLeave)   status='Leave';
// // // //       else if (rec?.checkIn) {
// // // //         status='Present';
// // // //         const shift = shiftByGroup[emp.shiftGroup] || {};
// // // //         const start = shift.startTime || '00:00';
// // // //         const end   = shift.endTime   || '23:59';
// // // //         isLate  = rec.checkIn  > start;
// // // //         isEarly = rec.checkOut && rec.checkOut < end;
// // // //       } else {
// // // //         status='Absent';
// // // //       }

// // // //       // half-day if Present but checkIn after half of shift
// // // //       let isHalfDay = false;
// // // //       if (status==='Present' && shiftByGroup[emp.shiftGroup]) {
// // // //         const [h1,m1] = shiftByGroup[emp.shiftGroup].startTime.split(':').map(Number);
// // // //         const [h2,m2] = shiftByGroup[emp.shiftGroup].endTime.split(':').map(Number);
// // // //         const midSec = ((h1*3600+m1*60)+(h2*3600+m2*60))/2;
// // // //         const inSec  = rec && rec.checkIn
// // // //           ? rec.checkIn.split(':').reduce((a,v,i)=> a + v*(i===0?3600:60),0)
// // // //           : 0;
// // // //         isHalfDay = inSec > midSec;
// // // //       }

// // // //       return {
// // // //         empid:          emp.empid,
// // // //         name:           emp.name,
// // // //         shiftGroup:     emp.shiftGroup,
// // // //         date:           today,
// // // //         status,
// // // //         checkIn:        rec?.checkIn  || null,
// // // //         checkOut:       rec?.checkOut || null,
// // // //         late:           isLate,
// // // //         early:          isEarly,
// // // //         permissionCount,
// // // //         leave:          status==='Leave',
// // // //         holiday:        status==='Holiday',
// // // //         weekOff:        status==='WeekOff',
// // // //         halfDay:        isHalfDay
// // // //       };
// // // //     });

// // // //     return res.json(result);

// // // //   } catch (err) {
// // // //     console.error('getLiveAttendance error:', err);
// // // //     return res.status(500).json({ error: err.message });
// // // //   }
// // // // };

// // // // // 4) Employee’s full history
// // // // exports.getEmployeeAttendance = async (req, res) => {
// // // //   const { empid } = req.params;
// // // //   try {
// // // //     const snap = await db.collection(ATT_COL)
// // // //       .where('empid','==',empid)
// // // //       .orderBy('date','desc').get();
// // // //     const records = snap.docs.map(d=>({ id:d.id, ...d.data() }));
// // // //     return res.json(records);
// // // //   } catch (err) {
// // // //     console.error('getEmployeeAttendance error:', err);
// // // //     return res.status(500).json({ error: err.message });
// // // //   }
// // // // };

// // // // // 5) All records (admin only)
// // // // exports.getAllAttendance = async (req, res) => {
// // // //   try {
// // // //     const snap = await db.collection(ATT_COL).get();
// // // //     const records = snap.docs.map(d=>({ id:d.id, ...d.data() }));
// // // //     return res.json(records);
// // // //   } catch (err) {
// // // //     console.error('getAllAttendance error:', err);
// // // //     return res.status(500).json({ error: err.message });
// // // //   }
// // // // };

// // // // // 6) Approve / Reject
// // // // exports.approveAttendance = async (req, res) => {
// // // //   const { id, status } = req.body;
// // // //   try {
// // // //     await db.collection(ATT_COL).doc(id).update({
// // // //       approvalStatus: status,
// // // //       updatedAt:      admin.firestore.FieldValue.serverTimestamp()
// // // //     });
// // // //     return res.json({ message:`Attendance ${status.toLowerCase()} successfully` });
// // // //   } catch (err) {
// // // //     console.error('approveAttendance error:', err);
// // // //     return res.status(500).json({ error: err.message });
// // // //   }
// // // // };

// // // // // 7) Monthly summary (simple list)
// // // // exports.getMonthlySummary = async (req, res) => {
// // // //   const { empid, year, month } = req.params;
// // // //   try {
// // // //     const snap = await db.collection(ATT_COL)
// // // //       .where('empid','==',empid)
// // // //       .where('date','>=',`${year}-${month}-01`)
// // // //       .where('date','<=',`${year}-${month}-31`)
// // // //       .get();
// // // //     const records = snap.docs.map(d=>({ id:d.id, ...d.data() }));
// // // //     return res.json(records);
// // // //   } catch (err) {
// // // //     console.error('getMonthlySummary error:', err);
// // // //     return res.status(500).json({ error: err.message });
// // // //   }
// // // // };

// // // // // 8) Daily roster (admin only)
// // // // exports.getDailyRoster = async (req, res) => {
// // // //   const date = req.query.date;
// // // //   if (!date) {
// // // //     return res.status(400).json({ error:'Missing ?date=YYYY-MM-DD' });
// // // //   }
// // // //   try {
// // // //     const empSnap = await db.collection(EMP_COL).get();
// // // //     const employees = empSnap.docs.map(d=>d.data());

// // // //     const attSnap = await db.collection(ATT_COL)
// // // //       .where('date','==',date).get();
// // // //     const attByEmp = Object.fromEntries(
// // // //       attSnap.docs.map(d=>[d.data().empid,d.data()])
// // // //     );

// // // //     const roster = employees.map(emp => {
// // // //       const rec = attByEmp[emp.empid];
// // // //       let raw = 'Absent';
// // // //       if (rec?.approvalStatus==='Approved' && !rec.checkIn) raw='Leave';
// // // //       else if (rec?.checkIn) raw = rec.checkIn > '09:00' ? 'Late':'Present';

// // // //       return {
// // // //         empid:      emp.empid,
// // // //         name:       emp.name,
// // // //         shiftGroup: emp.shiftGroup,
// // // //         status:     (raw==='Present'||raw==='Late') ? 'active':'inactive'
// // // //       };
// // // //     });
// // // //     return res.json(roster);

// // // //   } catch (err) {
// // // //     console.error('getDailyRoster error:', err);
// // // //     return res.status(500).json({ error: err.message });
// // // //   }
// // // // };

// // // // // ===================== NEW: RANGE SUMMARY (admin) =====================
// // // // /**
// // // //  * GET /api/attendance/range-summary?start=YYYY-MM-DD&end=YYYY-MM-DD
// // // //  * Returns:
// // // //  *  counts: {
// // // //  *    activeEmployees, onLeave, checkedIn, absent,
// // // //  *    lateCheckIn, earlyCheckOut, halfDay, present, holiday, weekOff
// // // //  *  }
// // // //  *  rows: [ { employeeId, employeeName, shift, date, checkIn, checkOut, department, attendance, workedHours, late, early, approval } ]
// // // //  * - activeEmployees from employees.status == 'active'
// // // //  * - onLeave is the number of leave-days in the window (approved leaves)
// // // //  * - present counts only attendance with approvalStatus == 'Approved'
// // // //  * - late/early/half-day computed from shift times (group)
// // // //  */
// // // // exports.getRangeSummary = async (req, res) => {
// // // //   try {
// // // //     const start = String(req.query.start || '').slice(0,10);
// // // //     const end   = String(req.query.end   || '').slice(0,10);
// // // //     if (!start || !end || new Date(end) < new Date(start)) {
// // // //       return res.status(400).json({ error: 'Provide ?start=YYYY-MM-DD&end=YYYY-MM-DD' });
// // // //     }

// // // //     // Employees
// // // //     const empSnap = await db.collection(EMP_COL).get();
// // // //     const employees = empSnap.docs.map(d => d.data());
// // // //     const empById   = Object.fromEntries(employees.map(e => [e.empid, e]));

// // // //     const activeEmployees = employees.filter(e => String(e.status||'').toLowerCase()==='active').length;

// // // //     // Shifts
// // // //     const shiftsSnap = await db.collection(SHIFT_COL).get();
// // // //     const shiftByGroup = Object.fromEntries(shiftsSnap.docs.map(d => [d.data().group, d.data()]));

// // // //     // Attendance in window
// // // //     const attSnap = await db.collection(ATT_COL)
// // // //       .where('date','>=',start).where('date','<=',end).get();
// // // //     const attByEmpDate = {};
// // // //     attSnap.forEach(doc => {
// // // //       const a = doc.data();
// // // //       attByEmpDate[`${a.empid}|${a.date}`] = { id: doc.id, ...a };
// // // //     });

// // // //     // Approved leaves (build set of leave days inside range)
// // // //     const leavesSnap = await db.collection(LEAVE_COL).get();
// // // //     const approvedLeaves = leavesSnap.docs
// // // //       .map(d => d.data())
// // // //       .filter(L => String(L.approvalStatus ?? L.status ?? 'Pending').toLowerCase()==='approved')
// // // //       .map(L => ({
// // // //         empid: L.empid,
// // // //         type:  String(L.type||''),
// // // //         start: toISO(L.startDate || L.selectDate || L.date),
// // // //         end:   toISO(L.endDate   || L.selectDate || L.date || L.startDate),
// // // //       }));

// // // //     const leaveDays = new Set(); // empid|YYYY-MM-DD
// // // //     let onLeaveCount = 0;
// // // //     for (const L of approvedLeaves) {
// // // //       if (!L.start) continue;
// // // //       const s = L.start, e = L.end || L.start;
// // // //       if (e < start || s > end) continue;
// // // //       for (const d of eachYMD( (s<start?start:s), (e>end?end:e) )) {
// // // //         leaveDays.add(`${L.empid}|${d}`); onLeaveCount++;
// // // //       }
// // // //     }

// // // //     // Totals
// // // //     let checkedIn=0, absent=0, lateIn=0, earlyOut=0, halfDay=0, presentApproved=0, holiday=0, weekOff=0;

// // // //     const rows = [];
// // // //     const dates = eachYMD(start, end);
// // // //     for (const ymd of dates) {
// // // //       const isHoliday = HOLIDAYS_SET.has(ymd);
// // // //       const isWO = isSunday(ymd);
// // // //       if (isHoliday) holiday++;
// // // //       if (isWO) weekOff++;

// // // //       for (const emp of employees) {
// // // //         const key   = `${emp.empid}|${ymd}`;
// // // //         const att   = attByEmpDate[key] || null;
// // // //         const shift = shiftByGroup[emp.shiftGroup] || { startTime: '09:00', endTime: '18:00' };
// // // //         const startT = shift.startTime || '09:00';
// // // //         const endT   = shift.endTime   || '18:00';
// // // //         const mid    = midpointHHMM(startT, endT);

// // // //         let status = 'Absent';
// // // //         let isLate=false, isEarly=false;

// // // //         if (isHoliday) {
// // // //           status = 'Holiday';
// // // //         } else if (isWO) {
// // // //           status = 'WeekOff';
// // // //         } else if (leaveDays.has(key)) {
// // // //           status = (approvedLeaves.find(l => l.empid===emp.empid && l.start<=ymd && ymd<= (l.end||l.start) && l.type.toLowerCase().includes('half')))
// // // //                    ? 'Half Day'
// // // //                    : 'On Leave';
// // // //           if (status==='Half Day') halfDay++;
// // // //         } else if (att?.checkIn) {
// // // //           checkedIn++;
// // // //           status = 'Present';
// // // //           if (cmpHHMM(att.checkIn, startT)) { isLate = true; lateIn++; }
// // // //           if (att.checkOut && !cmpHHMM(att.checkOut, endT)) { isEarly = true; earlyOut++; }
// // // //           if (cmpHHMM(att.checkIn, mid)) { status = 'Half Day'; halfDay++; }
// // // //           if (String(att.approvalStatus||'').toLowerCase()==='approved') presentApproved++;
// // // //         } else {
// // // //           absent++;
// // // //         }

// // // //         rows.push({
// // // //           employeeId:  emp.empid,
// // // //           employeeName: emp.name || '',
// // // //           shift:       emp.shift || emp.shiftGroup || '',
// // // //           date:        ymd,
// // // //           checkIn:     att?.checkIn || '-',
// // // //           checkOut:    att?.checkOut || '-',
// // // //           department:  emp.dept || emp.department || '',
// // // //           attendance:  status,
// // // //           workedHours: att?.workedHours ? String(att.workedHours) : '-',
// // // //           late:        isLate,
// // // //           early:       isEarly,
// // // //           approval:    att?.approvalStatus || 'Pending'
// // // //         });
// // // //       }
// // // //     }

// // // //     return res.json({
// // // //       counts: {
// // // //         activeEmployees: activeEmployees,
// // // //         onLeave: onLeaveCount,
// // // //         checkedIn,
// // // //         absent,
// // // //         lateCheckIn: lateIn,
// // // //         earlyCheckOut: earlyOut,
// // // //         halfDay,
// // // //         present: presentApproved,
// // // //         holiday,
// // // //         weekOff
// // // //       },
// // // //       rows
// // // //     });
// // // //   } catch (err) {
// // // //     console.error('getRangeSummary error:', err);
// // // //     return res.status(500).json({ error: err.message });
// // // //   }
// // // // };

// // // // // ===================== NEW: MONTH-VIEW AGGREGATOR (fixed) =====================
// // // // /**
// // // //  * GET /api/attendance/month-view/:empid/:year/:month
// // // //  * Returns:
// // // //  *  - dayStatuses: { 'YYYY-MM-DD': 'Present'|'Absent'|'Leave'|'Holiday'|'WeekOff'|'HalfDay' }
// // // //  *  - totals: { present, absent, leave, holiday, weekOff, halfDay }
// // // //  *  - extras: { lateCheckin, earlyCheckout, permissionCount }
// // // //  *  Uses precedence: Holiday > WeekOff > Leave > Present > Absent
// // // //  *  HalfDay is either explicit half-day leave or check-in after shift midpoint.
// // // //  *  Counts only up to today for the current month (future dates ignored).
// // // //  */
// // // // exports.getMonthView = async (req, res) => {
// // // //   try {
// // // //     const { empid, year, month } = req.params;   // month = '08', year = '2025'
// // // //     const y = parseInt(year, 10);
// // // //     const m = parseInt(month, 10);               // 1..12
// // // //     if (!empid || !y || !m) {
// // // //       return res.status(400).json({ error: 'Bad params' });
// // // //     }

// // // //     const first = `${year}-${month}-01`;
// // // //     const last  = `${year}-${month}-${pad2(daysInMonth(y, m))}`;

// // // //     // Helpers to normalize leave dates
// // // //     const toISODate = (v) => {
// // // //       try {
// // // //         if (!v) return '';
// // // //         if (typeof v === 'string') return v.slice(0, 10);
// // // //         if (v.toDate && typeof v.toDate === 'function') {
// // // //           return v.toDate().toISOString().slice(0, 10);
// // // //         }
// // // //         const d = new Date(v);
// // // //         if (!Number.isNaN(d.getTime())) return d.toISOString().slice(0, 10);
// // // //       } catch (_) {}
// // // //       return '';
// // // //     };
// // // //     const isApproved = (l) => {
// // // //       const s = String(l.approvalStatus || l.status || '').trim().toLowerCase();
// // // //       return s === 'approved';
// // // //     };

// // // //     // Load employee & shift
// // // //     const empSnap = await db.collection(EMP_COL).where('empid','==',empid).limit(1).get();
// // // //     if (empSnap.empty) return res.status(404).json({ error:'Employee not found' });
// // // //     const emp = empSnap.docs[0].data();

// // // //     const shiftSnap = await db.collection(SHIFT_COL).where('group','==',emp.shiftGroup).limit(1).get();
// // // //     const shift = shiftSnap.empty ? {} : shiftSnap.docs[0].data();
// // // //     const shiftStart = shift.startTime || '09:00';
// // // //     const shiftEnd   = shift.endTime   || '18:00';
// // // //     const mid        = midpointHHMM(shiftStart, shiftEnd);

// // // //     // Attendance for month
// // // //     const attSnap = await db.collection(ATT_COL)
// // // //       .where('empid','==',empid)
// // // //       .where('date','>=',first)
// // // //       .where('date','<=',last)
// // // //       .get();
// // // //     const attByDate = Object.fromEntries(attSnap.docs.map(d => [d.data().date, d.data()]));

// // // //     // Leaves (Approved only), normalize date range
// // // //     const leavesSnap = await db.collection(LEAVE_COL).where('empid','==',empid).get();

// // // //     const rangeLeaves = [];   // [{start:'YYYY-MM-DD', end:'YYYY-MM-DD', isHalf:boolean}]
// // // //     let permissionCount = 0;  // approved "permission time" in window

// // // //     leavesSnap.forEach(doc => {
// // // //       const l = doc.data();
// // // //       if (!isApproved(l)) return;

// // // //       const type = String(l.type || '').toLowerCase();

// // // //       // Normalize dates (any one of these may be present)
// // // //       const sdStr = toISODate(l.startDate || l.selectDate || l.date);
// // // //       const edStr = toISODate(l.endDate   || l.selectDate || l.date || l.startDate);

// // // //       if (type.includes('permission')) {
// // // //         // Count approved permission-time inside month window
// // // //         if ((sdStr && sdStr >= first && sdStr <= last) ||
// // // //             (edStr && edStr >= first && edStr <= last)) {
// // // //           permissionCount += 1;
// // // //         }
// // // //         return; // do not mark day as Leave
// // // //       }

// // // //       if (!sdStr) return;          // must have at least a start day
// // // //       const start = sdStr;
// // // //       const end   = edStr || sdStr;

// // // //       // Skip if fully outside month
// // // //       if (end < first || start > last) return;

// // // //       rangeLeaves.push({ start, end, isHalf: type.includes('half') });
// // // //     });

// // // //     // Optional holiday set
// // // //     const holidaySet = new Set(HOLIDAYS_SET);

// // // //     // Build day-by-day statuses
// // // //     const dayStatuses = {};
// // // //     let present=0, absent=0, leave=0, holiday=0, weekOff=0, halfDay=0, late=0, early=0;

// // // //     const todayYMD = toYMD(new Date());
// // // //     const stopAt = (year === todayYMD.slice(0,4) && month === todayYMD.slice(5,7))
// // // //       ? todayYMD
// // // //       : last;

// // // //     for (let d=1; d<=daysInMonth(y,m); d++){
// // // //       const ymd = `${year}-${month}-${pad2(d)}`;
// // // //       if (ymd > stopAt) continue;

// // // //       let status;

// // // //       if (holidaySet.has(ymd)) {
// // // //         status = 'Holiday'; holiday++;
// // // //       } else if (isSunday(ymd)) {
// // // //         status = 'WeekOff'; weekOff++;
// // // //       } else {
// // // //         // Approved leave?
// // // //         const lv = rangeLeaves.find(l => l.start <= ymd && ymd <= l.end);
// // // //         if (lv) {
// // // //           if (lv.isHalf) { status = 'HalfDay'; halfDay++; }
// // // //           else           { status = 'Leave';   leave++;   }
// // // //         } else {
// // // //           const rec = attByDate[ymd];
// // // //           if (rec && rec.checkIn) {
// // // //             status = 'Present'; present++;

// // // //             if (cmpHHMM(rec.checkIn, shiftStart)) late++;
// // // //             if (rec.checkOut && !cmpHHMM(rec.checkOut, shiftEnd)) early++;

// // // //             // Half-day if checked in after midpoint
// // // //             if (cmpHHMM(rec.checkIn, mid)) {
// // // //               status = 'HalfDay';
// // // //               halfDay++;
// // // //               present--; // convert that present day into half-day
// // // //             }
// // // //           } else {
// // // //             status = 'Absent'; absent++;
// // // //           }
// // // //         }
// // // //       }

// // // //       dayStatuses[ymd] = status;
// // // //     }

// // // //     return res.json({
// // // //       empid,
// // // //       month: `${year}-${month}`,
// // // //       shift: { group: emp.shiftGroup, startTime: shiftStart, endTime: shiftEnd, midpoint: mid },
// // // //       dayStatuses,
// // // //       totals: { present, absent, leave, holiday, weekOff, halfDay },
// // // //       extras: { lateCheckin: late, earlyCheckout: early, permissionCount }
// // // //     });

// // // //   } catch (err) {
// // // //     console.error('getMonthView error:', err);
// // // //     return res.status(500).json({ error: err.message });
// // // //   }
// // // // };

// // // // // ===================== NEW: ADMIN APPROVAL LIST & DECISION =====================

// // // // /**
// // // //  * GET /api/attendance/approvals?type=Late%20check%20in|Late%20check%20out|Leave%20Type|Permission|Over%20Time|Half%20Day%20Leave|Comp%20Off|All&status=Pending|Approved|Rejected|All&start=YYYY-MM-DD&end=YYYY-MM-DD
// // // //  * Lists normalized approval cards across attendance (late in/out) and leaves.
// // // //  * Only this handler is changed; others remain intact for integration.
// // // //  */
// // // // exports.listApprovalRequests = async (req, res) => {
// // // //   try {
// // // //     const typeQRaw = String(req.query.type || 'All');
// // // //     const typeQ    = typeQRaw.toLowerCase();
// // // //     const statusQ  = String(req.query.status || 'Pending');
// // // //     const statusWanted = statusQ.toLowerCase();
// // // //     const start    = req.query.start || null;   // YYYY-MM-DD
// // // //     const end      = req.query.end   || null;   // YYYY-MM-DD

// // // //     // load employees → quick lookups for name/dept/shiftGroup
// // // //     const empSnap = await db.collection(EMP_COL).get();
// // // //     const empById = {};
// // // //     empSnap.forEach(d => { const e = d.data(); empById[e.empid] = e; });

// // // //     // load shifts by group (for start/end inference on attendance)
// // // //     const shiftsSnap  = await db.collection(SHIFT_COL).get();
// // // //     const shiftByGroup = {};
// // // //     shiftsSnap.forEach(d => { const s = d.data(); shiftByGroup[s.group] = s; });

// // // //     const out = [];

// // // //     // ---------- helpers ----------
// // // //     const toISO = (v) => {
// // // //       try {
// // // //         if (!v) return '';
// // // //         if (typeof v === 'string') return v.slice(0, 10);
// // // //         if (v.toDate && typeof v.toDate === 'function') return v.toDate().toISOString().slice(0, 10);
// // // //         const d = new Date(v); return d.toISOString().slice(0, 10);
// // // //       } catch { return ''; }
// // // //     };
// // // //     const overlaps = (aStart, aEnd, bStart, bEnd) => {
// // // //       if (!aStart && !aEnd) return true; // no filter → always ok
// // // //       const A1 = aStart || '0000-01-01';
// // // //       const A2 = aEnd   || '9999-12-31';
// // // //       const B1 = bStart || bEnd || '';
// // // //       const B2 = bEnd   || bStart || '';
// // // //       if (!B1) return true; // leave has no date → include
// // // //       return (B1 <= A2) && (B2 >= A1);
// // // //     };
// // // //     const mapLeaveType = (txt) => {
// // // //       const t = String(txt || '').toLowerCase();
// // // //       if (t.includes('permission')) return 'Permission';
// // // //       if (t.includes('over'))       return 'Over Time';
// // // //       if (t.includes('half'))       return 'Half Day Leave';
// // // //       if (t.includes('comp'))       return 'Comp Off';
// // // //       return 'Leave Type';
// // // //     };

// // // //     // ----- A) Attendance: late check in / late check out -----
// // // //     let attRef = db.collection(ATT_COL);
// // // //     if (statusWanted !== 'all') attRef = attRef.where('approvalStatus', '==', statusQ);
// // // //     if (start) attRef = attRef.where('date', '>=', start);
// // // //     if (end)   attRef = attRef.where('date', '<=', end);

// // // //     const attSnap = await attRef.get();
// // // //     attSnap.forEach(doc => {
// // // //       const a = doc.data();
// // // //       const emp   = empById[a.empid] || {};
// // // //       const shift = shiftByGroup[emp.shiftGroup] || {};
// // // //       const startTime = shift.startTime || '09:00';
// // // //       const endTime   = shift.endTime   || '18:00';

// // // //       let subType = null;
// // // //       if (a.checkIn  && a.checkIn  > startTime) subType = 'late check in';
// // // //       else if (a.checkOut && a.checkOut > endTime) subType = 'late check out';

// // // //       if (!subType) return; // ignore normal attendance
// // // //       if (typeQ !== 'all' && typeQ !== subType) return;

// // // //       out.push({
// // // //         source: 'attendance',
// // // //         requestId: doc.id,
// // // //         type: subType === 'late check in' ? 'Late check in' : 'Late check out',
// // // //         empid: a.empid,
// // // //         name: emp.name || a.name || '',
// // // //         department: emp.dept || emp.department || '',
// // // //         shift: emp.shift || shift.shift || null,
// // // //         shiftGroup: emp.shiftGroup || '',
// // // //         requestTime: subType === 'late check in' ? (a.checkIn || '') : (a.checkOut || ''),
// // // //         requestDate: a.date,
// // // //         reason: '-', // static for now
// // // //         location: a.location || '-',
// // // //         latitude: a.latitude || null,
// // // //         longitude: a.longitude || null,
// // // //         status: a.approvalStatus || 'Pending',
// // // //       });
// // // //     });

// // // //     // ----- B) Leaves: Leave Type / Permission / Over Time / Half Day Leave / Comp Off -----
// // // //     // Fetch all leaves and filter locally so we can normalize status (approvalStatus | status, any casing)
// // // //     const leaveSnap = await db.collection(LEAVE_COL).get();

// // // //     leaveSnap.forEach(doc => {
// // // //       const L   = doc.data();
// // // //       const emp = empById[L.empid] || {};

// // // //       // normalize status; default Pending
// // // //       const sNorm = String(L.approvalStatus ?? L.status ?? 'Pending').toLowerCase();
// // // //       if (statusWanted !== 'all' && sNorm !== statusWanted) return;

// // // //       const friendlyType = mapLeaveType(L.type);
// // // //       if (typeQ !== 'all' && typeQ !== friendlyType.toLowerCase()) return;

// // // //       // normalize date range and respect ?start/?end overlap if provided
// // // //       const dStart = toISO(L.startDate || L.date || L.selectDate);
// // // //       const dEnd   = toISO(L.endDate   || dStart);
// // // //       if (!overlaps(start, end, dStart, dEnd)) return;

// // // //       out.push({
// // // //         source: 'leaves',
// // // //         requestId: doc.id,
// // // //         type: friendlyType,
// // // //         empid: L.empid,
// // // //         name: emp.name || L.name || '',
// // // //         department: emp.dept || emp.department || L.department || '',
// // // //         shift: emp.shift || null,
// // // //         shiftGroup: emp.shiftGroup || '',
// // // //         requestTime: L.time || L.requestTime || '',
// // // //         requestDate: dStart || '',          // primary day shown on card
// // // //         reason: L.reason || '-',
// // // //         location: L.location || '-',
// // // //         latitude: L.latitude || null,
// // // //         longitude: L.longitude || null,
// // // //         status: L.approvalStatus ?? L.status ?? 'Pending',
// // // //       });
// // // //     });

// // // //     // newest first by requestDate if present
// // // //     out.sort((a, b) => String(b.requestDate || '').localeCompare(String(a.requestDate || '')));

// // // //     return res.json(out);
// // // //   } catch (err) {
// // // //     console.error('listApprovalRequests error:', err);
// // // //     return res.status(500).json({ error: err.message });
// // // //   }
// // // // };


// // // // /**
// // // //  * POST /api/attendance/approvals/decision
// // // //  * Body:
// // // //  *  {
// // // //  *    "source": "attendance" | "leaves",
// // // //  *    // attendance:
// // // //  *    "attendanceId": "docId"  OR  ("empid": "...", "date": "YYYY-MM-DD"),
// // // //  *    // leaves:
// // // //  *    "leaveId": "docId",
// // // //  *    "status": "Approved" | "Rejected",
// // // //  *    "remarks": "optional"
// // // //  *  }
// // // //  * Updates approvalStatus at the correct collection without touching other handlers.
// // // //  */
// // // // exports.decideApproval = async (req, res) => {
// // // //   try {
// // // //     const { source, attendanceId, leaveId, empid, date, status, remarks } = req.body || {};
// // // //     const clean = String(status || '').trim();
// // // //     if (!['Approved','Rejected'].includes(clean)) {
// // // //       return res.status(400).json({ error: 'status must be Approved or Rejected' });
// // // //     }
// // // //     if (!source || !['attendance','leaves'].includes(source)) {
// // // //       return res.status(400).json({ error: 'source must be attendance or leaves' });
// // // //     }

// // // //     if (source === 'attendance') {
// // // //       let docRef = null;

// // // //       if (attendanceId) {
// // // //         docRef = db.collection(ATT_COL).doc(attendanceId);
// // // //       } else if (empid && date) {
// // // //         const q = await db.collection(ATT_COL)
// // // //           .where('empid','==',empid)
// // // //           .where('date','==',date)
// // // //           .limit(1).get();
// // // //         if (q.empty) return res.status(404).json({ error: 'Attendance record not found' });
// // // //         docRef = q.docs[0].ref;
// // // //       } else {
// // // //         return res.status(400).json({ error: 'attendanceId or (empid & date) required' });
// // // //       }

// // // //       await docRef.update({
// // // //         approvalStatus: clean,
// // // //         decisionBy: req.user?.empid || null,
// // // //         decisionAt: admin.firestore.FieldValue.serverTimestamp(),
// // // //         decisionRemarks: remarks || null
// // // //       });
// // // //       return res.json({ message: `Attendance ${clean.toLowerCase()} successfully` });
// // // //     }

// // // //     // leaves
// // // //     if (!leaveId) return res.status(400).json({ error: 'leaveId required' });
// // // //     await db.collection(LEAVE_COL).doc(leaveId).update({
// // // //       approvalStatus: clean,
// // // //       decisionBy: req.user?.empid || null,
// // // //       decisionAt: admin.firestore.FieldValue.serverTimestamp(),
// // // //       decisionRemarks: remarks || null
// // // //     });
// // // //     return res.json({ message: `Leave ${clean.toLowerCase()} successfully` });

// // // //   } catch (err) {
// // // //     console.error('decideApproval error:', err);
// // // //     return res.status(500).json({ error: err.message });
// // // //   }
// // // // };
// // // const admin = require('firebase-admin');
// // // const db = require('../config/firebase').db;

// // // const EMP_COL   = 'employees';
// // // const ATT_COL   = 'attendance';
// // // const LEAVE_COL = 'leaves';
// // // const SHIFT_COL = 'shifts';

// // // /**
// // //  * Placeholder - load actual holiday/weekoff rules if you have them
// // //  */
// // // async function loadHolidaysAndWeekOffs(date) {
// // //   return {
// // //     holidays: new Set(),   // e.g. new Set(['2025-07-25'])
// // //     weekOffs: new Set()    // e.g. new Set(['2025-07-27'])
// // //   };
// // // }

// // // // ---------- small utils ----------
// // // function toYMD(d = new Date()) {
// // //   const ist = new Date(d.getTime() + 5.5 * 60 * 60 * 1000);
// // //   return ist.toISOString().slice(0, 10);
// // // }
// // // function pad2(n){ return String(n).padStart(2,'0'); }
// // // function daysInMonth(year, month){ return new Date(year, month, 0).getDate(); } // month: 1..12
// // // function isSunday(ymd){ return new Date(ymd).getDay() === 0; } // 0=Sun
// // // function cmpHHMM(a,b){ return (a||'00:00') > (b||'00:00'); }
// // // function midpointHHMM(start, end){
// // //   const [h1,m1] = (start||'00:00').split(':').map(Number);
// // //   const [h2,m2] = (end  ||'23:59').split(':').map(Number);
// // //   const s1 = h1*3600+m1*60, s2 = h2*3600+m2*60;
// // //   const mid = Math.floor((s1+s2)/2);
// // //   const mh = Math.floor(mid/3600), mm = Math.floor((mid%3600)/60);
// // //   return `${pad2(mh)}:${pad2(mm)}`;
// // // }
// // // function toISO(v){
// // //   try{
// // //     if(!v) return '';
// // //     if (typeof v === 'string') return v.slice(0,10);
// // //     if (v.toDate && typeof v.toDate === 'function') return v.toDate().toISOString().slice(0,10);
// // //     const d = new Date(v); return d.toISOString().slice(0,10);
// // //   }catch{ return ''; }
// // // }
// // // function eachYMD(start,end){
// // //   const out=[]; const d=new Date(start);
// // //   for(;;){ const ymd=d.toISOString().slice(0,10); out.push(ymd); if(ymd===end) break; d.setDate(d.getDate()+1); }
// // //   return out;
// // // }

// // // // NOTE: replace with real holidays if you have them
// // // const HOLIDAYS_SET = new Set([
// // //   // '2025-01-01', '2025-01-15', ...
// // // ]);

// // // // ===================== EXISTING HANDLERS (kept) =====================

// // // // 0) Get current user’s empid, name & role
// // // exports.getCurrentUser = async (req, res) => {
// // //   try {
// // //     const empid = req.user.empid;
// // //     const snap = await db.collection(EMP_COL)
// // //       .where('empid', '==', empid)
// // //       .limit(1).get();

// // //     if (snap.empty) {
// // //       return res.status(404).json({ error: 'Employee not found' });
// // //     }
// // //     const d = snap.docs[0].data();
// // //     return res.json({
// // //       empid: d.empid,
// // //       name:  d.name,
// // //       role:  req.user.role,
// // //       shiftGroup: d.shiftGroup
// // //     });
// // //   } catch (err) {
// // //     console.error('getCurrentUser error:', err);
// // //     return res.status(500).json({ error: err.message });
// // //   }
// // // };

// // // // 1) Check-in
// // // exports.checkIn = async (req, res) => {
// // //   const { empid, name, location } = req.body;
// // //   if (!empid || !name || !location) {
// // //      return res.status(400).json({ error: 'empid, name and location are required' });
// // //   }
// // //   const today = new Date().toISOString().slice(0, 10);
// // //   try {
// // //     const snap = await db.collection(ATT_COL)
// // //       .where('empid','==',empid)
// // //       .where('date','==',today)
// // //       .get();

// // //     if (!snap.empty) {
// // //       const doc = snap.docs[0];
// // //       if (doc.data().checkIn) {
// // //         return res.status(400).json({ error:'Already checked in today' });
// // //       }
// // //       await doc.ref.update({
// // //         checkIn:        new Date().toLocaleTimeString('en-GB'),
// // //         location,
// // //         status:         'Present',
// // //         approvalStatus: 'Pending',
// // //         updatedAt:      admin.firestore.FieldValue.serverTimestamp()
// // //       });
// // //       return res.json({ message:'Check-in updated' });
// // //     }

// // //     await db.collection(ATT_COL).add({
// // //       empid,
// // //       name,
// // //       date:           today,
// // //       checkIn:        new Date().toLocaleTimeString('en-GB'),
// // //       location,
// // //       status:         'Present',
// // //       approvalStatus: 'Pending',
// // //       createdAt:      admin.firestore.FieldValue.serverTimestamp(),
// // //       updatedAt:      admin.firestore.FieldValue.serverTimestamp()
// // //     });
// // //     return res.json({ message:'Checked-in successfully' });

// // //   } catch (err) {
// // //     console.error('checkIn error:', err);
// // //     return res.status(500).json({ error: err.message });
// // //   }
// // // };

// // // // 2) Check-out
// // // exports.checkOut = async (req, res) => {
// // //   const { empid, location } = req.body;
// // //   if (!empid || !location) {
// // //     return res.status(400).json({ error: 'empid and location are required' });
// // //   }
// // //   const today = new Date().toISOString().slice(0, 10);
// // //   try {
// // //     const snap = await db.collection(ATT_COL)
// // //       .where('empid','==',empid)
// // //       .where('date','==',today)
// // //       .get();
// // //     if (snap.empty) {
// // //       return res.status(400).json({ error:'You need to check in first' });
// // //     }
// // //     const doc = snap.docs[0];
// // //     if (doc.data().checkOut) {
// // //       return res.status(400).json({ error:'Already checked out today' });
// // //     }
// // //     await doc.ref.update({
// // //       checkOut:   new Date().toLocaleTimeString('en-GB'),
// // //       location,
// // //       updatedAt:  admin.firestore.FieldValue.serverTimestamp()
// // //     });

// // //     // mark employee inactive on checkout
// // //     const empSnap = await db.collection(EMP_COL)
// // //       .where('empid','==',empid)
// // //       .limit(1).get();
// // //     if (!empSnap.empty) {
// // //       await empSnap.docs[0].ref.update({
// // //         status:    'inactive',
// // //         updatedAt: admin.firestore.FieldValue.serverTimestamp()
// // //       });
// // //     }

// // //     return res.json({ message:'Checked-out & set inactive' });
// // //   } catch (err) {
// // //     console.error('checkOut error:', err);
// // //     return res.status(500).json({ error: err.message });
// // //   }
// // // };

// // // // 3) Live Attendance
// // // exports.getLiveAttendance = async (req, res) => {
// // //   const today = new Date().toISOString().slice(0, 10);
// // //   const isAdmin = req.user.role === 'admin';

// // //   try {
// // //     // a) Load employees (all for admin, or just self for user)
// // //     let employees;
// // //     if (isAdmin) {
// // //       const empSnap = await db.collection(EMP_COL).get();
// // //       employees = empSnap.docs.map(d => d.data());
// // //     } else {
// // //       const empSnap = await db.collection(EMP_COL)
// // //         .where('empid','==',req.user.empid)
// // //         .limit(1).get();
// // //       if (empSnap.empty) return res.json([]);
// // //       employees = [empSnap.docs[0].data()];
// // //     }

// // //     // b) Build employee → attendance map
// // //     const attSnap = await db.collection(ATT_COL)
// // //       .where('date','==',today)
// // //       .get();
// // //     const attMap = Object.fromEntries(
// // //       attSnap.docs.map(d => [d.data().empid, d.data()])
// // //     );

// // //     // c) Load approved leaves
// // //     const leaveSnap = await db.collection(LEAVE_COL)
// // //       .where('approvalStatus','==','Approved')
// // //       .where('startDate','<=',today)
// // //       .get();
// // //     const validLeaves = leaveSnap.docs
// // //       .map(d=>d.data())
// // //       .filter(l=>l.endDate>=today)
// // //       .map(l=>l.empid);
// // //     const leaveSet = new Set(validLeaves);

// // //     // d) Holidays & weekOffs
// // //     const { holidays, weekOffs } = await loadHolidaysAndWeekOffs(today);

// // //     // e) Load shifts (for checking late/early)
// // //     const shiftsSnap = await db.collection(SHIFT_COL).get();
// // //     const shiftByGroup = Object.fromEntries(
// // //       shiftsSnap.docs.map(d=>[d.data().group, d.data()])
// // //     );

// // //     // f) Build response
// // //     const result = employees.map(emp => {
// // //       const rec = attMap[emp.empid];
// // //       let status, isLate=false, isEarly=false;
// // //       let permissionCount = Array.isArray(rec?.permissionRequests)
// // //         ? rec.permissionRequests.length
// // //         : (rec?.permissionRequest?1:0);
// // //       let isLeave = leaveSet.has(emp.empid);
// // //       let isHoliday = holidays.has(today);
// // //       let isWeekOff = weekOffs.has(today);

// // //       if (isHoliday)      status='Holiday';
// // //       else if (isWeekOff) status='WeekOff';
// // //       else if (isLeave)   status='Leave';
// // //       else if (rec?.checkIn) {
// // //         status='Present';
// // //         const shift = shiftByGroup[emp.shiftGroup] || {};
// // //         const start = shift.startTime || '00:00';
// // //         const end   = shift.endTime   || '23:59';
// // //         isLate  = rec.checkIn  > start;
// // //         isEarly = rec.checkOut && rec.checkOut < end;
// // //       } else {
// // //         status='Absent';
// // //       }

// // //       // half-day if Present but checkIn after half of shift
// // //       let isHalfDay = false;
// // //       if (status==='Present' && shiftByGroup[emp.shiftGroup]) {
// // //         const [h1,m1] = shiftByGroup[emp.shiftGroup].startTime.split(':').map(Number);
// // //         const [h2,m2] = shiftByGroup[emp.shiftGroup].endTime.split(':').map(Number);
// // //         const midSec = ((h1*3600+m1*60)+(h2*3600+m2*60))/2;
// // //         const inSec  = rec && rec.checkIn
// // //           ? rec.checkIn.split(':').reduce((a,v,i)=> a + v*(i===0?3600:60),0)
// // //           : 0;
// // //         isHalfDay = inSec > midSec;
// // //       }

// // //       return {
// // //         empid:          emp.empid,
// // //         name:           emp.name,
// // //         shiftGroup:     emp.shiftGroup,
// // //         date:           today,
// // //         status,
// // //         checkIn:        rec?.checkIn  || null,
// // //         checkOut:       rec?.checkOut || null,
// // //         late:           isLate,
// // //         early:          isEarly,
// // //         permissionCount,
// // //         leave:          status==='Leave',
// // //         holiday:        status==='Holiday',
// // //         weekOff:        status==='WeekOff',
// // //         halfDay:        isHalfDay
// // //       };
// // //     });

// // //     return res.json(result);

// // //   } catch (err) {
// // //     console.error('getLiveAttendance error:', err);
// // //     return res.status(500).json({ error: err.message });
// // //   }
// // // };

// // // // 4) Employee’s full history
// // // exports.getEmployeeAttendance = async (req, res) => {
// // //   const { empid } = req.params;
// // //   try {
// // //     const snap = await db.collection(ATT_COL)
// // //       .where('empid','==',empid)
// // //       .orderBy('date','desc').get();
// // //     const records = snap.docs.map(d=>({ id:d.id, ...d.data() }));
// // //     return res.json(records);
// // //   } catch (err) {
// // //     console.error('getEmployeeAttendance error:', err);
// // //     return res.status(500).json({ error: err.message });
// // //   }
// // // };

// // // // 5) All records (admin only)
// // // exports.getAllAttendance = async (req, res) => {
// // //   try {
// // //     const snap = await db.collection(ATT_COL).get();
// // //     const records = snap.docs.map(d=>({ id:d.id, ...d.data() }));
// // //     return res.json(records);
// // //   } catch (err) {
// // //     console.error('getAllAttendance error:', err);
// // //     return res.status(500).json({ error: err.message });
// // //   }
// // // };

// // // // 6) Approve / Reject
// // // exports.approveAttendance = async (req, res) => {
// // //   const { id, status } = req.body;
// // //   try {
// // //     await db.collection(ATT_COL).doc(id).update({
// // //       approvalStatus: status,
// // //       updatedAt:      admin.firestore.FieldValue.serverTimestamp()
// // //     });
// // //     return res.json({ message:`Attendance ${status.toLowerCase()} successfully` });
// // //   } catch (err) {
// // //     console.error('approveAttendance error:', err);
// // //     return res.status(500).json({ error: err.message });
// // //   }
// // // };

// // // // 7) Monthly summary (simple list)
// // // exports.getMonthlySummary = async (req, res) => {
// // //   const { empid, year, month } = req.params;
// // //   try {
// // //     const snap = await db.collection(ATT_COL)
// // //       .where('empid','==',empid)
// // //       .where('date','>=',`${year}-${month}-01`)
// // //       .where('date','<=',`${year}-${month}-31`)
// // //       .get();
// // //     const records = snap.docs.map(d=>({ id:d.id, ...d.data() }));
// // //     return res.json(records);
// // //   } catch (err) {
// // //     console.error('getMonthlySummary error:', err);
// // //     return res.status(500).json({ error: err.message });
// // //   }
// // // };

// // // // 8) Daily roster (admin only)
// // // exports.getDailyRoster = async (req, res) => {
// // //   const date = req.query.date;
// // //   if (!date) {
// // //     return res.status(400).json({ error:'Missing ?date=YYYY-MM-DD' });
// // //   }
// // //   try {
// // //     const empSnap = await db.collection(EMP_COL).get();
// // //     const employees = empSnap.docs.map(d=>d.data());

// // //     const attSnap = await db.collection(ATT_COL)
// // //       .where('date','==',date).get();
// // //     const attByEmp = Object.fromEntries(
// // //       attSnap.docs.map(d=>[d.data().empid,d.data()])
// // //     );

// // //     const roster = employees.map(emp => {
// // //       const rec = attByEmp[emp.empid];
// // //       let raw = 'Absent';
// // //       if (rec?.approvalStatus==='Approved' && !rec.checkIn) raw='Leave';
// // //       else if (rec?.checkIn) raw = rec.checkIn > '09:00' ? 'Late':'Present';

// // //       return {
// // //         empid:      emp.empid,
// // //         name:       emp.name,
// // //         shiftGroup: emp.shiftGroup,
// // //         status:     (raw==='Present'||raw==='Late') ? 'active':'inactive'
// // //       };
// // //     });
// // //     return res.json(roster);

// // //   } catch (err) {
// // //     console.error('getDailyRoster error:', err);
// // //     return res.status(500).json({ error: err.message });
// // //   }
// // // };

// // // // ===================== NEW: RANGE SUMMARY (admin) =====================
// // // /**
// // //  * GET /api/attendance/range-summary?start=YYYY-MM-DD&end=YYYY-MM-DD
// // //  * Returns:
// // //  *  counts: {
// // //  *    activeEmployees, onLeave, checkedIn, absent,
// // //  *    lateCheckIn, earlyCheckOut, halfDay, present, holiday, weekOff
// // //  *  }
// // //  *  rows: [ { employeeId, employeeName, shift, date, checkIn, checkOut, department, attendance, workedHours, late, early, approval } ]
// // //  * - activeEmployees from employees.status == 'active'
// // //  * - onLeave is the number of leave-days in the window (approved leaves)
// // //  * - present counts only attendance with approvalStatus == 'Approved'
// // //  * - late/early/half-day computed from shift times (group)
// // //  */
// // // exports.getRangeSummary = async (req, res) => {
// // //   try {
// // //     const start = String(req.query.start || '').slice(0,10);
// // //     const end   = String(req.query.end   || '').slice(0,10);
// // //     if (!start || !end || new Date(end) < new Date(start)) {
// // //       return res.status(400).json({ error: 'Provide ?start=YYYY-MM-DD&end=YYYY-MM-DD' });
// // //     }

// // //     // Employees
// // //     const empSnap = await db.collection(EMP_COL).get();
// // //     const employees = empSnap.docs.map(d => d.data());
// // //     const empById   = Object.fromEntries(employees.map(e => [e.empid, e]));

// // //     const activeEmployees = employees.filter(e => String(e.status||'').toLowerCase()==='active').length;

// // //     // Shifts
// // //     const shiftsSnap = await db.collection(SHIFT_COL).get();
// // //     const shiftByGroup = Object.fromEntries(shiftsSnap.docs.map(d => [d.data().group, d.data()]));

// // //     // Attendance in window
// // //     const attSnap = await db.collection(ATT_COL)
// // //       .where('date','>=',start).where('date','<=',end).get();
// // //     const attByEmpDate = {};
// // //     attSnap.forEach(doc => {
// // //       const a = doc.data();
// // //       attByEmpDate[`${a.empid}|${a.date}`] = { id: doc.id, ...a };
// // //     });

// // //     // Approved leaves (build set of leave days inside range)
// // //     const leavesSnap = await db.collection(LEAVE_COL).get();
// // //     const approvedLeaves = leavesSnap.docs
// // //       .map(d => d.data())
// // //       .filter(L => String(L.approvalStatus ?? L.status ?? 'Pending').toLowerCase()==='approved')
// // //       .map(L => ({
// // //         empid: L.empid,
// // //         type:  String(L.type||''),
// // //         start: toISO(L.startDate || L.selectDate || L.date),
// // //         end:   toISO(L.endDate   || L.selectDate || L.date || L.startDate),
// // //       }));

// // //     const leaveDays = new Set(); // empid|YYYY-MM-DD
// // //     let onLeaveCount = 0;
// // //     for (const L of approvedLeaves) {
// // //       if (!L.start) continue;
// // //       const s = L.start, e = L.end || L.start;
// // //       if (e < start || s > end) continue;
// // //       for (const d of eachYMD( (s<start?start:s), (e>end?end:e) )) {
// // //         leaveDays.add(`${L.empid}|${d}`); onLeaveCount++;
// // //       }
// // //     }

// // //     // Totals
// // //     let checkedIn=0, absent=0, lateIn=0, earlyOut=0, halfDay=0, presentApproved=0, holiday=0, weekOff=0;

// // //     const rows = [];
// // //     const dates = eachYMD(start, end);
// // //     for (const ymd of dates) {
// // //       const isHoliday = HOLIDAYS_SET.has(ymd);
// // //       const isWO = isSunday(ymd);
// // //       if (isHoliday) holiday++;
// // //       if (isWO) weekOff++;

// // //       for (const emp of employees) {
// // //         const key   = `${emp.empid}|${ymd}`;
// // //         const att   = attByEmpDate[key] || null;
// // //         const shift = shiftByGroup[emp.shiftGroup] || { startTime: '09:00', endTime: '18:00' };
// // //         const startT = shift.startTime || '09:00';
// // //         const endT   = shift.endTime   || '18:00';
// // //         const mid    = midpointHHMM(startT, endT);

// // //         let status = 'Absent';
// // //         let isLate=false, isEarly=false;

// // //         if (isHoliday) {
// // //           status = 'Holiday';
// // //         } else if (isWO) {
// // //           status = 'WeekOff';
// // //         } else if (leaveDays.has(key)) {
// // //           status = (approvedLeaves.find(l => l.empid===emp.empid && l.start<=ymd && ymd<= (l.end||l.start) && l.type.toLowerCase().includes('half')))
// // //                    ? 'Half Day'
// // //                    : 'On Leave';
// // //           if (status==='Half Day') halfDay++;
// // //         } else if (att?.checkIn) {
// // //           checkedIn++;
// // //           status = 'Present';
// // //           if (cmpHHMM(att.checkIn, startT)) { isLate = true; lateIn++; }
// // //           if (att.checkOut && !cmpHHMM(att.checkOut, endT)) { isEarly = true; earlyOut++; }
// // //           if (cmpHHMM(att.checkIn, mid)) { status = 'Half Day'; halfDay++; }
// // //           if (String(att.approvalStatus||'').toLowerCase()==='approved') presentApproved++;
// // //         } else {
// // //           absent++;
// // //         }

// // //         rows.push({
// // //           employeeId:  emp.empid,
// // //           employeeName: emp.name || '',
// // //           shift:       emp.shift || emp.shiftGroup || '',
// // //           date:        ymd,
// // //           checkIn:     att?.checkIn || '-',
// // //           checkOut:    att?.checkOut || '-',
// // //           department:  emp.dept || emp.department || '',
// // //           attendance:  status,
// // //           workedHours: att?.workedHours ? String(att.workedHours) : '-',
// // //           late:        isLate,
// // //           early:       isEarly,
// // //           approval:    att?.approvalStatus || 'Pending'
// // //         });
// // //       }
// // //     }

// // //     return res.json({
// // //       counts: {
// // //         activeEmployees: activeEmployees,
// // //         onLeave: onLeaveCount,
// // //         checkedIn,
// // //         absent,
// // //         lateCheckIn: lateIn,
// // //         earlyCheckOut: earlyOut,
// // //         halfDay,
// // //         present: presentApproved,
// // //         holiday,
// // //         weekOff
// // //       },
// // //       rows
// // //     });
// // //   } catch (err) {
// // //     console.error('getRangeSummary error:', err);
// // //     return res.status(500).json({ error: err.message });
// // //   }
// // // };

// // // // ===================== NEW: MONTH-VIEW AGGREGATOR (fixed) =====================
// // // /**
// // //  * GET /api/attendance/month-view/:empid/:year/:month
// // //  * Returns:
// // //  *  - dayStatuses: { 'YYYY-MM-DD': 'Present'|'Absent'|'Leave'|'Holiday'|'WeekOff'|'HalfDay' }
// // //  *  - totals: { present, absent, leave, holiday, weekOff, halfDay }
// // //  *  - extras: { lateCheckin, earlyCheckout, permissionCount }
// // //  *  Uses precedence: Holiday > WeekOff > Leave > Present > Absent
// // //  *  HalfDay is either explicit half-day leave or check-in after shift midpoint.
// // //  *  Counts only up to today for the current month (future dates ignored).
// // //  */
// // // exports.getMonthView = async (req, res) => {
// // //   try {
// // //     const { empid, year, month } = req.params;   // month = '08', year = '2025'
// // //     const y = parseInt(year, 10);
// // //     const m = parseInt(month, 10);               // 1..12
// // //     if (!empid || !y || !m) {
// // //       return res.status(400).json({ error: 'Bad params' });
// // //     }

// // //     const first = `${year}-${month}-01`;
// // //     const last  = `${year}-${month}-${pad2(daysInMonth(y, m))}`;

// // //     // Helpers to normalize leave dates
// // //     const toISODate = (v) => {
// // //       try {
// // //         if (!v) return '';
// // //         if (typeof v === 'string') return v.slice(0, 10);
// // //         if (v.toDate && typeof v.toDate === 'function') {
// // //           return v.toDate().toISOString().slice(0, 10);
// // //         }
// // //         const d = new Date(v);
// // //         if (!Number.isNaN(d.getTime())) return d.toISOString().slice(0, 10);
// // //       } catch (_) {}
// // //       return '';
// // //     };
// // //     const isApproved = (l) => {
// // //       const s = String(l.approvalStatus || l.status || '').trim().toLowerCase();
// // //       return s === 'approved';
// // //     };

// // //     // Load employee & shift
// // //     const empSnap = await db.collection(EMP_COL).where('empid','==',empid).limit(1).get();
// // //     if (empSnap.empty) return res.status(404).json({ error:'Employee not found' });
// // //     const emp = empSnap.docs[0].data();

// // //     const shiftSnap = await db.collection(SHIFT_COL).where('group','==',emp.shiftGroup).limit(1).get();
// // //     const shift = shiftSnap.empty ? {} : shiftSnap.docs[0].data();
// // //     const shiftStart = shift.startTime || '09:00';
// // //     const shiftEnd   = shift.endTime   || '18:00';
// // //     const mid        = midpointHHMM(shiftStart, shiftEnd);

// // //     // Attendance for month
// // //     const attSnap = await db.collection(ATT_COL)
// // //       .where('empid','==',empid)
// // //       .where('date','>=',first)
// // //       .where('date','<=',last)
// // //       .get();
// // //     const attByDate = Object.fromEntries(attSnap.docs.map(d => [d.data().date, d.data()]));

// // //     // Leaves (Approved only), normalize date range
// // //     const leavesSnap = await db.collection(LEAVE_COL).where('empid','==',empid).get();

// // //     const rangeLeaves = [];   // [{start:'YYYY-MM-DD', end:'YYYY-MM-DD', isHalf:boolean}]
// // //     let permissionCount = 0;  // approved "permission time" in window

// // //     leavesSnap.forEach(doc => {
// // //       const l = doc.data();
// // //       if (!isApproved(l)) return;

// // //       const type = String(l.type || '').toLowerCase();

// // //       // Normalize dates (any one of these may be present)
// // //       const sdStr = toISODate(l.startDate || l.selectDate || l.date);
// // //       const edStr = toISODate(l.endDate   || l.selectDate || l.date || l.startDate);

// // //       if (type.includes('permission')) {
// // //         // Count approved permission-time inside month window
// // //         if ((sdStr && sdStr >= first && sdStr <= last) ||
// // //             (edStr && edStr >= first && edStr <= last)) {
// // //           permissionCount += 1;
// // //         }
// // //         return; // do not mark day as Leave
// // //       }

// // //       if (!sdStr) return;          // must have at least a start day
// // //       const start = sdStr;
// // //       const end   = edStr || sdStr;

// // //       // Skip if fully outside month
// // //       if (end < first || start > last) return;

// // //       rangeLeaves.push({ start, end, isHalf: type.includes('half') });
// // //     });

// // //     // Optional holiday set
// // //     const holidaySet = new Set(HOLIDAYS_SET);

// // //     // Build day-by-day statuses
// // //     const dayStatuses = {};
// // //     let present=0, absent=0, leave=0, holiday=0, weekOff=0, halfDay=0, late=0, early=0;

// // //     const todayYMD = toYMD(new Date());
// // //     const stopAt = (year === todayYMD.slice(0,4) && month === todayYMD.slice(5,7))
// // //       ? todayYMD
// // //       : last;

// // //     for (let d=1; d<=daysInMonth(y,m); d++){
// // //       const ymd = `${year}-${month}-${pad2(d)}`;
// // //       if (ymd > stopAt) continue;

// // //       let status;

// // //       if (holidaySet.has(ymd)) {
// // //         status = 'Holiday'; holiday++;
// // //       } else if (isSunday(ymd)) {
// // //         status = 'WeekOff'; weekOff++;
// // //       } else {
// // //         // Approved leave?
// // //         const lv = rangeLeaves.find(l => l.start <= ymd && ymd <= l.end);
// // //         if (lv) {
// // //           if (lv.isHalf) { status = 'HalfDay'; halfDay++; }
// // //           else           { status = 'Leave';   leave++;   }
// // //         } else {
// // //           const rec = attByDate[ymd];
// // //           if (rec && rec.checkIn) {
// // //             status = 'Present'; present++;

// // //             if (cmpHHMM(rec.checkIn, shiftStart)) late++;
// // //             if (rec.checkOut && !cmpHHMM(rec.checkOut, shiftEnd)) early++;

// // //             // Half-day if checked in after midpoint
// // //             if (cmpHHMM(rec.checkIn, mid)) {
// // //               status = 'HalfDay';
// // //               halfDay++;
// // //               present--; // convert that present day into half-day
// // //             }
// // //           } else {
// // //             status = 'Absent'; absent++;
// // //           }
// // //         }
// // //       }

// // //       dayStatuses[ymd] = status;
// // //     }

// // //     return res.json({
// // //       empid,
// // //       month: `${year}-${month}`,
// // //       shift: { group: emp.shiftGroup, startTime: shiftStart, endTime: shiftEnd, midpoint: mid },
// // //       dayStatuses,
// // //       totals: { present, absent, leave, holiday, weekOff, halfDay },
// // //       extras: { lateCheckin: late, earlyCheckout: early, permissionCount }
// // //     });

// // //   } catch (err) {
// // //     console.error('getMonthView error:', err);
// // //     return res.status(500).json({ error: err.message });
// // //   }
// // // };

// // // // ===================== NEW: USER-SCOPED "MY REQUESTS" =====================
// // // /**
// // //  * GET /api/attendance/my-requests?status=Pending|Approved|Rejected|All&start=YYYY-MM-DD&end=YYYY-MM-DD
// // //  * Returns current user's own approval cards (attendance + leaves).
// // //  * No admin role required; protected by verifyToken to set req.user.empid.
// // //  */
// // // exports.listMyRequests = async (req, res) => {
// // //   try {
// // //     const empid = req.user?.empid;
// // //     if (!empid) return res.status(401).json({ message: 'Unauthorized' });

// // //     const statusQ = String(req.query.status || 'All');   // Pending|Approved|Rejected|All
// // //     const wantStatus = statusQ.toLowerCase();
// // //     const start = req.query.start || null;               // YYYY-MM-DD
// // //     const end   = req.query.end   || null;

// // //     // Load shifts (for late/early inference)
// // //     const shiftsSnap = await db.collection(SHIFT_COL).get();
// // //     const shiftByGroup = {};
// // //     shiftsSnap.forEach(d => { const s = d.data(); shiftByGroup[s.group] = s; });

// // //     // Employee (for shift group)
// // //     let emp = null;
// // //     const eSnap = await db.collection(EMP_COL).where('empid','==',empid).limit(1).get();
// // //     if (!eSnap.empty) emp = eSnap.docs[0].data();

// // //     const out = [];

// // //     // ------------ A) Attendance items for this empid ------------
// // //     let attRef = db.collection(ATT_COL).where('empid','==',empid);
// // //     if (start) attRef = attRef.where('date', '>=', start);
// // //     if (end)   attRef = attRef.where('date', '<=', end);
// // //     const attSnap = await attRef.get();

// // //     attSnap.forEach(doc => {
// // //       const a = doc.data();
// // //       const shift = shiftByGroup[emp?.shiftGroup] || {};
// // //       const startTime = shift.startTime || '09:00';
// // //       const endTime   = shift.endTime   || '18:00';

// // //       let subType = null;
// // //       if (a.checkIn  && a.checkIn  > startTime) subType = 'Late check in';
// // //       else if (a.checkOut && a.checkOut > endTime) subType = 'Late check out';
// // //       else if (a.checkOut && a.checkOut < endTime) subType = 'Early check out';

// // //       // Only include items that actually have an approvalStatus (your system uses this)
// // //       const sNorm = String(a.approvalStatus || 'Pending').toLowerCase();
// // //       if (wantStatus !== 'all' && sNorm !== wantStatus) return;

// // //       out.push({
// // //         source: 'attendance',
// // //         requestId: doc.id,
// // //         type: subType || 'Attendance',
// // //         empid: a.empid,
// // //         name: a.name || '',
// // //         requestDate: a.date,
// // //         requestTime: subType === 'Late check in' ? (a.checkIn || '')
// // //                     : (subType === 'Late check out' || subType === 'Early check out') ? (a.checkOut || '')
// // //                     : '',
// // //         reason: a.reason || '-',
// // //         location: a.location || '-',
// // //         latitude: a.latitude || null,
// // //         longitude: a.longitude || null,
// // //         status: a.approvalStatus || 'Pending',
// // //       });
// // //     });

// // //     // ------------ B) Leaves created by this empid ------------
// // //     let leaveRef = db.collection(LEAVE_COL).where('empid','==',empid);
// // //     const leaveSnap = await leaveRef.get();

// // //     leaveSnap.forEach(doc => {
// // //       const L = doc.data();
// // //       const sNorm = String(L.approvalStatus ?? L.status ?? 'Pending').toLowerCase();
// // //       if (wantStatus !== 'all' && sNorm !== wantStatus) return;

// // //       const dStart = toISO(L.startDate || L.date || L.selectDate);
// // //       const dEnd   = toISO(L.endDate   || dStart);
// // //       if (start && dEnd   && dEnd   < start) return;
// // //       if (end   && dStart && dStart > end)   return;

// // //       out.push({
// // //         source: 'leaves',
// // //         requestId: doc.id,
// // //         type: mapLeaveType(L.type),
// // //         empid: L.empid,
// // //         name: L.name || '',
// // //         requestDate: dStart || '',
// // //         requestTime: L.time || '',
// // //         reason: L.reason || '-',
// // //         location: L.location || '-',
// // //         latitude: L.latitude || null,
// // //         longitude: L.longitude || null,
// // //         status: L.approvalStatus ?? L.status ?? 'Pending',
// // //       });
// // //     });

// // //     // newest first
// // //     out.sort((a,b)=> String(b.requestDate||'').localeCompare(String(a.requestDate||'')));

// // //     return res.json(out);
// // //   } catch (err) {
// // //     console.error('listMyRequests error:', err);
// // //     return res.status(500).json({ error: err.message });
// // //   }
// // // };

// // // // ===================== NEW: ADMIN APPROVAL LIST & DECISION =====================

// // // /**
// // //  * GET /api/attendance/approvals?type=Late%20check%20in|Late%20check%20out|Leave%20Type|Permission|Over%20Time|Half%20Day%20Leave|Comp%20Off|All&status=Pending|Approved|Rejected|All&start=YYYY-MM-DD&end=YYYY-MM-DD
// // //  * Lists normalized approval cards across attendance (late in/out) and leaves.
// // //  * Only this handler is changed; others remain intact for integration.
// // //  */
// // // exports.listApprovalRequests = async (req, res) => {
// // //   try {
// // //     const typeQRaw = String(req.query.type || 'All');
// // //     const typeQ    = typeQRaw.toLowerCase();
// // //     const statusQ  = String(req.query.status || 'Pending');
// // //     const statusWanted = statusQ.toLowerCase();
// // //     const start    = req.query.start || null;   // YYYY-MM-DD
// // //     const end      = req.query.end   || null;   // YYYY-MM-DD

// // //     // load employees → quick lookups for name/dept/shiftGroup
// // //     const empSnap = await db.collection(EMP_COL).get();
// // //     const empById = {};
// // //     empSnap.forEach(d => { const e = d.data(); empById[e.empid] = e; });

// // //     // load shifts by group (for start/end inference on attendance)
// // //     const shiftsSnap  = await db.collection(SHIFT_COL).get();
// // //     const shiftByGroup = {};
// // //     shiftsSnap.forEach(d => { const s = d.data(); shiftByGroup[s.group] = s; });

// // //     const out = [];

// // //     // ---------- helpers ----------
// // //     const toISOx = (v) => {
// // //       try {
// // //         if (!v) return '';
// // //         if (typeof v === 'string') return v.slice(0, 10);
// // //         if (v.toDate && typeof v.toDate === 'function') return v.toDate().toISOString().slice(0, 10);
// // //         const d = new Date(v); return d.toISOString().slice(0, 10);
// // //       } catch { return ''; }
// // //     };
// // //     const overlaps = (aStart, aEnd, bStart, bEnd) => {
// // //       if (!aStart && !aEnd) return true; // no filter → always ok
// // //       const A1 = aStart || '0000-01-01';
// // //       const A2 = aEnd   || '9999-12-31';
// // //       const B1 = bStart || bEnd || '';
// // //       const B2 = bEnd   || bStart || '';
// // //       if (!B1) return true; // leave has no date → include
// // //       return (B1 <= A2) && (B2 >= A1);
// // //     };
// // //     const mapLeaveType = (txt) => {
// // //       const t = String(txt || '').toLowerCase();
// // //       if (t.includes('permission')) return 'Permission';
// // //       if (t.includes('over'))       return 'Over Time';
// // //       if (t.includes('half'))       return 'Half Day Leave';
// // //       if (t.includes('comp'))       return 'Comp Off';
// // //       return 'Leave Type';
// // //     };

// // //     // ----- A) Attendance: late check in / late check out -----
// // //     let attRef = db.collection(ATT_COL);
// // //     if (statusWanted !== 'all') attRef = attRef.where('approvalStatus', '==', statusQ);
// // //     if (start) attRef = attRef.where('date', '>=', start);
// // //     if (end)   attRef = attRef.where('date', '<=', end);

// // //     const attSnap = await attRef.get();
// // //     attSnap.forEach(doc => {
// // //       const a = doc.data();
// // //       const emp   = empById[a.empid] || {};
// // //       const shift = shiftByGroup[emp.shiftGroup] || {};
// // //       const startTime = shift.startTime || '09:00';
// // //       const endTime   = shift.endTime   || '18:00';

// // //       let subType = null;
// // //       if (a.checkIn  && a.checkIn  > startTime) subType = 'late check in';
// // //       else if (a.checkOut && a.checkOut > endTime) subType = 'late check out';

// // //       if (!subType) return; // ignore normal attendance
// // //       if (typeQ !== 'all' && typeQ !== subType) return;

// // //       out.push({
// // //         source: 'attendance',
// // //         requestId: doc.id,
// // //         type: subType === 'late check in' ? 'Late check in' : 'Late check out',
// // //         empid: a.empid,
// // //         name: emp.name || a.name || '',
// // //         department: emp.dept || emp.department || '',
// // //         shift: emp.shift || shift.shift || null,
// // //         shiftGroup: emp.shiftGroup || '',
// // //         requestTime: subType === 'late check in' ? (a.checkIn || '') : (a.checkOut || ''),
// // //         requestDate: a.date,
// // //         reason: '-', // static for now
// // //         location: a.location || '-',
// // //         latitude: a.latitude || null,
// // //         longitude: a.longitude || null,
// // //         status: a.approvalStatus || 'Pending',
// // //       });
// // //     });

// // //     // ----- B) Leaves: Leave Type / Permission / Over Time / Half Day Leave / Comp Off -----
// // //     // Fetch all leaves and filter locally so we can normalize status (approvalStatus | status, any casing)
// // //     const leaveSnap = await db.collection(LEAVE_COL).get();

// // //     leaveSnap.forEach(doc => {
// // //       const L   = doc.data();
// // //       const emp = empById[L.empid] || {};

// // //       // normalize status; default Pending
// // //       const sNorm = String(L.approvalStatus ?? L.status ?? 'Pending').toLowerCase();
// // //       if (statusWanted !== 'all' && sNorm !== statusWanted) return;

// // //       const friendlyType = mapLeaveType(L.type);
// // //       if (typeQ !== 'all' && typeQ !== friendlyType.toLowerCase()) return;

// // //       // normalize date range and respect ?start/?end overlap if provided
// // //       const dStart = toISOx(L.startDate || L.date || L.selectDate);
// // //       const dEnd   = toISOx(L.endDate   || dStart);
// // //       if (!overlaps(start, end, dStart, dEnd)) return;

// // //       out.push({
// // //         source: 'leaves',
// // //         requestId: doc.id,
// // //         type: friendlyType,
// // //         empid: L.empid,
// // //         name: emp.name || L.name || '',
// // //         department: emp.dept || emp.department || L.department || '',
// // //         shift: emp.shift || null,
// // //         shiftGroup: emp.shiftGroup || '',
// // //         requestTime: L.time || L.requestTime || '',
// // //         requestDate: dStart || '',          // primary day shown on card
// // //         reason: L.reason || '-',
// // //         location: L.location || '-',
// // //         latitude: L.latitude || null,
// // //         longitude: L.longitude || null,
// // //         status: L.approvalStatus ?? L.status ?? 'Pending',
// // //       });
// // //     });

// // //     // newest first by requestDate if present
// // //     out.sort((a, b) => String(b.requestDate || '').localeCompare(String(a.requestDate || '')));

// // //     return res.json(out);
// // //   } catch (err) {
// // //     console.error('listApprovalRequests error:', err);
// // //     return res.status(500).json({ error: err.message });
// // //   }
// // // };


// // // /**
// // //  * POST /api/attendance/approvals/decision
// // //  * Body:
// // //  *  {
// // //  *    "source": "attendance" | "leaves",
// // //  *    // attendance:
// // //  *    "attendanceId": "docId"  OR  ("empid": "...", "date": "YYYY-MM-DD"),
// // //  *    // leaves:
// // //  *    "leaveId": "docId",
// // //  *    "status": "Approved" | "Rejected",
// // //  *    "remarks": "optional"
// // //  *  }
// // //  * Updates approvalStatus at the correct collection without touching other handlers.
// // //  */
// // // exports.decideApproval = async (req, res) => {
// // //   try {
// // //     const { source, attendanceId, leaveId, empid, date, status, remarks } = req.body || {};
// // //     const clean = String(status || '').trim();
// // //     if (!['Approved','Rejected'].includes(clean)) {
// // //       return res.status(400).json({ error: 'status must be Approved or Rejected' });
// // //     }
// // //     if (!source || !['attendance','leaves'].includes(source)) {
// // //       return res.status(400).json({ error: 'source must be attendance or leaves' });
// // //     }

// // //     if (source === 'attendance') {
// // //       let docRef = null;

// // //       if (attendanceId) {
// // //         docRef = db.collection(ATT_COL).doc(attendanceId);
// // //       } else if (empid && date) {
// // //         const q = await db.collection(ATT_COL)
// // //           .where('empid','==',empid)
// // //           .where('date','==',date)
// // //           .limit(1).get();
// // //         if (q.empty) return res.status(404).json({ error: 'Attendance record not found' });
// // //         docRef = q.docs[0].ref;
// // //       } else {
// // //         return res.status(400).json({ error: 'attendanceId or (empid & date) required' });
// // //       }

// // //       await docRef.update({
// // //         approvalStatus: clean,
// // //         decisionBy: req.user?.empid || null,
// // //         decisionAt: admin.firestore.FieldValue.serverTimestamp(),
// // //         decisionRemarks: remarks || null
// // //       });
// // //       return res.json({ message: `Attendance ${clean.toLowerCase()} successfully` });
// // //     }

// // //     // leaves
// // //     if (!leaveId) return res.status(400).json({ error: 'leaveId required' });
// // //     await db.collection(LEAVE_COL).doc(leaveId).update({
// // //       approvalStatus: clean,
// // //       decisionBy: req.user?.empid || null,
// // //       decisionAt: admin.firestore.FieldValue.serverTimestamp(),
// // //       decisionRemarks: remarks || null
// // //     });
// // //     return res.json({ message: `Leave ${clean.toLowerCase()} successfully` });

// // //   } catch (err) {
// // //     console.error('decideApproval error:', err);
// // //     return res.status(500).json({ error: err.message });
// // //   }
// // // };
// // const admin = require('firebase-admin');
// // const db = require('../config/firebase').db;

// // const EMP_COL   = 'employees';
// // const ATT_COL   = 'attendance';
// // const LEAVE_COL = 'leaves';
// // const SHIFT_COL = 'shifts';

// // /** ---------- helpers ---------- */
// // function pad2(n){ return String(n).padStart(2,'0'); }
// // function toYMD(d = new Date()) {
// //   const ist = new Date(d.getTime() + 5.5 * 60 * 60 * 1000);
// //   return ist.toISOString().slice(0, 10);
// // }
// // function daysInMonth(year, month){ return new Date(year, month, 0).getDate(); } // month: 1..12
// // function isSunday(ymd){ return new Date(ymd).getDay() === 0; } // 0=Sun
// // function cmpHHMM(a,b){ return (a||'00:00') > (b||'00:00'); }
// // function midpointHHMM(start, end){
// //   const [h1,m1] = (start||'00:00').split(':').map(Number);
// //   const [h2,m2] = (end  ||'23:59').split(':').map(Number);
// //   const s1 = h1*3600+m1*60, s2 = h2*3600+m2*60;
// //   const mid = Math.floor((s1+s2)/2);
// //   const mh = Math.floor(mid/3600), mm = Math.floor((mid%3600)/60);
// //   return `${pad2(mh)}:${pad2(mm)}`;
// // }
// // function toISO(v){
// //   try{
// //     if(!v) return '';
// //     if (typeof v === 'string') return v.slice(0,10);
// //     if (v.toDate && typeof v.toDate === 'function') return v.toDate().toISOString().slice(0,10);
// //     const d = new Date(v); return d.toISOString().slice(0,10);
// //   }catch{ return ''; }
// // }
// // function eachYMD(start,end){
// //   const out=[]; const d=new Date(start);
// //   for(;;){ const ymd=d.toISOString().slice(0,10); out.push(ymd); if(ymd===end) break; d.setDate(d.getDate()+1); }
// //   return out;
// // }

// // /** Holidays placeholder (replace with real rules if you have them) */
// // const HOLIDAYS_SET = new Set([]);

// // /** 0) Get current user */
// // exports.getCurrentUser = async (req, res) => {
// //   try {
// //     const empid = req.user.empid;
// //     const snap = await db.collection(EMP_COL)
// //       .where('empid', '==', empid)
// //       .limit(1).get();

// //     if (snap.empty) return res.status(404).json({ error: 'Employee not found' });
// //     const d = snap.docs[0].data();
// //     return res.json({
// //       empid: d.empid,
// //       name:  d.name,
// //       role:  req.user.role,
// //       shiftGroup: d.shiftGroup
// //     });
// //   } catch (err) {
// //     console.error('getCurrentUser error:', err);
// //     return res.status(500).json({ error: err.message });
// //   }
// // };

// // /** 1) Check-in */
// // exports.checkIn = async (req, res) => {
// //   const { empid, name, location } = req.body;
// //   if (!empid || !name || !location) {
// //      return res.status(400).json({ error: 'empid, name and location are required' });
// //   }
// //   const today = new Date().toISOString().slice(0, 10);
// //   try {
// //     const snap = await db.collection(ATT_COL)
// //       .where('empid','==',empid)
// //       .where('date','==',today)
// //       .get();

// //     if (!snap.empty) {
// //       const doc = snap.docs[0];
// //       if (doc.data().checkIn) {
// //         return res.status(400).json({ error:'Already checked in today' });
// //       }
// //       await doc.ref.update({
// //         checkIn:        new Date().toLocaleTimeString('en-GB'),
// //         location,
// //         status:         'Present',
// //         approvalStatus: 'Pending',
// //         updatedAt:      admin.firestore.FieldValue.serverTimestamp()
// //       });
// //       return res.json({ message:'Check-in updated' });
// //     }

// //     await db.collection(ATT_COL).add({
// //       empid,
// //       name,
// //       date:           today,
// //       checkIn:        new Date().toLocaleTimeString('en-GB'),
// //       location,
// //       status:         'Present',
// //       approvalStatus: 'Pending',
// //       createdAt:      admin.firestore.FieldValue.serverTimestamp(),
// //       updatedAt:      admin.firestore.FieldValue.serverTimestamp()
// //     });
// //     return res.json({ message:'Checked-in successfully' });

// //   } catch (err) {
// //     console.error('checkIn error:', err);
// //     return res.status(500).json({ error: err.message });
// //   }
// // };

// // /** 2) Check-out */
// // exports.checkOut = async (req, res) => {
// //   const { empid, location } = req.body;
// //   if (!empid || !location) {
// //     return res.status(400).json({ error: 'empid and location are required' });
// //   }
// //   const today = new Date().toISOString().slice(0, 10);
// //   try {
// //     const snap = await db.collection(ATT_COL)
// //       .where('empid','==',empid)
// //       .where('date','==',today)
// //       .get();
// //     if (snap.empty) {
// //       return res.status(400).json({ error:'You need to check in first' });
// //     }
// //     const doc = snap.docs[0];
// //     if (doc.data().checkOut) {
// //       return res.status(400).json({ error:'Already checked out today' });
// //     }
// //     await doc.ref.update({
// //       checkOut:   new Date().toLocaleTimeString('en-GB'),
// //       location,
// //       updatedAt:  admin.firestore.FieldValue.serverTimestamp()
// //     });

// //     // mark employee inactive on checkout
// //     const empSnap = await db.collection(EMP_COL)
// //       .where('empid','==',empid)
// //       .limit(1).get();
// //     if (!empSnap.empty) {
// //       await empSnap.docs[0].ref.update({
// //         status:    'inactive',
// //         updatedAt: admin.firestore.FieldValue.serverTimestamp()
// //       });
// //     }

// //     return res.json({ message:'Checked-out & set inactive' });
// //   } catch (err) {
// //     console.error('checkOut error:', err);
// //     return res.status(500).json({ error: err.message });
// //   }
// // };

// // /** 3) Live Attendance */
// // exports.getLiveAttendance = async (req, res) => {
// //   const today = new Date().toISOString().slice(0, 10);
// //   const isAdmin = req.user.role === 'admin';

// //   try {
// //     // a) Load employees
// //     let employees;
// //     if (isAdmin) {
// //       const empSnap = await db.collection(EMP_COL).get();
// //       employees = empSnap.docs.map(d => d.data());
// //     } else {
// //       const empSnap = await db.collection(EMP_COL)
// //         .where('empid','==',req.user.empid)
// //         .limit(1).get();
// //       if (empSnap.empty) return res.json([]);
// //       employees = [empSnap.docs[0].data()];
// //     }

// //     // b) Attendance map
// //     const attSnap = await db.collection(ATT_COL)
// //       .where('date','==',today)
// //       .get();
// //     const attMap = Object.fromEntries(attSnap.docs.map(d => [d.data().empid, d.data()]));

// //     // c) Approved leaves including today
// //     const leaveSnap = await db.collection(LEAVE_COL)
// //       .where('approvalStatus','==','Approved')
// //       .where('startDate','<=',today)
// //       .get();
// //     const validLeaves = leaveSnap.docs
// //       .map(d=>d.data())
// //       .filter(l => (toISO(l.endDate) || toISO(l.startDate)) >= today)
// //       .map(l=>l.empid);
// //     const leaveSet = new Set(validLeaves);

// //     // d) Shifts
// //     const shiftsSnap = await db.collection(SHIFT_COL).get();
// //     const shiftByGroup = Object.fromEntries(shiftsSnap.docs.map(d=>[d.data().group, d.data()]));

// //     // e) basic holiday/weekoff flags
// //     const isHoliday = HOLIDAYS_SET.has(today);
// //     const isWeekOff = isSunday(today);

// //     // f) Build response
// //     const result = employees.map(emp => {
// //       const rec = attMap[emp.empid];
// //       let status, isLate=false, isEarly=false;
// //       let permissionCount = Array.isArray(rec?.permissionRequests)
// //         ? rec.permissionRequests.length
// //         : (rec?.permissionRequest?1:0);

// //       if (isHoliday)      status='Holiday';
// //       else if (isWeekOff) status='WeekOff';
// //       else if (leaveSet.has(emp.empid)) status='Leave';
// //       else if (rec?.checkIn) {
// //         status='Present';
// //         const shift = shiftByGroup[emp.shiftGroup] || {};
// //         const start = shift.startTime || '00:00';
// //         const end   = shift.endTime   || '23:59';
// //         isLate  = rec.checkIn  > start;
// //         isEarly = rec.checkOut && rec.checkOut < end;
// //       } else {
// //         status='Absent';
// //       }

// //       // half-day heuristic
// //       let isHalfDay = false;
// //       if (status==='Present' && shiftByGroup[emp.shiftGroup]) {
// //         const [h1,m1] = shiftByGroup[emp.shiftGroup].startTime.split(':').map(Number);
// //         const [h2,m2] = shiftByGroup[emp.shiftGroup].endTime.split(':').map(Number);
// //         const midSec = ((h1*3600+m1*60)+(h2*3600+m2*60))/2;
// //         const inSec  = rec && rec.checkIn
// //           ? rec.checkIn.split(':').reduce((a,v,i)=> a + v*(i===0?3600:60),0)
// //           : 0;
// //         isHalfDay = inSec > midSec;
// //       }

// //       return {
// //         empid:          emp.empid,
// //         name:           emp.name,
// //         shiftGroup:     emp.shiftGroup,
// //         date:           today,
// //         status,
// //         checkIn:        rec?.checkIn  || null,
// //         checkOut:       rec?.checkOut || null,
// //         late:           isLate,
// //         early:          isEarly,
// //         permissionCount,
// //         leave:          status==='Leave',
// //         holiday:        status==='Holiday',
// //         weekOff:        status==='WeekOff',
// //         halfDay:        isHalfDay
// //       };
// //     });

// //     return res.json(result);

// //   } catch (err) {
// //     console.error('getLiveAttendance error:', err);
// //     return res.status(500).json({ error: err.message });
// //   }
// // };

// // /** 4) Employee history */
// // exports.getEmployeeAttendance = async (req, res) => {
// //   const { empid } = req.params;
// //   try {
// //     const snap = await db.collection(ATT_COL)
// //       .where('empid','==',empid)
// //       .orderBy('date','desc').get();
// //     const records = snap.docs.map(d=>({ id:d.id, ...d.data() }));
// //     return res.json(records);
// //   } catch (err) {
// //     console.error('getEmployeeAttendance error:', err);
// //     return res.status(500).json({ error: err.message });
// //   }
// // };

// // /** 5) All records (admin) */
// // exports.getAllAttendance = async (req, res) => {
// //   try {
// //     const snap = await db.collection(ATT_COL).get();
// //     const records = snap.docs.map(d=>({ id:d.id, ...d.data() }));
// //     return res.json(records);
// //   } catch (err) {
// //     console.error('getAllAttendance error:', err);
// //     return res.status(500).json({ error: err.message });
// //   }
// // };

// // /** 6) Approve / Reject attendance */
// // exports.approveAttendance = async (req, res) => {
// //   const { id, status } = req.body;
// //   try {
// //     await db.collection(ATT_COL).doc(id).update({
// //       approvalStatus: status,
// //       updatedAt:      admin.firestore.FieldValue.serverTimestamp()
// //     });
// //     return res.json({ message:`Attendance ${status.toLowerCase()} successfully` });
// //   } catch (err) {
// //     console.error('approveAttendance error:', err);
// //     return res.status(500).json({ error: err.message });
// //   }
// // };

// // /** 7) Monthly summary list */
// // exports.getMonthlySummary = async (req, res) => {
// //   const { empid, year, month } = req.params;
// //   try {
// //     const snap = await db.collection(ATT_COL)
// //       .where('empid','==',empid)
// //       .where('date','>=',`${year}-${month}-01`)
// //       .where('date','<=',`${year}-${month}-31`)
// //       .get();
// //     const records = snap.docs.map(d=>({ id:d.id, ...d.data() }));
// //     return res.json(records);
// //   } catch (err) {
// //     console.error('getMonthlySummary error:', err);
// //     return res.status(500).json({ error: err.message });
// //   }
// // };

// // /** 8) Daily roster (admin) */
// // exports.getDailyRoster = async (req, res) => {
// //   const date = req.query.date;
// //   if (!date) return res.status(400).json({ error:'Missing ?date=YYYY-MM-DD' });
// //   try {
// //     const empSnap = await db.collection(EMP_COL).get();
// //     const employees = empSnap.docs.map(d=>d.data());

// //     const attSnap = await db.collection(ATT_COL).where('date','==',date).get();
// //     const attByEmp = Object.fromEntries(attSnap.docs.map(d=>[d.data().empid,d.data()]));

// //     const roster = employees.map(emp => {
// //       const rec = attByEmp[emp.empid];
// //       let raw = 'Absent';
// //       if (rec?.approvalStatus==='Approved' && !rec.checkIn) raw='Leave';
// //       else if (rec?.checkIn) raw = rec.checkIn > '09:00' ? 'Late':'Present';
// //       return {
// //         empid:      emp.empid,
// //         name:       emp.name,
// //         shiftGroup: emp.shiftGroup,
// //         status:     (raw==='Present'||raw==='Late') ? 'active':'inactive'
// //       };
// //     });
// //     return res.json(roster);
// //   } catch (err) {
// //     console.error('getDailyRoster error:', err);
// //     return res.status(500).json({ error: err.message });
// //   }
// // };

// // /** 9) Range summary (admin) */
// // exports.getRangeSummary = async (req, res) => {
// //   try {
// //     const start = String(req.query.start || '').slice(0,10);
// //     const end   = String(req.query.end   || '').slice(0,10);
// //     if (!start || !end || new Date(end) < new Date(start)) {
// //       return res.status(400).json({ error: 'Provide ?start=YYYY-MM-DD&end=YYYY-MM-DD' });
// //     }

// //     const empSnap = await db.collection(EMP_COL).get();
// //     const employees = empSnap.docs.map(d => d.data());

// //     const activeEmployees = employees.filter(e => String(e.status||'').toLowerCase()==='active').length;

// //     const shiftsSnap = await db.collection(SHIFT_COL).get();
// //     const shiftByGroup = Object.fromEntries(shiftsSnap.docs.map(d => [d.data().group, d.data()]));

// //     const attSnap = await db.collection(ATT_COL)
// //       .where('date','>=',start).where('date','<=',end).get();
// //     const attByEmpDate = {};
// //     attSnap.forEach(doc => { const a = doc.data(); attByEmpDate[`${a.empid}|${a.date}`] = { id: doc.id, ...a }; });

// //     const leavesSnap = await db.collection(LEAVE_COL).get();
// //     const approvedLeaves = leavesSnap.docs
// //       .map(d => d.data())
// //       .filter(L => String(L.approvalStatus ?? L.status ?? 'Pending').toLowerCase()==='approved')
// //       .map(L => ({ empid: L.empid, type: String(L.type||''), start: toISO(L.startDate || L.selectDate || L.date), end: toISO(L.endDate || L.selectDate || L.date || L.startDate) }));

// //     const leaveDays = new Set();
// //     let onLeaveCount = 0;
// //     for (const L of approvedLeaves) {
// //       if (!L.start) continue;
// //       const s = L.start, e = L.end || L.start;
// //       if (e < start || s > end) continue;
// //       for (const d of eachYMD( (s<start?start:s), (e>end?end:e) )) {
// //         leaveDays.add(`${L.empid}|${d}`); onLeaveCount++;
// //       }
// //     }

// //     let checkedIn=0, absent=0, lateIn=0, earlyOut=0, halfDay=0, presentApproved=0, holiday=0, weekOff=0;
// //     const rows = [];
// //     const dates = eachYMD(start, end);

// //     for (const ymd of dates) {
// //       const isHoliday = HOLIDAYS_SET.has(ymd);
// //       const isWO = isSunday(ymd);
// //       if (isHoliday) holiday++;
// //       if (isWO) weekOff++;

// //       for (const emp of employees) {
// //         const key   = `${emp.empid}|${ymd}`;
// //         const att   = attByEmpDate[key] || null;
// //         const shift = shiftByGroup[emp.shiftGroup] || { startTime: '09:00', endTime: '18:00' };
// //         const startT = shift.startTime || '09:00';
// //         const endT   = shift.endTime   || '18:00';
// //         const mid    = midpointHHMM(startT, endT);

// //         let status = 'Absent';
// //         let isLate=false, isEarly=false;

// //         if (isHoliday) {
// //           status = 'Holiday';
// //         } else if (isWO) {
// //           status = 'WeekOff';
// //         } else if (leaveDays.has(key)) {
// //           status = (approvedLeaves.find(l => l.empid===emp.empid && l.start<=ymd && ymd<= (l.end||l.start) && l.type.toLowerCase().includes('half')))
// //                    ? 'Half Day'
// //                    : 'On Leave';
// //           if (status==='Half Day') halfDay++;
// //         } else if (att?.checkIn) {
// //           checkedIn++;
// //           status = 'Present';
// //           if (cmpHHMM(att.checkIn, startT)) { isLate = true; lateIn++; }
// //           if (att.checkOut && !cmpHHMM(att.checkOut, endT)) { isEarly = true; earlyOut++; }
// //           if (cmpHHMM(att.checkIn, mid)) { status = 'Half Day'; halfDay++; }
// //           if (String(att.approvalStatus||'').toLowerCase()==='approved') presentApproved++;
// //         } else {
// //           absent++;
// //         }

// //         rows.push({
// //           employeeId:  emp.empid,
// //           employeeName: emp.name || '',
// //           shift:       emp.shift || emp.shiftGroup || '',
// //           date:        ymd,
// //           checkIn:     att?.checkIn || '-',
// //           checkOut:    att?.checkOut || '-',
// //           department:  emp.dept || emp.department || '',
// //           attendance:  status,
// //           workedHours: att?.workedHours ? String(att.workedHours) : '-',
// //           late:        isLate,
// //           early:       isEarly,
// //           approval:    att?.approvalStatus || 'Pending'
// //         });
// //       }
// //     }

// //     return res.json({
// //       counts: {
// //         activeEmployees: activeEmployees,
// //         onLeave: onLeaveCount,
// //         checkedIn,
// //         absent,
// //         lateCheckIn: lateIn,
// //         earlyCheckOut: earlyOut,
// //         halfDay,
// //         present: presentApproved,
// //         holiday,
// //         weekOff
// //       },
// //       rows
// //     });
// //   } catch (err) {
// //     console.error('getRangeSummary error:', err);
// //     return res.status(500).json({ error: err.message });
// //   }
// // };

// // /** 10) Month view aggregate */
// // exports.getMonthView = async (req, res) => {
// //   try {
// //     const { empid, year, month } = req.params;
// //     const y = parseInt(year, 10);
// //     const m = parseInt(month, 10);
// //     if (!empid || !y || !m) return res.status(400).json({ error: 'Bad params' });

// //     const first = `${year}-${month}-01`;
// //     const last  = `${year}-${month}-${pad2(daysInMonth(y, m))}`;

// //     const empSnap = await db.collection(EMP_COL).where('empid','==',empid).limit(1).get();
// //     if (empSnap.empty) return res.status(404).json({ error:'Employee not found' });
// //     const emp = empSnap.docs[0].data();

// //     const shiftSnap = await db.collection(SHIFT_COL).where('group','==',emp.shiftGroup).limit(1).get();
// //     const shift = shiftSnap.empty ? {} : shiftSnap.docs[0].data();
// //     const shiftStart = shift.startTime || '09:00';
// //     const shiftEnd   = shift.endTime   || '18:00';
// //     const mid        = midpointHHMM(shiftStart, shiftEnd);

// //     const attSnap = await db.collection(ATT_COL)
// //       .where('empid','==',empid)
// //       .where('date','>=',first)
// //       .where('date','<=',last)
// //       .get();
// //     const attByDate = Object.fromEntries(attSnap.docs.map(d => [d.data().date, d.data()]));

// //     const leavesSnap = await db.collection(LEAVE_COL).where('empid','==',empid).get();

// //     const rangeLeaves = [];
// //     let permissionCount = 0;

// //     leavesSnap.forEach(doc => {
// //       const l = doc.data();
// //       const st = String(l.approvalStatus || l.status || '').trim().toLowerCase();
// //       if (st !== 'approved') return;

// //       const type = String(l.type || '').toLowerCase();
// //       const sdStr = toISO(l.startDate || l.selectDate || l.date);
// //       const edStr = toISO(l.endDate   || l.selectDate || l.date || l.startDate);

// //       if (type.includes('permission')) {
// //         if ((sdStr && sdStr >= first && sdStr <= last) ||
// //             (edStr && edStr >= first && edStr <= last)) {
// //           permissionCount += 1;
// //         }
// //         return;
// //       }
// //       if (!sdStr) return;

// //       const start = sdStr;
// //       const end   = edStr || sdStr;
// //       if (end < first || start > last) return;

// //       rangeLeaves.push({ start, end, isHalf: type.includes('half') });
// //     });

// //     const holidaySet = new Set(HOLIDAYS_SET);

// //     const dayStatuses = {};
// //     let present=0, absent=0, leave=0, holiday=0, weekOff=0, halfDay=0, late=0, early=0;

// //     const todayYMD = toYMD(new Date());
// //     const stopAt = (year === todayYMD.slice(0,4) && month === todayYMD.slice(5,7)) ? todayYMD : last;

// //     for (let d=1; d<=daysInMonth(y,m); d++){
// //       const ymd = `${year}-${month}-${pad2(d)}`;
// //       if (ymd > stopAt) continue;

// //       let status;

// //       if (holidaySet.has(ymd)) {
// //         status = 'Holiday'; holiday++;
// //       } else if (isSunday(ymd)) {
// //         status = 'WeekOff'; weekOff++;
// //       } else {
// //         const lv = rangeLeaves.find(l => l.start <= ymd && ymd <= l.end);
// //         if (lv) {
// //           if (lv.isHalf) { status = 'HalfDay'; halfDay++; }
// //           else           { status = 'Leave';   leave++;   }
// //         } else {
// //           const rec = attByDate[ymd];
// //           if (rec && rec.checkIn) {
// //             status = 'Present'; present++;
// //             if (cmpHHMM(rec.checkIn, shiftStart)) late++;
// //             if (rec.checkOut && !cmpHHMM(rec.checkOut, shiftEnd)) early++;
// //             if (cmpHHMM(rec.checkIn, mid)) {
// //               status = 'HalfDay';
// //               halfDay++;
// //               present--;
// //             }
// //           } else {
// //             status = 'Absent'; absent++;
// //           }
// //         }
// //       }

// //       dayStatuses[ymd] = status;
// //     }

// //     return res.json({
// //       empid,
// //       month: `${year}-${month}`,
// //       shift: { group: emp.shiftGroup, startTime: shiftStart, endTime: shiftEnd, midpoint: mid },
// //       dayStatuses,
// //       totals: { present, absent, leave, holiday, weekOff, halfDay },
// //       extras: { lateCheckin: late, earlyCheckout: early, permissionCount }
// //     });

// //   } catch (err) {
// //     console.error('getMonthView error:', err);
// //     return res.status(500).json({ error: err.message });
// //   }
// // };

// // /** 11) Admin Approvals list */
// // exports.listApprovalRequests = async (req, res) => {
// //   try {
// //     const typeQ = String(req.query.type || 'All').toLowerCase();
// //     const statusQ = String(req.query.status || 'Pending');
// //     const statusWanted = statusQ.toLowerCase();
// //     const start = req.query.start || null;
// //     const end   = req.query.end   || null;

// //     const empSnap = await db.collection(EMP_COL).get();
// //     const empById = {};
// //     empSnap.forEach(d => { const e = d.data(); empById[e.empid] = e; });

// //     const shiftsSnap  = await db.collection(SHIFT_COL).get();
// //     const shiftByGroup = {};
// //     shiftsSnap.forEach(d => { const s = d.data(); shiftByGroup[s.group] = s; });

// //     const out = [];
// //     const overlaps = (aStart, aEnd, bStart, bEnd) => {
// //       if (!aStart && !aEnd) return true;
// //       const A1 = aStart || '0000-01-01';
// //       const A2 = aEnd   || '9999-12-31';
// //       const B1 = bStart || bEnd || '';
// //       const B2 = bEnd   || bStart || '';
// //       if (!B1) return true;
// //       return (B1 <= A2) && (B2 >= A1);
// //     };
// //     const mapLeaveType = (txt) => {
// //       const t = String(txt || '').toLowerCase();
// //       if (t.includes('permission')) return 'Permission';
// //       if (t.includes('over'))       return 'Over Time';
// //       if (t.includes('half'))       return 'Half Day Leave';
// //       if (t.includes('comp'))       return 'Comp Off';
// //       return 'Leave Type';
// //     };

// //     // Attendance
// //     let attRef = db.collection(ATT_COL);
// //     if (statusWanted !== 'all') attRef = attRef.where('approvalStatus', '==', statusQ);
// //     if (start) attRef = attRef.where('date', '>=', start);
// //     if (end)   attRef = attRef.where('date', '<=', end);

// //     const attSnap = await attRef.get();
// //     attSnap.forEach(doc => {
// //       const a = doc.data();
// //       const emp   = empById[a.empid] || {};
// //       const shift = shiftByGroup[emp.shiftGroup] || {};
// //       const startTime = shift.startTime || '09:00';
// //       const endTime   = shift.endTime   || '18:00';

// //       let subType = null;
// //       if (a.checkIn  && a.checkIn  > startTime) subType = 'late check in';
// //       else if (a.checkOut && a.checkOut > endTime) subType = 'late check out';
// //       if (!subType) return;
// //       if (typeQ !== 'all' && typeQ !== subType) return;

// //       out.push({
// //         source: 'attendance',
// //         requestId: doc.id,
// //         type: subType === 'late check in' ? 'Late check in' : 'Late check out',
// //         empid: a.empid,
// //         name: emp.name || a.name || '',
// //         department: emp.dept || emp.department || '',
// //         shift: emp.shift || shift.shift || null,
// //         shiftGroup: emp.shiftGroup || '',
// //         requestTime: subType === 'late check in' ? (a.checkIn || '') : (a.checkOut || ''),
// //         requestDate: a.date,
// //         reason: '-',
// //         location: a.location || '-',
// //         latitude: a.latitude || null,
// //         longitude: a.longitude || null,
// //         status: a.approvalStatus || 'Pending',
// //       });
// //     });

// //     // Leaves
// //     const leaveSnap = await db.collection(LEAVE_COL).get();
// //     leaveSnap.forEach(doc => {
// //       const L   = doc.data();
// //       const emp = empById[L.empid] || {};
// //       const sNorm = String(L.approvalStatus ?? L.status ?? 'Pending').toLowerCase();
// //       if (statusWanted !== 'all' && sNorm !== statusWanted) return;

// //       const friendlyType = mapLeaveType(L.type);
// //       if (typeQ !== 'all' && typeQ !== friendlyType.toLowerCase()) return;

// //       const dStart = toISO(L.startDate || L.date || L.selectDate);
// //       const dEnd   = toISO(L.endDate   || dStart);
// //       if (!overlaps(start, end, dStart, dEnd)) return;

// //       out.push({
// //         source: 'leaves',
// //         requestId: doc.id,
// //         type: friendlyType,
// //         empid: L.empid,
// //         name: emp.name || L.name || '',
// //         department: emp.dept || emp.department || L.department || '',
// //         shift: emp.shift || null,
// //         shiftGroup: emp.shiftGroup || '',
// //         requestTime: L.time || L.requestTime || '',
// //         requestDate: dStart || '',
// //         reason: L.reason || '-',
// //         location: L.location || '-',
// //         latitude: L.latitude || null,
// //         longitude: L.longitude || null,
// //         status: L.approvalStatus ?? L.status ?? 'Pending',
// //       });
// //     });

// //     out.sort((a, b) => String(b.requestDate || '').localeCompare(String(a.requestDate || '')));
// //     return res.json(out);
// //   } catch (err) {
// //     console.error('listApprovalRequests error:', err);
// //     return res.status(500).json({ error: err.message });
// //   }
// // };

// // /** 12) Admin decision */
// // exports.decideApproval = async (req, res) => {
// //   try {
// //     const { source, attendanceId, leaveId, empid, date, status, remarks } = req.body || {};
// //     const clean = String(status || '').trim();
// //     if (!['Approved','Rejected'].includes(clean)) {
// //       return res.status(400).json({ error: 'status must be Approved or Rejected' });
// //     }
// //     if (!source || !['attendance','leaves'].includes(source)) {
// //       return res.status(400).json({ error: 'source must be attendance or leaves' });
// //     }

// //     if (source === 'attendance') {
// //       let docRef = null;
// //       if (attendanceId) {
// //         docRef = db.collection(ATT_COL).doc(attendanceId);
// //       } else if (empid && date) {
// //         const q = await db.collection(ATT_COL)
// //           .where('empid','==',empid)
// //           .where('date','==',date)
// //           .limit(1).get();
// //         if (q.empty) return res.status(404).json({ error: 'Attendance record not found' });
// //         docRef = q.docs[0].ref;
// //       } else {
// //         return res.status(400).json({ error: 'attendanceId or (empid & date) required' });
// //       }

// //       await docRef.update({
// //         approvalStatus: clean,
// //         decisionBy: req.user?.empid || null,
// //         decisionAt: admin.firestore.FieldValue.serverTimestamp(),
// //         decisionRemarks: remarks || null
// //       });
// //       return res.json({ message: `Attendance ${clean.toLowerCase()} successfully` });
// //     }

// //     if (!leaveId) return res.status(400).json({ error: 'leaveId required' });
// //     await db.collection(LEAVE_COL).doc(leaveId).update({
// //       approvalStatus: clean,
// //       decisionBy: req.user?.empid || null,
// //       decisionAt: admin.firestore.FieldValue.serverTimestamp(),
// //       decisionRemarks: remarks || null
// //     });
// //     return res.json({ message: `Leave ${clean.toLowerCase()} successfully` });

// //   } catch (err) {
// //     console.error('decideApproval error:', err);
// //     return res.status(500).json({ error: err.message });
// //   }
// // };

// // /** 13) User-scoped "My Requests" */
// // exports.listMyRequests = async (req, res) => {
// //   try {
// //     const empid = req.user?.empid;
// //     if (!empid) return res.status(401).json({ message: 'Unauthorized' });

// //     const statusQ = String(req.query.status || 'All');
// //     const wantStatus = statusQ.toLowerCase();
// //     const start = req.query.start || null;
// //     const end   = req.query.end   || null;

// //     // Shifts (for late/early inference)
// //     const shiftsSnap = await db.collection(SHIFT_COL).get();
// //     const shiftByGroup = {};
// //     shiftsSnap.forEach(d => { const s = d.data(); shiftByGroup[s.group] = s; });

// //     // Employee
// //     let emp = null;
// //     const eSnap = await db.collection(EMP_COL).where('empid','==',empid).limit(1).get();
// //     if (!eSnap.empty) emp = eSnap.docs[0].data();

// //     const out = [];

// //     // Attendance
// //     let attRef = db.collection(ATT_COL).where('empid','==',empid);
// //     if (start) attRef = attRef.where('date', '>=', start);
// //     if (end)   attRef = attRef.where('date', '<=', end);
// //     const attSnap = await attRef.get();

// //     attSnap.forEach(doc => {
// //       const a = doc.data();
// //       const shift = shiftByGroup[emp?.shiftGroup] || {};
// //       const startTime = shift.startTime || '09:00';
// //       const endTime   = shift.endTime   || '18:00';

// //       let subType = null;
// //       if (a.checkIn  && a.checkIn  > startTime) subType = 'Late check in';
// //       else if (a.checkOut && a.checkOut > endTime) subType = 'Late check out';
// //       else if (a.checkOut && a.checkOut < endTime) subType = 'Early check out';

// //       const sNorm = String(a.approvalStatus || 'Pending').toLowerCase();
// //       if (wantStatus !== 'all' && sNorm !== wantStatus) return;

// //       out.push({
// //         source: 'attendance',
// //         requestId: doc.id,
// //         type: subType || 'Attendance',
// //         empid: a.empid,
// //         name: a.name || '',
// //         requestDate: a.date,
// //         requestTime: subType === 'Late check in' ? (a.checkIn || '')
// //                     : (subType === 'Late check out' || subType === 'Early check out') ? (a.checkOut || '')
// //                     : '',
// //         reason: a.reason || '-',
// //         location: a.location || '-',
// //         latitude: a.latitude || null,
// //         longitude: a.longitude || null,
// //         status: a.approvalStatus || 'Pending',
// //       });
// //     });

// //     // Leaves
// //     const leaveSnap = await db.collection(LEAVE_COL).where('empid','==',empid).get();

// //     const mapLeaveType = (txt) => {
// //       const t = String(txt || '').toLowerCase();
// //       if (t.includes('permission')) return 'Permission';
// //       if (t.includes('over'))       return 'Over Time';
// //       if (t.includes('half'))       return 'Half Day Leave';
// //       if (t.includes('comp'))       return 'Comp Off';
// //       return 'Leave Type';
// //     };

// //     leaveSnap.forEach(doc => {
// //       const L = doc.data();
// //       const sNorm = String(L.approvalStatus ?? L.status ?? 'Pending').toLowerCase();
// //       if (wantStatus !== 'all' && sNorm !== wantStatus) return;

// //       const dStart = toISO(L.startDate || L.date || L.selectDate);
// //       const dEnd   = toISO(L.endDate   || dStart);
// //       if (start && dEnd   && dEnd   < start) return;
// //       if (end   && dStart && dStart > end)   return;

// //       out.push({
// //         source: 'leaves',
// //         requestId: doc.id,
// //         type: mapLeaveType(L.type),
// //         empid: L.empid,
// //         name: L.name || '',
// //         requestDate: dStart || '',
// //         requestTime: L.time || '',
// //         reason: L.reason || '-',
// //         location: L.location || '-',
// //         latitude: L.latitude || null,
// //         longitude: L.longitude || null,
// //         status: L.approvalStatus ?? L.status ?? 'Pending',
// //       });
// //     });

// //     out.sort((a,b)=> String(b.requestDate||'').localeCompare(String(a.requestDate||'')));
// //     return res.json(out);
// //   } catch (err) {
// //     console.error('listMyRequests error:', err);
// //     return res.status(500).json({ error: err.message });
// //   }
// // };
// const admin = require('firebase-admin');
// const db = require('../config/firebase').db;

// const EMP_COL   = 'employees';
// const ATT_COL   = 'attendance';
// const LEAVE_COL = 'leaves';
// const SHIFT_COL = 'shifts';

// /** ---------- helpers ---------- */
// function pad2(n){ return String(n).padStart(2,'0'); }
// function toYMD(d = new Date()) {
//   const ist = new Date(d.getTime() + 5.5 * 60 * 60 * 1000);
//   return ist.toISOString().slice(0, 10);
// }
// function daysInMonth(year, month){ return new Date(year, month, 0).getDate(); } // month: 1..12
// function isSunday(ymd){ return new Date(ymd).getDay() === 0; } // 0=Sun
// function cmpHHMM(a,b){ return (a||'00:00') > (b||'00:00'); }
// function midpointHHMM(start, end){
//   const [h1,m1] = (start||'00:00').split(':').map(Number);
//   const [h2,m2] = (end  ||'23:59').split(':').map(Number);
//   const s1 = h1*3600+m1*60, s2 = h2*3600+m2*60;
//   const mid = Math.floor((s1+s2)/2);
//   const mh = Math.floor(mid/3600), mm = Math.floor((mid%3600)/60);
//   return `${pad2(mh)}:${pad2(mm)}`;
// }
// function toISO(v){
//   try{
//     if(!v) return '';
//     if (typeof v === 'string') return v.slice(0,10);
//     if (v.toDate && typeof v.toDate === 'function') return v.toDate().toISOString().slice(0,10);
//     const d = new Date(v); return d.toISOString().slice(0,10);
//   }catch{ return ''; }
// }
// function eachYMD(start,end){
//   const out=[]; const d=new Date(start);
//   for(;;){ const ymd=d.toISOString().slice(0,10); out.push(ymd); if(ymd===end) break; d.setDate(d.getDate()+1); }
//   return out;
// }

// /** Holidays placeholder (replace with real rules if you have them) */
// const HOLIDAYS_SET = new Set([]);

// /** 0) Get current user */
// exports.getCurrentUser = async (req, res) => {
//   try {
//     const empid = req.user.empid;
//     const snap = await db.collection(EMP_COL)
//       .where('empid', '==', empid)
//       .limit(1).get();

//     if (snap.empty) return res.status(404).json({ error: 'Employee not found' });
//     const d = snap.docs[0].data();
//     return res.json({
//       empid: d.empid,
//       name:  d.name,
//       role:  req.user.role,
//       shiftGroup: d.shiftGroup
//     });
//   } catch (err) {
//     console.error('getCurrentUser error:', err);
//     return res.status(500).json({ error: err.message });
//   }
// };

// /** 1) Check-in */
// exports.checkIn = async (req, res) => {
//   const { empid, name, location } = req.body;
//   if (!empid || !name || !location) {
//      return res.status(400).json({ error: 'empid, name and location are required' });
//   }
//   const today = new Date().toISOString().slice(0, 10);
//   try {
//     const snap = await db.collection(ATT_COL)
//       .where('empid','==',empid)
//       .where('date','==',today)
//       .get();

//     if (!snap.empty) {
//       const doc = snap.docs[0];
//       if (doc.data().checkIn) {
//         return res.status(400).json({ error:'Already checked in today' });
//       }
//       await doc.ref.update({
//         checkIn:        new Date().toLocaleTimeString('en-GB'),
//         location,
//         status:         'Present',
//         approvalStatus: 'Pending',
//         updatedAt:      admin.firestore.FieldValue.serverTimestamp()
//       });
//       return res.json({ message:'Check-in updated' });
//     }

//     await db.collection(ATT_COL).add({
//       empid,
//       name,
//       date:           today,
//       checkIn:        new Date().toLocaleTimeString('en-GB'),
//       location,
//       status:         'Present',
//       approvalStatus: 'Pending',
//       createdAt:      admin.firestore.FieldValue.serverTimestamp(),
//       updatedAt:      admin.firestore.FieldValue.serverTimestamp()
//     });
//     return res.json({ message:'Checked-in successfully' });

//   } catch (err) {
//     console.error('checkIn error:', err);
//     return res.status(500).json({ error: err.message });
//   }
// };

// /** 2) Check-out */
// exports.checkOut = async (req, res) => {
//   const { empid, location } = req.body;
//   if (!empid || !location) {
//     return res.status(400).json({ error: 'empid and location are required' });
//   }
//   const today = new Date().toISOString().slice(0, 10);
//   try {
//     const snap = await db.collection(ATT_COL)
//       .where('empid','==',empid)
//       .where('date','==',today)
//       .get();
//     if (snap.empty) {
//       return res.status(400).json({ error:'You need to check in first' });
//     }
//     const doc = snap.docs[0];
//     if (doc.data().checkOut) {
//       return res.status(400).json({ error:'Already checked out today' });
//     }
//     await doc.ref.update({
//       checkOut:   new Date().toLocaleTimeString('en-GB'),
//       location,
//       updatedAt:  admin.firestore.FieldValue.serverTimestamp()
//     });

//     // mark employee inactive on checkout
//     const empSnap = await db.collection(EMP_COL)
//       .where('empid','==',empid)
//       .limit(1).get();
//     if (!empSnap.empty) {
//       await empSnap.docs[0].ref.update({
//         status:    'inactive',
//         updatedAt: admin.firestore.FieldValue.serverTimestamp()
//       });
//     }

//     return res.json({ message:'Checked-out & set inactive' });
//   } catch (err) {
//     console.error('checkOut error:', err);
//     return res.status(500).json({ error: err.message });
//   }
// };

// /** 3) Live Attendance */
// exports.getLiveAttendance = async (req, res) => {
//   const today = new Date().toISOString().slice(0, 10);
//   const isAdmin = req.user.role === 'admin';

//   try {
//     // a) Load employees
//     let employees;
//     if (isAdmin) {
//       const empSnap = await db.collection(EMP_COL).get();
//       employees = empSnap.docs.map(d => d.data());
//     } else {
//       const empSnap = await db.collection(EMP_COL)
//         .where('empid','==',req.user.empid)
//         .limit(1).get();
//       if (empSnap.empty) return res.json([]);
//       employees = [empSnap.docs[0].data()];
//     }

//     // b) Attendance map
//     const attSnap = await db.collection(ATT_COL)
//       .where('date','==',today)
//       .get();
//     const attMap = Object.fromEntries(attSnap.docs.map(d => [d.data().empid, d.data()]));

//     // c) Approved leaves including today
//     const leaveSnap = await db.collection(LEAVE_COL)
//       .where('approvalStatus','==','Approved')
//       .where('startDate','<=',today)
//       .get();
//     const validLeaves = leaveSnap.docs
//       .map(d=>d.data())
//       .filter(l => (toISO(l.endDate) || toISO(l.startDate)) >= today)
//       .map(l=>l.empid);
//     const leaveSet = new Set(validLeaves);

//     // d) Shifts
//     const shiftsSnap = await db.collection(SHIFT_COL).get();
//     const shiftByGroup = Object.fromEntries(shiftsSnap.docs.map(d=>[d.data().group, d.data()]));

//     // e) basic holiday/weekoff flags
//     const isHoliday = HOLIDAYS_SET.has(today);
//     const isWeekOff = isSunday(today);

//     // f) Build response
//     const result = employees.map(emp => {
//       const rec = attMap[emp.empid];
//       let status, isLate=false, isEarly=false;
//       let permissionCount = Array.isArray(rec?.permissionRequests)
//         ? rec.permissionRequests.length
//         : (rec?.permissionRequest?1:0);

//       if (isHoliday)      status='Holiday';
//       else if (isWeekOff) status='WeekOff';
//       else if (leaveSet.has(emp.empid)) status='Leave';
//       else if (rec?.checkIn) {
//         status='Present';
//         const shift = shiftByGroup[emp.shiftGroup] || {};
//         const start = shift.startTime || '00:00';
//         const end   = shift.endTime   || '23:59';
//         isLate  = rec.checkIn  > start;
//         isEarly = rec.checkOut && rec.checkOut < end;
//       } else {
//         status='Absent';
//       }

//       // half-day heuristic
//       let isHalfDay = false;
//       if (status==='Present' && shiftByGroup[emp.shiftGroup]) {
//         const [h1,m1] = shiftByGroup[emp.shiftGroup].startTime.split(':').map(Number);
//         const [h2,m2] = shiftByGroup[emp.shiftGroup].endTime.split(':').map(Number);
//         const midSec = ((h1*3600+m1*60)+(h2*3600+m2*60))/2;
//         const inSec  = rec && rec.checkIn
//           ? rec.checkIn.split(':').reduce((a,v,i)=> a + v*(i===0?3600:60),0)
//           : 0;
//         isHalfDay = inSec > midSec;
//       }

//       return {
//         empid:          emp.empid,
//         name:           emp.name,
//         shiftGroup:     emp.shiftGroup,
//         date:           today,
//         status,
//         checkIn:        rec?.checkIn  || null,
//         checkOut:       rec?.checkOut || null,
//         late:           isLate,
//         early:          isEarly,
//         permissionCount,
//         leave:          status==='Leave',
//         holiday:        status==='Holiday',
//         weekOff:        status==='WeekOff',
//         halfDay:        isHalfDay
//       };
//     });

//     return res.json(result);

//   } catch (err) {
//     console.error('getLiveAttendance error:', err);
//     return res.status(500).json({ error: err.message });
//   }
// };

// /** 4) Employee history */
// exports.getEmployeeAttendance = async (req, res) => {
//   const { empid } = req.params;
//   try {
//     const snap = await db.collection(ATT_COL)
//       .where('empid','==',empid)
//       .orderBy('date','desc').get();
//     const records = snap.docs.map(d=>({ id:d.id, ...d.data() }));
//     return res.json(records);
//   } catch (err) {
//     console.error('getEmployeeAttendance error:', err);
//     return res.status(500).json({ error: err.message });
//   }
// };

// /** 5) All records (admin) */
// exports.getAllAttendance = async (req, res) => {
//   try {
//     const snap = await db.collection(ATT_COL).get();
//     const records = snap.docs.map(d=>({ id:d.id, ...d.data() }));
//     return res.json(records);
//   } catch (err) {
//     console.error('getAllAttendance error:', err);
//     return res.status(500).json({ error: err.message });
//   }
// };

// /** 6) Approve / Reject attendance */
// exports.approveAttendance = async (req, res) => {
//   const { id, status } = req.body;
//   try {
//     await db.collection(ATT_COL).doc(id).update({
//       approvalStatus: status,
//       updatedAt:      admin.firestore.FieldValue.serverTimestamp()
//     });
//     return res.json({ message:`Attendance ${status.toLowerCase()} successfully` });
//   } catch (err) {
//     console.error('approveAttendance error:', err);
//     return res.status(500).json({ error: err.message });
//   }
// };

// /** 7) Monthly summary list */
// exports.getMonthlySummary = async (req, res) => {
//   const { empid, year, month } = req.params;
//   try {
//     const snap = await db.collection(ATT_COL)
//       .where('empid','==',empid)
//       .where('date','>=',`${year}-${month}-01`)
//       .where('date','<=',`${year}-${month}-31`)
//       .get();
//     const records = snap.docs.map(d=>({ id:d.id, ...d.data() }));
//     return res.json(records);
//   } catch (err) {
//     console.error('getMonthlySummary error:', err);
//     return res.status(500).json({ error: err.message });
//   }
// };

// /** 8) Daily roster (admin) */
// exports.getDailyRoster = async (req, res) => {
//   const date = req.query.date;
//   if (!date) return res.status(400).json({ error:'Missing ?date=YYYY-MM-DD' });
//   try {
//     const empSnap = await db.collection(EMP_COL).get();
//     const employees = empSnap.docs.map(d=>d.data());

//     const attSnap = await db.collection(ATT_COL).where('date','==',date).get();
//     const attByEmp = Object.fromEntries(attSnap.docs.map(d=>[d.data().empid,d.data()]));

//     const roster = employees.map(emp => {
//       const rec = attByEmp[emp.empid];
//       let raw = 'Absent';
//       if (rec?.approvalStatus==='Approved' && !rec.checkIn) raw='Leave';
//       else if (rec?.checkIn) raw = rec.checkIn > '09:00' ? 'Late':'Present';
//       return {
//         empid:      emp.empid,
//         name:       emp.name,
//         shiftGroup: emp.shiftGroup,
//         status:     (raw==='Present'||raw==='Late') ? 'active':'inactive'
//       };
//     });
//     return res.json(roster);
//   } catch (err) {
//     console.error('getDailyRoster error:', err);
//     return res.status(500).json({ error: err.message });
//   }
// };

// /** 9) Range summary (admin) */
// exports.getRangeSummary = async (req, res) => {
//   try {
//     const start = String(req.query.start || '').slice(0,10);
//     const end   = String(req.query.end   || '').slice(0,10);
//     if (!start || !end || new Date(end) < new Date(start)) {
//       return res.status(400).json({ error: 'Provide ?start=YYYY-MM-DD&end=YYYY-MM-DD' });
//     }

//     const empSnap = await db.collection(EMP_COL).get();
//     const employees = empSnap.docs.map(d => d.data());

//     const activeEmployees = employees.filter(e => String(e.status||'').toLowerCase()==='active').length;

//     const shiftsSnap = await db.collection(SHIFT_COL).get();
//     const shiftByGroup = Object.fromEntries(shiftsSnap.docs.map(d => [d.data().group, d.data()]));

//     const attSnap = await db.collection(ATT_COL)
//       .where('date','>=',start).where('date','<=',end).get();
//     const attByEmpDate = {};
//     attSnap.forEach(doc => { const a = doc.data(); attByEmpDate[`${a.empid}|${a.date}`] = { id: doc.id, ...a }; });

//     const leavesSnap = await db.collection(LEAVE_COL).get();
//     const approvedLeaves = leavesSnap.docs
//       .map(d => d.data())
//       .filter(L => String(L.approvalStatus ?? L.status ?? 'Pending').toLowerCase()==='approved')
//       .map(L => ({ empid: L.empid, type: String(L.type||''), start: toISO(L.startDate || L.selectDate || L.date), end: toISO(L.endDate || L.selectDate || L.date || L.startDate) }));

//     const leaveDays = new Set();
//     let onLeaveCount = 0;
//     for (const L of approvedLeaves) {
//       if (!L.start) continue;
//       const s = L.start, e = L.end || L.start;
//       if (e < start || s > end) continue;
//       for (const d of eachYMD( (s<start?start:s), (e>end?end:e) )) {
//         leaveDays.add(`${L.empid}|${d}`); onLeaveCount++;
//       }
//     }

//     let checkedIn=0, absent=0, lateIn=0, earlyOut=0, halfDay=0, presentApproved=0, holiday=0, weekOff=0;
//     const rows = [];
//     const dates = eachYMD(start, end);

//     for (const ymd of dates) {
//       const isHoliday = HOLIDAYS_SET.has(ymd);
//       const isWO = isSunday(ymd);
//       if (isHoliday) holiday++;
//       if (isWO) weekOff++;

//       for (const emp of employees) {
//         const key   = `${emp.empid}|${ymd}`;
//         const att   = attByEmpDate[key] || null;
//         const shift = shiftByGroup[emp.shiftGroup] || { startTime: '09:00', endTime: '18:00' };
//         const startT = shift.startTime || '09:00';
//         const endT   = shift.endTime   || '18:00';
//         const mid    = midpointHHMM(startT, endT);

//         let status = 'Absent';
//         let isLate=false, isEarly=false;

//         if (isHoliday) {
//           status = 'Holiday';
//         } else if (isWO) {
//           status = 'WeekOff';
//         } else if (leaveDays.has(key)) {
//           status = (approvedLeaves.find(l => l.empid===emp.empid && l.start<=ymd && ymd<= (l.end||l.start) && l.type.toLowerCase().includes('half')))
//                    ? 'Half Day'
//                    : 'On Leave';
//           if (status==='Half Day') halfDay++;
//         } else if (att?.checkIn) {
//           checkedIn++;
//           status = 'Present';
//           if (cmpHHMM(att.checkIn, startT)) { isLate = true; lateIn++; }
//           if (att.checkOut && !cmpHHMM(att.checkOut, endT)) { isEarly = true; earlyOut++; }
//           if (cmpHHMM(att.checkIn, mid)) { status = 'Half Day'; halfDay++; }
//           if (String(att.approvalStatus||'').toLowerCase()==='approved') presentApproved++;
//         } else {
//           absent++;
//         }

//         rows.push({
//           employeeId:  emp.empid,
//           employeeName: emp.name || '',
//           shift:       emp.shift || emp.shiftGroup || '',
//           date:        ymd,
//           checkIn:     att?.checkIn || '-',
//           checkOut:    att?.checkOut || '-',
//           department:  emp.dept || emp.department || '',
//           attendance:  status,
//           workedHours: att?.workedHours ? String(att.workedHours) : '-',
//           late:        isLate,
//           early:       isEarly,
//           approval:    att?.approvalStatus || 'Pending'
//         });
//       }
//     }

//     return res.json({
//       counts: {
//         activeEmployees: activeEmployees,
//         onLeave: onLeaveCount,
//         checkedIn,
//         absent,
//         lateCheckIn: lateIn,
//         earlyCheckOut: earlyOut,
//         halfDay,
//         present: presentApproved,
//         holiday,
//         weekOff
//       },
//       rows
//     });
//   } catch (err) {
//     console.error('getRangeSummary error:', err);
//     return res.status(500).json({ error: err.message });
//   }
// };

// /** 10) Month view aggregate */
// exports.getMonthView = async (req, res) => {
//   try {
//     const { empid, year, month } = req.params;
//     const y = parseInt(year, 10);
//     const m = parseInt(month, 10);
//     if (!empid || !y || !m) return res.status(400).json({ error: 'Bad params' });

//     const first = `${year}-${month}-01`;
//     const last  = `${year}-${month}-${pad2(daysInMonth(y, m))}`;

//     const empSnap = await db.collection(EMP_COL).where('empid','==',empid).limit(1).get();
//     if (empSnap.empty) return res.status(404).json({ error:'Employee not found' });
//     const emp = empSnap.docs[0].data();

//     const shiftSnap = await db.collection(SHIFT_COL).where('group','==',emp.shiftGroup).limit(1).get();
//     const shift = shiftSnap.empty ? {} : shiftSnap.docs[0].data();
//     const shiftStart = shift.startTime || '09:00';
//     const shiftEnd   = shift.endTime   || '18:00';
//     const mid        = midpointHHMM(shiftStart, shiftEnd);

//     const attSnap = await db.collection(ATT_COL)
//       .where('empid','==',empid)
//       .where('date','>=',first)
//       .where('date','<=',last)
//       .get();
//     const attByDate = Object.fromEntries(attSnap.docs.map(d => [d.data().date, d.data()]));

//     const leavesSnap = await db.collection(LEAVE_COL).where('empid','==',empid).get();

//     const rangeLeaves = [];
//     let permissionCount = 0;

//     leavesSnap.forEach(doc => {
//       const l = doc.data();
//       const raw = String(req.query.status || 'All').trim();
//       const wantStatus = raw.toLowerCase();

//       const type = String(l.type || '').toLowerCase();
//       const sdStr = toISO(l.startDate || l.selectDate || l.date);
//       const edStr = toISO(l.endDate   || l.selectDate || l.date || l.startDate);

//       if (type.includes('permission')) {
//         if ((sdStr && sdStr >= first && sdStr <= last) ||
//             (edStr && edStr >= first && edStr <= last)) {
//           permissionCount += 1;
//         }
//         return;
//       }
//       if (!sdStr) return;

//       const start = sdStr;
//       const end   = edStr || sdStr;
//       if (end < first || start > last) return;

//       rangeLeaves.push({ start, end, isHalf: type.includes('half') });
//     });

//     const holidaySet = new Set(HOLIDAYS_SET);

//     const dayStatuses = {};
//     let present=0, absent=0, leave=0, holiday=0, weekOff=0, halfDay=0, late=0, early=0;

//     const todayYMD = toYMD(new Date());
//     const stopAt = (year === todayYMD.slice(0,4) && month === todayYMD.slice(5,7)) ? todayYMD : last;

//     for (let d=1; d<=daysInMonth(y,m); d++){
//       const ymd = `${year}-${month}-${pad2(d)}`;
//       if (ymd > stopAt) continue;

//       let status;

//       if (holidaySet.has(ymd)) {
//         status = 'Holiday'; holiday++;
//       } else if (isSunday(ymd)) {
//         status = 'WeekOff'; weekOff++;
//       } else {
//         const lv = rangeLeaves.find(l => l.start <= ymd && ymd <= l.end);
//         if (lv) {
//           if (lv.isHalf) { status = 'HalfDay'; halfDay++; }
//           else           { status = 'Leave';   leave++;   }
//         } else {
//           const rec = attByDate[ymd];
//           if (rec && rec.checkIn) {
//             status = 'Present'; present++;
//             if (cmpHHMM(rec.checkIn, shiftStart)) late++;
//             if (rec.checkOut && !cmpHHMM(rec.checkOut, shiftEnd)) early++;
//             if (cmpHHMM(rec.checkIn, mid)) {
//               status = 'HalfDay';
//               halfDay++;
//               present--;
//             }
//           } else {
//             status = 'Absent'; absent++;
//           }
//         }
//       }

//       dayStatuses[ymd] = status;
//     }

//     return res.json({
//       empid,
//       month: `${year}-${month}`,
//       shift: { group: emp.shiftGroup, startTime: shiftStart, endTime: shiftEnd, midpoint: mid },
//       dayStatuses,
//       totals: { present, absent, leave, holiday, weekOff, halfDay },
//       extras: { lateCheckin: late, earlyCheckout: early, permissionCount }
//     });

//   } catch (err) {
//     console.error('getMonthView error:', err);
//     return res.status(500).json({ error: err.message });
//   }
// };

// /** 11) Admin Approvals list */
// exports.listApprovalRequests = async (req, res) => {
//   try {
//     const typeQ = String(req.query.type || 'All').toLowerCase();
//     const statusQ = String(req.query.status || 'Pending');
//     const statusWanted = statusQ.toLowerCase();
//     const start = req.query.start || null;
//     const end   = req.query.end   || null;

//     const empSnap = await db.collection(EMP_COL).get();
//     const empById = {};
//     empSnap.forEach(d => { const e = d.data(); empById[e.empid] = e; });

//     const shiftsSnap  = await db.collection(SHIFT_COL).get();
//     const shiftByGroup = {};
//     shiftsSnap.forEach(d => { const s = d.data(); shiftByGroup[s.group] = s; });

//     const out = [];
//     const overlaps = (aStart, aEnd, bStart, bEnd) => {
//       if (!aStart && !aEnd) return true;
//       const A1 = aStart || '0000-01-01';
//       const A2 = aEnd   || '9999-12-31';
//       const B1 = bStart || bEnd || '';
//       const B2 = bEnd   || bStart || '';
//       if (!B1) return true;
//       return (B1 <= A2) && (B2 >= A1);
//     };
//     const mapLeaveType = (txt) => {
//       const t = String(txt || '').toLowerCase();
//       if (t.includes('permission')) return 'Permission';
//       if (t.includes('over'))       return 'Over Time';
//       if (t.includes('half'))       return 'Half Day Leave';
//       if (t.includes('comp'))       return 'Comp Off';
//       return 'Leave Type';
//     };

//     // Attendance
//     let attRef = db.collection(ATT_COL);
//     if (statusWanted !== 'all') attRef = attRef.where('approvalStatus', '==', statusQ);
//     if (start) attRef = attRef.where('date', '>=', start);
//     if (end)   attRef = attRef.where('date', '<=', end);

//     const attSnap = await attRef.get();
//     attSnap.forEach(doc => {
//       const a = doc.data();
//       const emp   = empById[a.empid] || {};
//       const shift = shiftByGroup[emp.shiftGroup] || {};
//       const startTime = shift.startTime || '09:00';
//       const endTime   = shift.endTime   || '18:00';

//       let subType = null;
//       if (a.checkIn  && a.checkIn  > startTime) subType = 'late check in';
//       else if (a.checkOut && a.checkOut > endTime) subType = 'late check out';
//       if (!subType) return;
//       if (typeQ !== 'all' && typeQ !== subType) return;

//       out.push({
//         source: 'attendance',
//         requestId: doc.id,
//         type: subType === 'late check in' ? 'Late check in' : 'Late check out',
//         empid: a.empid,
//         name: emp.name || a.name || '',
//         department: emp.dept || emp.department || '',
//         shift: emp.shift || shift.shift || null,
//         shiftGroup: emp.shiftGroup || '',
//         requestTime: subType === 'late check in' ? (a.checkIn || '') : (a.checkOut || ''),
//         requestDate: a.date,
//         reason: '-',
//         location: a.location || '-',
//         latitude: a.latitude || null,
//         longitude: a.longitude || null,
//         status: a.approvalStatus || 'Pending',
//       });
//     });

//     // Leaves
//     const leaveSnap = await db.collection(LEAVE_COL).get();
//     leaveSnap.forEach(doc => {
//       const L   = doc.data();
//       const emp = empById[L.empid] || {};
//       const sNorm = String(a.approvalStatus || 'Pending').trim().toLowerCase();
//       if (wantStatus !== 'all' && sNorm !== wantStatus) return;

//       const friendlyType = mapLeaveType(L.type);
//       if (typeQ !== 'all' && typeQ !== friendlyType.toLowerCase()) return;

//       const dStart = toISO(L.startDate || L.date || L.selectDate);
//       const dEnd   = toISO(L.endDate   || dStart);
//       if (!overlaps(start, end, dStart, dEnd)) return;

//       out.push({
//         source: 'leaves',
//         requestId: doc.id,
//         type: friendlyType,
//         empid: L.empid,
//         name: emp.name || L.name || '',
//         department: emp.dept || emp.department || L.department || '',
//         shift: emp.shift || null,
//         shiftGroup: emp.shiftGroup || '',
//         requestTime: L.time || L.requestTime || '',
//         requestDate: dStart || '',
//         reason: L.reason || '-',
//         location: L.location || '-',
//         latitude: L.latitude || null,
//         longitude: L.longitude || null,
//         status: L.approvalStatus ?? L.status ?? 'Pending',
//       });
//     });

//     out.sort((a, b) => String(b.requestDate || '').localeCompare(String(a.requestDate || '')));
//     return res.json(out);
//   } catch (err) {
//     console.error('listApprovalRequests error:', err);
//     return res.status(500).json({ error: err.message });
//   }
// };

// /** 12) Admin decision */
// exports.decideApproval = async (req, res) => {
//   try {
//     const { source, attendanceId, leaveId, empid, date, status, remarks } = req.body || {};
//     const clean = String(status || '').trim();
//     if (!['Approved','Rejected'].includes(clean)) {
//       return res.status(400).json({ error: 'status must be Approved or Rejected' });
//     }
//     if (!source || !['attendance','leaves'].includes(source)) {
//       return res.status(400).json({ error: 'source must be attendance or leaves' });
//     }

//     if (source === 'attendance') {
//       let docRef = null;
//       if (attendanceId) {
//         docRef = db.collection(ATT_COL).doc(attendanceId);
//       } else if (empid && date) {
//         const q = await db.collection(ATT_COL)
//           .where('empid','==',empid)
//           .where('date','==',date)
//           .limit(1).get();
//         if (q.empty) return res.status(404).json({ error: 'Attendance record not found' });
//         docRef = q.docs[0].ref;
//       } else {
//         return res.status(400).json({ error: 'attendanceId or (empid & date) required' });
//       }

//       await docRef.update({
//         approvalStatus: clean,
//         decisionBy: req.user?.empid || null,
//         decisionAt: admin.firestore.FieldValue.serverTimestamp(),
//         decisionRemarks: remarks || null
//       });
//       return res.json({ message: `Attendance ${clean.toLowerCase()} successfully` });
//     }

//     if (!leaveId) return res.status(400).json({ error: 'leaveId required' });
//     await db.collection(LEAVE_COL).doc(leaveId).update({
//       approvalStatus: clean,
//       decisionBy: req.user?.empid || null,
//       decisionAt: admin.firestore.FieldValue.serverTimestamp(),
//       decisionRemarks: remarks || null
//     });
//     return res.json({ message: `Leave ${clean.toLowerCase()} successfully` });

//   } catch (err) {
//     console.error('decideApproval error:', err);
//     return res.status(500).json({ error: err.message });
//   }
// };

// /** 13) User-scoped "My Requests" */
// // ===================== USER-SCOPED "MY REQUESTS" (single-day aware) =====================
// /**
//  * GET /api/attendance/my-requests?status=Pending|Approved|Rejected|All&start=YYYY-MM-DD&end=YYYY-MM-DD
//  * Returns current user's own approval cards (attendance + leaves).
//  * If start===end, only return items for that exact day.
//  */
// exports.listMyRequests = async (req, res) => {
//   try {
//     const empid = req.user?.empid;
//     if (!empid) return res.status(401).json({ message: 'Unauthorized' });

//     const statusQ = String(req.query.status || 'All');   // Pending|Approved|Rejected|All
//     const wantStatus = statusQ.toLowerCase();
//     const start = (req.query.start || '').slice(0, 10);  // YYYY-MM-DD
//     const end   = (req.query.end   || '').slice(0, 10);
//     const singleDay = !!(start && end && start === end);

//     // util helpers
//     const toISO = (v) => {
//       try {
//         if (!v) return '';
//         if (typeof v === 'string') return v.slice(0, 10);
//         if (v.toDate && typeof v.toDate === 'function') return v.toDate().toISOString().slice(0, 10);
//         const d = new Date(v); return d.toISOString().slice(0, 10);
//       } catch { return ''; }
//     };
//     const mapLeaveType = (txt) => {
//       const t = String(txt || '').toLowerCase();
//       if (t.includes('permission')) return 'Permission';
//       if (t.includes('over'))       return 'Over Time';
//       if (t.includes('half'))       return 'Half Day Leave';
//       if (t.includes('comp'))       return 'Comp Off';
//       return 'Leave Type';
//     };

//     // Load shifts (for inferring late/early on attendance)
//     const shiftsSnap = await db.collection(SHIFT_COL).get();
//     const shiftByGroup = {};
//     shiftsSnap.forEach(d => { const s = d.data(); shiftByGroup[s.group] = s; });

//     // Employee (to know shift group)
//     let emp = null;
//     const eSnap = await db.collection(EMP_COL).where('empid','==',empid).limit(1).get();
//     if (!eSnap.empty) emp = eSnap.docs[0].data();

//     const out = [];

//     // ------------ A) Attendance items for this empid ------------
//     let attRef = db.collection(ATT_COL).where('empid','==',empid);
//     if (start) attRef = attRef.where('date', '>=', start);
//     if (end)   attRef = attRef.where('date', '<=', end);
//     const attSnap = await attRef.get();

//     attSnap.forEach(doc => {
//       const a = doc.data();

//       // status filter (Pending/Approved/Rejected/All)
//       const sNorm = String(a.approvalStatus || 'Pending').toLowerCase();
//       if (wantStatus !== 'all' && sNorm !== wantStatus) return;

//       // strict single-day filter
//       if (singleDay && a.date !== start) return;

//       const shift = shiftByGroup[emp?.shiftGroup] || {};
//       const startTime = shift.startTime || '09:00';
//       const endTime   = shift.endTime   || '18:00';

//       let subType = null;
//       if (a.checkIn  && a.checkIn  > startTime) subType = 'Late check in';
//       else if (a.checkOut && a.checkOut > endTime) subType = 'Late check out';
//       else if (a.checkOut && a.checkOut < endTime) subType = 'Early check out';

//       out.push({
//         source: 'attendance',
//         requestId: doc.id,
//         type: subType || 'Attendance',
//         empid: a.empid,
//         name: a.name || '',
//         requestDate: a.date,
//         requestTime: subType === 'Late check in' ? (a.checkIn || '')
//                     : (subType === 'Late check out' || subType === 'Early check out') ? (a.checkOut || '')
//                     : '',
//         reason: a.reason || '-',
//         location: a.location || '-',
//         latitude: a.latitude || null,
//         longitude: a.longitude || null,
//         status: a.approvalStatus || 'Pending',
//       });
//     });

//     // ------------ B) Leaves created by this empid ------------
//     const leaveSnap = await db.collection(LEAVE_COL).where('empid','==',empid).get();

//     leaveSnap.forEach(doc => {
//       const L = doc.data();
//       const sNorm = String(L.approvalStatus ?? L.status ?? 'Pending').toLowerCase();
//       if (wantStatus !== 'all' && sNorm !== wantStatus) return;

//       const dStart = toISO(L.startDate || L.date || L.selectDate);
//       const dEnd   = toISO(L.endDate   || dStart);

//       // strict single-day filter for leaves
//       if (singleDay) {
//         if (!(dStart && start >= dStart && start <= (dEnd || dStart))) return;
//       } else {
//         // normal overlap filter
//         if (start && dEnd   && dEnd   < start) return;
//         if (end   && dStart && dStart > end)   return;
//       }

//       out.push({
//         source: 'leaves',
//         requestId: doc.id,
//         type: mapLeaveType(L.type),
//         empid: L.empid,
//         name: L.name || '',
//         requestDate: dStart || '',
//         requestTime: L.time || '',
//         reason: L.reason || '-',
//         location: L.location || '-',
//         latitude: L.latitude || null,
//         longitude: L.longitude || null,
//         status: L.approvalStatus ?? L.status ?? 'Pending',
//       });
//     });

//     // newest first
//     out.sort((a,b)=> String(b.requestDate||'').localeCompare(String(a.requestDate||'')));
//     return res.json(out);
//   } catch (err) {
//     console.error('listMyRequests error:', err);
//     return res.status(500).json({ error: err.message });
//   }
// };
// controllers/attendanceController.js
const admin = require('firebase-admin');
const db = require('../config/firebase').db;

const EMP_COL   = 'employees';
const ATT_COL   = 'attendance';
const LEAVE_COL = 'leaves';
const SHIFT_COL = 'shifts';

/** ---------- helpers ---------- */
function pad2(n){ return String(n).padStart(2,'0'); }
function toYMD(d = new Date()) {
  const ist = new Date(d.getTime() + 5.5 * 60 * 60 * 1000);
  return ist.toISOString().slice(0, 10);
}
function daysInMonth(year, month){ return new Date(year, month, 0).getDate(); } // month: 1..12
function isSunday(ymd){ return new Date(ymd).getDay() === 0; } // 0=Sun
function cmpHHMM(a,b){ return (a||'00:00') > (b||'00:00'); }
function midpointHHMM(start, end){
  const [h1,m1] = (start||'00:00').split(':').map(Number);
  const [h2,m2] = (end  ||'23:59').split(':').map(Number);
  const s1 = h1*3600+m1*60, s2 = h2*3600+m2*60;
  const mid = Math.floor((s1+s2)/2);
  const mh = Math.floor(mid/3600), mm = Math.floor((mid%3600)/60);
  return `${pad2(mh)}:${pad2(mm)}`;
}
function toISO(v){
  try{
    if(!v) return '';
    if (typeof v === 'string') return v.slice(0,10);
    if (v.toDate && typeof v.toDate === 'function') return v.toDate().toISOString().slice(0,10);
    const d = new Date(v); return d.toISOString().slice(0,10);
  }catch{ return ''; }
}
function eachYMD(start,end){
  const out=[]; const d=new Date(start);
  for(;;){ const ymd=d.toISOString().slice(0,10); out.push(ymd); if(ymd===end) break; d.setDate(d.getDate()+1); }
  return out;
}
const HOLIDAYS_SET = new Set([]);

/** 0) Get current user */
exports.getCurrentUser = async (req, res) => {
  try {
    const empid = req.user.empid;
    const snap = await db.collection(EMP_COL)
      .where('empid', '==', empid)
      .limit(1).get();

    if (snap.empty) return res.status(404).json({ error: 'Employee not found' });
    const d = snap.docs[0].data();
    return res.json({
      empid: d.empid,
      name:  d.name,
      role:  req.user.role,
      shiftGroup: d.shiftGroup
    });
  } catch (err) {
    console.error('getCurrentUser error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** 1) Check-in */
exports.checkIn = async (req, res) => {
  const { empid, name, location } = req.body;
  if (!empid || !name || !location) {
     return res.status(400).json({ error: 'empid, name and location are required' });
  }
  const today = new Date().toISOString().slice(0, 10);
  try {
    const snap = await db.collection(ATT_COL)
      .where('empid','==',empid)
      .where('date','==',today)
      .get();

    if (!snap.empty) {
      const doc = snap.docs[0];
      if (doc.data().checkIn) {
        return res.status(400).json({ error:'Already checked in today' });
      }
      await doc.ref.update({
        checkIn:        new Date().toLocaleTimeString('en-GB'),
        location,
        status:         'Present',
        approvalStatus: 'Pending',
        updatedAt:      admin.firestore.FieldValue.serverTimestamp()
      });
      return res.json({ message:'Check-in updated' });
    }

    await db.collection(ATT_COL).add({
      empid,
      name,
      date:           today,
      checkIn:        new Date().toLocaleTimeString('en-GB'),
      location,
      status:         'Present',
      approvalStatus: 'Pending',
      createdAt:      admin.firestore.FieldValue.serverTimestamp(),
      updatedAt:      admin.firestore.FieldValue.serverTimestamp()
    });
    return res.json({ message:'Checked-in successfully' });

  } catch (err) {
    console.error('checkIn error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** 2) Check-out */
exports.checkOut = async (req, res) => {
  const { empid, location } = req.body;
  if (!empid || !location) {
    return res.status(400).json({ error: 'empid and location are required' });
  }
  const today = new Date().toISOString().slice(0, 10);
  try {
    const snap = await db.collection(ATT_COL)
      .where('empid','==',empid)
      .where('date','==',today)
      .get();
    if (snap.empty) {
      return res.status(400).json({ error:'You need to check in first' });
    }
    const doc = snap.docs[0];
    if (doc.data().checkOut) {
      return res.status(400).json({ error:'Already checked out today' });
    }
    await doc.ref.update({
      checkOut:   new Date().toLocaleTimeString('en-GB'),
      location,
      updatedAt:  admin.firestore.FieldValue.serverTimestamp()
    });

    // mark employee inactive on checkout
    const empSnap = await db.collection(EMP_COL)
      .where('empid','==',empid)
      .limit(1).get();
    if (!empSnap.empty) {
      await empSnap.docs[0].ref.update({
        status:    'inactive',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }

    return res.json({ message:'Checked-out & set inactive' });
  } catch (err) {
    console.error('checkOut error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** 3) Live Attendance */
exports.getLiveAttendance = async (req, res) => {
  const today = new Date().toISOString().slice(0, 10);
  const isAdmin = req.user.role === 'admin';

  try {
    // a) Load employees
    let employees;
    if (isAdmin) {
      const empSnap = await db.collection(EMP_COL).get();
      employees = empSnap.docs.map(d => d.data());
    } else {
      const empSnap = await db.collection(EMP_COL)
        .where('empid','==',req.user.empid)
        .limit(1).get();
      if (empSnap.empty) return res.json([]);
      employees = [empSnap.docs[0].data()];
    }

    // b) Attendance map
    const attSnap = await db.collection(ATT_COL)
      .where('date','==',today)
      .get();
    const attMap = Object.fromEntries(attSnap.docs.map(d => [d.data().empid, d.data()]));

    // c) Approved leaves including today
    const leaveSnap = await db.collection(LEAVE_COL)
      .where('approvalStatus','==','Approved')
      .where('startDate','<=',today)
      .get();
    const validLeaves = leaveSnap.docs
      .map(d=>d.data())
      .filter(l => (toISO(l.endDate) || toISO(l.startDate)) >= today)
      .map(l=>l.empid);
    const leaveSet = new Set(validLeaves);

    // d) Shifts
    const shiftsSnap = await db.collection(SHIFT_COL).get();
    const shiftByGroup = Object.fromEntries(shiftsSnap.docs.map(d=>[d.data().group, d.data()]));

    // e) basic holiday/weekoff flags
    const isHoliday = HOLIDAYS_SET.has(today);
    const isWeekOff = isSunday(today);

    // f) Build response
    const result = employees.map(emp => {
      const rec = attMap[emp.empid];
      let status, isLate=false, isEarly=false;
      let permissionCount = Array.isArray(rec?.permissionRequests)
        ? rec.permissionRequests.length
        : (rec?.permissionRequest?1:0);

      if (isHoliday)      status='Holiday';
      else if (isWeekOff) status='WeekOff';
      else if (leaveSet.has(emp.empid)) status='Leave';
      else if (rec?.checkIn) {
        status='Present';
        const shift = shiftByGroup[emp.shiftGroup] || {};
        const start = shift.startTime || '00:00';
        const end   = shift.endTime   || '23:59';
        isLate  = rec.checkIn  > start;
        isEarly = rec.checkOut && rec.checkOut < end;
      } else {
        status='Absent';
      }

      // half-day heuristic
      let isHalfDay = false;
      if (status==='Present' && shiftByGroup[emp.shiftGroup]) {
        const [h1,m1] = shiftByGroup[emp.shiftGroup].startTime.split(':').map(Number);
        const [h2,m2] = shiftByGroup[emp.shiftGroup].endTime.split(':').map(Number);
        const midSec = ((h1*3600+m1*60)+(h2*3600+m2*60))/2;
        const inSec  = rec && rec.checkIn
          ? rec.checkIn.split(':').reduce((a,v,i)=> a + v*(i===0?3600:60),0)
          : 0;
        isHalfDay = inSec > midSec;
      }

      return {
        empid:          emp.empid,
        name:           emp.name,
        shiftGroup:     emp.shiftGroup,
        date:           today,
        status,
        checkIn:        rec?.checkIn  || null,
        checkOut:       rec?.checkOut || null,
        late:           isLate,
        early:          isEarly,
        permissionCount,
        leave:          status==='Leave',
        holiday:        status==='Holiday',
        weekOff:        status==='WeekOff',
        halfDay:        isHalfDay
      };
    });

    return res.json(result);

  } catch (err) {
    console.error('getLiveAttendance error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** 4) Employee history */
exports.getEmployeeAttendance = async (req, res) => {
  const { empid } = req.params;
  try {
    const snap = await db.collection(ATT_COL)
      .where('empid','==',empid)
      .orderBy('date','desc').get();
    const records = snap.docs.map(d=>({ id:d.id, ...d.data() }));
    return res.json(records);
  } catch (err) {
    console.error('getEmployeeAttendance error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** 5) All records (admin) */
exports.getAllAttendance = async (req, res) => {
  try {
    const snap = await db.collection(ATT_COL).get();
    const records = snap.docs.map(d=>({ id:d.id, ...d.data() }));
    return res.json(records);
  } catch (err) {
    console.error('getAllAttendance error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** 6) Approve / Reject attendance */
exports.approveAttendance = async (req, res) => {
  const { id, status } = req.body;
  try {
    await db.collection(ATT_COL).doc(id).update({
      approvalStatus: status,
      updatedAt:      admin.firestore.FieldValue.serverTimestamp()
    });
    return res.json({ message:`Attendance ${status.toLowerCase()} successfully` });
  } catch (err) {
    console.error('approveAttendance error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** 7) Monthly summary list */
exports.getMonthlySummary = async (req, res) => {
  const { empid, year, month } = req.params;
  try {
    const snap = await db.collection(ATT_COL)
      .where('empid','==',empid)
      .where('date','>=',`${year}-${month}-01`)
      .where('date','<=',`${year}-${month}-31`)
      .get();
    const records = snap.docs.map(d=>({ id:d.id, ...d.data() }));
    return res.json(records);
  } catch (err) {
    console.error('getMonthlySummary error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** 8) Daily roster (admin) */
exports.getDailyRoster = async (req, res) => {
  const date = req.query.date;
  if (!date) return res.status(400).json({ error:'Missing ?date=YYYY-MM-DD' });
  try {
    const empSnap = await db.collection(EMP_COL).get();
    const employees = empSnap.docs.map(d=>d.data());

    const attSnap = await db.collection(ATT_COL).where('date','==',date).get();
    const attByEmp = Object.fromEntries(attSnap.docs.map(d=>[d.data().empid,d.data()]));

    const roster = employees.map(emp => {
      const rec = attByEmp[emp.empid];
      let raw = 'Absent';
      if (rec?.approvalStatus==='Approved' && !rec.checkIn) raw='Leave';
      else if (rec?.checkIn) raw = rec.checkIn > '09:00' ? 'Late':'Present';
      return {
        empid:      emp.empid,
        name:       emp.name,
        shiftGroup: emp.shiftGroup,
        status:     (raw==='Present'||raw==='Late') ? 'active':'inactive'
      };
    });
    return res.json(roster);
  } catch (err) {
    console.error('getDailyRoster error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** 9) Range summary (admin) */
exports.getRangeSummary = async (req, res) => {
  try {
    const start = String(req.query.start || '').slice(0,10);
    const end   = String(req.query.end   || '').slice(0,10);
    if (!start || !end || new Date(end) < new Date(start)) {
      return res.status(400).json({ error: 'Provide ?start=YYYY-MM-DD&end=YYYY-MM-DD' });
    }

    const empSnap = await db.collection(EMP_COL).get();
    const employees = empSnap.docs.map(d => d.data());

    const activeEmployees = employees.filter(e => String(e.status||'').toLowerCase()==='active').length;

    const shiftsSnap = await db.collection(SHIFT_COL).get();
    const shiftByGroup = Object.fromEntries(shiftsSnap.docs.map(d => [d.data().group, d.data()]));

    const attSnap = await db.collection(ATT_COL)
      .where('date','>=',start).where('date','<=',end).get();
    const attByEmpDate = {};
    attSnap.forEach(doc => { const a = doc.data(); attByEmpDate[`${a.empid}|${a.date}`] = { id: doc.id, ...a }; });

    const leavesSnap = await db.collection(LEAVE_COL).get();
    const approvedLeaves = leavesSnap.docs
      .map(d => d.data())
      .filter(L => String(L.approvalStatus ?? L.status ?? 'Pending').toLowerCase()==='approved')
      .map(L => ({ empid: L.empid, type: String(L.type||''), start: toISO(L.startDate || L.selectDate || L.date), end: toISO(L.endDate || L.selectDate || L.date || L.startDate) }));

    const leaveDays = new Set();
    let onLeaveCount = 0;
    for (const L of approvedLeaves) {
      if (!L.start) continue;
      const s = L.start, e = L.end || L.start;
      if (e < start || s > end) continue;
      for (const d of eachYMD( (s<start?start:s), (e>end?end:e) )) {
        leaveDays.add(`${L.empid}|${d}`); onLeaveCount++;
      }
    }

    let checkedIn=0, absent=0, lateIn=0, earlyOut=0, halfDay=0, presentApproved=0, holiday=0, weekOff=0;
    const rows = [];
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
        let isLate=false, isEarly=false;

        if (isHoliday) {
          status = 'Holiday';
        } else if (isWO) {
          status = 'WeekOff';
        } else if (leaveDays.has(key)) {
          status = (approvedLeaves.find(l => l.empid===emp.empid && l.start<=ymd && ymd<= (l.end||l.start) && l.type.toLowerCase().includes('half')))
                   ? 'Half Day'
                   : 'On Leave';
          if (status==='Half Day') halfDay++;
        } else if (att?.checkIn) {
          checkedIn++;
          status = 'Present';
          if (cmpHHMM(att.checkIn, startT)) { isLate = true; lateIn++; }
          if (att.checkOut && !cmpHHMM(att.checkOut, endT)) { isEarly = true; earlyOut++; }
          if (cmpHHMM(att.checkIn, mid)) { status = 'Half Day'; halfDay++; }
          if (String(att.approvalStatus||'').toLowerCase()==='approved') presentApproved++;
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
          approval:    att?.approvalStatus || 'Pending'
        });
      }
    }

    return res.json({
      counts: {
        activeEmployees: activeEmployees,
        onLeave: onLeaveCount,
        checkedIn,
        absent,
        lateCheckIn: lateIn,
        earlyCheckOut: earlyOut,
        halfDay,
        present: presentApproved,
        holiday,
        weekOff
      },
      rows
    });
  } catch (err) {
    console.error('getRangeSummary error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** 10) Month view aggregate */
exports.getMonthView = async (req, res) => {
  try {
    const { empid, year, month } = req.params;
    const y = parseInt(year, 10);
    const m = parseInt(month, 10);
    if (!empid || !y || !m) return res.status(400).json({ error: 'Bad params' });

    const first = `${year}-${month}-01`;
    const last  = `${year}-${month}-${pad2(daysInMonth(y, m))}`;

    const empSnap = await db.collection(EMP_COL).where('empid','==',empid).limit(1).get();
    if (empSnap.empty) return res.status(404).json({ error:'Employee not found' });
    const emp = empSnap.docs[0].data();

    const shiftSnap = await db.collection(SHIFT_COL).where('group','==',emp.shiftGroup).limit(1).get();
    const shift = shiftSnap.empty ? {} : shiftSnap.docs[0].data();
    const shiftStart = shift.startTime || '09:00';
    const shiftEnd   = shift.endTime   || '18:00';
    const mid        = midpointHHMM(shiftStart, shiftEnd);

    const attSnap = await db.collection(ATT_COL)
      .where('empid','==',empid)
      .where('date','>=',first)
      .where('date','<=',last)
      .get();
    const attByDate = Object.fromEntries(attSnap.docs.map(d => [d.data().date, d.data()]));

    const leavesSnap = await db.collection(LEAVE_COL).where('empid','==',empid).get();

    const rangeLeaves = [];
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

    const holidaySet = new Set(HOLIDAYS_SET);

    const dayStatuses = {};
    let present=0, absent=0, leave=0, holiday=0, weekOff=0, halfDay=0, late=0, early=0;

    const todayYMD = toYMD(new Date());
    const stopAt = (year === todayYMD.slice(0,4) && month === todayYMD.slice(5,7)) ? todayYMD : last;

    for (let d=1; d<=daysInMonth(y,m); d++){
      const ymd = `${year}-${month}-${pad2(d)}`;
      if (ymd > stopAt) continue;

      let status;

      if (holidaySet.has(ymd)) {
        status = 'Holiday'; holiday++;
      } else if (isSunday(ymd)) {
        status = 'WeekOff'; weekOff++;
      } else {
        const lv = rangeLeaves.find(l => l.start <= ymd && ymd <= l.end);
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
      extras: { lateCheckin: late, earlyCheckout: early, permissionCount }
    });

  } catch (err) {
    console.error('getMonthView error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** ---------- Normalization helpers for approvals ---------- */
const norm = (s) => String(s || '').trim().toLowerCase();
const normalizeType = (s) => {
  const t = norm(s).replace(/\s+/g, ' ');
  if (!t || t === 'all') return 'all';

  // attendance buckets
  if (t.includes('late')  && t.includes('check') && t.includes('in'))  return 'late check in';
  if (t.includes('early') && t.includes('check') && t.includes('out')) return 'early check out';
  if (t.includes('late')  && t.includes('check') && t.includes('out')) return 'late check out';

  // leave buckets
  if (t.includes('permission'))                      return 'permission';
  if (t.includes('over') && t.includes('time'))      return 'over time';
  if (t.includes('half') && t.includes('day'))       return 'half day leave';
  if (t.includes('comp') && t.includes('off'))       return 'comp off';
  if (t.includes('leave'))                           return 'leave type';

  return t;
};
const mapLeaveType = (txt) => {
  const t = norm(txt);
  if (t.includes('permission')) return 'Permission';
  if (t.includes('over') && t.includes('time')) return 'Over Time';
  if (t.includes('half') && t.includes('day'))  return 'Half Day Leave';
  if (t.includes('comp') && t.includes('off'))  return 'Comp Off';
  return 'Leave Type';
};
const overlaps = (aStart, aEnd, bStart, bEnd) => {
  if (!aStart && !aEnd) return true;
  const A1 = aStart || '0000-01-01';
  const A2 = aEnd   || '9999-12-31';
  const B1 = bStart || bEnd || '';
  const B2 = bEnd   || bStart || '';
  if (!B1) return true;
  return (B1 <= A2) && (B2 >= A1);
};

/** 11) Admin Approvals list */
exports.listApprovalRequests = async (req, res) => {
  try {
    const typeFilter   = normalizeType(req.query.type || 'All'); // normalized
    const statusRaw    = String(req.query.status || 'Pending').trim();
    const statusWanted = norm(statusRaw);                        // pending|approved|rejected|all
    const start        = (req.query.start || '').slice(0,10) || null;
    const end          = (req.query.end   || '').slice(0,10) || null;

    // preload employees & shifts
    const empSnap = await db.collection(EMP_COL).get();
    const empById = Object.fromEntries(empSnap.docs.map(d => {
      const e = d.data();
      return [e.empid, e];
    }));
    const shiftSnap = await db.collection(SHIFT_COL).get();
    const shiftByGroup = Object.fromEntries(shiftSnap.docs.map(d => {
      const s = d.data();
      return [s.group, s];
    }));

    const out = [];

    // A) Attendance requests
    let attRef = db.collection(ATT_COL);
    if (statusWanted !== 'all') attRef = attRef.where('approvalStatus', '==', statusRaw);
    if (start) attRef = attRef.where('date', '>=', start);
    if (end)   attRef = attRef.where('date', '<=', end);

    const attSnap = await attRef.get();
    attSnap.forEach(doc => {
      const a = doc.data();
      const emp   = empById[a.empid] || {};
      const shift = shiftByGroup[emp.shiftGroup] || {};
      const startTime = shift.startTime || '09:00';
      const endTime   = shift.endTime   || '18:00';

      // infer subtype
      let subType = null;
      if (a.checkIn  && a.checkIn  > startTime) subType = 'Late check in';
      if (a.checkOut && a.checkOut < endTime)   subType = 'Early check out';
      else if (a.checkOut && a.checkOut > endTime) subType = 'Late check out';

      // exclude plain present
      if (!subType) return;

      // apply type filter
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
      const L   = doc.data();
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
  } catch (err) {
    console.error('listApprovalRequests error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** 12) Admin decision */
exports.decideApproval = async (req, res) => {
  try {
    const { source, attendanceId, leaveId, empid, date, status, remarks } = req.body || {};
    const clean = String(status || '').trim();
    if (!['Approved','Rejected'].includes(clean)) {
      return res.status(400).json({ error: 'status must be Approved or Rejected' });
    }
    if (!source || !['attendance','leaves'].includes(source)) {
      return res.status(400).json({ error: 'source must be attendance or leaves' });
    }

    if (source === 'attendance') {
      let docRef = null;
      if (attendanceId) {
        docRef = db.collection(ATT_COL).doc(attendanceId);
      } else if (empid && date) {
        const q = await db.collection(ATT_COL)
          .where('empid','==',empid)
          .where('date','==',date)
          .limit(1).get();
        if (q.empty) return res.status(404).json({ error: 'Attendance record not found' });
        docRef = q.docs[0].ref;
      } else {
        return res.status(400).json({ error: 'attendanceId or (empid & date) required' });
      }

      await docRef.update({
        approvalStatus: clean,
        decisionBy: req.user?.empid || null,
        decisionAt: admin.firestore.FieldValue.serverTimestamp(),
        decisionRemarks: remarks || null
      });
      return res.json({ message: `Attendance ${clean.toLowerCase()} successfully` });
    }

    if (!leaveId) return res.status(400).json({ error: 'leaveId required' });
    await db.collection(LEAVE_COL).doc(leaveId).update({
      approvalStatus: clean,
      decisionBy: req.user?.empid || null,
      decisionAt: admin.firestore.FieldValue.serverTimestamp(),
      decisionRemarks: remarks || null
    });
    return res.json({ message: `Leave ${clean.toLowerCase()} successfully` });

  } catch (err) {
    console.error('decideApproval error:', err);
    return res.status(500).json({ error: err.message });
  }
};

/** 13) User-scoped "My Requests" */
exports.listMyRequests = async (req, res) => {
  try {
    const empid = req.user?.empid;
    if (!empid) return res.status(401).json({ message: 'Unauthorized' });

    const statusQ = String(req.query.status || 'All');   // Pending|Approved|Rejected|All
    const wantStatus = statusQ.trim().toLowerCase();
    const start = (req.query.start || '').slice(0, 10);  // YYYY-MM-DD
    const end   = (req.query.end   || '').slice(0, 10);
    const singleDay = !!(start && end && start === end);

    // preload shifts (for attendance subtype)
    const shiftsSnap = await db.collection(SHIFT_COL).get();
    const shiftByGroup = {};
    shiftsSnap.forEach(d => { const s = d.data(); shiftByGroup[s.group] = s; });

    // employee
    let emp = null;
    const eSnap = await db.collection(EMP_COL).where('empid','==',empid).limit(1).get();
    if (!eSnap.empty) emp = eSnap.docs[0].data();

    const out = [];

    // A) Attendance items
    let attRef = db.collection(ATT_COL).where('empid','==',empid);
    if (start) attRef = attRef.where('date', '>=', start);
    if (end)   attRef = attRef.where('date', '<=', end);
    const attSnap = await attRef.get();

    attSnap.forEach(doc => {
      const a = doc.data();

      const sNorm = String(a.approvalStatus || 'Pending').toLowerCase();
      if (wantStatus !== 'all' && sNorm !== wantStatus) return;
      if (singleDay && a.date !== start) return;

      const shift = shiftByGroup[emp?.shiftGroup] || {};
      const startTime = shift.startTime || '09:00';
      const endTime   = shift.endTime   || '18:00';

      let subType = null;
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
        requestTime: subType === 'Late check in' ? (a.checkIn || '')
                    : (subType === 'Late check out' || subType === 'Early check out') ? (a.checkOut || '')
                    : '',
        reason: a.reason || '-',
        location: a.location || '-',
        latitude: a.latitude || null,
        longitude: a.longitude || null,
        status: a.approvalStatus || 'Pending',
      });
    });

    // B) Leaves created by this empid
    const leaveSnap = await db.collection(LEAVE_COL).where('empid','==',empid).get();

    leaveSnap.forEach(doc => {
      const L = doc.data();
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

    out.sort((a,b)=> String(b.requestDate||'').localeCompare(String(a.requestDate||'')));
    return res.json(out);
  } catch (err) {
    console.error('listMyRequests error:', err);
    return res.status(500).json({ error: err.message });
  }
};
