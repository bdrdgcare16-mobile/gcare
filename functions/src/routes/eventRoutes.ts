import { Router, Request, Response, NextFunction } from 'express';
import {
  createEvent,
  getAllEvents,
  getEventById,
  updateEvent,
  deleteEvent
} from '../controllers/eventController';
import { authMiddleware, roleMiddleware } from '../middlewares/authMiddleware';
import { requireFeature } from '../middlewares/featureMiddleware';
import { hrFeatureGate } from '../middlewares/hrFeatureMiddleware';
// import { roleMiddleware } from '../middlewares/roleMiddleware'; // optional if you already have this

export default function eventRoutes(db: FirebaseFirestore.Firestore) {
  const router = Router();

  // Make Firestore available on req.app.locals.db
  router.use((req: Request, _res: Response, next: NextFunction) => {
    (req.app.locals as any).db = db;
    next();
  });

  // IMPORTANT: protect all event routes
  router.use(authMiddleware);

  // Tenant entitlement: events feature
  router.use(requireFeature('events'));

  // HR additionally needs 'events' in approvedFeatures (no-op for other roles)
  router.use(hrFeatureGate(['events']));

  // Both admin and employee from same company can view
  router.get('/', getAllEvents);
  router.get('/:id', getEventById);

  // Create / update / delete — admin, or HR with 'events' approved
  // (hrFeatureGate at router level enforces the approved feature for hr).
  router.post('/', roleMiddleware(['admin', 'hr']), createEvent);
  router.put('/:id', roleMiddleware(['admin', 'hr']), updateEvent);
  router.delete('/:id', roleMiddleware(['admin', 'hr']), deleteEvent);

  return router;
}