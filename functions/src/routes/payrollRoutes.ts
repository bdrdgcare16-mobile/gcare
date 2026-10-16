import {
  Router,
} from 'express';

import {
  confirmPayrollPaid,
  generatePayroll,
  generatePreviousMonthPayroll,
  getMyPayroll,
  listMonthlyPayroll,
  listPreviousMonthPayroll,
  previewPayroll,
  savePayrollSnapshotController,
  updatePayrollController,
} from '../controllers/payrollController';

import {
  validatePayrollMonth,
  validateSalaryCalculationMethod,
} from '../validators/payrollValidator';

import { authMiddleware, roleMiddleware } from '../middlewares/authMiddleware';
import { requireFeature } from '../middlewares/featureMiddleware';
import { hrFeatureGate } from '../middlewares/hrFeatureMiddleware';

const router = Router();

/*
 * All payroll routes are authenticated. Tenant context always comes from the
 * verified JWT — request body/query companyId is never trusted for
 * authorization. Ordering: auth → role → feature → validators → controller.
 */

const payrollEnabled = requireFeature('payroll');
// HR inherits the tenant-admin payroll module when 'payroll' is in
// approvedFeatures — full read + generate/snapshot/mark-paid/edit,
// same operations available to the tenant admin role.
const isPayrollWriter = roleMiddleware(['admin', 'hr']);
const isPayrollReader = roleMiddleware(['admin', 'hr']);
const hrPayroll = hrFeatureGate(['payroll']);

// Any authenticated user may read their own payslip.
router.get(
  '/my-payroll',
  authMiddleware,
  payrollEnabled,
  getMyPayroll,
);

router.get(
  '/previous-month',
  authMiddleware,
  isPayrollReader,
  hrPayroll,
  payrollEnabled,
  listPreviousMonthPayroll,
);

router.get(
  '/',
  authMiddleware,
  isPayrollReader,
  hrPayroll,
  payrollEnabled,
  validatePayrollMonth,
  listMonthlyPayroll,
);

router.post(
  '/generate',
  authMiddleware,
  isPayrollWriter,
  hrPayroll,
  payrollEnabled,
  validatePayrollMonth,
  validateSalaryCalculationMethod,
  generatePayroll,
);

router.post(
  '/generate/preview',
  authMiddleware,
  isPayrollReader,
  hrPayroll,
  payrollEnabled,
  validatePayrollMonth,
  validateSalaryCalculationMethod,
  previewPayroll,
);

router.post(
  '/snapshot',
  authMiddleware,
  isPayrollWriter,
  hrPayroll,
  payrollEnabled,
  validateSalaryCalculationMethod,
  savePayrollSnapshotController,
);

router.post(
  '/generate/previous-month',
  authMiddleware,
  isPayrollWriter,
  hrPayroll,
  payrollEnabled,
  validateSalaryCalculationMethod,
  generatePreviousMonthPayroll,
);

router.patch(
  '/:payrollId',
  authMiddleware,
  isPayrollWriter,
  hrPayroll,
  payrollEnabled,
  updatePayrollController,
);

router.patch(
  '/:payrollId/paid',
  authMiddleware,
  isPayrollWriter,
  hrPayroll,
  payrollEnabled,
  confirmPayrollPaid,
);

export default router;
