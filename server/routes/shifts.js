// const router = require('express').Router();
// const shiftController = require('../controllers/shiftController');
// const { verifyToken, isAdmin } = require('../middlewares/authMiddleware');

// /**
//  * @swagger
//  * tags:
//  *   - name: Shifts
//  *     description: CRUD operations for shift templates
//  *
//  * components:
//  *   schemas:
//  *     Shift:
//  *       type: object
//  *       properties:
//  *         id:
//  *           type: string
//  *           format: uuid
//  *           description: Unique shift template ID
//  *         name:
//  *           type: string
//  *           description: Descriptive name for the shift
//  *         startTime:
//  *           type: string
//  *           pattern: "^(?:[01]\\d|2[0-3]):[0-5]\\d$"
//  *           description: Shift start time in HH:mm (24‑hour)
//  *         endTime:
//  *           type: string
//  *           pattern: "^(?:[01]\\d|2[0-3]):[0-5]\\d$"
//  *           description: Shift end time in HH:mm
//  *         group:
//  *           type: string
//  *           description: Group or category of the shift (e.g. "Day Shift")
//  *         createdAt:
//  *           type: string
//  *           format: date-time
//  *         updatedAt:
//  *           type: string
//  *           format: date-time
//  *       required:
//  *         - id
//  *         - name
//  *         - startTime
//  *         - endTime
//  *         - group
//  *
//  *   parameters:
//  *     ShiftId:
//  *       in: path
//  *       name: id
//  *       required: true
//  *       schema:
//  *         type: string
//  *         format: uuid
//  *       description: The shift template’s UUID
//  */

// /**
//  * @swagger
//  * /api/shifts:
//  *   post:
//  *     summary: Create a new shift template (Admin only)
//  *     tags: [Shifts]
//  *     security:
//  *       - bearerAuth: []
//  *     requestBody:
//  *       description: Shift template data
//  *       required: true
//  *       content:
//  *         application/json:
//  *           schema:
//  *             type: object
//  *             required:
//  *               - name
//  *               - startTime
//  *               - endTime
//  *               - group
//  *             properties:
//  *               name:
//  *                 type: string
//  *               startTime:
//  *                 type: string
//  *                 pattern: "^(?:[01]\\d|2[0-3]):[0-5]\\d$"
//  *               endTime:
//  *                 type: string
//  *                 pattern: "^(?:[01]\\d|2[0-3]):[0-5]\\d$"
//  *               group:
//  *                 type: string
//  *     responses:
//  *       '201':
//  *         description: Created shift template
//  *         content:
//  *           application/json:
//  *             schema:
//  *               $ref: '#/components/schemas/Shift'
//  *       '400':
//  *         description: Validation error
//  *       '401':
//  *         description: Unauthorized
//  *       '403':
//  *         description: Forbidden
//  *       '500':
//  *         description: Internal server error
//  */
// router.post('/', verifyToken, isAdmin, shiftController.createShift);

// /**
//  * @swagger
//  * /api/shifts:
//  *   get:
//  *     summary: List all shift templates (Admin only)
//  *     tags: [Shifts]
//  *     security:
//  *       - bearerAuth: []
//  *     responses:
//  *       '200':
//  *         description: Array of shift templates
//  *         content:
//  *           application/json:
//  *             schema:
//  *               type: array
//  *               items:
//  *                 $ref: '#/components/schemas/Shift'
//  *       '401':
//  *         description: Unauthorized
//  *       '403':
//  *         description: Forbidden
//  *       '500':
//  *         description: Internal server error
//  */
// router.get('/', verifyToken, isAdmin, shiftController.getAllShifts);

// /**
//  * @swagger
//  * /api/shifts/{id}:
//  *   get:
//  *     summary: Get a single shift template by UUID (Admin only)
//  *     tags: [Shifts]
//  *     security:
//  *       - bearerAuth: []
//  *     parameters:
//  *       - $ref: '#/components/parameters/ShiftId'
//  *     responses:
//  *       '200':
//  *         description: Shift template object
//  *         content:
//  *           application/json:
//  *             schema:
//  *               $ref: '#/components/schemas/Shift'
//  *       '401':
//  *         description: Unauthorized
//  *       '403':
//  *         description: Forbidden
//  *       '404':
//  *         description: Not found
//  *       '500':
//  *         description: Internal server error
//  */
// router.get('/:id', verifyToken, isAdmin, shiftController.getShiftById);

// /**
//  * @swagger
//  * /api/shifts/{id}:
//  *   put:
//  *     summary: Update a shift template (Admin only)
//  *     tags: [Shifts]
//  *     security:
//  *       - bearerAuth: []
//  *     parameters:
//  *       - $ref: '#/components/parameters/ShiftId'
//  *     requestBody:
//  *       description: Fields to update
//  *       required: true
//  *       content:
//  *         application/json:
//  *           schema:
//  *             type: object
//  *             properties:
//  *               name:
//  *                 type: string
//  *               startTime:
//  *                 type: string
//  *                 pattern: "^(?:[01]\\d|2[0-3]):[0-5]\\d$"
//  *               endTime:
//  *                 type: string
//  *                 pattern: "^(?:[01]\\d|2[0-3]):[0-5]\\d$"
//  *               group:
//  *                 type: string
//  *     responses:
//  *       '200':
//  *         description: Updated shift template
//  *         content:
//  *           application/json:
//  *             schema:
//  *               $ref: '#/components/schemas/Shift'
//  *       '400':
//  *         description: Validation error
//  *       '401':
//  *         description: Unauthorized
//  *       '403':
//  *         description: Forbidden
//  *       '404':
//  *         description: Not found
//  *       '500':
//  *         description: Internal server error
//  */
// router.put('/:id', verifyToken, isAdmin, shiftController.updateShift);

// /**
//  * @swagger
//  * /api/shifts/{id}:
//  *   delete:
//  *     summary: Delete a shift template (Admin only)
//  *     tags: [Shifts]
//  *     security:
//  *       - bearerAuth: []
//  *     parameters:
//  *       - $ref: '#/components/parameters/ShiftId'
//  *     responses:
//  *       '200':
//  *         description: Deletion confirmation
//  *         content:
//  *           application/json:
//  *             schema:
//  *               type: object
//  *               properties:
//  *                 message:
//  *                   type: string
//  *       '401':
//  *         description: Unauthorized
//  *       '403':
//  *         description: Forbidden
//  *       '404':
//  *         description: Not found
//  *       '500':
//  *         description: Internal server error
//  */
// router.delete('/:id', verifyToken, isAdmin, shiftController.deleteShift);

// module.exports = router;
// routes/shifts.js
const express = require('express');
const router = express.Router();
const shiftController = require('../controllers/shiftController');
const { verifyToken, isAdmin } = require('../middlewares/authMiddleware');

/**
 * @swagger
 * tags:
 *   - name: Shifts
 *     description: CRUD operations for shift templates
 *
 * components:
 *   schemas:
 *     Shift:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *           description: Unique shift template ID
 *         name:
 *           type: string
 *           description: Descriptive name for the shift
 *         startTime:
 *           type: string
 *           pattern: '^(?:[01]\\d|2[0-3]):[0-5]\\d$'
 *           description: Shift start time in HH:mm (24-hour)
 *         endTime:
 *           type: string
 *           pattern: '^(?:[01]\\d|2[0-3]):[0-5]\\d$'
 *           description: Shift end time in HH:mm (24-hour)
 *         shiftname:
 *           type: string
 *           description: shiftname or category of the shift (e.g. "Day Shift")
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 *       required:
 *         - id
 *         - name
 *         - startTime
 *         - endTime
 *         - shiftname
 *
 *   parameters:
 *     ShiftId:
 *       in: path
 *       name: id
 *       required: true
 *       schema:
 *         type: string
 *         format: uuid
 *       description: The shift template’s UUID
 */

/**
 * @swagger
 * /api/shifts:
 *   post:
 *     summary: Create a new shift template (Admin only)
 *     tags: [Shifts]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       description: Shift template data
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - startTime
 *               - endTime
 *               - shiftname
 *             properties:
 *               name:
 *                 type: string
 *               startTime:
 *                 type: string
 *                 pattern: '^(?:[01]\\d|2[0-3]):[0-5]\\d$'
 *               endTime:
 *                 type: string
 *                 pattern: '^(?:[01]\\d|2[0-3]):[0-5]\\d$'
 *               shiftname:
 *                 type: string
 *     responses:
 *       201:
 *         description: Created shift template
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Shift'
 *       400:
 *         description: Validation error (missing fields)
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden (non-admin)
 *       500:
 *         description: Internal server error
 */
router.post(
  '/',
  verifyToken,
  isAdmin,
  shiftController.createShift
);

/**
 * @swagger
 * /api/shifts:
 *   get:
 *     summary: List all shift templates (Admin only)
 *     tags: [Shifts]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Array of shift templates
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Shift'
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden (non-admin)
 *       500:
 *         description: Internal server error
 */
router.get(
  '/',
  verifyToken,
  isAdmin,
  shiftController.getAllShifts
);

/**
 * @swagger
 * /api/shifts/{id}:
 *   get:
 *     summary: Get a single shift template by UUID (Admin only)
 *     tags: [Shifts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - $ref: '#/components/parameters/ShiftId'
 *     responses:
 *       200:
 *         description: Shift template object
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Shift'
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden (non-admin)
 *       404:
 *         description: Shift not found
 *       500:
 *         description: Internal server error
 */
router.get(
  '/:id',
  verifyToken,
  isAdmin,
  shiftController.getShiftById
);

/**
 * @swagger
 * /api/shifts/{id}:
 *   put:
 *     summary: Update a shift template (Admin only)
 *     tags: [Shifts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - $ref: '#/components/parameters/ShiftId'
 *     requestBody:
 *       description: Fields to update
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               startTime:
 *                 type: string
 *                 pattern: '^(?:[01]\\d|2[0-3]):[0-5]\\d$'
 *               endTime:
 *                 type: string
 *                 pattern: '^(?:[01]\\d|2[0-3]):[0-5]\\d$'
 *               shiftname:
 *                 type: string
 *     responses:
 *       200:
 *         description: Updated shift template
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Shift'
 *       400:
 *         description: Validation error
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden (non-admin)
 *       404:
 *         description: Shift not found
 *       500:
 *         description: Internal server error
 */
router.put(
  '/:id',
  verifyToken,
  isAdmin,
  shiftController.updateShift
);

/**
 * @swagger
 * /api/shifts/{id}:
 *   delete:
 *     summary: Delete a shift template (Admin only)
 *     tags: [Shifts]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - $ref: '#/components/parameters/ShiftId'
 *     responses:
 *       200:
 *         description: Deletion confirmation
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Shift template deleted
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden (non-admin)
 *       404:
 *         description: Shift not found
 *       500:
 *         description: Internal server error
 */
router.delete(
  '/:id',
  verifyToken,
  isAdmin,
  shiftController.deleteShift
);

module.exports = router;
