// routes/reports.js
const router = require('express').Router();
const ctrl   = require('../controllers/reportController');
const { verifyToken, isAdmin } = require('../middlewares/authMiddleware');

/**
 * @swagger
 * tags:
 *   - name: Reports
 *     description: Report scheduler
 *
 * components:
 *   schemas:
 *     ReportSchedule:
 *       type: object
 *       required: [name, reportType, templateId, recipient, scheduleTime]
 *       properties:
 *         id:
 *           type: string
 *         name:
 *           type: string
 *         reportType:
 *           type: string
 *           enum: [Check-In, Check-Out, Present, Absent, Late Check-In]
 *         templateId:
 *           type: string
 *         recipient:
 *           type: string
 *           format: email
 *         scheduleTime:
 *           type: string
 *           description: Cron expression or "HH:mm"
 *         createdAt:
 *           type: string
 *           format: date-time
 */

/**
 * @swagger
 * /api/reports:
 *   post:
 *     summary: Create a report schedule
 *     tags: [Reports]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/ReportSchedule'
 *     responses:
 *       201:
 *         description: Schedule created
 *       400:
 *         description: Validation error
 *       500:
 *         description: Server error
 */
router.post(
  '/',
  verifyToken,
  isAdmin,
  ctrl.createSchedule
);

/**
 * @swagger
 * /api/reports:
 *   get:
 *     summary: List all report schedules
 *     tags: [Reports]
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200:
 *         description: Array of schedules
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/ReportSchedule'
 *       500:
 *         description: Server error
 */
router.get(
  '/',
  verifyToken,
  isAdmin,
  ctrl.listSchedules
);
/**
 * @swagger
 * /api/reports/{id}/run:
 *   post:
 *     summary: Manually trigger a report schedule (admin only)
 *     tags: [Reports]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Triggered
 *       404:
 *         description: Not found
 *       500:
 *         description: Server error
 */
router.post(
  '/:id/run',
  verifyToken,
  isAdmin,
  ctrl.runNow
  );



/**
 * @swagger
 * /api/reports/{id}:
 *   delete:
 *     summary: Delete a schedule
 *     tags: [Reports]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Deleted
 *       500:
 *         description: Server error
 */
router.delete(
  '/:id',
  verifyToken,
  isAdmin,
  ctrl.deleteSchedule
);

module.exports = router;
