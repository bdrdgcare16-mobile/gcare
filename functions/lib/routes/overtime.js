"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const overtimecontroller_1 = require("../controllers/overtimecontroller");
const router = (0, express_1.Router)();
/**
 * Route: /api/overtime
 * Example: GET /api/overtime?empid=EMP001&date=2025-10-28
 */
router.get("/", overtimecontroller_1.getOvertimeHours);
exports.default = router;
//# sourceMappingURL=overtime.js.map