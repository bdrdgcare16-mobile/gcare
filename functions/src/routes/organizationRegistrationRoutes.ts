// functions/src/routes/organizationRegistrationRoutes.ts

import { Router } from 'express';
import {
  confirmRegistrationVerification,
  createRegistrationDraft,
  getRegistrationDocument,
  getRegistrationDraft,
  getRegistrationStatus,
  listRegistrationDocuments,
  requestRegistrationVerification,
  submitRegistration,
  updateRegistrationDraft,
  uploadRegistrationDocuments,
} from '../controllers/organizationRegistrationController';
import { uploadRegistrationDocs } from '../middlewares/upload.middleware';

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

// Contact verification (OTP) — resume-credential gated.
router.post('/verify/request', requestRegistrationVerification);
router.post('/verify/confirm', confirmRegistrationVerification);

// Organization document upload/retrieval — resume-credential gated.
router.post(
  '/documents',
  uploadRegistrationDocs([
    { name: 'registrationCertificate', maxCount: 1 },
    { name: 'gstCertificate', maxCount: 1 },
    { name: 'authorizationLetter', maxCount: 1 },
    { name: 'adminIdProof', maxCount: 1 },
  ]),
  uploadRegistrationDocuments,
);
router.get('/documents/:id', listRegistrationDocuments);
router.get('/documents/:id/:field', getRegistrationDocument);

export default router;
