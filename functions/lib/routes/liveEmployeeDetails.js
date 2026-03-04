"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const authMiddleware_1 = require("../middlewares/authMiddleware");
const liveEmployeeDetails_controller_1 = require("../controllers/liveEmployeeDetails.controller");
const router = (0, express_1.Router)();
// GET /api/liveEmployeeDetails/:empid?dateIso=YYYY-MM-DD
router.get('/:empid', authMiddleware_1.verifyToken, liveEmployeeDetails_controller_1.liveEmployeeDetails);
exports.default = router;
//# sourceMappingURL=liveEmployeeDetails.js.map