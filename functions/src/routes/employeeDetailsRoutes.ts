import { Router } from 'express';
import { authMiddleware, roleMiddleware } from '../middlewares/authMiddleware';
import { requireFeature } from '../middlewares/featureMiddleware';
import { hrFeatureGate } from '../middlewares/hrFeatureMiddleware';
import { getRequestDetails } from '../controllers/employeeDetailsController';

const router = Router();

router.get("/request-details", authMiddleware, requireFeature('attendance'), roleMiddleware(['admin', 'hr']), hrFeatureGate(['attendance', 'leave']), getRequestDetails);
export default router;