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
exports.getCompanyProfile = exports.checkCompanyProfile = exports.saveCompanyProfile = void 0;
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
const COMPANY_COLLECTION = 'companyProfile';
const normalizeEmail = (v) => String(v || '').trim().toLowerCase();
const computeFilled = (p) => Boolean(p.companyName && p.email && p.phone && p.adminName && p.designation);
/** Try multiple ways to find a profile for a given admin email (lowercased). */
async function findProfileDoc(adminEmailLower) {
    // 1) Fast path: docId === admin email lower
    const byIdRef = db.collection(COMPANY_COLLECTION).doc(adminEmailLower);
    const byIdSnap = await byIdRef.get();
    if (byIdSnap.exists)
        return byIdSnap;
    // 2) Fallbacks (support older shapes)
    const tryQueries = [
        db.collection(COMPANY_COLLECTION).where('adminEmailLower', '==', adminEmailLower).limit(1).get(),
        db.collection(COMPANY_COLLECTION).where('adminEmail', '==', adminEmailLower).limit(1).get(),
        db.collection(COMPANY_COLLECTION).where('emailLower', '==', adminEmailLower).limit(1).get(),
        db.collection(COMPANY_COLLECTION).where('email', '==', adminEmailLower).limit(1).get(),
    ];
    for (const p of tryQueries) {
        const snap = await p;
        if (!snap.empty)
            return snap.docs[0];
    }
    return null;
}
const saveCompanyProfile = async (req, res) => {
    try {
        const tokenUser = req.user;
        const adminEmailFromToken = normalizeEmail(tokenUser?.email);
        if (!adminEmailFromToken) {
            return res.status(401).json({ success: false, message: 'Unauthorized: token email missing' });
        }
        const { companyName, email, phone, website, adminName, designation, logoBase64, logoMimeType, } = (req.body || {});
        const required = { companyName, email, phone, adminName, designation };
        const missing = Object.entries(required).filter(([, v]) => !v).map(([k]) => k);
        if (missing.length) {
            return res.status(400).json({ success: false, error: 'Missing required fields', missingFields: missing });
        }
        const now = admin.firestore.Timestamp.now();
        const docRef = db.collection(COMPANY_COLLECTION).doc(adminEmailFromToken);
        const data = {
            id: adminEmailFromToken,
            adminEmail: adminEmailFromToken,
            adminEmailLower: adminEmailFromToken,
            companyName: String(companyName),
            email: normalizeEmail(email),
            emailLower: normalizeEmail(email),
            phone: String(phone),
            website: website ? String(website) : '',
            adminName: String(adminName),
            designation: String(designation),
            updatedAt: now,
        };
        // derive/ensure "filled"
        data.filled = computeFilled(data);
        if (logoBase64 && logoMimeType) {
            const ok = ['image/jpeg', 'image/png', 'image/gif'].includes(logoMimeType);
            if (!ok)
                return res.status(400).json({ success: false, message: 'Only JPEG, PNG, GIF allowed' });
            const base64Data = (logoBase64.split(';base64,').pop() || logoBase64).trim();
            const sizeBytes = (base64Data.length * 3) / 4 - (base64Data.endsWith('==') ? 2 : base64Data.endsWith('=') ? 1 : 0);
            if (sizeBytes > 5 * 1024 * 1024) {
                return res.status(400).json({ success: false, message: 'Max image size 5MB' });
            }
            data.logoBase64 = `data:${logoMimeType};base64,${base64Data}`;
        }
        const prev = await docRef.get();
        if (!prev.exists)
            data.createdAt = now;
        await docRef.set(data, { merge: true });
        const fresh = await docRef.get();
        return res.status(200).json({
            success: true,
            message: 'Company profile saved successfully',
            data: { id: fresh.id, ...fresh.data() },
            timestamp: now.toDate().toISOString(),
        });
    }
    catch (e) {
        console.error('saveCompanyProfile error:', e);
        return res.status(500).json({ success: false, message: 'Internal server error' });
    }
};
exports.saveCompanyProfile = saveCompanyProfile;
const checkCompanyProfile = async (req, res) => {
    try {
        const tokenUser = req.user;
        const adminEmail = normalizeEmail(tokenUser?.email);
        if (!adminEmail) {
            return res.status(400).json({ success: false, filled: false, error: 'User email not found in token' });
        }
        const snap = await findProfileDoc(adminEmail);
        if (!snap) {
            return res.status(200).json({ success: true, filled: false, data: null });
        }
        const raw = snap.data() || {};
        const filled = typeof raw.filled === 'boolean' ? raw.filled : computeFilled(raw);
        return res.status(200).json({
            success: true,
            filled,
            data: { id: snap.id, ...raw },
        });
    }
    catch (error) {
        console.error('Error in checkCompanyProfile:', error);
        return res.status(500).json({ success: false, filled: false, error: 'Internal server error' });
    }
};
exports.checkCompanyProfile = checkCompanyProfile;
const getCompanyProfile = async (req, res) => {
    try {
        const tokenUser = req.user;
        const adminEmail = normalizeEmail(tokenUser?.email);
        if (!adminEmail) {
            return res.status(400).json({ success: false, message: 'User email not found in token' });
        }
        const snap = await findProfileDoc(adminEmail);
        if (!snap) {
            return res.status(404).json({ success: false, message: 'Company profile not found' });
        }
        return res.status(200).json({ success: true, data: { id: snap.id, ...snap.data() } });
    }
    catch (e) {
        console.error('getCompanyProfile error:', e);
        return res.status(500).json({ success: false, message: 'Failed to fetch company profile' });
    }
};
exports.getCompanyProfile = getCompanyProfile;
//# sourceMappingURL=companyController.js.map