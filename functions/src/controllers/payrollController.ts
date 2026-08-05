import {
  NextFunction,
  Request,
  Response,
} from 'express';

import {
  generateAllEmployeePayroll,
  getMonthlyPayrolls,
  markPayrollAsPaid,
  previewAllEmployeePayroll,
  savePayrollSnapshot,
} from '../services/payrollService';

import {
  getPreviousPayrollMonth,
} from '../utils/payroll';

export const generatePayroll = async (
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> => {
  try {
    const result =
      await generateAllEmployeePayroll({
        companyId:
          req.body.companyId ||
          undefined,

        year:
          Number(req.body.year),

        month:
          Number(req.body.month),

        salaryCalculationMethod:
          req.body.salaryCalculationMethod,
      });

    try {
      await savePayrollSnapshot({
        companyId: String(req.body.companyId ?? ''),
        year: Number(req.body.year),
        month: Number(req.body.month),
        salaryCalculationMethod:
          String(req.body.salaryCalculationMethod ?? 'ACTUAL_CALENDAR_DAYS'),
        generatedCount: result.generated.length,
        failedCount: result.failed.length,
        generatedSample: result.generated
          .slice(0, 10)
          .map((item) => item.id ?? ''),
        failedSample: result.failed
          .slice(0, 10)
          .map((item) => ({
            empid: item.empid,
            reason: item.reason,
          })),
        createdBy: 'admin',
      });
    } catch (snapshotError) {
      console.log('[PAYROLL] snapshot save failed', {
        error: snapshotError,
      });
    }

    res.status(200).json({
      success: true,

      message:
        'Payroll generated successfully',

      data: result,
    });
  } catch (error) {
    next(error);
  }
};

export const generatePreviousMonthPayroll =
  async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const period =
        getPreviousPayrollMonth();

      const result =
        await generateAllEmployeePayroll({
          companyId:
            req.body.companyId ||
            undefined,

          year:
            period.year,

          month:
            period.month,

          salaryCalculationMethod:
            req.body.salaryCalculationMethod,
        });

      try {
        await savePayrollSnapshot({
          companyId: String(req.body.companyId ?? ''),
          year: period.year,
          month: period.month,
          salaryCalculationMethod:
            String(req.body.salaryCalculationMethod ?? 'ACTUAL_CALENDAR_DAYS'),
          generatedCount: result.generated.length,
          failedCount: result.failed.length,
          generatedSample: result.generated
            .slice(0, 10)
            .map((item) => item.id ?? ''),
          failedSample: result.failed
            .slice(0, 10)
            .map((item) => ({
              empid: item.empid,
              reason: item.reason,
            })),
          createdBy: 'admin',
        });
      } catch (snapshotError) {
        console.log('[PAYROLL] snapshot save failed', {
          error: snapshotError,
        });
      }

      res.status(200).json({
        success: true,

        message:
          'Previous month payroll generated successfully',

        period,

        data: result,
      });
    } catch (error) {
      next(error);
    }
  };

export const listMonthlyPayroll =
  async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const companyId = String(
        req.query.companyId ??
        (req as any)
          .user?.companyId ??
        '',
      );

      if (!companyId) {
        res.status(400).json({
          success: false,
          message:
            'companyId is required',
        });

        return;
      }

      const payrolls =
        await getMonthlyPayrolls({
          companyId,

          year:
            Number(req.query.year),

          month:
            Number(req.query.month),
        });

      res.status(200).json({
        success: true,
        count: payrolls.length,
        data: payrolls,
      });
    } catch (error) {
      next(error);
    }
  };

export const listPreviousMonthPayroll =
  async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const companyId = String(
        req.query.companyId ??
        (req as any)
          .user?.companyId ??
        '',
      );

      if (!companyId) {
        res.status(400).json({
          success: false,
          message:
            'companyId is required',
        });

        return;
      }

      const period =
        getPreviousPayrollMonth();

      const payrolls =
        await getMonthlyPayrolls({
          companyId,

          year:
            period.year,

          month:
            period.month,
        });

      res.status(200).json({
        success: true,
        period,
        count: payrolls.length,
        data: payrolls,
      });
    } catch (error) {
      next(error);
    }
  };

export const previewPayroll = async (
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> => {
  try {
    const result = await previewAllEmployeePayroll({
      companyId: req.body.companyId || undefined,
      year: Number(req.body.year),
      month: Number(req.body.month),
      salaryCalculationMethod: req.body.salaryCalculationMethod,
    });

    res.status(200).json({
      success: true,
      message: 'Payroll preview generated successfully',
      data: result,
    });
  } catch (error) {
    next(error);
  }
};

export const savePayrollSnapshotController = async (
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> => {
  try {
    const companyId = String(req.body.companyId ?? '');

    if (!companyId) {
      res.status(400).json({
        success: false,
        message: 'companyId is required',
      });
      return;
    }

    await savePayrollSnapshot({
      companyId,
      year: Number(req.body.year),
      month: Number(req.body.month),
      salaryCalculationMethod:
        String(req.body.salaryCalculationMethod ?? 'ACTUAL_CALENDAR_DAYS') as any,
      generatedCount: Number(req.body.generatedCount ?? 0),
      failedCount: Number(req.body.failedCount ?? 0),
      generatedSample: Array.isArray(req.body.generatedSample)
        ? req.body.generatedSample.map(String)
        : [],
      failedSample: Array.isArray(req.body.failedSample)
        ? req.body.failedSample.map((item: any) => ({
            empid: String(item.empid ?? ''),
            reason: String(item.reason ?? ''),
          }))
        : [],
      createdBy: String(req.body.createdBy ?? 'admin'),
    });

    res.status(200).json({
      success: true,
      message: 'Payroll snapshot saved successfully',
    });
  } catch (error) {
    next(error);
  }
};

export const confirmPayrollPaid =
  async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const paidBy =
        (req as any)
          .user?.empid ??
        (req as any)
          .user?.uid ??
        'admin';

      await markPayrollAsPaid(
        req.params.payrollId,
        paidBy,
      );

      res.status(200).json({
        success: true,
        message:
          'Payroll marked as paid',
      });
    } catch (error) {
      next(error);
    }
  };

export const getMyPayroll = async (
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> => {
  try {
    const empid = (req as any).user?.empid;
    const companyId = (req as any).user?.companyId;

    if (!empid || !companyId) {
      res.status(401).json({
        success: false,
        message: 'Authentication required',
      });
      return;
    }

    const month = Number(req.query.month);
    const year = Number(req.query.year);

    if (!month || !year || month < 1 || month > 12) {
      res.status(400).json({
        success: false,
        message: 'Invalid month or year',
      });
      return;
    }

    console.log('Employee payslip lookup', {
      companyId,
      empid,
      month,
      monthType: typeof month,
      year,
      yearType: typeof year,
      payrollPeriod: `${year}-${String(month).padStart(2, '0')}`,
    });

    const payroll = await getMonthlyPayrolls({
      companyId,
      year,
      month,
    });

    console.log(`Query returned ${payroll.length} payroll records for company ${companyId}, year ${year}, month ${month}`);

    // Filter for the authenticated employee's paid payroll only
    const employeePayroll = payroll.find(
      (p: any) =>
        p.empid === empid &&
        (p.paymentStatus === 'paid' || p.isPaid === true)
    );

    if (!employeePayroll) {
      console.log('No paid payroll found for employee', {
        empid,
        companyId,
        month,
        year,
        foundPayrolls: payroll.map((p: any) => ({ id: p.id, empid: p.empid, paymentStatus: p.paymentStatus, isPaid: p.isPaid })),
      });
      res.status(404).json({
        success: false,
        message: 'No confirmed payslip is available for the selected period',
      });
      return;
    }

    // Normalize paidAt to ISO string for frontend compatibility
    const normalizedPayroll = {
      ...employeePayroll,
      paidAt: employeePayroll.paidAt?.toDate?.().toISOString?.() ?? employeePayroll.paidAt ?? null,
    };

    res.status(200).json(normalizedPayroll);
  } catch (error) {
    next(error);
  }
};