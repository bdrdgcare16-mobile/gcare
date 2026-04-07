import { Router } from 'express';
import * as ctrl from '../controllers/leaveController';
import { verifyToken, roleMiddleware } from '../middlewares/authMiddleware';

const router = Router();

const isUserOrAdmin = roleMiddleware(['admin', 'employee']);
const isAdminOnly = roleMiddleware(['admin']);

router.post('/', verifyToken, isUserOrAdmin, ctrl.createLeaveRequest);
router.get('/', verifyToken, isUserOrAdmin, ctrl.getAllLeaveRequests);
router.get('/pending', verifyToken, isAdminOnly, ctrl.getPendingLeaves);
router.get('/balance', verifyToken, isUserOrAdmin, ctrl.getLeaveBalance);

router.put('/:id/status', verifyToken, isAdminOnly, ctrl.updateLeaveStatus);
router.put('/:id/cancel', verifyToken, isUserOrAdmin, ctrl.cancelLeaveRequest);
router.delete('/:id', verifyToken, isAdminOnly, ctrl.deleteLeave);

export default router;