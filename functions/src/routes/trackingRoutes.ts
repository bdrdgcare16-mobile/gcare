import { Router } from 'express';
import { verifyToken, roleMiddleware } from '../middlewares/authMiddleware';

import { requireFeature } from '../middlewares/featureMiddleware';
import { hrFeatureGate } from '../middlewares/hrFeatureMiddleware';

import {
  trackingCheckIn,
  trackingAppendPos,
  trackingCheckOut,
  trackingGetDay,
  trackingLiveStatus,
  trackingAddEvent,
  trackingHeartbeat,
} from '../controllers/trackingController';

const router = Router();

router.post('/check-in', verifyToken, requireFeature('tracking'), hrFeatureGate(['tracking']), trackingCheckIn);
router.post('/pos', verifyToken, requireFeature('tracking'), hrFeatureGate(['tracking']), trackingAppendPos);
// NOTE: never log req.headers or req.body here - the Authorization bearer
// token would end up in Cloud Logging.
router.post('/check-out', verifyToken, requireFeature('tracking'), hrFeatureGate(['tracking']), trackingCheckOut);
router.post('/event', verifyToken, requireFeature('tracking'), hrFeatureGate(['tracking']), trackingAddEvent);
// Lightweight liveness + GPS-state ping (no point/event writes). Same
// tenant/feature gates as /pos - it is an authenticated employee device
// contact.
router.post('/heartbeat', verifyToken, requireFeature('tracking'), hrFeatureGate(['tracking']), trackingHeartbeat);
// Day read is also used by the admin/HR employee-detail view inside the
// attendance module, so an 'attendance'-approved HR may read it too.
router.get(
  '/day',
  verifyToken,
  requireFeature('tracking'),
  roleMiddleware(['admin', 'hr', 'employee']),
  hrFeatureGate(['tracking', 'attendance']),
  trackingGetDay,
);
// Admin-only (enforced inside the controller, which also allows
// super_admin): company-wide live tracking summary for one date. No
// roleMiddleware here so the controller's own role set stays the single
// source of truth for who may read it.
router.get('/live', verifyToken, requireFeature('tracking'), hrFeatureGate(['tracking']), trackingLiveStatus);

export default router;
