// functions/src/routes/hrRoutes.ts
// HR self-service endpoints — every route requires an authenticated user
// with role 'hr'. HR users can read the company's available features and
// manage their OWN feature request; they cannot review/approve anything.
import { Router } from "express";
import {
  getApprovedFeatures,
  getAvailableFeatures,
  getHrModule,
  getMyFeatureRequest,
  submitFeatureRequest,
} from "../controllers/hrRequestController";
import {
  getCompanyPolicy,
  saveCompanyPolicy,
  publishCompanyPolicy,
} from "../controllers/companyPolicyController";
import {
  authMiddleware as requireAuth,
  roleMiddleware,
} from "../middlewares/authMiddleware";
import { requireHrFeature } from "../middlewares/hrFeatureMiddleware";

const router = Router();
const requireHr = roleMiddleware(["hr"]);

router.get("/features/available", requireAuth, requireHr, getAvailableFeatures);
router.get("/features/approved", requireAuth, requireHr, getApprovedFeatures);

// Feature-gated HR modules — access requires the feature key to be in the
// HR user's approvedFeatures (users/<hrUserId>), NOT just the company's
// enabledFeatures. requireHrFeature enforces role + feature per request.
router.get(
  "/modules/:feature",
  requireAuth,
  requireHrFeature((req) => String(req.params.feature || "")),
  getHrModule,
);
router.get("/feature-request", requireAuth, requireHr, getMyFeatureRequest);
router.post("/feature-request", requireAuth, requireHr, submitFeatureRequest);

// Company policy — HR-owned, versioned draft → publish. companyId and
// user identity come from the JWT only.
router.get("/company-policy", requireAuth, requireHr, getCompanyPolicy);
router.post("/company-policy", requireAuth, requireHr, saveCompanyPolicy);
router.post(
  "/company-policy/publish",
  requireAuth,
  requireHr,
  publishCompanyPolicy,
);

export default router;
