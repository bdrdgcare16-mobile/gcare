"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const authMiddleware_1 = require("../middlewares/authMiddleware");
const trackingController_1 = require("../controllers/trackingController");
const router = (0, express_1.Router)();
router.post('/check-in', authMiddleware_1.verifyToken, trackingController_1.trackingCheckIn);
router.post('/pos', authMiddleware_1.verifyToken, trackingController_1.trackingAppendPos);
router.post('/check-out', authMiddleware_1.verifyToken, trackingController_1.trackingCheckOut);
router.get('/day', authMiddleware_1.verifyToken, trackingController_1.trackingGetDay);
exports.default = router;
//# sourceMappingURL=tracking.js.map