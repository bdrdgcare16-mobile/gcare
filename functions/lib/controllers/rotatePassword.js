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
exports.rotatePassword = rotatePassword;
const bcrypt = __importStar(require("bcryptjs"));
const firestore_1 = require("firebase-admin/firestore");
async function rotatePassword(opts) {
    const { db, userId, oldHash, newPlainPassword, source, keepLast = 5 } = opts;
    const userRef = db.collection('users').doc(userId);
    const histCol = userRef.collection('password_history');
    await db.runTransaction(async (tx) => {
        const now = firestore_1.Timestamp.now();
        // 1) Expire old hash
        if (oldHash) {
            const active = await histCol
                .where('hash', '==', oldHash)
                .where('status', '==', 'active')
                .limit(1)
                .get();
            if (!active.empty) {
                tx.update(active.docs[0].ref, { status: 'expired', expiredAt: now });
            }
            else {
                const hdoc = histCol.doc();
                tx.set(hdoc, {
                    hash: oldHash,
                    status: 'expired',
                    changedAt: now,
                    expiredAt: now,
                    source: 'migrated',
                    version: now.toMillis(),
                });
            }
        }
        // 2) Create new active hash
        const newHash = await bcrypt.hash(newPlainPassword, 10);
        const newDoc = histCol.doc();
        tx.set(newDoc, {
            hash: newHash,
            status: 'active',
            changedAt: now,
            expiredAt: null,
            source,
            version: now.toMillis(),
        });
        // 3) Update user document
        tx.set(userRef, {
            password: newHash,
            passwordHash: newHash,
            hashedPassword: newHash,
            authSource: 'firebase',
            lastPasswordChangedAt: now,
            updatedAt: now,
        }, { merge: true });
        // 4) Keep last N records only
        const histSnap = await histCol.orderBy('changedAt', 'desc').get();
        const toDelete = histSnap.docs.slice(keepLast);
        for (const d of toDelete)
            tx.delete(d.ref);
    });
}
//# sourceMappingURL=rotatePassword.js.map