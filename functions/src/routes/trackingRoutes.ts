import { Router } from 'express';
import { verifyToken } from '../middlewares/authMiddleware';
import {
  trackingCheckIn,
  trackingAppendPos,
  trackingAppendEvent,
  trackingAppendGpsEvent,
  trackingCheckOut,
  trackingGetDay,
} from '../controllers/trackingController';

const router = Router();

router.post('/check-in', verifyToken, trackingCheckIn);
router.post('/pos', verifyToken, trackingAppendPos);
router.post('/event', verifyToken, trackingAppendEvent);
router.post('/check-out', verifyToken, trackingCheckOut);
router.get('/day', verifyToken, trackingGetDay);
router.post('/gps-event', verifyToken, trackingAppendGpsEvent);

export default router;
