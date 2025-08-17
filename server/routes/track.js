const express = require('express');
const router = express.Router();
const trackController = require('../controllers/trackController');
const multer = require('multer');

// Multer setup
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/track/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '_' + file.originalname;
    cb(null, uniqueSuffix);
  }
});
const upload = multer({ storage });

/**
 * @swagger
 * /api/track:
 *   post:
 *     summary: Submit location tracking data
 *     consumes:
 *       - multipart/form-data
 *     parameters:
 *       - name: empId
 *         in: formData
 *         required: true
 *         type: string
 *       - name: name
 *         in: formData
 *         required: true
 *         type: string
 *       - name: latitude
 *         in: formData
 *         required: true
 *         type: number
 *       - name: longitude
 *         in: formData
 *         required: true
 *         type: number
 *       - name: address
 *         in: formData
 *         required: true
 *         type: string
 *       - name: file
 *         in: formData
 *         required: false
 *         type: file
 *     responses:
 *       200:
 *         description: Location tracked successfully
 */
router.post('/', upload.single('file'), trackController.trackLocation);

/**
 * @swagger
 * /api/track:
 *   get:
 *     summary: Get all tracked locations
 *     responses:
 *       200:
 *         description: List of all track data
 */
router.get('/', trackController.getAllTracks);

module.exports = router;
