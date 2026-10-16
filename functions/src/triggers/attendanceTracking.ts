import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { db } from "../config/firebase";
import { FieldValue } from "firebase-admin/firestore";

/**
 * Safety net that mirrors attendance lifecycle onto tracking session docs.
 *
 * Attendance docs live at: attendance/{attId} with fields:
 *   empid:string, companyId:string, date:"YYYY-MM-DD",
 *   checkIn?:string, checkOut?:string|boolean
 *
 * Tracking docs are tenant-scoped: tracking/{companyId}_{empid}_{dateIso}.
 * This trigger:
 *  - creates a session doc ONLY when one does not exist (never wipes
 *    pathMap, never reopens a closed session - reopening is the exclusive
 *    job of POST /tracking/check-in which verifies active attendance);
 *  - stamps endedAt on the session doc when check-out appears.
 */
export const attendanceTrackingTrigger = onDocumentWritten(
  "attendance/{attId}",
  async (event) => {
    const before = event.data?.before?.data() as any | undefined;
    const after = event.data?.after?.data() as any | undefined;
    if (!after) return;

    const empId: string | undefined = after.empid ?? after.empId;
    const dateIso: string | undefined = after.date ?? after.dateIso;
    const companyId: string | undefined = after.companyId;
    if (!empId || !dateIso || !companyId) return;

    const hadCheckIn = !!before?.checkIn;
    const hasCheckIn = !!after.checkIn;

    // Accept boolean or string for checkOut
    const truthyCheckOut = (v: any) =>
      v === true || (typeof v === "string" && v.trim().length > 0);
    const hadCheckOut = truthyCheckOut(before?.checkOut);
    const hasCheckOut = truthyCheckOut(after.checkOut);

    const docId = `${companyId}_${empId}_${dateIso}`;
    const dayRef = db.collection("tracking").doc(docId);

    // 1) When check-in first appears -> create session doc if missing.
    //    Never touch an existing doc: preserve pathMap and any endedAt.
    if (!hadCheckIn && hasCheckIn) {
      await db.runTransaction(async (tx) => {
        const snap = await tx.get(dayRef);
        if (snap.exists) return;
        tx.create(dayRef, {
          id: docId,
          empid: empId,
          companyId,
          dateIso,
          pathMap: [],
          events: [],
          startedAt: FieldValue.serverTimestamp(),
          endedAt: null,
          lastUpdateAt: FieldValue.serverTimestamp(),
          active: true,
          fieldworkEnabled: true,
        });
      });
      return;
    }

    // 2) When check-out appears -> close the session if it exists.
    if (!hadCheckOut && hasCheckOut) {
      await db.runTransaction(async (tx) => {
        const snap = await tx.get(dayRef);
        if (!snap.exists) return;
        tx.update(dayRef, {
          endedAt: FieldValue.serverTimestamp(),
          lastUpdateAt: FieldValue.serverTimestamp(),
          active: false,
          // A closed session can never be mid-interruption.
          interruption: FieldValue.delete(),
        });
      });
      return;
    }
  }
);
