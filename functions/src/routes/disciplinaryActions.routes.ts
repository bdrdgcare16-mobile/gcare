// functions/src/routes/disciplinaryActions.routes.ts
import { Router } from 'express';
import { authMiddleware, roleMiddleware } from '../middlewares/authMiddleware';
import {
  createDisciplinaryActionController,
  getAdminDisciplinaryActionsController,
  getDisciplinaryActionByIdController,
  updateDisciplinaryActionController,
  resubmitDisciplinaryActionController,
  getSuperAdminDisciplinaryActionsController,
  approveDisciplinaryActionController,
  rejectDisciplinaryActionController,
  getEmployeeDisciplinaryActionsController,
} from '../controllers/disciplinaryActions.controller';

const router = Router();

// Admin
router.post(
  '/',
  authMiddleware,
  roleMiddleware(['admin']),
  createDisciplinaryActionController
);

router.get(
  '/admin',
  authMiddleware,
  roleMiddleware(['admin']),
  getAdminDisciplinaryActionsController
);

router.get(
  '/my',
  authMiddleware,
  roleMiddleware(['employee']),
  getEmployeeDisciplinaryActionsController
);

// Super Admin
router.get(
  '/super-admin',
  authMiddleware,
  roleMiddleware(['super_admin']),
  getSuperAdminDisciplinaryActionsController
);

router.post(
  '/:id/approve',
  authMiddleware,
  roleMiddleware(['super_admin']),
  approveDisciplinaryActionController
);

router.post(
  '/:id/reject',
  authMiddleware,
  roleMiddleware(['super_admin']),
  rejectDisciplinaryActionController
);

// Shared detail
router.get(
  '/:id',
  authMiddleware,
  roleMiddleware(['admin', 'super_admin', 'employee']),
  getDisciplinaryActionByIdController
);

// Admin update/resubmit (must come after the more specific /super-admin and /my routes)
router.put(
  '/:id',
  authMiddleware,
  roleMiddleware(['admin']),
  updateDisciplinaryActionController
);

router.post(
  '/:id/resubmit',
  authMiddleware,
  roleMiddleware(['admin']),
  resubmitDisciplinaryActionController
);

export default router;
