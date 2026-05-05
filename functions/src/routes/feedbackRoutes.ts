import { Router, Request, Response, NextFunction } from 'express';
import { createFeedback, getAllFeedback } from '../controllers/feedbackController';
import type { Firestore } from 'firebase-admin/firestore';
import { authMiddleware } from '../middlewares/authMiddleware';

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
 *         companyId:
 *           type: string
 *         date:
 *           type: string
 *           format: date-time
 */

export default function feedbackRoutes(db: Firestore) {
  const router = Router();

  router.use((req: Request, _res: Response, next: NextFunction) => {
    req.app.locals.db = db;
    next();
  });

  // Protect all feedback routes
  router.use(authMiddleware);

  /**
   * @openapi
   * /api/feedback:
   *   post:
   *     summary: Submit feedback (user)
   *     tags: [Feedback]
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
   *       401: { description: Unauthorized }
   */
  router.post('/', createFeedback);

  /**
   * @openapi
   * /api/feedback:
   *   get:
   *     summary: Get all feedbacks for logged-in company only
   *     tags: [Feedback]
   *     responses:
   *       200:
   *         description: List of feedbacks
   *       401:
   *         description: Unauthorized
   */
  router.get('/', getAllFeedback);

  return router;
}