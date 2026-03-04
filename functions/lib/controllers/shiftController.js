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
exports.deleteShift = exports.updateShift = exports.getShiftById = exports.getAllShifts = exports.createShift = void 0;
const admin = __importStar(require("firebase-admin"));
const uuid_1 = require("uuid");
const db = admin.firestore();
/**
 * Create a new shift template
 * POST /api/shifts
 */
const createShift = async (req, res) => {
    try {
        // Basic validation
        const { name, startTime, endTime, shiftname } = (req.body || {});
        if (!name || !startTime || !endTime || !shiftname) {
            return res
                .status(400)
                .json({ error: 'name, startTime, endTime and shiftname are required' });
        }
        const id = (0, uuid_1.v4)();
        const now = admin.firestore.Timestamp.now();
        const payload = {
            id,
            name: String(name),
            startTime: String(startTime),
            endTime: String(endTime),
            shiftname: String(shiftname),
            createdAt: now,
            updatedAt: now,
        };
        await db.collection('shifts').doc(id).set(payload);
        return res.status(201).json(payload);
    }
    catch (err) {
        console.error('createShift error:', err);
        return res.status(500).json({ error: 'Internal server error' });
    }
};
exports.createShift = createShift;
/**
 * List all shift templates
 * GET /api/shifts
 */
const getAllShifts = async (_req, res) => {
    try {
        const snap = await db
            .collection('shifts')
            .orderBy('createdAt', 'desc')
            .get();
        // Return Firestore data as-is (id is already stored in document data)
        const shifts = snap.docs.map((d) => d.data());
        return res.json(shifts);
    }
    catch (err) {
        console.error('getAllShifts error:', err);
        return res.status(500).json({ error: 'Internal server error' });
    }
};
exports.getAllShifts = getAllShifts;
/**
 * Get a single shift by UUID
 * GET /api/shifts/:id
 */
const getShiftById = async (req, res) => {
    try {
        const { id } = req.params;
        const doc = await db.collection('shifts').doc(id).get();
        if (!doc.exists) {
            return res.status(404).json({ error: 'Shift template not found' });
        }
        return res.json(doc.data());
    }
    catch (err) {
        console.error('getShiftById error:', err);
        return res.status(500).json({ error: 'Internal server error' });
    }
};
exports.getShiftById = getShiftById;
/**
 * Update a shift template
 * PUT /api/shifts/:id
 */
const updateShift = async (req, res) => {
    try {
        const { id } = req.params;
        const updates = {
            ...req.body,
            updatedAt: admin.firestore.Timestamp.now(),
        };
        const ref = db.collection('shifts').doc(id);
        const doc = await ref.get();
        if (!doc.exists) {
            return res.status(404).json({ error: 'Shift template not found' });
        }
        await ref.update(updates);
        return res.json({ id, ...updates });
    }
    catch (err) {
        console.error('updateShift error:', err);
        return res.status(500).json({ error: 'Internal server error' });
    }
};
exports.updateShift = updateShift;
/**
 * Delete a shift template
 * DELETE /api/shifts/:id
 */
const deleteShift = async (req, res) => {
    try {
        const { id } = req.params;
        const ref = db.collection('shifts').doc(id);
        const doc = await ref.get();
        if (!doc.exists) {
            return res.status(404).json({ error: 'Shift template not found' });
        }
        await ref.delete();
        return res.json({ message: 'Shift template deleted' });
    }
    catch (err) {
        console.error('deleteShift error:', err);
        return res.status(500).json({ error: 'Internal server error' });
    }
};
exports.deleteShift = deleteShift;
//# sourceMappingURL=shiftController.js.map