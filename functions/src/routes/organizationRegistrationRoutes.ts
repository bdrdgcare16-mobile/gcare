// functions/src/routes/organizationRegistrationRoutes.ts

import { Router } from 'express';
import {
  confirmRegistrationVerification,
  createRegistrationDraft,
  getMyRegistration,
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
import {
  authMiddleware,
  optionalAuthMiddleware,
  roleMiddleware,
} from '../middlewares/authMiddleware';

/**
 * Organization-registration routes.
 *
 * 3D-C follow-up: applications are bound to an authenticated
 * org_applicant account. optionalAuthMiddleware attaches req.user when a
 * valid SERV JWT is presented (never rejects); each handler then accepts
 * EITHER the bound applicant's JWT OR the device-local resume token
 * (x-registration-resume-token). A JWT bound to a DIFFERENT applicant is
 * rejected with 403 inside the credential check. Mounted behind
 * authRateLimit in app.ts.
 *
 * Review endpoints live in platformAdminRegistrationRoutes (mounted at
 * /platform-admin/registrations) behind authMiddleware +
 * roleMiddleware(['platform_admin']).
 */
const router = Router();

// Attach req.user when a valid JWT is present — harmless for token-only
// callers, required for authenticated applicant identity binding.
router.use(optionalAuthMiddleware);

// Server-side resolution of the caller's current application — the
// source of truth for post-login routing.
router.get(
  '/mine',
  authMiddleware,
  roleMiddleware(['org_applicant']),
  getMyRegistration,
);

router.post('/draft', createRegistrationDraft);
router.get('/draft/:id', getRegistrationDraft);
router.patch('/draft/:id', updateRegistrationDraft);
router.get('/status/:id', getRegistrationStatus);
router.post('/submit', submitRegistration);

// Contact verification (OTP) — applicant credential gated.
router.post('/verify/request', requestRegistrationVerification);
router.post('/verify/confirm', confirmRegistrationVerification);

// Organization document upload/retrieval — applicant credential gated.
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
