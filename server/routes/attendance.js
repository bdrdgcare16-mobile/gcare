
// // 
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
