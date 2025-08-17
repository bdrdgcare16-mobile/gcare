// controllers/reportController.js
const admin = require('firebase-admin');
const db    = admin.firestore();
const reportService = require('../services/reportService');
const REPORTS = 'reports';

/**
 * 1) Create a new schedule
 */
exports.createSchedule = async (req, res) => {
  const { name, reportType, templateId, recipient, scheduleTime } = req.body;
  if (!name || !reportType || !templateId || !recipient || !scheduleTime) {
    return res.status(400).json({ message: 'All fields are required.' });
  }

  try {
    const docRef = await db.collection(REPORTS).add({
      name,
      reportType,
      templateId,
      recipient,
      scheduleTime,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    res.status(201).json({ id: docRef.id, message: 'Schedule created.' });
  } catch (err) {
    console.error('createSchedule error:', err);
    res.status(500).json({ message: 'Server error.' });
  }
};

/**
 * 2) List all schedules
 */
exports.listSchedules = async (req, res) => {
  try {
    const snap = await db.collection(REPORTS)
                         .orderBy('createdAt','desc').get();
    const data = snap.docs.map(d => ({
      id: d.id,
      ...d.data(),
      createdAt: d.data().createdAt.toDate().toISOString()
    }));
    res.json(data);
  } catch (err) {
    console.error('listSchedules error:', err);
    res.status(500).json({ message: 'Server error.' });
  }
};

/**
 * 3) Delete a schedule
 */
exports.deleteSchedule = async (req, res) => {
  try {
    const { id } = req.params;
    await db.collection(REPORTS).doc(id).delete();
    res.json({ message: 'Schedule deleted.' });
  } catch (err) {
    console.error('deleteSchedule error:', err);
    res.status(500).json({ message: 'Server error.' });
  }
};
/**
 * 4) Run a schedule immediately (manual trigger)
 */
exports.runNow = async (req, res) => {
  try {
    const { id } = req.params;
    const doc = await db.collection(REPORTS).doc(id).get();
    if (!doc.exists) {
      return res.status(404).json({ message: 'Not found.' });
    }

    // delegate to your service
    await reportService.runReport(doc.data());
    res.json({ message: 'Report run manually.' });

  } catch (err) {
    console.error('runNow error:', err);
    res.status(500).json({ message: 'Server error.' });
  }
};
