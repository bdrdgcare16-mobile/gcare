import { Router } from 'express';
import { authMiddleware } from '../middlewares/authMiddleware';
import { getRequestDetails } from '../controllers/employeeDetailsController';

const router = Router();

router.get("/request-details", authMiddleware, getRequestDetails);
export default router;