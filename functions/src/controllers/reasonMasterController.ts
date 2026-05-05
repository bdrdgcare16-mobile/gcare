// functions/src/controllers/reasonMasterController.ts
import { Request, Response } from "express";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../config/firebase";
import { trackUsage } from "../services/usageService";
const TYPES_COL   = "reason_types";
const REASONS_COL = "reasons";

/* --------------------------- helpers --------------------------- */
const safe = (v: any) => String(v ?? "").trim();
const now  = () => FieldValue.serverTimestamp();

function getReqCompanyId(req: Request): string | null {
  return String((req as any).user?.companyId || '').trim() || null;
}

/* ============================== Usage Tracking Helper ============================== */

async function trackReasonUsage(
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
    console.error('Usage tracking failed in reason:', trackingError);
  }
}

function ok(res: Response, data: any, code = 200) {
  return res.status(code).json(data);
}
function bad(res: Response, msg = "Bad request", code = 400) {
  return res.status(code).json({ status: "error", message: msg });
}
function notfound(res: Response, msg = "Not found") {
  return res.status(404).json({ status: "error", message: msg });
}

/* ----------------------- Reason Types CRUD ---------------------- */
export async function listTypes(req: Request, res: Response) {
  const companyId = getReqCompanyId(req);
  if (!companyId) {
    return res.status(403).json({ status: "error", message: "Company ID missing in token" });
  }

  const snap = await db.collection(TYPES_COL)
    .where("companyId", "==", companyId)
    .where("deleted", "==", false)
    .get();
  const items = snap.docs.map(d => ({ id: d.id, ...(d.data() as any) }));

  // Track usage after successful types read
  await trackReasonUsage(req, {
    readCount: 1,
    apiCalls: 1,
  });

  return ok(res, items);
}

export async function createType(req: Request, res: Response) {
  const companyId = getReqCompanyId(req);
  if (!companyId) {
    return res.status(403).json({ status: "error", message: "Company ID missing in token" });
  }

  console.log('[createType] req.user =', (req as any).user);
  console.log('[createType] companyId =', companyId);
  console.log('[createType] body =', req.body);

  const name = safe(req.body?.name);
  if (!name) return bad(res, "Field `name` is required");

  const dup = await db.collection(TYPES_COL)
    .where("companyId", "==", companyId)
    .where("name_lower", "==", name.toLowerCase())
    .where("deleted", "==", false)
    .limit(1).get();
  if (!dup.empty) return bad(res, "Type already exists");

  console.log('[createType] saving payload =', {
    name,
    name_lower: name.toLowerCase(),
    companyId,
    deleted: false
  });

  const doc = await db.collection(TYPES_COL).add({
    name,
    name_lower: name.toLowerCase(),
    companyId,
    deleted: false,
    createdAt: now(),
    updatedAt: now(),
  });
  const data = (await doc.get()).data();

  // Track usage after successful type creation
  await trackReasonUsage(req, {
    writeCount: 1,
    apiCalls: 1,
  });

  return ok(res, { id: doc.id, ...(data as any) }, 201);
}

export async function deleteType(req: Request, res: Response) {
  const companyId = getReqCompanyId(req);
  if (!companyId) {
    return res.status(403).json({ status: "error", message: "Company ID missing in token" });
  }

  const id = safe(req.params.id);
  const ref = db.collection(TYPES_COL).doc(id);
  const snap = await ref.get();
  if (!snap.exists) return notfound(res, "Type not found");

  const typeData = snap.data() as any;
  if (typeData.companyId !== companyId) {
    return res.status(403).json({ status: "error", message: "You are not allowed to delete this type" });
  }

  // Soft delete type
  await ref.update({ deleted: true, updatedAt: now() });

  // Soft delete reasons for this type as well (only from same company)
  const batch = db.batch();
  const rs = await db.collection(REASONS_COL)
    .where("typeId", "==", id)
    .where("companyId", "==", companyId)
    .where("deleted", "==", false)
    .get();
  rs.forEach(d => batch.update(d.ref, { deleted: true, updatedAt: now() }));
  await batch.commit();

  // Track usage after successful type deletion
  await trackReasonUsage(req, {
    deleteCount: 1,
    apiCalls: 1,
  });

  return ok(res, { status: "ok", message: "Type and its reasons soft-deleted" });
}

/* ------------------------- Reasons CRUD ------------------------- */

// GET /api/reasons?search=..&typeId=..&limit=50&cursor=docId
export async function listReasons(req: Request, res: Response) {
  const companyId = getReqCompanyId(req);
  if (!companyId) {
    return res.status(403).json({ status: "error", message: "Company ID missing in token" });
  }

  const { search, typeId, limit = 50, cursor } = req.query as any;

  // First try the ideal (indexed) query
  try {
    let q: FirebaseFirestore.Query = db.collection(REASONS_COL)
      .where("companyId", "==", companyId)
      .where("deleted", "==", false)
      .orderBy("createdAt", "desc");

    if (typeId) q = q.where("typeId", "==", safe(typeId));

    if (cursor) {
      const cdoc = await db.collection(REASONS_COL).doc(String(cursor)).get();
      if (cdoc.exists) q = q.startAfter(cdoc);
    }

    const snap = await q.limit(Number(limit) || 50).get();
    let items = snap.docs.map(d => ({ id: d.id, ...(d.data() as any) }));

    if (search) {
      const s = String(search).toLowerCase();
      items = items.filter(r =>
        String(r.reason ?? "").toLowerCase().includes(s) ||
        String(r.typeName ?? "").toLowerCase().includes(s)
      );
    }

    const nextCursor = snap.docs.length ? snap.docs[snap.docs.length - 1].id : null;

    // Track usage after successful reasons read
    await trackReasonUsage(req, {
      readCount: 1,
      apiCalls: 1,
    });

    return ok(res, { items, nextCursor });
  } catch (err: any) {
    // If there is no composite index, Firestore throws FAILED_PRECONDITION (code 9)
    if (err?.code !== 9 /* FAILED_PRECONDITION */) {
      console.error('listReasons unexpected error:', err);
      return res.status(500).json({ status: 'error', message: err?.message || 'Internal error' });
    }
  }

  // Fallback (no composite index): fetch without orderBy and sort in memory
  try {
    let q: FirebaseFirestore.Query = db.collection(REASONS_COL)
      .where("companyId", "==", companyId)
      .where("deleted", "==", false);

    if (typeId) q = q.where("typeId", "==", safe(typeId));

    const snap = await q.limit(500).get(); // safe cap; adjust as needed
    let items = snap.docs.map(d => ({ id: d.id, ...(d.data() as any) }));

    // Sort locally by createdAt desc
    items.sort((a: any, b: any) => {
      const ta = (a?.createdAt?._seconds ?? a?.createdAt?.seconds ?? 0);
      const tb = (b?.createdAt?._seconds ?? b?.createdAt?.seconds ?? 0);
      return tb - ta;
    });

    if (search) {
      const s = String(search).toLowerCase();
      items = items.filter(r =>
        String(r.reason ?? "").toLowerCase().includes(s) ||
        String(r.typeName ?? "").toLowerCase().includes(s)
      );
    }

    // Fallback pagination omitted (no stable server-side order without index)
        // Track usage after successful reasons read (fallback)
    await trackReasonUsage(req, {
      readCount: 1,
      apiCalls: 1,
    });

    return ok(res, { items, nextCursor: null });
  } catch (err: any) {
    console.error('listReasons fallback error:', err);
    return res.status(500).json({ status: 'error', message: err?.message || 'Internal error' });
  }
}

// POST /api/reasons  { typeId, reason, createdBy? }
export async function createReason(req: Request, res: Response) {
  const companyId = getReqCompanyId(req);
  if (!companyId) {
    return res.status(403).json({ status: "error", message: "Company ID missing in token" });
  }

  const typeId = safe(req.body?.typeId);
  const reason = safe(req.body?.reason);
  const createdBy = safe((req as any).user?.email ?? req.body?.createdBy);

  if (!typeId) return bad(res, "Field `typeId` is required");
  if (!reason) return bad(res, "Field `reason` is required");

  const typeDoc = await db.collection(TYPES_COL).doc(typeId).get();
  if (!typeDoc.exists || (typeDoc.data() as any)?.deleted) return bad(res, "Invalid typeId");

  const typeData = typeDoc.data() as any;
  if (typeData.companyId !== companyId) {
    return res.status(403).json({ status: "error", message: "You are not allowed to use this type" });
  }

  const typeName = typeData.name;

  const doc = await db.collection(REASONS_COL).add({
    typeId,
    typeName,
    reason,
    companyId,
    createdBy: createdBy || null,
    deleted: false,
    createdAt: now(),
    updatedAt: now(),
  });

  const data = (await doc.get()).data();

  // Track usage after successful reason creation
  await trackReasonUsage(req, {
    writeCount: 1,
    apiCalls: 1,
  });

  return ok(res, { id: doc.id, ...(data as any) }, 201);
}

// DELETE /api/reasons/:id
export async function deleteReason(req: Request, res: Response) {
  const companyId = getReqCompanyId(req);
  if (!companyId) {
    return res.status(403).json({ status: "error", message: "Company ID missing in token" });
  }

  const id = safe(req.params.id);
  const ref = db.collection(REASONS_COL).doc(id);
  const snap = await ref.get();
  if (!snap.exists) return notfound(res, "Reason not found");

  const reasonData = snap.data() as any;
  if (reasonData.companyId !== companyId) {
    return res.status(403).json({ status: "error", message: "You are not allowed to delete this reason" });
  }

  await ref.update({ deleted: true, updatedAt: now() });

  // Track usage after successful reason deletion
  await trackReasonUsage(req, {
    deleteCount: 1,
    apiCalls: 1,
  });

  return ok(res, { status: "ok", message: "Reason soft-deleted" });
}
