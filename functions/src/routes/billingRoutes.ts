import { verifyToken } from "../common/auth.utils";
import { runMonthlyBilling } from "../controllers/billingController";
import { isAdmin } from "../middlewares/authMiddleware";
import router from "./authRoutes";

router.post('/billing/generate', verifyToken, isAdmin, runMonthlyBilling);
export default router;