import { Timestamp } from 'firebase-admin/firestore';

export type LeavePayType =
  | 'paid'
  | 'unpaid'
  | null;

export type PayrollPaymentStatus =
  | 'pending'
  | 'paid';

export type PayrollCalculationSource =
  | 'automatic'
  | 'admin-edited'
  | 'manual';

export type SalaryCalculationMethod =
  | 'ACTUAL_CALENDAR_DAYS'
  | 'FIXED_30_DAYS'
  | 'SCHEDULED_WORKING_DAYS';

export interface PayrollAllowance {
  type: string;
  amount: number;
  remarks?: string;
}

export interface PayrollDailyBreakdown {
  date: string;

  attendanceStatus: string | null;
  leavePayType: LeavePayType;

  resolvedStatus:
    | 'present'
    | 'paid-leave'
    | 'unpaid-leave'
    | 'absent'
    | 'half-day'
    | 'holiday'
    | 'week-off'
    | 'not-applicable';

  workedValue: number;
  paidLeaveValue: number;
  unpaidLeaveValue: number;
  absentValue: number;
  lopValue: number;
  payableValue: number;
}

export interface PayrollData {
  id?: string;

  companyId: string;
  empid: string;
  employeeName: string;

  year: number;
  month: number;
  payrollPeriod: string;

  startDate: string;
  endDate: string;

  totalCalendarDays: number;
  eligibleDays: number;

  workedDays: number;

  paidLeaveDays: number;
  unpaidLeaveDays: number;

  absentDays: number;
  halfDays: number;

  holidayDays: number;
  weekOffDays: number;

  lopDays: number;
  payableDays: number;

  basicSalary: number;

  allowances: PayrollAllowance[];
  totalAllowance: number;

  perDaySalary?: number;
  earnedBasic?: number;
  hra?: number;
  otherAllowances?: number;
  earnedAllowance?: number;
  grossSalary?: number;
  lopDeduction?: number;
  totalDeductions?: number;
  netSalary?: number;
  salaryCalculationMethod?: SalaryCalculationMethod;

  paymentStatus: PayrollPaymentStatus;
  isPaid: boolean;

  calculationSource:
    PayrollCalculationSource;

  dailyBreakdown:
    PayrollDailyBreakdown[];

  generatedAt?: Timestamp;
  updatedAt?: Timestamp;

  paidAt?: Timestamp;
  paidBy?: string;

  editedAt?: Timestamp;
  editedBy?: string;
  editReason?: string;
}