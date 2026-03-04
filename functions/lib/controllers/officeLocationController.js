"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getAllLocations = exports.deleteLocation = exports.addOrUpdateLocation = void 0;
const firebase_1 = require("../config/firebase");
// POST /add  (mounted under /api/office)
const addOrUpdateLocation = async (req, res) => {
    const { address, radius, latitude, longitude } = req.body || {};
    if (!address || radius == null || latitude == null || longitude == null) {
        return res.status(400).json({ error: 'All fields are required' });
    }
    const newLocation = {
        address: String(address),
        radius: Number(radius),
        latitude: Number(latitude),
        longitude: Number(longitude),
        timestamp: new Date(),
    };
    try {
        const docRef = await firebase_1.db.collection('officeLocations').add(newLocation);
        return res
            .status(201)
            .json({ message: 'Location added successfully', docId: docRef.id });
    }
    catch (error) {
        console.error('Error adding location:', error);
        return res.status(500).json({ error: 'Failed to add location' });
    }
};
exports.addOrUpdateLocation = addOrUpdateLocation;
// DELETE /delete/:docId
const deleteLocation = async (req, res) => {
    const { docId } = req.params;
    try {
        await firebase_1.db.collection('officeLocations').doc(docId).delete();
        return res.status(200).json({ message: 'Location deleted successfully' });
    }
    catch (error) {
        console.error('Error deleting location:', error);
        return res.status(500).json({ error: 'Failed to delete location' });
    }
};
exports.deleteLocation = deleteLocation;
// GET /locations
const getAllLocations = async (_req, res) => {
    try {
        const snapshot = await firebase_1.db.collection('officeLocations').get();
        const locations = snapshot.docs.map((doc) => ({
            docId: doc.id,
            ...doc.data(),
        }));
        return res.status(200).json(locations);
    }
    catch (error) {
        console.error('Error fetching locations:', error);
        return res.status(500).json({ error: 'Failed to fetch locations' });
    }
};
exports.getAllLocations = getAllLocations;
//# sourceMappingURL=officeLocationController.js.map