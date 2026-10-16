import { Router } from 'express';

import * as shiftController from '../controllers/shiftController';

import { verifyToken, roleMiddleware } from '../middlewares/authMiddleware';
import { requireFeature } from '../middlewares/featureMiddleware';
import { hrFeatureGate } from '../middlewares/hrFeatureMiddleware';


const router = Router();
const shiftsEnabled = requireFeature('attendance');


/**

 * @swagger

 * tags:

 *   - name: Shifts

 *     description: CRUD operations for shift templates

 */



// HR reads shifts for the attendance/employees/onboarding modules —
// allowed when any of those features is approved for the HR user.
const hrShiftRead = hrFeatureGate(['attendance', 'employees', 'onboarding']);
const isAdminOrHr = roleMiddleware(['admin', 'hr']);
// Shift writes are module operations: admin, or HR with 'attendance'
// in approvedFeatures (hrFeatureGate is a no-op for admin). The
// controller scopes every read/write to the token's companyId.
const hrShiftWrite = hrFeatureGate(['attendance']);

router.post('/', verifyToken, shiftsEnabled, isAdminOrHr, hrShiftWrite, shiftController.createShift);

router.get('/', verifyToken, shiftsEnabled, roleMiddleware(['admin', 'employee', 'hr']), hrShiftRead, shiftController.getAllShifts);

// Employee self-service: the caller's own assigned shift for attendance.
// Must be registered before /:id so 'assigned' is not treated as a doc id.
router.get('/assigned', verifyToken, shiftsEnabled, roleMiddleware(['admin', 'employee', 'hr']), hrShiftRead, shiftController.getAssignedShift);

router.get('/:id', verifyToken, shiftsEnabled, roleMiddleware(['admin', 'employee', 'hr']), hrShiftRead, shiftController.getShiftById);

router.put('/:id', verifyToken, shiftsEnabled, isAdminOrHr, hrShiftWrite, shiftController.updateShift);

router.delete('/:id', verifyToken, shiftsEnabled, isAdminOrHr, hrShiftWrite, shiftController.deleteShift);



export default router;