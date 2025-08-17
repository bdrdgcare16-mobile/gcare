const express = require('express');
const router = express.Router();
const officelocationController = require('../controllers/officelocationController');

/**
 * @swagger
 * tags:
 *   name: Office Locations
 *   description: Manage office locations where employees will check in and check out
 */

/**
 * @swagger
 * /api/office/add:
 *   post:
 *     summary: Add or update an office location
 *     tags: [Office Locations]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               address:
 *                 type: string
 *                 description: The address of the office
 *               radius:
 *                 type: number
 *                 format: float
 *                 description: The radius in meters
 *               latitude:
 *                 type: number
 *                 format: float
 *                 description: Latitude of the office location
 *               longitude:
 *                 type: number
 *                 format: float
 *                 description: Longitude of the office location
 *     responses:
 *       201:
 *         description: Office location added/updated successfully
 *       400:
 *         description: Bad request, missing or invalid data
 *       500:
 *         description: Internal server error
 */
router.post('/add', officelocationController.addOrUpdateLocation);

/**
 * @swagger
 * /api/office/locations:
 *   get:
 *     summary: Get all office locations
 *     tags: [Office Locations]
 *     responses:
 *       200:
 *         description: List of all office locations
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   docId:
 *                     type: string
 *                     description: Document ID in Firestore
 *                   address:
 *                     type: string
 *                   radius:
 *                     type: number
 *                   latitude:
 *                     type: number
 *                   longitude:
 *                     type: number
 *                   timestamp:
 *                     type: string
 *                     format: date-time
 *       500:
 *         description: Internal server error
 */
router.get('/locations', officelocationController.getAllLocations);

/**
 * @swagger
 * /api/office/delete/{docId}:
 *   delete:
 *     summary: Delete an office location
 *     tags: [Office Locations]
 *     parameters:
 *       - name: docId
 *         in: path
 *         required: true
 *         description: The document ID of the office location to delete
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Office location deleted successfully
 *       404:
 *         description: Office location not found
 *       500:
 *         description: Internal server error
 */
router.delete('/delete/:docId', officelocationController.deleteLocation);

module.exports = router;
