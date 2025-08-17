
// // // // // const express = require('express');
// // // // // const router  = express.Router();
// // // // // const ctrl    = require('../controllers/attendanceController');
// // // // // const { verifyToken, isUserOrAdmin, isAdmin, isUser } = require('../middlewares/authMiddleware');

// // // // // /**
// // // // //  * @swagger
// // // // //  * tags:
// // // // //  *   - name: Attendance
// // // // //  *     description: Attendance tracking (check-in/out, live view, history, admin)
// // // // //  *
// // // // //  * components:
// // // // //  *   securitySchemes:
// // // // //  *     bearerAuth:
// // // // //  *       type: http
// // // // //  *       scheme: bearer
// // // // //  *       bearerFormat: JWT
// // // // //  *   schemas:
// // // // //  *     UserInfo:
// // // // //  *       type: object
// // // // //  *       properties:
// // // // //  *         empid: { type: string, example: "emp014" }
// // // // //  *         name:  { type: string, example: "Anupriya" }
// // // // //  *         role:  { type: string, example: "employee" }
// // // // //  *         shiftGroup: { type: string, example: "shift1" }
// // // // //  *
// // // // //  *     CheckInRequest:
// // // // //  *       type: object
// // // // //  *       required: [empid, name, location]
// // // // //  *       properties:
// // // // //  *         empid:    { type: string, example: "emp014" }
// // // // //  *         name:     { type: string, example: "Anupriya" }
// // // // //  *         location: { type: string, example: "Chennai" }
// // // // //  *
// // // // //  *     CheckOutRequest:
// // // // //  *       type: object
// // // // //  *       required: [empid, location]
// // // // //  *       properties:
// // // // //  *         empid:    { type: string, example: "emp014" }
// // // // //  *         location: { type: string, example: "Chennai" }
// // // // //  *
// // // // //  *     ApproveAttendanceRequest:
// // // // //  *       type: object
// // // // //  *       required: [id, status]
// // // // //  *       properties:
// // // // //  *         id:     { type: string, example: "fv7X9c3mabc123" }
// // // // //  *         status: { type: string, enum: [Approved, Rejected], example: Approved }
// // // // //  *
// // // // //  *     AttendanceRecord:
// // // // //  *       type: object
// // // // //  *       properties:
// // // // //  *         id:        { type: string, example: "fv7X9c3mabc123" }
// // // // //  *         empid:     { type: string, example: "emp014" }
// // // // //  *         name:      { type: string, example: "Anupriya" }
// // // // //  *         date:      { type: string, format: date, example: "2025-08-11" }
// // // // //  *         checkIn:   { type: string, nullable: true, example: "09:02" }
// // // // //  *         checkOut:  { type: string, nullable: true, example: "17:55" }
// // // // //  *         status:    { type: string, example: "Present" }
// // // // //  *         approvalStatus: { type: string, example: "Pending" }
// // // // //  *         location:  { type: string, example: "Chennai" }
// // // // //  *
// // // // //  *     LiveAttendanceItem:
// // // // //  *       type: object
// // // // //  *       properties:
// // // // //  *         empid:      { type: string, example: "emp014" }
// // // // //  *         name:       { type: string, example: "Anupriya" }
// // // // //  *         shiftGroup: { type: string, example: "shift1" }
// // // // //  *         date:       { type: string, format: date, example: "2025-08-11" }
// // // // //  *         status:     { type: string, example: "Present" }
// // // // //  *         checkIn:    { type: string, nullable: true, example: "09:02" }
// // // // //  *         checkOut:   { type: string, nullable: true, example: "17:55" }
// // // // //  *         late:       { type: boolean, example: false }
// // // // //  *         early:      { type: boolean, example: false }
// // // // //  *         permissionCount: { type: integer, example: 0 }
// // // // //  *         leave:      { type: boolean, example: false }
// // // // //  *         holiday:    { type: boolean, example: false }
// // // // //  *         weekOff:    { type: boolean, example: false }
// // // // //  *         halfDay:    { type: boolean, example: false }
// // // // //  *
// // // // //  *     RosterItem:
// // // // //  *       type: object
// // // // //  *       properties:
// // // // //  *         empid:      { type: string, example: "emp014" }
// // // // //  *         name:       { type: string, example: "Anupriya" }
// // // // //  *         shiftGroup: { type: string, example: "shift1" }
// // // // //  *         status:     { type: string, enum: [active, inactive], example: "active" }
// // // // //  *
// // // // //  *     MonthViewTotals:
// // // // //  *       type: object
// // // // //  *       properties:
// // // // //  *         present: { type: integer, example: 1 }
// // // // //  *         absent:  { type: integer, example: 6 }
// // // // //  *         leave:   { type: integer, example: 2 }
// // // // //  *         holiday: { type: integer, example: 0 }
// // // // //  *         weekOff: { type: integer, example: 2 }
// // // // //  *         halfDay: { type: integer, example: 0 }
// // // // //  *
// // // // //  *     MonthViewExtras:
// // // // //  *       type: object
// // // // //  *       properties:
// // // // //  *         lateCheckin:   { type: integer, example: 0 }
// // // // //  *         earlyCheckout: { type: integer, example: 0 }
// // // // //  *         permissionCount: { type: integer, example: 1 }
// // // // //  *
// // // // //  *     MonthViewShift:
// // // // //  *       type: object
// // // // //  *       properties:
// // // // //  *         group:    { type: string, example: "shift1" }
// // // // //  *         startTime:{ type: string, example: "09:00" }
// // // // //  *         endTime:  { type: string, example: "18:00" }
// // // // //  *         midpoint: { type: string, example: "13:30" }
// // // // //  *
// // // // //  *     MonthViewResponse:
// // // // //  *       type: object
// // // // //  *       properties:
// // // // //  *         empid: { type: string, example: "emp014" }
// // // // //  *         month: { type: string, example: "2025-08" }
// // // // //  *         shift: { $ref: '#/components/schemas/MonthViewShift' }
// // // // //  *         dayStatuses:
// // // // //  *           type: object
// // // // //  *           additionalProperties:
// // // // //  *             type: string
// // // // //  *             enum: [Present, Absent, Leave, Holiday, WeekOff, HalfDay]
// // // // //  *           example:
// // // // //  *             2025-08-01: Absent
// // // // //  *             2025-08-02: Absent
// // // // //  *             2025-08-03: WeekOff
// // // // //  *             2025-08-06: Present
// // // // //  *             2025-08-08: Leave
// // // // //  *             2025-08-09: Leave
// // // // //  *         totals: { $ref: '#/components/schemas/MonthViewTotals' }
// // // // //  *         extras: { $ref: '#/components/schemas/MonthViewExtras' }
// // // // //  */

// // // // // // 1) Health check
// // // // // /**
// // // // //  * @swagger
// // // // //  * /api/attendance/ping:
// // // // //  *   get:
// // // // //  *     summary: Health check
// // // // //  *     tags: [Attendance]
// // // // //  *     responses:
// // // // //  *       200:
// // // // //  *         description: pong
// // // // //  *         content:
// // // // //  *           text/plain:
// // // // //  *             schema:
// // // // //  *               type: string
// // // // //  *             example: pong
// // // // //  */
// // // // // router.get('/ping', (req, res) => res.send('pong'));

// // // // // // 2) Get current user
// // // // // /**
// // // // //  * @swagger
// // // // //  * /api/attendance/me:
// // // // //  *   get:
// // // // //  *     summary: Get logged-in user’s empid, name, role & shiftGroup
// // // // //  *     tags: [Attendance]
// // // // //  *     security:
// // // // //  *       - bearerAuth: []
// // // // //  *     responses:
// // // // //  *       200:
// // // // //  *         description: User info
// // // // //  *         content:
// // // // //  *           application/json:
// // // // //  *             schema:
// // // // //  *               $ref: '#/components/schemas/UserInfo'
// // // // //  *       401:
// // // // //  *         description: Unauthorized
// // // // //  */
// // // // // router.get('/me', verifyToken, ctrl.getCurrentUser);

// // // // // // 3) Check-in (user only)
// // // // // /**
// // // // //  * @swagger
// // // // //  * /api/attendance/check-in:
// // // // //  *   post:
// // // // //  *     summary: Employee Check-in
// // // // //  *     description: Requires **Authorization: Bearer &lt;JWT&gt;**.
// // // // //  *     tags: [Attendance]
// // // // //  *     security:
// // // // //  *       - bearerAuth: []
// // // // //  *     requestBody:
// // // // //  *       required: true
// // // // //  *       content:
// // // // //  *         application/json:
// // // // //  *           schema:
// // // // //  *             $ref: '#/components/schemas/CheckInRequest'
// // // // //  *           examples:
// // // // //  *             default:
// // // // //  *               value:
// // // // //  *                 empid: emp014
// // // // //  *                 name: Anupriya
// // // // //  *                 location: Chennai
// // // // //  *     responses:
// // // // //  *       200:
// // // // //  *         description: Check-in updated / created
// // // // //  *         content:
// // // // //  *           application/json:
// // // // //  *             schema:
// // // // //  *               type: object
// // // // //  *               example: { message: "Checked-in successfully" }
// // // // //  *       400:
// // // // //  *         description: Already checked in or invalid
// // // // //  *       401:
// // // // //  *         description: Unauthorized (missing/invalid token)
// // // // //  *       500:
// // // // //  *         description: Server error
// // // // //  */
// // // // // router.post('/check-in', verifyToken, isUser, ctrl.checkIn);

// // // // // // 4) Check-out (user only)
// // // // // /**
// // // // //  * @swagger
// // // // //  * /api/attendance/check-out:
// // // // //  *   post:
// // // // //  *     summary: Employee Check-out
// // // // //  *     description: Requires **Authorization: Bearer &lt;JWT&gt;**.
// // // // //  *     tags: [Attendance]
// // // // //  *     security:
// // // // //  *       - bearerAuth: []
// // // // //  *     requestBody:
// // // // //  *       required: true
// // // // //  *       content:
// // // // //  *         application/json:
// // // // //  *           schema:
// // // // //  *             $ref: '#/components/schemas/CheckOutRequest'
// // // // //  *           examples:
// // // // //  *             default:
// // // // //  *               value:
// // // // //  *                 empid: emp014
// // // // //  *                 location: Chennai
// // // // //  *     responses:
// // // // //  *       200:
// // // // //  *         description: Check-out successful
// // // // //  *         content:
// // // // //  *           application/json:
// // // // //  *             schema:
// // // // //  *               type: object
// // // // //  *               example: { message: "Checked-out & set inactive" }
// // // // //  *       400:
// // // // //  *         description: Must check in first or already checked out
// // // // //  *       401:
// // // // //  *         description: Unauthorized (missing/invalid token)
// // // // //  *       500:
// // // // //  *         description: Server error
// // // // //  */
// // // // // router.post('/check-out', verifyToken, isUser, ctrl.checkOut);

// // // // // // 5) Live attendance (admin sees all, user sees own)
// // // // // /**
// // // // //  * @swagger
// // // // //  * /api/attendance/live:
// // // // //  *   get:
// // // // //  *     summary: Live attendance for today (admin sees all, user sees self)
// // // // //  *     tags: [Attendance]
// // // // //  *     security:
// // // // //  *       - bearerAuth: []
// // // // //  *     responses:
// // // // //  *       200:
// // // // //  *         description: Array of live attendance items
// // // // //  *         content:
// // // // //  *           application/json:
// // // // //  *             schema:
// // // // //  *               type: array
// // // // //  *               items:
// // // // //  *                 $ref: '#/components/schemas/LiveAttendanceItem'
// // // // //  *       401:
// // // // //  *         description: Unauthorized
// // // // //  *       403:
// // // // //  *         description: Forbidden
// // // // //  *       500:
// // // // //  *         description: Server error
// // // // //  */
// // // // // router.get('/live', verifyToken, isUserOrAdmin, ctrl.getLiveAttendance);

// // // // // // 6) Full history (self only)
// // // // // /**
// // // // //  * @swagger
// // // // //  * /api/attendance/history/{empid}:
// // // // //  *   get:
// // // // //  *     summary: Full attendance history for one employee
// // // // //  *     tags: [Attendance]
// // // // //  *     security:
// // // // //  *       - bearerAuth: []
// // // // //  *     parameters:
// // // // //  *       - in: path
// // // // //  *         name: empid
// // // // //  *         required: true
// // // // //  *         schema: { type: string, example: "emp014" }
// // // // //  *     responses:
// // // // //  *       200:
// // // // //  *         description: Attendance record array
// // // // //  *         content:
// // // // //  *           application/json:
// // // // //  *             schema:
// // // // //  *               type: array
// // // // //  *               items:
// // // // //  *                 $ref: '#/components/schemas/AttendanceRecord'
// // // // //  *       401:
// // // // //  *         description: Unauthorized
// // // // //  *       500:
// // // // //  *         description: Server error
// // // // //  */
// // // // // router.get('/history/:empid', verifyToken, isUser, ctrl.getEmployeeAttendance);

// // // // // // 7) All records (admin only)
// // // // // /**
// // // // //  * @swagger
// // // // //  * /api/attendance/all:
// // // // //  *   get:
// // // // //  *     summary: Get all attendance records (admin)
// // // // //  *     tags: [Attendance]
// // // // //  *     security:
// // // // //  *       - bearerAuth: []
// // // // //  *     responses:
// // // // //  *       200:
// // // // //  *         description: All attendance entries
// // // // //  *         content:
// // // // //  *           application/json:
// // // // //  *             schema:
// // // // //  *               type: array
// // // // //  *               items:
// // // // //  *                 $ref: '#/components/schemas/AttendanceRecord'
// // // // //  *       401:
// // // // //  *         description: Unauthorized
// // // // //  *       403:
// // // // //  *         description: Forbidden
// // // // //  *       500:
// // // // //  *         description: Server error
// // // // //  */
// // // // // router.get('/all', verifyToken, isAdmin, ctrl.getAllAttendance);

// // // // // // 8) Approve / Reject (admin only)
// // // // // /**
// // // // //  * @swagger
// // // // //  * /api/attendance/approve:
// // // // //  *   post:
// // // // //  *     summary: Approve or reject an attendance entry (admin)
// // // // //  *     description: Requires **Authorization: Bearer &lt;JWT&gt;**.
// // // // //  *     tags: [Attendance]
// // // // //  *     security:
// // // // //  *       - bearerAuth: []
// // // // //  *     requestBody:
// // // // //  *       required: true
// // // // //  *       content:
// // // // //  *         application/json:
// // // // //  *           schema:
// // // // //  *             $ref: '#/components/schemas/ApproveAttendanceRequest'
// // // // //  *           examples:
// // // // //  *             approve:
// // // // //  *               value: { id: "attendanceDocId123", status: "Approved" }
// // // // //  *             reject:
// // // // //  *               value: { id: "attendanceDocId123", status: "Rejected" }
// // // // //  *     responses:
// // // // //  *       200:
// // // // //  *         description: Approval updated
// // // // //  *         content:
// // // // //  *           application/json:
// // // // //  *             schema:
// // // // //  *               type: object
// // // // //  *               example: { message: "Attendance approved successfully" }
// // // // //  *       401:
// // // // //  *         description: Unauthorized
// // // // //  *       403:
// // // // //  *         description: Forbidden
// // // // //  *       500:
// // // // //  *         description: Server error
// // // // //  */
// // // // // router.post('/approve', verifyToken, isAdmin, ctrl.approveAttendance);

// // // // // // 9) Monthly summary (self only)
// // // // // /**
// // // // //  * @swagger
// // // // //  * /api/attendance/summary/{empid}/{year}/{month}:
// // // // //  *   get:
// // // // //  *     summary: Monthly attendance summary (raw records for the month)
// // // // //  *     tags: [Attendance]
// // // // //  *     security:
// // // // //  *       - bearerAuth: []
// // // // //  *     parameters:
// // // // //  *       - in: path
// // // // //  *         name: empid
// // // // //  *         required: true
// // // // //  *         schema: { type: string, example: "emp014" }
// // // // //  *       - in: path
// // // // //  *         name: year
// // // // //  *         required: true
// // // // //  *         schema: { type: string, example: "2025" }
// // // // //  *       - in: path
// // // // //  *         name: month
// // // // //  *         required: true
// // // // //  *         schema: { type: string, example: "08" }
// // // // //  *     responses:
// // // // //  *       200:
// // // // //  *         description: Array of attendance records in the month
// // // // //  *         content:
// // // // //  *           application/json:
// // // // //  *             schema:
// // // // //  *               type: array
// // // // //  *               items:
// // // // //  *                 $ref: '#/components/schemas/AttendanceRecord'
// // // // //  *       401:
// // // // //  *         description: Unauthorized
// // // // //  *       500:
// // // // //  *         description: Server error
// // // // //  */
// // // // // router.get('/summary/:empid/:year/:month', verifyToken, isUser, ctrl.getMonthlySummary);

// // // // // // 10) Daily roster (admin only)
// // // // // /**
// // // // //  * @swagger
// // // // //  * /api/attendance/roster:
// // // // //  *   get:
// // // // //  *     summary: Daily active/inactive roster (admin)
// // // // //  *     tags: [Attendance]
// // // // //  *     security:
// // // // //  *       - bearerAuth: []
// // // // //  *     parameters:
// // // // //  *       - in: query
// // // // //  *         name: date
// // // // //  *         required: true
// // // // //  *         schema: { type: string, example: "2025-08-11" }
// // // // //  *     responses:
// // // // //  *       200:
// // // // //  *         description: Roster array
// // // // //  *         content:
// // // // //  *           application/json:
// // // // //  *             schema:
// // // // //  *               type: array
// // // // //  *               items:
// // // // //  *                 $ref: '#/components/schemas/RosterItem'
// // // // //  *       400:
// // // // //  *         description: Missing date
// // // // //  *       401:
// // // // //  *         description: Unauthorized
// // // // //  *       403:
// // // // //  *         description: Forbidden
// // // // //  *       500:
// // // // //  *         description: Server error
// // // // //  */
// // // // // router.get('/roster', verifyToken, isAdmin, ctrl.getDailyRoster);

// // // // // // 11) Month view (self only)
// // // // // /**
// // // // //  * @swagger
// // // // //  * /api/attendance/month-view/{empid}/{year}/{month}:
// // // // //  *   get:
// // // // //  *     summary: Month view aggregate (day statuses, totals, extras)
// // // // //  *     description: >
// // // // //  *       Returns a calendar-oriented view for one employee and month.
// // // // //  *       Precedence: Holiday → WeekOff → Leave → Present → Absent.
// // // // //  *       HalfDay is explicit half-day leave or check-in after shift midpoint.
// // // // //  *       For the current month, future dates are not included.
// // // // //  *     tags: [Attendance]
// // // // //  *     security:
// // // // //  *       - bearerAuth: []
// // // // //  *     parameters:
// // // // //  *       - in: path
// // // // //  *         name: empid
// // // // //  *         schema: { type: string, example: "emp014" }
// // // // //  *         required: true
// // // // //  *       - in: path
// // // // //  *         name: year
// // // // //  *         schema: { type: string, example: "2025" }
// // // // //  *         required: true
// // // // //  *       - in: path
// // // // //  *         name: month
// // // // //  *         schema: { type: string, example: "08" }
// // // // //  *         required: true
// // // // //  *     responses:
// // // // //  *       200:
// // // // //  *         description: Month aggregate
// // // // //  *         content:
// // // // //  *           application/json:
// // // // //  *             schema:
// // // // //  *               $ref: '#/components/schemas/MonthViewResponse'
// // // // //  *       401:
// // // // //  *         description: Unauthorized
// // // // //  *       403:
// // // // //  *         description: Forbidden
// // // // //  *       500:
// // // // //  *         description: Server error
// // // // //  */
// // // // // router.get('/month-view/:empid/:year/:month', verifyToken, isUser, ctrl.getMonthView);

// // // // // module.exports = router;
// // // // const express = require('express');
// // // // const router  = express.Router();
// // // // const ctrl    = require('../controllers/attendanceController');
// // // // const { verifyToken, isUserOrAdmin, isAdmin, isUser } = require('../middlewares/authMiddleware');

// // // // /**
// // // //  * @swagger
// // // //  * tags:
// // // //  *   - name: Attendance
// // // //  *     description: Attendance tracking (check-in/out, live view, history, admin)
// // // //  *
// // // //  * components:
// // // //  *   securitySchemes:
// // // //  *     bearerAuth:
// // // //  *       type: http
// // // //  *       scheme: bearer
// // // //  *       bearerFormat: JWT
// // // //  *   schemas:
// // // //  *     UserInfo:
// // // //  *       type: object
// // // //  *       properties:
// // // //  *         empid: { type: string, example: "emp014" }
// // // //  *         name:  { type: string, example: "Anupriya" }
// // // //  *         role:  { type: string, example: "employee" }
// // // //  *         shiftGroup: { type: string, example: "shift1" }
// // // //  *
// // // //  *     CheckInRequest:
// // // //  *       type: object
// // // //  *       required: [empid, name, location]
// // // //  *       properties:
// // // //  *         empid:    { type: string, example: "emp014" }
// // // //  *         name:     { type: string, example: "Anupriya" }
// // // //  *         location: { type: string, example: "Chennai" }
// // // //  *
// // // //  *     CheckOutRequest:
// // // //  *       type: object
// // // //  *       required: [empid, location]
// // // //  *       properties:
// // // //  *         empid:    { type: string, example: "emp014" }
// // // //  *         location: { type: string, example: "Chennai" }
// // // //  *
// // // //  *     ApproveAttendanceRequest:
// // // //  *       type: object
// // // //  *       required: [id, status]
// // // //  *       properties:
// // // //  *         id:     { type: string, example: "fv7X9c3mabc123" }
// // // //  *         status: { type: string, enum: [Approved, Rejected], example: Approved }
// // // //  *
// // // //  *     ApprovalCard:
// // // //  *       type: object
// // // //  *       properties:
// // // //  *         source: { type: string, enum: [attendance, leaves], example: attendance }
// // // //  *         requestId: { type: string, example: "docId123" }
// // // //  *         type: { type: string, example: "Late check in" }
// // // //  *         empid: { type: string, example: "EMP007" }
// // // //  *         name: { type: string, example: "Sundar" }
// // // //  *         department: { type: string, example: "IT" }
// // // //  *         shift: { type: integer, nullable: true, example: 1 }
// // // //  *         shiftGroup: { type: string, example: "A" }
// // // //  *         requestTime: { type: string, example: "10:30 AM" }
// // // //  *         requestDate: { type: string, example: "2025-07-28" }
// // // //  *         reason: { type: string, example: "-" }
// // // //  *         location: { type: string, example: "-" }
// // // //  *         latitude: { type: number, format: float, nullable: true }
// // // //  *         longitude:{ type: number, format: float, nullable: true }
// // // //  *         status: { type: string, example: "Pending" }
// // // //  *
// // // //  *     DecideApprovalRequest:
// // // //  *       type: object
// // // //  *       required: [source, status]
// // // //  *       properties:
// // // //  *         source: { type: string, enum: [attendance, leaves] }
// // // //  *         attendanceId: { type: string, description: "Required for source=attendance (or provide empid & date)" }
// // // //  *         empid: { type: string, description: "Alternative to attendanceId with date" }
// // // //  *         date: { type: string, description: "YYYY-MM-DD, with empid if no attendanceId" }
// // // //  *         leaveId: { type: string, description: "Required for source=leaves" }
// // // //  *         status: { type: string, enum: [Approved, Rejected] }
// // // //  *         remarks:{ type: string }
// // // //  *
// // // //  *     AttendanceRecord:
// // // //  *       type: object
// // // //  *       properties:
// // // //  *         id:        { type: string, example: "fv7X9c3mabc123" }
// // // //  *         empid:     { type: string, example: "emp014" }
// // // //  *         name:      { type: string, example: "Anupriya" }
// // // //  *         date:      { type: string, format: date, example: "2025-08-11" }
// // // //  *         checkIn:   { type: string, nullable: true, example: "09:02" }
// // // //  *         checkOut:  { type: string, nullable: true, example: "17:55" }
// // // //  *         status:    { type: string, example: "Present" }
// // // //  *         approvalStatus: { type: string, example: "Pending" }
// // // //  *         location:  { type: string, example: "Chennai" }
// // // //  *
// // // //  *     LiveAttendanceItem:
// // // //  *       type: object
// // // //  *       properties:
// // // //  *         empid:      { type: string, example: "emp014" }
// // // //  *         name:       { type: string, example: "Anupriya" }
// // // //  *         shiftGroup: { type: string, example: "shift1" }
// // // //  *         date:       { type: string, format: date, example: "2025-08-11" }
// // // //  *         status:     { type: string, example: "Present" }
// // // //  *         checkIn:    { type: string, nullable: true, example: "09:02" }
// // // //  *         checkOut:   { type: string, nullable: true, example: "17:55" }
// // // //  *         late:       { type: boolean, example: false }
// // // //  *         early:      { type: boolean, example: false }
// // // //  *         permissionCount: { type: integer, example: 0 }
// // // //  *         leave:      { type: boolean, example: false }
// // // //  *         holiday:    { type: boolean, example: false }
// // // //  *         weekOff:    { type: boolean, example: false }
// // // //  *         halfDay:    { type: boolean, example: false }
// // // //  *
// // // //  *     RosterItem:
// // // //  *       type: object
// // // //  *       properties:
// // // //  *         empid:      { type: string, example: "emp014" }
// // // //  *         name:       { type: string, example: "Anupriya" }
// // // //  *         shiftGroup: { type: string, example: "shift1" }
// // // //  *         status:     { type: string, enum: [active, inactive], example: "active" }
// // // //  *
// // // //  *     MonthViewTotals:
// // // //  *       type: object
// // // //  *       properties:
// // // //  *         present: { type: integer, example: 1 }
// // // //  *         absent:  { type: integer, example: 6 }
// // // //  *         leave:   { type: integer, example: 2 }
// // // //  *         holiday: { type: integer, example: 0 }
// // // //  *         weekOff: { type: integer, example: 2 }
// // // //  *         halfDay: { type: integer, example: 0 }
// // // //  *
// // // //  *     MonthViewExtras:
// // // //  *       type: object
// // // //  *       properties:
// // // //  *         lateCheckin:   { type: integer, example: 0 }
// // // //  *         earlyCheckout: { type: integer, example: 0 }
// // // //  *         permissionCount: { type: integer, example: 1 }
// // // //  *
// // // //  *     MonthViewShift:
// // // //  *       type: object
// // // //  *       properties:
// // // //  *         group:    { type: string, example: "shift1" }
// // // //  *         startTime:{ type: string, example: "09:00" }
// // // //  *         endTime:  { type: string, example: "18:00" }
// // // //  *         midpoint: { type: string, example: "13:30" }
// // // //  *
// // // //  *     MonthViewResponse:
// // // //  *       type: object
// // // //  *       properties:
// // // //  *         empid: { type: string, example: "emp014" }
// // // //  *         month: { type: string, example: "2025-08" }
// // // //  *         shift: { $ref: '#/components/schemas/MonthViewShift' }
// // // //  *         dayStatuses:
// // // //  *           type: object
// // // //  *           additionalProperties:
// // // //  *             type: string
// // // //  *             enum: [Present, Absent, Leave, Holiday, WeekOff, HalfDay]
// // // //  *           example:
// // // //  *             2025-08-01: Absent
// // // //  *             2025-08-02: Absent
// // // //  *             2025-08-03: WeekOff
// // // //  *             2025-08-06: Present
// // // //  *             2025-08-08: Leave
// // // //  *             2025-08-09: Leave
// // // //  *         totals: { $ref: '#/components/schemas/MonthViewTotals' }
// // // //  *         extras: { $ref: '#/components/schemas/MonthViewExtras' }
// // // //  */

// // // // // 1) Health check
// // // // /**
// // // //  * @swagger
// // // //  * /api/attendance/ping:
// // // //  *   get:
// // // //  *     summary: Health check
// // // //  *     tags: [Attendance]
// // // //  *     responses:
// // // //  *       200:
// // // //  *         description: pong
// // // //  *         content:
// // // //  *           text/plain:
// // // //  *             schema:
// // // //  *               type: string
// // // //  *             example: pong
// // // //  */
// // // // router.get('/ping', (req, res) => res.send('pong'));

// // // // // 2) Get current user
// // // // /**
// // // //  * @swagger
// // // //  * /api/attendance/me:
// // // //  *   get:
// // // //  *     summary: Get logged-in user’s empid, name, role & shiftGroup
// // // //  *     tags: [Attendance]
// // // //  *     security:
// // // //  *       - bearerAuth: []
// // // //  *     responses:
// // // //  *       200:
// // // //  *         description: User info
// // // //  *         content:
// // // //  *           application/json:
// // // //  *             schema:
// // // //  *               $ref: '#/components/schemas/UserInfo'
// // // //  *       401:
// // // //  *         description: Unauthorized
// // // //  */
// // // // router.get('/me', verifyToken, ctrl.getCurrentUser);

// // // // // 3) Check-in (user only)
// // // // /**
// // // //  * @swagger
// // // //  * /api/attendance/check-in:
// // // //  *   post:
// // // //  *     summary: Employee Check-in
// // // //  *     description: Requires **Authorization: Bearer &lt;JWT&gt;**.
// // // //  *     tags: [Attendance]
// // // //  *     security:
// // // //  *       - bearerAuth: []
// // // //  *     requestBody:
// // // //  *       required: true
// // // //  *       content:
// // // //  *         application/json:
// // // //  *           schema:
// // // //  *             $ref: '#/components/schemas/CheckInRequest'
// // // //  *           examples:
// // // //  *             default:
// // // //  *               value:
// // // //  *                 empid: emp014
// // // //  *                 name: Anupriya
// // // //  *                 location: Chennai
// // // //  *     responses:
// // // //  *       200:
// // // //  *         description: Check-in updated / created
// // // //  *         content:
// // // //  *           application/json:
// // // //  *             schema:
// // // //  *               type: object
// // // //  *               example: { message: "Checked-in successfully" }
// // // //  *       400:
// // // //  *         description: Already checked in or invalid
// // // //  *       401:
// // // //  *         description: Unauthorized (missing/invalid token)
// // // //  *       500:
// // // //  *         description: Server error
// // // //  */
// // // // router.post('/check-in', verifyToken, isUser, ctrl.checkIn);

// // // // // 4) Check-out (user only)
// // // // /**
// // // //  * @swagger
// // // //  * /api/attendance/check-out:
// // // //  *   post:
// // // //  *     summary: Employee Check-out
// // // //  *     description: Requires **Authorization: Bearer &lt;JWT&gt;**.
// // // //  *     tags: [Attendance]
// // // //  *     security:
// // // //  *       - bearerAuth: []
// // // //  *     requestBody:
// // // //  *       required: true
// // // //  *       content:
// // // //  *         application/json:
// // // //  *           schema:
// // // //  *             $ref: '#/components/schemas/CheckOutRequest'
// // // //  *           examples:
// // // //  *             default:
// // // //  *               value:
// // // //  *                 empid: emp014
// // // //  *                 location: Chennai
// // // //  *     responses:
// // // //  *       200:
// // // //  *         description: Check-out successful
// // // //  *         content:
// // // //  *           application/json:
// // // //  *             schema:
// // // //  *               type: object
// // // //  *               example: { message: "Checked-out & set inactive" }
// // // //  *       400:
// // // //  *         description: Must check in first or already checked out
// // // //  *       401:
// // // //  *         description: Unauthorized (missing/invalid token)
// // // //  *       500:
// // // //  *         description: Server error
// // // //  */
// // // // router.post('/check-out', verifyToken, isUser, ctrl.checkOut);

// // // // // 5) Live attendance (admin sees all, user sees own)
// // // // /**
// // // //  * @swagger
// // // //  * /api/attendance/live:
// // // //  *   get:
// // // //  *     summary: Live attendance for today (admin sees all, user sees self)
// // // //  *     tags: [Attendance]
// // // //  *     security:
// // // //  *       - bearerAuth: []
// // // //  *     responses:
// // // //  *       200:
// // // //  *         description: Array of live attendance items
// // // //  *         content:
// // // //  *           application/json:
// // // //  *             schema:
// // // //  *               type: array
// // // //  *               items:
// // // //  *                 $ref: '#/components/schemas/LiveAttendanceItem'
// // // //  *       401:
// // // //  *         description: Unauthorized
// // // //  *       403:
// // // //  *         description: Forbidden
// // // //  *       500:
// // // //  *         description: Server error
// // // //  */
// // // // router.get('/live', verifyToken, isUserOrAdmin, ctrl.getLiveAttendance);

// // // // // 6) Full history (self only)
// // // // /**
// // // //  * @swagger
// // // //  * /api/attendance/history/{empid}:
// // // //  *   get:
// // // //  *     summary: Full attendance history for one employee
// // // //  *     tags: [Attendance]
// // // //  *     security:
// // // //  *       - bearerAuth: []
// // // //  *     parameters:
// // // //  *       - in: path
// // // //  *         name: empid
// // // //  *         required: true
// // // //  *         schema: { type: string, example: "emp014" }
// // // //  *     responses:
// // // //  *       200:
// // // //  *         description: Attendance record array
// // // //  *         content:
// // // //  *           application/json:
// // // //  *             schema:
// // // //  *               type: array
// // // //  *               items:
// // // //  *                 $ref: '#/components/schemas/AttendanceRecord'
// // // //  *       401:
// // // //  *         description: Unauthorized
// // // //  *       500:
// // // //  *         description: Server error
// // // //  */
// // // // router.get('/history/:empid', verifyToken, isUser, ctrl.getEmployeeAttendance);

// // // // // 7) All records (admin only)
// // // // /**
// // // //  * @swagger
// // // //  * /api/attendance/all:
// // // //  *   get:
// // // //  *     summary: Get all attendance records (admin)
// // // //  *     tags: [Attendance]
// // // //  *     security:
// // // //  *       - bearerAuth: []
// // // //  *     responses:
// // // //  *       200:
// // // //  *         description: All attendance entries
// // // //  *         content:
// // // //  *           application/json:
// // // //  *             schema:
// // // //  *               type: array
// // // //  *               items:
// // // //  *                 $ref: '#/components/schemas/AttendanceRecord'
// // // //  *       401:
// // // //  *         description: Unauthorized
// // // //  *       403:
// // // //  *         description: Forbidden
// // // //  *       500:
// // // //  *         description: Server error
// // // //  */
// // // // router.get('/all', verifyToken, isAdmin, ctrl.getAllAttendance);

// // // // // 8) Approve / Reject (admin only)
// // // // /**
// // // //  * @swagger
// // // //  * /api/attendance/approve:
// // // //  *   post:
// // // //  *     summary: Approve or reject an attendance entry (admin)
// // // //  *     description: Requires **Authorization: Bearer &lt;JWT&gt;**.
// // // //  *     tags: [Attendance]
// // // //  *     security:
// // // //  *       - bearerAuth: []
// // // //  *     requestBody:
// // // //  *       required: true
// // // //  *       content:
// // // //  *         application/json:
// // // //  *           schema:
// // // //  *             $ref: '#/components/schemas/ApproveAttendanceRequest'
// // // //  *           examples:
// // // //  *             approve:
// // // //  *               value: { id: "attendanceDocId123", status: "Approved" }
// // // //  *             reject:
// // // //  *               value: { id: "attendanceDocId123", status: "Rejected" }
// // // //  *     responses:
// // // //  *       200:
// // // //  *         description: Approval updated
// // // //  *         content:
// // // //  *           application/json:
// // // //  *             schema:
// // // //  *               type: object
// // // //  *               example: { message: "Attendance approved successfully" }
// // // //  *       401:
// // // //  *         description: Unauthorized
// // // //  *       403:
// // // //  *         description: Forbidden
// // // //  *       500:
// // // //  *         description: Server error
// // // //  */
// // // // router.post('/approve', verifyToken, isAdmin, ctrl.approveAttendance);

// // // // // 9) Monthly summary (self only)
// // // // /**
// // // //  * @swagger
// // // //  * /api/attendance/summary/{empid}/{year}/{month}:
// // // //  *   get:
// // // //  *     summary: Monthly attendance summary (raw records for the month)
// // // //  *     tags: [Attendance]
// // // //  *     security:
// // // //  *       - bearerAuth: []
// // // //  *     parameters:
// // // //  *       - in: path
// // // //  *         name: empid
// // // //  *         required: true
// // // //  *         schema: { type: string, example: "emp014" }
// // // //  *       - in: path
// // // //  *         name: year
// // // //  *         required: true
// // // //  *         schema: { type: string, example: "2025" }
// // // //  *       - in: path
// // // //  *         name: month
// // // //  *         required: true
// // // //  *         schema: { type: string, example: "08" }
// // // //  *     responses:
// // // //  *       200:
// // // //  *         description: Array of attendance records in the month
// // // //  *         content:
// // // //  *           application/json:
// // // //  *             schema:
// // // //  *               type: array
// // // //  *               items:
// // // //  *                 $ref: '#/components/schemas/AttendanceRecord'
// // // //  *       401:
// // // //  *         description: Unauthorized
// // // //  *       500:
// // // //  *         description: Server error
// // // //  */
// // // // router.get('/summary/:empid/:year/:month', verifyToken, isUser, ctrl.getMonthlySummary);

// // // // // 10) Daily roster (admin only)
// // // // /**
// // // //  * @swagger
// // // //  * /api/attendance/roster:
// // // //  *   get:
// // // //  *     summary: Daily active/inactive roster (admin)
// // // //  *     tags: [Attendance]
// // // //  *     security:
// // // //  *       - bearerAuth: []
// // // //  *     parameters:
// // // //  *       - in: query
// // // //  *         name: date
// // // //  *         required: true
// // // //  *         schema: { type: string, example: "2025-08-11" }
// // // //  *     responses:
// // // //  *       200:
// // // //  *         description: Roster array
// // // //  *         content:
// // // //  *           application/json:
// // // //  *             schema:
// // // //  *               type: array
// // // //  *               items:
// // // //  *                 $ref: '#/components/schemas/RosterItem'
// // // //  *       400:
// // // //  *         description: Missing date
// // // //  *       401:
// // // //  *         description: Unauthorized
// // // //  *       403:
// // // //  *         description: Forbidden
// // // //  *       500:
// // // //  *         description: Server error
// // // //  */
// // // // router.get('/roster', verifyToken, isAdmin, ctrl.getDailyRoster);

// // // // // 11) Month view (self only)
// // // // /**
// // // //  * @swagger
// // // //  * /api/attendance/month-view/{empid}/{year}/{month}:
// // // //  *   get:
// // // //  *     summary: Month view aggregate (day statuses, totals, extras)
// // // //  *     description: >
// // // //  *       Returns a calendar-oriented view for one employee and month.
// // // //  *       Precedence: Holiday → WeekOff → Leave → Present → Absent.
// // // //  *       HalfDay is explicit half-day leave or check-in after shift midpoint.
// // // //  *       For the current month, future dates are not included.
// // // //  *     tags: [Attendance]
// // // //  *     security:
// // // //  *       - bearerAuth: []
// // // //  *     parameters:
// // // //  *       - in: path
// // // //  *         name: empid
// // // //  *         schema: { type: string, example: "emp014" }
// // // //  *         required: true
// // // //  *       - in: path
// // // //  *         name: year
// // // //  *         schema: { type: string, example: "2025" }
// // // //  *         required: true
// // // //  *       - in: path
// // // //  *         name: month
// // // //  *         schema: { type: string, example: "08" }
// // // //  *         required: true
// // // //  *     responses:
// // // //  *       200:
// // // //  *         description: Month aggregate
// // // //  *         content:
// // // //  *           application/json:
// // // //  *             schema:
// // // //  *               $ref: '#/components/schemas/MonthViewResponse'
// // // //  *       401:
// // // //  *         description: Unauthorized
// // // //  *       403:
// // // //  *         description: Forbidden
// // // //  *       500:
// // // //  *         description: Server error
// // // //  */
// // // // router.get('/month-view/:empid/:year/:month', verifyToken, isUser, ctrl.getMonthView);

// // // // // 12) NEW — Approvals listing (admin)
// // // // /**
// // // //  * @swagger
// // // //  * /api/attendance/approvals:
// // // //  *   get:
// // // //  *     summary: List approval requests across attendance (late in/out) and leaves
// // // //  *     tags: [Attendance]
// // // //  *     security:
// // // //  *       - bearerAuth: []
// // // //  *     parameters:
// // // //  *       - in: query
// // // //  *         name: type
// // // //  *         schema:
// // // //  *           type: string
// // // //  *           enum: [All, "Late check in", "Late check out", "Leave Type", Permission, "Over Time", "Half Day Leave", "Comp Off"]
// // // //  *         description: Filter by request type (default All)
// // // //  *       - in: query
// // // //  *         name: status
// // // //  *         schema:
// // // //  *           type: string
// // // //  *           enum: [Pending, Approved, Rejected]
// // // //  *         description: Approval status (default Pending)
// // // //  *       - in: query
// // // //  *         name: start
// // // //  *         schema: { type: string, example: "2025-07-01" }
// // // //  *         description: Optional start date (YYYY-MM-DD)
// // // //  *       - in: query
// // // //  *         name: end
// // // //  *         schema: { type: string, example: "2025-07-31" }
// // // //  *         description: Optional end date (YYYY-MM-DD)
// // // //  *     responses:
// // // //  *       200:
// // // //  *         description: Normalized list of approval cards
// // // //  *         content:
// // // //  *           application/json:
// // // //  *             schema:
// // // //  *               type: array
// // // //  *               items:
// // // //  *                 $ref: '#/components/schemas/ApprovalCard'
// // // //  *       401: { description: Unauthorized }
// // // //  *       403: { description: Forbidden }
// // // //  *       500: { description: Server error }
// // // //  */
// // // // router.get('/approvals', verifyToken, isAdmin, ctrl.listApprovalRequests);

// // // // // 13) NEW — Approvals decision (admin)
// // // // /**
// // // //  * @swagger
// // // //  * /api/attendance/approvals/decision:
// // // //  *   post:
// // // //  *     summary: Approve or reject a specific request (attendance or leaves)
// // // //  *     tags: [Attendance]
// // // //  *     security:
// // // //  *       - bearerAuth: []
// // // //  *     requestBody:
// // // //  *       required: true
// // // //  *       content:
// // // //  *         application/json:
// // // //  *           schema:
// // // //  *             $ref: '#/components/schemas/DecideApprovalRequest'
// // // //  *           examples:
// // // //  *             approveLateIn:
// // // //  *               value:
// // // //  *                 source: attendance
// // // //  *                 empid: EMP007
// // // //  *                 date: 2025-07-28
// // // //  *                 status: Approved
// // // //  *             rejectLeave:
// // // //  *               value:
// // // //  *                 source: leaves
// // // //  *                 leaveId: "leaveDocId123"
// // // //  *                 status: Rejected
// // // //  *                 remarks: Not eligible
// // // //  *     responses:
// // // //  *       200:
// // // //  *         description: Decision applied
// // // //  *       400:
// // // //  *         description: Bad request
// // // //  *       401:
// // // //  *         description: Unauthorized
// // // //  *       403:
// // // //  *         description: Forbidden
// // // //  *       404:
// // // //  *         description: Not found
// // // //  *       500:
// // // //  *         description: Server error
// // // //  */
// // // // router.post('/approvals/decision', verifyToken, isAdmin, ctrl.decideApproval);
// // // // // NEW: Date-range summary for Admin dashboards (counts + rows)
// // // //  /**
// // // //   * @swagger
// // // //   * /api/attendance/range-summary:
// // // //   *   get:
// // // //   *     summary: Aggregated counts (cards) + row items for a date range (admin)
// // // //   *     tags: [Attendance]
// // // //   *     security: [ { bearerAuth: [] } ]
// // // //   *     parameters:
// // // //   *       - in: query
// // // //   *         name: start
// // // //   *         required: true
// // // //   *         schema: { type: string, example: "2025-08-09" }
// // // //   *       - in: query
// // // //   *         name: end
// // // //   *         required: true
// // // //   *         schema: { type: string, example: "2025-08-13" }
// // // //   *     responses:
// // // //   *       200: { description: Summary + rows }
// // // //   */
// // // // router.get('/range-summary', verifyToken, isAdmin, ctrl.getRangeSummary);



// // // // // NEW: current user's own requests (no admin role required)
// // // // router.get('/my-requests', verifyToken, attendanceController.listMyRequests);


// // // // module.exports = router;
// // // const express = require('express');
// // // const router  = express.Router();

// // // const ctrl = require('../controllers/attendanceController'); // ✅ correct import
// // // const { verifyToken, isUserOrAdmin, isAdmin, isUser } = require('../middlewares/authMiddleware');

// // // /**
// // //  * @swagger
// // //  * tags:
// // //  *   - name: Attendance
// // //  *     description: Attendance tracking (check-in/out, live view, history, admin)
// // //  */

// // // /** Health check */
// // // router.get('/ping', (req, res) => res.send('pong'));

// // // /**
// // //  * @swagger
// // //  * /api/attendance/me:
// // //  *   get:
// // //  *     summary: Get logged-in user’s empid, name, role & shiftGroup
// // //  *     description: 'Requires Authorization: Bearer <JWT>.'
// // //  *     tags: [Attendance]
// // //  *     security:
// // //  *       - bearerAuth: []
// // //  *     responses:
// // //  *       200:
// // //  *         description: User info
// // //  *       401:
// // //  *         description: Unauthorized
// // //  */
// // // router.get('/me', verifyToken, ctrl.getCurrentUser);

// // // /**
// // //  * @swagger
// // //  * /api/attendance/check-in:
// // //  *   post:
// // //  *     summary: Employee Check-in
// // //  *     description: 'Requires Authorization: Bearer <JWT>.'
// // //  *     tags: [Attendance]
// // //  *     security:
// // //  *       - bearerAuth: []
// // //  *     responses:
// // //  *       200: { description: Check-in updated / created }
// // //  *       400: { description: Already checked in or invalid }
// // //  *       401: { description: Unauthorized }
// // //  *       500: { description: Server error }
// // //  */
// // // router.post('/check-in', verifyToken, isUser, ctrl.checkIn);

// // // /**
// // //  * @swagger
// // //  * /api/attendance/check-out:
// // //  *   post:
// // //  *     summary: Employee Check-out
// // //  *     description: 'Requires Authorization: Bearer <JWT>.'
// // //  *     tags: [Attendance]
// // //  *     security:
// // //  *       - bearerAuth: []
// // //  *     responses:
// // //  *       200: { description: Check-out successful }
// // //  *       400: { description: Must check in first or already checked out }
// // //  *       401: { description: Unauthorized }
// // //  *       500: { description: Server error }
// // //  */
// // // router.post('/check-out', verifyToken, isUser, ctrl.checkOut);

// // // /**
// // //  * @swagger
// // //  * /api/attendance/live:
// // //  *   get:
// // //  *     summary: Live attendance for today (admin sees all, user sees self)
// // //  *     description: 'Requires Authorization: Bearer <JWT>.'
// // //  *     tags: [Attendance]
// // //  *     security:
// // //  *       - bearerAuth: []
// // //  *     responses:
// // //  *       200: { description: OK }
// // //  *       401: { description: Unauthorized }
// // //  *       403: { description: Forbidden }
// // //  */
// // // router.get('/live', verifyToken, isUserOrAdmin, ctrl.getLiveAttendance);

// // // /**
// // //  * @swagger
// // //  * /api/attendance/history/{empid}:
// // //  *   get:
// // //  *     summary: Full attendance history for one employee
// // //  *     description: 'Requires Authorization: Bearer <JWT>.'
// // //  *     tags: [Attendance]
// // //  *     security:
// // //  *       - bearerAuth: []
// // //  *     parameters:
// // //  *       - in: path
// // //  *         name: empid
// // //  *         required: true
// // //  *         schema:
// // //  *           type: string
// // //  *     responses:
// // //  *       200: { description: OK }
// // //  *       401: { description: Unauthorized }
// // //  */
// // // router.get('/history/:empid', verifyToken, isUser, ctrl.getEmployeeAttendance);

// // // /**
// // //  * @swagger
// // //  * /api/attendance/all:
// // //  *   get:
// // //  *     summary: Get all attendance records (admin)
// // //  *     description: 'Requires Authorization: Bearer <JWT>.'
// // //  *     tags: [Attendance]
// // //  *     security:
// // //  *       - bearerAuth: []
// // //  *     responses:
// // //  *       200: { description: OK }
// // //  *       401: { description: Unauthorized }
// // //  *       403: { description: Forbidden }
// // //  */
// // // router.get('/all', verifyToken, isAdmin, ctrl.getAllAttendance);

// // // /**
// // //  * @swagger
// // //  * /api/attendance/approve:
// // //  *   post:
// // //  *     summary: Approve or reject an attendance entry (admin)
// // //  *     description: 'Requires Authorization: Bearer <JWT>.'
// // //  *     tags: [Attendance]
// // //  *     security:
// // //  *       - bearerAuth: []
// // //  *     responses:
// // //  *       200: { description: Approval updated }
// // //  *       401: { description: Unauthorized }
// // //  *       403: { description: Forbidden }
// // //  */
// // // router.post('/approve', verifyToken, isAdmin, ctrl.approveAttendance);

// // // /**
// // //  * @swagger
// // //  * /api/attendance/summary/{empid}/{year}/{month}:
// // //  *   get:
// // //  *     summary: Monthly attendance summary (raw records for the month)
// // //  *     description: 'Requires Authorization: Bearer <JWT>.'
// // //  *     tags: [Attendance]
// // //  *     security:
// // //  *       - bearerAuth: []
// // //  *     parameters:
// // //  *       - in: path
// // //  *         name: empid
// // //  *         required: true
// // //  *         schema:
// // //  *           type: string
// // //  *       - in: path
// // //  *         name: year
// // //  *         required: true
// // //  *         schema:
// // //  *           type: string
// // //  *       - in: path
// // //  *         name: month
// // //  *         required: true
// // //  *         schema:
// // //  *           type: string
// // //  *     responses:
// // //  *       200: { description: OK }
// // //  */
// // // router.get('/summary/:empid/:year/:month', verifyToken, isUser, ctrl.getMonthlySummary);

// // // /**
// // //  * @swagger
// // //  * /api/attendance/roster:
// // //  *   get:
// // //  *     summary: Daily active/inactive roster (admin)
// // //  *     description: 'Requires Authorization: Bearer <JWT>.'
// // //  *     tags: [Attendance]
// // //  *     security:
// // //  *       - bearerAuth: []
// // //  *     parameters:
// // //  *       - in: query
// // //  *         name: date
// // //  *         required: true
// // //  *         schema:
// // //  *           type: string
// // //  *           example: '2025-08-11'
// // //  *     responses:
// // //  *       200: { description: OK }
// // //  *       400: { description: Missing date }
// // //  */
// // // router.get('/roster', verifyToken, isAdmin, ctrl.getDailyRoster);

// // // /**
// // //  * @swagger
// // //  * /api/attendance/month-view/{empid}/{year}/{month}:
// // //  *   get:
// // //  *     summary: Month view aggregate (day statuses, totals, extras)
// // //  *     description: 'Requires Authorization: Bearer <JWT>.'
// // //  *     tags: [Attendance]
// // //  *     security:
// // //  *       - bearerAuth: []
// // //  *     parameters:
// // //  *       - in: path
// // //  *         name: empid
// // //  *         required: true
// // //  *         schema:
// // //  *           type: string
// // //  *       - in: path
// // //  *         name: year
// // //  *         required: true
// // //  *         schema:
// // //  *           type: string
// // //  *       - in: path
// // //  *         name: month
// // //  *         required: true
// // //  *         schema:
// // //  *           type: string
// // //  *     responses:
// // //  *       200: { description: OK }
// // //  */
// // // router.get('/month-view/:empid/:year/:month', verifyToken, isUser, ctrl.getMonthView);

// // // /**
// // //  * @swagger
// // //  * /api/attendance/approvals:
// // //  *   get:
// // //  *     summary: List approval requests across attendance (late in/out) and leaves
// // //  *     description: 'Requires Authorization: Bearer <JWT>. Admin only.'
// // //  *     tags: [Attendance]
// // //  *     security:
// // //  *       - bearerAuth: []
// // //  *     parameters:
// // //  *       - in: query
// // //  *         name: type
// // //  *         schema:
// // //  *           type: string
// // //  *           example: All
// // //  *       - in: query
// // //  *         name: status
// // //  *         schema:
// // //  *           type: string
// // //  *           example: Pending
// // //  *       - in: query
// // //  *         name: start
// // //  *         schema:
// // //  *           type: string
// // //  *       - in: query
// // //  *         name: end
// // //  *         schema:
// // //  *           type: string
// // //  *     responses:
// // //  *       200: { description: OK }
// // //  *       401: { description: Unauthorized }
// // //  *       403: { description: Forbidden }
// // //  */
// // // router.get('/approvals', verifyToken, isAdmin, ctrl.listApprovalRequests);

// // // /**
// // //  * @swagger
// // //  * /api/attendance/approvals/decision:
// // //  *   post:
// // //  *     summary: Approve or reject a specific request (attendance or leaves)
// // //  *     description: 'Requires Authorization: Bearer <JWT>. Admin only.'
// // //  *     tags: [Attendance]
// // //  *     security:
// // //  *       - bearerAuth: []
// // //  *     responses:
// // //  *       200: { description: Decision applied }
// // //  *       400: { description: Bad request }
// // //  *       401: { description: Unauthorized }
// // //  *       403: { description: Forbidden }
// // //  *       404: { description: Not found }
// // //  */
// // // router.post('/approvals/decision', verifyToken, isAdmin, ctrl.decideApproval);

// // // /**
// // //  * @swagger
// // //  * /api/attendance/range-summary:
// // //  *   get:
// // //  *     summary: Aggregated counts + rows for a date range (admin)
// // //  *     description: 'Requires Authorization: Bearer <JWT>. Admin only.'
// // //  *     tags: [Attendance]
// // //  *     security:
// // //  *       - bearerAuth: []
// // //  *     parameters:
// // //  *       - in: query
// // //  *         name: start
// // //  *         required: true
// // //  *         schema:
// // //  *           type: string
// // //  *       - in: query
// // //  *         name: end
// // //  *         required: true
// // //  *         schema:
// // //  *           type: string
// // //  *     responses:
// // //  *       200: { description: OK }
// // //  */
// // // router.get('/range-summary', verifyToken, isAdmin, ctrl.getRangeSummary);

// // // /**
// // //  * @swagger
// // //  * /api/attendance/my-requests:
// // //  *   get:
// // //  *     summary: Current user's own requests (attendance + leaves)
// // //  *     description: 'Requires Authorization: Bearer <JWT>.'
// // //  *     tags: [Attendance]
// // //  *     security:
// // //  *       - bearerAuth: []
// // //  *     parameters:
// // //  *       - in: query
// // //  *         name: status
// // //  *         schema:
// // //  *           type: string
// // //  *           example: Pending
// // //  *       - in: query
// // //  *         name: start
// // //  *         schema:
// // //  *           type: string
// // //  *       - in: query
// // //  *         name: end
// // //  *         schema:
// // //  *           type: string
// // //  *     responses:
// // //  *       200: { description: OK }
// // //  */
// // // router.get('/my-requests', verifyToken, ctrl.listMyRequests); // ✅ use ctrl

// // // module.exports = router;
// // const express = require('express');
// // const router  = express.Router();

// // const ctrl = require('../controllers/attendanceController'); // ✅ correct import
// // const { verifyToken, isUserOrAdmin, isAdmin, isUser } = require('../middlewares/authMiddleware');

// // /**
// //  * @swagger
// //  * tags:
// //  *   - name: Attendance
// //  *     description: Attendance tracking (check-in/out, live view, history, admin)
// //  */

// // /** Health check */
// // router.get('/ping', (req, res) => res.send('pong'));

// // /**
// //  * @swagger
// //  * /api/attendance/me:
// //  *   get:
// //  *     summary: Get logged-in user’s empid, name, role & shiftGroup
// //  *     description: 'Requires Authorization: Bearer <JWT>.'
// //  *     tags: [Attendance]
// //  *     security:
// //  *       - bearerAuth: []
// //  *     responses:
// //  *       200:
// //  *         description: User info
// //  *       401:
// //  *         description: Unauthorized
// //  */
// // router.get('/me', verifyToken, ctrl.getCurrentUser);

// // /**
// //  * @swagger
// //  * /api/attendance/check-in:
// //  *   post:
// //  *     summary: Employee Check-in
// //  *     description: 'Requires Authorization: Bearer <JWT>.'
// //  *     tags: [Attendance]
// //  *     security:
// //  *       - bearerAuth: []
// //  *     responses:
// //  *       200: { description: Check-in updated / created }
// //  *       400: { description: Already checked in or invalid }
// //  *       401: { description: Unauthorized }
// //  *       500: { description: Server error }
// //  */
// // router.post('/check-in', verifyToken, isUser, ctrl.checkIn);

// // /**
// //  * @swagger
// //  * /api/attendance/check-out:
// //  *   post:
// //  *     summary: Employee Check-out
// //  *     description: 'Requires Authorization: Bearer <JWT>.'
// //  *     tags: [Attendance]
// //  *     security:
// //  *       - bearerAuth: []
// //  *     responses:
// //  *       200: { description: Check-out successful }
// //  *       400: { description: Must check in first or already checked out }
// //  *       401: { description: Unauthorized }
// //  *       500: { description: Server error }
// //  */
// // router.post('/check-out', verifyToken, isUser, ctrl.checkOut);

// // /**
// //  * @swagger
// //  * /api/attendance/live:
// //  *   get:
// //  *     summary: Live attendance for today (admin sees all, user sees self)
// //  *     description: 'Requires Authorization: Bearer <JWT>.'
// //  *     tags: [Attendance]
// //  *     security:
// //  *       - bearerAuth: []
// //  *     responses:
// //  *       200: { description: OK }
// //  *       401: { description: Unauthorized }
// //  *       403: { description: Forbidden }
// //  */
// // router.get('/live', verifyToken, isUserOrAdmin, ctrl.getLiveAttendance);

// // /**
// //  * @swagger
// //  * /api/attendance/history/{empid}:
// //  *   get:
// //  *     summary: Full attendance history for one employee
// //  *     description: 'Requires Authorization: Bearer <JWT>.'
// //  *     tags: [Attendance]
// //  *     security:
// //  *       - bearerAuth: []
// //  *     parameters:
// //  *       - in: path
// //  *         name: empid
// //  *         required: true
// //  *         schema:
// //  *           type: string
// //  *     responses:
// //  *       200: { description: OK }
// //  *       401: { description: Unauthorized }
// //  */
// // router.get('/history/:empid', verifyToken, isUser, ctrl.getEmployeeAttendance);

// // /**
// //  * @swagger
// //  * /api/attendance/all:
// //  *   get:
// //  *     summary: Get all attendance records (admin)
// //  *     description: 'Requires Authorization: Bearer <JWT>.'
// //  *     tags: [Attendance]
// //  *     security:
// //  *       - bearerAuth: []
// //  *     responses:
// //  *       200: { description: OK }
// //  *       401: { description: Unauthorized }
// //  *       403: { description: Forbidden }
// //  */
// // router.get('/all', verifyToken, isAdmin, ctrl.getAllAttendance);

// // /**
// //  * @swagger
// //  * /api/attendance/approve:
// //  *   post:
// //  *     summary: Approve or reject an attendance entry (admin)
// //  *     description: 'Requires Authorization: Bearer <JWT>.'
// //  *     tags: [Attendance]
// //  *     security:
// //  *       - bearerAuth: []
// //  *     responses:
// //  *       200: { description: Approval updated }
// //  *       401: { description: Unauthorized }
// //  *       403: { description: Forbidden }
// //  */
// // router.post('/approve', verifyToken, isAdmin, ctrl.approveAttendance);

// // /**
// //  * @swagger
// //  * /api/attendance/summary/{empid}/{year}/{month}:
// //  *   get:
// //  *     summary: Monthly attendance summary (raw records for the month)
// //  *     description: 'Requires Authorization: Bearer <JWT>.'
// //  *     tags: [Attendance]
// //  *     security:
// //  *       - bearerAuth: []
// //  *     parameters:
// //  *       - in: path
// //  *         name: empid
// //  *         required: true
// //  *         schema:
// //  *           type: string
// //  *       - in: path
// //  *         name: year
// //  *         required: true
// //  *         schema:
// //  *           type: string
// //  *       - in: path
// //  *         name: month
// //  *         required: true
// //  *         schema:
// //  *           type: string
// //  *     responses:
// //  *       200: { description: OK }
// //  */
// // router.get('/summary/:empid/:year/:month', verifyToken, isUser, ctrl.getMonthlySummary);

// // /**
// //  * @swagger
// //  * /api/attendance/roster:
// //  *   get:
// //  *     summary: Daily active/inactive roster (admin)
// //  *     description: 'Requires Authorization: Bearer <JWT>.'
// //  *     tags: [Attendance]
// //  *     security:
// //  *       - bearerAuth: []
// //  *     parameters:
// //  *       - in: query
// //  *         name: date
// //  *         required: true
// //  *         schema:
// //  *           type: string
// //  *           example: '2025-08-11'
// //  *     responses:
// //  *       200: { description: OK }
// //  *       400: { description: Missing date }
// //  */
// // router.get('/roster', verifyToken, isAdmin, ctrl.getDailyRoster);

// // /**
// //  * @swagger
// //  * /api/attendance/month-view/{empid}/{year}/{month}:
// //  *   get:
// //  *     summary: Month view aggregate (day statuses, totals, extras)
// //  *     description: 'Requires Authorization: Bearer <JWT>.'
// //  *     tags: [Attendance]
// //  *     security:
// //  *       - bearerAuth: []
// //  *     parameters:
// //  *       - in: path
// //  *         name: empid
// //  *         required: true
// //  *         schema:
// //  *           type: string
// //  *       - in: path
// //  *         name: year
// //  *         required: true
// //  *         schema:
// //  *           type: string
// //  *       - in: path
// //  *         name: month
// //  *         required: true
// //  *         schema:
// //  *           type: string
// //  *     responses:
// //  *       200: { description: OK }
// //  */
// // router.get('/month-view/:empid/:year/:month', verifyToken, isUser, ctrl.getMonthView);

// // /**
// //  * @swagger
// //  * /api/attendance/approvals:
// //  *   get:
// //  *     summary: List approval requests across attendance (late in/out) and leaves
// //  *     description: 'Requires Authorization: Bearer <JWT>. Admin only.'
// //  *     tags: [Attendance]
// //  *     security:
// //  *       - bearerAuth: []
// //  *     parameters:
// //  *       - in: query
// //  *         name: type
// //  *         schema:
// //  *           type: string
// //  *           example: All
// //  *       - in: query
// //  *         name: status
// //  *         schema:
// //  *           type: string
// //  *           example: Pending
// //  *       - in: query
// //  *         name: start
// //  *         schema:
// //  *           type: string
// //  *       - in: query
// //  *         name: end
// //  *         schema:
// //  *           type: string
// //  *     responses:
// //  *       200: { description: OK }
// //  *       401: { description: Unauthorized }
// //  *       403: { description: Forbidden }
// //  */
// // router.get('/approvals', verifyToken, isAdmin, ctrl.listApprovalRequests);

// // /**
// //  * @swagger
// //  * /api/attendance/approvals/decision:
// //  *   post:
// //  *     summary: Approve or reject a specific request (attendance or leaves)
// //  *     description: 'Requires Authorization: Bearer <JWT>. Admin only.'
// //  *     tags: [Attendance]
// //  *     security:
// //  *       - bearerAuth: []
// //  *     responses:
// //  *       200: { description: Decision applied }
// //  *       400: { description: Bad request }
// //  *       401: { description: Unauthorized }
// //  *       403: { description: Forbidden }
// //  *       404: { description: Not found }
// //  */
// // router.post('/approvals/decision', verifyToken, isAdmin, ctrl.decideApproval);

// // /**
// //  * @swagger
// //  * /api/attendance/range-summary:
// //  *   get:
// //  *     summary: Aggregated counts + rows for a date range (admin)
// //  *     description: 'Requires Authorization: Bearer <JWT>. Admin only.'
// //  *     tags: [Attendance]
// //  *     security:
// //  *       - bearerAuth: []
// //  *     parameters:
// //  *       - in: query
// //  *         name: start
// //  *         required: true
// //  *         schema:
// //  *           type: string
// //  *       - in: query
// //  *         name: end
// //  *         required: true
// //  *         schema:
// //  *           type: string
// //  *     responses:
// //  *       200: { description: OK }
// //  */
// // router.get('/range-summary', verifyToken, isAdmin, ctrl.getRangeSummary);

// // /**
// //  * @swagger
// //  * /api/attendance/my-requests:
// //  *   get:
// //  *     summary: Current user's own requests (attendance + leaves)
// //  *     description: 'Requires Authorization: Bearer <JWT>.'
// //  *     tags: [Attendance]
// //  *     security:
// //  *       - bearerAuth: []
// //  *     parameters:
// //  *       - in: query
// //  *         name: status
// //  *         schema:
// //  *           type: string
// //  *           example: Pending
// //  *       - in: query
// //  *         name: start
// //  *         schema:
// //  *           type: string
// //  *       - in: query
// //  *         name: end
// //  *         schema:
// //  *           type: string
// //  *     responses:
// //  *       200: { description: OK }
// //  */

// // router.get('/my-requests', verifyToken, ctrl.listMyRequests); // ✅ use ctrl

// // module.exports = router;
// const express = require('express');
// const router  = express.Router();

// const ctrl = require('../controllers/attendanceController'); // ✅ correct import
// const { verifyToken, isUserOrAdmin, isAdmin, isUser } = require('../middlewares/authMiddleware');

// /**
//  * @swagger
//  * tags:
//  *   - name: Attendance
//  *     description: Attendance tracking (check-in/out, live view, history, admin)
//  */

// /** Health check */
// router.get('/ping', (req, res) => res.send('pong'));

// /**
//  * @swagger
//  * /api/attendance/me:
//  *   get:
//  *     summary: Get logged-in user’s empid, name, role & shiftGroup
//  *     description: 'Requires Authorization: Bearer <JWT>.'
//  *     tags: [Attendance]
//  *     security:
//  *       - bearerAuth: []
//  *     responses:
//  *       200:
//  *         description: User info
//  *       401:
//  *         description: Unauthorized
//  */
// router.get('/me', verifyToken, ctrl.getCurrentUser);

// /**
//  * @swagger
//  * /api/attendance/check-in:
//  *   post:
//  *     summary: Employee Check-in
//  *     description: 'Requires Authorization: Bearer <JWT>.'
//  *     tags: [Attendance]
//  *     security:
//  *       - bearerAuth: []
//  *     responses:
//  *       200: { description: Check-in updated / created }
//  *       400: { description: Already checked in or invalid }
//  *       401: { description: Unauthorized }
//  *       500: { description: Server error }
//  */
// router.post('/check-in', verifyToken, isUser, ctrl.checkIn);

// /**
//  * @swagger
//  * /api/attendance/check-out:
//  *   post:
//  *     summary: Employee Check-out
//  *     description: 'Requires Authorization: Bearer <JWT>.'
//  *     tags: [Attendance]
//  *     security:
//  *       - bearerAuth: []
//  *     responses:
//  *       200: { description: Check-out successful }
//  *       400: { description: Must check in first or already checked out }
//  *       401: { description: Unauthorized }
//  *       500: { description: Server error }
//  */
// router.post('/check-out', verifyToken, isUser, ctrl.checkOut);

// /**
//  * @swagger
//  * /api/attendance/live:
//  *   get:
//  *     summary: Live attendance for today (admin sees all, user sees self)
//  *     description: 'Requires Authorization: Bearer <JWT>.'
//  *     tags: [Attendance]
//  *     security:
//  *       - bearerAuth: []
//  *     responses:
//  *       200: { description: OK }
//  *       401: { description: Unauthorized }
//  *       403: { description: Forbidden }
//  */
// router.get('/live', verifyToken, isUserOrAdmin, ctrl.getLiveAttendance);

// /**
//  * @swagger
//  * /api/attendance/history/{empid}:
//  *   get:
//  *     summary: Full attendance history for one employee
//  *     description: 'Requires Authorization: Bearer <JWT>.'
//  *     tags: [Attendance]
//  *     security:
//  *       - bearerAuth: []
//  *     parameters:
//  *       - in: path
//  *         name: empid
//  *         required: true
//  *         schema:
//  *           type: string
//  *     responses:
//  *       200: { description: OK }
//  *       401: { description: Unauthorized }
//  */
// router.get('/history/:empid', verifyToken, isUser, ctrl.getEmployeeAttendance);

// /**
//  * @swagger
//  * /api/attendance/all:
//  *   get:
//  *     summary: Get all attendance records (admin)
//  *     description: 'Requires Authorization: Bearer <JWT>.'
//  *     tags: [Attendance]
//  *     security:
//  *       - bearerAuth: []
//  *     responses:
//  *       200: { description: OK }
//  *       401: { description: Unauthorized }
//  *       403: { description: Forbidden }
//  */
// router.get('/all', verifyToken, isAdmin, ctrl.getAllAttendance);

// /**
//  * @swagger
//  * /api/attendance/approve:
//  *   post:
//  *     summary: Approve or reject an attendance entry (admin)
//  *     description: 'Requires Authorization: Bearer <JWT>.'
//  *     tags: [Attendance]
//  *     security:
//  *       - bearerAuth: []
//  *     responses:
//  *       200: { description: Approval updated }
//  *       401: { description: Unauthorized }
//  *       403: { description: Forbidden }
//  */
// router.post('/approve', verifyToken, isAdmin, ctrl.approveAttendance);

// /**
//  * @swagger
//  * /api/attendance/summary/{empid}/{year}/{month}:
//  *   get:
//  *     summary: Monthly attendance summary (raw records for the month)
//  *     description: 'Requires Authorization: Bearer <JWT>.'
//  *     tags: [Attendance]
//  *     security:
//  *       - bearerAuth: []
//  *     parameters:
//  *       - in: path
//  *         name: empid
//  *         required: true
//  *         schema:
//  *           type: string
//  *       - in: path
//  *         name: year
//  *         required: true
//  *         schema:
//  *           type: string
//  *       - in: path
//  *         name: month
//  *         required: true
//  *         schema:
//  *           type: string
//  *     responses:
//  *       200: { description: OK }
//  */
// router.get('/summary/:empid/:year/:month', verifyToken, isUser, ctrl.getMonthlySummary);

// /**
//  * @swagger
//  * /api/attendance/roster:
//  *   get:
//  *     summary: Daily active/inactive roster (admin)
//  *     description: 'Requires Authorization: Bearer <JWT>.'
//  *     tags: [Attendance]
//  *     security:
//  *       - bearerAuth: []
//  *     parameters:
//  *       - in: query
//  *         name: date
//  *         required: true
//  *         schema:
//  *           type: string
//  *           example: '2025-08-11'
//  *     responses:
//  *       200: { description: OK }
//  *       400: { description: Missing date }
//  */
// router.get('/roster', verifyToken, isAdmin, ctrl.getDailyRoster);

// /**
//  * @swagger
//  * /api/attendance/month-view/{empid}/{year}/{month}:
//  *   get:
//  *     summary: Month view aggregate (day statuses, totals, extras)
//  *     description: 'Requires Authorization: Bearer <JWT>.'
//  *     tags: [Attendance]
//  *     security:
//  *       - bearerAuth: []
//  *     parameters:
//  *       - in: path
//  *         name: empid
//  *         required: true
//  *         schema:
//  *           type: string
//  *       - in: path
//  *         name: year
//  *         required: true
//  *         schema:
//  *           type: string
//  *       - in: path
//  *         name: month
//  *         required: true
//  *         schema:
//  *           type: string
//  *     responses:
//  *       200: { description: OK }
//  */
// router.get('/month-view/:empid/:year/:month', verifyToken, isUser, ctrl.getMonthView);

// /**
//  * @swagger
//  * /api/attendance/approvals:
//  *   get:
//  *     summary: List approval requests across attendance (late in/out) and leaves
//  *     description: 'Requires Authorization: Bearer <JWT>. Admin only.'
//  *     tags: [Attendance]
//  *     security:
//  *       - bearerAuth: []
//  *     parameters:
//  *       - in: query
//  *         name: type
//  *         schema:
//  *           type: string
//  *           example: All
//  *       - in: query
//  *         name: status
//  *         schema:
//  *           type: string
//  *           example: Pending
//  *       - in: query
//  *         name: start
//  *         schema:
//  *           type: string
//  *       - in: query
//  *         name: end
//  *         schema:
//  *           type: string
//  *     responses:
//  *       200: { description: OK }
//  *       401: { description: Unauthorized }
//  *       403: { description: Forbidden }
//  */
// router.get('/approvals', verifyToken, isAdmin, ctrl.listApprovalRequests);

// /**
//  * @swagger
//  * /api/attendance/approvals/decision:
//  *   post:
//  *     summary: Approve or reject a specific request (attendance or leaves)
//  *     description: 'Requires Authorization: Bearer <JWT>. Admin only.'
//  *     tags: [Attendance]
//  *     security:
//  *       - bearerAuth: []
//  *     responses:
//  *       200: { description: Decision applied }
//  *       400: { description: Bad request }
//  *       401: { description: Unauthorized }
//  *       403: { description: Forbidden }
//  *       404: { description: Not found }
//  */
// router.post('/approvals/decision', verifyToken, isAdmin, ctrl.decideApproval);

// /**
//  * @swagger
//  * /api/attendance/range-summary:
//  *   get:
//  *     summary: Aggregated counts + rows for a date range (admin)
//  *     description: 'Requires Authorization: Bearer <JWT>. Admin only.'
//  *     tags: [Attendance]
//  *     security:
//  *       - bearerAuth: []
//  *     parameters:
//  *       - in: query
//  *         name: start
//  *         required: true
//  *         schema:
//  *           type: string
//  *       - in: query
//  *         name: end
//  *         required: true
//  *         schema:
//  *           type: string
//  *     responses:
//  *       200: { description: OK }
//  */
// router.get('/range-summary', verifyToken, isAdmin, ctrl.getRangeSummary);

// /**
//  * @swagger
//  * /api/attendance/my-requests:
//  *   get:
//  *     summary: Current user's own requests (attendance + leaves)
//  *     description: 'Requires Authorization: Bearer <JWT>.'
//  *     tags: [Attendance]
//  *     security:
//  *       - bearerAuth: []
//  *     parameters:
//  *       - in: query
//  *         name: status
//  *         schema:
//  *           type: string
//  *           example: Pending
//  *       - in: query
//  *         name: start
//  *         schema:
//  *           type: string
//  *       - in: query
//  *         name: end
//  *         schema:
//  *           type: string
//  *     responses:
//  *       200: { description: OK }
//  */
// router.get('/my-requests', verifyToken, ctrl.listMyRequests); // ✅ use ctrl

// module.exports = router;
const express = require('express');
const router  = express.Router();

const ctrl = require('../controllers/attendanceController'); // ✅ correct import
const { verifyToken, isUserOrAdmin, isAdmin, isUser } = require('../middlewares/authMiddleware');

/**
 * @swagger
 * tags:
 *   - name: Attendance
 *     description: Attendance tracking (check-in/out, live view, history, admin)
 */

/* ---------- Sanity check: make sure all handlers exist ---------- */
const requiredHandlers = [
  'getCurrentUser',
  'checkIn',
  'checkOut',
  'getLiveAttendance',
  'getEmployeeAttendance',
  'getAllAttendance',
  'approveAttendance',
  'getMonthlySummary',
  'getDailyRoster',
  'getRangeSummary',
  'getMonthView',
  'listApprovalRequests',
  'decideApproval',
  'listMyRequests',
];

requiredHandlers.forEach((h) => {
  if (typeof ctrl[h] !== 'function') {
    console.error(`[routes/attendance] Missing handler: ${h} from controllers/attendanceController.js`);
  }
});

/** Health check */
router.get('/ping', (req, res) => res.send('pong'));

/**
 * @swagger
 * /api/attendance/me:
 *   get:
 *     summary: Get logged-in user’s empid, name, role & shiftGroup
 *     description: 'Requires Authorization: Bearer <JWT>.'
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User info
 *       401:
 *         description: Unauthorized
 */
router.get('/me', verifyToken, ctrl.getCurrentUser);

/**
 * @swagger
 * /api/attendance/check-in:
 *   post:
 *     summary: Employee Check-in
 *     description: 'Requires Authorization: Bearer <JWT>.'
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200: { description: Check-in updated / created }
 *       400: { description: Already checked in or invalid }
 *       401: { description: Unauthorized }
 *       500: { description: Server error }
 */
router.post('/check-in', verifyToken, isUser, ctrl.checkIn);

/**
 * @swagger
 * /api/attendance/check-out:
 *   post:
 *     summary: Employee Check-out
 *     description: 'Requires Authorization: Bearer <JWT>.'
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200: { description: Check-out successful }
 *       400: { description: Must check in first or already checked out }
 *       401: { description: Unauthorized }
 *       500: { description: Server error }
 */
router.post('/check-out', verifyToken, isUser, ctrl.checkOut);

/**
 * @swagger
 * /api/attendance/live:
 *   get:
 *     summary: Live attendance for today (admin sees all, user sees self)
 *     description: 'Requires Authorization: Bearer <JWT>.'
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200: { description: OK }
 *       401: { description: Unauthorized }
 *       403: { description: Forbidden }
 */
router.get('/live', verifyToken, isUserOrAdmin, ctrl.getLiveAttendance);

/**
 * @swagger
 * /api/attendance/history/{empid}:
 *   get:
 *     summary: Full attendance history for one employee
 *     description: 'Requires Authorization: Bearer <JWT>.'
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: empid
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200: { description: OK }
 *       401: { description: Unauthorized }
 */
router.get('/history/:empid', verifyToken, isUser, ctrl.getEmployeeAttendance);

/**
 * @swagger
 * /api/attendance/all:
 *   get:
 *     summary: Get all attendance records (admin)
 *     description: 'Requires Authorization: Bearer <JWT>.'
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200: { description: OK }
 *       401: { description: Unauthorized }
 *       403: { description: Forbidden }
 */
router.get('/all', verifyToken, isAdmin, ctrl.getAllAttendance);

/**
 * @swagger
 * /api/attendance/approve:
 *   post:
 *     summary: Approve or reject an attendance entry (admin)
 *     description: 'Requires Authorization: Bearer <JWT>.'
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200: { description: Approval updated }
 *       401: { description: Unauthorized }
 *       403: { description: Forbidden }
 */
router.post('/approve', verifyToken, isAdmin, ctrl.approveAttendance);

/**
 * @swagger
 * /api/attendance/summary/{empid}/{year}/{month}:
 *   get:
 *     summary: Monthly attendance summary (raw records for the month)
 *     description: 'Requires Authorization: Bearer <JWT>.'
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: empid
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: year
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: month
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200: { description: OK }
 */
router.get('/summary/:empid/:year/:month', verifyToken, isUser, ctrl.getMonthlySummary);

/**
 * @swagger
 * /api/attendance/roster:
 *   get:
 *     summary: Daily active/inactive roster (admin)
 *     description: 'Requires Authorization: Bearer <JWT>.'
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: date
 *         required: true
 *         schema:
 *           type: string
 *           example: '2025-08-11'
 *     responses:
 *       200: { description: OK }
 *       400: { description: Missing date }
 */
router.get('/roster', verifyToken, isAdmin, ctrl.getDailyRoster);

/**
 * @swagger
 * /api/attendance/month-view/{empid}/{year}/{month}:
 *   get:
 *     summary: Month view aggregate (day statuses, totals, extras)
 *     description: 'Requires Authorization: Bearer <JWT>.'
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: empid
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: year
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: month
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200: { description: OK }
 */
router.get('/month-view/:empid/:year/:month', verifyToken, isUser, ctrl.getMonthView);

/**
 * @swagger
 * /api/attendance/approvals:
 *   get:
 *     summary: List approval requests across attendance (late in/out) and leaves
 *     description: 'Requires Authorization: Bearer <JWT>. Admin only.'
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *           example: All
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           example: Pending
 *       - in: query
 *         name: start
 *         schema:
 *           type: string
 *       - in: query
 *         name: end
 *         schema:
 *           type: string
 *     responses:
 *       200: { description: OK }
 *       401: { description: Unauthorized }
 *       403: { description: Forbidden }
 */
router.get('/approvals', verifyToken, isAdmin, ctrl.listApprovalRequests);

/**
 * @swagger
 * /api/attendance/approvals/decision:
 *   post:
 *     summary: Approve or reject a specific request (attendance or leaves)
 *     description: 'Requires Authorization: Bearer <JWT>. Admin only.'
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200: { description: Decision applied }
 *       400: { description: Bad request }
 *       401: { description: Unauthorized }
 *       403: { description: Forbidden }
 *       404: { description: Not found }
 */
router.post('/approvals/decision', verifyToken, isAdmin, ctrl.decideApproval);

/**
 * @swagger
 * /api/attendance/range-summary:
 *   get:
 *     summary: Aggregated counts + rows for a date range (admin)
 *     description: 'Requires Authorization: Bearer <JWT>. Admin only.'
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: start
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: end
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200: { description: OK }
 */
router.get('/range-summary', verifyToken, isAdmin, ctrl.getRangeSummary);

/**
 * @swagger
 * /api/attendance/my-requests:
 *   get:
 *     summary: Current user's own requests (attendance + leaves)
 *     description: 'Requires Authorization: Bearer <JWT>.'
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           example: Pending
 *       - in: query
 *         name: start
 *         schema:
 *           type: string
 *       - in: query
 *         name: end
 *         schema:
 *           type: string
 *     responses:
 *       200: { description: OK }
 */
if (typeof ctrl.listMyRequests === 'function') {
  router.get('/my-requests', verifyToken, ctrl.listMyRequests);
} else {
  console.error('[routes/attendance] ctrl.listMyRequests is undefined – route will respond 500.');
  router.get('/my-requests', verifyToken, (req, res) =>
    res.status(500).json({ error: 'listMyRequests handler missing on server' })
  );
}

module.exports = router;
