// routes/leave.js
const express = require('express');
const router = express.Router();
const leaveController = require('../controllers/leaveController');

// ✅ import from your existing middleware
const {
  verifyToken,      // validates JWT and sets req.user
  isAdmin,          // role: admin
  isUserOrAdmin     // role: employee/user/admin
} = require('../middlewares/authMiddleware');

/**
 * @swagger
 * tags:
 *   name: Leaves
 *   description: Employee leave requests
 */

/**
 * @swagger
 * /api/leaves:
 *   post:
 *     summary: Create a leave request
 *     tags: [Leaves]
 *     security: [{ BearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/LeaveCreateRequest'
 *           example:
 *             type: "Casual Leave"
 *             startDate: "2025-08-09T00:00:00.000Z"
 *             endDate: "2025-08-10T00:00:00.000Z"
 *             reason: "Family function"
 *             selectShift: "Shift 1"
 *     responses:
 *       201:
 *         description: Created
 *       400:
 *         description: Validation error
 *       403:
 *         description: Forbidden
 *       404:
 *         description: User not found
 */
router.post('/', verifyToken, isUserOrAdmin, leaveController.createLeave);

/**
 * @swagger
 * /api/leaves/mine:
 *   get:
 *     summary: List my leave requests
 *     tags: [Leaves]
 *     security: [{ BearerAuth: [] }]
 *     responses:
 *       200:
 *         description: My leaves
 */
router.get('/mine', verifyToken, isUserOrAdmin, leaveController.getMyLeaves);

/**
 * @swagger
 * /api/leaves:
 *   get:
 *     summary: List all leave requests (admin)
 *     tags: [Leaves]
 *     security: [{ BearerAuth: [] }]
 *     responses:
 *       200:
 *         description: All leaves
 */
router.get('/', verifyToken, isAdmin, leaveController.getAllLeaves);

/**
 * @swagger
 * /api/leaves/pending:
 *   get:
 *     summary: List pending leave requests (optionally filter by type)
 *     tags: [Leaves]
 *     security: [{ BearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *           enum: [Casual Leave, Planned Leave, Sick Leave, Half-Day, Overtime, Permission Time, Comp Off]
 *     responses:
 *       200:
 *         description: Pending leaves
 */
router.get('/pending', verifyToken, isAdmin, leaveController.getPendingLeaves);

/**
 * @swagger
 * /api/leaves/{id}:
 *   get:
 *     summary: Get a leave by ID
 *     tags: [Leaves]
 *     security: [{ BearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         schema: { type: string }
 *         required: true
 *     responses:
 *       200:
 *         description: The leave
 *       404:
 *         description: Not found
 */
router.get('/:id', verifyToken, isUserOrAdmin, leaveController.getLeaveById);

/**
 * @swagger
 * /api/leaves/{id}:
 *   put:
 *     summary: Update a leave status (admin)
 *     tags: [Leaves]
 *     security: [{ BearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         schema: { type: string }
 *         required: true
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/LeaveUpdateRequest'
 *           example:
 *             status: "Approved"
 *             adminNotes: "Approved by HR"
 *     responses:
 *       200:
 *         description: Updated
 *       400:
 *         description: Invalid status
 *       404:
 *         description: Not found
 */
router.put('/:id', verifyToken, isAdmin, leaveController.updateLeave);

/**
 * @swagger
 * /api/leaves/{id}:
 *   delete:
 *     summary: Delete a leave request (admin)
 *     tags: [Leaves]
 *     security: [{ BearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         schema: { type: string }
 *         required: true
 *     responses:
 *       200:
 *         description: Deleted
 */
router.delete('/:id', verifyToken, isAdmin, leaveController.deleteLeave);

module.exports = router;
