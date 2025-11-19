"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const employeeController = __importStar(require("../controllers/employeeController"));
const authMiddleware_1 = require("../middlewares/authMiddleware");
const router = (0, express_1.Router)();
// All /employees routes require auth
router.use(authMiddleware_1.authMiddleware);
/**
 * @swagger
 * components:
 *   schemas:
 *     Employee:
 *       type: object
 *       properties:
 *         id: { type: string }
 *         empid: { type: string }
 *         name: { type: string }
 *         email: { type: string }
 *         phone: { type: string }
 *         location: { type: string }
 *         dept: { type: string }
 *         designation: { type: string }
 *         shiftGroup: { type: string }
 *         role: { type: string }
 *         status:
 *           type: string
 *           enum: [active, inactive]
 *         createdAt: { type: string, format: date-time }
 *         updatedAt: { type: string, format: date-time }
 *         createdBy: { type: string }
 *         updatedBy: { type: string }
 *       required: [empid, name, email, status]
 */
/**
 * @swagger
 * /api/employees:
 *   post:
 *     summary: Create a new employee (Admin only)
 *     tags: [Employees]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Employee'
 *     responses:
 *       201: { description: Employee created successfully }
 *       400: { description: Missing required fields }
 *       409: { description: Employee with this ID or email already exists }
 *       500: { description: Internal server error }
 */
router.post('/', (0, authMiddleware_1.roleMiddleware)(['admin']), employeeController.createEmployee);
/**
 * @swagger
 * /api/employees:
 *   get:
 *     summary: Get all employees with pagination and filtering (Admin only)
 *     tags: [Employees]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: status
 *         schema: { type: string, enum: [active, inactive] }
 *       - in: query
 *         name: search
 *         schema: { type: string }
 *         description: Search tokens for name/email/empid/phone/department/designation
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 10 }
 *     responses:
 *       200:
 *         description: List of employees
 */
router.get('/', (0, authMiddleware_1.roleMiddleware)(['admin']), employeeController.getEmployees);
/**
 * @swagger
 * /api/employees/{id}:
 *   get:
 *     summary: Get employee by ID (Admin or self via other guards)
 *     tags: [Employees]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200: { description: Employee details }
 *       404: { description: Employee not found }
 */
router.get('/:id', (0, authMiddleware_1.roleMiddleware)(['admin']), employeeController.getEmployeeById);
/**
 * @swagger
 * /api/employees/{id}:
 *   put:
 *     summary: Update employee (Admin only)
 *     tags: [Employees]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Employee'
 *     responses:
 *       200: { description: Employee updated successfully }
 *       404: { description: Employee not found }
 */
router.put('/:id', (0, authMiddleware_1.roleMiddleware)(['admin']), employeeController.updateEmployee);
/**
 * @swagger
 * /api/employees/{id}:
 *   delete:
 *     summary: Delete an employee (Admin only)
 *     tags: [Employees]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200: { description: Employee deleted successfully }
 */
router.delete('/:id', (0, authMiddleware_1.roleMiddleware)(['admin']), employeeController.deleteEmployee);
exports.default = router;
//# sourceMappingURL=employees.js.map