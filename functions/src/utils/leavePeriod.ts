import { istTodayYmd, monthRangeYmd } from './dateYmd';

/**
 * Current calendar month in IST as {start,end} YYYY-MM-DD plus UTC-midnight
 * Date objects (the way leave type dates are persisted).
 */
export function getCurrentMonthRangeIST(now: Date = new Date()): {
  start: Date;
  end: Date;
  startYmd: string;
  endYmd: string;
} {
  const today = istTodayYmd(now);
  const { start, end } = monthRangeYmd(Number(today.slice(0, 4)), Number(today.slice(5, 7)));
  return {
    start: new Date(`${start}T00:00:00.000Z`),
    end: new Date(`${end}T00:00:00.000Z`),
    startYmd: start,
    endYmd: end,
  };
}

/**
 * Normalises a leave type name so Admin spellings and the names the Apply
 * Leave screen submits resolve to the same entitlement bucket.
 * Emergency, Planned, Casual and Sick are four independent leave types.
 */
export function canonicalLeaveTypeName(raw: string): string {
  const norm = String(raw ?? '').toLowerCase().replace(/[^a-z]/g, '');
  switch (norm) {
    case 'casual':
    case 'casualleave':
      return 'Casual Leave';
    case 'sick':
    case 'sickleave':
      return 'Sick Leave';
    case 'planned':
    case 'plannedleave':
      return 'Planned Leave';
    case 'emergency':
    case 'emergencyleave':
      return 'Emergency Leave';
    default:
      return String(raw ?? '').trim();
  }
}

/** Request types that are not governed by a monthly leave-type allowance. */
export const NON_RULE_TYPES = ['Overtime', 'Permission Time', 'Half-Day', 'Comp Off'];