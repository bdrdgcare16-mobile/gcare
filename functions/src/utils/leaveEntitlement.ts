import {
  clipRangeYmd,
  daysInclusive,
  isValidYmd,
  monthRangeYmd,
  normalizeToYmd,
} from './dateYmd';
import { canonicalLeaveTypeName, getCurrentMonthRangeIST, NON_RULE_TYPES } from './leavePeriod';

/**
 * Monthly recurring leave entitlement.
 *
 * A leave type is ONE persistent configuration that renews every calendar
 * month. The allowance of a month is the configured allowance of the version
 * effective in that month:
 *   - a version becomes effective in the month of its stored start date;
 *   - the latest effective version wins (ties: newest createdAt);
 *   - changing an allowance adds a new version effective from the chosen
 *     month, so earlier months keep the allowance they had.
 * Usage is never stored: it is derived per month from the employee's leaves,
 * so each month starts fresh and history is never rewritten.
 */

export interface LeaveRuleDoc {
  id?: string;
  type: string;
  allowedDays?: number | string;
  fromDate?: unknown;
  createdAt?: unknown;
  active?: boolean;
}

export interface LeaveRecordLike {
  leaveType?: string;
  type?: string;
  startDate?: unknown;
  endDate?: unknown;
  status?: unknown;
  approvalStatus?: unknown;
}

const MONTH_NAMES = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const MAX_MONTHS = 120;

export const monthLabel = (ym: string): string =>
  `${MONTH_NAMES[Number(ym.slice(5, 7)) - 1]} ${ym.slice(0, 4)}`;

/** 'YYYY-MM' of the stored start date; '0000-00' when missing (always effective). */
export function ruleStartMonth(rule: LeaveRuleDoc): string {
  const from = normalizeToYmd(rule.fromDate);
  return from ? from.slice(0, 7) : '0000-00';
}

function createdMs(rule: LeaveRuleDoc): number {
  const c: any = rule.createdAt;
  if (!c) return 0;
  if (typeof c.toMillis === 'function') return c.toMillis();
  if (typeof c._seconds === 'number') return c._seconds * 1000;
  if (typeof c.seconds === 'number') return c.seconds * 1000;
  const t = new Date(c).getTime();
  return Number.isNaN(t) ? 0 : t;
}

/** Newest-first ordering used to pick the effective version. */
export function compareVersionsNewestFirst(a: LeaveRuleDoc, b: LeaveRuleDoc): number {
  const byMonth = ruleStartMonth(b).localeCompare(ruleStartMonth(a));
  return byMonth !== 0 ? byMonth : createdMs(b) - createdMs(a);
}

/** The version of `type` in force for month `ym` (YYYY-MM), or null. */
export function resolveRuleForMonth(
  rules: LeaveRuleDoc[],
  type: string,
  ym: string,
): LeaveRuleDoc | null {
  const canonical = canonicalLeaveTypeName(type);
  const effective = rules
    .filter((r) => r.active !== false && canonicalLeaveTypeName(r.type) === canonical)
    .filter((r) => ruleStartMonth(r) <= ym)
    .sort(compareVersionsNewestFirst);
  return effective[0] ?? null;
}

/** Splits [start, end] into per-month segments (handles year changes and leap years). */
export function monthsInRange(
  start: string,
  end: string,
): Array<{ ym: string; start: string; end: string }> {
  const out: Array<{ ym: string; start: string; end: string }> = [];
  if (!isValidYmd(start) || !isValidYmd(end) || end < start) return out;

  let y = Number(start.slice(0, 4));
  let m = Number(start.slice(5, 7));
  const lastYm = end.slice(0, 7);

  for (let i = 0; i < MAX_MONTHS; i++) {
    const range = monthRangeYmd(y, m);
    const ym = range.start.slice(0, 7);
    const clipped = clipRangeYmd(start, end, range.start, range.end);
    if (clipped) out.push({ ym, ...clipped });
    if (ym >= lastYm) break;
    m += 1;
    if (m > 12) {
      m = 1;
      y += 1;
    }
  }
  return out;
}

/** Pending and Approved leaves reserve days; Rejected and Cancelled do not. */
export function isCountedLeave(l: LeaveRecordLike): boolean {
  const s = [l.status, l.approvalStatus].map((v) => String(v ?? '').trim().toLowerCase());
  if (s.some((v) => v === 'rejected' || v === 'cancelled' || v === 'canceled')) return false;
  return s.some((v) => v === 'pending' || v === 'approved');
}

/** Calendar days of `canonicalType` already reserved inside one month. */
export function usageInMonth(
  leaves: LeaveRecordLike[],
  canonicalType: string,
  month: { start: string; end: string },
): number {
  let used = 0;
  for (const l of leaves) {
    if (!isCountedLeave(l)) continue;
    if (canonicalLeaveTypeName(String(l.leaveType ?? l.type ?? '')) !== canonicalType) continue;
    const s = normalizeToYmd(l.startDate);
    const e = normalizeToYmd(l.endDate) || s;
    if (!s) continue;
    const clipped = clipRangeYmd(s, e, month.start, month.end);
    if (clipped) used += daysInclusive(clipped.start, clipped.end);
  }
  return used;
}

export function entitlementForMonth(
  rules: LeaveRuleDoc[],
  leaves: LeaveRecordLike[],
  type: string,
  ym: string,
): { rule: LeaveRuleDoc; allowance: number; used: number; remaining: number } | null {
  const rule = resolveRuleForMonth(rules, type, ym);
  if (!rule) return null;
  const range = monthRangeYmd(Number(ym.slice(0, 4)), Number(ym.slice(5, 7)));
  const allowance = Number(rule.allowedDays) || 0;
  const used = usageInMonth(leaves, canonicalLeaveTypeName(type), range);
  return { rule, allowance, used, remaining: Math.max(0, allowance - used) };
}

/**
 * Validates a leave request against the monthly entitlement of every month it
 * touches. Returns an error message, or null when the request is acceptable.
 *
 *  - Not allowed to start in a month that already ended.
 *  - Any later month or year is allowed.
 *  - For each month: days already reserved + requested days in that month
 *    must not exceed that month's allowance.
 * Types without a configured leave type are not restricted.
 */
export function checkMonthlyEntitlement(args: {
  rules: LeaveRuleDoc[];
  existingLeaves: LeaveRecordLike[];
  request: { leaveType: string; startDate: string; endDate: string };
  now?: Date;
}): string | null {
  const { rules, existingLeaves, request, now = new Date() } = args;
  if (NON_RULE_TYPES.includes(request.leaveType)) return null;

  const requested = canonicalLeaveTypeName(request.leaveType);
  const ofType = rules.filter(
    (r) => r.active !== false && canonicalLeaveTypeName(r.type) === requested,
  );
  if (ofType.length === 0) return null;

  const current = getCurrentMonthRangeIST(now);
  if (request.startDate < current.startYmd) {
    return `${requested} cannot be applied for a month that has already ended. Please choose a date from ${current.startYmd} onwards.`;
  }

  const months = monthsInRange(request.startDate, request.endDate);
  if (months.length === 0) return 'Invalid leave dates.';

  for (const month of months) {
    const rule = resolveRuleForMonth(ofType, requested, month.ym);
    if (!rule) return `${requested} is not available for ${monthLabel(month.ym)}.`;

    const allowance = Number(rule.allowedDays) || 0;
    if (allowance <= 0) continue;

    // Usage is measured over the WHOLE month; the request only asks for its own segment.
    const wholeMonth = monthRangeYmd(Number(month.ym.slice(0, 4)), Number(month.ym.slice(5, 7)));
    const used = usageInMonth(existingLeaves, requested, wholeMonth);
    const asking = daysInclusive(month.start, month.end);
    if (used + asking > allowance) {
      const remaining = Math.max(0, allowance - used);
      return `${requested}: only ${remaining} of ${allowance} day${allowance === 1 ? '' : 's'} remaining for ${monthLabel(month.ym)}.`;
    }
  }

  return null;
}