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
// routes/report.ts
const express_1 = require("express");
const ctrl = __importStar(require("../controllers/reportController"));
const authMiddleware_1 = require("../middlewares/authMiddleware");
const router = (0, express_1.Router)();
// All report routes require auth
router.use(authMiddleware_1.authMiddleware);
/**
 * @swagger
 * tags:
 *   - name: Reports
 *     description: Report scheduler
 *
 * components:
 *   schemas:
 *     ReportSchedule:
 *       type: object
 *       required: [name, reportType, templateId, recipient, scheduleTime]
 *       properties:
 *         id: { type: string }
 *         name: { type: string }
 *         reportType:
 *           type: string
 *           enum: [Check-In, Check-Out, Present, Absent, Late Check-In]
 *         templateId: { type: string }
 *         recipient:
 *           type: string
 *           format: email
 *         scheduleTime: { type: string, description: 'Cron or HH:mm' }
 *         createdAt: { type: string, format: date-time }
 */
// POST /api/reports
router.post('/', (0, authMiddleware_1.roleMiddleware)(['admin']), ctrl.createSchedule);
// GET /api/reports
router.get('/', (0, authMiddleware_1.roleMiddleware)(['admin']), ctrl.listSchedules);
// POST /api/reports/:id/run
router.post('/:id/run', (0, authMiddleware_1.roleMiddleware)(['admin']), ctrl.runNow);
// DELETE /api/reports/:id
router.delete('/:id', (0, authMiddleware_1.roleMiddleware)(['admin']), ctrl.deleteSchedule);
exports.default = router;
//# sourceMappingURL=report.js.map