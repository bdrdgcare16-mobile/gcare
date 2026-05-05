import { Request, Response } from 'express';
import { db } from '../config/firebase';
import { Timestamp } from 'firebase-admin/firestore';
import { trackUsage } from '../services/usageService';

const REWARDS = 'rewards';

type TS = Timestamp;

interface Reward {
  id?: string;
  empid: string;
  name: string;
  department: string;
  description: string;
  adminname: string;
  companyId: string;
  createdBy?: string;
  date: Date | TS;
  createdAt: TS | Date;
  updatedAt: TS | Date;
}

type AuthUser = {
  userId?: string;
  uid?: string;
  name?: string | null;
  email?: string | null;
  empid?: string | null;
  role?: string | null;
  companyId?: string | null;
};

function normalizeDate(input: unknown): Date {
  if (!input) return new Date();
  if (typeof input === 'object' && input !== null && typeof (input as any).toDate === 'function') {
    try {
      return (input as TS).toDate();
    } catch {
      // ignore
    }
  }
  const d = new Date(input as any);
  return isNaN(d.getTime()) ? new Date() : d;
}

function str(v: unknown): string {
  return (typeof v === 'string' ? v : '').trim();
}

function getReqUser(req: Request): AuthUser {
  return ((req as any).user || {}) as AuthUser;
}

function getReqCompanyId(req: Request): string | null {
  return str(getReqUser(req)?.companyId) || null;
}

function getReqActorId(req: Request): string | null {
  const user = getReqUser(req);
  return str(user.userId || user.uid) || null;
}

function serialize(doc: FirebaseFirestore.DocumentSnapshot | any) {
  const data = (doc && typeof doc.data === 'function') ? doc.data() : doc || {};
  const out: any = { id: doc?.id ?? data.id, ...data };

  const toIso = (v: any) => {
    if (!v) return v;
    if (typeof v === 'object' && typeof v.toDate === 'function') return v.toDate().toISOString();
    if (v instanceof Date) return v.toISOString();
    return v;
  };

  out.date = toIso(out.date);
  out.createdAt = toIso(out.createdAt);
  out.updatedAt = toIso(out.updatedAt);

  return out;
}

/* ============================== Usage Tracking Helper ============================== */

async function trackRewardUsage(
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
    console.error('Usage tracking failed in reward:', trackingError);
  }
}

/** POST /api/rewards */
export const createReward = async (req: Request, res: Response): Promise<Response> => {
  try {
    const body = (req.body || {}) as Partial<Reward>;
    const empid = str(body.empid);
    const name = str(body.name);
    const department = str(body.department);
    const description = str(body.description);

    const user = (req as any).user || {};
    const companyId = str(user.companyId);
    const actorId = getReqActorId(req);

    console.log('[createReward] req.user =', user);
    console.log('[createReward] companyId =', companyId);
    console.log('[createReward] actorId =', actorId);

    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized: missing companyId' });
    }

    const adminname =
      str(user?.name) ||
      str(user?.email) ||
      str((body as any).adminname) ||
      'Admin';

    const missing: string[] = [];
    if (!empid) missing.push('empid');
    if (!name) missing.push('name');
    if (!department) missing.push('department');
    if (!description) missing.push('description');

    if (missing.length) {
      return res.status(400).json({ error: `Missing fields: ${missing.join(', ')}` });
    }

    const now = Timestamp.now();
    const reward = {
      empid,
      name,
      department,
      description,
      adminname,
      companyId,
      createdBy: actorId || '',
      date: normalizeDate((body as any).date),
      createdAt: now,
      updatedAt: now,
    };

    console.log('[createReward] reward payload =', reward);

    const docRef = await db.collection(REWARDS).add(reward);
    const saved = await docRef.get();

    // Track usage after successful reward creation
    await trackRewardUsage(req, {
      writeCount: 1,
      apiCalls: 1,
    });

    return res.status(201).json(serialize(saved));
  } catch (error: any) {
    console.error('createReward error:', error);
    return res.status(500).json({ error: error.message || 'Server error' });
  }
};

/** GET /api/rewards */
export const getAllRewards = async (req: Request, res: Response): Promise<Response> => {
  try {
    const user = getReqUser(req);
    const companyId = getReqCompanyId(req);
    
    // Debug logs
    console.log('[getAllRewards] req.user.role =', user.role);
    console.log('[getAllRewards] req.user.empid =', user.empid);
    console.log('[getAllRewards] req.query.empid =', (req.query as any)?.empid);
    console.log('[getAllRewards] req.user.companyId =', user.companyId);
    
    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized: missing companyId' });
    }

    const empidParam = str((req.query as any)?.empid);
    const rewards: any[] = [];

    if (empidParam) {
      // Employee role: can only access own rewards
      if (user.role === 'employee') {
        if (user.empid !== empidParam) {
          console.log('[getAllRewards] Employee access denied: empid mismatch');
          return res.status(403).json({ error: 'Not authorized' });
        }
      }
      
      const tried = new Set<string>();
      const variants = [empidParam];
      const lc = empidParam.toLowerCase();
      const uc = empidParam.toUpperCase();

      if (lc !== empidParam) variants.push(lc);
      if (uc !== empidParam && uc !== lc) variants.push(uc);

      for (const v of variants) {
        if (tried.has(v)) continue;
        tried.add(v);

        const snap = await db
          .collection(REWARDS)
          .where('companyId', '==', companyId)
          .where('empid', '==', v)
          .get();

        for (const d of snap.docs) rewards.push(serialize(d));

        if (rewards.length && v === empidParam) break;
      }

      const dedup = Object.values(
        rewards.reduce<Record<string, any>>((acc, r: any) => {
          acc[r.id] = r;
          return acc;
        }, {})
      );

      dedup.sort(
        (a: any, b: any) =>
          new Date(b.date || 0).getTime() - new Date(a.date || 0).getTime()
      );

      // Track usage after successful rewards read
      await trackRewardUsage(req, {
        readCount: 1,
        apiCalls: 1,
      });

      return res.json(dedup);
    }

    // Admin role: can see all company rewards (no empid filter)
    if (user.role === 'admin') {
      const snapshot = await db
        .collection(REWARDS)
        .where('companyId', '==', companyId)
        .orderBy('date', 'desc')
        .get();

      // Track usage after successful rewards read
      await trackRewardUsage(req, {
        readCount: 1,
        apiCalls: 1,
      });

      return res.json(snapshot.docs.map((d) => serialize(d)));
    }

    // Employee role with no empid param: return empty (should use /mine endpoint)
    return res.json([]);
  } catch (error: any) {
    console.error('getAllRewards error:', error);
    return res.status(500).json({ error: error.message || 'Server error' });
  }
};

/** GET /api/rewards/:id */
export const getRewardById = async (req: Request, res: Response): Promise<Response> => {
  try {
    const companyId = getReqCompanyId(req);
    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized: missing companyId' });
    }

    const id = String(req.params.id);
    const doc = await db.collection(REWARDS).doc(id).get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Not found' });
    }

    const data = doc.data() as any;
    if (str(data?.companyId) !== companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Track usage after successful reward read
    await trackRewardUsage(req, {
      readCount: 1,
      apiCalls: 1,
    });

    return res.json(serialize(doc));
  } catch (error: any) {
    console.error('getRewardById error:', error);
    return res.status(500).json({ error: error.message || 'Server error' });
  }
};

/** DELETE /api/rewards/:id */
export const deleteReward = async (req: Request, res: Response): Promise<Response> => {
  try {
    const companyId = getReqCompanyId(req);
    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized: missing companyId' });
    }

    const id = String(req.params.id);
    const ref = db.collection(REWARDS).doc(id);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Not found' });
    }

    const data = doc.data() as any;
    if (str(data?.companyId) !== companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    await ref.delete();

    // Track usage after successful reward deletion
    await trackRewardUsage(req, {
      deleteCount: 1,
      apiCalls: 1,
    });

    return res.json({ message: 'Deleted successfully' });
  } catch (error: any) {
    console.error('deleteReward error:', error);
    return res.status(500).json({ error: error.message || 'Server error' });
  }
};

/** GET /api/rewards/mine */
export const getMyRewards = async (req: Request, res: Response): Promise<Response> => {
  try {
    const empid = str((req as any).user?.empid);
    const companyId = getReqCompanyId(req);

    if (!empid) {
      return res.status(401).json({ error: 'Unauthorized: missing empid' });
    }

    if (!companyId) {
      return res.status(401).json({ error: 'Unauthorized: missing companyId' });
    }

    const snap = await db
      .collection(REWARDS)
      .where('companyId', '==', companyId)
      .where('empid', '==', empid)
      .get();

    const list = snap.docs.map((d) => serialize(d));

    // Track usage after successful my rewards read
    await trackRewardUsage(req, {
      readCount: 1,
      apiCalls: 1,
    });

    return res.json(list);
  } catch (error: any) {
    console.error('getMyRewards error:', error);
    return res.status(500).json({ error: error.message || 'Server error' });
  }
};