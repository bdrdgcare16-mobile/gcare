import { Router } from 'express';
import { getAuditLogs } from '../controllers/auditLogController';
import { authMiddleware, roleMiddleware } from '../middlewares/authMiddleware';

const router = Router();

router.use(authMiddleware);
router.get('/', roleMiddleware(['admin']), getAuditLogs);

export default router;
