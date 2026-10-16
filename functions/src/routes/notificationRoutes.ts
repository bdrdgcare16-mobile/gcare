import { Router } from 'express';
import { verifyToken } from '../middlewares/authMiddleware';
import {
  registerDevice,
  unregisterDevice,
  listNotifications,
  unreadCount,
  markRead,
  markUnread,
  markAllRead,
} from '../controllers/notificationController';

const router = Router();

/** Register/refresh the current device's FCM token for the authenticated user */
router.post('/register-device', verifyToken, registerDevice);

/** Deactivate a device's FCM token (e.g. on logout) */
router.post('/unregister-device', verifyToken, unregisterDevice);

/** Notification history for the authenticated user (own + company-scoped).
 *  Admin callers also trigger the bounded pendingAdminNotify reconciliation. */
router.get('/', verifyToken, listNotifications);

/** Unread badge count for the bell icon. */
router.get('/unread-count', verifyToken, unreadCount);

/** Mark every unread notification of the caller as read. */
router.post('/read-all', verifyToken, markAllRead);

/** Read/unread a single notification (ownership enforced server-side). */
router.post('/:id/read', verifyToken, markRead);
router.post('/:id/unread', verifyToken, markUnread);

export default router;
