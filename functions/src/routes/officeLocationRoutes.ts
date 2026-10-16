import { Router } from 'express';
import * as officeLocationController from '../controllers/officeLocationController';
import { verifyToken, roleMiddleware } from '../middlewares/authMiddleware';
import { requireFeature } from '../middlewares/featureMiddleware';
import { hrFeatureGate } from '../middlewares/hrFeatureMiddleware';

const router = Router();

const officeEnabled = requireFeature('attendance');
// Office locations are tenant config — only admin or HR with the
// 'attendance' feature approved may read/manage them. Previously any
// authenticated caller (including employees) could mutate locations.
const isAdminOrHr = roleMiddleware(['admin', 'hr']);
const hrAttendance = hrFeatureGate(['attendance']);

// Employee self-service: read-only access to their own assigned office geo
// config for the check-in flow. Mutations stay admin/HR-only. Any tenant
// role may call it — it returns only the caller's own assigned office
// (admin/HR already have full reads via /locations anyway).
router.get(
  '/assigned',
  verifyToken,
  officeEnabled,
  roleMiddleware(['employee', 'hr', 'admin']),
  officeLocationController.getAssignedLocation,
);

router.post('/add', verifyToken, officeEnabled, isAdminOrHr, hrAttendance, officeLocationController.addOrUpdateLocation);
router.put('/update/:docId', verifyToken, officeEnabled, isAdminOrHr, hrAttendance, officeLocationController.updateLocation);
router.get('/locations', verifyToken, officeEnabled, isAdminOrHr, hrAttendance, officeLocationController.getAllLocations);
router.delete('/delete/:docId', verifyToken, officeEnabled, isAdminOrHr, hrAttendance, officeLocationController.deleteLocation);

export default router;