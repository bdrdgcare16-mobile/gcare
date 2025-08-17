const express = require('express');
const router = express.Router();

const companyController = require('../controllers/companyController');
const { verifyToken } = require('../middlewares/authMiddleware');
const upload = require('../middlewares/uploadMiddleware'); // ✅ Multer middleware

// 🔸 POST: Create or update company profile
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
 *       500:
 *         description: Internal server error
 */
router.post(
  '/profile',
  verifyToken,
  upload.single('logo'),
  companyController.saveOrUpdateCompanyProfile
);

// 🔸 GET: Fetch saved company profile
/**
 * @swagger
 * /api/company/profile:
 *   get:
 *     summary: Get saved company profile
 *     tags: [Company]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Company profile fetched successfully
 *       404:
 *         description: Company profile not found
 *       500:
 *         description: Internal server error
 */
router.get(
  '/profile',
  verifyToken,
  companyController.getCompanyProfile
);

// 🔸 GET: Check if form already submitted
/**
 * @swagger
 * /api/company/profile/check:
 *   get:
 *     summary: Check if company profile has been filled
 *     tags: [Company]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Form status returned
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 filled:
 *                   type: boolean
 *       500:
 *         description: Internal server error
 */
router.get(
  '/profile/check',
  verifyToken,
  companyController.isCompanyProfileFilled
);

module.exports = router;
