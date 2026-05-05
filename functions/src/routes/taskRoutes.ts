import { Router } from 'express';
import { verifyToken, isAdmin } from '../middlewares/authMiddleware';
import {
  createBroadcastTask,
  createSingleTask,
  getTask,
  listTasksForUser,
  createDailyUpdateForSelf,
  listEmployeeTasks,
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

/** User view: merged list for the current employee */
router.get('/user', verifyToken, listTasksForUser);

/** Admin view: employee task list */
router.get('/employee', verifyToken, isAdmin, listEmployeeTasks);

/** Admin view: employee task list */
router.get('/', verifyToken, isAdmin, listEmployeeTasks);

/** Single task by id */
router.get('/:id', verifyToken, getTask);

export default router;