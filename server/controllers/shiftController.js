// const  { db } = require('../config/firebase');
// const { v4: uuidv4 } = require('uuid');

// /**
//  * Create a new shift template
//  */
// exports.createShift = async (req, res) => {
//   console.log('REQ.BODY:', req.body);
//   const { name, startTime, endTime, group } = req.body;

//   // Basic validation
//   if (!name || !startTime || !endTime || !group) {
//     return res
//       .status(400)
//       .json({ error: 'name, startTime, endTime and group are required' });
//   }

//   try {
//     const id = uuidv4();
//     const now = new Date();

//     const payload = {
//       id,
//       name,
//       startTime,
//       endTime,
//       group,
//       createdAt: now,
//       updatedAt: now
//     };

//     await db.collection('shifts').doc(id).set(payload);
//     return res.status(201).json(payload);

//   } catch (err) {
//     console.error('createShift error:', err);
//     return res.status(500).json({ error: 'Internal server error' });
//   }
// };

// /**
//  * List all shift templates
//  */
// exports.getAllShifts = async (req, res) => {
//   console.log('REQ.BODY:', req.body);
//   try {
//     const snap = await db
//       .collection('shifts')
//       .orderBy('createdAt', 'desc')
//       .get();

//     const shifts = snap.docs.map(d => d.data());
//     return res.json(shifts);

//   } catch (err) {
//     console.error('getAllShifts error:', err);
//     return res.status(500).json({ error: 'Internal server error' });
//   }
// };

// /**
//  * Get a single shift by UUID
//  */
// exports.getShiftById = async (req, res) => {
//   console.log('REQ.BODY:', req.body);
//   const { id } = req.params;

//   try {
//     const doc = await db.collection('shifts').doc(id).get();
//     if (!doc.exists) {
//       return res.status(404).json({ error: 'Shift template not found' });
//     }
//     return res.json(doc.data());

//   } catch (err) {
//     console.error('getShiftById error:', err);
//     return res.status(500).json({ error: 'Internal server error' });
//   }
// };

// /**
//  * Update a shift template
//  */
// exports.updateShift = async (req, res) => {
//   console.log('REQ.BODY:', req.body);
//   const { id } = req.params;
//   const updates = { ...req.body, updatedAt: new Date() };

//   try {
//     const ref = db.collection('shifts').doc(id);
//     const doc = await ref.get();
//     if (!doc.exists) {
//       return res.status(404).json({ error: 'Shift template not found' });
//     }

//     await ref.update(updates);
//     return res.json({ id, ...updates });

//   } catch (err) {
//     console.error('updateShift error:', err);
//     return res.status(500).json({ error: 'Internal server error' });
//   }
// };

// /**
//  * Delete a shift template
//  */
// exports.deleteShift = async (req, res) => {
//   console.log('REQ.BODY:', req.body);
//   const { id } = req.params;

//   try {
//     const ref = db.collection('shifts').doc(id);
//     const doc = await ref.get();
//     if (!doc.exists) {
//       return res.status(404).json({ error: 'Shift template not found' });
//     }

//     await ref.delete();
//     return res.json({ message: 'Shift template deleted' });

//   } catch (err) {
//     console.error('deleteShift error:', err);
//     return res.status(500).json({ error: 'Internal server error' });
//   }
// };
// controllers/shiftController.js
// controllers/shiftController.js

const { db } = require('../config/firebase');
const { v4: uuidv4 } = require('uuid');

/**
 * Create a new shift template
 */
exports.createShift = async (req, res) => {
  console.log('👉 createShift REQ.BODY:', req.body);
  const { name, startTime, endTime, shiftname } = req.body;

  // Basic validation
  if (!name || !startTime || !endTime || !shiftname) {
    return res
      .status(400)
      .json({ error: 'name, startTime, endTime and shiftname are required' });
  }

  try {
    const id = uuidv4();
    const now = new Date();

    const payload = {
      id,
      name,
      startTime,
      endTime,
      shiftname,
      createdAt: now,
      updatedAt: now
    };

    await db.collection('shifts').doc(id).set(payload);
    return res.status(201).json(payload);

  } catch (err) {
    console.error('createShift error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

/**
 * List all shift templates
 */
exports.getAllShifts = async (req, res) => {
  console.log('👉 getAllShifts called');
  try {
    const snap = await db
      .collection('shifts')
      .orderBy('createdAt', 'desc')
      .get();

    const shifts = snap.docs.map(d => d.data());
    return res.json(shifts);

  } catch (err) {
    console.error('getAllShifts error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

/**
 * Get a single shift by UUID
 */
exports.getShiftById = async (req, res) => {
  console.log('👉 getShiftById REQ.PARAMS:', req.params);
  const { id } = req.params;

  try {
    const doc = await db.collection('shifts').doc(id).get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Shift template not found' });
    }
    return res.json(doc.data());

  } catch (err) {
    console.error('getShiftById error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

/**
 * Update a shift template
 */
exports.updateShift = async (req, res) => {
  console.log('👉 updateShift REQ.PARAMS & BODY:', req.params, req.body);
  const { id } = req.params;
  const updates = { ...req.body, updatedAt: new Date() };

  try {
    const ref = db.collection('shifts').doc(id);
    const doc = await ref.get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Shift template not found' });
    }

    await ref.update(updates);
    return res.json({ id, ...updates });

  } catch (err) {
    console.error('updateShift error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

/**
 * Delete a shift template
 */
exports.deleteShift = async (req, res) => {
  console.log('👉 deleteShift REQ.PARAMS:', req.params);
  const { id } = req.params;

  try {
    const ref = db.collection('shifts').doc(id);
    const doc = await ref.get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Shift template not found' });
    }

    await ref.delete();
    return res.json({ message: 'Shift template deleted' });

  } catch (err) {
    console.error('deleteShift error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};
