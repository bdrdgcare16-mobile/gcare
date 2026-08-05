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
} from '../controllers/payrollController';

import {
  validatePayrollMonth,
  validateSalaryCalculationMethod,
} from '../validators/payrollValidator';

import { authMiddleware } from '../middlewares/authMiddleware';

const router = Router();

/*
 * Add your existing admin authentication
 * middleware to these routes.
 */

router.get(
  '/my-payroll',
  authMiddleware,
  getMyPayroll,
);

router.get(
  '/previous-month',
  listPreviousMonthPayroll,
);

router.get(
  '/',
  validatePayrollMonth,
  listMonthlyPayroll,
);

router.post(
  '/generate',
  validatePayrollMonth,
  validateSalaryCalculationMethod,
  generatePayroll,
);

router.post(
  '/generate/preview',
  validatePayrollMonth,
  validateSalaryCalculationMethod,
  previewPayroll,
);

router.post(
  '/snapshot',
  validateSalaryCalculationMethod,
  savePayrollSnapshotController,
);

router.post(
  '/generate/previous-month',
  validateSalaryCalculationMethod,
  generatePreviousMonthPayroll,
);

router.patch(
  '/:payrollId/paid',
  confirmPayrollPaid,
);

export default router;