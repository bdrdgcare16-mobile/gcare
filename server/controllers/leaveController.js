
const { db } = require('../config/firebase');
const { v4: uuidv4 } = require('uuid');

const LEAVE_TYPES = ['Casual Leave', 'Planned Leave', 'Sick Leave'];
const SHIFT_TYPES = ['Half-Day', 'Overtime', 'Permission Time', 'Comp Off'];

exports.createLeave = async (req, res) => {
  try {
    const userId = req.user.userId;

    // Server-side visibility for debugging
    console.log('[leaves:create] userId =', userId);
    console.log('[leaves:create] raw body =', req.body);

    // 1) Fetch empid
    const userSnap = await db.collection('users').doc(userId).get();
    if (!userSnap.exists) {
      console.warn('[leaves:create] user not found for userId', userId);
      return res.status(404).json({ error: 'User not found' });
    }
    const { empid } = userSnap.data();

    // 2) Destructure form fields (+ compatibility with UI names)
    let {
      type,
      reason,

      // single-day / shift kinds
      selectDate,
      selectShift,
      startTime,
      endTime,

      // multi-day (canonical)
      startDate,
      endDate,

      // compatibility with UI page
      fromDate,
      toDate,
      leaveCount,
      category,
      leaveType,

      documentUrl,
      imageUrl
    } = req.body;

    // Map alternate names from UI:
    if (!type && leaveType) type = leaveType;
    if (category && typeof category === 'string') {
      if (category.trim().toLowerCase() === 'comp off' ||
          category.trim().toLowerCase() === 'compoff') {
        type = 'Comp Off';
      }
    }
    startDate = startDate || fromDate;
    endDate   = endDate   || toDate;

    // 3) Validate type
    if (!type || ![...LEAVE_TYPES, ...SHIFT_TYPES].includes(type)) {
      console.warn('[leaves:create] invalid type:', type);
      return res.status(400).json({ error: 'Invalid or missing "type"' });
    }

    // 4) Base payload
    const id = uuidv4();
    const payload = {
      id,
      userId,
      empid,
      type,
      reason: (reason || '').toString(),
      status: 'Pending',
      requestedAt: new Date()
    };

    // 5) Type-specific logic
    if (type === 'Overtime' || type === 'Permission Time') {
      if (!selectDate || !startTime || !endTime) {
        return res.status(400).json({ error: 'selectDate, startTime, endTime are required for Overtime/Permission Time' });
      }
      const start = new Date(`${selectDate} ${startTime}`);
      const end   = new Date(`${selectDate} ${endTime}`);
      if (isNaN(start) || isNaN(end) || end <= start) {
        return res.status(400).json({ error: 'Invalid startTime/endTime' });
      }
      payload.selectDate  = new Date(selectDate);
      payload.selectShift = selectShift || null;
      payload.startTime   = startTime;
      payload.endTime     = endTime;
      payload.date        = new Date(selectDate);
      payload.duration    = (end - start) / 3600000; // hours
    }
    else if (type === 'Half-Day') {
      if (!selectDate) {
        return res.status(400).json({ error: 'selectDate is required for Half-Day' });
      }
      payload.selectDate  = new Date(selectDate);
      payload.selectShift = selectShift || null;
      payload.date        = new Date(selectDate);
      payload.session     = (selectShift || '').includes('Morning') ? 'Morning' : 'Afternoon';
      payload.leaveCount  = 0.5;
    }
    else if (LEAVE_TYPES.includes(type) || type === 'Comp Off') {
      if (!startDate || !endDate) {
        return res.status(400).json({ error: 'startDate and endDate are required for multi-day leaves' });
      }
      const s = new Date(startDate);
      const e = new Date(endDate);
      if (isNaN(s) || isNaN(e) || e < s) {
        return res.status(400).json({ error: 'Invalid startDate/endDate' });
      }
      payload.startDate = s;
      payload.endDate   = e;

      if (leaveCount !== undefined && leaveCount !== null && leaveCount !== '') {
        const parsed = Number(leaveCount);
        if (isNaN(parsed) || parsed <= 0) {
          return res.status(400).json({ error: 'leaveCount must be a positive number' });
        }
        payload.leaveCount = parsed;
      } else {
        const days = Math.floor((e - s) / 86400000) + 1;
        payload.leaveCount = days;
      }
    }

    // 6) Optional attachments
    if (documentUrl) payload.documentUrl = documentUrl;
    if (imageUrl)    payload.imageUrl    = imageUrl;

    // 7) Persist
    console.log('[leaves:create] writing to Firestore -> leaves/', id);
    await db.collection('leaves').doc(id).set(payload);
    console.log('[leaves:create] write OK. Returning 201.');
    return res.status(201).json(payload);

  } catch (err) {
    console.error('createLeave error:', err);
    return res.status(500).json({ error: err.message || err.toString() });
  }
};

exports.getMyLeaves = async (req, res) => {
  try {
    const userId = req.user.userId;
    const snaps = await db
      .collection('leaves')
      .where('userId', '==', userId)
      .orderBy('requestedAt', 'desc')
      .get();
    return res.json(snaps.docs.map(d => d.data()));
  } catch (err) {
    console.error('getMyLeaves error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

exports.getAllLeaves = async (req, res) => {
  try {
    const snaps = await db
      .collection('leaves')
      .orderBy('requestedAt', 'desc')
      .get();
    return res.json(snaps.docs.map(d => d.data()));
  } catch (err) {
    console.error('getAllLeaves error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

exports.getPendingLeaves = async (req, res) => {
  try {
    let query = db
      .collection('leaves')
      .where('status', '==', 'Pending');

    if (req.query.type) {
      query = query.where('type', '==', req.query.type);
    }

    const snaps = await query.orderBy('requestedAt', 'desc').get();
    return res.json(snaps.docs.map(d => d.data()));
  } catch (err) {
    console.error('getPendingLeaves error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

exports.getLeaveById = async (req, res) => {
  try {
    const { id } = req.params;
    const doc = await db.collection('leaves').doc(id).get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Leave not found' });
    }
    const leave = doc.data();
    if (req.user.role !== 'admin' && leave.userId !== req.user.userId) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    return res.json(leave);
  } catch (err) {
    console.error('getLeaveById error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

exports.updateLeave = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, adminNotes } = req.body;
    if (!['Pending', 'Approved', 'Rejected'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }
    const updateData = {
      status,
      reviewedAt: new Date(),
      reviewedBy: req.user.userId
    };
    if (adminNotes) updateData.adminNotes = adminNotes;

    await db.collection('leaves').doc(id).update(updateData);
    return res.json({ id, ...updateData });
  } catch (err) {
    console.error('updateLeave error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

exports.deleteLeave = async (req, res) => {
  try {
    const { id } = req.params;
    await db.collection('leaves').doc(id).delete();
    return res.json({ message: 'Request deleted' });
  } catch (err) {
    console.error('deleteLeave error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};
