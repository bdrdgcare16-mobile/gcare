import { Router } from 'express';
import * as platformController from '../controllers/platformController';
import * as hrReviewController from '../controllers/platformHrReviewController';
import * as registrationController from '../controllers/platformRegistrationController';
import {
  authMiddleware,
  roleMiddleware,
} from '../middlewares/authMiddleware';

const router = Router();

// All platform administration endpoints require an authenticated
// platform_admin (Platform Admin) token.
router.use(authMiddleware, roleMiddleware(['platform_admin']));

// Feature catalog + dependency map (drives the admin UI checkboxes)
router.get('/features', platformController.listFeatureCatalog);

// Tenant management
router.get('/companies', platformController.listCompanies);

// Organization registration applications — the "Organization
// Registrations" review surface. Employee onboarding is a separate
// collection reviewed by Company Admin, not by this API.
router.get('/registrations', registrationController.listRegistrations);
router.get('/registrations/:id', registrationController.getRegistration);
router.get(
  '/registrations/:id/documents/:field',
  registrationController.getRegistrationDocument,
);
router.post(
  '/registrations/:id/approve',
  registrationController.approveRegistration,
);
router.post(
  '/registrations/:id/reject',
  registrationController.rejectRegistration,
);
router.post(
  '/registrations/:id/request-changes',
  registrationController.requestChangesRegistration,
);
router.post('/companies', platformController.createCompany);
router.get('/companies/:companyId', platformController.getCompany);
router.patch('/companies/:companyId', platformController.updateCompany);

// HR feature-request review — Platform Admin only. Approving a request
// grants features to that HR user alone; it never modifies the company's
// enabledFeatures.
router.get('/hr-feature-requests', hrReviewController.listHrFeatureRequests);
router.get(
  '/hr-feature-requests/:requestId',
  hrReviewController.getHrFeatureRequest,
);
router.post(
  '/hr-feature-requests/:requestId/approve',
  hrReviewController.approveHrFeatureRequest,
);
router.post(
  '/hr-feature-requests/:requestId/request-changes',
  hrReviewController.requestChangesHrFeatureRequest,
);
router.post(
  '/hr-feature-requests/:requestId/reject',
  hrReviewController.rejectHrFeatureRequest,
);

export default router;
