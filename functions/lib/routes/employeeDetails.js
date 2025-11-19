"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const authMiddleware_1 = require("../middlewares/authMiddleware");
const employeedetailcontroller_1 = require("../controllers/employeedetailcontroller");
const router = (0, express_1.Router)();
/**
 * GET /api/attendance/request-details
 * Query: id&src=attendance|other_location  OR  empid&date=YYYY-MM-DD
 */
router.get('/request-details', authMiddleware_1.authMiddleware, employeedetailcontroller_1.getRequestDetails);
exports.default = router;
//# sourceMappingURL=employeeDetails.js.map