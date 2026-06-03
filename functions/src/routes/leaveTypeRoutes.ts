import { Router } from 'express';
import * as ctrl from '../controllers/leaveTypeController';
import { verifyToken, isAdmin, roleMiddleware } from '../middlewares/authMiddleware';

const router = Router();

const isUserOrAdmin = roleMiddleware(['admin', 'employee']);

router.post('/', verifyToken, isUserOrAdmin, ctrl.createLeaveType);
router.get('/', verifyToken, isUserOrAdmin, ctrl.listLeaveTypes);
router.put('/:id', verifyToken, isAdmin, ctrl.updateLeaveType);
router.delete('/:id', verifyToken, isAdmin, ctrl.deleteLeaveType);

export default router;