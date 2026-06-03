import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { db } from "../config/firebase";
import { FieldValue } from "firebase-admin/firestore";

/**
 * Assumptions:
 * - Attendance docs live at: attendance/{attId}
 * - Each doc contains: empId:string, dateIso:"YYYY-MM-DD", checkIn?:string, checkOut?:string|boolean
 *   (Adapt field names if yours differ — the logic stays the same.)
 */
export const attendanceTrackingTrigger = onDocumentWritten(
  "attendance/{attId}",
  async (event) => {
    const before = event.data?.before?.data() as any | undefined;
    const after = event.data?.after?.data() as any | undefined;
    if (!after) return;

    const empId: string | undefined = after.empId;
    const dateIso: string | undefined = after.dateIso; // add this to your attendance doc if missing
    if (!empId || !dateIso) return;

    const hadCheckIn = !!before?.checkIn;
    const hasCheckIn = !!after.checkIn;

    // Accept boolean or string for checkOut
    const hadCheckOut = !!(before?.checkOut === true || (typeof before?.checkOut === "string" && before.checkOut));
    const hasCheckOut = !!(after.checkOut === true || (typeof after.checkOut === "string" && after.checkOut));

    const dayRef = db.collection("tracking").doc(`${empId}_${dateIso}`);

    // 1) When check-in first appears -> start tracking (do NOT clear pathMap)
    if (!hadCheckIn && hasCheckIn) {
      console.log('[AttendanceTracking] Check-in tracking seed started - empid:', empId, 'dateIso:', dateIso, 'docId:', `${empId}_${dateIso}`);
      
      // Check if attendance has valid check-in latitude/longitude
      const checkInLat = Number(after.latitude ?? after.checkInLatitude);
      const checkInLng = Number(after.longitude ?? after.checkInLongitude);
      const hasValidLocation = Number.isFinite(checkInLat) && Number.isFinite(checkInLng);
      
      console.log('[AttendanceTracking] Check-in latitude/longitude:', checkInLat, checkInLng, 'valid:', hasValidLocation);

      // Get existing tracking document to check pathMap
      const trackingSnap = await dayRef.get();
      const existingData = trackingSnap.exists ? trackingSnap.data() as any : null;
      const existingPathMap = existingData?.pathMap as Array<any> | undefined;
      const pathMapExists = existingPathMap && Array.isArray(existingPathMap) && existingPathMap.length > 0;

      console.log('[AttendanceTracking] Existing pathMap length:', existingPathMap?.length ?? 0, 'pathMap exists:', pathMapExists);

      let pathMapToSet: any[] = [];
      if (hasValidLocation && !pathMapExists) {
        // Seed pathMap with check-in location
        const seedPoint = {
          lat: checkInLat,
          lng: checkInLng,
          ts: after.checkIn || new Date().toISOString(),
          source: "check-in-seed"
        };
        pathMapToSet = [seedPoint];
        console.log('[AttendanceTracking] Seed point added - lat:', seedPoint.lat, 'lng:', seedPoint.lng, 'ts:', seedPoint.ts, 'source:', seedPoint.source);
      } else if (pathMapExists) {
        console.log('[AttendanceTracking] Seed skipped because pathMap already exists with', existingPathMap?.length, 'points');
      } else {
        console.log('[AttendanceTracking] Seed skipped because check-in location is invalid');
      }

      await dayRef.set(
        {
          id: `${empId}_${dateIso}`,
          empid: empId,
          dateIso: dateIso,
          pathMap: pathMapToSet,
          startedAt: FieldValue.serverTimestamp(),
          endedAt: null,
          lastUpdateAt: FieldValue.serverTimestamp(),
          active: true,
          fieldworkEnabled: true,
        },
        { merge: true }
      );
      return;
    }

    // 2) When check-out appears -> stop tracking (do NOT delete pathMap)
    if (!hadCheckOut && hasCheckOut) {
      await dayRef.set(
        {
          endedAt: FieldValue.serverTimestamp(),
          lastUpdateAt: FieldValue.serverTimestamp(),
          active: false,
        },
        { merge: true }
      );
      return;
    }
  }
);
