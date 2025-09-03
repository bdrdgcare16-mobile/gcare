
const { db } = require('../config/firebase');
const { v4: uuidv4 } = require('uuid');

const COLL = 'leave_types';

exports.createLeaveType = async (req, res) => {
  try {
    const { userId, role } = req.user || {};
    if (role !== 'admin') return res.status(403).json({ error: 'Admin only' });

    let { type, shift, fromDate, toDate, days } = req.body || {};
    type  = String(type || '').trim();
    shift = String(shift || '').trim();

    if (!type || !shift || !fromDate || !toDate || !days) {
      return res.status(400).json({ error: 'type, shift, fromDate, toDate and days are required' });
    }

    const s = new Date(fromDate);
    const e = new Date(toDate);
    const allowedDays = Number(days);
    if (isNaN(s) || isNaN(e) || e < s) return res.status(400).json({ error: 'Invalid fromDate/toDate' });
    if (!Number.isFinite(allowedDays) || allowedDays <= 0) {
      return res.status(400).json({ error: '"days" must be a positive number' });
    }

    const id = uuidv4();
    const payload = {
      id,
      type,
      shift,
      fromDate: s,
      toDate: e,
      allowedDays,
      active: true,
      createdBy: userId,
      createdAt: new Date(),
    };

    await db.collection(COLL).doc(id).set(payload);
    return res.status(201).json(payload);
  } catch (err) {
    console.error('[leave-types:create] error', err);
    return res.status(500).json({ error: err.message || 'Internal error' });
  }
};

// shift is OPTIONAL; no orderBy (no index needed)
exports.listLeaveTypes = async (req, res) => {
  try {
    const raw = req.query.shift;
    const shift = typeof raw === 'string' ? raw.trim() : '';

    let q = db.collection(COLL).where('active', '==', true);
    if (shift) q = q.where('shift', '==', shift);

    const snaps = await q.get();
    const out = snaps.docs.map(d => d.data());
    return res.json(out);
  } catch (err) {
    console.error('[leave-types:list] error', err);
    return res.status(500).json({ error: 'Internal error' });
  }
};
