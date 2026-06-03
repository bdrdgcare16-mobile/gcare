import { Request, Response } from 'express';
import { db } from '../config/firebase';

export type AuthUser = {
  userId: string;
  email: string;
  role: string;
  empid?: string | null;
  uid?: string; // compat
};

type TrackPoint = { lat: number; lng: number; ts: string; accuracy?: number; source?: string };

type TrackEvent = {
  type: string;
  message: string;
  ts: string;
  source?: string;
};

type TrackDayDoc = {
  id: string;             // empid_YYYY-MM-DD
  empid: string;
  dateIso: string;        // YYYY-MM-DD
  pathMap: TrackPoint[];
  events?: TrackEvent[];
  startedAt?: string | null;    // ISO
  endedAt?: string | null;
  lastUpdateAt: string;   // ISO
};

const COL = 'tracking';

function todayIsoUTC(): string {
  return new Date().toISOString().slice(0, 10);
}

// Prefer explicit empid (header/query/body) and fall back to token.
// This lets admins view/save for any employee.
function pickEmpId(req: Request): string {
  const fromHeader = String(req.headers['x-empid'] || '').trim();
  const fromQuery  = String(req.query.empid || '').trim();
  const fromBody   = String((req.body || {}).empid || '').trim();
  const fromToken  = ((req.user as AuthUser | undefined)?.empid || '').trim();
  const emp = fromHeader || fromQuery || fromBody || fromToken;
  if (!emp) throw new Error('empid missing (token/header/query/body)');
  return emp;
}

function dateFromReq(req: Request): string {
  const q = (req.query.dateIso as string) || (req.body?.dateIso as string) || '';
  if (/^\d{4}-\d{2}-\d{2}$/.test(q)) return q;
  return todayIsoUTC();
}

function docId(empid: string, dateIso: string): string {
  return `${empid}_${dateIso}`;
}

function pointFromBody(body: any): TrackPoint {
  const lat = Number(body?.lat);
  const lng = Number(body?.lng);
  const accuracy = (Number.isFinite(Number(body?.accuracy)) ? Number(body?.accuracy) : undefined);
  const source = (body?.source ? String(body.source) : undefined);

  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    throw new Error('lat/lng required as numbers');
  }
  return { lat, lng, ts: new Date().toISOString(), accuracy, source };
}

function eventFromBody(body: any): TrackEvent {
  const type = String(body?.type || body?.eventType || '').trim();
  const message = String(body?.message || '').trim();
  const source = body?.source ? String(body.source).trim() : undefined;
  const tsRaw = body?.ts ? String(body.ts).trim() : '';
  const ts = tsRaw ? new Date(tsRaw).toISOString() : new Date().toISOString();

  if (!type) {
    throw new Error('event type required');
  }
  if (!message) {
    throw new Error('event message required');
  }
  return { type, message, source, ts };
}

/* ---------- NEW: throttle helpers (strict 20 min) ---------- */
/* ---------- Tracking throttle helpers ---------- */
const TRACKING_DEBUG_VERSION = 'tracking-debug-2min-1meter-v2';
console.log('[TrackingController] VERSION:', TRACKING_DEBUG_VERSION);

function minutesBetween(aIso: string, bIso: string) {
  return Math.abs((new Date(aIso).getTime() - new Date(bIso).getTime()) / 60000);
}

const MIN_TRACK_INTERVAL_MIN = 10;
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

/** POST /api/tracking/check-in */
export async function trackingCheckIn(req: Request, res: Response) {
  try {
    const empid = pickEmpId(req);
    const dateIso = dateFromReq(req);
    const id = docId(empid, dateIso);
    const now = new Date().toISOString();

    const ref = db.collection(COL).doc(id);

    const data: TrackDayDoc = {
      id,
      empid,
      dateIso,
      pathMap: [],
      events: [],
      startedAt: now,
      endedAt: null,
      lastUpdateAt: now,
    };

    await ref.set(data, { merge: true });
    return res.status(200).json({ ok: true, id, empid, dateIso });
  } catch (e: any) {
    return res.status(400).json({ error: e?.message || String(e) });
  }
}

/** POST /api/tracking/pos  — STRICT: accept at most once every 20 minutes. */
export async function trackingAppendPos(req: Request, res: Response) {
  console.log('[TrackingController] LOG: /tracking/pos endpoint HIT');
  console.log('[TrackingController] LOG: Request body:', JSON.stringify(req.body, null, 2));
  console.log('[TrackingController] LOG: Request headers:', JSON.stringify(req.headers, null, 2));
  
  try {
    const empid = pickEmpId(req);
    const dateIso = dateFromReq(req);
    const id = docId(empid, dateIso);
    const pt = pointFromBody(req.body);
    const nowIso = new Date().toISOString();
    
    // ✅ NEW: Capture reject reason outside transaction scope for response
    let rejectReasonForResponse = '';

    console.log('[TrackingController] LOG: Parsed data - empid:', empid, 'dateIso:', dateIso, 'docId:', id);
    console.log('[TrackingController] LOG: Point data - lat:', pt.lat, 'lng:', pt.lng, 'accuracy:', pt.accuracy, 'ts:', pt.ts);

    const ref = db.collection(COL).doc(id);

    let accepted = false;
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);

      console.log('[TrackingController] LOG: Transaction - checking if document exists for docId:', id);

      if (!snap.exists) {
        console.log('[TrackingController] LOG: Document does not exist - creating new tracking document');
        const data: TrackDayDoc = {
          id,
          empid,
          dateIso,
          pathMap: [pt],
          startedAt: nowIso,
          endedAt: null,
          lastUpdateAt: nowIso,
        };
        tx.set(ref, data);
        accepted = true;
        console.log('[TrackingController] LOG: New document created with pathMap length: 1');
        return;
      }

      const data = snap.data() as TrackDayDoc;
      const list = Array.isArray(data.pathMap) ? data.pathMap : [];
      const last = list.length ? list[list.length - 1] : null;

      console.log('[TrackingController] LOG: Existing document found - current pathMap length:', list.length);
      if (last) {
        console.log('[TrackingController] LOG: Last point - lat:', last.lat, 'lng:', last.lng, 'ts:', last.ts);
      } else {
        console.log('[TrackingController] LOG: No last point found in pathMap (pathMap is empty)');
      }

      let allow = false;
      let rejectReason = '';
      // If pathMap is empty (no previous points), always accept the first point without throttling
      if (list.length === 0) {
        allow = true;
        rejectReason = 'First point - pathMap was empty, no throttling applied';
      } else {
        // list.length > 0, so last is guaranteed to exist
        const lastPoint = last!;
        const sinceMin = minutesBetween(pt.ts, lastPoint.ts);
        // STRICT time throttle - only apply if we already have points
        allow = sinceMin >= MIN_TRACK_INTERVAL_MIN;
        rejectReason = allow ? 'Time interval OK' : `Time throttled - only ${sinceMin.toFixed(1)}min since last (need ${MIN_TRACK_INTERVAL_MIN}min)`;

        // Optional: if last write was long ago BUT device hasn't moved at all, still skip
        if (allow) {
          const distance = distanceMeters({lat:lastPoint.lat, lng:lastPoint.lng}, {lat:pt.lat, lng:pt.lng});
          if (distance < MIN_MOVE_METERS) {
            // treat as duplicate at the same spot — keep lastUpdateAt only
            allow = false;
            rejectReason = `Movement too small - only ${distance.toFixed(1)}m (need ${MIN_MOVE_METERS}m)`;
          }
        }
      }

      console.log('[TrackingController] LOG: Allow append:', allow, 'Reason:', rejectReason);
      console.log('[TrackingController] LOG: Time since last:', last ? minutesBetween(pt.ts, last.ts).toFixed(1) + 'min' : 'N/A');
      console.log('[TrackingController] LOG: Distance from last:', last ? distanceMeters({lat:last.lat, lng:last.lng}, {lat:pt.lat, lng:pt.lng}).toFixed(1) + 'm' : 'N/A');

      // ✅ UPDATED: Capture reason for response
      rejectReasonForResponse = rejectReason;

      const previousPathMapLength = list.length;
      const timeSinceLast = last ? minutesBetween(pt.ts, last.ts) : 0;
      const distanceFromLast = last ? distanceMeters({lat:last.lat, lng:last.lng}, {lat:pt.lat, lng:pt.lng}) : 0;

      if (allow) {
       const updatedPath = [...list.slice(-199), pt]; // keep last 200 only
       console.log('[TrackingController] LOG: APPENDING SUCCESS - new pathMap length:', updatedPath.length);
       tx.update(ref, { pathMap: updatedPath, lastUpdateAt: nowIso });
       accepted = true;
       console.log('[TrackingController] LOG: Transaction completed - point appended successfully');
       
       // Enhanced logging for accepted point
       console.log('[TrackingController] ACCEPTED POINT - empid:', empid, 'dateIso:', dateIso, 'docId:', id, 
         'previousPathMapLength:', previousPathMapLength, 'newPathMapLength:', updatedPath.length, 'accepted:', true);
      } else {
        console.log('[TrackingController] LOG: APPEND REJECTED - point not added to pathMap');
        
        // Enhanced logging for rejected point
        console.log('[TrackingController] REJECTED POINT - empid:', empid, 'dateIso:', dateIso, 'docId:', id, 
          'previousPathMapLength:', previousPathMapLength, 'rejectedReason:', rejectReason, 
          'timeDifference:', timeSinceLast.toFixed(1) + 'min', 'distanceDifference:', distanceFromLast.toFixed(1) + 'm');
        return;
      }
    });

    // ✅ UPDATED: Include reason and throttle constants in response
    console.log('[TrackingController] LOG: Final response - ok:', true, 'id:', id, 'added:', accepted ? 'YES' : 'NO', 'throttled:', !accepted, 'reason:', rejectReasonForResponse);
    return res.status(200).json({
      ok: true,
      id,
      added: accepted ? pt : null,
      throttled: !accepted,
      reason: accepted ? 'Point added to pathMap' : rejectReasonForResponse,
      minIntervalMinutes: MIN_TRACK_INTERVAL_MIN,
      minMoveMeters: MIN_MOVE_METERS,
    });
  } catch (e: any) {
    return res.status(400).json({ error: e?.message || String(e) });
  }
}

/** POST /api/tracking/event */
export async function trackingAppendEvent(req: Request, res: Response) {
  try {
    const empid = pickEmpId(req);
    const dateIso = dateFromReq(req);
    const id = docId(empid, dateIso);
    const event = eventFromBody(req.body);
    const nowIso = new Date().toISOString();
    const ref = db.collection(COL).doc(id);

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) {
        const data: TrackDayDoc = {
          id,
          empid,
          dateIso,
          pathMap: [],
          events: [event],
          startedAt: nowIso,
          endedAt: null,
          lastUpdateAt: nowIso,
        };
        tx.set(ref, data);
        return;
      }

      const data = snap.data() as TrackDayDoc;
      const events = Array.isArray(data.events) ? data.events : [];
      const updatedEvents = [...events.slice(-199), event];
      tx.update(ref, { events: updatedEvents, lastUpdateAt: nowIso });
    });

    return res.status(200).json({ ok: true, id, added: event });
  } catch (e: any) {
    return res.status(400).json({ error: e?.message || String(e) });
  }
}

/** POST /api/tracking/check-out */
export async function trackingCheckOut(req: Request, res: Response) {
  try {
    const empid = pickEmpId(req);
    const dateIso = dateFromReq(req);
    const id = docId(empid, dateIso);
    const ref = db.collection(COL).doc(id);

    const now = new Date().toISOString();
    await ref.set({ endedAt: now, lastUpdateAt: now } as Partial<TrackDayDoc>, { merge: true });

    return res.status(200).json({ ok: true, id, endedAt: now });
  } catch (e: any) {
    return res.status(400).json({ error: e?.message || String(e) });
  }
}

/** GET /api/tracking/day?dateIso=YYYY-MM-DD */
export async function trackingGetDay(req: Request, res: Response) {
  try {
    const empid = pickEmpId(req);
    const dateIso = dateFromReq(req);
    const id = docId(empid, dateIso);

    const snap = await db.collection(COL).doc(id).get();
    if (!snap.exists) {
      const empty: TrackDayDoc = {
        id,
        empid,
        dateIso,
        pathMap: [],
        endedAt: null,
        lastUpdateAt: new Date().toISOString(),
      };
      return res.json({ ok: true, data: empty });
    }
    return res.json({ ok: true, data: snap.data() });
  } catch (e: any) {
    return res.status(400).json({ error: e?.message || String(e) });
  }
}

/** POST /api/tracking/gps-event
 * Stores only important GPS-related events:
 * - poor_gps
 * - gps_disabled
 *
 * This does not modify pathMap.
 * This does not affect existing trackingAppendEvent logic.
 */
export async function trackingAppendGpsEvent(req: Request, res: Response) {
  try {
    const empid = pickEmpId(req);
    const dateIso = dateFromReq(req);
    const id = docId(empid, dateIso);
    const nowIso = new Date().toISOString();

    const type = String(req.body?.type || '').trim();
    const message = String(req.body?.message || '').trim();
    const reason = req.body?.reason ? String(req.body.reason).trim() : message;
    const source = req.body?.source ? String(req.body.source).trim() : 'unknown';

    const lat =
      req.body?.lat !== undefined && req.body?.lat !== null
        ? Number(req.body.lat)
        : undefined;

    const lng =
      req.body?.lng !== undefined && req.body?.lng !== null
        ? Number(req.body.lng)
        : undefined;

    const accuracy =
      req.body?.accuracy !== undefined && req.body?.accuracy !== null
        ? Number(req.body.accuracy)
        : undefined;

    const allowedTypes = ['poor_gps', 'gps_disabled' , 'account_logged_out'];

    if (!allowedTypes.includes(type)) {
      return res.status(400).json({
        ok: false,
        message: 'Invalid GPS event type. Allowed types: poor_gps, gps_disabled, account_logged_out',
      });
    }

    if (!message) {
      return res.status(400).json({
        ok: false,
        message: 'message is required',
      });
    }

    const event = {
      type,
      message,
      reason,
      ...(lat !== undefined && Number.isFinite(lat) ? { lat } : {}),
      ...(lng !== undefined && Number.isFinite(lng) ? { lng } : {}),
      ...(accuracy !== undefined && Number.isFinite(accuracy) ? { accuracy } : {}),
      source,
      ts: req.body?.ts ? String(req.body.ts) : nowIso,
      createdAt: nowIso,
    };

    const ref = db.collection(COL).doc(id);

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);

      if (!snap.exists) {
        const data: TrackDayDoc = {
          id,
          empid,
          dateIso,
          pathMap: [],
          events: [event],
          startedAt: null,
          endedAt: null,
          lastUpdateAt: nowIso,
        };

        tx.set(ref, data);
        return;
      }

      const data = snap.data() as TrackDayDoc;
      const events = Array.isArray(data.events) ? data.events : [];

      const updatedEvents = [...events, event].slice(-100);

      tx.update(ref, {
        events: updatedEvents,
        lastUpdateAt: nowIso,
      });
    });

    return res.status(200).json({
      ok: true,
      id,
      added: event,
      message: 'GPS tracking event saved',
    });
  } catch (e: any) {
    return res.status(400).json({
      ok: false,
      error: e?.message || String(e),
    });
  }
}
