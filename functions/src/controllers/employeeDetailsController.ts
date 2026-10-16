import { Request, Response } from 'express';
import { db } from '../config/firebase';


/* ------------------------- small utils ------------------------- */
const toFloat = (v: any): number | undefined => {
  if (v === null || v === undefined) return undefined;
  const n = Number(v);
  return Number.isFinite(n) ? n : undefined;
};

const pickStr = (o: any, keys: string[], fallback = ''): string => {
  for (const k of keys) {
    const v = o?.[k];
    if (v !== undefined && v !== null) {
      const s = String(v).trim();
      if (s) return s;
    } 
  }
  return fallback;
};

const H_EARTH = 6371000; // meters
const haversine = (a: { lat: number; lng: number }, b: { lat: number; lng: number }) => {
  const dLat = ((b.lat - a.lat) * Math.PI) / 180;
  const dLng = ((b.lng - a.lng) * Math.PI) / 180;
  const la1 = (a.lat * Math.PI) / 180;
  const la2 = (b.lat * Math.PI) / 180;
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(la1) * Math.cos(la2) * Math.sin(dLng / 2) ** 2;
  return H_EARTH * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h));
};

/* --------------------- fetch helpers (Firestore) --------------------- */
// 'foreign' marks a doc that exists but belongs to another company —
// callers must translate it to a 403, never to data.
const FOREIGN = Symbol('foreign');
type FetchResult = Record<string, any> | null | typeof FOREIGN;

async function getAttendanceById(id: string, companyId: string): Promise<FetchResult> {
  const snap = await db.collection('attendance').doc(id).get();
  if (!snap.exists) return null;
  const data: Record<string, any> = { id: snap.id, ...snap.data() };
  return data.companyId === companyId ? data : FOREIGN;
}
async function getOtherLocById(id: string, companyId: string): Promise<FetchResult> {
  const snap = await db.collection('otherLocation').doc(id).get();
  if (!snap.exists) return null;
  const data: Record<string, any> = { id: snap.id, ...snap.data() };
  return data.companyId === companyId ? data : FOREIGN;
}

async function getAttendanceByEmpDate(empid: string, date: string, companyId: string) {
  const q = await db
    .collection('attendance')
    .where('empid', '==', empid)
    .where('date', '==', date)
    .where('companyId', '==', companyId)
    .limit(1)
    .get();
  if (q.empty) return null;
  const d = q.docs[0];
  return { id: d.id, ...d.data() };
}

async function getOtherLocByEmpDate(empid: string, date: string, companyId: string) {
  const q = await db
    .collection('otherLocation')
    .where('empid', '==', empid)
    .where('date', '==', date)
    .where('companyId', '==', companyId)
    .limit(1)
    .get();
  if (q.empty) return null;
  const d = q.docs[0];
  return { id: d.id, ...d.data() };
}

/* --------------------- merge + normalize payload --------------------- */
function normalize(
  attendance: any | null,
  otherLoc: any | null
) {
  const srcA = attendance || {};
  const srcO = otherLoc || {};

  // identity
  const empid = pickStr({ ...srcA, ...srcO }, ['empid', 'employeeId', 'EmpID']);
  const name = pickStr({ ...srcA, ...srcO }, ['name', 'employeeName']);
  const type = pickStr({ ...srcA, ...srcO }, ['type', 'category']);
  const time = pickStr({ ...srcA, ...srcO }, ['time', 'requestTime', 'checkInTime', 'checkOutTime', 'createdAt', 'updatedAt']);
  const date = pickStr({ ...srcA, ...srcO }, ['date', 'requestDate', 'onDate', 'startDate']);

  // branch + expected
  const branchName = pickStr({ ...srcA, ...srcO }, ['branchName', 'branchLocation', 'location']);
  const expectedLatitude =
    toFloat(srcA.expectedLatitude) ?? toFloat(srcO.expectedLatitude) ??
    toFloat(srcA.branchLatitude)   ?? toFloat(srcO.branchLatitude);
  const expectedLongitude =
    toFloat(srcA.expectedLongitude) ?? toFloat(srcO.expectedLongitude) ??
    toFloat(srcA.branchLongitude)   ?? toFloat(srcO.branchLongitude);
  const expectedRadius =
    toFloat(srcO.expectedRadius) ?? toFloat(srcA.expectedRadius) ?? toFloat(srcO.radius) ?? toFloat(srcA.radius);

  // request location (prefer otherLocation doc if exists)
  const latitude  =
    toFloat(srcO.latitude) ?? toFloat(srcA.latitude) ??
    toFloat(srcA.checkInLatitude) ?? toFloat(srcA.checkOutLatitude);
  const longitude =
    toFloat(srcO.longitude) ?? toFloat(srcA.longitude) ??
    toFloat(srcA.checkInLongitude) ?? toFloat(srcA.checkOutLongitude);

  // distance/within
  let distanceFromBranch =
    toFloat(srcO.distanceFromBranch) ?? toFloat(srcA.distanceFromBranch);
  if (
    distanceFromBranch === undefined &&
    expectedLatitude !== undefined &&
    expectedLongitude !== undefined &&
    latitude !== undefined &&
    longitude !== undefined
  ) {
    distanceFromBranch = haversine(
      { lat: expectedLatitude, lng: expectedLongitude },
      { lat: latitude, lng: longitude }
    );
  }

  let withinRadius: boolean | undefined =
    srcO.withinRadius ?? srcA.withinRadius;
  if (withinRadius === undefined && expectedRadius !== undefined && distanceFromBranch !== undefined) {
    withinRadius = distanceFromBranch <= expectedRadius;
  }

  // status
  const status =
    pickStr({ ...srcA, ...srcO }, ['status', 'approvalStatus']) || 'Pending';

  // id to return (prefer otherLoc id if exists)
  const requestId = srcO.id || srcA.id || pickStr({ ...srcA, ...srcO }, ['requestId']);

  return {
    requestId,
    empid,
    name,
    type,
    time,
    date,
    branchName,
    expectedLatitude,
    expectedLongitude,
    expectedRadius,
    latitude,
    longitude,
    distanceFromBranch,
    withinRadius,
    status,
  };
}

/* --------------------------- controller --------------------------- */
/**
 * GET /api/attendance/request-details
 * Query:
 *  - id & src=attendance|other_location   OR
 *  - empid & date=YYYY-MM-DD
 *
 * Response: normalized merged object (attendance + otherLocation)
 */
export async function getRequestDetails(req: Request, res: Response) {
  try {
    const companyId = String((req as any).user?.companyId ?? '').trim();
    if (!companyId) {
      return res.status(403).json({ error: 'companyId missing in token' });
    }

    const id   = String(req.query.id ?? '').trim();
    const src  = String(req.query.src ?? '').trim().toLowerCase();
    const emp  = String(req.query.empid ?? '').trim();
    const date = String(req.query.date ?? '').trim();

    let attendance: any | null = null;
    let otherLoc: any | null = null;

    if (id) {
      if (src === 'other_location') {
        otherLoc = await getOtherLocById(id, companyId);
        if (otherLoc === FOREIGN) {
          return res.status(403).json({ error: 'Access denied: companyId mismatch' });
        }
        const empid = pickStr(otherLoc, ['empid']);
        const d     = pickStr(otherLoc, ['date']).slice(0, 10);
        if (empid && d) attendance = await getAttendanceByEmpDate(empid, d, companyId);
      } else {
        attendance = await getAttendanceById(id, companyId);
        if (attendance === FOREIGN) {
          return res.status(403).json({ error: 'Access denied: companyId mismatch' });
        }
        const empid = pickStr(attendance, ['empid']);
        const d     = pickStr(attendance, ['date']).slice(0, 10);
        if (empid && d) otherLoc = await getOtherLocByEmpDate(empid, d, companyId);
      }
    } else if (emp && date) {
      attendance = await getAttendanceByEmpDate(emp, date.slice(0, 10), companyId);
      otherLoc   = await getOtherLocByEmpDate(emp, date.slice(0, 10), companyId);
    } else {
      return res.status(400).json({ error: 'Provide (id & src) or (empid & date)' });
    }

    if (!attendance && !otherLoc) {
      return res.status(404).json({ error: 'No records found' });
    }

    const merged = normalize(attendance, otherLoc);
    return res.json(merged);
  } catch (err: any) {
    console.error('getRequestDetails error', err);
    return res.status(500).json({ error: err?.message ?? 'Server error' });
  }
}
