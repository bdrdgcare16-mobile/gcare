import { onSchedule } from 'firebase-functions/v2/scheduler';
import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../config/firebase';
import { attendanceIsDue, isOpenAttendance } from '../services/attendanceSession';
import { GPS_STALE_AFTER_MIN } from '../controllers/trackingController';
import { notifyCompanyAdminsOfTrackingInterruption } from '../services/notification.service';

/**
 * Missing-heartbeat monitor for live tracking sessions.
 *
 * The devices post to /tracking/pos every ~15 min; any authenticated
 * contact (append, throttle, same-spot skip, event) refreshes
 * lastUpdateAt. A session with an open endedAt and lastUpdateAt older
 * than HEARTBEAT_STALE_AFTER_MIN means ~3 consecutive ticks produced no
 * contact - device offline, app swiped away, dead battery, Doze, or
 * force-stop. We CANNOT distinguish those causes, so the notification
 * only says "Tracking Interrupted / Location updates missing" - never
 * claims a specific cause.
 *
 * Duplicate suppression: the doc carries `interruption { since,
 * alertSent, alertedAt }`. The sweep skips docs already flagged for the
 * CURRENT gap, so a multi-hour outage produces exactly one alert per
 * session. The next /pos contact clears the flag and emits
 * "Tracking Resumed" (see trackingAppendPos).
 *
 * Cost: one scheduled invocation every 15 min (96/day) + one indexed
 * query returning only stale open sessions (typically zero). Cloud
 * Scheduler + function invocations are free-tier negligible at this
 * cadence even at fleet scale, since the query is index-bounded.
 */

const TRACKING_COL = 'tracking';
const ATT_COL = 'attendance';
const EMP_COL = 'employees';

/** Configurable threshold - keep >= 2.5x the 15-min post cadence so a
 *  single Doze-deferred tick cannot alert. */
export const HEARTBEAT_STALE_AFTER_MIN = 45;

/** Gaps older than 24h are abandoned sessions (forgotten check-out,
 *  dead device), not actionable interruptions. The sweep query bounds
 *  lastUpdateAt to (floor, cutoff) so they are never scanned or flagged. */
const INTERRUPTION_ALERT_MAX_AGE_MS = 24 * 60 * 60000;

/** Page size per query; cursor pagination continues within a run. */
const SWEEP_BATCH_LIMIT = 300;

/** Hard bound on pages per run (~3000 docs); leftovers go to the next sweep. */
const MAX_SWEEP_PAGES = 10;

function activeAttendanceExists(
  attendanceRowsSnap: { empty: boolean; docs: Array<{ data: () => any }> },
): boolean {
  if (attendanceRowsSnap.empty) return false;
  for (const d of attendanceRowsSnap.docs) {
    const data = d.data() as any;
    if (isOpenAttendance(data) && !attendanceIsDue(data)) return true;
  }
  return false;
}

/**
 * One sweep over stale open sessions. Exported for tests and for manual
 * invocation; never throws (a failing sweep must not cascade).
 */
export async function runTrackingHeartbeatSweep(
  now: Date = new Date(),
  opts?: { staleAfterMin?: number },
): Promise<{
  scanned: number; alerted: number; alreadyAlerted: number;
  noActiveAttendance: number; errors: number;
}> {
  const out = {
    scanned: 0, alerted: 0, alreadyAlerted: 0,
    noActiveAttendance: 0, errors: 0,
  };
  const staleAfterMin = opts?.staleAfterMin ?? HEARTBEAT_STALE_AFTER_MIN;
  const cutoffIso =
    new Date(now.getTime() - staleAfterMin * 60000).toISOString();
  // Lower bound on the gap: a session whose last contact is more than
  // INTERRUPTION_ALERT_MAX_AGE_MS old is abandoned (forgotten check-out,
  // dead/uninstalled device) - not an actionable interruption. Bounding
  // lastUpdateAt on BOTH sides keeps the query on the existing
  // (endedAt, companyId, lastUpdateAt) composite index - same three
  // fields, no new index required - and means abandoned docs are never
  // scanned, never flagged, and can never emit a false "Tracking
  // Resumed" later (recovery requires interruption.alertSent, which a
  // skipped doc never receives).
  const floorIso =
    new Date(now.getTime() - INTERRUPTION_ALERT_MAX_AGE_MS).toISOString();

  // Index-backed: (endedAt ASC, companyId ASC, lastUpdateAt ASC) in
  // firestore.indexes.json. Only OPEN sessions are ever scanned, ordered
  // by lastUpdateAt so the most-stale sessions are always processed first
  // regardless of which company they belong to.
  //
  // companyId >= '' excludes legacy tracking docs ({empid}_{date} ids,
  // no companyId field): Firestore inequality predicates never match
  // documents where the field is absent. Without this, ~1800 stale
  // legacy sessions (all un-attributable, all skipped below) permanently
  // fill the batch and starve new-format sessions.
  //
  // Cursor pagination handles the remaining >300-eligible case: a single
  // LIMIT page ordered companyId-major would starve later companies.
  // Pages are bounded (MAX_SWEEP_PAGES) so a runaway scan can never run
  // long - leftovers are picked up by the next 15-min sweep anyway.
  let lastDoc: any = null;
  let pages = 0;
  let snap: any = { empty: true, docs: [], size: 0 };
  do {
    try {
      let q = db
        .collection(TRACKING_COL)
        .where('endedAt', '==', null)
        .where('companyId', '>=', '')
        .where('lastUpdateAt', '>', floorIso)
        .where('lastUpdateAt', '<', cutoffIso)
        .limit(SWEEP_BATCH_LIMIT);
      if (lastDoc) q = q.startAfter(lastDoc);
      snap = await q.get();
    } catch (err: any) {
      console.error('[HEARTBEAT] sweep query failed:', err?.message || String(err));
      return out;
    }
    pages++;

    for (const docSnap of snap.docs) {
    out.scanned++;
    try {
      const data = docSnap.data() as any;
      const empid = String(data?.empid || '').trim();
      const companyId = String(data?.companyId || '').trim();
      const dateIso = String(data?.dateIso || '').trim();
      const lastUpdateAt = String(data?.lastUpdateAt || '').trim();
      if (!empid || !companyId || !dateIso || !lastUpdateAt) continue;

      // One alert per gap: already flagged for THIS interruption -> skip.
      if (data?.interruption?.alertSent === true) {
        out.alreadyAlerted++;
        continue;
      }

      // Only alert when attendance says the employee is still working -
      // an orphaned open session (e.g. logout without check-out) is not
      // an interruption worth paging admins about.
      const attSnap = await db
        .collection(ATT_COL)
        .where('empid', '==', empid)
        .where('companyId', '==', companyId)
        .where('date', '==', dateIso)
        .limit(1)
        .get();
      if (!activeAttendanceExists(attSnap)) {
        out.noActiveAttendance++;
        continue;
      }

      // Claim the flag atomically: a /pos contact racing this sweep may
      // have already cleared/resolved the gap. Re-read inside the tx and
      // only mark when the doc is still open, unflagged, and unchanged.
      let claimed = false;
      await db.runTransaction(async (tx) => {
        const fresh: any = await tx.get(docSnap.ref);
        const d = fresh.data() as any;
        if (!fresh.exists || d?.endedAt != null) return;
        if (d?.interruption?.alertSent === true) return;
        if (String(d?.lastUpdateAt || '') !== lastUpdateAt) return;
        tx.update(docSnap.ref, {
          interruption: {
            since: lastUpdateAt,
            alertSent: true,
            alertedAt: now.toISOString(),
          },
        });
        claimed = true;
      });
      if (!claimed) continue;

      let employeeName = empid;
      try {
        const empSnap = await db
          .collection(EMP_COL)
          .where('empid', '==', empid)
          .where('companyId', '==', companyId)
          .limit(1)
          .get();
        const n = empSnap.docs[0]?.data()?.name;
        if (n) employeeName = String(n);
      } catch (_) { /* name lookup best-effort */ }

      await notifyCompanyAdminsOfTrackingInterruption({
        companyId,
        empid,
        employeeName,
        kind: 'interrupted',
        sinceTs: lastUpdateAt,
        dateIso,
      });
      out.alerted++;
    } catch (err: any) {
      out.errors++;
      console.error('[HEARTBEAT] doc sweep failed:', docSnap.id,
        err?.message || String(err));
    }
    }

    lastDoc = snap.docs[snap.docs.length - 1] ?? lastDoc;
  } while (!snap.empty && snap.size >= SWEEP_BATCH_LIMIT && pages < MAX_SWEEP_PAGES);

  if (!snap.empty && snap.size >= SWEEP_BATCH_LIMIT && pages >= MAX_SWEEP_PAGES) {
    console.warn('[HEARTBEAT] sweep page bound reached - ' +
      `${MAX_SWEEP_PAGES * SWEEP_BATCH_LIMIT} docs scanned, leftovers next run`);
  }

  if (out.scanned || out.alerted) {
    console.log('[HEARTBEAT] sweep result', {
      staleAfterMin, cutoffIso, pages, ...out,
    });
  }
  return out;
}

/**
 * Cleanup pass: clear stale interruption flags on sessions that are
 * already CLOSED (endedAt set). checkOut and the attendance trigger both
 * delete the field, but a doc that was flagged after check-out via a
 * race, or closed by a legacy path, can retain it forever. Open-session
 * flags are left strictly alone - they are the dedup state.
 */
export async function runInterruptionCleanup(
  opts?: { limit?: number },
): Promise<{ cleared: number }> {
  const out = { cleared: 0 };
  try {
    const snap = await db
      .collection(TRACKING_COL)
      .where('interruption.alertSent', '==', true)
      .limit(opts?.limit ?? 200)
      .get();
    for (const docSnap of snap.docs) {
      try {
        if (docSnap.data()?.endedAt == null) continue; // open gap - keep flag
        await docSnap.ref.update({
          interruption: FieldValue.delete(),
        });
        out.cleared++;
      } catch (_) { /* best-effort */ }
    }
  } catch (err: any) {
    console.error('[HEARTBEAT] cleanup failed:', err?.message || String(err));
  }
  return out;
}

/**
 * The effective "last valid GPS fix" instant for a doc: the explicit
 * lastGpsFixAt (covers fixes skipped by the route filter), then the
 * newest stored point's capture time, then startedAt - a session that
 * never produced a fix gets one grace window from check-in.
 */
function effectiveGpsFixIso(data: any): string {
  const explicit = String(data?.lastGpsFixAt || '').trim();
  if (explicit) return explicit;
  const pathMap = Array.isArray(data?.pathMap) ? data.pathMap : [];
  const lastPoint = pathMap.length ? pathMap[pathMap.length - 1] : null;
  const fromPoint = String(lastPoint?.capturedAt || lastPoint?.ts || '').trim();
  if (fromPoint) return fromPoint;
  return String(data?.startedAt || '').trim();
}

/**
 * GPS-gap sweep: sessions whose device KEEPS CONTACTING (fresh
 * lastUpdateAt/lastHeartbeatAt) but has produced no valid GPS fix past
 * GPS_STALE_AFTER_MIN. This is the "service alive, GPS dead" case the
 * contact sweep cannot see: indoor lock loss, a stalled provider, or an
 * unreported GPS toggle.
 *
 * Alert policy (deliberately conservative):
 * - Requires FRESH contact (< GPS_STALE_AFTER_MIN) so a device that is
 *   also silent does not get a mislabeled "GPS delayed" alert - the
 *   45-min contact sweep owns that case.
 * - Skips sessions whose lastGpsState is a CONFIRMED cause
 *   (service_off / perm_denied): admins already got the GPS-OFF or
 *   permission-revoked notification; a gap alert would be noise.
 * - One alert per gap via `gpsGap { since, alertSent, alertedAt }`,
 *   cleared by the next fresh fix in /pos or /heartbeat which emits
 *   "GPS Updates Recovered".
 * - Same attendance guard + closed-session exclusion as the contact
 *   sweep: never alert after check-out.
 */
export async function runGpsGapSweep(
  now: Date = new Date(),
  opts?: { staleAfterMin?: number },
): Promise<{
  scanned: number; alerted: number; alreadyAlerted: number;
  noActiveAttendance: number; contactStale: number;
  confirmedCause: number; errors: number;
}> {
  const out = {
    scanned: 0, alerted: 0, alreadyAlerted: 0, noActiveAttendance: 0,
    contactStale: 0, confirmedCause: 0, errors: 0,
  };
  const staleAfterMin = opts?.staleAfterMin ?? GPS_STALE_AFTER_MIN;
  const cutoffMs = now.getTime() - staleAfterMin * 60000;
  const cutoffIso = new Date(cutoffMs).toISOString();

  // Index-backed: (endedAt ASC, companyId ASC, startedAt ASC) in
  // firestore.indexes.json. startedAt is present on every session doc
  // (including pre-upgrade docs with no lastGpsFixAt), so sessions that
  // never obtained a single fix are covered too. The precise freshness
  // check happens inside the claim transaction below.
  let lastDoc: any = null;
  let pages = 0;
  let snap: any = { empty: true, docs: [], size: 0 };
  do {
    try {
      let q = db
        .collection(TRACKING_COL)
        .where('endedAt', '==', null)
        .where('companyId', '>=', '')
        .where('startedAt', '<', cutoffIso)
        .limit(SWEEP_BATCH_LIMIT);
      if (lastDoc) q = q.startAfter(lastDoc);
      snap = await q.get();
    } catch (err: any) {
      console.error('[GPS-GAP] sweep query failed:', err?.message || String(err));
      return out;
    }
    pages++;

    for (const docSnap of snap.docs) {
    out.scanned++;
    try {
      const data = docSnap.data() as any;
      const empid = String(data?.empid || '').trim();
      const companyId = String(data?.companyId || '').trim();
      const dateIso = String(data?.dateIso || '').trim();
      if (!empid || !companyId || !dateIso) continue;

      // Contact must be FRESH for this to be a GPS problem rather than a
      // contact interruption (owned by the 45-min sweep above).
      const lastContactIso = String(
        data?.lastHeartbeatAt || data?.lastUpdateAt || '').trim();
      const contactMs = Date.parse(lastContactIso);
      if (!Number.isFinite(contactMs) || contactMs < cutoffMs) {
        out.contactStale++;
        continue;
      }

      // Effective GPS freshness - a stationary employee's skipped fixes
      // refresh lastGpsFixAt, so they never reach this point.
      const fixIso = effectiveGpsFixIso(data);
      const fixMs = Date.parse(fixIso);
      if (Number.isFinite(fixMs) && fixMs >= cutoffMs) continue;

      // One alert per gap.
      if (data?.gpsGap?.alertSent === true) {
        out.alreadyAlerted++;
        continue;
      }

      // Confirmed causes already produced their own notification.
      const gpsState = String(data?.lastGpsState || '');
      if (gpsState === 'service_off' || gpsState === 'perm_denied') {
        out.confirmedCause++;
        continue;
      }

      // Only alert while attendance says the employee is still working.
      const attSnap = await db
        .collection(ATT_COL)
        .where('empid', '==', empid)
        .where('companyId', '==', companyId)
        .where('date', '==', dateIso)
        .limit(1)
        .get();
      if (!activeAttendanceExists(attSnap)) {
        out.noActiveAttendance++;
        continue;
      }

      // Claim the flag atomically: a fresh fix racing this sweep may
      // already have cleared the gap. Re-verify inside the tx.
      let claimed = false;
      await db.runTransaction(async (tx) => {
        const fresh: any = await tx.get(docSnap.ref);
        const d = fresh.data() as any;
        if (!fresh.exists || d?.endedAt != null) return;
        if (d?.gpsGap?.alertSent === true) return;
        const freshContact = Date.parse(
          String(d?.lastHeartbeatAt || d?.lastUpdateAt || ''));
        if (!Number.isFinite(freshContact) || freshContact < cutoffMs) return;
        if (effectiveGpsFixIso(d) !== fixIso) return; // fix arrived - skip
        tx.update(docSnap.ref, {
          gpsGap: {
            since: fixIso,
            alertSent: true,
            alertedAt: now.toISOString(),
          },
        });
        claimed = true;
      });
      if (!claimed) continue;

      let employeeName = empid;
      try {
        const empSnap = await db
          .collection(EMP_COL)
          .where('empid', '==', empid)
          .where('companyId', '==', companyId)
          .limit(1)
          .get();
        const n = empSnap.docs[0]?.data()?.name;
        if (n) employeeName = String(n);
      } catch (_) { /* name lookup best-effort */ }

      await notifyCompanyAdminsOfTrackingInterruption({
        companyId,
        empid,
        employeeName,
        kind: 'gps_delayed',
        sinceTs: fixIso,
        dateIso,
      });
      out.alerted++;
    } catch (err: any) {
      out.errors++;
      console.error('[GPS-GAP] doc sweep failed:', docSnap.id,
        err?.message || String(err));
    }
    }

    lastDoc = snap.docs[snap.docs.length - 1] ?? lastDoc;
  } while (!snap.empty && snap.size >= SWEEP_BATCH_LIMIT && pages < MAX_SWEEP_PAGES);

  if (out.scanned || out.alerted) {
    console.log('[GPS-GAP] sweep result', {
      staleAfterMin, cutoffIso, pages, ...out,
    });
  }
  return out;
}

export const trackingHeartbeatMonitor = onSchedule(
  {
    schedule: 'every 15 minutes',
    region: 'us-central1',
    retryCount: 1,
    // Worst-case run pages through MAX_SWEEP_PAGES x SWEEP_BATCH_LIMIT
    // docs (each needing a tx + attendance + employee + notify round
    // trip) - ~30s per full page measured on the emulator. 540s covers
    // ~10 pages with headroom; the default 60s would kill mid-run.
    timeoutSeconds: 540,
  },
  async () => {
    await runTrackingHeartbeatSweep();
    await runGpsGapSweep();
    await runInterruptionCleanup();
  },
);
