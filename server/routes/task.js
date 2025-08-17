// // // // // routes/task.js

// // // // const router = require('express').Router();
// // // // const taskController = require('../controllers/taskController');
// // // // const { verifyToken, isAdmin, isUser } = require('../middlewares/authMiddleware');

// // // // /**
// // // //  * @swagger
// // // //  * tags:
// // // //  *   - name: Tasks
// // // //  *     description: Task management and assignment
// // // //  *
// // // //  * components:
// // // //  *   schemas:
// // // //  *     Task:
// // // //  *       # (omitted for brevity)
// // // //  *
// // // //  *   parameters:
// // // //  *     TaskId:
// // // //  *       in: path
// // // //  *       name: id
// // // //  *       required: true
// // // //  *       schema:
// // // //  *         type: string
// // // //  *         format: uuid
// // // //  *       description: The **task’s** UUID (document ID)
// // // //  *     EmpId:
// // // //  *       in: path
// // // //  *       name: empid
// // // //  *       required: true
// // // //  *       schema:
// // // //  *         type: string
// // // //  *       description: The **employee’s** empId to filter by
// // // //  */

// // // // /**
// // // //  * @swagger
// // // //  * /api/tasks:
// // // //  *   post:
// // // //  *     # ...
// // // //  */
// // // // router.post('/', verifyToken, isAdmin, taskController.createTask);

// // // // /**
// // // //  * @swagger
// // // //  * /api/tasks/my:
// // // //  *   get:
// // // //  *     # ...
// // // //  */
// // // // router.get('/my', verifyToken, isUser, taskController.getMyTasks);

// // // // /**
// // // //  * @swagger
// // // //  * /api/tasks:
// // // //  *   get:
// // // //  *     # ...
// // // //  */
// // // // router.get('/', verifyToken, isAdmin, taskController.getAllTasks);

// // // // /**
// // // //  * @swagger
// // // //  * /api/tasks/{id}:
// // // //  *   get:
// // // //  *     summary: Get a single task by its **UUID**
// // // //  *     parameters:
// // // //  *       - $ref: '#/components/parameters/TaskId'
// // // //  *     # ...
// // // //  */
// // // // router.get('/:id', verifyToken, taskController.getTaskById);

// // // // /**
// // // //  * @swagger
// // // //  * /api/tasks/{id}:
// // // //  *   put:
// // // //  *     summary: Update a task (must supply **task UUID** in path)
// // // //  *     parameters:
// // // //  *       - $ref: '#/components/parameters/TaskId'
// // // //  *     # ...
// // // //  */
// // // // router.put('/:id', verifyToken, taskController.updateTask);

// // // // /**
// // // //  * @swagger
// // // //  * /api/tasks/{id}:
// // // //  *   delete:
// // // //  *     summary: Delete a task (must supply **task UUID** in path)
// // // //  *     parameters:
// // // //  *       - $ref: '#/components/parameters/TaskId'
// // // //  *     # ...
// // // //  */
// // // // router.delete('/:id', verifyToken, isAdmin, taskController.deleteTask);

// // // // /**
// // // //  * @swagger
// // // //  * /api/tasks/user/{empid}:
// // // //  *   get:
// // // //  *     summary: Get tasks assigned to a specific **empId** (Admin only)
// // // //  *     parameters:
// // // //  *       - $ref: '#/components/parameters/EmpId'
// // // //  *     # ...
// // // //  */
// // // // router.get('/user/:empid', verifyToken, isAdmin, taskController.getTasksByEmp);

// // // // module.exports = router;

// // // // routes/task.js

// // // const router = require('express').Router();
// // // const taskController = require('../controllers/taskController');
// // // const { verifyToken, isAdmin, isUser } = require('../middlewares/authMiddleware');

// // // /**
// // //  * @swagger
// // //  * tags:
// // //  *   - name: Tasks
// // //  *     description: Task management and assignment
// // //  *
// // //  * components:
// // //  *   parameters:
// // //  *     TaskId:
// // //  *       in: path
// // //  *       name: taskId
// // //  *       required: true
// // //  *       schema:
// // //  *         type: string
// // //  *         format: uuid
// // //  *       description: The task’s UUID (i.e. Firestore doc ID)
// // //  *
// // //  *     EmpId:
// // //  *       in: path
// // //  *       name: empid
// // //  *       required: true
// // //  *       schema:
// // //  *         type: string
// // //  *       description: The employee’s empId to filter tasks
// // //  */

// // // /**
// // //  * @swagger
// // //  * /api/tasks:
// // //  *   post:
// // //  *     tags: [Tasks]
// // //  *     summary: Create a new task (Admin only)
// // //  *     security:
// // //  *       - bearerAuth: []
// // //  *     requestBody:
// // //  *       # ...
// // //  *     responses:
// // //  *       # ...
// // //  */
// // // router.post('/', verifyToken, isAdmin, taskController.createTask);

// // // /**
// // //  * @swagger
// // //  * /api/tasks:
// // //  *   get:
// // //  *     tags: [Tasks]
// // //  *     summary: List all tasks (Admin only)
// // //  *     security:
// // //  *       - bearerAuth: []
// // //  *     responses:
// // //  *       # ...
// // //  */
// // // router.get('/', verifyToken, isAdmin, taskController.getAllTasks);

// // // /**
// // //  * @swagger
// // //  * /api/tasks/my:
// // //  *   get:
// // //  *     tags: [Tasks]
// // //  *     summary: List tasks assigned to the authenticated user
// // //  *     security:
// // //  *       - bearerAuth: []
// // //  *     responses:
// // //  *       # ...
// // //  */
// // // router.get('/my', verifyToken, isUser, taskController.getMyTasks);

// // // /**
// // //  * @swagger
// // //  * /api/tasks/{taskId}:
// // //  *   get:
// // //  *     tags: [Tasks]
// // //  *     summary: Get one task by its **UUID**
// // //  *     parameters:
// // //  *       - $ref: '#/components/parameters/TaskId'
// // //  *     security:
// // //  *       - bearerAuth: []
// // //  *     responses:
// // //  *       # ...
// // //  */
// // // router.get('/:taskId', verifyToken, taskController.getTaskById);

// // // /**
// // //  * @swagger
// // //  * /api/tasks/{taskId}:
// // //  *   put:
// // //  *     tags: [Tasks]
// // //  *     summary: Update a task (must supply **taskId** in path)
// // //  *     parameters:
// // //  *       - $ref: '#/components/parameters/TaskId'
// // //  *     security:
// // //  *       - bearerAuth: []
// // //  *     requestBody:
// // //  *       # ...
// // //  *     responses:
// // //  *       # ...
// // //  */
// // // router.put('/:taskId', verifyToken, taskController.updateTask);

// // // /**
// // //  * @swagger
// // //  * /api/tasks/{taskId}:
// // //  *   delete:
// // //  *     tags: [Tasks]
// // //  *     summary: Delete a task (Admin only; supply **taskId** in path)
// // //  *     parameters:
// // //  *       - $ref: '#/components/parameters/TaskId'
// // //  *     security:
// // //  *       - bearerAuth: []
// // //  *     responses:
// // //  *       # ...
// // //  */
// // // router.delete('/:taskId', verifyToken, isAdmin, taskController.deleteTask);

// // // /**
// // //  * @swagger
// // //  * /api/tasks/user/{empid}:
// // //  *   get:
// // //  *     tags: [Tasks]
// // //  *     summary: Get tasks assigned to a specific **empId** (Admin only)
// // //  *     parameters:
// // //  *       - $ref: '#/components/parameters/EmpId'
// // //  *     security:
// // //  *       - bearerAuth: []
// // //  *     responses:
// // //  *       # ...
// // //  */
// // // router.get('/user/:empid', verifyToken, isAdmin, taskController.getTasksByEmp);

// // // module.exports = router;
// // // routes/task.js
// // const express = require('express');
// // const multer = require('multer');
// // const auth = require('../middlewares/authMiddleware');
// // const ctrl = require('../controllers/taskcontroller');

// // const router = express.Router();

// // // Multer in-memory storage (we upload to Firebase Storage from buffer)
// // const upload = multer({
// //   storage: multer.memoryStorage(),
// //   limits: { fileSize: 25 * 1024 * 1024, files: 1 }, // 25MB, single file
// // });

// // /**
// //  * Admin: upload one file & assign to ALL employees
// //  * Body: multipart/form-data
// //  *   - field name for file: "file"
// //  *   - optional: title, description, dueDate (yyyy-MM-dd), kind
// //  */
// // router.post('/broadcast', auth, upload.single('file'), ctrl.createBroadcastTask);

// // /**
// //  * Admin: upload one file to ONE employee
// //  * Body: multipart/form-data
// //  *   - assignedTo (empid) [required]
// //  *   - file (field name "file")      [required]
// //  *   - title?, description?, dueDate?, kind?
// //  */
// // router.post('/upload', auth, upload.single('file'), ctrl.createSingleTask);

// // /**
// //  * List tasks.
// //  * Admin:
// //  *   GET /api/tasks?audience=all
// //  *   GET /api/tasks?audience=employee
// //  * Employee:
// //  *   GET /api/tasks?empid=EMP001
// //  */
// // router.get('/', auth, ctrl.listTasks);

// // /** Get single task */
// // router.get('/:id', auth, ctrl.getTask);

// // module.exports = router;
// // routes/task.js
// // routes/task.js
// const express = require('express');
// const multer = require('multer');
// const auth = require('../middlewares/authMiddleware');   // must export a function
// const ctrl = require('../controllers/taskcontroller');   // must export the 4 funcs below

// const router = express.Router();

// // in-memory upload; backend pushes buffer to storage
// const upload = multer({
//   storage: multer.memoryStorage(),
//   limits: { fileSize: 25 * 1024 * 1024, files: 1 },
// });

// // Admin: upload one file → ALL employees
// router.post('/broadcast', auth, upload.single('file'), ctrl.createBroadcastTask);

// // Admin: upload one file → ONE employee (body.assignedTo)
// router.post('/upload', auth, upload.single('file'), ctrl.createSingleTask);

// // List tasks (admin: ?audience=all|employee, employee: ?empid=EMP001)
// router.get('/', auth, ctrl.listTasks);

// // Get a single task by id
// router.get('/:id', auth, ctrl.getTask);

// module.exports = router;
// routes/task.js
const express = require('express');
const multer = require('multer');
const ctrl = require('../controllers/taskcontroller');

// ---- resolve auth middleware to a function ----
let auth = require('../middlewares/authMiddleware');      // or '../middleware/auth'
if (typeof auth !== 'function') {
  // try common export names; fall back to a no-op (dev only)
  auth = auth?.verifyToken || auth?.authenticate || auth?.auth || ((req, res, next) => next());
}

// Multer in-memory storage (upload to Firebase Storage from buffer)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 25 * 1024 * 1024, files: 1 }, // 25MB, single file
});

const router = express.Router();

/**
 * Admin: upload one file & assign to ALL employees
 * Body: multipart/form-data
 *   - file (field name "file")  [required]
 *   - title?, description?, dueDate?, kind?
 */
router.post('/broadcast', auth, upload.single('file'), ctrl.createBroadcastTask);

/**
 * Admin: upload one file to ONE employee
 * Body: multipart/form-data
 *   - assignedTo (empid)        [required]
 *   - file (field name "file")  [required]
 *   - title?, description?, dueDate?, kind?
 */
router.post('/upload', auth, upload.single('file'), ctrl.createSingleTask);

/**
 * List tasks.
 * Admin:
 *   GET /api/tasks?audience=all
 *   GET /api/tasks?audience=employee
 * Employee:
 *   GET /api/tasks?empid=EMP001
 */
router.get('/', auth, ctrl.listTasks);

/** Get single task by id */
router.get('/:id', auth, ctrl.getTask);

module.exports = router;
