import {
  Request,
  Response,
  NextFunction,
} from 'express';

export const validatePayrollMonth = (
  req: Request,
  res: Response,
  next: NextFunction,
): void => {
  const year = Number(
    req.body.year ??
    req.query.year,
  );

  const month = Number(
    req.body.month ??
    req.query.month,
  );

  if (
    !Number.isInteger(year) ||
    year < 2000
  ) {
    res.status(400).json({
      success: false,
      message:
        'Valid payroll year is required',
    });

    return;
  }

  if (
    !Number.isInteger(month) ||
    month < 1 ||
    month > 12
  ) {
    res.status(400).json({
      success: false,
      message:
        'Payroll month must be between 1 and 12',
    });

    return;
  }

  next();
};

export const validateSalaryCalculationMethod = (
  req: Request,
  res: Response,
  next: NextFunction,
): void => {
  const rawMethod = String(req.body.salaryCalculationMethod ?? 'ACTUAL_CALENDAR_DAYS').trim();
  const allowedMethods = new Set([
    'ACTUAL_CALENDAR_DAYS',
    'FIXED_30_DAYS',
    'SCHEDULED_WORKING_DAYS',
  ]);

  if (!allowedMethods.has(rawMethod)) {
    res.status(400).json({
      success: false,
      message:
        'salaryCalculationMethod must be one of ACTUAL_CALENDAR_DAYS, FIXED_30_DAYS, or SCHEDULED_WORKING_DAYS',
    });
    return;
  }

  next();
};