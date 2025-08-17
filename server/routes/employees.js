// const express = require('express');
// const router = express.Router();
// const employeeController = require('../controllers/employeeController');
// const { verifyToken, isAdmin, isUserOrAdmin } = require('../middlewares/authMiddleware');

// console.log('employeeController exports:', Object.keys(employeeController));
// /**
//  * @swagger
//  * tags:
//  *   - name: Employees
//  *     description: Employee management (admin)
//  *
//  * components:
//  *   schemas:
//  *     Employee:
//  *       type: object
//  *       properties:
//  *         id:
//  *           type: string
//  *         empid:
//  *           type: string
//  *         name:
//  *           type: string
//  *         email:
//  *           type: string
//  *         phone:
//  *           type: string
//  *         location:
//  *           type: string
//  *         dept:
//  *           type: string
//  *         designation:
//  *           type: string
//  *         shiftGroup:
//  *           type: string
//  *         status:
//  *           type: string
//  *           enum: [active, inactive]
//  *       required:
//  *         - empid
//  *         - email
//  *
//  *   parameters:
//  *     EmployeeId:
//  *       in: path
//  *       name: id
//  *       required: true
//  *       schema:
//  *         type: string
//  *       description: Firestore document ID
//  */

// /**
//  * @swagger
//  * /api/employees/{id}:
//  *   get:
//  *     summary: Get one employee by ID (admin or self)
//  *     tags: [Employees]
//  *     security: [{ bearerAuth: [] }]
//  *     parameters:
//  *       - $ref: '#/components/parameters/EmployeeId'
//  *     responses:
//  *       200:
//  *         description: Employee object
//  *         content:
//  *           application/json:
//  *             schema:
//  *               $ref: '#/components/schemas/Employee'
//  *       401:
//  *         description: Unauthorized
//  *       404:
//  *         description: Not found
//  *       500:
//  *         description: Server error
//  */
// router.get(
//   '/:id',
//   verifyToken,
//   isUserOrAdmin,
//   employeeController.getEmployeeById // <-- Must be defined and exported in controller
// );

// /**
//  * @swagger
//  * /api/employees:
//  *   get:
//  *     summary: List all employees (admin only)
//  *     tags: [Employees]
//  *     security: [{ bearerAuth: [] }]
//  *     responses:
//  *       200:
//  *         description: Array of Employee objects
//  *         content:
//  *           application/json:
//  *             schema:
//  *               type: array
//  *               items:
//  *                 $ref: '#/components/schemas/Employee'
//  *       401:
//  *         description: Unauthorized
//  *       500:
//  *         description: Server error
//  */
// router.get(
//   '/',
//   verifyToken,
//   isAdmin,
//   employeeController.getAllEmployees // <-- Must be defined and exported in controller
// );

// module.exports = router;
const express = require('express');
const router = express.Router();
const employeeController = require('../controllers/employeeController');
const { verifyToken, isAdmin, isUserOrAdmin } = require('../middlewares/authMiddleware');

console.log('employeeController exports:', Object.keys(employeeController));
/**
 * @swagger
 * tags:
 *   - name: Employees
 *     description: Employee management (admin)
 *
 * components:
 *   schemas:
 *     Employee:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *         empid:
 *           type: string
 *         name:
 *           type: string
 *         email:
 *           type: string
 *         phone:
 *           type: string
 *         location:
 *           type: string
 *         dept:
 *           type: string
 *         designation:
 *           type: string
 *         shiftGroup:
 *           type: string
 *         status:
 *           type: string
 *           enum: [active, inactive]
 *       required:
 *         - empid
 *         - email
 *
 *   parameters:
 *     EmployeeId:
 *       in: path
 *       name: id
 *       required: true
 *       schema:
 *         type: string
 *       description: Firestore document ID
 */

/**
 * @swagger
 * /api/employees:
 *   post:
 *     summary: Create a new employee (admin only)
 *     tags: [Employees]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Employee'
 *     responses:
 *       201:
 *         description: Employee created
 *       400:
 *         description: Missing required fields
 *       409:
 *         description: Employee ID already exists
 *       500:
 *         description: Server error
 */
router.post(
  '/',
  verifyToken,
  isAdmin,
  employeeController.createEmployee
);

/**
 * @swagger
 * /api/employees:
 *   get:
 *     summary: List all employees (admin only)
 *     tags: [Employees]
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200:
 *         description: Array of Employee objects
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Employee'
 *       401:
 *         description: Unauthorized
 *       500:
 *         description: Server error
 */
router.get(
  '/',
  verifyToken,
  isAdmin,
  employeeController.getAllEmployees
);

/**
 * @swagger
 * /api/employees/{id}:
 *   get:
 *     summary: Get one employee by ID (admin or self)
 *     tags: [Employees]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - $ref: '#/components/parameters/EmployeeId'
 *     responses:
 *       200:
 *         description: Employee object
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Employee'
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Not found
 *       500:
 *         description: Server error
 */
router.get(
  '/:id',
  verifyToken,
  isUserOrAdmin,
  employeeController.getEmployeeById
);

/**
 * @swagger
 * /api/employees/{id}:
 *   put:
 *     summary: Update an employee (admin only)
 *     tags: [Employees]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - $ref: '#/components/parameters/EmployeeId'
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Employee'
 *     responses:
 *       200:
 *         description: Employee updated
 *       400:
 *         description: Bad request
 *       404:
 *         description: Not found
 *       500:
 *         description: Server error
 */
router.put(
  '/:id',
  verifyToken,
  isAdmin,
  employeeController.updateEmployee
);

module.exports = router;
