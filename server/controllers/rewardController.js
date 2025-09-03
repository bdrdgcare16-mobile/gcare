
function normalizeDate(input) {
  if (!input) return new Date();
  // Firestore Timestamp? (admin SDK): has toDate()
  if (typeof input === 'object' && input !== null && typeof input.toDate === 'function') {
    try { return input.toDate(); } catch (_) { /* fallthrough */ }
  }
  // ISO/string/number
  const d = new Date(input);
  return isNaN(d.getTime()) ? new Date() : d;
}

/** Safely read a string field; trims and returns '' if missing. */
function str(v) {
  return (typeof v === 'string' ? v : '').trim();
}

/** Convert Firestore document data to response-friendly JSON (date => ISO). */
function serialize(doc) {
  const data = doc.data ? doc.data() : doc; // supports both docSnapshot and plain obj
  const out = { id: doc.id || data.id, ...data };

  // Normalize date fields to ISO strings for the API response
  const d = out.date;
  if (d && typeof d === 'object' && typeof d.toDate === 'function') {
    out.date = d.toDate().toISOString();
  } else if (d instanceof Date) {
    out.date = d.toISOString();
  }

  const ca = out.createdAt;
  if (ca && typeof ca === 'object' && typeof ca.toDate === 'function') {
    out.createdAt = ca.toDate().toISOString();
  } else if (ca instanceof Date) {
    out.createdAt = ca.toISOString();
  }

  const ua = out.updatedAt;
  if (ua && typeof ua === 'object' && typeof ua.toDate === 'function') {
    out.updatedAt = ua.toDate().toISOString();
  } else if (ua instanceof Date) {
    out.updatedAt = ua.toISOString();
  }

  return out;
}

// ----------------------------------------------------------------------------
// Controllers
// ----------------------------------------------------------------------------

exports.createReward = async (req, res) => {
  try {
    const db = req.app.locals.db;
    if (!db) return res.status(500).json({ error: 'Database not initialized' });

    const body = req.body || {};
    const empid = str(body.empid);
    const name = str(body.name);
    const department = str(body.department);
    const description = str(body.description);

    // If you use auth, prefer admin name from token; else body/admin fallback
    const adminname =
      str(req.user?.name) ||
      str(req.user?.email) ||
      str(body.adminname) ||
      'Admin';

    // Basic validation to match your schema
    const missing = [];
    if (!empid) missing.push('empid');
    if (!name) missing.push('name');
    if (!department) missing.push('department');
    if (!description) missing.push('description');
    if (!adminname) missing.push('adminname');
    if (missing.length) {
      return res.status(400).json({ error: `Missing fields: ${missing.join(', ')}` });
    }

    const reward = {
      empid,
      name,
      department,
      description,
      adminname,
      date: normalizeDate(body.date),
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    const docRef = await db.collection('rewards').add(reward);
    const saved = await docRef.get();
    return res.status(201).json(serialize(saved));
  } catch (error) {
    console.error('createReward error:', error);
    return res.status(500).json({ error: error.message || 'Server error' });
  }
};

/**
 * GET /api/rewards
 * - If empid is provided, do a case-tolerant lookup:
 *   1) empid as given
 *   2) empid.toLowerCase() (if different)
 *   3) empid.toUpperCase() (if different)
 *   Results are merged & sorted by date desc in memory (no composite index needed).
 * - If no empid is provided, returns all rewards ordered by date desc (Firestore order).
 */
exports.getAllRewards = async (req, res) => {
  try {
    const db = req.app.locals.db;
    if (!db) return res.status(500).json({ error: 'Database not initialized' });

    const empidParam = str(req.query?.empid);
    const rewards = [];

    if (empidParam) {
      const triedKeys = new Set();

      const variants = [empidParam];
      const lc = empidParam.toLowerCase();
      const uc = empidParam.toUpperCase();
      if (lc !== empidParam) variants.push(lc);
      if (uc !== empidParam && uc !== lc) variants.push(uc);

      for (const value of variants) {
        if (triedKeys.has(value)) continue;
        triedKeys.add(value);

        const snap = await db.collection('rewards').where('empid', '==', value).get();
        for (const doc of snap.docs) {
          rewards.push(serialize(doc));
        }
        // If we already found matches with the exact value, we can break early
        if (rewards.length && value === empidParam) break;
      }

      // Remove any accidental duplicates by id
      const dedup = Object.values(
        rewards.reduce((acc, r) => {
          acc[r.id] = r;
          return acc;
        }, {})
      );

      // Sort newest first without Firestore composite indexes
      dedup.sort((a, b) => new Date(b.date || 0) - new Date(a.date || 0));

      return res.json(dedup);
    }

    // No empid filter — simple order by date desc (this usually does NOT need a composite index)
    const snapshot = await db.collection('rewards').orderBy('date', 'desc').get();
    return res.json(snapshot.docs.map((d) => serialize(d)));
  } catch (error) {
    console.error('getAllRewards error:', error);
    return res.status(500).json({ error: error.message || 'Server error' });
  }
};

exports.getRewardById = async (req, res) => {
  try {
    const db = req.app.locals.db;
    if (!db) return res.status(500).json({ error: 'Database not initialized' });

    const doc = await db.collection('rewards').doc(String(req.params.id)).get();
    if (!doc.exists) return res.status(404).json({ error: 'Not found' });

    return res.json(serialize(doc));
  } catch (error) {
    console.error('getRewardById error:', error);
    return res.status(500).json({ error: error.message || 'Server error' });
  }
};

exports.deleteReward = async (req, res) => {
  try {
    const db = req.app.locals.db;
    if (!db) return res.status(500).json({ error: 'Database not initialized' });

    await db.collection('rewards').doc(String(req.params.id)).delete();
    return res.json({ message: 'Deleted successfully' });
  } catch (error) {
    console.error('deleteReward error:', error);
    return res.status(500).json({ error: error.message || 'Server error' });
  }
};

/**
 * Optional convenience endpoint: return rewards for the logged-in employee.
 * Requires req.user.empid (so enable verifyToken in the route).
 */
exports.getMyRewards = async (req, res) => {
  try {
    const db = req.app.locals.db;
    if (!db) return res.status(500).json({ error: 'Database not initialized' });

    const empid = str(req.user?.empid);
    if (!empid) return res.status(401).json({ error: 'Unauthorized: missing empid' });

    const snapshot = await db
      .collection('rewards')
      .where('empid', '==', empid)
      .get();

    const rewards = snapshot.docs.map((doc) => serialize(doc));
    return res.json(rewards);
  } catch (error) {
    console.error('getMyRewards error:', error);
    return res.status(500).json({ error: error.message || 'Server error' });
  }
};
