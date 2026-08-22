import { Router } from 'express';
import { verifyToken } from '../middlewares/authMiddleware';
import {
  registerDevice,
  unregisterDevice,
} from '../controllers/notificationController';

const router = Router();

/** Register/refresh the current device's FCM token for the authenticated user */
router.post('/register-device', verifyToken, registerDevice);

/** Deactivate a device's FCM token (e.g. on logout) */
router.post('/unregister-device', verifyToken, unregisterDevice);

export default router;
