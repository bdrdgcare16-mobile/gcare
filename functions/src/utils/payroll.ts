export const normalizePayrollValue = (
  value: unknown,
): string => {
  return String(value ?? '')
    .trim()
    .toLowerCase()
    .replace(/[_-]+/g, ' ')
    .replace(/\s+/g, ' ');
};

export const roundPayrollValue = (
  value: number,
): number => {
  return Math.round(value * 2) / 2;
};

export const padPayrollNumber = (
  value: number,
): string => {
  return String(value).padStart(2, '0');
};

export const formatPayrollDate = (
  date: Date,
): string => {
  return [
    date.getFullYear(),
    padPayrollNumber(
      date.getMonth() + 1,
    ),
    padPayrollNumber(date.getDate()),
  ].join('-');
};

export const parsePayrollDate = (
  value: string,
): Date => {
  const [year, month, day] = value
    .split('-')
    .map(Number);

  return new Date(
    year,
    month - 1,
    day,
  );
};

export const getPayrollMonthRange = (
  year: number,
  month: number,
): {
  startDate: string;
  endDate: string;
  totalCalendarDays: number;
} => {
  const totalCalendarDays =
    new Date(year, month, 0).getDate();

  return {
    startDate:
      `${year}-${padPayrollNumber(month)}-01`,

    endDate:
      `${year}-${padPayrollNumber(month)}-` +
      padPayrollNumber(
        totalCalendarDays,
      ),

    totalCalendarDays,
  };
};

export const getPreviousPayrollMonth =
  (): {
    year: number;
    month: number;
  } => {
    const now = new Date();

    const previousMonth = new Date(
      now.getFullYear(),
      now.getMonth() - 1,
      1,
    );

    return {
      year:
        previousMonth.getFullYear(),

      month:
        previousMonth.getMonth() + 1,
    };
  };

export const getPayrollDateList = (
  startDate: string,
  endDate: string,
): string[] => {
  const start =
    parsePayrollDate(startDate);

  const end =
    parsePayrollDate(endDate);

  const dates: string[] = [];

  for (
    let current = new Date(start);
    current <= end;
    current.setDate(
      current.getDate() + 1,
    )
  ) {
    dates.push(
      formatPayrollDate(current),
    );
  }

  return dates;
};

export const createPayrollDocumentId = (
  companyId: string,
  empid: string,
  year: number,
  month: number,
): string => {
  return [
    companyId,
    empid,
    year,
    padPayrollNumber(month),
  ].join('_');
};