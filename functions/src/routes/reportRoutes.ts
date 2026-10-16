// routes/report.ts
import { Router } from 'express';
import * as ctrl from '../controllers/reportController';
import { authMiddleware, roleMiddleware } from '../middlewares/authMiddleware';
import { requireFeature } from '../middlewares/featureMiddleware';
import { hrFeatureGate } from '../middlewares/hrFeatureMiddleware';

const router = Router();

// All report routes require auth
router.use(authMiddleware);

// Tenant entitlement: reports feature
router.use(requireFeature('reports'));

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
 *         id: { type: string }
 *         name: { type: string }
 *         reportType:
 *           type: string
 *           enum: [Check-In, Check-Out, Present, Absent, Late Check-In]
 *         templateId: { type: string }
 *         recipient:
 *           type: string
 *           format: email
 *         scheduleTime: { type: string, description: 'Cron or HH:mm' }
 *         createdAt: { type: string, format: date-time }
 */

// HR inherits the tenant-admin reports module when 'reports' is in
// approvedFeatures.
const isAdminOrHr = roleMiddleware(['admin', 'hr']);
const hrReports = hrFeatureGate(['reports']);

// POST /api/reports
router.post('/', isAdminOrHr, hrReports, ctrl.createSchedule);

// GET /api/reports
router.get('/', isAdminOrHr, hrReports, ctrl.listSchedules);

// POST /api/reports/:id/run
router.post('/:id/run', isAdminOrHr, hrReports, ctrl.runNow);

// DELETE /api/reports/:id
router.delete('/:id', isAdminOrHr, hrReports, ctrl.deleteSchedule);

export default router;
