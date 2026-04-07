import { Router } from 'express';
import * as officeLocationController from '../controllers/officeLocationController';

const router = Router();

router.post('/add', officeLocationController.addOrUpdateLocation);
router.put('/update/:docId', officeLocationController.updateLocation);
router.get('/locations', officeLocationController.getAllLocations);
router.delete('/delete/:docId', officeLocationController.deleteLocation);

export default router;