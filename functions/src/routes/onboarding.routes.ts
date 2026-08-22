
import { Router } from "express";
import {
  changeOnboardingStatus,
  createEmployeeOnboarding,
  getEmployeeOnboardingById,
  getEmployeeOnboardings,
  resolveOnboardingDocumentUrl,
} from "../controllers/onboarding.controller";
import { type Request, type Response } from "express";
import { authMiddleware, roleMiddleware } from "../middlewares/authMiddleware";
import { uploadOnboarding } from "../middlewares/upload.middleware";

const router = Router();

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

router.get(
  "/",
  authMiddleware,
  roleMiddleware(['super_admin']),
  getEmployeeOnboardings,
);

// Resolves a stored Firebase Storage object path to a short-lived signed
// URL so onboarding documents (offer letters, ID proofs, etc.) can be
// viewed even though they are stored as private object paths, not URLs.
router.get(
  "/documents/resolve-url",
  authMiddleware,
  roleMiddleware(['super_admin']),
  resolveOnboardingDocumentUrl,
);

router.get(
  "/:id",
  authMiddleware,
  roleMiddleware(['super_admin']),
  getEmployeeOnboardingById,
);

router.patch(
  "/:id/status",
  authMiddleware,
  roleMiddleware(['super_admin']),
  changeOnboardingStatus,
);

export default router;