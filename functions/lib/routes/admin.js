"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
// functions/src/routes/admin.ts
const express_1 = require("express");
const adminController_1 = require("../controllers/adminController");
const authMiddleware_1 = require("../middlewares/authMiddleware");
const router = (0, express_1.Router)();
// secure these with admin-only token
router.post("/create", authMiddleware_1.authMiddleware, authMiddleware_1.isAdmin, adminController_1.createAdmin);
router.post("/promote", authMiddleware_1.authMiddleware, authMiddleware_1.isAdmin, adminController_1.promoteToAdmin);
exports.default = router;
//# sourceMappingURL=admin.js.map