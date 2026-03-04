"use strict";
// // functions/src/routes/reasons.ts
// import { Router } from "express";
// import {
//   listTypes,
//   createType,
//   deleteType,
//   listReasons,
//   createReason,
//   deleteReason,
// } from "../controllers/reasonMasterController";
Object.defineProperty(exports, "__esModule", { value: true });
// // If you have auth middleware, import and use it:
// // import { verifyToken } from "../middlewares/auth";
// const router = Router();
// // Helper function to wrap async route handlers with error handling
// const wrap = (fn: any) => (req: any, res: any, next: any) =>
//   Promise.resolve(fn(req, res, next)).catch(next);
// // ---------- Health check (optional) ----------
// router.get("/__health", (_req, res) => res.json({ ok: true, at: new Date().toISOString() }));
// /* ================== Reason Types ================== */
// router.get("/types", /* verifyToken, */ wrap(listTypes));
// router.post("/types", /* verifyToken, */ wrap(createType));
// router.delete("/types/:id", /* verifyToken, */ wrap(deleteType));
// /* ==================== Reasons ===================== */
// router.get("/", /* verifyToken, */ wrap(listReasons));
// router.post("/", /* verifyToken, */ wrap(createReason));
// router.delete("/:id", /* verifyToken, */ wrap(deleteReason));
// export default router;
const express_1 = require("express");
const reasonMasterController_1 = require("../controllers/reasonMasterController");
// If you have auth middleware, import and use it:
// import { verifyToken } from "../middlewares/auth";
const router = (0, express_1.Router)();
// Helper function to wrap async route handlers with error handling
const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
// ---------- Health check (optional) ----------
router.get("/__health", (_req, res) => res.json({ ok: true, at: new Date().toISOString() }));
/* ================== Reason Types ================== */
router.get("/types", /* verifyToken, */ wrap(reasonMasterController_1.listTypes));
router.post("/types", /* verifyToken, */ wrap(reasonMasterController_1.createType));
router.delete("/types/:id", /* verifyToken, */ wrap(reasonMasterController_1.deleteType));
/* ==================== Reasons ===================== */
router.get("/", /* verifyToken, */ wrap(reasonMasterController_1.listReasons));
router.post("/", /* verifyToken, */ wrap(reasonMasterController_1.createReason));
router.delete("/:id", /* verifyToken, */ wrap(reasonMasterController_1.deleteReason));
exports.default = router;
//# sourceMappingURL=reasons.js.map