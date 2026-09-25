// functions/src/routes/platformAdminRegistrationRoutes.ts

import { Router } from 'express';
import {
  approveRegistration,
  getRegistrationDocumentForReview,
  getRegistrationForReview,
  listRegistrations,
  rejectRegistration,
  requestRegistrationChanges,
} from '../controllers/platformAdminRegistrationController';
import { authMiddleware, roleMiddleware } from '../middlewares/authMiddleware';

/**
 * Platform Admin organization-registration REVIEW routes (Milestone 3D-B/C).
 *
 * 3D-B added read-only list/detail/document endpoints; 3D-C adds the three
 * review decisions (approve / reject / request-changes). Approval is
 * REVIEW-ONLY — no organization, org code, Admin account, or feature
 * enablement is created here.
 *
 * Every route requires a valid SERV JWT with role 'platform_admin' — a
 * distinct browser-portal role. employee, org admin, super_admin and
 * applicant resume-token holders are all rejected; enforcement is
 * server-side, not a frontend route guard.
 */
const router = Router();

router.use(authMiddleware, roleMiddleware(['platform_admin']));

router.get('/', listRegistrations);
router.get('/:id', getRegistrationForReview);
router.get('/:id/documents/:field', getRegistrationDocumentForReview);

router.post('/:id/approve', approveRegistration);
router.post('/:id/reject', rejectRegistration);
router.post('/:id/request-changes', requestRegistrationChanges);

export default router;
