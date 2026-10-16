import { Router } from "express";
import { getOvertimeHours } from "../controllers/overtimecontroller";
import { verifyToken, roleMiddleware } from "../middlewares/authMiddleware";
import { requireFeature } from "../middlewares/featureMiddleware";
import { hrFeatureGate } from "../middlewares/hrFeatureMiddleware";

const router = Router();

/**
 * Route: /api/overtime
 * Example: GET /api/overtime?empid=EMP001&date=2025-10-28
 * Authenticated: tenant scope always comes from the verified JWT.
 * Admin/HR management read — without a role gate an employee could
 * query a colleague's overtime by empid. HR additionally needs the
 * 'attendance' feature approved.
 */
router.get(
  "/",
  verifyToken,
  requireFeature('attendance'),
  roleMiddleware(['admin', 'hr']),
  hrFeatureGate(['attendance']),
  getOvertimeHours,
);

export default router;
