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
      await dayRef.set(
        {
          id: `${empId}_${dateIso}`,
          empid: empId,
          dateIso: dateIso,
          pathMap: [],
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
