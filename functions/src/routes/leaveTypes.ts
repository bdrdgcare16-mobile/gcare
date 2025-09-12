// import { Router } from 'express';
// import * as ctrl from '../controllers/leaveTypeController';
// import { verifyToken, isAdmin } from '../middlewares/authMiddleware';

// const router = Router();

// /**
//  * @swagger
//  * components:
//  *   schemas:
//  *     LeaveType:
//  *       type: object
//  *       properties:
//  *         id:
//  *           type: string
//  *           description: The unique identifier for the leave type
//  *         name:
//  *           type: string
//  *           description: The name of the leave type
//  *         description:
//  *           type: string
//  *           description: Optional description of the leave type
//  *         maxDays:
//  *           type: number
//  *           description: Maximum number of days allowed for this leave type
//  *         isActive:
//  *           type: boolean
//  *           description: Whether the leave type is currently active
//  *         createdAt:
//  *           type: string
//  *           format: date-time
//  *           description: When the leave type was created
//  *         updatedAt:
//  *           type: string
//  *           format: date-time
//  *           description: When the leave type was last updated
//  *         createdBy:
//  *           type: string
//  *           description: ID of the user who created the leave type
//  */

// /**
//  * @swagger
//  * /api/leave-types:
//  *   post:
//  *     summary: Create a new leave type (Admin only)
//  *     tags: [Leave Types]
//  *     security:
//  *       - bearerAuth: []
//  *     requestBody:
//  *       required: true
//  *       content:
//  *         application/json:
//  *           schema:
//  *             type: object
//  *             required:
//  *               - name
//  *               - maxDays
//  *             properties:
//  *               name:
//  *                 type: string
//  *                 description: Name of the leave type (e.g., "Sick Leave", "Vacation")
//  *               description:
//  *                 type: string
//  *                 description: Optional description of the leave type
//  *               maxDays:
//  *                 type: number
//  *                 description: Maximum number of days allowed for this leave type
//  *     responses:
//  *       201:
//  *         description: Leave type created successfully
//  *         content:
//  *           application/json:
//  *             schema:
//  *               $ref: '#/components/schemas/LeaveType'
//  *       400:
//  *         description: Invalid input data
//  *       403:
//  *         description: Admin access required
//  *       500:
//  *         description: Server error
//  */
// router.post('/', verifyToken, isAdmin, ctrl.createLeaveType);

// /**
//  * @swagger
//  * /api/leave-types:
//  *   get:
//  *     summary: List all active leave types
//  *     tags: [Leave Types]
//  *     security:
//  *       - bearerAuth: []
//  *     responses:
//  *       200:
//  *         description: List of active leave types
//  *         content:
//  *           application/json:
//  *             schema:
//  *               type: array
//  *               items:
//  *                 $ref: '#/components/schemas/LeaveType'
//  *       500:
//  *         description: Server error
//  */
// router.get('/', verifyToken, ctrl.listLeaveTypes);

import { Router } from 'express';
import * as ctrl from '../controllers/leaveTypeController';
import { verifyToken, isAdmin, roleMiddleware } from '../middlewares/authMiddleware';

const router = Router();

// employees or admins may read; only admins may create
const isUserOrAdmin = roleMiddleware(['admin', 'employee']);

router.post('/', verifyToken, isAdmin, ctrl.createLeaveType);
router.get('/', verifyToken, isUserOrAdmin, ctrl.listLeaveTypes);

export default router;
