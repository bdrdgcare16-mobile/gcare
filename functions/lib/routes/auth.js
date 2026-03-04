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
const authController = __importStar(require("../controllers/authController"));
const authMiddleware_1 = require("../middlewares/authMiddleware");
const router = (0, express_1.Router)();
/* ================= Public ================= */
router.post('/register', authController.register);
router.post('/login', authController.login);
// Legacy simple reset (direct change) — expects { email, newPassword }
router.post('/forgot-password', authController.forgotPassword);
// Modern OTP flow
// Public – request Firebase reset email link
router.post('/forgot-password/request-link', authController.requestPasswordResetLink);
/* ================= Protected ================= */
router.use(authMiddleware_1.authMiddleware);
// This fixes your 404: Flutter calls GET /api/auth/me
router.get('/me', authController.getMe);
// Optional profile aliases
router.get('/profile', authController.getProfile);
router.put('/profile', authController.updateProfile);
router.get('/ping', (_req, res) => res.json({ ok: true, scope: 'auth' }));
// Change password (direct) — expects { email, newPassword }
router.post('/change-password', authController.changePassword);
/* ================= Admin-only ================= */
router.post('/admin/create-employee-login', (0, authMiddleware_1.roleMiddleware)(['admin']), authController.createEmployeeLogin);
router.post('/admin/backfill-employee-logins', (0, authMiddleware_1.roleMiddleware)(['admin', 'super_admin']), authController.backfillEmployeesToUsers);
exports.default = router;
//# sourceMappingURL=auth.js.map