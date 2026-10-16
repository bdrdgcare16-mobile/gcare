import { Router } from 'express';

import { verifyToken } from '../middlewares/authMiddleware';

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



router.post('/check-in', verifyToken, trackingCheckIn);

router.post('/pos', verifyToken, trackingAppendPos);

// NOTE: never log req.headers or req.body here - the Authorization bearer
// token would end up in Cloud Logging.
router.post('/check-out', verifyToken, trackingCheckOut);

router.get('/day', verifyToken, trackingGetDay);

// Admin-only: company-wide live tracking summary for one date.
router.get('/live', verifyToken, trackingLiveStatus);



router.post('/event', verifyToken, trackingAddEvent);

// Lightweight liveness + GPS-state ping (no point/event writes).
router.post('/heartbeat', verifyToken, trackingHeartbeat);



export default router;

