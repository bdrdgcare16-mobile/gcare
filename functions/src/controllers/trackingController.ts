// import { Request, Response } from 'express';
// import { db } from '../config/firebase';

// export type AuthUser = {
//   userId: string;
//   email: string;
//   role: string;
//   empid?: string | null;
//   uid?: string; // compat
// };

// type TrackPoint = { lat: number; lng: number; ts: string };

// type TrackDayDoc = {
//   id: string;             // empid_YYYY-MM-DD
//   empid: string;
//   dateIso: string;        // YYYY-MM-DD
//   pathMap: TrackPoint[];
//   startedAt?: string;     // ISO
//   endedAt?: string | null; // <-- allow null while session is open
//   lastUpdateAt: string;   // ISO
// };

// const COL = 'tracking';

// function todayIsoUTC(): string {
//   return new Date().toISOString().slice(0, 10);
// }

// function pickEmpId(req: Request): string {
//   const u = (req.user as AuthUser | undefined);
//   const fromToken = (u?.empid || '').trim();
//   const fromQuery = (String(req.query.empid || '')).trim();
//   const fromBody  = (String((req.body || {}).empid || '')).trim();
//   const emp = fromToken || fromQuery || fromBody;
//   if (!emp) throw new Error('empid missing (token or query/body)');
//   return emp;
// }

// function dateFromReq(req: Request): string {
//   const q = (req.query.dateIso as string) || (req.body?.dateIso as string) || '';
//   if (/^\d{4}-\d{2}-\d{2}$/.test(q)) return q;
//   return todayIsoUTC();
// }

// function docId(empid: string, dateIso: string): string {
//   return `${empid}_${dateIso}`;
// }

// function pointFromBody(body: any): TrackPoint {
//   const lat = Number(body?.lat);
//   const lng = Number(body?.lng);
//   if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
//     throw new Error('lat/lng required as numbers');
//   }
//   return { lat, lng, ts: new Date().toISOString() };
// }

// /** POST /api/tracking/check-in
//  *  Clears/creates the day doc and starts a new path (empty).
//  */
// export async function trackingCheckIn(req: Request, res: Response) {
//   try {
//     const empid = pickEmpId(req);
//     const dateIso = dateFromReq(req);
//     const id = docId(empid, dateIso);
//     const now = new Date().toISOString();

//     const ref = db.collection(COL).doc(id);

//     const data: TrackDayDoc = {
//       id,
//       empid,
//       dateIso,
//       pathMap: [],
//       startedAt: now,
//       endedAt: null,      // <-- use null, not FieldValue.delete()
//       lastUpdateAt: now,
//     };

//     // Merge to avoid nuking unrelated keys if any
//     await ref.set(data, { merge: true });

//     return res.status(200).json({ ok: true, id, empid, dateIso });
//   } catch (e: any) {
//     return res.status(400).json({ error: e?.message || String(e) });
//   }
// }

// /** POST /api/tracking/pos */
// export async function trackingAppendPos(req: Request, res: Response) {
//   try {
//     const empid = pickEmpId(req);
//     const dateIso = dateFromReq(req);
//     const id = docId(empid, dateIso);
//     const pt = pointFromBody(req.body);
//     const now = new Date().toISOString();

//     const ref = db.collection(COL).doc(id);

//     await db.runTransaction(async (tx) => {
//       const snap = await tx.get(ref);
//       if (!snap.exists) {
//         const data: TrackDayDoc = {
//           id,
//           empid,
//           dateIso,
//           pathMap: [pt],
//           startedAt: now,
//           endedAt: null,
//           lastUpdateAt: now,
//         };
//         tx.set(ref, data);
//         return;
//       }

//       const data = snap.data() as TrackDayDoc;
//       const next = Array.isArray(data.pathMap) ? [...data.pathMap, pt] : [pt];

//       tx.update(ref, {
//         pathMap: next,
//         lastUpdateAt: now,
//       });
//     });

//     return res.status(200).json({ ok: true, id, added: pt });
//   } catch (e: any) {
//     return res.status(400).json({ error: e?.message || String(e) });
//   }
// }

// /** POST /api/tracking/check-out */
// export async function trackingCheckOut(req: Request, res: Response) {
//   try {
//     const empid = pickEmpId(req);
//     const dateIso = dateFromReq(req);
//     const id = docId(empid, dateIso);
//     const ref = db.collection(COL).doc(id);

//     const now = new Date().toISOString();
//     await ref.set(
//       { endedAt: now, lastUpdateAt: now } as Partial<TrackDayDoc>,
//       { merge: true }
//     );

//     return res.status(200).json({ ok: true, id, endedAt: now });
//   } catch (e: any) {
//     return res.status(400).json({ error: e?.message || String(e) });
//   }
// }

// /** GET /api/tracking/day?dateIso=YYYY-MM-DD */
// export async function trackingGetDay(req: Request, res: Response) {
//   try {
//     const empid = pickEmpId(req);
//     const dateIso = dateFromReq(req);
//     const id = docId(empid, dateIso);

//     const snap = await db.collection(COL).doc(id).get();
//     if (!snap.exists) {
//       const empty: TrackDayDoc = {
//         id,
//         empid,
//         dateIso,
//         pathMap: [],
//         endedAt: null,
//         lastUpdateAt: new Date().toISOString(),
//       };
//       return res.json({ ok: true, data: empty });
//     }
//     return res.json({ ok: true, data: snap.data() });
//   } catch (e: any) {
//     return res.status(400).json({ error: e?.message || String(e) });
//   }
// }
import { Request, Response } from 'express';
import { db } from '../config/firebase';

export type AuthUser = {
  userId: string;
  email: string;
  role: string;
  empid?: string | null;
  uid?: string; // compat
};

type TrackPoint = { lat: number; lng: number; ts: string };

type TrackDayDoc = {
  id: string;             // empid_YYYY-MM-DD
  empid: string;
  dateIso: string;        // YYYY-MM-DD
  pathMap: TrackPoint[];
  startedAt?: string;     // ISO
  endedAt?: string | null;
  lastUpdateAt: string;   // ISO
};

const COL = 'tracking';

function todayIsoUTC(): string {
  return new Date().toISOString().slice(0, 10);
}

// ✅ pick empid from: JWT → header x-empid → query → body
function pickEmpId(req: Request): string {
  const u = (req.user as AuthUser | undefined);
  const fromToken  = (u?.empid || '').trim();
  const fromHeader = String(req.headers['x-empid'] || '').trim();
  const fromQuery  = String(req.query.empid || '').trim();
  const fromBody   = String((req.body || {}).empid || '').trim();

  const emp = fromToken || fromHeader || fromQuery || fromBody;
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
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    throw new Error('lat/lng required as numbers');
  }
  return { lat, lng, ts: new Date().toISOString() };
}

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

/** POST /api/tracking/pos */
export async function trackingAppendPos(req: Request, res: Response) {
  try {
    const empid = pickEmpId(req);
    const dateIso = dateFromReq(req);
    const id = docId(empid, dateIso);
    const pt = pointFromBody(req.body);
    const now = new Date().toISOString();

    const ref = db.collection(COL).doc(id);

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) {
        const data: TrackDayDoc = {
          id,
          empid,
          dateIso,
          pathMap: [pt],
          startedAt: now,
          endedAt: null,
          lastUpdateAt: now,
        };
        tx.set(ref, data);
        return;
      }

      const data = snap.data() as TrackDayDoc;
      const next = Array.isArray(data.pathMap) ? [...data.pathMap, pt] : [pt];

      tx.update(ref, {
        pathMap: next,
        lastUpdateAt: now,
      });
    });

    return res.status(200).json({ ok: true, id, added: pt });
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
