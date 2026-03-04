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
exports.getMyRewards = exports.deleteReward = exports.getRewardById = exports.getAllRewards = exports.createReward = void 0;
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
const REWARDS = 'rewards';
/** Normalize various date inputs (ISO string / number / Firestore Timestamp) to JS Date. */
function normalizeDate(input) {
    if (!input)
        return new Date();
    if (typeof input === 'object' && input !== null && typeof input.toDate === 'function') {
        try {
            return input.toDate();
        }
        catch {
            /* fallthrough */
        }
    }
    const d = new Date(input);
    return isNaN(d.getTime()) ? new Date() : d;
}
/** Safely read a string field; trims and returns '' if missing. */
function str(v) {
    return (typeof v === 'string' ? v : '').trim();
}
/** Convert Firestore doc (or plain object) to response-friendly JSON (dates => ISO). */
function serialize(doc) {
    const data = (doc && typeof doc.data === 'function') ? doc.data() : doc || {};
    const out = { id: doc?.id ?? data.id, ...data };
    const toIso = (v) => {
        if (!v)
            return v;
        if (typeof v === 'object' && typeof v.toDate === 'function')
            return v.toDate().toISOString();
        if (v instanceof Date)
            return v.toISOString();
        return v;
    };
    out.date = toIso(out.date);
    out.createdAt = toIso(out.createdAt);
    out.updatedAt = toIso(out.updatedAt);
    return out;
}
// ---------------------------------------------------------------------------
// Controllers
// ---------------------------------------------------------------------------
/** POST /api/rewards */
const createReward = async (req, res) => {
    try {
        const body = (req.body || {});
        const empid = str(body.empid);
        const name = str(body.name);
        const department = str(body.department);
        const description = str(body.description);
        // If you use auth, prefer admin name from token; else body/admin fallback
        const user = req.user;
        const adminname = str(user?.name) ||
            str(user?.email) ||
            str(body.adminname) ||
            'Admin';
        const missing = [];
        if (!empid)
            missing.push('empid');
        if (!name)
            missing.push('name');
        if (!department)
            missing.push('department');
        if (!description)
            missing.push('description');
        if (!adminname)
            missing.push('adminname');
        if (missing.length) {
            return res.status(400).json({ error: `Missing fields: ${missing.join(', ')}` });
        }
        const now = admin.firestore.Timestamp.now();
        const reward = {
            empid,
            name,
            department,
            description,
            adminname,
            date: normalizeDate(body.date),
            createdAt: now,
            updatedAt: now,
        };
        const docRef = await db.collection(REWARDS).add(reward);
        const saved = await docRef.get();
        return res.status(201).json(serialize(saved));
    }
    catch (error) {
        console.error('createReward error:', error);
        return res.status(500).json({ error: error.message || 'Server error' });
    }
};
exports.createReward = createReward;
/**
 * GET /api/rewards
 * If ?empid= is provided, tries exact / lower / upper case variants, merges, sorts by date desc.
 * If not provided, returns all rewards ordered by date desc.
 */
const getAllRewards = async (req, res) => {
    try {
        const empidParam = str(req.query?.empid);
        const rewards = [];
        if (empidParam) {
            const tried = new Set();
            const variants = [empidParam];
            const lc = empidParam.toLowerCase();
            const uc = empidParam.toUpperCase();
            if (lc !== empidParam)
                variants.push(lc);
            if (uc !== empidParam && uc !== lc)
                variants.push(uc);
            for (const v of variants) {
                if (tried.has(v))
                    continue;
                tried.add(v);
                const snap = await db.collection(REWARDS).where('empid', '==', v).get();
                for (const d of snap.docs)
                    rewards.push(serialize(d));
                // If exact value returned matches, can break early
                if (rewards.length && v === empidParam)
                    break;
            }
            // Dedup by id
            const dedup = Object.values(rewards.reduce((acc, r) => {
                acc[r.id] = r;
                return acc;
            }, {}));
            // Sort newest first using normalized date
            dedup.sort((a, b) => new Date(b.date || 0).getTime() - new Date(a.date || 0).getTime());
            return res.json(dedup);
        }
        // No filter
        const snapshot = await db.collection(REWARDS).orderBy('date', 'desc').get();
        return res.json(snapshot.docs.map((d) => serialize(d)));
    }
    catch (error) {
        console.error('getAllRewards error:', error);
        return res.status(500).json({ error: error.message || 'Server error' });
    }
};
exports.getAllRewards = getAllRewards;
/** GET /api/rewards/:id */
const getRewardById = async (req, res) => {
    try {
        const id = String(req.params.id);
        const doc = await db.collection(REWARDS).doc(id).get();
        if (!doc.exists)
            return res.status(404).json({ error: 'Not found' });
        return res.json(serialize(doc));
    }
    catch (error) {
        console.error('getRewardById error:', error);
        return res.status(500).json({ error: error.message || 'Server error' });
    }
};
exports.getRewardById = getRewardById;
/** DELETE /api/rewards/:id */
const deleteReward = async (req, res) => {
    try {
        const id = String(req.params.id);
        await db.collection(REWARDS).doc(id).delete();
        return res.json({ message: 'Deleted successfully' });
    }
    catch (error) {
        console.error('deleteReward error:', error);
        return res.status(500).json({ error: error.message || 'Server error' });
    }
};
exports.deleteReward = deleteReward;
/** GET /api/rewards/mine  (requires auth; expects req.user.empid) */
const getMyRewards = async (req, res) => {
    try {
        const empid = str(req.user?.empid);
        if (!empid)
            return res.status(401).json({ error: 'Unauthorized: missing empid' });
        const snap = await db.collection(REWARDS).where('empid', '==', empid).get();
        const list = snap.docs.map((d) => serialize(d));
        return res.json(list);
    }
    catch (error) {
        console.error('getMyRewards error:', error);
        return res.status(500).json({ error: error.message || 'Server error' });
    }
};
exports.getMyRewards = getMyRewards;
//# sourceMappingURL=rewardController.js.map