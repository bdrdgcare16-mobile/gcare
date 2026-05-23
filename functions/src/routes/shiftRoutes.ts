import { Router } from 'express';

import * as shiftController from '../controllers/shiftController';

import { verifyToken, isAdmin, roleMiddleware } from '../middlewares/authMiddleware';


const router = Router();
const isUserOrAdmin = roleMiddleware(['admin', 'employee']);


/**

 * @swagger

 * tags:

 *   - name: Shifts

 *     description: CRUD operations for shift templates

 */



router.post('/', verifyToken, isAdmin, shiftController.createShift);

router.get('/', verifyToken, isUserOrAdmin, shiftController.getAllShifts);

router.get('/:id', verifyToken, isUserOrAdmin, shiftController.getShiftById);

router.put('/:id', verifyToken, isAdmin, shiftController.updateShift);

router.delete('/:id', verifyToken, isAdmin, shiftController.deleteShift);



export default router;