import { Request, Response } from 'express';
import * as admin from 'firebase-admin';

const db = admin.firestore();

interface OfficeLocation {
  id?: string;
  address: string;
  name: string;
  radius: number; // in meters
  latitude: number;
  longitude: number;
  isActive: boolean;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
  createdBy: string;
  updatedBy: string;
}

/**
 * Add or update an office location (Admin only)
 */
export const addOrUpdateLocation = async (req: Request, res: Response): Promise<Response> => {
  try {
    const currentUser = (req as any).user;
    const { 
      id, // For updates
      address, 
      name,
      radius = 100, // Default 100 meters
      latitude, 
      longitude,
      isActive = true
    } = req.body;

    // Validate required fields
    if (!address || !name || typeof latitude !== 'number' || typeof longitude !== 'number') {
      return res.status(400).json({ 
        error: 'Address, name, latitude, and longitude are required' 
      });
    }

    const now = admin.firestore.Timestamp.now();
    const locationData: Omit<OfficeLocation, 'id'> = {
      address,
      name,
      radius: Number(radius) || 100,
      latitude: Number(latitude),
      longitude: Number(longitude),
      isActive: isActive !== false, // Default to true if not provided
      createdAt: now,
      updatedAt: now,
      createdBy: currentUser.userId,
      updatedBy: currentUser.userId,
    };

    let locationRef;
    
    if (id) {
      // Update existing location
      locationRef = db.collection('officeLocations').doc(id);
      const doc = await locationRef.get();
      
      if (!doc.exists) {
        return res.status(404).json({ error: 'Office location not found' });
      }
      
      // Preserve createdBy and createdAt for updates
      locationData.createdAt = doc.data()?.createdAt || now;
      locationData.createdBy = doc.data()?.createdBy || currentUser.userId;
      
      await locationRef.update({
        ...locationData,
        updatedAt: now,
        updatedBy: currentUser.userId
      });
    } else {
      // Create new location
      locationRef = await db.collection('officeLocations').add(locationData);
    }

    const location = await locationRef.get();
    
    return res.status(201).json({
      id: location.id,
      ...location.data(),
    });
  } catch (error) {
    console.error('Error saving office location:', error);
    return res.status(500).json({ error: 'Failed to save office location' });
  }
};

/**
 * Get all office locations
 */
export const getAllLocations = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { activeOnly = 'true' } = req.query;
    const showActiveOnly = activeOnly === 'true';

    let query = db.collection('officeLocations');
    
    if (showActiveOnly) {
      query = query.where('isActive', '==', true) as any;
    }

    const snapshot = await query.orderBy('name').get();
    
    const locations = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      // Normalize fields
      radius: Number(doc.data().radius) || 100,
      latitude: Number(doc.data().latitude),
      longitude: Number(doc.data().longitude),
      isActive: doc.data().isActive !== false,
    }));

    return res.status(200).json(locations);
  } catch (error) {
    console.error('Error fetching office locations:', error);
    return res.status(500).json({ error: 'Failed to fetch office locations' });
  }
};

/**
 * Get a specific office location by ID
 */
export const getLocationById = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { id } = req.params;
    
    const doc = await db.collection('officeLocations').doc(id).get();
    
    if (!doc.exists) {
      return res.status(404).json({ error: 'Office location not found' });
    }
    
    const location = {
      id: doc.id,
      ...doc.data(),
      // Normalize fields
      radius: Number(doc.data()?.radius) || 100,
      latitude: Number(doc.data()?.latitude),
      longitude: Number(doc.data()?.longitude),
      isActive: doc.data()?.isActive !== false,
    };
    
    return res.status(200).json(location);
  } catch (error) {
    console.error('Error fetching office location:', error);
    return res.status(500).json({ error: 'Failed to fetch office location' });
  }
};

/**
 * Delete an office location (Admin only)
 */
export const deleteLocation = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { id } = req.params;
    
    // Check if the location exists
    const doc = await db.collection('officeLocations').doc(id).get();
    
    if (!doc.exists) {
      return res.status(404).json({ error: 'Office location not found' });
    }
    
    // Check if the location is being used in any attendance records
    const attendanceQuery = await db
      .collection('attendance')
      .where('officeLocationId', '==', id)
      .limit(1)
      .get();
    
    if (!attendanceQuery.empty) {
      return res.status(400).json({ 
        error: 'Cannot delete office location with associated attendance records' 
      });
    }
    
    // Soft delete by setting isActive to false
    await db.collection('officeLocations').doc(id).update({
      isActive: false,
      updatedAt: admin.firestore.Timestamp.now(),
      updatedBy: (req as any).user.userId
    });
    
    return res.status(200).json({ message: 'Office location deactivated successfully' });
  } catch (error) {
    console.error('Error deleting office location:', error);
    return res.status(500).json({ error: 'Failed to delete office location' });
  }
};

/**
 * Check if a location is within the office boundary
 */
export const checkLocation = async (req: Request, res: Response): Promise<Response> => {
  try {
    const { latitude, longitude } = req.body;
    
    if (typeof latitude !== 'number' || typeof longitude !== 'number') {
      return res.status(400).json({ 
        error: 'Latitude and longitude are required and must be numbers' 
      });
    }
    
    // Get all active office locations
    const snapshot = await db
      .collection('officeLocations')
      .where('isActive', '==', true)
      .get();
    
    if (snapshot.empty) {
      return res.status(404).json({ 
        error: 'No active office locations found',
        isWithinOffice: false
      });
    }
    
    // Check if the point is within any office location's radius
    const userLocation = { latitude, longitude };
    let isWithinOffice = false;
    let nearestOffice = null;
    let minDistance = Infinity;
    
    snapshot.docs.forEach(doc => {
      const office = doc.data();
      const officeLocation = {
        latitude: Number(office.latitude),
        longitude: Number(office.longitude)
      };
      const radius = Number(office.radius) || 100; // Default to 100 meters
      
      // Calculate distance using Haversine formula
      const distance = calculateDistance(userLocation, officeLocation);
      
      if (distance < minDistance) {
        minDistance = distance;
        nearestOffice = {
          id: doc.id,
          name: office.name,
          address: office.address,
          distance: Math.round(distance * 100) / 100, // Round to 2 decimal places
          isWithinRadius: distance <= radius
        };
      }
      
      if (distance <= radius) {
        isWithinOffice = true;
      }
    });
    
    return res.status(200).json({
      isWithinOffice,
      nearestOffice,
      userLocation: {
        latitude: userLocation.latitude,
        longitude: userLocation.longitude
      }
    });
  } catch (error) {
    console.error('Error checking location:', error);
    return res.status(500).json({ 
      error: 'Failed to check location',
      isWithinOffice: false
    });
  }
};

/**
 * Helper function to calculate distance between two points using Haversine formula
 * @returns Distance in meters
 */
function calculateDistance(
  point1: { latitude: number; longitude: number },
  point2: { latitude: number; longitude: number }
): number {
  const R = 6371e3; // Earth's radius in meters
  const φ1 = (point1.latitude * Math.PI) / 180; // Convert to radians
  const φ2 = (point2.latitude * Math.PI) / 180;
  const Δφ = ((point2.latitude - point1.latitude) * Math.PI) / 180;
  const Δλ = ((point2.longitude - point1.longitude) * Math.PI) / 180;

  const a =
    Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
    Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  
  return R * c; // Distance in meters
}
