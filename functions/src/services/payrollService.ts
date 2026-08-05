import { FieldValue } from "firebase-admin/firestore";
import { db } from "../config/firebase";

import { PayrollDailyBreakdown, PayrollData, SalaryCalculationMethod } from "../models/payroll";

import {
  createPayrollDocumentId,
  getPayrollDateList,
  getPayrollMonthRange,
  normalizePayrollValue,
  padPayrollNumber,
  roundPayrollValue,
} from "../utils/payroll";

/**
 * Shared helper to preserve payment state when upserting payroll records.
 * This ensures that once a payroll is paid, it never reverts to pending.
 * 
 * Safety rule: Any record with paidAt AND paidBy present is treated as paid,
 * even if paymentStatus was accidentally reset to pending by old code.
 */
export function resolvePreservedPaymentState(
  existingData?: PayrollData | null,
): {
  paymentStatus: 'paid' | 'pending';
  isPaid: boolean;
  paidAt: any;
  paidBy: string | undefined;
} {
  const alreadyPaid =
    existingData?.paymentStatus === 'paid' ||
    existingData?.isPaid === true ||
    (
      existingData?.paidAt != null &&
      existingData?.paidBy != null
    );

  if (alreadyPaid) {
    return {
      paymentStatus: 'paid',
      isPaid: true,
      paidAt: existingData?.paidAt ?? null,
      paidBy: existingData?.paidBy ?? undefined,
    };
  }

  return {
    paymentStatus: 'pending',
    isPaid: false,
    paidAt: null,
    paidBy: undefined,
  };
}

/**
 * Global payroll upsert helper that preserves payment state using a transaction.
 * This prevents race conditions between Generate Payroll and Confirm Paid operations.
 * 
 * If the payroll is already paid, it returns the existing data without modification (immutable).
 * If the payroll is pending or new, it writes the calculated data with pending status.
 */
export async function upsertPayrollPreservingPaymentState(
  payrollId: string,
  calculatedPayroll: PayrollData,
): Promise<PayrollData> {
  const ref = db.collection('payrolls').doc(payrollId);

  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);

    const existing = snapshot.exists
      ? snapshot.data() as PayrollData
      : null;

    const paymentState = resolvePreservedPaymentState(existing);

    // If already paid, return existing data without modification (immutable)
    if (paymentState.paymentStatus === 'paid' && existing) {
      return {
        id: snapshot.id,
        ...existing,
      };
    }

    // Otherwise, write the calculated data with preserved payment state
    const writeData: any = {
      ...calculatedPayroll,
      ...paymentState,
      updatedAt: FieldValue.serverTimestamp(),
    };

    transaction.set(
      ref,
      writeData,
      { merge: true },
    );

    // Return the calculated payroll (without FieldValue for updatedAt)
    return {
      id: payrollId,
      ...calculatedPayroll,
      ...paymentState,
    };
  });
}

const dayOfWeekFromYMD = (ymd: string): number => {
  const [year, month, day] = ymd.split("-").map(Number);
  return new Date(Date.UTC(year, month - 1, day)).getUTCDay();
};

// Get weekly-off configuration for a company, fallback to Sunday
const getWeeklyOffDays = async (companyId: string): Promise<number[]> => {
  try {
    const companyDoc = await db.collection('companyProfile').doc(companyId).get();
    if (companyDoc.exists) {
      const companyData = companyDoc.data() as any;
      if (companyData?.weeklyOffConfig?.days && Array.isArray(companyData.weeklyOffConfig.days)) {
        return companyData.weeklyOffConfig.days;
      }
    }
  } catch (error) {
    console.error('Error fetching weekly-off config:', error);
  }
  // Fallback to Sunday (0)
  return [0];
};

const isWeeklyOff = (ymd: string, weeklyOffDays: number[]): boolean => {
  const dayOfWeek = dayOfWeekFromYMD(ymd);
  return weeklyOffDays.includes(dayOfWeek);
};

const isFutureDate = (ymd: string): boolean => {
  const [year, month, day] = ymd.split("-").map(Number);
  const dateUTC = Date.UTC(year, month - 1, day);
  const now = new Date();
  const todayUTC = Date.UTC(
    now.getUTCFullYear(),
    now.getUTCMonth(),
    now.getUTCDate(),
  );

  return dateUTC > todayUTC;
};

export const normalizeSalaryCalculationMethod = (
  method?: string,
): SalaryCalculationMethod => {
  const raw = String(method ?? 'ACTUAL_CALENDAR_DAYS')
    .trim()
    .toUpperCase()
    .replace(/[- ]+/g, '_');

  if (raw === 'PRO_RATED') {
    return 'ACTUAL_CALENDAR_DAYS';
  }

  if (raw === 'FIXED') {
    return 'FIXED_30_DAYS';
  }

  if (
    raw === 'ACTUAL_CALENDAR_DAYS' ||
    raw === 'FIXED_30_DAYS' ||
    raw === 'SCHEDULED_WORKING_DAYS'
  ) {
    return raw as SalaryCalculationMethod;
  }

  throw new Error(
    'salaryCalculationMethod must be one of ACTUAL_CALENDAR_DAYS, FIXED_30_DAYS, SCHEDULED_WORKING_DAYS',
  );
};

interface EmployeeRecord {
  id?: string;

  companyId: string;
  empid: string;

  employeeName?: string;
  name?: string;

  basicSalary?: number;
  monthlySalary?: number;
  salary?: number;
  salaryDetails?: {
    basicSalary?: number;
  };
  compensation?: {
    basicSalary?: number;
  };

  active?: boolean;
  status?: string;

  joiningDate?: string | null;
  relievingDate?: string | null;
}

interface SalarySource {
  field: string;
  value: unknown;
  location: string;
}

export const resolveMonthlyBasicSalary = (
  employee: EmployeeRecord,
  salaryRecord: Record<string, unknown> | null | undefined,
  salaryRecordLocation: string,
): number => {
  const candidateSources: SalarySource[] = [
    {
      field: 'salaryRecord.basicSalary',
      value: salaryRecord?.basicSalary,
      location: salaryRecordLocation,
    },
    {
      field: 'salaryRecord.monthlySalary',
      value: salaryRecord?.monthlySalary,
      location: salaryRecordLocation,
    },
    {
      field: 'salaryRecord.salary',
      value: (salaryRecord as any)?.salary,
      location: salaryRecordLocation,
    },
    {
      field: 'salaryRecord.grossSalary',
      value: (salaryRecord as any)?.grossSalary,
      location: salaryRecordLocation,
    },
    {
      field: 'salaryRecord.netSalary',
      value: (salaryRecord as any)?.netSalary,
      location: salaryRecordLocation,
    },
    {
      field: 'employee.basicSalary',
      value: employee.basicSalary,
      location: 'employees collection',
    },
    {
      field: 'employee.monthlySalary',
      value: employee.monthlySalary,
      location: 'employees collection',
    },
    {
      field: 'employee.salary',
      value: employee.salary,
      location: 'employees collection',
    },
    {
      field: 'employee.salaryDetails.basicSalary',
      value: employee.salaryDetails?.basicSalary,
      location: 'employees collection',
    },
    {
      field: 'employee.compensation.basicSalary',
      value: employee.compensation?.basicSalary,
      location: 'employees collection',
    },
  ];

  const resolvedSource = candidateSources.find(
    ({ value }) => value !== null && value !== undefined,
  );

  if (!resolvedSource) {
    const debugValues = candidateSources.map((source) => ({
      field: source.field,
      value: source.value,
      location: source.location,
    }));

    throw new Error(
      `Employee ${employee.empid} salary missing: no valid salary field found. Checked fields ${candidateSources
        .map((source) => source.field)
        .join(', ')}; raw values ${JSON.stringify(debugValues)}; salaryRecordLocation=${salaryRecordLocation}`,
    );
  }

  const rawSalary = resolvedSource.value;
  const rawSalaryString = typeof rawSalary === 'string' ? rawSalary.trim() : rawSalary;

  let basicSalary: number;

  if (typeof rawSalaryString === 'number') {
    basicSalary = rawSalaryString;
  } else if (typeof rawSalaryString === 'string') {
    const numericString = rawSalaryString;
    if (!/^[+-]?(?:\d+|\d*\.\d+)$/.test(numericString)) {
      throw new Error(
        `Employee ${employee.empid} salary invalid: checked field ${resolvedSource.field}; raw salary value ${JSON.stringify(
          rawSalary,
        )}; location ${resolvedSource.location}`,
      );
    }

    basicSalary = Number(numericString);
  } else {
    throw new Error(
      `Employee ${employee.empid} salary invalid: checked field ${resolvedSource.field}; raw salary value ${JSON.stringify(
        rawSalary,
      )}; location ${resolvedSource.location}`,
    );
  }

  if (!Number.isFinite(basicSalary) || basicSalary <= 0) {
    throw new Error(
      `Employee ${employee.empid} salary invalid: checked field ${resolvedSource.field}; raw salary value ${JSON.stringify(
        rawSalary,
      )}; location ${resolvedSource.location}; resolvedSalary=${basicSalary}`,
    );
  }

  logResolvedSalaryOnce({
    employeeId: employee.empid,
    employeeBasicSalary: employee.basicSalary,
    employeeMonthlySalary: employee.monthlySalary,
    salaryRecordBasicSalary: salaryRecord?.basicSalary,
    resolvedSalary: basicSalary,
  });

  return basicSalary;
};

let salaryResolutionLogged = false;

const logResolvedSalaryOnce = (logData: {
  employeeId: string;
  employeeBasicSalary: unknown;
  employeeMonthlySalary: unknown;
  salaryRecordBasicSalary: unknown;
  resolvedSalary: number;
}) => {
  if (salaryResolutionLogged) {
    return;
  }

  console.log({
    employeeId: logData.employeeId,
    employeeBasicSalary: logData.employeeBasicSalary,
    employeeMonthlySalary: logData.employeeMonthlySalary,
    salaryRecordBasicSalary: logData.salaryRecordBasicSalary,
    resolvedSalary: logData.resolvedSalary,
  });

  salaryResolutionLogged = true;
};

interface AttendanceRecord {
  id?: string;

  companyId?: string;
  empid?: string;

  date: string;
  status?: string;

  isPresent?: boolean;
  isAbsent?: boolean;
  isLeave?: boolean;
  isHoliday?: boolean;
  isWeekOff?: boolean;
  isHalfDay?: boolean;

  checkIn?: string | null;
}

interface LeaveRecord {
  id?: string;

  companyId?: string;

  empid?: string;
  empId?: string;

  startDate: string;
  endDate: string;

  approvalStatus?: string;
  status?: string;

  leavePayType?: "paid" | "unpaid" | null;
}

const getEmployee = async (
  companyId: string,
  empid: string,
): Promise<EmployeeRecord | null> => {
  const snapshot = await db
    .collection("employees")
    .where("companyId", "==", companyId)
    .where("empid", "==", empid)
    .limit(1)
    .get();

  if (snapshot.empty) {
    return null;
  }

  const document = snapshot.docs[0];

  return {
    id: document.id,
    ...(document.data() as EmployeeRecord),
  };
};

const getActiveEmployees = async (
  companyId?: string,
): Promise<EmployeeRecord[]> => {
  console.log("[PAYROLL] Company ID:", companyId);

  let query: FirebaseFirestore.Query = db.collection("employees");

  if (companyId) {
    query = query.where("companyId", "==", companyId);
  }

  const snapshot = await query.get();

  console.log("[PAYROLL] Employee query count:", snapshot.size);

  const activeEmployees = snapshot.docs
    .map((document) => ({
      id: document.id,
      ...(document.data() as EmployeeRecord),
    }))
    .filter((employee) => {
      const status = String(employee.status ?? "")
        .trim()
        .toLowerCase();

      return (
        status === "active" &&
        Boolean(employee.companyId) &&
        Boolean(employee.empid)
      );
    });

  console.log("[PAYROLL] Active employee count:", activeEmployees.length);

  return activeEmployees;
};

const getEmployeeAttendance = async (
  empid: string,
  startDate: string,
  endDate: string,
): Promise<AttendanceRecord[]> => {
  const snapshot = await db
    .collection("attendance")
    .where("empid", "==", empid)
    .where("date", ">=", startDate)
    .where("date", "<=", endDate)
    .get();

  return snapshot.docs.map((document) => ({
    id: document.id,
    ...(document.data() as AttendanceRecord),
  }));
};

const getApprovedLeaves = async (
  empid: string,
  startDate: string,
  endDate: string,
): Promise<LeaveRecord[]> => {
  const [empidSnapshot, empIdSnapshot] = await Promise.all([
    db
      .collection("leaves")
      .where("empid", "==", empid)
      .where("approvalStatus", "==", "Approved")
      .get(),

    db
      .collection("leaves")
      .where("empId", "==", empid)
      .where("approvalStatus", "==", "Approved")
      .get(),
  ]);

  const uniqueLeaves = new Map<string, LeaveRecord>();

  for (const document of [...empidSnapshot.docs, ...empIdSnapshot.docs]) {
    const leave = {
      id: document.id,
      ...(document.data() as LeaveRecord),
    };

    const overlapsMonth =
      leave.startDate <= endDate && leave.endDate >= startDate;

    if (overlapsMonth) {
      uniqueLeaves.set(document.id, leave);
    }
  }

  return Array.from(uniqueLeaves.values());
};

const resolveAttendanceStatus = (attendance?: AttendanceRecord): string => {
  if (!attendance) {
    return "";
  }

  const status = normalizePayrollValue(attendance.status);

  if (attendance.isHoliday === true || status === "holiday") {
    return "holiday";
  }

  if (
    attendance.isWeekOff === true ||
    status === "week off" ||
    status === "weekoff" ||
    status === "weekly off"
  ) {
    return "week-off";
  }

  if (
    attendance.isHalfDay === true ||
    status === "half day" ||
    status === "halfday"
  ) {
    return "half-day";
  }

  if (attendance.isPresent === true || status === "present") {
    return "present";
  }

  if (attendance.isAbsent === true || status === "absent") {
    return "absent";
  }

  const checkIn = String(attendance.checkIn ?? "").trim();

  if (checkIn && checkIn !== "-" && checkIn.toLowerCase() !== "null") {
    return "present";
  }

  return "";
};

const resolvePayrollDate = (
  date: string,
  attendance?: AttendanceRecord,
  leave?: LeaveRecord,
  weeklyOffDays: number[] = [0], // Default to Sunday
): PayrollDailyBreakdown => {
  const attendanceStatus = resolveAttendanceStatus(attendance);
  const normalizedAttendanceStatus = String(attendanceStatus ?? "").trim().toLowerCase();
  const checkIn = String(attendance?.checkIn ?? "").trim();
  const hasValidCheckIn =
    checkIn.length > 0 &&
    checkIn !== "-" &&
    checkIn.toLowerCase() !== "null";
  const hasAttendanceValue =
    normalizedAttendanceStatus.length > 0 || hasValidCheckIn;
  const isFuture = isFutureDate(date);
  const isHoliday = normalizedAttendanceStatus === "holiday";
  const isWeekOffDate = isWeeklyOff(date, weeklyOffDays);
  const isPaidLeave = leave?.leavePayType === "paid";
  const isUnpaidLeave = leave?.leavePayType === "unpaid";
  const isHalfDay = normalizedAttendanceStatus === "half-day";
  const isPresentAttendance =
    normalizedAttendanceStatus === "present" ||
    hasValidCheckIn;
  const isExplicitAbsent = normalizedAttendanceStatus === "absent";
  const isWeekOffWithoutAttendance = isWeekOffDate && !hasAttendanceValue;

  let resolvedStatus: PayrollDailyBreakdown["resolvedStatus"] = "absent";
  let workedValue = 0;
  let paidLeaveValue = 0;
  let unpaidLeaveValue = 0;
  let absentValue = 0;
  let lopValue = 0;
  let payableValue = 0;
  let leavePayType: "paid" | "unpaid" | null = null;

  if (isFuture) {
    resolvedStatus = "not-applicable";
  } else if (isHoliday) {
    resolvedStatus = "holiday";
    payableValue = 1;
  } else if (isPaidLeave) {
    leavePayType = "paid";
    resolvedStatus = "paid-leave";
    paidLeaveValue = 1;
    payableValue = 1;
  } else if (isUnpaidLeave) {
    leavePayType = "unpaid";
    resolvedStatus = "unpaid-leave";
    unpaidLeaveValue = 1;
    lopValue = 1;
  } else if (isPresentAttendance) {
    resolvedStatus = "present";
    workedValue = 1;
    payableValue = 1;
  } else if (isWeekOffWithoutAttendance) {
    resolvedStatus = "week-off";
    payableValue = 1;
  } else if (isHalfDay) {
    resolvedStatus = "half-day";
    workedValue = 0.5;
    absentValue = 0.5;
    lopValue = 0.5;
    payableValue = 0.5;
  } else if (isExplicitAbsent) {
    resolvedStatus = "absent";
    absentValue = 1;
    lopValue = 1;
  } else {
    resolvedStatus = "absent";
    absentValue = 1;
    lopValue = 1;
  }

  const resolved: PayrollDailyBreakdown = {
    date,

    attendanceStatus: attendanceStatus || null,

    leavePayType,

    resolvedStatus,

    workedValue,
    paidLeaveValue,
    unpaidLeaveValue,
    absentValue,
    lopValue,
    payableValue,
  };

  console.log("[PAYROLL WEEK OFF]", {
    empid: attendance?.empid ?? null,
    date,
    weekday: dayOfWeekFromYMD(date),
    isWeekOff: isWeekOffDate,
    rawAttendanceStatus: attendanceStatus,
    resolvedStatus,
  });

  return resolved;
};

export const calculateEmployeePayroll = async (params: {
  companyId: string;
  empid: string;
  year: number;
  month: number;
  salaryCalculationMethod?: SalaryCalculationMethod;
}): Promise<PayrollData> => {
  const employee = await getEmployee(params.companyId, params.empid);

  if (!employee) {
    throw new Error("Employee not found");
  }

  // Fetch weekly-off configuration for the company
  const weeklyOffDays = await getWeeklyOffDays(params.companyId);

    // Try to fetch onboarding record from employee_onboarding_dev
    let onboardingEmployee: any = null;
    let onboardingDocumentId: string | null = null;
    let onboardingEmployeeIdentifier: string | null = null;
    try {
      // Build queries with companyId validation to prevent cross-company leakage
      const baseQuery = db.collection('employee_onboarding_dev')
        .where('companyId', '==', params.companyId);

      const [q1, q2, q3, q4, q5, q6] = await Promise.all([
        baseQuery.where('empid', '==', params.empid).limit(1).get(),
        baseQuery.where('employeeId', '==', params.empid).limit(1).get(),
        baseQuery.where('uid', '==', params.empid).limit(1).get(),
        baseQuery.where('officialEmail', '==', params.empid).limit(1).get(),
        baseQuery.where('companyDetails.employeeId', '==', params.empid).limit(1).get(),
        baseQuery.where('companyDetails.officialEmail', '==', params.empid).limit(1).get(),
      ]);

      const snaps = [q1, q2, q3, q4, q5, q6];
      const snapFields = [
        'empid',
        'employeeId',
        'uid',
        'officialEmail',
        'companyDetails.employeeId',
        'companyDetails.officialEmail',
      ];

      for (let i = 0; i < snaps.length; i++) {
        const s = snaps[i];
        if (!s.empty) {
          onboardingEmployee = s.docs[0].data();
          onboardingDocumentId = s.docs[0].id;
          onboardingEmployeeIdentifier = snapFields[i] ?? null;
          break;
        }
      }
    } catch (err) {
      console.log('[PAYROLL] onboarding lookup error', { empid: params.empid, err: String(err) });
    }

    // If not found using companyId filter, retry without companyId (some onboarding docs lack companyId)
    if (!onboardingEmployee) {
      try {
        const baseQuery2 = db.collection('employee_onboarding_dev');

        const [r1, r2, r3, r4, r5, r6] = await Promise.all([
          baseQuery2.where('empid', '==', params.empid).limit(1).get(),
          baseQuery2.where('employeeId', '==', params.empid).limit(1).get(),
          baseQuery2.where('uid', '==', params.empid).limit(1).get(),
          baseQuery2.where('officialEmail', '==', params.empid).limit(1).get(),
          baseQuery2.where('companyDetails.employeeId', '==', params.empid).limit(1).get(),
          baseQuery2.where('companyDetails.officialEmail', '==', params.empid).limit(1).get(),
        ]);

        const snaps2 = [r1, r2, r3, r4, r5, r6];
        const snapFields2 = [
          'empid',
          'employeeId',
          'uid',
          'officialEmail',
          'companyDetails.employeeId',
          'companyDetails.officialEmail',
        ];

        for (let i = 0; i < snaps2.length; i++) {
          const s = snaps2[i];
          if (!s.empty) {
            onboardingEmployee = s.docs[0].data();
            onboardingDocumentId = s.docs[0].id;
            onboardingEmployeeIdentifier = snapFields2[i] ?? null;
            break;
          }
        }
      } catch (err) {
        console.log('[PAYROLL] onboarding lookup retry error', { empid: params.empid, err: String(err) });
      }
    }

    // Add MR013 specific diagnostic log as requested (temporary)
    if (String(params.empid) === 'MR013') {
      const bankDetails = onboardingEmployee?.bankDetails ?? null;
      try {
        console.log('MR013 PAYROLL LOOKUP', {
          employeeId: params.empid,
          onboardingDocumentFound: !!onboardingEmployee,
          onboardingDocumentId,
          onboardingEmployeeIdentifier,
          bankDetails,
          bankDetailKeys: Object.keys(bankDetails ?? {}),
        });
      } catch (err) {
        console.log('MR013 PAYROLL LOOKUP (log error)', { err: String(err) });
      }
    }

  const monthRange = getPayrollMonthRange(params.year, params.month);

  let startDate = monthRange.startDate;

  let endDate = monthRange.endDate;

  if (employee.joiningDate && employee.joiningDate > startDate) {
    startDate = employee.joiningDate;
  }

  if (employee.relievingDate && employee.relievingDate < endDate) {
    endDate = employee.relievingDate;
  }

  if (startDate > endDate) {
    throw new Error("Employee is not eligible for this payroll period");
  }

  const [attendanceRecords, leaveRecords] = await Promise.all([
    getEmployeeAttendance(params.empid, startDate, endDate),

    getApprovedLeaves(params.empid, startDate, endDate),
  ]);

  const attendanceByDate = new Map<string, AttendanceRecord>();

  for (const record of attendanceRecords) {
    if (record.date) {
      attendanceByDate.set(record.date, record);
    }
  }

  const leaveByDate = new Map<string, LeaveRecord>();

  for (const leave of leaveRecords) {
    if (leave.leavePayType !== "paid" && leave.leavePayType !== "unpaid") {
      continue;
    }

    const effectiveStart =
      leave.startDate > startDate ? leave.startDate : startDate;

    const effectiveEnd = leave.endDate < endDate ? leave.endDate : endDate;

    const leaveDates = getPayrollDateList(effectiveStart, effectiveEnd);

    for (const leaveDate of leaveDates) {
      leaveByDate.set(leaveDate, leave);
    }
  }

  const dates = getPayrollDateList(startDate, endDate);

  const dailyBreakdown = dates.map((date: string) =>
    resolvePayrollDate(date, attendanceByDate.get(date), leaveByDate.get(date), weeklyOffDays),
  );

  const sum = (selector: (item: PayrollDailyBreakdown) => number): number => {
    return dailyBreakdown.reduce(
      (total: number, item: PayrollDailyBreakdown) => total + selector(item),
      0,
    );
  };

  const workedDays = roundPayrollValue(
    sum((item: PayrollDailyBreakdown) => item.workedValue),
  );

  const paidLeaveDays = roundPayrollValue(
    sum((item: PayrollDailyBreakdown) => item.paidLeaveValue),
  );

  const unpaidLeaveDays = roundPayrollValue(
    sum((item: PayrollDailyBreakdown) => item.unpaidLeaveValue),
  );

  const absentDays = roundPayrollValue(
    sum((item: PayrollDailyBreakdown) => item.absentValue),
  );

  const lopDays = roundPayrollValue(
    sum((item: PayrollDailyBreakdown) => item.lopValue),
  );

  const payableDays = roundPayrollValue(
    sum((item: PayrollDailyBreakdown) => item.payableValue),
  );

  const halfDays = dailyBreakdown.filter(
    (item: PayrollDailyBreakdown) => item.resolvedStatus === "half-day",
  ).length;

  const holidayDays = dailyBreakdown.filter(
    (item: PayrollDailyBreakdown) => item.resolvedStatus === "holiday",
  ).length;

  const weekOffDays = dailyBreakdown.filter(
    (item: PayrollDailyBreakdown) => item.resolvedStatus === "week-off",
  ).length;

  const payrollId = createPayrollDocumentId(
    params.companyId,
    params.empid,
    params.year,
    params.month,
  );

    // Salary sourcing from onboarding bankDetails and employee records
    const salaryRecord = onboardingEmployee?.bankDetails ?? null;

    const basicSalary = resolveMonthlyBasicSalary(
      employee,
      salaryRecord,
      'employee_onboarding_dev.bankDetails',
    );
    const hra = Number(salaryRecord?.hra ?? 0);
    const otherAllowances = Number(salaryRecord?.allowances ?? 0);
    const configuredGrossSalary = Number(salaryRecord?.grossSalary ?? 0);
    const configuredNetSalary = Number(salaryRecord?.netSalary ?? 0);

    // Sanity check configured gross/net vs components
    if (configuredGrossSalary > 0) {
      const compGross = basicSalary + hra + otherAllowances;
      if (Math.abs(compGross - configuredGrossSalary) > 0.5) {
        console.log('[PAYROLL] configured gross mismatch', {
          empid: params.empid,
          basicSalary,
          hra,
          otherAllowances,
          configuredGrossSalary,
          compGross,
        });
      }
    }
    if (configuredNetSalary > 0) {
      if (Math.abs(configuredNetSalary - configuredGrossSalary) > 0.5) {
        console.log('[PAYROLL] configured net/gross mismatch', {
          empid: params.empid,
          configuredNetSalary,
          configuredGrossSalary,
        });
      }
    }

    if (!Number.isFinite(basicSalary) || basicSalary <= 0) {
      throw new Error(`Basic salary missing for employee ${params.empid}`);
    }

    const eligibleDays = dates.length;

    const totalAllowance = hra + otherAllowances;

    const salaryCalculationMethod = normalizeSalaryCalculationMethod(
      params.salaryCalculationMethod,
    );

    const scheduledWorkingDays = eligibleDays - holidayDays - weekOffDays;

  if (
    salaryCalculationMethod === 'SCHEDULED_WORKING_DAYS' &&
    scheduledWorkingDays <= 0
  ) {
    throw new Error(
      'Scheduled working days cannot be calculated for this payroll period',
    );
  }

  const divisor =
    salaryCalculationMethod === 'FIXED_30_DAYS'
      ? 30
      : salaryCalculationMethod === 'SCHEDULED_WORKING_DAYS'
        ? scheduledWorkingDays
        : eligibleDays;

  const perDaySalary = basicSalary / divisor;

  // Calculate LOP deduction based on salary calculation method
  let lopDeduction = 0;
  if (salaryCalculationMethod === 'ACTUAL_CALENDAR_DAYS') {
    lopDeduction = perDaySalary * lopDays;
  } else if (salaryCalculationMethod === 'FIXED_30_DAYS') {
    lopDeduction = perDaySalary * lopDays;
  } else if (salaryCalculationMethod === 'SCHEDULED_WORKING_DAYS') {
    // For scheduled working days, only count LOP on scheduled working days
    const lopWorkingDays = lopDays; // Simplified: assumes all LOP falls on working days
    lopDeduction = perDaySalary * lopWorkingDays;
  }

  // Calculate earned salary based on base days
  // For FIXED_30_DAYS and SCHEDULED_WORKING_DAYS, use full monthly salary then deduct LOP
  // For ACTUAL_CALENDAR_DAYS, use eligibleDays
  const baseDays = salaryCalculationMethod === 'FIXED_30_DAYS' || salaryCalculationMethod === 'SCHEDULED_WORKING_DAYS' 
    ? divisor 
    : eligibleDays;
  const earnedBasic = perDaySalary * baseDays;
  const earnedAllowance = totalAllowance;

  const grossSalary = earnedBasic + earnedAllowance;
  const totalDeductions = 0; // preserve existing deductions handling (none available here)
  const netSalary = grossSalary - lopDeduction - totalDeductions;

  return {
    id: payrollId,

    companyId: params.companyId,

    empid: params.empid,

    employeeName: employee.employeeName ?? employee.name ?? params.empid,

    year: params.year,

    month: params.month,

    payrollPeriod: `${params.year}-` + padPayrollNumber(params.month),

    startDate,
    endDate,

    totalCalendarDays: monthRange.totalCalendarDays,

    eligibleDays: dates.length,

    workedDays,
    paidLeaveDays,
    unpaidLeaveDays,
    absentDays,

    halfDays,
    holidayDays,
    weekOffDays,

    lopDays,
    payableDays,

    basicSalary: basicSalary,

    allowances: [
      { type: 'HRA', amount: hra },
      { type: 'Other Allowances', amount: otherAllowances },
    ],
    totalAllowance: totalAllowance,

    perDaySalary: perDaySalary,
    earnedBasic: earnedBasic,
    hra: hra,
    otherAllowances: otherAllowances,
    earnedAllowance: earnedAllowance,
    grossSalary: grossSalary,

    paymentStatus: "pending",
    isPaid: false,

    calculationSource:
      salaryCalculationMethod === 'FIXED_30_DAYS'
        ? 'admin-edited'
        : 'automatic',
    salaryCalculationMethod,

    dailyBreakdown,

    lopDeduction: lopDeduction,
    totalDeductions: totalDeductions,
    netSalary: netSalary,

    generatedAt: FieldValue.serverTimestamp() as never,

    updatedAt: FieldValue.serverTimestamp() as never,
  };
};

export const generateEmployeePayroll = async (params: {
  companyId: string;
  empid: string;
  year: number;
  month: number;
  salaryCalculationMethod?: SalaryCalculationMethod;
}): Promise<PayrollData> => {
  const payroll = await calculateEmployeePayroll(params);

  if (!payroll.id) {
    throw new Error("Payroll ID not generated");
  }

  // Use the global upsert helper that preserves payment state with transaction
  return upsertPayrollPreservingPaymentState(payroll.id, payroll);
};

export const generateAllEmployeePayroll = async (params: {
  companyId?: string;
  year: number;
  month: number;
  salaryCalculationMethod?: SalaryCalculationMethod;
}) => {
  const employees = await getActiveEmployees(params.companyId);

  const generated: PayrollData[] = [];
  const failed: Array<{ empid: string; reason: string }> = [];

  for (const employee of employees) {
    if (!employee.companyId || !employee.empid) {
      continue;
    }

    try {
      const payroll = await generateEmployeePayroll({
        companyId: employee.companyId,
        empid: employee.empid,
        year: params.year,
        month: params.month,
        salaryCalculationMethod: params.salaryCalculationMethod,
      });

      generated.push(payroll);
    } catch (error) {
      failed.push({
        empid: employee.empid,
        reason:
          error instanceof Error ? error.message : "Payroll generation failed",
      });
    }
  }

  return {
    generated,
    failed,
  };
};

export const previewAllEmployeePayroll = async (params: {
  companyId?: string;
  year: number;
  month: number;
  salaryCalculationMethod?: SalaryCalculationMethod;
}): Promise<{
  generated: PayrollData[];
  failed: Array<{ empid: string; reason: string }>;
}> => {
  const employees = await getActiveEmployees(params.companyId);

  const generated: PayrollData[] = [];
  const failed: Array<{ empid: string; reason: string }> = [];

  for (const employee of employees) {
    if (!employee.companyId || !employee.empid) {
      continue;
    }

    try {
      const payroll = await calculateEmployeePayroll({
        companyId: employee.companyId,
        empid: employee.empid,
        year: params.year,
        month: params.month,
        salaryCalculationMethod: params.salaryCalculationMethod,
      });

      generated.push(payroll);
    } catch (error) {
      failed.push({
        empid: employee.empid,
        reason:
          error instanceof Error ? error.message : 'Payroll preview failed',
      });
    }
  }

  return {
    generated,
    failed,
  };
};

export const savePayrollSnapshot = async (params: {
  companyId: string;
  year: number;
  month: number;
  salaryCalculationMethod: string;
  generatedCount: number;
  failedCount: number;
  generatedSample: string[];
  failedSample: Array<{ empid: string; reason: string }>;
  createdBy?: string;
}): Promise<void> => {
  const normalizedMethod = normalizeSalaryCalculationMethod(
    params.salaryCalculationMethod,
  );

  const snapshotId = `${params.companyId}_${params.year}_${params.month}_${Date.now()}`;

  await db.collection('payrollSnapshots').doc(snapshotId).set({
    companyId: params.companyId,
    year: params.year,
    month: params.month,
    salaryCalculationMethod: normalizedMethod,
    generatedCount: params.generatedCount,
    failedCount: params.failedCount,
    generatedIds: params.generatedSample,
    failed: params.failedSample.slice(0, 50),
    createdBy: params.createdBy ?? 'system',
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
};

export const getMonthlyPayrolls = async (params: {
  companyId: string;
  year: number;
  month: number;
}): Promise<PayrollData[]> => {
  const snapshot = await db
    .collection('payrolls')
    .where('companyId', '==', params.companyId)
    .where('year', '==', params.year)
    .where('month', '==', params.month)
    .get();

  return snapshot.docs.map((document) => ({
    id: document.id,
    ...(document.data() as PayrollData),
  }));
};

export const markPayrollAsPaid = async (
  payrollId: string,
  paidBy: string,
): Promise<void> => {
  const reference = db.collection('payrolls').doc(payrollId);

  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(reference);

    if (!snapshot.exists) {
      throw new Error('Payroll not found');
    }

    const existingData = snapshot.data() as PayrollData;

    // Guard: if already paid, do nothing (idempotent operation)
    const alreadyPaid =
      existingData?.paymentStatus === 'paid' ||
      existingData?.isPaid === true;

    if (alreadyPaid) {
      // Already paid, no update needed
      return;
    }

    transaction.update(reference, {
      paymentStatus: 'paid',
      isPaid: true,
      paidBy,
      paidAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
};
