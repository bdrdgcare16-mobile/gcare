import { Router } from 'express';
import * as leaveTypeController from '../controllers/leaveTypeController';
import { authMiddleware, roleMiddleware } from '../middlewares/authMiddleware';

const router = Router();

// Apply auth middleware to all routes
router.use(authMiddleware);

/**
 * @swagger
 * components:
 *   schemas:
 *     LeaveType:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *         type:
 *           type: string
 *           example: "Annual Leave"
 *         description:
 *           type: string
 *           example: "Paid time off work"
 *         allowedDays:
 *           type: integer
 *           example: 20
 *         carryForward:
 *           type: boolean
 *           example: true
 *         maxCarryForwardDays:
 *           type: integer
 *           example: 5
 *         requiresApproval:
 *           type: boolean
 *           example: true
 *         documentRequired:
 *           type: boolean
 *           example: false
 *         active:
 *           type: boolean
 *           example: true
 *         color:
 *           type: string
 *           example: "#3b82f6"
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 */

/**
 * @swagger
 * /api/leave-types:
 *   post:
 *     summary: Create a new leave type (Admin only)
 *     tags: [Leave Types]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - type
 *               - allowedDays
 *             properties:
 *               type:
 *                 type: string
 *                 example: "Sick Leave"
 *               description:
 *                 type: string
 *                 example: "Paid time off for health reasons"
 *               allowedDays:
 *                 type: integer
 *                 example: 10
 *               carryForward:
 *                 type: boolean
 *                 default: false
 *               maxCarryForwardDays:
 *                 type: integer
 *                 default: 0
 *               requiresApproval:
 *                 type: boolean
 *                 default: true
 *               documentRequired:
 *                 type: boolean
 *                 default: false
 *               active:
 *                 type: boolean
 *                 default: true
 *               color:
 *                 type: string
 *                 default: "#3b82f6"
 *     responses:
 *       201:
 *         description: Leave type created successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/LeaveType'
 *       400:
 *         description: Invalid input or missing required fields
 *       409:
 *         description: Leave type already exists
 *       500:
 *         description: Internal server error
 */
router.post('/', roleMiddleware(['admin']), leaveTypeController.createLeaveType);

/**
 * @swagger
 * /api/leave-types:
 *   get:
 *     summary: Get all leave types
 *     tags: [Leave Types]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: activeOnly
 *         schema:
 *           type: boolean
 *           default: true
 *         description: Whether to return only active leave types
 *     responses:
 *       200:
 *         description: List of leave types
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/LeaveType'
 *       500:
 *         description: Internal server error
 */
router.get('/', leaveTypeController.listLeaveTypes);

/**
 * @swagger
 * /api/leave-types/{id}:
 *   get:
 *     summary: Get a specific leave type by ID
 *     tags: [Leave Types]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Leave type ID
 *     responses:
 *       200:
 *         description: Leave type details
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/LeaveType'
 *       404:
 *         description: Leave type not found
 *       500:
 *         description: Internal server error
 */
router.get('/:id', leaveTypeController.getLeaveTypeById);

/**
 * @swagger
 * /api/leave-types/{id}:
 *   put:
 *     summary: Update a leave type (Admin only)
 *     tags: [Leave Types]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Leave type ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               type:
 *                 type: string
 *                 example: "Updated Sick Leave"
 *               description:
 *                 type: string
 *                 example: "Updated description"
 *               allowedDays:
 *                 type: integer
 *                 example: 15
 *               carryForward:
 *                 type: boolean
 *               maxCarryForwardDays:
 *                 type: integer
 *               requiresApproval:
 *                 type: boolean
 *               documentRequired:
 *                 type: boolean
 *               active:
 *                 type: boolean
 *               color:
 *                 type: string
 *     responses:
 *       200:
 *         description: Leave type updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/LeaveType'
 *       400:
 *         description: Invalid input
 *       404:
 *         description: Leave type not found
 *       500:
 *         description: Internal server error
 */
router.put('/:id', roleMiddleware(['admin']), leaveTypeController.updateLeaveType);

/**
 * @swagger
 * /api/leave-types/{id}:
 *   delete:
 *     summary: Delete a leave type (Admin only)
 *     tags: [Leave Types]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Leave type ID
 *     responses:
 *       200:
 *         description: Leave type deleted successfully
 *       400:
 *         description: Cannot delete leave type with associated leave requests
 *       404:
 *         description: Leave type not found
 *       500:
 *         description: Internal server error
 */
router.delete('/:id', roleMiddleware(['admin']), leaveTypeController.deleteLeaveType);

export default router;
