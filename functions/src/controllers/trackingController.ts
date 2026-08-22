import { Request, Response } from 'express';
import { db } from '../config/firebase';
import { FieldValue } from 'firebase-admin/firestore';

export type AuthUser = {
  userId: string;
  email: string;
  role: string;
  empid?: string | null;
  uid?: string; // compat
};

type TrackPoint = { lat: number; lng: number; ts: string; accuracy?: number; source?: string };

type TrackEvent = {
  type: 'poor_gps' | 'gps_disabled' | 'location_disabled' | 'location_enabled' | 'account_logged_out';
  ts: string;  // ISO timestamp
  message?: string;
  latitude?: number;
  longitude?: number;
};

type TrackDayDoc = {
  id: string;             // empid_YYYY-MM-DD
  empid: string;
  dateIso: string;        // YYYY-MM-DD
  pathMap: TrackPoint[];
  events: TrackEvent[];   // Tracking events array
  startedAt?: string;     // ISO
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

/* ---------- NEW: throttle helpers (strict 20 min) ---------- */
/* ---------- Tracking throttle helpers ---------- */
const TRACKING_DEBUG_VERSION = 'tracking-debug-2min-1meter-v2';
console.log('[TrackingController] VERSION:', TRACKING_DEBUG_VERSION);

function minutesBetween(aIso: string, bIso: string) {
  return Math.abs((new Date(aIso).getTime() - new Date(bIso).getTime()) / 60000);
}

const MIN_TRACK_INTERVAL_MIN = 15;
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
  
  try {
    const empid = pickEmpId(req);
    const dateIso = dateFromReq(req);
    const id = docId(empid, dateIso);
    const pt = pointFromBody(req.body);
    const nowIso = new Date().toISOString();
    
    // ✅ NEW: Capture reject reason outside transaction scope for response
    let rejectReasonForResponse = '';


    const ref = db.collection(COL).doc(id);

    let accepted = false;
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);


      if (!snap.exists) {
        console.log('[TrackingController] LOG: Document does not exist - creating new tracking document');
        const data: TrackDayDoc = {
          id,
          empid,
          dateIso,
          pathMap: [pt],
          events: [],
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

        // Optional: if last write was long ago BUT device hasn't moved at all, still skip
        if (allow) {
          const distance = distanceMeters({lat:last.lat, lng:last.lng}, {lat:pt.lat, lng:pt.lng});
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


      if (allow) {
       const updatedPath = [...list.slice(-199), pt]; // keep last 200 only
       console.log('[TrackingController] LOG: APPENDING SUCCESS - new pathMap length:', updatedPath.length);
       tx.update(ref, { pathMap: updatedPath, lastUpdateAt: nowIso });
       accepted = true;
       console.log('[TrackingController] LOG: Transaction completed - point appended successfully');
      } else {
        console.log('[TrackingController] LOG: APPEND REJECTED - point not added to pathMap');
        return;
      }
    });

    // ✅ UPDATED: Include reason and throttle constants in response
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

/** POST /api/tracking/check-out */
export async function trackingCheckOut(req: Request, res: Response) {
  console.log('[TrackingController] CHECKOUT FUNCTION STARTED - NEW VERSION 2026-08-11');
  try {
    const empid = pickEmpId(req);
    const dateIso = dateFromReq(req);
    const id = docId(empid, dateIso);
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
      events: FieldValue.arrayUnion(logoutEvent)
    } as any, { merge: true });

    console.log('[TrackingController] check-out - After FieldValue.arrayUnion success');
    
    return res.status(200).json({ ok: true, id, endedAt: now });
  } catch (e: any) {
    console.error('[TrackingController] check-out - ERROR occurred');
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
      console.log('[TrackingController] getDay - Document not found, returning empty data');
      const empty: TrackDayDoc = {
        id,
        empid,
        dateIso,
        pathMap: [],
        events: [],
        endedAt: null,
        lastUpdateAt: new Date().toISOString(),
      };
      return res.json({ ok: true, data: empty });
    }
    
    const data = snap.data() as TrackDayDoc;
    console.log('[TrackingController] getDay - Document found, events count:', data.events?.length || 0);
    
    return res.json({ ok: true, data: snap.data() });
  } catch (e: any) {
    console.error('[TrackingController] getDay - Error:', e?.message || String(e));
    return res.status(400).json({ error: e?.message || String(e) });
  }
}

/** POST /api/tracking/event - Add tracking event */
export async function trackingAddEvent(req: Request, res: Response) {
  try {
    const empid = pickEmpId(req);
    const dateIso = dateFromReq(req);
    const id = docId(empid, dateIso);
    
    const eventType = req.body?.type as string;
    const message = req.body?.message as string | undefined;
    const latitude = req.body?.latitude as number | undefined;
    const longitude = req.body?.longitude as number | undefined;
    
    console.log('[TrackingController] addEvent - type:', eventType);
    
    const validTypes = ['poor_gps', 'gps_disabled', 'location_disabled', 'location_enabled', 'account_logged_out'];
    if (!eventType || !validTypes.includes(eventType)) {
      console.error('[TrackingController] addEvent - Invalid event type:', eventType);
      return res.status(400).json({ error: 'Invalid event type. Must be one of: ' + validTypes.join(', ') });
    }

    const newEvent: TrackEvent = {
      type: eventType as any,
      ts: new Date().toISOString(),
      message,
      latitude,
      longitude,
    };


    const ref = db.collection(COL).doc(id);
    
    // First ensure the document exists
    const snap = await ref.get();
    if (!snap.exists) {
      console.log('[TrackingController] addEvent - Document does not exist, creating with event');
      // Create document with this event if it doesn't exist
      const now = new Date().toISOString();
      const data: TrackDayDoc = {
        id,
        empid,
        dateIso,
        pathMap: [],
        events: [newEvent],
        startedAt: now,
        endedAt: null,
        lastUpdateAt: now,
      };
      await ref.set(data);
    } else {
      console.log('[TrackingController] addEvent - Document exists, adding event');
      // Add event to existing document
      await ref.update({
        events: FieldValue.arrayUnion(newEvent),
        lastUpdateAt: new Date().toISOString(),
      } as any);
    }

    console.log('[TrackingController] addEvent - Event saved successfully');
    return res.status(200).json({ ok: true, event: newEvent });
  } catch (e: any) {
    console.error('[TrackingController] addEvent - Error:', e?.message || String(e));
    return res.status(400).json({ error: e?.message || String(e) });
  }
}
