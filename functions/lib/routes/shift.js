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
const shiftController = __importStar(require("../controllers/shiftController"));
const authMiddleware_1 = require("../middlewares/authMiddleware");
const router = (0, express_1.Router)();
/**
 * NOTE:
 * This router must be mounted at `/api/shifts` in index.ts:
 *   app.use('/api/shifts', shiftRoutes);
 *
 * Do NOT prefix routes here with /api or /shifts again.
 */
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
 *         name:
 *           type: string
 *         startTime:
 *           type: string
 *           pattern: '^(?:[01]\\d|2[0-3]):[0-5]\\d$'
 *         endTime:
 *           type: string
 *           pattern: '^(?:[01]\\d|2[0-3]):[0-5]\\d$'
 *         shiftname:
 *           type: string
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 *       required: [id, name, startTime, endTime, shiftname]
 *
 *   parameters:
 *     ShiftId:
 *       in: path
 *       name: id
 *       required: true
 *       schema:
 *         type: string
 *         format: uuid
 */
/**
 * @swagger
 * /api/shifts:
 *   post:
 *     summary: Create a new shift template (Admin only)
 *     tags: [Shifts]
 *     security:
 *       - bearerAuth: []
 */
router.post('/', authMiddleware_1.verifyToken, authMiddleware_1.isAdmin, shiftController.createShift);
/**
 * @swagger
 * /api/shifts:
 *   get:
 *     summary: List all shift templates (Admin only)
 *     tags: [Shifts]
 *     security:
 *       - bearerAuth: []
 */
router.get('/', authMiddleware_1.verifyToken, authMiddleware_1.isAdmin, shiftController.getAllShifts);
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
 */
router.get('/:id', authMiddleware_1.verifyToken, authMiddleware_1.isAdmin, shiftController.getShiftById);
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
 */
router.put('/:id', authMiddleware_1.verifyToken, authMiddleware_1.isAdmin, shiftController.updateShift);
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
 */
router.delete('/:id', authMiddleware_1.verifyToken, authMiddleware_1.isAdmin, shiftController.deleteShift);
exports.default = router;
//# sourceMappingURL=shift.js.map