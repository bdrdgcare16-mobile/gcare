import { Router } from 'express';
import * as ctrl from '../controllers/leaveTypeController';
import { verifyToken, isAdmin, roleMiddleware } from '../middlewares/authMiddleware';

const router = Router();

/**
 * NOTE:
 * This router must be mounted at `/api/leave-types` in index.ts:
 *   app.use('/api/leave-types', leaveTypeRoutes);
 */

// Allow employees or admins to read
const isUserOrAdmin = roleMiddleware(['admin', 'employee']);

/**
 * @swagger
 * /api/leave-types:
 *   post:
 *     summary: Create a new leave type (Admin only)
 *     tags: [Leave Types]
 *     security:
 *       - bearerAuth: []
 */
router.post('/', verifyToken, isAdmin, ctrl.createLeaveType);

/**
 * @swagger
 * /api/leave-types:
 *   get:
 *     summary: List active leave types (Employee or Admin)
 *     tags: [Leave Types]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: shift
 *         schema:
 *           type: string
 *         required: false
 *         description: Filter by shift name
 */
router.get('/', verifyToken, isUserOrAdmin, ctrl.listLeaveTypes);

export default router;
