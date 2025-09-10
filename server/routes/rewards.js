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
