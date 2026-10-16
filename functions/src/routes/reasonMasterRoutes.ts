import { Router } from "express";
import {
  listTypes,
  createType,
  deleteType,
  listReasons,
  createReason,
  deleteReason,
} from "../controllers/reasonMasterController";
import { verifyToken, roleMiddleware } from "../middlewares/authMiddleware";
import { requireFeature } from "../middlewares/featureMiddleware";
import { hrFeatureGate } from "../middlewares/hrFeatureMiddleware";

const router = Router();

// Helper function to wrap async route handlers with error handling
const wrap = (fn: any) => (req: any, res: any, next: any) =>
  Promise.resolve(fn(req, res, next)).catch(next);

const attendanceEnabled = requireFeature('attendance');
// Reason master data is tenant config — admin, or HR with 'attendance'
// approved. Previously any authenticated caller could mutate it.
const isAdminOrHr = roleMiddleware(['admin', 'hr']);
const hrAttendance = hrFeatureGate(['attendance']);
// Employees need read-only access to their company's active reasons for
// attendance check-in/out. Mutations stay admin/HR-only; hrAttendance still
// gates HR callers (hrFeatureGate is a no-op for non-HR roles).
const isAdminHrOrEmployee = roleMiddleware(['admin', 'hr', 'employee']);

// ---------- Health check (optional) ----------
router.get("/__health", (_req, res) => res.json({ ok: true, at: new Date().toISOString() }));

/* ================== Reason Types ================== */
router.get("/types", verifyToken, attendanceEnabled, isAdminOrHr, hrAttendance, wrap(listTypes));
router.post("/types", verifyToken, attendanceEnabled, isAdminOrHr, hrAttendance, wrap(createType));
router.delete("/types/:id", verifyToken, attendanceEnabled, isAdminOrHr, hrAttendance, wrap(deleteType));

/* ==================== Reasons ===================== */
router.get("/", verifyToken, attendanceEnabled, isAdminHrOrEmployee, hrAttendance, wrap(listReasons));
router.post("/", verifyToken, attendanceEnabled, isAdminOrHr, hrAttendance, wrap(createReason));
router.delete("/:id", verifyToken, attendanceEnabled, isAdminOrHr, hrAttendance, wrap(deleteReason));

export default router;
