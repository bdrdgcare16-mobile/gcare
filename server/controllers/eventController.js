
const path = require('path');
const fs = require('fs');
const { randomUUID } = require('crypto'); // ✅ use built-in UUID

const getTrim = (obj, key) => (obj?.[key] ?? '').toString().trim();

// ensure uploads directory exists once
const uploadsDir = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

exports.createEvent = async (req, res) => {
  try {
    // helpful logs while integrating
    console.log('[events:create] content-type:', req.headers['content-type']);
    console.log('[events:create] body keys:', Object.keys(req.body || {}));
    console.log('[events:create] files keys:', req.files ? Object.keys(req.files) : '(none)');

    const db = req.app.locals.db;

    const title       = getTrim(req.body, 'title');
    const description = getTrim(req.body, 'description');
    const location    = getTrim(req.body, 'location');
    const fromDate    = getTrim(req.body, 'fromDate'); // yyyy-MM-dd
    const toDate      = getTrim(req.body, 'toDate');

    const missing = [];
    if (!title)       missing.push('title');
    if (!description) missing.push('description');
    if (!location)    missing.push('location');
    if (!fromDate)    missing.push('fromDate');
    if (!toDate)      missing.push('toDate');

    if (missing.length) {
      return res.status(400).json({ error: `Missing: ${missing.join(', ')}` });
    }

    let imageUrl = null;
    let fileUrl  = null;

    // express-fileupload can give a single file or an array; normalize to one
    const pickFirst = (f) => (Array.isArray(f) ? f[0] : f) || null;

    if (req.files?.image) {
      const image = pickFirst(req.files.image);
      const imageName = `${randomUUID()}${path.extname(image.name)}`; // ✅ no uuidv4()
      const imagePath = path.join(uploadsDir, imageName);
      await image.mv(imagePath);
      imageUrl = `/uploads/${imageName}`;
    }

    if (req.files?.file) {
      const f = pickFirst(req.files.file);
      const fileName = `${randomUUID()}${path.extname(f.name)}`; // ✅ no uuidv4()
      const filePath = path.join(uploadsDir, fileName);
      await f.mv(filePath);
      fileUrl = `/uploads/${fileName}`;
    }

    const eventDoc = {
      title,
      description,
      location,
      fromDate,
      toDate,
      imageUrl,
      fileUrl,
      createdAt: new Date(),
    };

    const ref = await db.collection('events').add(eventDoc);
    return res.status(201).json({ id: ref.id, ...eventDoc });
  } catch (err) {
    console.error('[events:create] error:', err);
    return res.status(500).json({ error: err.message || String(err) });
  }
};

exports.getAllEvents = async (req, res) => {
  try {
    const db = req.app.locals.db;
    const snap = await db.collection('events').orderBy('fromDate', 'desc').get();
    const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    return res.json(data);
  } catch (err) {
    console.error('[events:getAll] error:', err);
    return res.status(500).json({ error: err.message || String(err) });
  }
};

exports.deleteEvent = async (req, res) => {
  try {
    const db = req.app.locals.db;
    await db.collection('events').doc(req.params.id).delete();
    return res.status(200).json({ message: 'Event deleted successfully' });
  } catch (err) {
    console.error('[events:delete] error:', err);
    return res.status(500).json({ error: err.message || String(err) });
  }
};
