import { Router } from 'express';
import * as leaveController from '../controllers/leaveController';
import { authMiddleware, roleMiddleware } from '../middlewares/authMiddleware';

const router = Router();

// Apply auth middleware to all routes
router.use(authMiddleware);

/**
 * @swagger
 * components:
 *   schemas:
 *     LeaveRequest:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *         userId:
 *           type: string
 *         empid:
 *           type: string
 *         name:
 *           type: string
 *         leaveType:
 *           type: string
 *           enum: [Casual Leave, Planned Leave, Sick Leave, Half-Day, Overtime, Permission Time, Comp Off]
 *         startDate:
 *           type: string
 *           format: date
 *         endDate:
 *           type: string
 *           format: date
 *         reason:
 *           type: string
 *         status:
 *           type: string
 *           enum: [Pending, Approved, Rejected, Cancelled]
 *         session:
 *           type: string
 *           enum: [Morning, Afternoon]
 *         duration:
 *           type: number
 *         attachmentUrl:
 *           type: string
 *         approverId:
 *           type: string
 *         approverNotes:
 *           type: string
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 */

/**
 * @swagger
 * /api/leaves:
 *   post:
 *     summary: Create a new leave request
 *     tags: [Leaves]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - leaveType
 *               - startDate
 *               - endDate
 *               - reason
 *             properties:
 *               leaveType:
 *                 type: string
 *                 enum: [Casual Leave, Planned Leave, Sick Leave, Half-Day, Overtime, Permission Time, Comp Off]
 *               startDate:
 *                 type: string
 *                 format: date
 *               endDate:
 *                 type: string
 *                 format: date
 *               reason:
 *                 type: string
 *               session:
 *                 type: string
 *                 enum: [Morning, Afternoon]
 *                 description: Required for Half-Day leave type
 *               duration:
 *                 type: number
 *                 description: Required for Overtime and Permission Time leave types
 *               attachmentUrl:
 *                 type: string
 *                 format: uri
 *     responses:
 *       201:
 *         description: Leave request created successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/LeaveRequest'
 *       400:
 *         description: Invalid input or missing required fields
 *       500:
 *         description: Internal server error
 */
router.post('/', leaveController.createLeaveRequest);

/**
 * @swagger
 * /api/leaves:
 *   get:
 *     summary: Get all leave requests (admin) or filtered requests
 *     tags: [Leaves]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [Pending, Approved, Rejected, Cancelled]
 *         description: Filter by status
 *       - in: query
 *         name: userId
 *         schema:
 *           type: string
 *         description: Filter by user ID (admin only)
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Start date for filtering (YYYY-MM-DD)
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date
 *         description: End date for filtering (YYYY-MM-DD)
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page number for pagination
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *         description: Number of items per page
 *     responses:
 *       200:
 *         description: List of leave requests
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/LeaveRequest'
 *                 pagination:
 *                   type: object
 *                   properties:
 *                     page:
 *                       type: integer
 *                     limit:
 *                       type: integer
 *                     total:
 *                       type: integer
 *                     pages:
 *                       type: integer
 *       403:
 *         description: Unauthorized to view these leave requests
 *       500:
 *         description: Internal server error
 */
router.get('/', roleMiddleware(['admin']), leaveController.getAllLeaveRequests);

/**
 * @swagger
 * /api/leaves/my:
 *   get:
 *     summary: Get current user's leave requests
 *     tags: [Leaves]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [Pending, Approved, Rejected, Cancelled]
 *         description: Filter by status
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Start date for filtering (YYYY-MM-DD)
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date
 *         description: End date for filtering (YYYY-MM-DD)
 *     responses:
 *       200:
 *         description: List of user's leave requests
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/LeaveRequest'
 *       500:
 *         description: Internal server error
 */
router.get('/my', leaveController.getMyLeaveRequests);

/**
 * @swagger
 * /api/leaves/{id}:
 *   get:
 *     summary: Get a specific leave request by ID
 *     tags: [Leaves]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Leave request ID
 *     responses:
 *       200:
 *         description: Leave request details
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/LeaveRequest'
 *       403:
 *         description: Unauthorized to view this leave request
 *       404:
 *         description: Leave request not found
 *       500:
 *         description: Internal server error
 */
router.get('/:id', leaveController.getLeaveRequestById);

/**
 * @swagger
 * /api/leaves/{id}/status:
 *   put:
 *     summary: Update leave request status (approve/reject)
 *     tags: [Leaves]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Leave request ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - status
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [Approved, Rejected, Cancelled]
 *               notes:
 *                 type: string
 *     responses:
 *       200:
 *         description: Leave request status updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/LeaveRequest'
 *       400:
 *         description: Invalid status or leave request cannot be updated
 *       403:
 *         description: Unauthorized to update this leave request
 *       404:
 *         description: Leave request not found
 *       500:
 *         description: Internal server error
 */
router.put('/:id/status', roleMiddleware(['admin']), leaveController.updateLeaveStatus);

/**
 * @swagger
 * /api/leaves/{id}/cancel:
 *   post:
 *     summary: Cancel a leave request
 *     tags: [Leaves]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Leave request ID
 *     responses:
 *       200:
 *         description: Leave request cancelled successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/LeaveRequest'
 *       400:
 *         description: Leave request cannot be cancelled
 *       403:
 *         description: Unauthorized to cancel this leave request
 *       404:
 *         description: Leave request not found
 *       500:
 *         description: Internal server error
 */
router.post('/:id/cancel', leaveController.cancelLeaveRequest);

/**
 * @swagger
 * /api/leaves/balance:
 *   get:
 *     summary: Get current user's leave balance
 *     tags: [Leaves]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Leave balance retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 casualLeaves:
 *                   type: number
 *                 sickLeaves:
 *                   type: number
 *                 plannedLeaves:
 *                   type: number
 *                 compOff:
 *                   type: number
 *       500:
 *         description: Internal server error
 */
router.get('/balance', leaveController.getLeaveBalance);

export default router;
