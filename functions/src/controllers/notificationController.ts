import { Request, Response } from 'express';
import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../config/firebase';
import { COLLECTIONS } from '../constants/collections';
import { successResponse, errorResponse } from '../common/response';

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
