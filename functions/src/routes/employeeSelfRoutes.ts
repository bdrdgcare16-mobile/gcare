// functions/src/routes/employeeSelfRoutes.ts
// Employee self-service endpoints — every route requires an authenticated
// user with role 'employee'. Mounted at /api/employee (distinct from the
// admin-managed /api/employees CRUD router).
//
// companyId and employee identity always come from the JWT — never from
// body or query parameters.
import { Router } from "express";
import {
  getEmployeeCompanyPolicy,
  acknowledgeCompanyPolicy,
} from "../controllers/employeePolicyController";
import {
  authMiddleware as requireAuth,
  roleMiddleware,
} from "../middlewares/authMiddleware";

const router = Router();
const requireEmployee = roleMiddleware(["employee"]);

router.get(
  "/company-policy",
  requireAuth,
  requireEmployee,
  getEmployeeCompanyPolicy,
);
router.post(
  "/company-policy/acknowledge",
  requireAuth,
  requireEmployee,
  acknowledgeCompanyPolicy,
);

export default router;
