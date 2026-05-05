import { Router } from 'express';
import * as ctrl from '../controllers/rewardController';
import { authMiddleware, roleMiddleware } from '../middlewares/authMiddleware';

const router = Router();

/**
 * @swagger
 * tags:
 *   - name: Rewards
 *     description: Manage employee rewards (admin & user)
 */

router.post('/', authMiddleware, roleMiddleware(['admin']), ctrl.createReward);

// Admin and Employee can see rewards (employee only own, admin all company rewards)
router.get('/', authMiddleware, roleMiddleware(['admin', 'employee']), ctrl.getAllRewards);

// Employee can see own rewards only
router.get('/mine', authMiddleware, ctrl.getMyRewards);

// Admin can see one reward only if it belongs to same company
router.get('/:id', authMiddleware, roleMiddleware(['admin']), ctrl.getRewardById);

// Admin can delete reward only if it belongs to same company
router.delete('/:id', authMiddleware, roleMiddleware(['admin']), ctrl.deleteReward);

export default router;