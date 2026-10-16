import { Request, Response } from 'express';
import { db } from '../config/firebase';
import { FieldValue } from 'firebase-admin/firestore';
import {
  notifyCompanyAdminsOfTrackingEvent,
  notifyCompanyAdminsOfTrackingInterruption,
  notifyCompanyAdminsOfSuspiciousLocation,
} from '../services/notification.service';

export type AuthUser = {
  userId: string;
  email: string;
  role: string;
  empid?: string | null;
  uid?: string; // compat
};

type TrackPoint = {
  lat: number; lng: number; ts: string;
  accuracy?: number; source?: string; pointId?: string;
  /** Client-reported UTC capture time (validated, clamped). */
  capturedAt?: string;
  /** True when the device reported a platform mock-location provider. */
  mocked?: boolean;
  /** Server-assigned suspicion flags - never remove accepted points, only flag. */
  flags?: string[];
  /** Client capture-attempt diagnostics (whitelisted strings only):
   *  captureId, origin, scheduledCaptureAt, actualCaptureStartedAt,
   *  apiRequestStartedAt. Lets a stored point be traced back to the
   *  capture attempt that produced it for cadence auditing. */
  diag?: Record<string, string>;
};

/** A contact from a device clears an open heartbeat interruption. Set by
 *  the sweep, consumed/cleared by the next /pos or /event write. */
type InterruptionState = {
  since: string;       // lastUpdateAt that triggered detection
  alertSent: boolean;  // admin notification already emitted for THIS gap
  alertedAt: string;
};

// Outcome of POST /tracking/pos. HTTP 200 alone does not mean a point was stored.
type AppendStatus = 'appended' | 'duplicate' | 'time_throttled' | 'too_close' | 'session_ended';

type TrackEvent = {
  type: 'poor_gps' | 'gps_disabled' | 'location_disabled' | 'location_enabled' | 'account_logged_out'
      // Location permission revoked mid-session (granted state is implicit
      // in the next successful point - no explicit event needed).
      | 'permission_revoked'
      // Server-generated only - the client /event endpoint never accepts it.
      | 'suspicious_location';
  ts: string;  // ISO timestamp
  message?: string;
  latitude?: number;
  longitude?: number;
};

type TrackDayDoc = {
  id: string;             // {companyId}_{empid}_{YYYY-MM-DD} (new) or empid_YYYY-MM-DD (legacy)
  empid: string;
  companyId?: string;     // tenant owner - absent only on pre-migration legacy docs
  dateIso: string;        // YYYY-MM-DD
  pathMap: TrackPoint[];
  events: TrackEvent[];   // Tracking events array
  startedAt?: string;     // ISO
  endedAt?: string | null;
  lastUpdateAt: string;   // ISO - last authenticated contact (liveness)
  /** ISO - last authenticated device contact. Same instant as
   *  lastUpdateAt, kept as a separate field so admin UI can label it
   *  honestly ("device contact") instead of implying a GPS update. */
  lastHeartbeatAt?: string;
  /** ISO - device-reported capture time of the last VALID GPS fix,
   *  including fixes the route filter skipped (stationary/throttled).
   *  A stationary employee refreshes this without growing pathMap. */
  lastGpsFixAt?: string;
  /** ISO - server receive time of the last point actually appended to
   *  pathMap. Stale while the employee stays in one spot - that is
   *  expected and must never be flagged on its own. */
  lastLocationAt?: string;
  /** Device-reported state at the most recent heartbeat:
   *  ok | no_fix | service_off | perm_denied. Absent on pre-upgrade docs. */
  lastGpsState?: string;
  interruption?: InterruptionState;
  /** Gap where the device KEEPS CONTACTING but produces no valid GPS fix.
   *  Separate dedup state from `interruption` (which is no-contact). */
  gpsGap?: InterruptionState;
  /** flag -> ISO when the admin notification for that flag was emitted.
   *  One notification per flag kind per session - dedup state, so a
   *  spoofed fix every 15 min cannot spam admins. */
  suspiciousNotified?: Record<string, string>;
  /** Whitelisted diagnostics of the most recent capture attempt, as
   *  reported by heartbeat (captureId/result/failureReason/timings). */
  lastCaptureDiag?: Record<string, string>;
};

const COL = 'tracking';
const EMP_COL = 'employees';
const ATT_COL = 'attendance';

/** Roles allowed cross-employee tracking READS (still company-scoped). */
const ADMIN_ROLES = new Set(['admin', 'super_admin']);

/** HTTP error carrying a status code (converted in handlers). */
class HttpError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

/** The verified actor for a request: target empid + tenant, from the JWT. */
type Actor = {
  empid: string;      // target employee (self for employees; resolved target for admins)
  companyId: string;  // authenticated tenant - NEVER taken from the request
  role: string;
};

function todayIsoUTC(): string {
  return new Date().toISOString().slice(0, 10);
}

/** Client-supplied empid candidate (header/query/body) - never trusted alone. */
function requestedEmpId(req: Request): string {
  const fromHeader = String(req.headers['x-empid'] || '').trim();
  const fromQuery  = String(req.query.empid || '').trim();
  const fromBody   = String((req.body || {}).empid || '').trim();
  return fromHeader || fromQuery || fromBody;
}

/**
 * Resolve WHO may act on WHICH employee's tracking data, using only
 * server-verified identity (JWT via verifyToken + employees collection):
 *
 * - employee: the token's empid is authoritative. A client-supplied empid
 *   that differs is an impersonation attempt -> 403.
 * - admin / super_admin: may act on another empid only for approved
 *   READ operations (allowAdminTarget) and only after proving that
 *   employee belongs to the admin's own company (employees collection
 *   lookup). Admin tokens may never write tracking data (points, sessions,
 *   events, check-out) for another employee - a foreign GPS point or event
 *   must not be fabricatable through an admin token.
 * - companyId always comes from the token - never from the request.
 */
async function resolveActor(
  req: Request,
  opts?: { allowAdminTarget?: boolean }
): Promise<Actor> {
  const user = req.user as (AuthUser & { companyId?: string | null }) | undefined;
  const companyId = String(user?.companyId || '').trim();
  if (!companyId) {
    throw new HttpError(403, 'companyId missing in token');
  }
  const role = String(user?.role || 'employee').toLowerCase();
  const tokenEmp = String(user?.empid || '').trim();
  const requested = requestedEmpId(req);

  if (ADMIN_ROLES.has(role)) {
    const target = requested || tokenEmp;
    if (!target) throw new HttpError(400, 'empid missing (token/header/query/body)');
    // A different employee than the caller requires proof of same-company
    // membership; an admin may also act on their own empid freely.
    if (target !== tokenEmp) {
      if (opts?.allowAdminTarget !== true) {
        throw new HttpError(
          403, 'admins may not submit tracking data for another employee');
      }
      const snap = await db.collection(EMP_COL)
        .where('empid', '==', target)
        .where('companyId', '==', companyId)
        .limit(1)
        .get();
      if (snap.empty) {
        throw new HttpError(403, 'employee not found in your company');
      }
    }
    return { empid: target, companyId, role };
  }

  // Employee (and any non-admin role): own data only.
  if (!tokenEmp) throw new HttpError(403, 'empid missing in token');
  if (requested && requested !== tokenEmp) {
    throw new HttpError(403, 'empid mismatch - cannot act for another employee');
  }
  return { empid: tokenEmp, companyId, role };
}

function dateFromReq(req: Request): string {
  const q = (req.query.dateIso as string) || (req.body?.dateIso as string) || '';
  if (/^\d{4}-\d{2}-\d{2}$/.test(q)) return q;
  return todayIsoUTC();
}

/** New tenant-scoped document id. companyId is the authoritative tenant. */
function docId(companyId: string, empid: string, dateIso: string): string {
  return `${companyId}_${empid}_${dateIso}`;
}

/** Pre-migration document id (no tenant). Reads only - never written. */
function legacyDocId(empid: string, dateIso: string): string {
  return `${empid}_${dateIso}`;
}

/** True when the same empid exists in employees docs of >1 company. */
async function empidSpansMultipleCompanies(empid: string): Promise<boolean> {
  const snap = await db.collection(EMP_COL)
    .where('empid', '==', empid)
    .limit(10)
    .get();
  const companies = new Set(
    snap.docs.map((d) => String((d.data() as any)?.companyId || '').trim()));
  companies.delete('');
  return companies.size > 1;
}

/**
 * A legacy (un-tenanted) doc is only merged/closed when it can be safely
 * attributed to this actor's company. Returns the doc when authorized,
 * otherwise null - callers simply skip it: ambiguous legacy data is never
 * exposed and never throws (historical records are preserved, not deleted).
 *
 * Safety rules:
 * - Doc with a companyId field: must match the actor's company.
 * - Doc without companyId: only safe when the empid exists in exactly ONE
 *   company; if the same empid exists in multiple companies the record is
 *   unattributable and stays hidden until a manual migration assigns it.
 */
async function safeLegacyDoc(actor: Actor, data: any): Promise<TrackDayDoc | null> {
  if (!data) return null;
  const docCompany = String(data.companyId || '').trim();
  const docEmp = String(data.empid || '').trim();
  if (docEmp !== actor.empid) return null;
  if (docCompany) {
    if (docCompany !== actor.companyId) return null;
    return data as TrackDayDoc;
  }
  if (await empidSpansMultipleCompanies(actor.empid)) {
    console.log('[TrackingController] legacy doc skipped - empid exists in multiple companies, cannot attribute');
    return null;
  }
  return data as TrackDayDoc;
}

/**
 * A closed tracking session may only be reopened while an authoritative
 * attendance record shows the employee checked in and not checked out
 * (e.g. logout/re-login without check-out). Same-day re-check-in after
 * check-out is handled by attendance flow, not tracking.
 */
async function attendanceSessionActive(actor: Actor, dateIso: string): Promise<boolean> {
  const snap = await db.collection(ATT_COL)
    .where('empid', '==', actor.empid)
    .where('companyId', '==', actor.companyId)
    .where('date', '==', dateIso)
    .limit(1)
    .get();
  if (snap.empty) return false;
  const d = snap.docs[0].data() as any;
  const checkIn = String(d?.checkIn || '').trim();
  const checkOut = d?.checkOut;
  const hasCheckOut = !!(checkOut === true || (typeof checkOut === 'string' && checkOut.trim()));
  return checkIn !== '' && !hasCheckOut;
}

/* ---------- Live status computation (admin dashboard) ---------- */

/** A contact older than this means the session is not actively reporting.
 *  Matches the heartbeat sweep threshold so the UI and the alert system
 *  never disagree about whether a gap exists. */
export const TRACKING_STALE_AFTER_MIN = 45;

/** Grace period before a live-contact session with no valid GPS fix is
 *  reported as 'gps_delayed' and alerted. 15-min target + 20-min grace:
 *  ~2 missed capture cycles plus Android timer jitter and GPS acquisition
 *  latency - a single slow fix must not alert. */
export const GPS_STALE_AFTER_MIN = 35;

export type LiveTrackingStatus =
  'checked_out' | 'gps_unavailable' | 'permission_revoked' |
  'interrupted' | 'gps_delayed' | 'healthy' | 'unknown';

/** Event types that change the device's ability to report location. The
 *  LATEST of these wins: a disable followed by an enable resolves to
 *  normal freshness evaluation. */
const _GPS_STATE_EVENTS = new Set([
  'location_disabled', 'location_enabled', 'permission_revoked',
]);

/**
 * Last valid GPS-fix instant: explicit lastGpsFixAt first (covers fixes
 * the route filter skipped), then the newest stored point's capture
 * time, then the session start (a brand-new session gets one grace
 * window to obtain its first fix).
 */
function lastGpsFixMs(doc: TrackDayDoc): number {
  const explicit = Date.parse(String(doc.lastGpsFixAt || ''));
  if (Number.isFinite(explicit)) return explicit;
  const pathMap = Array.isArray(doc.pathMap) ? doc.pathMap : [];
  const lastPoint = pathMap.length ? pathMap[pathMap.length - 1] : null;
  const fromPoint = lastPoint
    ? Date.parse(String(lastPoint.capturedAt || lastPoint.ts || ''))
    : NaN;
  if (Number.isFinite(fromPoint)) return fromPoint;
  return Date.parse(String(doc.startedAt || ''));
}

/**
 * Derives the admin-visible tracking status for one day document.
 * Never reports 'healthy' from an open doc alone: an open session with no
 * contact in TRACKING_STALE_AFTER_MIN is 'interrupted'; a session whose
 * device is alive but producing no valid fix is 'gps_delayed' (cause
 * unknown) or 'gps_unavailable' (GPS OFF confirmed); a confirmed
 * permission loss is 'permission_revoked'. Device contact and GPS
 * freshness are evaluated on separate timestamps.
 */
export function computeTrackingStatus(
  doc: TrackDayDoc | null,
  nowMs: number,
): LiveTrackingStatus {
  if (!doc) return 'unknown';
  if (doc.endedAt) return 'checked_out';

  const fixMs = lastGpsFixMs(doc);

  // Confirmed GPS-state events. A valid fix AFTER a disable event means
  // the device recovered (an enable event was lost or deduped), so the
  // flag must not linger.
  const events = Array.isArray(doc.events) ? doc.events : [];
  let lastGpsEvent: TrackEvent | undefined;
  for (const e of events) {
    if (e && _GPS_STATE_EVENTS.has(String(e.type))) lastGpsEvent = e;
  }
  if (lastGpsEvent &&
      (lastGpsEvent.type === 'location_disabled' ||
       lastGpsEvent.type === 'permission_revoked')) {
    const eventMs = Date.parse(String(lastGpsEvent.ts || ''));
    if (!(Number.isFinite(fixMs) && fixMs > eventMs)) {
      return lastGpsEvent.type === 'permission_revoked'
        ? 'permission_revoked' : 'gps_unavailable';
    }
  }

  // No-contact trumps every other signal: a stale heartbeat state cannot
  // describe a device that stopped talking entirely.
  if (doc.interruption?.alertSent === true) return 'interrupted';

  const contactMs = Date.parse(
    String(doc.lastHeartbeatAt || doc.lastUpdateAt || ''));
  if (!Number.isFinite(contactMs)) return 'unknown';
  if (nowMs - contactMs > TRACKING_STALE_AFTER_MIN * 60000) {
    return 'interrupted';
  }

  // Fresh contact: the latest heartbeat's device-reported GPS state is
  // live evidence (perm_denied/service_off are continuously re-confirmed
  // while the service ticks).
  const state = String(doc.lastGpsState || '');
  if (state === 'perm_denied') return 'permission_revoked';
  if (state === 'service_off') return 'gps_unavailable';

  // Device alive, GPS state not confirmed-bad: has a valid fix gone
  // missing beyond the grace window?
  if (!Number.isFinite(fixMs)) return 'unknown';
  return (nowMs - fixMs > GPS_STALE_AFTER_MIN * 60000)
    ? 'gps_delayed' : 'healthy';
}

/** Client clock skew allowance before a future capture time is flagged. */
const MAX_FUTURE_SKEW_MIN = 15;
/** Offline queue can hold a multi-hour backlog; captures older than this
 *  are still stored but flagged, and never used for speed/replay math. */
const MAX_CAPTURE_AGE_HOURS = 72;
/** Faster than scheduled rail (~350 km/h): a pathMap jump beyond this is a
 *  teleport, not travel. Flagged for admin review - never a silent
 *  rejection, and never trusted as real movement. */
const MAX_PLAUSIBLE_SPEED_MPS = 350 / 3.6;

function pointFromBody(body: any): TrackPoint {
  const lat = Number(body?.lat);
  const lng = Number(body?.lng);
  const accuracy = (Number.isFinite(Number(body?.accuracy)) ? Number(body?.accuracy) : undefined);
  const source = (body?.source ? String(body.source) : undefined);
  // Optional client idempotency key so a retried submission is never stored twice.
  const rawPointId = typeof body?.pointId === 'string' ? body.pointId.trim() : '';
  const pointId = /^[A-Za-z0-9_.:-]{1,100}$/.test(rawPointId) ? rawPointId : undefined;

  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    throw new Error('lat/lng required as numbers');
  }
  // Impossible coordinates are never legitimate - cheap zero-false-
  // positive spoofing filter (lat=999 passed the finite check before).
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    throw new Error('lat/lng out of range');
  }

  const nowMs = Date.now();
  const flags: string[] = [];

  // Device-reported platform mock provider (Android isMockLocationProvider).
  // Catches naive spoofing only - a rooted device can forge clean results,
  // which is why the speed/replay checks exist too. Flagged, not rejected:
  // the review decision stays with the admin.
  const mocked = body?.mocked === true;
  if (mocked) flags.push('mock_location');

  // `capturedAtUtc` is the device's real capture time (ISO-8601 with Z).
  // The legacy `ts` field carries local time without a zone - never used
  // for trust decisions.
  const rawCaptured = typeof body?.capturedAtUtc === 'string'
    ? body.capturedAtUtc.trim() : '';
  let capturedAtMs: number | undefined;
  if (rawCaptured) {
    const parsed = Date.parse(rawCaptured);
    if (!Number.isFinite(parsed)) {
      flags.push('ts_invalid');
    } else {
      const driftMin = (parsed - nowMs) / 60000;
      const ageHours = (nowMs - parsed) / 3600000;
      if (driftMin > MAX_FUTURE_SKEW_MIN) {
        flags.push('ts_future');
      } else if (ageHours > MAX_CAPTURE_AGE_HOURS) {
        flags.push('ts_stale');
      } else {
        capturedAtMs = parsed;
      }
    }
  }

  const pt: TrackPoint = { lat, lng, ts: new Date(nowMs).toISOString() };
  // Firestore rejects undefined field values - only set optional fields when present.
  if (accuracy !== undefined) pt.accuracy = accuracy;
  if (source !== undefined) pt.source = source;
  if (pointId !== undefined) pt.pointId = pointId;
  if (mocked) pt.mocked = true;
  if (capturedAtMs !== undefined) {
    pt.capturedAt = new Date(capturedAtMs).toISOString();
  }
  const diag = sanitizeCaptureDiag(body?.diag);
  if (diag) pt.diag = diag;
  if (flags.length) pt.flags = flags;
  return pt;
}

/** Whitelisted capture-attempt diagnostics. Strings only, bounded length -
 *  a client cannot smuggle arbitrary blobs into a stored point. */
const DIAG_KEYS = new Set([
  'captureId', 'origin', 'scheduledCaptureAt', 'actualCaptureStartedAt',
  'apiRequestStartedAt', 'captureResult', 'failureReason',
]);
function sanitizeCaptureDiag(raw: any): Record<string, string> | undefined {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return undefined;
  const out: Record<string, string> = {};
  for (const k of DIAG_KEYS) {
    const v = raw[k];
    if (typeof v === 'string' && v.length > 0 && v.length <= 200) {
      out[k] = v;
    }
  }
  return Object.keys(out).length ? out : undefined;
}

/* ---------- NEW: throttle helpers (strict 20 min) ---------- */
/* ---------- Tracking throttle helpers ---------- */
const TRACKING_DEBUG_VERSION = 'tracking-debug-2min-1meter-v2';
console.log('[TrackingController] VERSION:', TRACKING_DEBUG_VERSION);

function minutesBetween(aIso: string, bIso: string) {
  return Math.abs((new Date(aIso).getTime() - new Date(bIso).getTime()) / 60000);
}

const MIN_TRACK_INTERVAL_MIN = 15;

/**
 * Server-authoritative session close. Stamps endedAt on an open tracking
 * day doc; a no-op when the doc is missing or already closed. Called from
 * /attendance/check-out so session lifetime does not depend on the client
 * surviving long enough to invoke /tracking/check-out itself, and reused by
 * trackingAppendPos to self-heal orphaned open docs.
 */
export async function closeTrackingSession(params: {
  companyId: string;
  empid: string;
  dateIso: string;
  at?: string;
}): Promise<{ closed: boolean }> {
  const { companyId, empid, dateIso } = params;
  if (!companyId || !empid || !dateIso) return { closed: false };
  const nowIso = params.at ?? new Date().toISOString();
  const ref = db.collection(COL).doc(docId(companyId, empid, dateIso));
  let closed = false;
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return;
    const data = snap.data() as TrackDayDoc;
    if (data.companyId && data.companyId !== companyId) return;
    if (data.endedAt) return;
    tx.update(ref, {
      endedAt: nowIso,
      lastUpdateAt: nowIso,
      lastHeartbeatAt: nowIso,
      interruption: FieldValue.delete(),
      gpsGap: FieldValue.delete(),
    });
    closed = true;
  });
  return { closed };
}

// very small movement filter so we don't store duplicate same-spot updates
function distanceMeters(a: {lat:number; lng:number}, b: {lat:number; lng:number}) {
  const R = 6371000; // m
  const toRad = (x:number)=> x * Math.PI/180;
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const s1 = Math.sin(dLat/2), s2 = Math.sin(dLng/2);
  const aa = s1*s1 + Math.cos(toRad(a.lat))*Math.cos(toRad(b.lat))*s2*s2;
  return Math.round(R * (2 * Math.atan2(Math.sqrt(aa), Math.sqrt(1-aa))));
}
const MIN_MOVE_METERS = 10;

/** Point flags worth an admin notification. Others (ts_stale on a queued
 *  offline backlog, coordinate noise) stay evidence-only in the events
 *  timeline - alerting on them would train admins to ignore alerts. */
const ALERTABLE_POINT_FLAGS = new Set([
  'mock_location', 'impossible_speed', 'replay',
]);

/** POST /api/tracking/check-in */
export async function trackingCheckIn(req: Request, res: Response) {
  try {
    const actor = await resolveActor(req);
    const dateIso = dateFromReq(req);
    const id = docId(actor.companyId, actor.empid, dateIso);
    const now = new Date().toISOString();

    const ref = db.collection(COL).doc(id);

    // If a session doc already exists for this employee+day, never wipe its
    // history. A session that was ended (logout/check-out) may only be
    // reopened while an authoritative attendance record shows the employee
    // still checked in (e.g. re-login without check-out).
    // Transactional so a concurrent /pos append can never be overwritten by
    // a blank pathMap (a merge-set of `pathMap: []` replaces the array).
    const result = await db.runTransaction(async (tx) => {
      const existing = await tx.get(ref);
      if (existing.exists) {
        const doc = existing.data() as TrackDayDoc | undefined;
        if (doc?.companyId && doc.companyId !== actor.companyId) {
          throw new HttpError(403, 'tracking session belongs to another company');
        }
        const ended = !!doc?.endedAt;
        if (ended) {
          // Outside a transaction would allow a stale read to reopen a
          // session after check-out - verify attendance inside it.
          const active = await attendanceSessionActive(actor, dateIso);
          if (!active) {
            throw new HttpError(403, 'tracking session is closed - no active attendance');
          }
          tx.update(ref, {
            endedAt: null,
            lastUpdateAt: now,
            lastHeartbeatAt: now,
          });
        }
        const pathMapCount = Array.isArray(doc?.pathMap) ? doc!.pathMap.length : 0;
        return { existed: true, reopened: ended, pathMapCount };
      }

      // Never create a tracking session without an authoritative active
      // attendance record (checked in and not checked out). Evaluated inside
      // the transaction so retries re-verify current attendance state.
      const active = await attendanceSessionActive(actor, dateIso);
      if (!active) {
        throw new HttpError(403, 'no active attendance - cannot start tracking');
      }

      const data: TrackDayDoc = {
        id,
        empid: actor.empid,
        companyId: actor.companyId,
        dateIso,
        pathMap: [],
        events: [],
        startedAt: now,
        endedAt: null,
        lastUpdateAt: now,
        lastHeartbeatAt: now,
      };
      tx.create(ref, data);
      return { existed: false, reopened: false, pathMapCount: 0 };
    });

    console.log('[TrackingController] check-in session existed:', result.existed,
      'reopened:', result.reopened, 'pathMapCount:', result.pathMapCount, 'dateIso:', dateIso);
    return res.status(200).json({ ok: true, id, empid: actor.empid, dateIso, ...result });
  } catch (e: any) {
    return res.status(e instanceof HttpError ? e.status : 400)
      .json({ error: e?.message || String(e) });
  }
}

/** POST /api/tracking/pos  — STRICT: accept at most once every 20 minutes. */
export async function trackingAppendPos(req: Request, res: Response) {
  console.log('[TrackingController] LOG: /tracking/pos endpoint HIT');
  
  try {
    const actor = await resolveActor(req);
    const dateIso = dateFromReq(req);
    const id = docId(actor.companyId, actor.empid, dateIso);
    const pt = pointFromBody(req.body);
    const nowIso = new Date().toISOString();
    
    // ✅ NEW: Capture reject reason outside transaction scope for response
    let rejectReasonForResponse = '';


    const ref = db.collection(COL).doc(id);

    let accepted = false;
    let status = 'appended' as AppendStatus;
    let pathMapCount = 0;
    // Set inside the transaction when this contact clears a heartbeat
    // interruption flagged by the sweep; the recovery notification is sent
    // after commit so a retried tx cannot double-notify.
    let recoveredFromInterruption = false;
    // Alertable spoof flags first seen by THIS session (doc-level dedup).
    // The admin notify fires post-commit.
    let suspiciousFlagsToAlert: string[] = [];
    // A valid GPS fix reaching the server clears an alerted GPS gap; the
    // "GPS Updates Recovered" notification fires post-commit.
    let recoveredFromGpsGap = false;
    await db.runTransaction(async (tx) => {
      // Reset per attempt - Firestore may re-run the transaction callback.
      accepted = false;
      status = 'appended';
      pathMapCount = 0;
      rejectReasonForResponse = '';
      recoveredFromGpsGap = false;
      const snap = await tx.get(ref);


      if (!snap.exists) {
        // A first point may only create a session when an authoritative
        // active attendance record exists - prevents fabricated tracking
        // days without a real check-in.
        const active = await attendanceSessionActive(actor, dateIso);
        if (!active) {
          throw new HttpError(403, 'no active attendance - cannot add tracking point');
        }
        console.log('[TrackingController] LOG: Document does not exist - creating new tracking document');
        const data: TrackDayDoc = {
          id,
          empid: actor.empid,
          companyId: actor.companyId,
          dateIso,
          pathMap: [pt],
          events: [],
          startedAt: nowIso,
          endedAt: null,
          lastUpdateAt: nowIso,
          lastHeartbeatAt: nowIso,
          lastGpsFixAt: pt.capturedAt ?? nowIso,
          lastLocationAt: nowIso,
        };
        tx.set(ref, data);
        accepted = true;
        pathMapCount = 1;
        console.log('[TrackingController] LOG: New document created with pathMap length: 1');
        return;
      }

      const data = snap.data() as TrackDayDoc;
      if (data.companyId && data.companyId !== actor.companyId) {
        console.log('[TrackingController] LOG: APPEND REJECTED - company mismatch');
        throw new HttpError(403, 'tracking data belongs to another company');
      }
      const list = Array.isArray(data.pathMap) ? data.pathMap : [];
      pathMapCount = list.length;

      // Reject new locations once the tracking session is closed
      // (check-out or logout already set endedAt).
      if (data.endedAt) {
        console.log('[TrackingController] LOG: APPEND REJECTED - tracking session already ended');
        status = 'session_ended';
        rejectReasonForResponse = 'Tracking session already ended';
        return;
      }

      // An open doc is not proof the shift is still active: the doc stays
      // open when the client dies between attendance check-out and
      // /tracking/check-out (crash, kill, offline). The attendance record
      // is authoritative - if it shows check-out (or is gone), close the
      // session server-side and reject the point. This also self-heals
      // orphaned open sessions so they cannot keep accepting locations.
      const sessionStillActive =
        await attendanceSessionActive(actor, dateIso);
      if (!sessionStillActive) {
        console.log('[TrackingController] LOG: APPEND REJECTED - attendance no longer active, closing session');
        status = 'session_ended';
        rejectReasonForResponse = 'Attendance session ended';
        tx.update(ref, {
          endedAt: nowIso,
          lastUpdateAt: nowIso,
          lastHeartbeatAt: nowIso,
          interruption: FieldValue.delete(),
          gpsGap: FieldValue.delete(),
        });
        return;
      }

      // Liveness: ANY authenticated contact on an open session refreshes
      // lastUpdateAt, even when the point itself is skipped (throttled/
      // duplicate/same-spot). A stationary employee keeps generating
      // contact - the heartbeat sweep must NOT treat that as a gap.
      //
      // GPS freshness: every submitted point is also a valid device fix,
      // even when the route filter skips storing it (throttled, same-spot).
      // lastGpsFixAt therefore uses the fix's own capture time (clamped by
      // pointFromBody) and only ever moves FORWARD - a late offline-queue
      // upload can never backdate freshness.
      const fixIso = pt.capturedAt ?? nowIso;
      const livenessUpdate: Record<string, any> = {
        lastUpdateAt: nowIso,
        lastHeartbeatAt: nowIso,
        // A fix reaching the server proves the device GPS pipeline works.
        lastGpsState: 'ok',
      };
      const prevFix = String(data.lastGpsFixAt || '');
      if (fixIso > prevFix) livenessUpdate['lastGpsFixAt'] = fixIso;

      // An alerted interruption ends on the first real contact; the admin
      // "recovered" notification fires after commit (see below).
      if (data.interruption?.alertSent) {
        recoveredFromInterruption = true;
        livenessUpdate['interruption'] = FieldValue.delete();
      }

      // An alerted GPS gap ends only on a fix NEWER than the gap start -
      // a late offline-queue upload must not fake a recovery.
      if (data.gpsGap?.alertSent &&
          Date.parse(fixIso) > Date.parse(String(data.gpsGap.since || '1970'))) {
        recoveredFromGpsGap = true;
        livenessUpdate['gpsGap'] = FieldValue.delete();
      }

      // Idempotent retry: this exact point was already stored.
      if (pt.pointId && list.some((p) => p?.pointId === pt.pointId)) {
        console.log('[TrackingController] LOG: duplicate pointId - already persisted');
        status = 'duplicate';
        rejectReasonForResponse = 'Point already persisted';
        tx.update(ref, livenessUpdate);
        return;
      }

      // Content-level idempotency: the SAME device fix (identical capture
      // instant, same spot) re-delivered under a different pointId. This
      // happens legitimately whenever two producers submit one Position -
      // e.g. the foreground-service tick and the main-isolate recovery
      // capture both receive the platform's current fix, or a queued
      // record is rebuilt by a different code path. One instant cannot be
      // two fixes, so this is harmless duplicate DELIVERY, not timestamp
      // manipulation: accept it idempotently and never flag the employee.
      // (Timestamp reuse with a DIFFERENT position is still caught as
      // `replay` below - that one is physically impossible.)
      if (Number.isFinite(Date.parse(String(pt.capturedAt || '')))) {
        const sameFix = list.find((p) => {
          if (!p?.capturedAt || p.capturedAt !== pt.capturedAt) return false;
          return distanceMeters(
            { lat: p.lat, lng: p.lng }, { lat: pt.lat, lng: pt.lng }) < 1;
        });
        if (sameFix) {
          console.log('[TrackingController] LOG: same fix re-delivered as',
            pt.pointId, '- already stored as', sameFix.pointId);
          status = 'duplicate';
          rejectReasonForResponse = 'Same GPS fix already persisted';
          tx.update(ref, livenessUpdate);
          return;
        }
      }

      const last = list.length ? list[list.length - 1] : null;

      // Anti-spoof checks against the previous accepted point. Results are
      // review flags on the point, never rejections: a flagged point is
      // persisted so admins see WHERE the anomaly happened, and the event
      // record explains WHY it was flagged.
      if (last) {
        const lastWhen = Date.parse(String(last.capturedAt || last.ts));
        const thisWhen = pt.capturedAt ? Date.parse(pt.capturedAt) : NaN;
        if (Number.isFinite(lastWhen) && Number.isFinite(thisWhen)) {
          const dtSec = (thisWhen - lastWhen) / 1000;
          const dist = distanceMeters(
            { lat: last.lat, lng: last.lng },
            { lat: pt.lat, lng: pt.lng });
          if (dtSec > 0 && dist / dtSec > MAX_PLAUSIBLE_SPEED_MPS) {
            pt.flags = [...(pt.flags ?? []), 'impossible_speed'];
          }
          // Replay / timestamp reuse: the SAME capture instant reported at
          // a DIFFERENT place. One device cannot hold two positions at one
          // instant, so this is timestamp manipulation - unlike an
          // identical fix re-delivered twice, which is handled as an
          // idempotent duplicate above and is never flagged.
          //
          // A negative dtSec (a delayed or offline-queued fix arriving
          // after a newer one) is NOT flagged: out-of-order delivery is
          // normal on mobile networks.
          if (dtSec === 0 && dist >= 1) {
            pt.flags = [...(pt.flags ?? []), 'replay'];
          }
        }
      }
      if (pt.flags?.length) {
        console.log('[TrackingController] suspicious point flags:',
          pt.flags, 'empid:', actor.empid);
        // Session-scoped alert dedup: each alertable flag notifies admins
        // once per tracking day; repeats stay evidence in events/pathMap.
        const notified = (data.suspiciousNotified ?? {}) as Record<string, string>;
        suspiciousFlagsToAlert = pt.flags.filter(
          (f) => ALERTABLE_POINT_FLAGS.has(f) && !notified[f]);
        if (suspiciousFlagsToAlert.length) {
          livenessUpdate['suspiciousNotified'] = {
            ...notified,
            ...Object.fromEntries(
              suspiciousFlagsToAlert.map((f) => [f, nowIso])),
          };
        }
      }

      console.log('[TrackingController] LOG: Existing document found - current pathMap length:', list.length);

      let allow = false;
      let rejectReason = '';
      if (!last) {
        allow = true;
        rejectReason = 'No previous points - first point allowed';
      } else {
        const sinceMin = minutesBetween(pt.ts, last.ts);
        // STRICT time throttle
        allow = sinceMin >= MIN_TRACK_INTERVAL_MIN;
        rejectReason = allow ? 'Time interval OK' : `Time throttled - only ${sinceMin.toFixed(1)}min since last (need ${MIN_TRACK_INTERVAL_MIN}min)`;
        if (!allow) status = 'time_throttled';

        // Optional: if last write was long ago BUT device hasn't moved at all, still skip
        if (allow) {
          const distance = distanceMeters({lat:last.lat, lng:last.lng}, {lat:pt.lat, lng:pt.lng});
          if (distance < MIN_MOVE_METERS) {
            // treat as duplicate at the same spot — keep lastUpdateAt only
            allow = false;
            rejectReason = `Movement too small - only ${distance.toFixed(1)}m (need ${MIN_MOVE_METERS}m)`;
            status = 'too_close';
          }
        }
      }

      console.log('[TrackingController] LOG: Allow append:', allow, 'Reason:', rejectReason);
      console.log('[TrackingController] LOG: Time since last:', last ? minutesBetween(pt.ts, last.ts).toFixed(1) + 'min' : 'N/A');
      console.log('[TrackingController] LOG: Distance from last:', last ? distanceMeters({lat:last.lat, lng:last.lng}, {lat:pt.lat, lng:pt.lng}).toFixed(1) + 'm' : 'N/A');

      // ✅ UPDATED: Capture reason for response
      rejectReasonForResponse = rejectReason;


      if (allow) {
       const updatedPath = [...list.slice(-199), pt]; // keep last 200 only
       console.log('[TrackingController] LOG: APPENDING SUCCESS - new pathMap length:', updatedPath.length);
       const update: Record<string, any> = {
         pathMap: updatedPath,
         // Server receive time of the newest STORED point - separate from
         // lastGpsFixAt so a stationary employee's skipped fixes still
         // count as GPS freshness without growing pathMap.
         lastLocationAt: nowIso,
         ...livenessUpdate,
       };
       // Flagged points get a timeline event so admins see the anomaly
       // without diffing raw path data. Server-generated - the client
       // event endpoint does not accept this type.
       if (pt.flags?.length) {
         const events = Array.isArray(data.events) ? data.events : [];
         update['events'] = [...events, {
           type: 'suspicious_location',
           ts: nowIso,
           message: `Tracking point flagged: ${pt.flags.join(', ')}`,
           latitude: pt.lat,
           longitude: pt.lng,
           // Diagnostic identity of the offending submission. Without
           // these, a flag cannot be traced back to a producer after the
           // fact (request logs do not survive long enough).
           pointId: pt.pointId ?? null,
           source: pt.source ?? null,
           capturedAt: pt.capturedAt ?? null,
         }];
       }
       tx.update(ref, update);
       accepted = true;
       pathMapCount = updatedPath.length;
       console.log('[TrackingController] LOG: Transaction completed - point appended successfully');
      } else {
        console.log('[TrackingController] LOG: APPEND REJECTED - point not added to pathMap');
        // Still contact on an open session - refresh liveness. A flagged
        // point that was skipped (throttled / same-spot / replay attempt)
        // also gets a suspicious_location event: skipping it must not
        // hide the spoof signal from admins.
        const update: Record<string, any> = { ...livenessUpdate };
        if (pt.flags?.length) {
          const events = Array.isArray(data.events) ? data.events : [];
          update['events'] = [...events, {
            type: 'suspicious_location',
            ts: nowIso,
            message:
              `Skipped tracking point flagged: ${pt.flags.join(', ')}`,
            latitude: pt.lat,
            longitude: pt.lng,
            pointId: pt.pointId ?? null,
            source: pt.source ?? null,
            capturedAt: pt.capturedAt ?? null,
          }];
        }
        tx.update(ref, update);
        return;
      }
    });

    // Significant spoof evidence -> one admin notification per flag kind
    // per session (deduped via suspiciousNotified inside the tx above).
    // Wording stays factual ("flagged for review") - an anomaly is not
    // proof of fraud (GPS drift, sensor faults, real high-speed travel).
    if (suspiciousFlagsToAlert.length) {
      try {
        let employeeName = actor.empid;
        try {
          const empSnap = await db.collection(EMP_COL)
            .where('empid', '==', actor.empid)
            .where('companyId', '==', actor.companyId)
            .limit(1)
            .get();
          const n = empSnap.docs[0]?.data()?.name;
          if (n) employeeName = String(n);
        } catch (_) { /* name lookup is best-effort */ }
        await notifyCompanyAdminsOfSuspiciousLocation({
          companyId: actor.companyId,
          empid: actor.empid,
          employeeName,
          flags: suspiciousFlagsToAlert,
          eventTs: nowIso,
          dateIso,
        });
      } catch (_) { /* suspicious notify is best-effort */ }
    }

    // First contact after an alerted interruption -> notify admins that
    // updates resumed. Never claims WHY the gap happened.
    if (recoveredFromInterruption) {
      try {
        await notifyCompanyAdminsOfTrackingInterruption({
          companyId: actor.companyId,
          empid: actor.empid,
          employeeName: actor.empid,
          kind: 'recovered',
          sinceTs: nowIso,
          dateIso,
        });
      } catch (_) { /* recovery notify is best-effort */ }
    }

    // First fresh fix after an alerted GPS gap -> 'GPS Updates Recovered'.
    if (recoveredFromGpsGap) {
      try {
        await notifyCompanyAdminsOfTrackingInterruption({
          companyId: actor.companyId,
          empid: actor.empid,
          employeeName: actor.empid,
          kind: 'gps_recovered',
          sinceTs: nowIso,
          dateIso,
        });
      } catch (_) { /* gps-gap recovery notify is best-effort */ }
    }

    console.log('[TrackingController] pos status:', status, 'pathMapCount:', pathMapCount, 'dateIso:', dateIso);

    // ✅ UPDATED: Include reason and throttle constants in response
    return res.status(200).json({
      ok: true,
      id,
      dateIso,
      status,
      // true only when this point (or the same pointId) is stored in pathMap
      persisted: status === 'appended' || status === 'duplicate',
      pathMapCount,
      added: accepted ? pt : null,
      throttled: !accepted,
      reason: accepted ? 'Point added to pathMap' : rejectReasonForResponse,
      minIntervalMinutes: MIN_TRACK_INTERVAL_MIN,
      minMoveMeters: MIN_MOVE_METERS,
    });
  } catch (e: any) {
    return res.status(e instanceof HttpError ? e.status : 400)
      .json({ error: e?.message || String(e) });
  }
}

/** POST /api/tracking/check-out */
export async function trackingCheckOut(req: Request, res: Response) {
  console.log('[TrackingController] CHECKOUT FUNCTION STARTED - NEW VERSION 2026-08-11');
  try {
    const actor = await resolveActor(req);
    const dateIso = dateFromReq(req);
    const id = docId(actor.companyId, actor.empid, dateIso);
    const ref = db.collection(COL).doc(id);

    const now = new Date().toISOString();

    console.log('[TrackingController] check-out - Creating logout event');
    // Create logout event
    const logoutEvent: TrackEvent = {
      type: 'account_logged_out',
      ts: now,
      message: 'User logged out',
    };

    console.log('[TrackingController] check-out - Logout event object:', JSON.stringify(logoutEvent));
    console.log('[TrackingController] check-out - Before Firestore update');

    await ref.set({
      endedAt: now,
      lastUpdateAt: now,
      lastHeartbeatAt: now,
      companyId: actor.companyId,
      // A closed session can never be mid-interruption - drop stale state
      // so the sweep and future sessions start clean.
      interruption: FieldValue.delete(),
      gpsGap: FieldValue.delete(),
      events: FieldValue.arrayUnion(logoutEvent)
    } as any, { merge: true });

    // Overnight shifts: the session doc is keyed to the CHECK-IN day. A
    // checkout after midnight arrives with today's dateIso and the dated
    // doc may not exist - close yesterday's still-open session too.
    const datedSnap = await ref.get();
    const datedExisted = datedSnap.exists &&
      ((datedSnap.data() as any)?.startedAt != null ||
       Array.isArray((datedSnap.data() as any)?.pathMap) &&
       (datedSnap.data() as any).pathMap.length > 0);
    if (!datedExisted) {
      const prev = new Date(Date.parse(`${dateIso}T00:00:00Z`) - 86400000)
        .toISOString().slice(0, 10);
      const prevRef = db.collection(COL)
        .doc(docId(actor.companyId, actor.empid, prev));
      const prevSnap = await prevRef.get();
      if (prevSnap.exists && !(prevSnap.data() as any)?.endedAt) {
        await prevRef.set({
          endedAt: now,
          lastUpdateAt: now,
          lastHeartbeatAt: now,
          companyId: actor.companyId,
          interruption: FieldValue.delete(),
          gpsGap: FieldValue.delete(),
          events: FieldValue.arrayUnion(logoutEvent),
        } as any, { merge: true });
        console.log('[TrackingController] check-out - closed previous-day session', prev);
      }
    }

    // A legacy (pre-tenant-scoped) doc for the same employee+day may still be
    // open - close it too so nothing can append to it. An unattributable
    // legacy doc (same empid in multiple companies) is skipped, not written.
    const legacyRef = db.collection(COL).doc(legacyDocId(actor.empid, dateIso));
    const legacySnap = await legacyRef.get();
    if (legacySnap.exists) {
      const safe = await safeLegacyDoc(actor, legacySnap.data());
      if (safe && !safe.endedAt) {
        await legacyRef.set({
          endedAt: now,
          lastUpdateAt: now,
          lastHeartbeatAt: now,
          gpsGap: FieldValue.delete(),
        }, { merge: true });
      }
    }

    console.log('[TrackingController] check-out - After FieldValue.arrayUnion success');

    return res.status(200).json({ ok: true, id, endedAt: now });
  } catch (e: any) {
    console.error('[TrackingController] check-out - ERROR occurred');
    return res.status(e instanceof HttpError ? e.status : 400)
      .json({ error: e?.message || String(e) });
  }
}

/** GET /api/tracking/day?dateIso=YYYY-MM-DD */
export async function trackingGetDay(req: Request, res: Response) {
  try {
    // Admin roles may READ a same-company employee's tracking day; all
    // write endpoints resolve without this flag and stay self-only.
    const actor = await resolveActor(req, { allowAdminTarget: true });
    const dateIso = dateFromReq(req);
    const id = docId(actor.companyId, actor.empid, dateIso);

    // Read the tenant-scoped doc AND the legacy (pre-migration) doc; a
    // session may have started before the id format changed, so history is
    // merged client-visible without mutating either document.
    const snap = await db.collection(COL).doc(id).get();
    const legacySnap = await db.collection(COL)
      .doc(legacyDocId(actor.empid, dateIso)).get();

    const current = snap.exists ? (snap.data() as TrackDayDoc) : null;
    if (current?.companyId && current.companyId !== actor.companyId) {
      throw new HttpError(403, 'tracking data belongs to another company');
    }
    let legacy: TrackDayDoc | null = null;
    if (legacySnap.exists) {
      // Only merged when safely attributable to this actor's company.
      legacy = await safeLegacyDoc(actor, legacySnap.data());
    }

    if (!current && !legacy) {
      console.log('[TrackingController] getDay - Document not found, returning empty data');
      const empty: TrackDayDoc = {
        id,
        empid: actor.empid,
        companyId: actor.companyId,
        dateIso,
        pathMap: [],
        events: [],
        endedAt: null,
        lastUpdateAt: new Date().toISOString(),
      };
      return res.json({ ok: true, data: {
        ...empty,
        lastHeartbeatAt: null,
        lastGpsFixAt: null,
        lastLocationAt: null,
        lastGpsState: null,
        // No session ever existed - never let lastUpdateAt=now read as
        // 'active' to a client that computes freshness.
        trackingStatus: 'unknown',
        serverNow: new Date().toISOString(),
      } });
    }

    // Merge both sources: dedupe points by pointId/ts and sort chronologically.
    const pathMap = [...(current?.pathMap ?? []), ...(legacy?.pathMap ?? [])]
      .filter((p, i, all) =>
        all.findIndex((q) =>
          (p.pointId && q.pointId === p.pointId) || (!p.pointId && q.ts === p.ts)
        ) === i)
      .sort((a, b) => String(a.ts).localeCompare(String(b.ts)));
    const events = [...(current?.events ?? []), ...(legacy?.events ?? [])];
    const endedAt = current?.endedAt ?? legacy?.endedAt ?? null;
    const merged = {
      ...(current ?? legacy)!,
      id,
      empid: actor.empid,
      companyId: actor.companyId,
      dateIso,
      pathMap,
      events,
      endedAt,
      // Server-computed status so admin clients never have to reimplement
      // the freshness/interruption rules (and can't disagree with /live).
      trackingStatus: computeTrackingStatus(
        { ...(current ?? legacy)!, pathMap, events, endedAt } as TrackDayDoc,
        Date.now()),
      serverNow: new Date().toISOString(),
    };

    console.log('[TrackingController] getDay - merged docs current:', !!current,
      'legacy:', !!legacy, 'points:', pathMap.length, 'events:', events.length);

    return res.json({ ok: true, data: merged });
  } catch (e: any) {
    console.error('[TrackingController] getDay - Error:', e?.message || String(e));
    return res.status(e instanceof HttpError ? e.status : 400)
      .json({ error: e?.message || String(e) });
  }
}

/** GET /api/tracking/live?dateIso=YYYY-MM-DD - admin-only company summary.
 *
 *  One query returns every employee's tracking-day summary for the
 *  requested (device-local) date, so the admin live view refreshes the
 *  whole company in a single request instead of N per-employee calls.
 *  Each row carries the fields needed to render status + freshness:
 *  never trusts "session open" as proof of live tracking - the client
 *  renders computeTrackingStatus() output only.
 */
export async function trackingLiveStatus(req: Request, res: Response) {
  try {
    const user = req.user as (AuthUser & { companyId?: string | null }) | undefined;
    const companyId = String(user?.companyId || '').trim();
    const role = String(user?.role || '').toLowerCase();
    if (!companyId) throw new HttpError(403, 'companyId missing in token');
    if (!ADMIN_ROLES.has(role)) {
      throw new HttpError(403, 'admin role required');
    }

    const dateIso = dateFromReq(req);
    const snap = await db.collection(COL)
      .where('companyId', '==', companyId)
      .where('dateIso', '==', dateIso)
      .get();

    const nowMs = Date.now();
    const rows = snap.docs.map((d) => {
      const data = d.data() as TrackDayDoc;
      const pathMap = Array.isArray(data.pathMap) ? data.pathMap : [];
      const lastPoint = pathMap.length ? pathMap[pathMap.length - 1] : null;
      const events = Array.isArray(data.events) ? data.events : [];
      const lastEvent = events.length ? events[events.length - 1] : null;
      const flaggedTypes = new Set<string>();
      let suspiciousCount = 0;
      for (const p of pathMap) {
        for (const f of (Array.isArray(p?.flags) ? p.flags : [])) {
          flaggedTypes.add(String(f));
        }
      }
      for (const e of events) {
        if (String(e?.type) === 'suspicious_location') suspiciousCount++;
      }
      return {
        empid: String(data.empid || ''),
        dateIso: String(data.dateIso || dateIso),
        startedAt: data.startedAt ?? null,
        endedAt: data.endedAt ?? null,
        lastUpdateAt: data.lastUpdateAt ?? null,
        lastHeartbeatAt: data.lastHeartbeatAt ?? data.lastUpdateAt ?? null,
        lastGpsFixAt: data.lastGpsFixAt ?? null,
        lastLocationAt: data.lastLocationAt ??
          (lastPoint ? (lastPoint.capturedAt ?? lastPoint.ts) : null),
        lastGpsState: data.lastGpsState ?? null,
        lastPoint: lastPoint ? {
          lat: lastPoint.lat,
          lng: lastPoint.lng,
          ts: lastPoint.ts,
          capturedAt: lastPoint.capturedAt ?? null,
          accuracy: lastPoint.accuracy ?? null,
        } : null,
        lastEvent: lastEvent ? {
          type: lastEvent.type,
          ts: lastEvent.ts,
          message: lastEvent.message ?? null,
        } : null,
        interrupted: data.interruption?.alertSent === true,
        status: computeTrackingStatus(data, nowMs),
        pathMapCount: pathMap.length,
        suspiciousCount,
        flaggedTypes: [...flaggedTypes],
      };
    }).filter((r) => r.empid);

    return res.json({
      ok: true,
      data: { dateIso, serverNow: new Date(nowMs).toISOString(), rows },
    });
  } catch (e: any) {
    return res.status(e instanceof HttpError ? e.status : 400)
      .json({ error: e?.message || String(e) });
  }
}

/** POST /api/tracking/event - Add tracking event to an ACTIVE session */
export async function trackingAddEvent(req: Request, res: Response) {
  try {
    const actor = await resolveActor(req);
    const dateIso = dateFromReq(req);
    const id = docId(actor.companyId, actor.empid, dateIso);

    const eventType = req.body?.type as string;
    const message = req.body?.message as string | undefined;
    // Optional client-supplied coords: accept only plausible values,
    // silently drop out-of-range rather than reject the whole event.
    const rawLat = Number(req.body?.latitude);
    const rawLng = Number(req.body?.longitude);
    const latitude = Number.isFinite(rawLat) && rawLat >= -90 && rawLat <= 90
      ? rawLat : undefined;
    const longitude = Number.isFinite(rawLng) && rawLng >= -180 && rawLng <= 180
      ? rawLng : undefined;
    // Optional client idempotency key for offline-queue retries.
    const rawClientId = typeof req.body?.clientEventId === 'string'
      ? req.body.clientEventId.trim() : '';
    const clientEventId =
      /^[A-Za-z0-9_.:-]{1,100}$/.test(rawClientId) ? rawClientId : undefined;

    console.log('[TrackingController] addEvent - type:', eventType);

    const validTypes = ['poor_gps', 'gps_disabled', 'location_disabled', 'location_enabled', 'permission_revoked', 'account_logged_out'];
    if (!eventType || !validTypes.includes(eventType)) {
      return res.status(400).json({ error: 'Invalid event type. Must be one of: ' + validTypes.join(', ') });
    }

    const nowIso = new Date().toISOString();
    const newEvent: TrackEvent & { eventId?: string; clientEventId?: string } = {
      type: eventType as any,
      ts: nowIso,
      eventId: `evt_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`,
    };
    if (message !== undefined) newEvent.message = message;
    if (latitude !== undefined) newEvent.latitude = latitude;
    if (longitude !== undefined) newEvent.longitude = longitude;
    if (clientEventId !== undefined) newEvent.clientEventId = clientEventId;

    const ref = db.collection(COL).doc(id);
    let status: 'added' | 'duplicate' = 'added';
    // Set inside the transaction when this event clears an alerted
    // heartbeat interruption; the "resumed" notification fires post-commit.
    let recoveredFromInterruption = false;

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      // Events only attach to an existing, still-open tracking session -
      // never fabricate a session and never append to a closed one.
      if (!snap.exists) {
        throw new HttpError(409, 'no active tracking session');
      }
      const data = snap.data() as TrackDayDoc;
      if (data.companyId && data.companyId !== actor.companyId) {
        throw new HttpError(403, 'tracking data belongs to another company');
      }
      if (data.endedAt) {
        throw new HttpError(409, 'tracking session is closed');
      }
      const events = Array.isArray(data.events) ? data.events : [];

      // Any authenticated event is liveness proof on an open session -
      // a GPS OFF event even explains the gap. Refresh lastUpdateAt and
      // clear an alerted interruption even when the event dedupes.
      const livenessUpdate: Record<string, any> = {
        lastUpdateAt: nowIso,
        lastHeartbeatAt: nowIso,
      };
      if (data.interruption?.alertSent) {
        recoveredFromInterruption = true;
        livenessUpdate['interruption'] = FieldValue.delete();
      }

      // Dedup 1: idempotent retry of the same client-generated event.
      if (clientEventId && events.some((e: any) => e?.clientEventId === clientEventId)) {
        status = 'duplicate';
        tx.update(ref, livenessUpdate as any);
        return;
      }
      // Dedup 2: same event type within 60s (double-tap, isolate race).
      if (events.some((e: any) => e?.type === eventType &&
          minutesBetween(String(e?.ts || ''), nowIso) < 1)) {
        status = 'duplicate';
        tx.update(ref, livenessUpdate as any);
        return;
      }
      tx.update(ref, {
        ...livenessUpdate,
        events: FieldValue.arrayUnion(newEvent),
      } as any);
    });

    console.log('[TrackingController] addEvent - status:', status);

    // Notify Company Admins on GPS OFF/ON transitions (fire-and-forget is
    // NOT acceptable for observability, but must never fail the request:
    // the helper swallows errors and never throws).
    if (status === 'added' &&
        (eventType === 'location_disabled' || eventType === 'location_enabled'
          || eventType === 'permission_revoked')) {
      let employeeName = actor.empid;
      try {
        const empSnap = await db.collection(EMP_COL)
          .where('empid', '==', actor.empid)
          .where('companyId', '==', actor.companyId)
          .limit(1)
          .get();
        const n = empSnap.docs[0]?.data()?.name;
        if (n) employeeName = String(n);
      } catch (_) { /* name lookup is best-effort */ }

      const notifyResult = await notifyCompanyAdminsOfTrackingEvent({
        companyId: actor.companyId,
        empid: actor.empid,
        employeeName,
        eventType: eventType as 'location_disabled' | 'location_enabled' | 'permission_revoked',
        eventTs: nowIso,
        dateIso,
      });
      // Observable, retryable loss state: records=0 means zero admin
      // notification records were even created (no admins in company, or
      // the admin lookup threw). Flag the doc so the reconciliation
      // sweep (reconcilePendingAdminNotifies, run lazily from admin
      // GET /notifications) can notify later - flagging only this case
      // guarantees a retry can never duplicate an existing in-app record.
      // pendingAdminNotify stays a boolean so the sweep can find flagged
      // docs with a plain equality query (no composite index needed);
      // details live in pendingAdminNotifyEvent.
      if (notifyResult.records === 0) {
        try {
          await ref.update({
            pendingAdminNotify: true,
            pendingAdminNotifyEvent: {
              eventId: newEvent.eventId,
              type: eventType,
              ts: nowIso,
              dateIso,
              empid: actor.empid,
            },
          } as any);
        } catch (_) { /* flagging is best-effort */ }
      }
    }

    // Event contact after an alerted interruption -> "Tracking Resumed".
    if (recoveredFromInterruption) {
      try {
        await notifyCompanyAdminsOfTrackingInterruption({
          companyId: actor.companyId,
          empid: actor.empid,
          employeeName: actor.empid,
          kind: 'recovered',
          sinceTs: nowIso,
          dateIso,
        });
      } catch (_) { /* recovery notify is best-effort */ }
    }

    return res.status(200).json({ ok: true, status, event: status === 'added' ? newEvent : null });
  } catch (e: any) {
    console.error('[TrackingController] addEvent - Error:', e?.message || String(e));
    return res.status(e instanceof HttpError ? e.status : 400)
      .json({ error: e?.message || String(e) });
  }
}

/** Device-reported GPS pipeline states accepted by /tracking/heartbeat. */
const GPS_HEARTBEAT_STATES = new Set([
  'ok', 'no_fix', 'service_off', 'perm_denied',
]);

/** POST /api/tracking/heartbeat — lightweight liveness + GPS-state ping.
 *
 *  The 15-min foreground tick calls this on EVERY cycle, including the
 *  ones where no fix was obtained (GPS off, permission denied, no fix,
 *  or a capture skipped because a recent point exists). It refreshes
 *  lastHeartbeatAt, records lastGpsState, and optionally advances
 *  lastGpsFixAt when the device reports a fix timestamp - letting the
 *  server distinguish "service alive, GPS dead" (gps_delayed) from
 *  "device silent" (interrupted).
 *
 *  A heartbeat never writes events or pathMap - it is contact only.
 *  When the session is closed (or the open doc's attendance has ended,
 *  self-healed exactly like /pos), it responds session_ended so the
 *  client tears down local tracking.
 */
export async function trackingHeartbeat(req: Request, res: Response) {
  try {
    const actor = await resolveActor(req);
    const dateIso = dateFromReq(req);
    const id = docId(actor.companyId, actor.empid, dateIso);
    const nowIso = new Date().toISOString();
    const nowMs = Date.now();

    const rawState = String(req.body?.gpsState || '').trim();
    const gpsState = GPS_HEARTBEAT_STATES.has(rawState) ? rawState : 'ok';

    // Device-reported time of its most recent valid fix. Validated with
    // the same skew/age bounds as points - never trusted blindly.
    const rawFix = typeof req.body?.gpsFixAtUtc === 'string'
      ? req.body.gpsFixAtUtc.trim() : '';
    let fixIso: string | undefined;
    if (rawFix) {
      const parsed = Date.parse(rawFix);
      const driftMin = (parsed - nowMs) / 60000;
      const ageHours = (nowMs - parsed) / 3600000;
      if (Number.isFinite(parsed) &&
          driftMin <= MAX_FUTURE_SKEW_MIN &&
          ageHours <= MAX_CAPTURE_AGE_HOURS) {
        fixIso = new Date(parsed).toISOString();
      }
    }

    const ref = db.collection(COL).doc(id);
    let status: 'ok' | 'session_ended' = 'ok';
    let recoveredFromInterruption = false;
    let recoveredFromGpsGap = false;

    await db.runTransaction(async (tx) => {
      recoveredFromInterruption = false;
      recoveredFromGpsGap = false;
      const snap = await tx.get(ref);
      const data = snap.exists ? (snap.data() as TrackDayDoc) : null;
      if (data?.companyId && data.companyId !== actor.companyId) {
        throw new HttpError(403, 'tracking data belongs to another company');
      }
      if (data?.endedAt) {
        status = 'session_ended';
        return;
      }

      // An open doc (or a missing one) is not proof the shift is active:
      // verify attendance inside the transaction. Inactive -> close and
      // tell the client to stop beating against a dead session.
      const active = await attendanceSessionActive(actor, dateIso);
      if (!active) {
        status = 'session_ended';
        if (snap.exists) {
          tx.update(ref, {
            endedAt: nowIso,
            lastUpdateAt: nowIso,
            lastHeartbeatAt: nowIso,
            interruption: FieldValue.delete(),
            gpsGap: FieldValue.delete(),
          });
        }
        return;
      }

      // Optional capture diagnostics - the result of the most recent
      // capture attempt (which is WHY the heartbeat was sent instead of a
      // point). Stored on the doc so "service alive, GPS dead" cases carry
      // device-side evidence (no_fix reason, capture duration).
      const diag = sanitizeCaptureDiag(req.body?.diag);
      if (diag) {
        console.log('[TrackingController] heartbeat diag', actor.empid, diag);
      }

      if (!snap.exists) {
        // Session doc missing but attendance is live (e.g. the check-in
        // write raced a heartbeat). Create the session rather than
        // tear down - identical to /pos's first-point creation.
        tx.set(ref, {
          id,
          empid: actor.empid,
          companyId: actor.companyId,
          dateIso,
          pathMap: [],
          events: [],
          startedAt: nowIso,
          endedAt: null,
          lastUpdateAt: nowIso,
          lastHeartbeatAt: nowIso,
          lastGpsState: gpsState,
          ...(fixIso ? { lastGpsFixAt: fixIso } : {}),
          ...(diag ? { lastCaptureDiag: diag } : {}),
        } as TrackDayDoc);
        return;
      }

      const update: Record<string, any> = {
        lastUpdateAt: nowIso,
        lastHeartbeatAt: nowIso,
        lastGpsState: gpsState,
      };
      if (diag) update['lastCaptureDiag'] = diag;
      const prevFix = String(data!.lastGpsFixAt || '');
      if (fixIso && fixIso > prevFix) update['lastGpsFixAt'] = fixIso;

      // Contact recovery: same rules as /pos - a heartbeat is real
      // authenticated contact on an open session.
      if (data!.interruption?.alertSent) {
        recoveredFromInterruption = true;
        update['interruption'] = FieldValue.delete();
      }
      // A heartbeat carrying a fresh fix timestamp clears an alerted GPS
      // gap just like a stored point would.
      const gap = data!.gpsGap;
      if (gap?.alertSent && fixIso &&
          Date.parse(fixIso) > Date.parse(String(gap.since || '1970'))) {
        recoveredFromGpsGap = true;
        update['gpsGap'] = FieldValue.delete();
      }
      tx.update(ref, update);
    });

    if (status === 'ok' && recoveredFromInterruption) {
      try {
        await notifyCompanyAdminsOfTrackingInterruption({
          companyId: actor.companyId,
          empid: actor.empid,
          employeeName: actor.empid,
          kind: 'recovered',
          sinceTs: nowIso,
          dateIso,
        });
      } catch (_) { /* recovery notify is best-effort */ }
    }
    if (status === 'ok' && recoveredFromGpsGap) {
      try {
        await notifyCompanyAdminsOfTrackingInterruption({
          companyId: actor.companyId,
          empid: actor.empid,
          employeeName: actor.empid,
          kind: 'gps_recovered',
          sinceTs: nowIso,
          dateIso,
        });
      } catch (_) { /* gps-gap recovery notify is best-effort */ }
    }

    return res.status(200).json({ ok: true, id, dateIso, status });
  } catch (e: any) {
    return res.status(e instanceof HttpError ? e.status : 400)
      .json({ error: e?.message || String(e) });
  }
}
