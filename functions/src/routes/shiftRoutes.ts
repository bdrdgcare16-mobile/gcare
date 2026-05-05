import { Router } from 'express';

import * as shiftController from '../controllers/shiftController';

import { verifyToken, isAdmin} from '../middlewares/authMiddleware';



const router = Router();



/**

 * @swagger

 * tags:

 *   - name: Shifts

 *     description: CRUD operations for shift templates

 */



router.post('/', verifyToken, isAdmin, shiftController.createShift);

router.get('/', verifyToken, isAdmin, shiftController.getAllShifts);

router.get('/:id', verifyToken, isAdmin, shiftController.getShiftById);

router.put('/:id', verifyToken, isAdmin, shiftController.updateShift);

router.delete('/:id', verifyToken, isAdmin, shiftController.deleteShift);



export default router;