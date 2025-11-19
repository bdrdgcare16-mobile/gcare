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
exports.getAllFeedback = exports.createFeedback = void 0;
const admin = __importStar(require("firebase-admin"));
const COLL = 'feedbacks';
// Helper: safely get Firestore from app.locals (set by router factory)
const getDb = (req) => {
    const locals = req.app?.locals;
    if (!locals?.db) {
        throw new Error('Database not initialized in app.locals');
    }
    return locals.db;
};
/**
 * POST /api/feedback
 * Headers (either):
 *  - x-user-id  (users/<id> doc will be resolved to empid/name), OR
 *  - x-empid AND x-name
 * Body:
 *  - { message: string }
 */
const createFeedback = async (req, res) => {
    try {
        const db = getDb(req);
        const message = String(req.body?.message ?? '').trim();
        const headerUserId = String(req.header('x-user-id') ?? '').trim();
        const headerEmpId = String(req.header('x-empid') ?? '').trim();
        const headerName = String(req.header('x-name') ?? '').trim();
        if (!message) {
            return res.status(400).json({ error: 'Missing message' });
        }
        let empid = '';
        let name = '';
        if (headerUserId) {
            // Resolve from users/<id>
            const snap = await db.collection('users').doc(headerUserId).get();
            if (!snap.exists) {
                return res.status(404).json({ error: 'User not found in users DB' });
            }
            const u = snap.data() ?? {};
            empid = String(u.empid ?? '');
            name = String(u.name ?? '');
        }
        else {
            // Fallback to direct meta
            empid = headerEmpId || String(req.body?.empid ?? '');
            name = headerName || String(req.body?.name ?? '');
        }
        if (!empid || !name) {
            return res.status(400).json({
                error: 'Missing user id and emp meta. Provide x-user-id OR x-empid/x-name (or empid/name in body).',
            });
        }
        const doc = {
            empid,
            name,
            message,
            date: admin.firestore.Timestamp.now(),
            response: '',
            visibility: ['admin'],
        };
        const ref = await db.collection(COLL).add(doc);
        return res.status(201).json({ id: ref.id });
    }
    catch (err) {
        console.error('createFeedback error:', err);
        return res.status(500).json({ error: err?.message ?? 'Server error' });
    }
};
exports.createFeedback = createFeedback;
/**
 * GET /api/feedback
 * Returns an array of feedbacks (newest first).
 */
const getAllFeedback = async (req, res) => {
    try {
        const db = getDb(req);
        const snap = await db.collection(COLL).orderBy('date', 'desc').get();
        const data = snap.docs.map((d) => {
            const x = d.data();
            // Normalize date to ISO string
            let iso = '';
            const dt = x?.date;
            if (dt && typeof dt.toDate === 'function') {
                iso = dt.toDate().toISOString();
            }
            else if (dt instanceof Date) {
                iso = dt.toISOString();
            }
            return {
                id: d.id,
                empid: String(x?.empid ?? ''),
                name: String(x?.name ?? ''),
                message: String(x?.message ?? ''),
                response: String(x?.response ?? ''),
                visibility: Array.isArray(x?.visibility) ? x.visibility : [],
                date: iso,
            };
        });
        return res.json(data);
    }
    catch (err) {
        console.error('getAllFeedback error:', err);
        return res.status(500).json({ error: err?.message ?? 'Server error' });
    }
};
exports.getAllFeedback = getAllFeedback;
//# sourceMappingURL=feedbackController.js.map