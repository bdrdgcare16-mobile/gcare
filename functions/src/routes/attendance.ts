import { Router } from 'express';
import * as attendanceController from '../controllers/attendanceController';
import { authMiddleware } from '../middlewares/authMiddleware';

const router = Router();

// Apply auth middleware to all routes
router.use(authMiddleware);

/**
 * @swagger
 * components:
 *   schemas:
 *     AttendanceRecord:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *         empid:
 *           type: string
 *         name:
 *           type: string
 *         date:
 *           type: string
 *           format: date
 *         checkIn:
 *           type: string
 *           format: date-time
 *         checkOut:
 *           type: string
 *           format: date-time
 *         location:
 *           type: string
 *         status:
 *           type: string
 *           enum: [present, absent, half-day, holiday, weekend, on-leave]
 *         totalHours:
 *           type: number
 *         lateMinutes:
 *           type: number
 *         earlyLeaveMinutes:
 *           type: number
 *         notes:
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
 * /api/attendance/check-in:
 *   post:
 *     summary: Check in for the day
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - empid
 *               - name
 *               - location
 *             properties:
 *               empid:
 *                 type: string
 *               name:
 *                 type: string
 *               location:
 *                 type: string
 *               notes:
 *                 type: string
 *     responses:
 *       201:
 *         description: Successfully checked in
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 attendance:
 *                   $ref: '#/components/schemas/AttendanceRecord'
 *       400:
 *         description: Missing required fields or already checked in
 *       403:
 *         description: Unauthorized to check in for this employee
 *       500:
 *         description: Internal server error
 */
router.post('/check-in', attendanceController.checkIn);

/**
 * @swagger
 * /api/attendance/check-out:
 *   post:
 *     summary: Check out for the day
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - empid
 *               - location
 *             properties:
 *               empid:
 *                 type: string
 *               location:
 *                 type: string
 *               notes:
 *                 type: string
 *     responses:
 *       200:
 *         description: Successfully checked out
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 attendance:
 *                   $ref: '#/components/schemas/AttendanceRecord'
 *       400:
 *         description: No active check-in found or missing required fields
 *       403:
 *         description: Unauthorized to check out for this employee
 *       500:
 *         description: Internal server error
 */
router.post('/check-out', attendanceController.checkOut);

/**
 * @swagger
 * /api/attendance/employee/{empid}:
 *   get:
 *     summary: Get attendance records for an employee
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: empid
 *         required: true
 *         schema:
 *           type: string
 *         description: Employee ID
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Start date (YYYY-MM-DD)
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date
 *         description: End date (YYYY-MM-DD)
 *     responses:
 *       200:
 *         description: List of attendance records
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/AttendanceRecord'
 *       403:
 *         description: Unauthorized to view this attendance
 *       500:
 *         description: Internal server error
 */
router.get('/employee/:empid', attendanceController.getEmployeeAttendance);

/**
 * @swagger
 * /api/attendance/status/{empid}:
 *   get:
 *     summary: Get current check-in/check-out status of an employee
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: empid
 *         required: true
 *         schema:
 *           type: string
 *         description: Employee ID
 *     responses:
 *       200:
 *         description: Current status of the employee
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   enum: [not_checked_in, checked_in, checked_out]
 *                 message:
 *                   type: string
 *                 checkInTime:
 *                   type: string
 *                   format: date-time
 *                 lastCheckOut:
 *                   type: string
 *                   format: date-time
 *                 duration:
 *                   type: number
 *       403:
 *         description: Unauthorized to view this status
 *       500:
 *         description: Internal server error
 */
router.get('/status/:empid', attendanceController.getCurrentStatus);

/**
 * @swagger
 * /api/attendance/summary/{empid}:
 *   get:
 *     summary: Get attendance summary for an employee
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: empid
 *         required: true
 *         schema:
 *           type: string
 *         description: Employee ID
 *       - in: query
 *         name: month
 *         schema:
 *           type: integer
 *           minimum: 1
 *           maximum: 12
 *         description: Month (1-12), defaults to current month
 *       - in: query
 *         name: year
 *         schema:
 *           type: integer
 *           minimum: 2000
 *           maximum: 2100
 *         description: Year (e.g., 2023), defaults to current year
 *     responses:
 *       200:
 *         description: Attendance summary for the specified period
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 empid:
 *                   type: string
 *                 month:
 *                   type: integer
 *                 year:
 *                   type: integer
 *                 presentDays:
 *                   type: integer
 *                 absentDays:
 *                   type: integer
 *                 totalHours:
 *                   type: number
 *                 lateDays:
 *                   type: integer
 *                 earlyLeaveDays:
 *                   type: integer
 *                 averageHoursPerDay:
 *                   type: number
 *       403:
 *         description: Unauthorized to view this summary
 *       500:
 *         description: Internal server error
 */
router.get('/summary/:empid', attendanceController.getAttendanceSummary);

export default router;
