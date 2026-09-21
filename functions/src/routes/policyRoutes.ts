import { Router } from 'express';
import * as policyController from '../controllers/policyController';
import { authMiddleware, roleMiddleware } from '../middlewares/authMiddleware';

const router = Router();

// All policy routes require a valid SERV JWT and the employee role.
router.use(authMiddleware, roleMiddleware(['employee']));

/**
 * GET /api/organization/policies
 * List all active policies for the authenticated employee's organization.
 */
router.get('/policies', policyController.listOrganizationPolicies);

/**
 * GET /api/organization/policies/acceptance-status
 * Returns whether all required active policies have been accepted.
 */
router.get(
  '/policies/acceptance-status',
  policyController.getPolicyAcceptanceStatus
);

/**
 * POST /api/organization/policies/accept
 * Record acceptance of an exact policy version.
 */
router.post('/policies/accept', policyController.acceptPolicyVersion);

export default router;
