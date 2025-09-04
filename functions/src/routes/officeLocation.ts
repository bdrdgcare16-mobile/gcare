import { Router } from 'express';
import * as officeLocationController from '../controllers/officeLocationController';
import { authMiddleware, roleMiddleware } from '../middlewares/authMiddleware';

const router = Router();

// Apply auth middleware to all routes
router.use(authMiddleware);

/**
 * @swagger
 * components:
 *   schemas:
 *     OfficeLocation:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *         name:
 *           type: string
 *           example: "Main Office"
 *         address:
 *           type: string
 *           example: "123 Business St, City, Country"
 *         latitude:
 *           type: number
 *           format: float
 *           example: 40.7128
 *         longitude:
 *           type: number
 *           format: float
 *           example: -74.0060
 *         radius:
 *           type: number
 *           format: float
 *           example: 100
 *         isActive:
 *           type: boolean
 *           example: true
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 */

/**
 * @swagger
 * /api/office-locations:
 *   post:
 *     summary: Add or update an office location (Admin only)
 *     tags: [Office Locations]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - address
 *               - latitude
 *               - longitude
 *             properties:
 *               id:
 *                 type: string
 *                 description: ID of the office location to update (leave empty for new location)
 *               name:
 *                 type: string
 *                 example: "Main Office"
 *               address:
 *                 type: string
 *                 example: "123 Business St, City, Country"
 *               latitude:
 *                 type: number
 *                 format: float
 *                 example: 40.7128
 *               longitude:
 *                 type: number
 *                 format: float
 *                 example: -74.0060
 *               radius:
 *                 type: number
 *                 format: float
 *                 default: 100
 *                 description: Radius in meters
 *               isActive:
 *                 type: boolean
 *                 default: true
 *     responses:
 *       201:
 *         description: Office location saved successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/OfficeLocation'
 *       400:
 *         description: Invalid input or missing required fields
 *       401:
 *         description: Unauthorized - Admin access required
 *       500:
 *         description: Internal server error
 */
router.post('/', roleMiddleware(['admin']), officeLocationController.addOrUpdateLocation);

/**
 * @swagger
 * /api/office-locations:
 *   get:
 *     summary: Get all office locations
 *     tags: [Office Locations]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: activeOnly
 *         schema:
 *           type: boolean
 *           default: true
 *         description: Whether to return only active office locations
 *     responses:
 *       200:
 *         description: List of office locations
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/OfficeLocation'
 *       500:
 *         description: Internal server error
 */
router.get('/', officeLocationController.getAllLocations);

/**
 * @swagger
 * /api/office-locations/{id}:
 *   get:
 *     summary: Get a specific office location by ID
 *     tags: [Office Locations]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Office location ID
 *     responses:
 *       200:
 *         description: Office location details
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/OfficeLocation'
 *       404:
 *         description: Office location not found
 *       500:
 *         description: Internal server error
 */
router.get('/:id', officeLocationController.getLocationById);

/**
 * @swagger
 * /api/office-locations/{id}:
 *   delete:
 *     summary: Deactivate an office location (Admin only)
 *     description: Performs a soft delete by setting isActive to false
 *     tags: [Office Locations]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Office location ID
 *     responses:
 *       200:
 *         description: Office location deactivated successfully
 *       400:
 *         description: Cannot deactivate office location with associated attendance records
 *       401:
 *         description: Unauthorized - Admin access required
 *       404:
 *         description: Office location not found
 *       500:
 *         description: Internal server error
 */
router.delete('/:id', roleMiddleware(['admin']), officeLocationController.deleteLocation);

/**
 * @swagger
 * /api/office-locations/check:
 *   post:
 *     summary: Check if a location is within any office boundary
 *     tags: [Office Locations]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - latitude
 *               - longitude
 *             properties:
 *               latitude:
 *                 type: number
 *                 format: float
 *                 example: 40.7128
 *               longitude:
 *                 type: number
 *                 format: float
 *                 example: -74.0060
 *     responses:
 *       200:
 *         description: Location check result
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 isWithinOffice:
 *                   type: boolean
 *                   description: Whether the location is within any office boundary
 *                 nearestOffice:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: string
 *                     name:
 *                       type: string
 *                     address:
 *                       type: string
 *                     distance:
 *                       type: number
 *                       description: Distance in meters to the nearest office
 *                     isWithinRadius:
 *                       type: boolean
 *                       description: Whether the location is within the office radius
 *                 userLocation:
 *                   type: object
 *                   properties:
 *                     latitude:
 *                       type: number
 *                     longitude:
 *                       type: number
 *       400:
 *         description: Invalid input
 *       404:
 *         description: No active office locations found
 *       500:
 *         description: Internal server error
 */
router.post('/check', officeLocationController.checkLocation);

export default router;
