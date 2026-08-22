import { Request, Response } from 'express';
import { Timestamp } from 'firebase-admin/firestore';
import { trackUsage } from '../services/usageService';

type FeedbackDoc = {
  empid: string;
  name: string;
  message: string;
  date: Timestamp | Date;
  response: string;
  visibility: string[];
  companyId: string;
  createdBy?: string;
};

type AuthUser = {
  userId?: string;
  uid?: string;
  empid?: string | null;
  name?: string | null;
  email?: string | null;
  role?: string | null;
  companyId?: string | null;
};

const COLL = 'feedbacks';

const getDb = (req: Request): FirebaseFirestore.Firestore => {
  const locals = req.app?.locals as { db?: FirebaseFirestore.Firestore } | undefined;
  if (!locals?.db) {
    throw new Error('Database not initialized in app.locals');
  }
  return locals.db;
};

const getReqUser = (req: Request): AuthUser => {
  return ((req as any).user || {}) as AuthUser;
};

const getReqCompanyId = (req: Request): string | null => {
  return String(getReqUser(req)?.companyId || '').trim() || null;
};

const getReqActorId = (req: Request): string | null => {
  const user = getReqUser(req);
  return String(user.userId || user.uid || '').trim() || null;
};

/* ============================== Usage Tracking Helper ============================== */

async function trackFeedbackUsage(
  req: Request,
  updates: Record<string, number>
) {
  try {
    const user = (req as any).user;
    await trackUsage({
      companyId: user?.companyId || '',
      companyName: user?.companyName || '',
      plan: user?.plan || '',
      updates,
    });
  } catch (trackingError) {
    console.error('Usage tracking failed in feedback:', trackingError);
  }
}

/**
 * POST /api/feedback
 * Body:
 *  - { message: string }
 *
 * User/company info is resolved from JWT middleware first.
 * Fallback to headers/body only if needed.
 */
export const createFeedback = async (req: Request, res: Response) => {
  try {
    const db = getDb(req);

    const message = String(req.body?.message ?? '').trim();
    const headerUserId = String(req.header('x-user-id') ?? '').trim();
    const headerEmpId = String(req.header('x-empid') ?? '').trim();
    const headerName = String(req.header('x-name') ?? '').trim();

    const authUser = getReqUser(req);
    const companyId = getReqCompanyId(req);
    const actorId = getReqActorId(req);

    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized: companyId missing in token' });
    }

    if (!message) {
      return res.status(400).json({ error: 'Missing message' });
    }

    let empid = String(authUser?.empid || '').trim();
    let name = String(authUser?.name || '').trim();

    if (!empid || !name) {
      if (headerUserId) {
        const snap = await db.collection('users').doc(headerUserId).get();
        if (!snap.exists) {
          return res.status(404).json({ error: 'User not found in users DB' });
        }

        const u = snap.data() ?? {};
        empid = String((u as any).empid ?? '').trim();
        name = String((u as any).name ?? '').trim();
      } else {
        empid = headerEmpId || String(req.body?.empid ?? '').trim();
        name = headerName || String(req.body?.name ?? '').trim();
      }
    }

    if (!empid || !name) {
      return res.status(400).json({
        error: 'Missing employee details. Provide empid and name through JWT, headers, or body.',
      });
    }

    const doc: FeedbackDoc = {
      empid,
      name,
      message,
      date: Timestamp.now(),
      response: '',
      visibility: ['admin'],
      companyId,
      createdBy: actorId || '',
    };

    const ref = await db.collection(COLL).add(doc);

    // Track usage after successful feedback creation
    await trackFeedbackUsage(req, {
      writeCount: 1,
      apiCalls: 1,
    });

    return res.status(201).json({
      message: 'Feedback submitted successfully',
      id: ref.id,
    });
  } catch (err: any) {
    console.error('createFeedback error:', err);
    return res.status(500).json({ error: err?.message ?? 'Server error' });
  }
};

/**
 * GET /api/feedback
 * Returns feedbacks only for the logged-in company.
 */
export const getAllFeedback = async (req: Request, res: Response) => {
  try {
    const locals = req.app?.locals as { db?: FirebaseFirestore.Firestore } | undefined;
    const db = locals?.db;

    console.log('GET /feedback hit');
    console.log('db exists =', !!db);

    if (!db) {
      return res.status(500).json({ error: 'Database not initialized in app.locals' });
    }

    const companyId = String(((req as any).user?.companyId ?? '')).trim();

    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized: companyId missing in token' });
    }

    const snap = await db
      .collection('feedbacks')
      .where('companyId', '==', companyId)
      .get();

    console.log('feedback count =', snap.size);

    const data = snap.docs.map((d) => {
      const x = d.data() as any;

      let iso = '';
      const dt = x?.date;
      if (dt && typeof dt.toDate === 'function') {
        iso = dt.toDate().toISOString();
      } else if (dt instanceof Date) {
        iso = dt.toISOString();
      } else if (typeof dt === 'string') {
        iso = dt;
      }

      return {
        id: d.id,
        empid: String(x?.empid ?? ''),
        name: String(x?.name ?? ''),
        message: String(x?.message ?? ''),
        response: String(x?.response ?? ''),
        visibility: Array.isArray(x?.visibility) ? x.visibility : [],
        companyId: String(x?.companyId ?? ''),
        date: iso,
      };
    });

    data.sort((a, b) => b.date.localeCompare(a.date));

    // Track usage after successful feedback read
    await trackFeedbackUsage(req, {
      readCount: 1,
      apiCalls: 1,
    });

    return res.status(200).json(data);
  } catch (err: any) {
    console.error('getAllFeedback error:', err);
    return res.status(500).json({ error: err?.message ?? 'Server error' });
  }
};