import { Request, Response } from 'express';
import { db } from '../config/firebase';
import { trackUsage } from '../services/usageService';

type OfficeLocation = {
  companyId: string;
  branchName: string;
  name: string;
  address: string;
  radius: number;
  latitude: number;
  longitude: number;
  timestamp: Date;
};

function getReqCompanyId(req: Request): string | null {
  return String((req as any).user?.companyId || '').trim() || null;
}

/* ============================== Usage Tracking Helper ============================== */

async function trackOfficeLocationUsage(
  req: Request,
  updates: Record<string, number>
) {
  try {
    const user = (req as any).user;
    await trackUsage({
      companyId: user?.companyId || '',
      companyName: user?.companyName || '',
      plan: user?.plan || '',
      updates,
    });
  } catch (trackingError) {
    console.error('Usage tracking failed in officeLocation:', trackingError);
  }
}

// POST /add  (mounted under /api/office)
export const addOrUpdateLocation = async (req: Request, res: Response) => {
  const companyId = getReqCompanyId(req);
  if (!companyId) {
    return res.status(403).json({ error: 'companyId missing in token' });
  }

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
    companyId,
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
      .where('companyId', '==', companyId)
      .where('address', '==', newLocation.address)
      .limit(1)
      .get();

    if (!existing.empty) {
      return res.status(400).json({
        error: 'Location already exists for this company',
      });
    }

    const docRef = await db.collection('officeLocations').add(newLocation);

    // Track usage after successful location creation
    await trackOfficeLocationUsage(req, {
      writeCount: 1,
      apiCalls: 1,
    });

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
  const companyId = getReqCompanyId(req);
  if (!companyId) {
    return res.status(403).json({ error: 'companyId missing in token' });
  }

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
    const ref = db.collection('officeLocations').doc(docId);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Location not found' });
    }

    const data = doc.data() as Record<string, any> | undefined;
    if (!data || data.companyId !== companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    await ref.update({
      branchName: String(branchName).trim(),
      name: String(name ?? branchName).trim(),
      address: String(address).trim(),
      radius: Number(radius),
      latitude: Number(latitude),
      longitude: Number(longitude),
      timestamp: new Date(),
    });

    // Track usage after successful location update
    await trackOfficeLocationUsage(req, {
      writeCount: 1,
      apiCalls: 1,
    });

    return res.status(200).json({ message: 'Location updated successfully' });
  } catch (error) {
    console.error('Error updating location:', error);
    return res.status(500).json({ error: 'Failed to update location' });
  }
};

// DELETE /delete/:docId
export const deleteLocation = async (req: Request, res: Response) => {
  const companyId = getReqCompanyId(req);
  if (!companyId) {
    return res.status(403).json({ error: 'companyId missing in token' });
  }

  const { docId } = req.params;

  try {
    const ref = db.collection('officeLocations').doc(docId);
    const doc = await ref.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Location not found' });
    }

    const data = doc.data() as Record<string, any> | undefined;
    if (!data || data.companyId !== companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    await ref.delete();

    // Track usage after successful location deletion
    await trackOfficeLocationUsage(req, {
      deleteCount: 1,
      apiCalls: 1,
    });

    return res.status(200).json({ message: 'Location deleted successfully' });
  } catch (error) {
    console.error('Error deleting location:', error);
    return res.status(500).json({ error: 'Failed to delete location' });
  }
};

// GET /locations
export const getAllLocations = async (req: Request, res: Response) => {
  const companyId = getReqCompanyId(req);
  console.log('[office:getAll] token companyId =', companyId);
  console.log('[office:getAll] req.user =', (req as any).user);

  if (!companyId) {
    return res.status(403).json({ error: 'companyId missing in token' });
  }

  try {
    const limit = Number(req.query.limit) || 50;

    const snapshot = await db
      .collection('officeLocations')
      .where('companyId', '==', companyId)
      .orderBy('timestamp', 'desc')
      .limit(limit)
      .get();

    console.log('[office:getAll] result count =', snapshot.size);
    console.log(
      '[office:getAll] companyIds =',
      snapshot.docs.map((doc) => doc.data().companyId)
    );

    const locations = snapshot.docs.map((doc) => ({
      docId: doc.id,
      ...doc.data(),
    }));

        // Track usage after successful locations read
    await trackOfficeLocationUsage(req, {
      readCount: 1,
      apiCalls: 1,
    });

    return res.status(200).json(locations);
  } catch (error) {
    console.error('Error fetching locations:', error);
    return res.status(500).json({ error: 'Failed to fetch locations' });
  }
};