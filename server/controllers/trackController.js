const admin = require('firebase-admin');
const db = admin.firestore();
const path = require('path');

exports.trackLocation = async (req, res) => {
  try {
    const { empId, name, latitude, longitude, address } = req.body;

    if (!empId || !name || !latitude || !longitude || !address) {
      return res.status(400).json({ error: 'All fields are required' });
    }

    const fileUrl = req.file ? `uploads/track/${req.file.filename}` : null;

    const newTrack = {
      empId,
      name,
      latitude: parseFloat(latitude),
      longitude: parseFloat(longitude),
      address,
      timestamp: new Date().toISOString(),
      fileUrl
    };

    await db.collection('track').add(newTrack);
    res.status(200).json({ message: 'Location tracked successfully', data: newTrack });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getAllTracks = async (req, res) => {
  try {
    const snapshot = await db.collection('track').get();
    const tracks = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.status(200).json(tracks);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
