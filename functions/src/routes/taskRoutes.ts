import { Router } from 'express';
import { verifyToken, roleMiddleware } from '../middlewares/authMiddleware';
import { requireFeature } from '../middlewares/featureMiddleware';
import { hrFeatureGate } from '../middlewares/hrFeatureMiddleware';
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

const tasksEnabled = requireFeature('tasks');
// Task list/broadcast/assign is HR work too — hr allowed when 'tasks' is in
// their approvedFeatures. Employee self endpoints are unchanged.
const isAdminOrHr = roleMiddleware(['admin', 'hr']);
const hrTasks = hrFeatureGate(['tasks']);

/** Backward-compatible generic create route */
router.post('/', verifyToken, tasksEnabled, isAdminOrHr, hrTasks, createBroadcastTask);

/** Admin: create a broadcast task for all employees */
router.post('/broadcast', verifyToken, tasksEnabled, isAdminOrHr, hrTasks, createBroadcastTask);

/** Admin: create a task for exactly one employee */
router.post('/assign', verifyToken, tasksEnabled, isAdminOrHr, hrTasks, createSingleTask);

/** Employee self-post: create a Daily Update */
router.post('/daily-update', verifyToken, tasksEnabled, createDailyUpdateForSelf);

/** Employee: mark an assigned task completed, with optional proof file */
router.post('/:id/complete', verifyToken, tasksEnabled, uploadTaskProof('proof'), completeTask);

/** User view: merged list for the current employee */
router.get('/user', verifyToken, tasksEnabled, listTasksForUser);

/** Admin view: employee task list */
router.get('/employee', verifyToken, tasksEnabled, isAdminOrHr, hrTasks, listEmployeeTasks);

/** Admin view: employee task list */
router.get('/', verifyToken, tasksEnabled, isAdminOrHr, hrTasks, listEmployeeTasks);

/** Admin: Get signed URL for task proof file */
router.get('/:id/proof-url', verifyToken, tasksEnabled, isAdminOrHr, hrTasks, getTaskProofUrl);

/** Single task by id */
router.get('/:id', verifyToken, tasksEnabled, getTask);

export default router;