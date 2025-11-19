"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.default = eventRoutes;
const express_1 = require("express");
const eventController_1 = require("../controllers/eventController");
/**
 * @openapi
 * tags:
 *   - name: Events
 *     description: Manage events (admin & user)
 *
 * components:
 *   schemas:
 *     EventIn:
 *       type: object
 *       required: [title, description, location, fromDate, toDate]
 *       properties:
 *         title:       { type: string, example: AI Conference }
 *         description: { type: string, example: AI in healthcare }
 *         location:    { type: string, example: Chennai }
 *         fromDate:    { type: string, format: date, example: 2025-08-13 }
 *         toDate:      { type: string, format: date, example: 2025-08-15 }
 *         image:       { type: string, format: binary, description: Optional image }
 *         file:        { type: string, format: binary, description: Optional related file }
 *     EventOut:
 *       allOf:
 *         - $ref: '#/components/schemas/EventIn'
 *         - type: object
 *           properties:
 *             id:        { type: string, example: tR8NvqbV3tpxBDQbqgmb }
 *             imageUrl:  { type: string, nullable: true }
 *             fileUrl:   { type: string, nullable: true }
 *             createdAt: { type: string, format: date-time }
 */
function eventRoutes(db) {
    const router = (0, express_1.Router)();
    // Make Firestore available on req.app.locals.db
    router.use((req, _res, next) => {
        req.app.locals.db = db;
        next();
    });
    /**
     * @openapi
     * /api/events:
     *   post:
     *     summary: Create a new event (multipart/form-data)
     *     tags: [Events]
     *     requestBody:
     *       required: true
     *       content:
     *         multipart/form-data:
     *           schema: { $ref: '#/components/schemas/EventIn' }
     *     responses:
     *       201:
     *         description: Created
     *         content:
     *           application/json:
     *             schema: { $ref: '#/components/schemas/EventOut' }
     *       400: { description: Missing fields }
     *       500: { description: Server error }
     */
    router.post('/', eventController_1.createEvent);
    /**
     * @openapi
     * /api/events:
     *   get:
     *     summary: Get all events
     *     tags: [Events]
     *     responses:
     *       200:
     *         description: OK
     *         content:
     *           application/json:
     *             schema:
     *               type: array
     *               items: { $ref: '#/components/schemas/EventOut' }
     *       500: { description: Server error }
     */
    router.get('/', eventController_1.getAllEvents);
    /**
     * @openapi
     * /api/events/{id}:
     *   delete:
     *     summary: Delete an event
     *     tags: [Events]
     *     parameters:
     *       - in: path
     *         name: id
     *         required: true
     *         schema: { type: string }
     *     responses:
     *       200: { description: Deleted }
     *       500: { description: Server error }
     */
    router.delete('/:id', eventController_1.deleteEvent);
    return router;
}
//# sourceMappingURL=event.js.map