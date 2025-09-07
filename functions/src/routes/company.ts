import { Router } from 'express';
import * as companyController from '../controllers/companyController';
import { authMiddleware } from '../middlewares/authMiddleware';
import multer, { FileFilterCallback } from 'multer';
import { Request } from 'express';

const router = Router();

// Test endpoint with token verification
router.get('/profile/check', authMiddleware, (req, res, next) => {
  // User is already set in req.user by authMiddleware
  // You can access user details via req.user
  res.status(200).json({ 
    test: "test123",
    user: req.user // Optional: include user info in the response for testing
  });
});

// Configure multer for file uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter: (req: Request, file: Express.Multer.File, cb: FileFilterCallback) => {
    // Accept images only
    if (!file.originalname.match(/\.(jpg|jpeg|png|gif)$/i)) {
      return cb(new Error('Only image files are allowed!'));
    }
    cb(null, true);
  },
});

/**
 * @swagger
 * /api/company/profile:
 *   post:
 *     summary: Save or update company profile
 *     tags: [Company]
 *     consumes:
 *       - multipart/form-data
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               logo:
 *                 type: string
 *                 format: binary
 *               companyName:
 *                 type: string
 *               email:
 *                 type: string
 *               phone:
 *                 type: string
 *               website:
 *                 type: string
 *               adminName:
 *                 type: string
 *               designation:
 *                 type: string
 *     responses:
 *       200:
 *         description: Company profile saved successfully
 *       400:
 *         description: Missing required fields
 *       500:
 *         description: Internal server error
 */
router.post(
  '/profile',
  authMiddleware,
  upload.single('logo'),
  companyController.saveCompanyProfile
);

/**
 * @swagger
 * /api/company/profile:
 *   get:
 *     summary: Get company profile
 *     tags: [Company]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Company profile retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Company'
 *       404:
 *         description: Company profile not found
 *       500:
 *         description: Internal server error
 */
router.get(
  '/profile',
  authMiddleware,
  companyController.getCompanyProfile
);

export default router;
