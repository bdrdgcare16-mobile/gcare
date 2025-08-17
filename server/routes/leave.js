
// /**
//  * @swagger
//  * tags:
//  *   - name: Leaves
//  *     description: CRUD operations for leave/shift/permission requests
//  *
//  * components:
//  *   schemas:
//  *     Leave:
//  *       type: object
//  *       properties:
//  *         id:
//  *           type: string
//  *           format: uuid
//  *           description: Unique identifier for the leave request
//  *         userId:
//  *           type: string
//  *           description: Firebase UID of the requester
//  *         empid:
//  *           type: string
//  *           description: Employee ID (embedded from users collection)
//  *         selectDate:
//  *           type: string
//  *           format: date
//  *           description: The date selected in the form
//  *         selectShift:
//  *           type: string
//  *           description: The shift selected in the form
//  *         startTime:
//  *           type: string
//  *           description: The start time picked by the user (e.g. "04:00 AM")
//  *         endTime:
//  *           type: string
//  *           description: The end time picked by the user (e.g. "03:00 PM")
//  *         type:
//  *           type: string
//  *           enum: [Casual Leave, Planned Leave, Sick Leave, Half-Day, Overtime, Permission Time, Comp Off]
//  *           description: Type of leave/shift request
//  *         reason:
//  *           type: string
//  *           description: Reason provided by the user
//  *         date:
//  *           type: string
//  *           format: date
//  *           description: Canonical date for half-day/overtime/permission
//  *         session:
//  *           type: string
//  *           description: Morning/Afternoon for half-day
//  *         duration:
//  *           type: number
//  *           description: Computed hours for overtime or permission
//  *         startDate:
//  *           type: string
//  *           format: date
//  *           description: For multi-day leaves & comp-off
//  *         endDate:
//  *           type: string
//  *           format: date
//  *           description: For multi-day leaves & comp-off
//  *         leaveCount:
//  *           type: number
//  *           description: Number of days (or 0.5 for half-day)
//  *         documentUrl:
//  *           type: string
//  *           description: Optional link to a supporting document
//  *         imageUrl:
//  *           type: string
//  *           description: Optional link to an image capture
//  *         status:
//  *           type: string
//  *           enum: [Pending, Approved, Rejected]
//  *           description: Current approval status
//  *         requestedAt:
//  *           type: string
//  *           format: date-time
//  *           description: Timestamp when the request was created
//  *         reviewedAt:
//  *           type: string
//  *           format: date-time
//  *           description: Timestamp when admin reviewed
//  *         reviewedBy:
//  *           type: string
//  *           description: Admin UID who reviewed
//  *         adminNotes:
//  *           type: string
//  *           description: Optional admin comments on approval/rejection
//  *       required:
//  *         - id
//  *         - userId
//  *         - empid
//  *         - type
//  *         - status
//  *         - requestedAt
//  *
//  */

// /**
//  * @swagger
//  * /api/leaves:
//  *   post:
//  *     summary: Create a new leave/shift/permission request
//  *     tags: [Leaves]
//  *     security:
//  *       - bearerAuth: []
//  *     requestBody:
//  *       required: true
//  *       content:
//  *         application/json:
//  *           schema:
//  *             type: object
//  *             properties:
//  *               selectDate:
//  *                 type: string
//  *                 format: date
//  *               selectShift:
//  *                 type: string
//  *               startTime:
//  *                 type: string
//  *               endTime:
//  *                 type: string
//  *               // Multi-day inputs (compat with UI):
//  *               startDate:
//  *                 type: string
//  *                 format: date
//  *               endDate:
//  *                 type: string
//  *                 format: date
//  *               fromDate:
//  *                 type: string
//  *                 format: date
//  *               toDate:
//  *                 type: string
//  *                 format: date
//  *               leaveCount:
//  *                 type: number
//  *               type:
//  *                 type: string
//  *                 enum: [Casual Leave, Planned Leave, Sick Leave, Half-Day, Overtime, Permission Time, Comp Off]
//  *               reason:
//  *                 type: string
//  *             required:
//  *               - type
//  *   get:
//  *     summary: Get all leave requests (admin only)
//  *     tags: [Leaves]
//  *     security:
//  *       - bearerAuth: []
//  *     responses:
//  *       '200':
//  *         description: Array of all leaves
//  *         content:
//  *           application/json:
//  *             schema:
//  *               type: array
//  *               items:
//  *                 $ref: '#/components/schemas/Leave'
//  *       '401':
//  *         description: Unauthorized
//  *       '403':
//  *         description: Forbidden
//  */

// /**
//  * @swagger
//  * /api/leaves/my:
//  *   get:
//  *     summary: Get the authenticated user’s leave requests
//  *     tags: [Leaves]
//  *     security:
//  *       - bearerAuth: []
//  *     responses:
//  *       '200':
//  *         description: Array of user’s leaves
//  *         content:
//  *           application/json:
//  *             schema:
//  *               type: array
//  *               items:
//  *                 $ref: '#/components/schemas/Leave'
//  *       '401':
//  *         description: Unauthorized
//  */

// /**
//  * @swagger
//  * /api/leaves/pending:
//  *   get:
//  *     summary: Get all pending leave requests (admin only)
//  *     tags: [Leaves]
//  *     security:
//  *       - bearerAuth: []
//  *     parameters:
//  *       - in: query
//  *         name: type
//  *         schema:
//  *           type: string
//  *           enum: [Casual Leave, Planned Leave, Sick Leave, Half-Day, Overtime, Permission Time, Comp Off]
//  *         description: Filter by request type
//  *     responses:
//  *       '200':
//  *         description: Array of pending leaves
//  *         content:
//  *           application/json:
//  *             schema:
//  *               type: array
//  *               items:
//  *                 $ref: '#/components/schemas/Leave'
//  *       '401':
//  *         description: Unauthorized
//  *       '403':
//  *         description: Forbidden
//  */

// /**
//  * @swagger
//  * /api/leaves/{id}:
//  *   get:
//  *     summary: Get one leave request by ID (owner or admin)
//  *     tags: [Leaves]
//  *     security:
//  *       - bearerAuth: []
//  *     parameters:
//  *       - in: path
//  *         name: id
//  *         required: true
//  *         schema:
//  *           type: string
//  *           format: uuid
//  *         description: Leave request ID
//  *     responses:
//  *       '200':
//  *         description: Leave object
//  *         content:
//  *           application/json:
//  *             schema:
//  *               $ref: '#/components/schemas/Leave'
//  *       '401':
//  *         description: Unauthorized
//  *       '403':
//  *         description: Forbidden
//  *       '404':
//  *         description: Not found
//  *
//  *   put:
//  *     summary: Approve or reject a leave request (admin only)
//  *     tags: [Leaves]
//  *     security:
//  *       - bearerAuth: []
//  *     parameters:
//  *       - in: path
//  *         name: id
//  *         required: true
//  *         schema:
//  *           type: string
//  *           format: uuid
//  *         description: Leave request ID
//  *     requestBody:
//  *       required: true
//  *       content:
//  *         application/json:
//  *           schema:
//  *             type: object
//  *             properties:
//  *               status:
//  *                 type: string
//  *                 enum: [Pending, Approved, Rejected]
//  *               adminNotes:
//  *                 type: string
//  *     responses:
//  *       '200':
//  *         description: Updated leave record
//  *         content:
//  *           application/json:
//  *             schema:
//  *               $ref: '#/components/schemas/Leave'
//  *       '400':
//  *         description: Validation error
//  *       '401':
//  *         description: Unauthorized
//  *       '403':
//  *         description: Forbidden
//  *       '404':
//  *         description: Not found
//  *
//  *   delete:
//  *     summary: Delete a leave request (admin only)
//  *     tags: [Leaves]
//  *     security:
//  *       - bearerAuth: []
//  *     parameters:
//  *       - in: path
//  *         name: id
//  *         required: true
//  *         schema:
//  *           type: string
//  *           format: uuid
//  *         description: Leave request ID
//  *     responses:
//  *       '200':
//  *         description: Deletion confirmation
//  *       '401':
//  *         description: Unauthorized
//  *       '403':
//  *         description: Forbidden
//  *       '404':
//  *         description: Not found
//  */

// const router = require('express').Router();
// const leaveController = require('../controllers/leaveController');
// const { verifyToken, isAdmin, isUser } = require('../middlewares/authMiddleware');

// // 1. Apply for any request-type (Half-Day, Overtime, Permission Time, Comp Off, Casual/Planned/Sick Leave)
// router.post('/', verifyToken, isUser, leaveController.createLeave);

// // 2. User: list your own requests
// router.get('/my', verifyToken, isUser, leaveController.getMyLeaves);

// // 3. Admin: list all requests
// router.get('/', verifyToken, isAdmin, leaveController.getAllLeaves);

// // 4. Admin: list only pending requests (optional ?type=Overtime etc.)
// router.get('/pending', verifyToken, isAdmin, leaveController.getPendingLeaves);

// // 5. Get one request (owner or admin)
// router.get('/:id', verifyToken, leaveController.getLeaveById);

// // 6. Admin: approve/reject
// router.put('/:id', verifyToken, isAdmin, leaveController.updateLeave);

// // 7. Admin: delete request
// router.delete('/:id', verifyToken, isAdmin, leaveController.deleteLeave);

// module.exports = router;
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
