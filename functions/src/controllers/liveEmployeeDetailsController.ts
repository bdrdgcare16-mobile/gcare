import { Request, Response } from 'express';
import { db } from '../config/firebase';
import { distanceMeters } from '../utils/geo';

type AttDoc = {
  empid: string;
  name?: string;
  date: string;
  shift?: string;
  shiftGroup?: string;
  dept?: string;
  department?: string;
  branchName?: string;
  checkIn?: string | null;
  checkOut?: string | null;
  checkInLatitude?: number | null;
  checkInLongitude?: number | null;
  expectedLatitude?: number | null;
  expectedLongitude?: number | null;
  expectedRadius?: number | null;
  status?: string;
};

function pickDate(req: Request) {
  const q = (req.query.dateIso as string) || '';
  if (/^\d{4}-\d{2}-\d{2}$/.test(q)) return q;
  return new Date().toISOString().slice(0, 10);
}

export async function liveEmployeeDetails(req: Request, res: Response) {
  try {
    const empid =
      (req.params.empid || '').trim() ||
      String(req.headers['x-empid'] || '').trim();

    if (!empid) {
      return res.status(400).json({
        status: 'error',
        message: 'Employee ID required',
      });
    }

    const dateIso = pickDate(req);

    const attendanceSnap = await db
      .collection('attendance')
      .where('empid', '==', empid)
      .where('date', '==', dateIso)
      .limit(1)
      .get();

    const employeeSnap = await db
      .collection('employees')
      .where('empid', '==', empid)
      .limit(1)
      .get();

    const employeeData = !employeeSnap.empty ? employeeSnap.docs[0].data() : null;

    if (attendanceSnap.empty) {
      return res.json({
        ok: true,
        data: {
          id: empid,
          name: employeeData?.name ?? '-',
          date: dateIso,
          shift: employeeData?.shiftGroup ?? '-',
          shiftGroup: employeeData?.shiftGroup ?? '-',
          dept: employeeData?.dept ?? '-',
          department: employeeData?.dept ?? '-',
          branchName:
              employeeData?.branchName ?? employeeData?.location ?? '-',
          location:
              employeeData?.branchName ?? employeeData?.location ?? '-',
          checkIn: null,
          checkOut: null,
          geofenceMeters: null,
          geofence: '-',
          latitude: null,
          longitude: null,
          expectedLatitude: null,
          expectedLongitude: null,
          status: 'Absent',
        },
      });
    }

    const d = attendanceSnap.docs[0].data() as AttDoc;

    const lat = Number(d.checkInLatitude ?? NaN);
    const lng = Number(d.checkInLongitude ?? NaN);
    const expLat = Number(d.expectedLatitude ?? NaN);
    const expLng = Number(d.expectedLongitude ?? NaN);
    const radius = Number(d.expectedRadius ?? 0) || 0;

    let geoMeters: number | null = null;
    if (
      Number.isFinite(lat) &&
      Number.isFinite(lng) &&
      Number.isFinite(expLat) &&
      Number.isFinite(expLng)
    ) {
      geoMeters = Math.round(
        distanceMeters({ lat, lng }, { lat: expLat, lng: expLng }),
      );
    }

    const resolvedShift =
      d.shift ||
      d.shiftGroup ||
      employeeData?.shiftGroup ||
      '-';

    const resolvedDept =
      d.dept ||
      d.department ||
      employeeData?.dept ||
      '-';

    const resolvedBranch =
      d.branchName ||
      employeeData?.branchName ||
      employeeData?.location ||
      '-';

    const status =
      d.checkIn && String(d.checkIn).trim().length > 0
        ? 'Present'
        : 'Absent';

    return res.json({
      ok: true,
      data: {
        id: d.empid,
        name: d.name ?? employeeData?.name ?? '-',
        date: d.date,
        shift: resolvedShift,
        shiftGroup: employeeData?.shiftGroup ?? d.shiftGroup ?? resolvedShift,
        dept: resolvedDept,
        department: resolvedDept,
        branchName: resolvedBranch,
        location: resolvedBranch,
        checkIn: d.checkIn ?? null,
        checkOut: d.checkOut ?? null,
        geofenceMeters: geoMeters,
        geofence: radius ? `${radius} m` : '-',
        latitude: Number.isFinite(lat) ? lat : null,
        longitude: Number.isFinite(lng) ? lng : null,
        expectedLatitude: Number.isFinite(expLat) ? expLat : null,
        expectedLongitude: Number.isFinite(expLng) ? expLng : null,
        status,
      },
    });
  } catch (e: any) {
    console.error('liveEmployeeDetails error:', e);
    return res.status(500).json({ error: e?.message || String(e) });
  }
}