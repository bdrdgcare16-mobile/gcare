// functions/src/routes/organizationRegistrationRoutes.ts

import { Router } from 'express';
import {
  createRegistrationDraft,
  getRegistrationDraft,
  getRegistrationStatus,
  submitRegistration,
  updateRegistrationDraft,
} from '../controllers/organizationRegistrationController';

/**
 * Public organization-registration draft routes.
 *
 * These endpoints are intentionally UNAUTHENTICATED — the applicant has no
 * SERV account yet. Access is controlled by the 256-bit resume credential
 * (`x-registration-resume-token` header) issued at draft creation. Mounted
 * behind authRateLimit in app.ts.
 *
 * Review/admin endpoints arrive in Milestone 3D behind authMiddleware +
 * roleMiddleware(['super_admin']).
 */
const router = Router();

router.post('/draft', createRegistrationDraft);
router.get('/draft/:id', getRegistrationDraft);
router.patch('/draft/:id', updateRegistrationDraft);
router.get('/status/:id', getRegistrationStatus);
router.post('/submit', submitRegistration);

export default router;
