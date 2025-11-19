"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.default = feedbackRoutes;
const express_1 = require("express");
const feedbackController_1 = require("../controllers/feedbackController");
/**
 * @openapi
 * tags:
 *   - name: Feedback
 *     description: User feedback management
 */
/**
 * @openapi
 * components:
 *   schemas:
 *     FeedbackOut:
 *       type: object
 *       properties:
 *         id:        { type: string }
 *         empid:     { type: string }
 *         name:      { type: string }
 *         message:   { type: string }
 *         response:  { type: string }
 *         visibility:
 *           type: array
 *           items: { type: string }
 *         date:
 *           type: string
 *           format: date-time
 */
// Factory so we can inject Firestore cleanly
function feedbackRoutes(db) {
    const router = (0, express_1.Router)();
    // Inject Firestore into req.app.locals.db so controllers can read it
    router.use((req, _res, next) => {
        req.app.locals.db = db;
        next();
    });
    /**
     * @openapi
     * /api/feedback:
     *   post:
     *     summary: Submit feedback (user)
     *     tags: [Feedback]
     *     description: |
     *       Provide **either**:
     *       - `x-user-id` (users doc id, server resolves empid/name), **or**
     *       - `x-empid` **and** `x-name` directly.
     *     parameters:
     *       - in: header
     *         name: x-user-id
     *         required: false
     *         schema: { type: string }
     *         description: Firestore `users` document ID
     *       - in: header
     *         name: x-empid
     *         required: false
     *         schema: { type: string }
     *       - in: header
     *         name: x-name
     *         required: false
     *         schema: { type: string }
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             properties:
     *               message: { type: string }
     *     responses:
     *       201: { description: Feedback created }
     *       400: { description: Missing user meta or message }
     */
    router.post('/', feedbackController_1.createFeedback);
    /**
     * @openapi
     * /api/feedback:
     *   get:
     *     summary: Get all feedbacks (admin)
     *     tags: [Feedback]
     *     responses:
     *       200:
     *         description: List of feedbacks
     *         content:
     *           application/json:
     *             schema:
     *               type: array
     *               items: { $ref: '#/components/schemas/FeedbackOut' }
     */
    router.get('/', feedbackController_1.getAllFeedback);
    return router;
}
//# sourceMappingURL=feedbackRoutes.js.map