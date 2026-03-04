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
exports.deleteLeaveType = exports.listLeaveTypes = exports.createLeaveType = void 0;
const uuid_1 = require("uuid");
const admin = __importStar(require("firebase-admin"));
const firebase_1 = require("../config/firebase");
const COLL = 'leave_types';
/**
 * POST /api/leave-types
 * Body: { type, fromDate, toDate, days }
 * Admin only
 */
const createLeaveType = async (req, res) => {
    try {
        const { userId, role } = (req.user ?? {});
        if (role !== 'admin') {
            return res.status(200).json({ message: 'Access restricted to administrators' });
        }
        let { type, fromDate, toDate, days } = (req.body ?? {});
        type = String(type ?? '').trim();
        // >>> SHIFT REMOVED: only require type/fromDate/toDate/days
        if (!type || !fromDate || !toDate || days == null) {
            return res.status(200).json({ message: 'Please fill in all required fields' });
        }
        const s = new Date(fromDate);
        const e = new Date(toDate);
        const allowedDays = Number(days);
        if (Number.isNaN(s.getTime()) || Number.isNaN(e.getTime()) || e < s) {
            return res.status(200).json({ message: 'Please enter valid dates' });
        }
        if (!Number.isFinite(allowedDays) || allowedDays <= 0) {
            return res.status(200).json({ message: 'Number of days must be greater than zero' });
        }
        const id = (0, uuid_1.v4)();
        const payload = {
            id,
            type,
            // >>> SHIFT REMOVED: no shift field in payload
            fromDate: admin.firestore.Timestamp.fromDate(s),
            toDate: admin.firestore.Timestamp.fromDate(e),
            allowedDays,
            active: true,
            createdBy: userId ?? null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        await firebase_1.db.collection(COLL).doc(id).set(payload);
        return res.status(201).json(payload);
    }
    catch (err) {
        console.error('[leave-types:create] error', err);
        return res.status(200).json({ message: 'An error occurred while processing your request' });
    }
};
exports.createLeaveType = createLeaveType;
/**
 * GET /api/leave-types
 * (shift filter removed)
 */
const listLeaveTypes = async (req, res) => {
    try {
        // >>> SHIFT REMOVED: always return active leave types, no query param needed
        const snaps = await firebase_1.db.collection(COLL).where('active', '==', true).get();
        const out = snaps.docs.map((d) => d.data());
        return res.status(200).json(out);
    }
    catch (err) {
        console.error('[leave-types:list] error', err);
        return res.status(200).json({ message: 'Unable to load leave types' });
    }
};
exports.listLeaveTypes = listLeaveTypes;
/**
 * DELETE /api/leave-types/:id
 * Admin only
 */
const deleteLeaveType = async (req, res) => {
    try {
        const { role } = (req.user ?? {});
        if (role !== 'admin') {
            return res.status(200).json({ message: 'Access restricted to administrators' });
        }
        const { id } = req.params;
        if (!id) {
            return res.status(200).json({ message: 'Leave type not found' });
        }
        // First check if the document exists
        const doc = await firebase_1.db.collection(COLL).doc(id).get();
        if (!doc.exists) {
            return res.status(404).json({ error: 'Leave type not found' });
        }
        // Soft delete by setting active to false
        await firebase_1.db.collection(COLL).doc(id).update({
            active: false,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        return res.status(200).json({
            status: 'success',
            message: 'Leave type deleted successfully'
        });
    }
    catch (err) {
        console.error('[leave-types:delete] error', err);
        return res.status(500).json({
            error: err?.message || 'Failed to delete leave type'
        });
    }
};
exports.deleteLeaveType = deleteLeaveType;
//# sourceMappingURL=leaveTypeController.js.map