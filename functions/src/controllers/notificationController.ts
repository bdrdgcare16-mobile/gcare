import { Request, Response } from 'express';
import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../config/firebase';
import { COLLECTIONS } from '../constants/collections';
import { successResponse, errorResponse } from '../common/response';
import { reconcilePendingAdminNotifies } from '../services/notification.service';

type AuthUser = {
  userId: string;
  email: string;
  role: string;
  empid?: string | null;
  companyId?: string | null;
};

function getAuthUser(req: Request): AuthUser | undefined {
  return req.user as AuthUser | undefined;
}

/**
 * Registers (or refreshes) a device's FCM token for the authenticated user.
 * userId/companyId are ALWAYS derived from the verified JWT — never trusted
 * from the request body — so a client cannot register a device on behalf
 * of another user or another company.
 */
export async function registerDevice(req: Request, res: Response) {
  try {
    const user = getAuthUser(req);
    const userId = user?.userId;
    const companyId = (user?.companyId || '').trim();

    if (!userId || !companyId) {
      return errorResponse(res, 'Unauthorized: userId/companyId missing in token', 401);
    }

    const { fcmToken, platform, deviceName } = (req.body ?? {}) as {
      fcmToken?: string;
      platform?: string;
      deviceName?: string;
    };

    const token = (fcmToken || '').trim();
    if (!token) {
      return errorResponse(res, 'fcmToken is required', 400);
    }

    // Avoid duplicate documents for the same FCM token. A token can only
    // belong to one device install, so reassign/refresh it if found.
    const existing = await db
      .collection(COLLECTIONS.DEVICE_REGISTRATIONS)
      .where('fcmToken', '==', token)
      .limit(1)
      .get();

    const payload = {
      userId,
      empid: user?.empid ?? null,
      companyId,
      fcmToken: token,
      platform: (platform || 'android').toString().trim().toLowerCase(),
      deviceName: (deviceName || '').toString().trim(),
      isActive: true,
      updatedAt: FieldValue.serverTimestamp(),
    };

    if (!existing.empty) {
      await existing.docs[0].ref.update(payload);
      return successResponse(res, { id: existing.docs[0].id }, 'Device registration updated', 200);
    }

    const docRef = await db.collection(COLLECTIONS.DEVICE_REGISTRATIONS).add({
      ...payload,
      createdAt: FieldValue.serverTimestamp(),
    });

    return successResponse(res, { id: docRef.id }, 'Device registered', 201);
  } catch (e: any) {
    return errorResponse(res, e?.message || 'Failed to register device', 500);
  }
}

/**
 * Marks a device's FCM token inactive, e.g. on logout, so it stops
 * receiving pushes without deleting the notification history it may be
 * referenced by.
 */
export async function unregisterDevice(req: Request, res: Response) {
  try {
    const user = getAuthUser(req);
    const userId = user?.userId;

    if (!userId) {
      return errorResponse(res, 'Unauthorized', 401);
    }

    const { fcmToken } = (req.body ?? {}) as { fcmToken?: string };
    const token = (fcmToken || '').trim();
    if (!token) {
      return errorResponse(res, 'fcmToken is required', 400);
    }

    const snap = await db
      .collection(COLLECTIONS.DEVICE_REGISTRATIONS)
      .where('fcmToken', '==', token)
      .where('userId', '==', userId)
      .limit(1)
      .get();

    if (!snap.empty) {
      await snap.docs[0].ref.update({
        isActive: false,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    // Idempotent either way — logout should never fail because of this.
    return successResponse(res, {}, 'Device unregistered', 200);
  } catch (e: any) {
    return errorResponse(res, e?.message || 'Failed to unregister device', 500);
  }
}

/* ===================== Notification history ===================== */

const ADMIN_ROLES = new Set(['admin', 'super_admin']);
const DEFAULT_LIMIT = 50;
const MAX_LIMIT = 100;

function toIso(v: any): string | null {
  try {
    if (!v) return null;
    if (typeof v.toDate === 'function') return v.toDate().toISOString();
    if (typeof v._seconds === 'number') return new Date(v._seconds * 1000).toISOString();
    if (typeof v === 'string') return v;
    const d = new Date(v);
    return Number.isNaN(d.getTime()) ? null : d.toISOString();
  } catch {
    return null;
  }
}

function serializeNotification(id: string, d: any) {
  return {
    id,
    type: d.type ?? '',
    title: d.title ?? '',
    body: d.body ?? '',
    entityType: d.entityType ?? '',
    entityId: d.entityId ?? '',
    data: d.data ?? {},
    isRead: d.isRead === true,
    pushStatus: d.pushStatus ?? null,
    createdAt: toIso(d.createdAt),
    readAt: toIso(d.readAt),
  };
}

/**
 * GET /api/notifications?unreadOnly=true&limit=50
 * Returns the calling user's own notification history - always scoped to
 * companyId + recipientUserId from the verified JWT, so no caller can ever
 * read another user's or another company's notifications.
 *
 * Admin callers additionally trigger a bounded reconciliation sweep: any
 * tracking session still flagged pendingAdminNotify gets its GPS OFF/ON
 * notification materialized now (deduped - see reconcilePendingAdminNotifies).
 */
export async function listNotifications(req: Request, res: Response) {
  try {
    const user = getAuthUser(req);
    const userId = user?.userId;
    const companyId = (user?.companyId || '').trim();
    if (!userId || !companyId) {
      return errorResponse(res, 'Unauthorized', 401);
    }

    const role = (user?.role || '').toLowerCase();
    if (ADMIN_ROLES.has(role)) {
      // Best-effort, bounded, idempotent - a sweep failure must not break
      // the history read.
      await reconcilePendingAdminNotifies(companyId).catch(() => undefined);
    }

    const parsed = parseInt(String(req.query?.limit ?? ''), 10);
    const limit = Number.isFinite(parsed)
      ? Math.min(Math.max(parsed, 1), MAX_LIMIT)
      : DEFAULT_LIMIT;
    const unreadOnly = String(req.query?.unreadOnly ?? '') === 'true';

    const snap = await db
      .collection(COLLECTIONS.NOTIFICATIONS)
      .where('companyId', '==', companyId)
      .where('recipientUserId', '==', userId)
      .orderBy('createdAt', 'desc')
      .limit(limit)
      .get();

    let items = snap.docs.map((d) => serializeNotification(d.id, d.data()));
    if (unreadOnly) items = items.filter((n) => !n.isRead);

    return successResponse(res, { notifications: items }, 'OK', 200);
  } catch (e: any) {
    return errorResponse(res, e?.message || 'Failed to list notifications', 500);
  }
}

/** GET /api/notifications/unread-count - badge count for the bell icon. */
export async function unreadCount(req: Request, res: Response) {
  try {
    const user = getAuthUser(req);
    const userId = user?.userId;
    const companyId = (user?.companyId || '').trim();
    if (!userId || !companyId) {
      return errorResponse(res, 'Unauthorized', 401);
    }

    const snap = await db
      .collection(COLLECTIONS.NOTIFICATIONS)
      .where('companyId', '==', companyId)
      .where('recipientUserId', '==', userId)
      .where('isRead', '==', false)
      .count()
      .get();

    return successResponse(res, { count: snap.data().count }, 'OK', 200);
  } catch (e: any) {
    return errorResponse(res, e?.message || 'Failed to count notifications', 500);
  }
}

/**
 * Shared mark-read/mark-unread implementation. Ownership is verified against
 * the JWT (companyId + recipientUserId) inside the doc itself - a caller can
 * never flip the read state of someone else's notification, even if they
 * know the document id.
 */
async function setReadState(req: Request, res: Response, read: boolean) {
  try {
    const user = getAuthUser(req);
    const userId = user?.userId;
    const companyId = (user?.companyId || '').trim();
    if (!userId || !companyId) {
      return errorResponse(res, 'Unauthorized', 401);
    }

    const id = String(req.params.id || '').trim();
    if (!id) return errorResponse(res, 'Notification id required', 400);

    const ref = db.collection(COLLECTIONS.NOTIFICATIONS).doc(id);
    const snap = await ref.get();
    const d = snap.data() as any;
    // Not-found and not-owned deliberately share 404 - existence of the
    // document must not leak across users or companies.
    if (!snap.exists || d?.companyId !== companyId || d?.recipientUserId !== userId) {
      return errorResponse(res, 'Notification not found', 404);
    }

    await ref.update(
      read
        ? { isRead: true, readAt: FieldValue.serverTimestamp() }
        : { isRead: false, readAt: null },
    );

    return successResponse(res, { id, isRead: read }, 'OK', 200);
  } catch (e: any) {
    return errorResponse(res, e?.message || 'Failed to update notification', 500);
  }
}

export function markRead(req: Request, res: Response) {
  return setReadState(req, res, true);
}

export function markUnread(req: Request, res: Response) {
  return setReadState(req, res, false);
}

/** POST /api/notifications/read-all - marks every unread notification of the caller. */
export async function markAllRead(req: Request, res: Response) {
  try {
    const user = getAuthUser(req);
    const userId = user?.userId;
    const companyId = (user?.companyId || '').trim();
    if (!userId || !companyId) {
      return errorResponse(res, 'Unauthorized', 401);
    }

    const snap = await db
      .collection(COLLECTIONS.NOTIFICATIONS)
      .where('companyId', '==', companyId)
      .where('recipientUserId', '==', userId)
      .where('isRead', '==', false)
      .limit(500)
      .get();

    if (!snap.empty) {
      const batch = db.batch();
      for (const d of snap.docs) {
        batch.update(d.ref, {
          isRead: true,
          readAt: FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }

    return successResponse(res, { marked: snap.size }, 'OK', 200);
  } catch (e: any) {
    return errorResponse(res, e?.message || 'Failed to mark notifications', 500);
  }
}
