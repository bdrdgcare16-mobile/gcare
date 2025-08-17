const express = require('express');
const router = express.Router();
const upload = require('../middlewares/uploadMiddleware');
const fileController = require('../controllers/fileController');

/**
 * @swagger
 * tags:
 *   name: Files
 *   description: File upload, view, and download
 */

/**
 * @swagger
 * /api/files/upload:
 *   post:
 *     summary: Upload a file (image or PDF)
 *     tags: [Files]
 *     consumes:
 *       - multipart/form-data
 *     requestBody:
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required:
 *               - file
 *             properties:
 *               file:
 *                 type: string
 *                 format: binary
 *                 description: File to upload
 *     responses:
 *       200:
 *         description: File uploaded successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 fileName:
 *                   type: string
 *                 originalName:
 *                   type: string
 *                 path:
 *                   type: string
 */
router.post('/upload', upload.single('file'), fileController.uploadFile);

/**
 * @swagger
 * /api/files/view/{name}:
 *   get:
 *     summary: View file inline (image or PDF)
 *     tags: [Files]
 *     parameters:
 *       - in: path
 *         name: name
 *         schema:
 *           type: string
 *         required: true
 *         description: File name to view
 *     responses:
 *       200:
 *         description: Returns the file for viewing
 *       404:
 *         description: File not found
 */
router.get('/view/:name', fileController.viewFile);

/**
 * @swagger
 * /api/files/download/{name}:
 *   get:
 *     summary: Download a file by name
 *     tags: [Files]
 *     parameters:
 *       - in: path
 *         name: name
 *         schema:
 *           type: string
 *         required: true
 *         description: File name to download
 *     responses:
 *       200:
 *         description: Triggers file download
 *       404:
 *         description: File not found
 */
router.get('/download/:name', fileController.downloadFile);

module.exports = router;
