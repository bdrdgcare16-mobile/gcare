import { Router } from 'express';
import multer from 'multer';
import { verifyToken, isAdmin } from '../middlewares/authMiddleware';
import {
  createBroadcastTask,
  createSingleTask,
  listTasks,
  getTask,
} from '../controllers/taskController';

// Extend the Express Request type to include the file property
declare global {
  namespace Express {
    interface Request {
      file?: Express.Multer.File;
    }
  }
}

const router = Router();

// Multer in-memory storage (upload to Firebase Storage from buffer)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 25 * 1024 * 1024, files: 1 }, // 25MB, single file
});

/**
 * Admin: upload one file & assign to ALL employees
 * Body: multipart/form-data
 *   - file (field name "file")  [required]
 *   - title?, description?, dueDate?, kind?
 */
router.post('/broadcast', verifyToken, isAdmin, upload.single('file'), createBroadcastTask);

/**
 * Admin: upload one file to ONE employee
 * Body: multipart/form-data
 *   - assignedTo (empid)        [required]
 *   - file (field name "file")  [required]
 *   - title?, description?, dueDate?, kind?
 */
router.post('/upload', verifyToken, isAdmin, upload.single('file'), createSingleTask);

/** List broadcast tasks */
router.get('/', verifyToken, listTasks);

/** Get single task by id */
router.get('/:id', verifyToken, getTask);

export default router;
