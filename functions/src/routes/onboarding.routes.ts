
import { Router } from "express";
import {
  changeOnboardingStatus,
  createEmployeeOnboarding,
  getEmployeeOnboardingById,
  getEmployeeOnboardings,
  getOnboardingByEmployeeId,
  resolveOnboardingDocumentUrl,
  serveDevOnboardingFile,
} from "../controllers/onboarding.controller";
import { type Request, type Response } from "express";
import { authMiddleware, roleMiddleware } from "../middlewares/authMiddleware";
import { requireFeature } from "../middlewares/featureMiddleware";
import { hrFeatureGate } from "../middlewares/hrFeatureMiddleware";
import { uploadOnboarding } from "../middlewares/upload.middleware";

const router = Router();

const onboardingEnabled = requireFeature('onboarding');

const onboardingUpload = uploadOnboarding([
  { name: "resume", maxCount: 1 },
  { name: "offerLetter", maxCount: 1 },
  { name: "aadhaarCard", maxCount: 1 },
  { name: "panCard", maxCount: 1 },
  { name: "bankProof", maxCount: 1 },
  { name: "degreeCertificate", maxCount: 1 },
  { name: "passportPhoto", maxCount: 1 },
  { name: "experienceCertificate", maxCount: 1 },
  { name: "relievingLetter", maxCount: 1 },
]);

router.post(
  "/",
  authMiddleware,
  onboardingEnabled,
  // Submission is an admin/HR action — employees and company_admin must
  // never create onboarding requests.
  roleMiddleware(['admin', 'hr']),
  // HR creates onboardings only when 'onboarding' is in approvedFeatures;
  // other roles keep the existing behaviour (no role restriction today).
  hrFeatureGate(['onboarding']),
  (req, res, next) => {
    console.log('[onboarding-upload] start', {
      contentType: req.headers['content-type'],
      contentLength: req.headers['content-length'],
      hasRawBody: Boolean((req as any).rawBody),
      rawBodyLength: (req as any).rawBody?.length ?? 0,
    });
    console.log('[onboarding-upload] multer start');

    const uploadWithCallback = onboardingUpload as unknown as (
      request: Request,
      response: Response,
      callback: (err?: unknown) => void,
    ) => void;

    uploadWithCallback(req, res, (err?: unknown) => {
      if (err) {
        const uploadError = err instanceof Error
          ? err
          : new Error(String(err));
        console.error('[onboarding-upload] multer error', {
          name: uploadError.name,
          message: uploadError.message,
          code: (uploadError as any).code,
        });
        // Upload failures are client-correctable: map them to 4xx instead
        // of letting the global handler emit a generic 500.
        if (!(uploadError as any).statusCode) {
          (uploadError as any).statusCode =
            (uploadError as any).code === 'LIMIT_FILE_SIZE' ? 413 : 400;
        }
        return next(uploadError);
      }

      console.log('[onboarding-upload] multer complete', {
        bodyFieldCount: Object.keys(req.body ?? {}).length,
        fileFieldCount: Object.keys(req.files ?? {}).length,
      });
      next();
    });
  },
  createEmployeeOnboarding
);

// V2: onboarding review moved from Platform/Super Admin to the Company
// Admin of the owning company. Controllers enforce companyId scoping.
router.get(
  "/",
  authMiddleware,
  onboardingEnabled,
  roleMiddleware(['company_admin']),
  getEmployeeOnboardings,
);

// Resolves a stored Firebase Storage object path to a short-lived signed
// URL so onboarding documents (offer letters, ID proofs, etc.) can be
// viewed even though they are stored as private object paths, not URLs.
router.get(
  "/documents/resolve-url",
  authMiddleware,
  onboardingEnabled,
  roleMiddleware(['company_admin']),
  resolveOnboardingDocumentUrl,
);

// DEV only: serves emulator-local onboarding documents via an HMAC-signed
// URL minted by the service (no Storage emulator/prod bucket access in DEV).
// Never registered outside the Functions emulator.
if (process.env.FUNCTIONS_EMULATOR === 'true') {
  router.get("/documents/dev-file", serveDevOnboardingFile);
}

router.get(
  "/by-empid/:empid",
  authMiddleware,
  onboardingEnabled,
  getOnboardingByEmployeeId,
);

router.get(
  "/:id",
  authMiddleware,
  onboardingEnabled,
  roleMiddleware(['company_admin']),
  getEmployeeOnboardingById,
);

router.patch(
  "/:id/status",
  authMiddleware,
  onboardingEnabled,
  roleMiddleware(['company_admin']),
  changeOnboardingStatus,
);

export default router;