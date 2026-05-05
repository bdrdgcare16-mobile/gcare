import { Router } from 'express';
import * as officeLocationController from '../controllers/officeLocationController';
import { verifyToken } from '../middlewares/authMiddleware';

const router = Router();

router.post('/add', verifyToken, officeLocationController.addOrUpdateLocation);
router.put('/update/:docId', verifyToken, officeLocationController.updateLocation);
router.get('/locations', verifyToken, officeLocationController.getAllLocations);
router.delete('/delete/:docId', verifyToken, officeLocationController.deleteLocation);

export default router;