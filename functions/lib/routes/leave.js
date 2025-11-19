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
const leaveController = __importStar(require("../controllers/leaveController"));
const authMiddleware_1 = require("../middlewares/authMiddleware");
const router = (0, express_1.Router)();
// All /api/leaves require auth
router.use(authMiddleware_1.authMiddleware);
// ============================================
// Leave Requests
// ============================================
/**
 * POST /api/leaves
 * Create a leave request (supports both new and legacy payloads)
 */
router.post('/', leaveController.createLeaveRequest);
/**
 * GET /api/leaves
 * Admin: list all (with filters + pagination)
 */
router.get('/', (0, authMiddleware_1.roleMiddleware)(['admin']), leaveController.getAllLeaveRequests);
/**
 * GET /api/leaves/my
 * Current user's leaves (filters optional)
 */
router.get('/my', leaveController.getAllLeaveRequests);
// Legacy alias for clients already calling /mine
router.get('/mine', leaveController.getAllLeaveRequests);
/**
 * GET /api/leaves/pending
 * Admin: pending leaves, optional ?type=
 */
router.get('/pending', (0, authMiddleware_1.roleMiddleware)(['admin']), leaveController.getPendingLeaves);
/**
 * GET /api/leaves/balance
 * Current user's balance
 */
router.get('/balance', leaveController.getLeaveBalance);
/**
 * GET /api/leaves/:id
 * View a single leave (self/admin/approver)
 */
router.get('/:id', leaveController.getLeaveRequestById);
// ============================================
// Leave Types Management
// ============================================
/**
 * GET /api/leave-types
 * Get all leave types
 */
router.get('/types/all', (0, authMiddleware_1.roleMiddleware)(['admin']), leaveController.getLeaveTypes);
/**
 * POST /api/leave-types
 * Add a new leave type (admin only)
 */
router.post('/types', (0, authMiddleware_1.roleMiddleware)(['admin']), leaveController.addLeaveType);
/**
 * DELETE /api/leave-types
 * Delete a leave type (admin only)
 */
router.delete('/types', (0, authMiddleware_1.roleMiddleware)(['admin']), leaveController.deleteLeaveType);
// ============================================
// Leave Request Management
// ============================================
/**
 * PUT /api/leaves/:id
 * Admin: approve/reject/cancel (body: { status, notes? })
 * – kept for backward-compat
 */
router.put('/:id', (0, authMiddleware_1.roleMiddleware)(['admin']), leaveController.updateLeaveStatus);
/**
 * PUT /api/leaves/:id/status
 * Admin: approve/reject/cancel (same handler)
 */
router.put('/:id/status', (0, authMiddleware_1.roleMiddleware)(['admin']), leaveController.updateLeaveStatus);
/**
 * POST /api/leaves/:id/cancel
 * Requester or admin: cancel a pending request
 */
router.post('/:id/cancel', leaveController.cancelLeaveRequest);
/**
 * DELETE /api/leaves/:id
 * Admin: delete a request
 */
router.delete('/:id', (0, authMiddleware_1.roleMiddleware)(['admin']), leaveController.deleteLeave);
exports.default = router;
//# sourceMappingURL=leave.js.map