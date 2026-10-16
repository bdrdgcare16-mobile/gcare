import { Request, Response } from 'express';
import { db, bucket } from '../config/firebase';

/**
 * Organization registration review API (Milestone 3D backend).
 *
 * Data lives in the `organization_registrations` collection. Documents
 * are keyed by an auto doc id and carry a human-facing `registrationId`
 * field — the Platform Admin UI routes on `registrationId`, so every
 * lookup accepts either.
 *
 * All endpoints are mounted under /api/platform which already enforces
 * authMiddleware + roleMiddleware(['platform_admin']).
 */

const COL = 'organization_registrations';

const VALID_STATUSES = new Set([
  'draft',
  'submitted',
  'pending_verification',
  'pending_approval',
  'changes_requested',
  'approved',
  'rejected',
]);

type Doc = FirebaseFirestore.DocumentSnapshot;

async function findRegistration(id: string): Promise<Doc | null> {
  const trimmed = String(id ?? '').trim();
  if (!trimmed) return null;

  const byField = await db
    .collection(COL)
    .where('registrationId', '==', trimmed)
    .limit(1)
    .get();
  if (!byField.empty) return byField.docs[0];

  const byId = await db.collection(COL).doc(trimmed).get();
  return byId.exists ? byId : null;
}

const toMillis = (v: any): number => {
  if (v == null) return 0;
  if (v instanceof Date) return v.getTime();
  if (typeof v === 'number') return v;
  if (typeof v === 'string') return Date.parse(v) || 0;
  if (typeof v === 'object' && '_seconds' in v) return v._seconds * 1000;
  return 0;
};

// GET /registrations?status=&search=&sort=&page=&pageSize=
export const listRegistrations = async (req: Request, res: Response) => {
  try {
    const status = String(req.query.status ?? '').trim();
    const search = String(req.query.search ?? '').trim().toLowerCase();
    const sort = String(req.query.sort ?? 'createdAt').trim();
    const page = Math.max(1, Number(req.query.page) || 1);
    const pageSize = Math.min(100, Math.max(1, Number(req.query.pageSize) || 20));

    let q: FirebaseFirestore.Query = db.collection(COL);
    if (status && VALID_STATUSES.has(status)) {
      q = q.where('status', '==', status);
    }

    const snap = await q.get();
    let items = snap.docs.map((d) => ({ id: d.id, ...d.data() } as any));

    if (search) {
      items = items.filter((r) => {
        const contact = r.adminContact ?? {};
        return [
          r.organizationName,
          r.registrationId,
          contact.fullName,
          contact.email,
          contact.officialEmail,
        ].some((v) => String(v ?? '').toLowerCase().includes(search));
      });
    }

    const sortField = sort === 'submittedAt' ? 'submittedAt' : 'createdAt';
    items.sort((a, b) => toMillis(b[sortField]) - toMillis(a[sortField]));

    const total = items.length;
    const start = (page - 1) * pageSize;
    const paged = items.slice(start, start + pageSize);

    return res.status(200).json({
      registrations: paged,
      page,
      pageSize,
      total,
      hasMore: start + paged.length < total,
    });
  } catch (err: any) {
    console.error('listRegistrations error:', err);
    return res.status(500).json({ error: 'Failed to load registrations' });
  }
};

// GET /registrations/:id  (id = registrationId field or doc id)
export const getRegistration = async (req: Request, res: Response) => {
  try {
    const doc = await findRegistration(String(req.params.id));
    if (!doc) {
      return res.status(404).json({ error: 'Registration not found' });
    }
    return res.status(200).json({
      registration: { id: doc.id, ...doc.data() },
    });
  } catch (err: any) {
    console.error('getRegistration error:', err);
    return res.status(500).json({ error: 'Failed to load registration' });
  }
};

// GET /registrations/:id/documents/:field?filename=
// documents[field] holds a Firebase Storage object path (or a legacy
// full URL); resolve it to a short-lived signed URL for review.
export const getRegistrationDocument = async (req: Request, res: Response) => {
  try {
    const doc = await findRegistration(String(req.params.id));
    if (!doc) {
      return res.status(404).json({ error: 'Registration not found' });
    }

    const field = String(req.params.field ?? '').trim();
    const data: any = doc.data() ?? {};
    const stored = data.documents?.[field];
    const path = typeof stored === 'string'
      ? stored
      : (stored?.path ?? stored?.url ?? '');

    if (!path) {
      return res.status(404).json({ error: 'Document not found' });
    }

    if (/^https?:\/\//.test(path) && !path.includes('storage.googleapis.com')) {
      return res.status(200).json({ url: path });
    }

    let objectPath = path;
    if (objectPath.includes('?')) objectPath = objectPath.split('?')[0];
    if (objectPath.includes('storage.googleapis.com/')) {
      objectPath = objectPath.split('storage.googleapis.com/')[1];
    }
    if (objectPath.startsWith(`${bucket.name}/`)) {
      objectPath = objectPath.slice(bucket.name.length + 1);
    }
    objectPath = decodeURIComponent(objectPath);

    const [url] = await bucket.file(objectPath).getSignedUrl({
      action: 'read',
      expires: Date.now() + 15 * 60 * 1000,
    });

    return res.status(200).json({ url });
  } catch (err: any) {
    console.error('getRegistrationDocument error:', err);
    return res.status(500).json({ error: 'Failed to open document' });
  }
};

// POST /registrations/:id/approve|reject|request-changes  { comment? }
async function review(
  req: Request,
  res: Response,
  action: 'approved' | 'rejected' | 'changes_requested',
  requireComment: boolean,
) {
  try {
    const comment = String(req.body?.comment ?? '').trim();
    if (requireComment && !comment) {
      return res.status(400).json({ error: 'A reason or comment is required' });
    }

    const doc = await findRegistration(String(req.params.id));
    if (!doc) {
      return res.status(404).json({ error: 'Registration not found' });
    }

    const now = new Date();
    const actor = String((req as any).user?.email ?? (req as any).user?.userId ?? 'platform_admin');
    const prev: any = doc.data() ?? {};

    const historyEntry = {
      action,
      actor,
      at: now,
      note: comment || null,
    };
    const auditEntry = {
      action,
      actor,
      at: now,
      from: prev.status ?? null,
      to: action,
      note: comment || null,
    };

    await doc.ref.update({
      status: action,
      decidedAt: now,
      decidedBy: actor,
      decision: action,
      ...(comment ? { note: comment } : {}),
      reviewHistory: [
        ...(Array.isArray(prev.reviewHistory) ? prev.reviewHistory : []),
        historyEntry,
      ],
      auditTrail: [
        ...(Array.isArray(prev.auditTrail) ? prev.auditTrail : []),
        auditEntry,
      ],
      updatedAt: now,
    });

    return res.status(200).json({
      success: true,
      status: action,
      message: `Registration ${action.replace('_', ' ')}`,
    });
  } catch (err: any) {
    console.error(`review(${action}) error:`, err);
    return res.status(500).json({ error: 'Review action failed' });
  }
}

export const approveRegistration = (req: Request, res: Response) =>
  review(req, res, 'approved', false);

export const rejectRegistration = (req: Request, res: Response) =>
  review(req, res, 'rejected', true);

export const requestChangesRegistration = (req: Request, res: Response) =>
  review(req, res, 'changes_requested', true);
