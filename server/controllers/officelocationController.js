const { db } = require('../config/firebase');  // Import Firestore instance

// Add or update office location
exports.addOrUpdateLocation = async (req, res) => {
  const { address, radius, latitude, longitude } = req.body;

  if (!address || !radius || !latitude || !longitude) {
    return res.status(400).json({ error: "All fields are required" });
  }

  const newLocation = {
    address,
    radius,
    latitude,
    longitude,
    timestamp: new Date(),
  };

  try {
    const docRef = await db.collection('officeLocations').add(newLocation);
    res.status(201).json({ message: 'Location added successfully', docId: docRef.id });
  } catch (error) {
    console.error("Error adding location: ", error);
    res.status(500).json({ error: 'Failed to add location' });
  }
};

// Delete office location
exports.deleteLocation = async (req, res) => {
  const { docId } = req.params;

  try {
    await db.collection('officeLocations').doc(docId).delete();
    res.status(200).json({ message: 'Location deleted successfully' });
  } catch (error) {
    console.error("Error deleting location: ", error);
    res.status(500).json({ error: 'Failed to delete location' });
  }
};

// Fetch all office locations
exports.getAllLocations = async (req, res) => {
  try {
    const snapshot = await db.collection('officeLocations').get();
    const locations = snapshot.docs.map(doc => ({
      docId: doc.id,
      ...doc.data(),
    }));

    res.status(200).json(locations);
  } catch (error) {
    console.error("Error fetching locations: ", error);
    res.status(500).json({ error: 'Failed to fetch locations' });
  }
};
