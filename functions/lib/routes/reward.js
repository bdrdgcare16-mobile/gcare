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
const ctrl = __importStar(require("../controllers/rewardController"));
const authMiddleware_1 = require("../middlewares/authMiddleware");
const router = (0, express_1.Router)();
/**
 * @swagger
 * tags:
 *   - name: Rewards
 *     description: Manage employee rewards (admin & user)
 *
 * components:
 *   schemas:
 *     Reward:
 *       type: object
 *       required:
 *         - empid
 *         - name
 *         - department
 *         - description
 *         - adminname
 *         - date
 *       properties:
 *         id: { type: string }
 *         empid: { type: string, description: Employee ID (recipient) }
 *         name: { type: string, description: Employee name }
 *         department: { type: string, description: Department }
 *         description: { type: string, description: Reason/context }
 *         adminname: { type: string, description: Admin who granted reward }
 *         date: { type: string, format: date-time, description: Reward date }
 *         createdAt: { type: string, format: date-time }
 *         updatedAt: { type: string, format: date-time }
 */
// Inject auth where needed
router.post('/', authMiddleware_1.authMiddleware, (0, authMiddleware_1.roleMiddleware)(['admin']), ctrl.createReward);
router.get('/', ctrl.getAllRewards);
router.get('/mine', authMiddleware_1.authMiddleware, ctrl.getMyRewards);
router.get('/:id', ctrl.getRewardById);
router.delete('/:id', authMiddleware_1.authMiddleware, (0, authMiddleware_1.roleMiddleware)(['admin']), ctrl.deleteReward);
exports.default = router;
//# sourceMappingURL=reward.js.map