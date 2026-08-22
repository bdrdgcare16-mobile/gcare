import { Router } from 'express';
import { verifyToken, isAdmin } from '../middlewares/authMiddleware';
import { uploadTaskProof } from '../middlewares/uploadMiddleware';
import {
  createBroadcastTask,
  createSingleTask,
  getTask,
  listTasksForUser,
  createDailyUpdateForSelf,
  listEmployeeTasks,
  completeTask,
  getTaskProofUrl,
} from '../controllers/taskController';

const router = Router();

/** Backward-compatible generic create route */
router.post('/', verifyToken, isAdmin, createBroadcastTask);

/** Admin: create a broadcast task for all employees */
router.post('/broadcast', verifyToken, isAdmin, createBroadcastTask);

/** Admin: create a task for exactly one employee */
router.post('/assign', verifyToken, isAdmin, createSingleTask);

/** Employee self-post: create a Daily Update */
router.post('/daily-update', verifyToken, createDailyUpdateForSelf);

/** Employee: mark an assigned task completed, with optional proof file */
router.post('/:id/complete', verifyToken, uploadTaskProof('proof'), completeTask);

/** User view: merged list for the current employee */
router.get('/user', verifyToken, listTasksForUser);

/** Admin view: employee task list */
router.get('/employee', verifyToken, isAdmin, listEmployeeTasks);

/** Admin view: employee task list */
router.get('/', verifyToken, isAdmin, listEmployeeTasks);

/** Admin: Get signed URL for task proof file */
router.get('/:id/proof-url', verifyToken, isAdmin, getTaskProofUrl);

/** Single task by id */
router.get('/:id', verifyToken, getTask);

export default router;