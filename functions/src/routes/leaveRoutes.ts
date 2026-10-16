import { Router } from 'express';
import * as ctrl from '../controllers/leaveController';
import { verifyToken, roleMiddleware } from '../middlewares/authMiddleware';
import { requireFeature } from '../middlewares/featureMiddleware';
import { hrFeatureGate } from '../middlewares/hrFeatureMiddleware';

const router = Router();

const isUserOrAdmin = roleMiddleware(['admin', 'employee']);
// HR inherits the tenant-admin leave module when 'leave' is in
// approvedFeatures — view, decide and delete requests.
const isAdminOrHr = roleMiddleware(['admin', 'hr']);
const hrLeave = hrFeatureGate(['leave']);
const leaveEnabled = requireFeature('leave');

router.post('/', verifyToken, leaveEnabled, isUserOrAdmin, ctrl.createLeaveRequest);
router.get('/', verifyToken, leaveEnabled, isUserOrAdmin, ctrl.getAllLeaveRequests);
router.get('/pending', verifyToken, leaveEnabled, isAdminOrHr, hrLeave, ctrl.getPendingLeaves);
router.get('/balance', verifyToken, leaveEnabled, isUserOrAdmin, ctrl.getLeaveBalance);

router.put('/:id/status', verifyToken, leaveEnabled, isAdminOrHr, hrLeave, ctrl.updateLeaveStatus);
router.put('/:id/cancel', verifyToken, leaveEnabled, isUserOrAdmin, ctrl.cancelLeaveRequest);
router.delete('/:id', verifyToken, leaveEnabled, isAdminOrHr, hrLeave, ctrl.deleteLeave);

export default router;