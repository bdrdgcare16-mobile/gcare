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
const attendanceController = __importStar(require("../controllers/attendanceController"));
const authMiddleware_1 = require("../middlewares/authMiddleware");
const router = (0, express_1.Router)();
// Apply auth middleware to all routes
router.use(authMiddleware_1.authMiddleware);
router.get('/live', attendanceController.getLiveAttendance);
router.get('/approvals', attendanceController.listApprovals);
router.post('/approvals/decision', attendanceController.decideApproval);
router.get('/my-requests', attendanceController.listMyRequests);
router.get('/employee/:empid', attendanceController.getEmployeeAttendance);
router.get('/monthly/:empid/:year/:month', attendanceController.getMonthlySummary);
router.get('/roster', attendanceController.getDailyRoster);
router.get('/range-summary', attendanceController.getRangeSummary);
router.get('/month-view/:empid/:year/:month', attendanceController.getMonthView);
router.post('/check-in', attendanceController.checkIn);
router.post('/check-out', attendanceController.checkOut);
router.get('/other-location', attendanceController.listOtherLocationEvents);
router.post('/other-location/decision', attendanceController.decideOtherLocationEvent);
router.get('/other-location/ping', (_req, res) => res.json({ ok: true }));
router.get('/me', attendanceController.getCurrentUser);
router.get('/summary/:empid/:year/:month', attendanceController.getMonthlySummary);
exports.default = router;
//# sourceMappingURL=attendance.js.map