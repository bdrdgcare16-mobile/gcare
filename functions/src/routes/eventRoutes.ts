import { Router, Request, Response, NextFunction } from 'express';
import {
  createEvent,
  getAllEvents,
  getEventById,
  updateEvent,
  deleteEvent
} from '../controllers/eventController';
import { authMiddleware } from '../middlewares/authMiddleware';
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

  // If you want only admin to create/update/delete, uncomment role middleware
  // router.post('/', roleMiddleware(['admin']), createEvent);
  // router.put('/:id', roleMiddleware(['admin']), updateEvent);
  // router.delete('/:id', roleMiddleware(['admin']), deleteEvent);

  // Both admin and employee from same company can view
  router.get('/', getAllEvents);
  router.get('/:id', getEventById);

  // Create / update / delete
  router.post('/', createEvent);
  router.put('/:id', updateEvent);
  router.delete('/:id', deleteEvent);

  return router;
}