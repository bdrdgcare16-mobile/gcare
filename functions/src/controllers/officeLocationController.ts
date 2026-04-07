import { Request, Response } from 'express';
import { db } from '../config/firebase';

type OfficeLocation = {
  branchName: string;
  name: string;
  address: string;
  radius: number;
  latitude: number;
  longitude: number;
  timestamp: Date;
};

// POST /add  (mounted under /api/office)
export const addOrUpdateLocation = async (req: Request, res: Response) => {
  const { branchName, name, address, radius, latitude, longitude } = req.body || {};

  if (
    !branchName ||
    !address ||
    radius == null ||
    latitude == null ||
    longitude == null
  ) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  const newLocation: OfficeLocation = {
    branchName: String(branchName).trim(),
    name: String(name ?? branchName).trim(),
    address: String(address).trim(),
    radius: Number(radius),
    latitude: Number(latitude),
    longitude: Number(longitude),
    timestamp: new Date(),
  };

  try {
    const existing = await db
      .collection('officeLocations')
      .where('address', '==', newLocation.address)
      .limit(1)
      .get();

    if (!existing.empty) {
      return res.status(400).json({
        error: 'Location already exists',
      });
    }

    const docRef = await db.collection('officeLocations').add(newLocation);

    return res.status(201).json({
      message: 'Location added successfully',
      docId: docRef.id,
    });
  } catch (error) {
    console.error('Error adding location:', error);
    return res.status(500).json({ error: 'Failed to add location' });
  }
};

// PUT /update/:docId
export const updateLocation = async (req: Request, res: Response) => {
  const { docId } = req.params;
  const { branchName, name, address, radius, latitude, longitude } = req.body || {};

  if (
    !branchName ||
    !address ||
    radius == null ||
    latitude == null ||
    longitude == null
  ) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  try {
    await db.collection('officeLocations').doc(docId).update({
      branchName: String(branchName).trim(),
      name: String(name ?? branchName).trim(),
      address: String(address).trim(),
      radius: Number(radius),
      latitude: Number(latitude),
      longitude: Number(longitude),
      timestamp: new Date(),
    });

    return res.status(200).json({ message: 'Location updated successfully' });
  } catch (error) {
    console.error('Error updating location:', error);
    return res.status(500).json({ error: 'Failed to update location' });
  }
};

// DELETE /delete/:docId
export const deleteLocation = async (req: Request, res: Response) => {
  const { docId } = req.params;

  try {
    await db.collection('officeLocations').doc(docId).delete();
    return res.status(200).json({ message: 'Location deleted successfully' });
  } catch (error) {
    console.error('Error deleting location:', error);
    return res.status(500).json({ error: 'Failed to delete location' });
  }
};

// GET /locations
export const getAllLocations = async (req: Request, res: Response) => {
  try {
    const limit = Number(req.query.limit) || 50;

    const snapshot = await db
      .collection('officeLocations')
      .orderBy('timestamp', 'desc')
      .limit(limit)
      .get();

    const locations = snapshot.docs.map((doc) => ({
      docId: doc.id,
      ...doc.data(),
    }));

    return res.status(200).json(locations);
  } catch (error) {
    console.error('Error fetching locations:', error);
    return res.status(500).json({ error: 'Failed to fetch locations' });
  }
};