"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteEvent = exports.getAllEvents = exports.createEvent = void 0;
const path_1 = __importDefault(require("path"));
const fs_1 = __importDefault(require("fs"));
const crypto_1 = require("crypto");
// Helper to safely trim fields
const getTrim = (obj, key) => (obj?.[key] ?? '').toString().trim();
// Ensure uploads directory exists (note: on serverless, use /tmp for persistence)
const uploadsDir = path_1.default.join(__dirname, '..', 'uploads');
if (!fs_1.default.existsSync(uploadsDir)) {
    fs_1.default.mkdirSync(uploadsDir, { recursive: true });
}
// Pick first file if array, else the single file, else null
const pickFirst = (f) => (Array.isArray(f) ? (f[0] ?? null) : (f ?? null));
const moveFile = (file, destPath) => new Promise((resolve, reject) => {
    try {
        file.mv(destPath, (err) => (err ? reject(err) : resolve()));
    }
    catch (e) {
        reject(e);
    }
});
const createEvent = async (req, res) => {
    try {
        // Helpful logs while integrating
        console.log('[events:create] content-type:', req.headers['content-type']);
        console.log('[events:create] body keys:', Object.keys(req.body || {}));
        console.log('[events:create] files keys:', req.files ? Object.keys(req.files) : '(none)');
        const db = req.app.locals.db;
        const title = getTrim(req.body, 'title');
        const description = getTrim(req.body, 'description');
        const location = getTrim(req.body, 'location');
        const fromDate = getTrim(req.body, 'fromDate'); // yyyy-MM-dd
        const toDate = getTrim(req.body, 'toDate');
        const missing = [];
        if (!title)
            missing.push('title');
        if (!description)
            missing.push('description');
        if (!location)
            missing.push('location');
        if (!fromDate)
            missing.push('fromDate');
        if (!toDate)
            missing.push('toDate');
        if (missing.length) {
            return res.status(400).json({ error: `Missing: ${missing.join(', ')}` });
        }
        let imageUrl = null;
        let fileUrl = null;
        // Note: using express-fileupload (req.files), typed as any here
        const files = req.files;
        if (files?.image) {
            const image = pickFirst(files.image);
            if (image) {
                const imageName = `${(0, crypto_1.randomUUID)()}${path_1.default.extname(image.name)}`;
                const imagePath = path_1.default.join(uploadsDir, imageName);
                await moveFile(image, imagePath);
                imageUrl = `/uploads/${imageName}`;
            }
        }
        if (files?.file) {
            const f = pickFirst(files.file);
            if (f) {
                const fileName = `${(0, crypto_1.randomUUID)()}${path_1.default.extname(f.name)}`;
                const filePath = path_1.default.join(uploadsDir, fileName);
                await moveFile(f, filePath);
                fileUrl = `/uploads/${fileName}`;
            }
        }
        const eventDoc = {
            title,
            description,
            location,
            fromDate, // stored as string "yyyy-MM-dd" (lex-sortable)
            toDate, // stored as string "yyyy-MM-dd"
            imageUrl,
            fileUrl,
            createdAt: new Date(),
        };
        const ref = await db.collection('events').add(eventDoc);
        return res.status(201).json({ id: ref.id, ...eventDoc });
    }
    catch (err) {
        console.error('[events:create] error:', err);
        return res.status(500).json({ error: err.message || String(err) });
    }
};
exports.createEvent = createEvent;
const getAllEvents = async (req, res) => {
    try {
        const db = req.app.locals.db;
        const snap = await db.collection('events').orderBy('fromDate', 'desc').get();
        const data = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
        return res.json(data);
    }
    catch (err) {
        console.error('[events:getAll] error:', err);
        return res.status(500).json({ error: err.message || String(err) });
    }
};
exports.getAllEvents = getAllEvents;
const deleteEvent = async (req, res) => {
    try {
        const db = req.app.locals.db;
        const { id } = req.params;
        await db.collection('events').doc(id).delete();
        return res.status(200).json({ message: 'Event deleted successfully' });
    }
    catch (err) {
        console.error('[events:delete] error:', err);
        return res.status(500).json({ error: err.message || String(err) });
    }
};
exports.deleteEvent = deleteEvent;
//# sourceMappingURL=eventController.js.map