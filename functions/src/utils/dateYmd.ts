const YMD_RE = /^(\d{4})-(\d{2})-(\d{2})$/;
const IST_OFFSET_MS = 330 * 60 * 1000;
const DAY_MS = 86400000;

const pad2 = (n: number): string => String(n).padStart(2, '0');

/** True only for real calendar dates (rejects 2026-02-30, 2026-13-01, ...). */
export function isValidYmd(v: unknown): v is string {
  if (typeof v !== 'string') return false;
  const m = YMD_RE.exec(v);
  if (!m) return false;
  const d = new Date(Date.UTC(Number(m[1]), Number(m[2]) - 1, Number(m[3])));
  return utcToYmd(d) === v;
}

export function ymdToUtc(ymd: string): Date {
  const m = YMD_RE.exec(ymd);
  if (!m) throw new Error(`Invalid YYYY-MM-DD: ${ymd}`);
  return new Date(Date.UTC(Number(m[1]), Number(m[2]) - 1, Number(m[3])));
}

export function utcToYmd(d: Date): string {
  return `${String(d.getUTCFullYear()).padStart(4, '0')}-${pad2(d.getUTCMonth() + 1)}-${pad2(d.getUTCDate())}`;
}

export function addDaysYmd(ymd: string, days: number): string {
  return utcToYmd(new Date(ymdToUtc(ymd).getTime() + days * DAY_MS));
}

/** Inclusive list of dates; [] when either side is invalid or end < start. */
export function eachYmd(start: string, end: string): string[] {
  if (!isValidYmd(start) || !isValidYmd(end) || end < start) return [];
  const out: string[] = [];
  const last = ymdToUtc(end).getTime();
  for (let t = ymdToUtc(start).getTime(); t <= last; t += DAY_MS) {
    out.push(utcToYmd(new Date(t)));
  }
  return out;
}

/** Number of calendar days in [start, end], 0 when invalid. */
export function daysInclusive(start: string, end: string): number {
  if (!isValidYmd(start) || !isValidYmd(end) || end < start) return 0;
  return Math.round((ymdToUtc(end).getTime() - ymdToUtc(start).getTime()) / DAY_MS) + 1;
}

/** First and last day of a month; month is 1-12. Handles leap years. */
export function monthRangeYmd(year: number, month: number): { start: string; end: string } {
  const start = new Date(Date.UTC(year, month - 1, 1));
  const end = new Date(Date.UTC(year, month, 0));
  return { start: utcToYmd(start), end: utcToYmd(end) };
}

/** Today's calendar date in IST (the business timezone of this app). */
export function istTodayYmd(now: Date = new Date()): string {
  return utcToYmd(new Date(now.getTime() + IST_OFFSET_MS));
}

/** Intersection of [start, end] with [from, to]; null when they do not overlap. */
export function clipRangeYmd(
  start: string,
  end: string,
  from: string,
  to: string,
): { start: string; end: string } | null {
  const s = start > from ? start : from;
  const e = end < to ? end : to;
  return s <= e ? { start: s, end: e } : null;
}

/**
 * Reduces a stored date value to its calendar date.
 *  - 'YYYY-MM-DD' and zone-less ISO strings keep the date the user picked.
 *  - Firestore Timestamps, Dates and zoned ISO strings use their UTC date,
 *    matching how date-only values are persisted (UTC midnight).
 */
export function normalizeToYmd(v: any): string {
  if (v == null || v === '') return '';
  try {
    if (typeof v === 'string') {
      const s = v.trim();
      if (/^\d{4}-\d{2}-\d{2}(?:$|[T ][\d:.]*$)/.test(s)) return s.slice(0, 10);
      const d = new Date(s);
      return Number.isNaN(d.getTime()) ? '' : utcToYmd(d);
    }
    if (typeof v.toDate === 'function') return utcToYmd(v.toDate());
    if (typeof v === 'object' && typeof v._seconds === 'number') {
      return utcToYmd(new Date(v._seconds * 1000));
    }
    const d = new Date(v);
    return Number.isNaN(d.getTime()) ? '' : utcToYmd(d);
  } catch {
    return '';
  }
}