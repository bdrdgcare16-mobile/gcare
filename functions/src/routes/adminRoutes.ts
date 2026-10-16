// functions/src/routes/admin.ts
import { Router } from "express";
import {
  createAdmin,
  createHrUser,
  deactivateHrUser,
  listHrUsers,
  promoteToAdmin,
  updateHrUser,
} from "../controllers/adminController";
import { authMiddleware as requireAuth, isAdmin as requireAdmin, roleMiddleware } from "../middlewares/authMiddleware";

const router = Router();

// secure these with admin-only token
router.post("/create", requireAuth, requireAdmin, createAdmin);
router.post("/promote", requireAuth, requireAdmin, promoteToAdmin);

// HR user management — Company Admin (role 'company_admin') and legacy
// tenant admins (role 'admin'). HR accounts are tenant users (role 'hr')
// scoped to the caller's company; they never get admin or platform_admin
// privileges. companyId always comes from the JWT — never the request.
const canManageHrUsers = roleMiddleware(['admin', 'company_admin']);
router.get("/hr-users", requireAuth, canManageHrUsers, listHrUsers);
router.post("/hr-users", requireAuth, canManageHrUsers, createHrUser);
router.put("/hr-users/:userId", requireAuth, canManageHrUsers, updateHrUser);
router.delete(
  "/hr-users/:userId",
  requireAuth,
  canManageHrUsers,
  deactivateHrUser,
);

export default router;
