const express = require('express');
const router = express.Router();
const staticController = require('../controllers/staticController');

/**
 * @swagger
 * /api/static/terms&conditions:
 *   get:
 *     summary: Get Terms and Conditions
 *     tags: [Static]
 *     responses:
 *       200:
 *         description: Terms and conditions text
 *       404:
 *         description: Terms not found
 */
router.get('/terms&conditions', staticController.getTerms);

/**
 * @swagger
 * /api/static/privacypolicy:
 *   get:
 *     summary: Get Privacy Policy
 *     tags: [Static]
 *     responses:
 *       200:
 *         description: Privacy policy text
 *       404:
 *         description: Privacy policy not found
 */
router.get('/privacypolicy', staticController.getPrivacy);

module.exports = router;
