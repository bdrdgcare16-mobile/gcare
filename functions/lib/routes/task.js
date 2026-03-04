"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
// src/routes/task.ts
const express_1 = require("express");
const authMiddleware_1 = require("../middlewares/authMiddleware");
const taskController_1 = require("../controllers/taskController");
const router = (0, express_1.Router)();
/** Admin: create a broadcast task for all employees (JSON only, no files) */
router.post('/broadcast', authMiddleware_1.verifyToken, authMiddleware_1.isAdmin, taskController_1.createBroadcastTask);
/** Admin: create a task for exactly one employee (JSON only, no files) */
router.post('/assign', authMiddleware_1.verifyToken, authMiddleware_1.isAdmin, taskController_1.createSingleTask);
/** Employee self-post: create a Daily Update for the logged-in user (JSON only) */
router.post('/daily-update', authMiddleware_1.verifyToken, taskController_1.createDailyUpdateForSelf);
/** User view: merged list for the current employee. */
router.get('/user', authMiddleware_1.verifyToken, taskController_1.listTasksForUser);
/** Employee-only list (optionally filter by empid). */
router.get('/employee', authMiddleware_1.verifyToken, taskController_1.listEmployeeTasks);
/** Admin/broadcast list (kept for compatibility). */
router.get('/', authMiddleware_1.verifyToken, taskController_1.listTasks);
/** Single task by id. */
router.get('/:id', authMiddleware_1.verifyToken, taskController_1.getTask);
exports.default = router;
//# sourceMappingURL=task.js.map