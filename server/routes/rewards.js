// // const express = require('express');
// // const router = express.Router();
// // const ctrl = require('../controllers/rewardController');

// // /**
// //  * @swagger
// //  * tags:
// //  *   - name: Rewards
// //  *     description: Manage employee rewards (admin & user)
// //  */

// // /**
// //  * @swagger
// //  * components:
// //  *   schemas:
// //  *     Reward:
// //  *       type: object
// //  *       required:
// //  *         - empid
// //  *         - name
// //  *         - department
// //  *         - description
// //  *         - adminname
// //  *         - date
// //  *       properties:
// //  *         empid:
// //  *           type: string
// //  *           description: Employee ID (who receives the reward)
// //  *         name:
// //  *           type: string
// //  *           description: Employee name
// //  *         department:
// //  *           type: string
// //  *           description: Department of employee
// //  *         description:
// //  *           type: string
// //  *           description: Reason for reward (e.g., for outstanding performance)
// //  *         adminname:
// //  *           type: string
// //  *           description: Name of admin who gave the reward
// //  *         date:
// //  *           type: string
// //  *           format: date-time
// //  *           description: Date the reward was given
// //  */

// // module.exports = (db) => {
// //   router.use((req, res, next) => {
// //     req.app.locals.db = db;
// //     next();
// //   });

// //   /**
// //    * @swagger
// //    * /api/rewards:
// //    *   post:
// //    *     summary: Create a new reward
// //    *     tags: [Rewards]
// //    *     requestBody:
// //    *       required: true
// //    *       content:
// //    *         application/json:
// //    *           schema:
// //    *             $ref: '#/components/schemas/Reward'
// //    *     responses:
// //    *       201:
// //    *         description: Reward created successfully
// //    *       500:
// //    *         description: Server error
// //    */
// //   router.post('/', ctrl.createReward);

// //   /**
// //    * @swagger
// //    * /api/rewards:
// //    *   get:
// //    *     summary: Get all rewards or filter by employee ID
// //    *     tags: [Rewards]
// //    *     parameters:
// //    *       - in: query
// //    *         name: empid
// //    *         schema:
// //    *           type: string
// //    *         description: Filter by employee ID
// //    *     responses:
// //    *       200:
// //    *         description: List of rewards
// //    *         content:
// //    *           application/json:
// //    *             schema:
// //    *               type: array
// //    *               items:
// //    *                 $ref: '#/components/schemas/Reward'
// //    *       500:
// //    *         description: Server error
// //    */
// //   router.get('/', ctrl.getAllRewards);

// //   /**
// //    * @swagger
// //    * /api/rewards/{id}:
// //    *   get:
// //    *     summary: Get a reward by its document ID
// //    *     tags: [Rewards]
// //    *     parameters:
// //    *       - in: path
// //    *         name: id
// //    *         required: true
// //    *         schema:
// //    *           type: string
// //    *         description: Firestore document ID of the reward
// //    *     responses:
// //    *       200:
// //    *         description: Reward found
// //    *         content:
// //    *           application/json:
// //    *             schema:
// //    *               $ref: '#/components/schemas/Reward'
// //    *       404:
// //    *         description: Reward not found
// //    *       500:
// //    *         description: Server error
// //    */
// //   router.get('/:id', ctrl.getRewardById);

// //   /**
// //    * @swagger
// //    * /api/rewards/{id}:
// //    *   delete:
// //    *     summary: Delete a reward by its document ID
// //    *     tags: [Rewards]
// //    *     parameters:
// //    *       - in: path
// //    *         name: id
// //    *         required: true
// //    *         schema:
// //    *           type: string
// //    *         description: Firestore document ID of the reward
// //    *     responses:
// //    *       200:
// //    *         description: Reward deleted successfully
// //    *       500:
// //    *         description: Server error
// //    */
// //   router.delete('/:id', ctrl.deleteReward);

// //   return router;
// // };
// // routes/rewards.js
// const express = require('express');
// const router = express.Router();
// const ctrl = require('../controllers/rewardController');

// // Try to load your auth middleware; fall back to no-ops if not present
// let verifyToken = (_req, _res, next) => next();
// let isAdmin = (_req, _res, next) => next();

// try {
//   // Adjust this path if needed (e.g. '../middleware/authMiddleware')
//   const auth = require('../middlewares/authMiddleware');
//   if (auth?.verifyToken) verifyToken = auth.verifyToken;
//   if (auth?.isAdmin) isAdmin = auth.isAdmin;
// } catch (_e) {
//   console.warn(
//     'Auth middleware not found; Rewards routes will be public. (This is OK if intentional)',
//   );
// }

// /**
//  * @swagger
//  * tags:
//  *   - name: Rewards
//  *     description: Manage employee rewards (admin & user)
//  */

// /**
//  * @swagger
//  * components:
//  *   schemas:
//  *     Reward:
//  *       type: object
//  *       required:
//  *         - empid
//  *         - name
//  *         - department
//  *         - description
//  *         - adminname
//  *         - date
//  *       properties:
//  *         empid: { type: string, description: Employee ID (recipient) }
//  *         name: { type: string, description: Employee name }
//  *         department: { type: string, description: Department }
//  *         description: { type: string, description: Reason/context }
//  *         adminname: { type: string, description: Admin who granted reward }
//  *         date: { type: string, format: date-time, description: Reward date }
//  */

// module.exports = (db) => {
//   // Inject Firestore db for this router
//   router.use((req, _res, next) => {
//     req.app.locals.db = db;
//     next();
//   });

//   /**
//    * @swagger
//    * /api/rewards:
//    *   post:
//    *     summary: Create a new reward (admin)
//    *     tags: [Rewards]
//    *     requestBody:
//    *       required: true
//    *       content:
//    *         application/json:
//    *           schema:
//    *             $ref: '#/components/schemas/Reward'
//    *     responses:
//    *       201: { description: Reward created successfully }
//    *       400: { description: Validation error }
//    *       401: { description: Unauthorized }
//    *       403: { description: Forbidden }
//    *       500: { description: Server error }
//    */
//   router.post('/', verifyToken, isAdmin, ctrl.createReward);

//   /**
//    * @swagger
//    * /api/rewards:
//    *   get:
//    *     summary: Get all rewards, optionally filtered by empid
//    *     tags: [Rewards]
//    *     parameters:
//    *       - in: query
//    *         name: empid
//    *         schema: { type: string }
//    *         description: Filter by employee ID
//    *     responses:
//    *       200:
//    *         description: List of rewards
//    *       500:
//    *         description: Server error
//    */
//   router.get('/', ctrl.getAllRewards);

//   /**
//    * @swagger
//    * /api/rewards/mine:
//    *   get:
//    *     summary: Get rewards for the current logged-in employee
//    *     tags: [Rewards]
//    *     responses:
//    *       200: { description: List of rewards }
//    *       401: { description: Unauthorized }
//    *       500: { description: Server error }
//    */
//   router.get('/mine', verifyToken, ctrl.getMyRewards);

//   /**
//    * @swagger
//    * /api/rewards/{id}:
//    *   get:
//    *     summary: Get a reward by its document ID
//    *     tags: [Rewards]
//    *     parameters:
//    *       - in: path
//    *         name: id
//    *         required: true
//    *         schema: { type: string }
//    *         description: Firestore document ID of the reward
//    *     responses:
//    *       200: { description: Reward found }
//    *       404: { description: Reward not found }
//    *       500: { description: Server error }
//    */
//   router.get('/:id', ctrl.getRewardById);

//   /**
//    * @swagger
//    * /api/rewards/{id}:
//    *   delete:
//    *     summary: Delete a reward by its document ID (admin)
//    *     tags: [Rewards]
//    *     parameters:
//    *       - in: path
//    *         name: id
//    *         required: true
//    *         schema: { type: string }
//    *     responses:
//    *       200: { description: Reward deleted successfully }
//    *       401: { description: Unauthorized }
//    *       403: { description: Forbidden }
//    *       500: { description: Server error }
//    */
//   router.delete('/:id', verifyToken, isAdmin, ctrl.deleteReward);

//   return router;
// };
const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/rewardController');

// Try to load your auth middleware; fall back to no-ops if not present
let verifyToken = (_req, _res, next) => next();
let isAdmin = (_req, _res, next) => next();

try {
  // Adjust this path if needed (e.g. '../middleware/authMiddleware')
  const auth = require('../middlewares/authMiddleware');
  if (auth?.verifyToken) verifyToken = auth.verifyToken;
  if (auth?.isAdmin) isAdmin = auth.isAdmin;
} catch (_e) {
  console.warn(
    'Auth middleware not found; Rewards routes will be public. (This is OK if intentional)',
  );
}

/**
 * @swagger
 * tags:
 *   - name: Rewards
 *     description: Manage employee rewards (admin & user)
 */

/**
 * @swagger
 * components:
 *   schemas:
 *     Reward:
 *       type: object
 *       required:
 *         - empid
 *         - name
 *         - department
 *         - description
 *         - adminname
 *         - date
 *       properties:
 *         empid: { type: string, description: Employee ID (recipient) }
 *         name: { type: string, description: Employee name }
 *         department: { type: string, description: Department }
 *         description: { type: string, description: Reason/context }
 *         adminname: { type: string, description: Admin who granted reward }
 *         date: { type: string, format: date-time, description: Reward date }
 */

module.exports = (db) => {
  // Inject Firestore db for this router
  router.use((req, _res, next) => {
    req.app.locals.db = db;
    next();
  });

  router.post('/', verifyToken, isAdmin, ctrl.createReward);

  router.get('/', ctrl.getAllRewards);

  router.get('/mine', verifyToken, ctrl.getMyRewards);

  router.get('/:id', ctrl.getRewardById);

  router.delete('/:id', verifyToken, isAdmin, ctrl.deleteReward);

  return router;
};
