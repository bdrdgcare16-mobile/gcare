import { Router } from 'express';
import * as ctrl from '../controllers/rewardController';
import { authMiddleware, roleMiddleware } from '../middlewares/authMiddleware';
import { requireFeature } from '../middlewares/featureMiddleware';
import { hrFeatureGate } from '../middlewares/hrFeatureMiddleware';

const router = Router();

const rewardsEnabled = requireFeature('rewards');
// HR inherits the tenant-admin rewards module when 'rewards' is in
// approvedFeatures — list, grant and delete within the same company.
const hrRewards = hrFeatureGate(['rewards']);

/**
 * @swagger
 * tags:
 *   - name: Rewards
 *     description: Manage employee rewards (admin & user)
 */

router.post('/', authMiddleware, rewardsEnabled, roleMiddleware(['admin', 'hr']), hrRewards, ctrl.createReward);

// Admin and Employee can see rewards (employee only own, admin all company rewards)
router.get('/', authMiddleware, rewardsEnabled, roleMiddleware(['admin', 'employee', 'hr']), hrRewards, ctrl.getAllRewards);

// Employee can see own rewards only
router.get('/mine', authMiddleware, rewardsEnabled, ctrl.getMyRewards);

// Admin can see one reward only if it belongs to same company
router.get('/:id', authMiddleware, rewardsEnabled, roleMiddleware(['admin', 'hr']), hrRewards, ctrl.getRewardById);

// Admin can delete reward only if it belongs to same company
router.delete('/:id', authMiddleware, rewardsEnabled, roleMiddleware(['admin', 'hr']), hrRewards, ctrl.deleteReward);

export default router;