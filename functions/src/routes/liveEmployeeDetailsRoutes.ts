import { Router } from 'express';
import { verifyToken, roleMiddleware } from '../middlewares/authMiddleware';
import { requireFeature } from '../middlewares/featureMiddleware';
import { hrFeatureGate } from '../middlewares/hrFeatureMiddleware';
import { liveEmployeeDetails } from '../controllers/liveEmployeeDetailsController';

const router = Router();

// GET /api/liveEmployeeDetails/:empid?dateIso=YYYY-MM-DD
// Admin/HR management view only (called from the employee detail page) —
// employee self-data is served by /api/attendance endpoints instead.
// Without a role gate an employee token could read any empid's live
// attendance data (hrFeatureGate only constrains the 'hr' role).
router.get(
  '/:empid',
  verifyToken,
  requireFeature('attendance'),
  roleMiddleware(['admin', 'hr']),
  hrFeatureGate(['attendance']),
  liveEmployeeDetails,
);

export default router;
