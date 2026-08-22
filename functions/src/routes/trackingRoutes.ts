import { Router } from 'express';
import { verifyToken } from '../middlewares/authMiddleware';
import {
  trackingCheckIn,
  trackingAppendPos,
  trackingCheckOut,
  trackingGetDay,
} from '../controllers/trackingController';

const router = Router();

router.post('/check-in', verifyToken, trackingCheckIn);
router.post('/pos', verifyToken, trackingAppendPos);
router.post('/check-out', verifyToken, (req, res) => {
  console.log('[TRACKING ROUTES] /check-out endpoint HIT');
  trackingCheckOut(req, res);
});
router.get('/day', verifyToken, trackingGetDay);

export default router;
