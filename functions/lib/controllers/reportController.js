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
exports.runNow = exports.deleteSchedule = exports.listSchedules = exports.createSchedule = void 0;
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
const REPORTS = 'reports';
/** Create a new schedule */
const createSchedule = async (req, res) => {
    try {
        const { name, reportType, templateId, recipient, scheduleTime } = req.body;
        if (!name || !reportType || !templateId || !recipient || !scheduleTime) {
            return res.status(400).json({ message: 'All fields are required.' });
        }
        const docRef = await db.collection(REPORTS).add({
            name,
            reportType,
            templateId,
            recipient,
            scheduleTime,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return res.status(201).json({ id: docRef.id, message: 'Schedule created.' });
    }
    catch (err) {
        console.error('createSchedule error:', err);
        return res.status(500).json({ message: 'Server error.' });
    }
};
exports.createSchedule = createSchedule;
/** List all schedules */
const listSchedules = async (_req, res) => {
    try {
        const snap = await db.collection(REPORTS).orderBy('createdAt', 'desc').get();
        const data = snap.docs.map((d) => {
            const raw = d.data();
            const createdAtIso = raw?.createdAt && typeof raw.createdAt.toDate === 'function'
                ? raw.createdAt.toDate().toISOString()
                : new Date().toISOString();
            return { id: d.id, ...raw, createdAt: createdAtIso };
        });
        return res.status(200).json(data);
    }
    catch (err) {
        console.error('listSchedules error:', err);
        return res.status(500).json({ message: 'Server error.' });
    }
};
exports.listSchedules = listSchedules;
/** Delete a schedule */
const deleteSchedule = async (req, res) => {
    try {
        const { id } = req.params;
        await db.collection(REPORTS).doc(id).delete();
        return res.status(200).json({ message: 'Schedule deleted.' });
    }
    catch (err) {
        console.error('deleteSchedule error:', err);
        return res.status(500).json({ message: 'Server error.' });
    }
};
exports.deleteSchedule = deleteSchedule;
/** Run a schedule immediately (manual trigger) */
const runNow = async (req, res) => {
    try {
        const { id } = req.params;
        const doc = await db.collection(REPORTS).doc(id).get();
        if (!doc.exists)
            return res.status(404).json({ message: 'Not found.' });
        // TODO: integrate with your report service if/when needed.
        // await reportService.runReport(doc.data());
        return res.status(200).json({ message: 'Report run manually.' });
    }
    catch (err) {
        console.error('runNow error:', err);
        return res.status(500).json({ message: 'Server error.' });
    }
};
exports.runNow = runNow;
//# sourceMappingURL=reportController.js.map