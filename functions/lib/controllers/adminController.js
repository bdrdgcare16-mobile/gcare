"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createAdmin = createAdmin;
exports.promoteToAdmin = promoteToAdmin;
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const firestore_1 = require("firebase-admin/firestore");
const db = (0, firestore_1.getFirestore)();
const USERS = "users"; // ← change if your collection name is different
// POST /api/admin/create
// body: { email, password, name? }
async function createAdmin(req, res) {
    try {
        const { email, password, name = "" } = req.body || {};
        if (!email || !password) {
            return res.status(400).json({ error: "email and password are required" });
        }
        // check duplicate
        const snap = await db.collection(USERS).where("email", "==", email.toLowerCase()).limit(1).get();
        if (!snap.empty) {
            return res.status(409).json({ error: "user already exists" });
        }
        const hash = await bcryptjs_1.default.hash(password, 10);
        const doc = {
            email: email.toLowerCase(),
            password: hash,
            name,
            role: "admin",
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
        };
        const ref = await db.collection(USERS).add(doc);
        return res.status(201).json({ id: ref.id, ...doc });
    }
    catch (e) {
        return res.status(500).json({ error: e.message || "failed to create admin" });
    }
}
// POST /api/admin/promote
// body: { email }  -> sets role = "admin"
async function promoteToAdmin(req, res) {
    try {
        const { email } = req.body || {};
        if (!email)
            return res.status(400).json({ error: "email is required" });
        const q = await db.collection(USERS).where("email", "==", email.toLowerCase()).limit(1).get();
        if (q.empty)
            return res.status(404).json({ error: "user not found" });
        const docRef = q.docs[0].ref;
        await docRef.update({ role: "admin", updatedAt: new Date().toISOString() });
        return res.json({ ok: true });
    }
    catch (e) {
        return res.status(500).json({ error: e.message || "failed to promote user" });
    }
}
//# sourceMappingURL=adminController.js.map