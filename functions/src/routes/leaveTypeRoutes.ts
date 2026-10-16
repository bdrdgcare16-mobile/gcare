import { Router } from 'express';
import * as ctrl from '../controllers/leaveTypeController';
import { verifyToken, roleMiddleware } from '../middlewares/authMiddleware';
import { requireFeature } from '../middlewares/featureMiddleware';
import { hrFeatureGate } from '../middlewares/hrFeatureMiddleware';

const router = Router();

// Leave types are module config — admin, employee (read/apply context),
// or HR with 'leave' approved.
const isLeaveActor = roleMiddleware(['admin', 'employee', 'hr']);
const isAdminOrHr = roleMiddleware(['admin', 'hr']);
const hrLeave = hrFeatureGate(['leave']);
const leaveEnabled = requireFeature('leave');

router.post('/', verifyToken, leaveEnabled, isLeaveActor, hrLeave, ctrl.createLeaveType);
router.get('/', verifyToken, leaveEnabled, isLeaveActor, hrLeave, ctrl.listLeaveTypes);
router.delete('/:id', verifyToken, leaveEnabled, isAdminOrHr, hrLeave, ctrl.deleteLeaveType);

export default router;