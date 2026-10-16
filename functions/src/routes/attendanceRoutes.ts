import { Router } from 'express';
import * as attendanceController from '../controllers/attendanceController';
import { authMiddleware, roleMiddleware } from '../middlewares/authMiddleware';
import { requireFeature } from '../middlewares/featureMiddleware';
import { hrFeatureGate } from '../middlewares/hrFeatureMiddleware';

const router = Router();

// Apply auth middleware to all routes
router.use(authMiddleware);

// Tenant entitlement: attendance feature must be enabled for this company
router.use(requireFeature('attendance'));

// HR callers additionally need the feature in their own approvedFeatures
// (hrFeatureGate is a no-op for admin/employee). Admin-facing endpoints are
// gated individually; employee self-service endpoints are left untouched.

// Leave approvals reuse the attendance approvals feed, so 'leave'-approved
// HR is allowed there; the decision endpoint keys off the request source.
export const approvalsSrc = (req: import('express').Request) =>
  String(req.body?.source || req.query?.src || '')
    .toLowerCase() === 'leaves'
    ? ['leave']
    : ['attendance'];

// Approval decisions are admin/HR only — employees must never decide
// requests, not even their own. HR additionally needs the matching
// approved feature (leave -> 'leave', everything else -> 'attendance').
const isAdminOrHr = roleMiddleware(['admin', 'hr']);
// Employee self-reads are allowed alongside admin/HR; the controllers
// force employee callers to their own token empid. company_admin is
// intentionally excluded — Company Admin manages HR users only.
const isAdminHrOrEmployee = roleMiddleware(['admin', 'hr', 'employee']);

router.get('/live', isAdminHrOrEmployee, hrFeatureGate(['attendance']), attendanceController.getLiveAttendance);
router.get('/approvals', isAdminOrHr, hrFeatureGate(['attendance', 'leave']), attendanceController.listApprovalRequests);
router.post('/approvals/decision', isAdminOrHr, hrFeatureGate(approvalsSrc), attendanceController.decideApproval);
router.get('/my-requests', attendanceController.listMyRequests);
router.get('/employee/:empid', isAdminHrOrEmployee, hrFeatureGate(['attendance']), attendanceController.getEmployeeAttendance);
router.get('/request-details', isAdminOrHr, hrFeatureGate(['attendance', 'leave']), attendanceController.getRequestDetails);
router.get('/monthly/:empid/:year/:month', isAdminHrOrEmployee, hrFeatureGate(['attendance']), attendanceController.getMonthlySummary);
router.get('/roster', isAdminOrHr, hrFeatureGate(['attendance']), attendanceController.getDailyRoster);
router.get('/range-summary', isAdminOrHr, hrFeatureGate(['reports', 'attendance']), attendanceController.getRangeSummary);
router.post('/check-in', attendanceController.checkIn);
router.post('/check-out', attendanceController.checkOut);
router.get('/other-location', isAdminOrHr, hrFeatureGate(['attendance']), attendanceController.listOtherLocationEvents);
router.post('/other-location/decision', isAdminOrHr, hrFeatureGate(['attendance']), attendanceController.decideOtherLocationEvent);
router.get('/other-location/ping', (_req, res) => res.json({ ok: true }));
router.get('/me', attendanceController.getCurrentUser);
router.get('/summary/:empid/:year/:month', isAdminHrOrEmployee, hrFeatureGate(['attendance']), attendanceController.getMonthlySummary);
router.get('/history', isAdminOrHr, hrFeatureGate(['attendance']), attendanceController.getAllAttendance);

export default router;