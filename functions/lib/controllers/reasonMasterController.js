"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.listTypes = listTypes;
exports.createType = createType;
exports.deleteType = deleteType;
exports.listReasons = listReasons;
exports.createReason = createReason;
exports.deleteReason = deleteReason;
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
const TYPES_COL = "reason_types";
const REASONS_COL = "reasons";
/* --------------------------- helpers --------------------------- */
const safe = (v) => String(v ?? "").trim();
const now = () => admin.firestore.FieldValue.serverTimestamp();
function ok(res, data, code = 200) {
    return res.status(code).json(data);
}
function bad(res, msg = "Bad request", code = 400) {
    return res.status(code).json({ status: "error", message: msg });
}
function notfound(res, msg = "Not found") {
    return res.status(404).json({ status: "error", message: msg });
}
/* ----------------------- Reason Types CRUD ---------------------- */
async function listTypes(_req, res) {
    const snap = await db.collection(TYPES_COL).where("deleted", "==", false).get();
    const items = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    return ok(res, items);
}
async function createType(req, res) {
    const name = safe(req.body?.name);
    if (!name)
        return bad(res, "Field `name` is required");
    const dup = await db.collection(TYPES_COL)
        .where("name_lower", "==", name.toLowerCase())
        .where("deleted", "==", false)
        .limit(1).get();
    if (!dup.empty)
        return bad(res, "Type already exists");
    const doc = await db.collection(TYPES_COL).add({
        name,
        name_lower: name.toLowerCase(),
        deleted: false,
        createdAt: now(),
        updatedAt: now(),
    });
    const data = (await doc.get()).data();
    return ok(res, { id: doc.id, ...data }, 201);
}
async function deleteType(req, res) {
    const id = safe(req.params.id);
    const ref = db.collection(TYPES_COL).doc(id);
    const snap = await ref.get();
    if (!snap.exists)
        return notfound(res, "Type not found");
    // Soft delete type
    await ref.update({ deleted: true, updatedAt: now() });
    // Soft delete reasons for this type as well
    const batch = db.batch();
    const rs = await db.collection(REASONS_COL)
        .where("typeId", "==", id)
        .where("deleted", "==", false)
        .get();
    rs.forEach(d => batch.update(d.ref, { deleted: true, updatedAt: now() }));
    await batch.commit();
    return ok(res, { status: "ok", message: "Type and its reasons soft-deleted" });
}
/* ------------------------- Reasons CRUD ------------------------- */
// GET /api/reasons?search=..&typeId=..&limit=50&cursor=docId
async function listReasons(req, res) {
    const { search, typeId, limit = 50, cursor } = req.query;
    // First try the ideal (indexed) query
    try {
        let q = db.collection(REASONS_COL)
            .where("deleted", "==", false)
            .orderBy("createdAt", "desc");
        if (typeId)
            q = q.where("typeId", "==", safe(typeId));
        if (cursor) {
            const cdoc = await db.collection(REASONS_COL).doc(String(cursor)).get();
            if (cdoc.exists)
                q = q.startAfter(cdoc);
        }
        const snap = await q.limit(Number(limit) || 50).get();
        let items = snap.docs.map(d => ({ id: d.id, ...d.data() }));
        if (search) {
            const s = String(search).toLowerCase();
            items = items.filter(r => String(r.reason ?? "").toLowerCase().includes(s) ||
                String(r.typeName ?? "").toLowerCase().includes(s));
        }
        const nextCursor = snap.docs.length ? snap.docs[snap.docs.length - 1].id : null;
        return ok(res, { items, nextCursor });
    }
    catch (err) {
        // If there is no composite index, Firestore throws FAILED_PRECONDITION (code 9)
        if (err?.code !== 9 /* FAILED_PRECONDITION */) {
            console.error('listReasons unexpected error:', err);
            return res.status(500).json({ status: 'error', message: err?.message || 'Internal error' });
        }
    }
    // Fallback (no composite index): fetch without orderBy and sort in memory
    try {
        let q = db.collection(REASONS_COL)
            .where("deleted", "==", false);
        if (typeId)
            q = q.where("typeId", "==", safe(typeId));
        const snap = await q.limit(500).get(); // safe cap; adjust as needed
        let items = snap.docs.map(d => ({ id: d.id, ...d.data() }));
        // Sort locally by createdAt desc
        items.sort((a, b) => {
            const ta = (a?.createdAt?._seconds ?? a?.createdAt?.seconds ?? 0);
            const tb = (b?.createdAt?._seconds ?? b?.createdAt?.seconds ?? 0);
            return tb - ta;
        });
        if (search) {
            const s = String(search).toLowerCase();
            items = items.filter(r => String(r.reason ?? "").toLowerCase().includes(s) ||
                String(r.typeName ?? "").toLowerCase().includes(s));
        }
        // Fallback pagination omitted (no stable server-side order without index)
        return ok(res, { items, nextCursor: null });
    }
    catch (err) {
        console.error('listReasons fallback error:', err);
        return res.status(500).json({ status: 'error', message: err?.message || 'Internal error' });
    }
}
// POST /api/reasons  { typeId, reason, createdBy? }
async function createReason(req, res) {
    const typeId = safe(req.body?.typeId);
    const reason = safe(req.body?.reason);
    const createdBy = safe(req.user?.email ?? req.body?.createdBy);
    if (!typeId)
        return bad(res, "Field `typeId` is required");
    if (!reason)
        return bad(res, "Field `reason` is required");
    const typeDoc = await db.collection(TYPES_COL).doc(typeId).get();
    if (!typeDoc.exists || typeDoc.data()?.deleted)
        return bad(res, "Invalid typeId");
    const typeName = typeDoc.data().name;
    const doc = await db.collection(REASONS_COL).add({
        typeId,
        typeName,
        reason,
        createdBy: createdBy || null,
        deleted: false,
        createdAt: now(),
        updatedAt: now(),
    });
    const data = (await doc.get()).data();
    return ok(res, { id: doc.id, ...data }, 201);
}
// DELETE /api/reasons/:id
async function deleteReason(req, res) {
    const id = safe(req.params.id);
    const ref = db.collection(REASONS_COL).doc(id);
    const snap = await ref.get();
    if (!snap.exists)
        return notfound(res, "Reason not found");
    await ref.update({ deleted: true, updatedAt: now() });
    return ok(res, { status: "ok", message: "Reason soft-deleted" });
}
//# sourceMappingURL=reasonMasterController.js.map