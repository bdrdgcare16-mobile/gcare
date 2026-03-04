"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.attendanceTrackingTrigger = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const firebase_1 = require("../config/firebase");
const firestore_2 = require("firebase-admin/firestore");
/**
 * Assumptions:
 * - Attendance docs live at: attendance/{attId}
 * - Each doc contains: empId:string, dateIso:"YYYY-MM-DD", checkIn?:string, checkOut?:string|boolean
 *   (Adapt field names if yours differ — the logic stays the same.)
 */
exports.attendanceTrackingTrigger = (0, firestore_1.onDocumentWritten)("attendance/{attId}", async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!after)
        return;
    const empId = after.empId;
    const dateIso = after.dateIso; // add this to your attendance doc if missing
    if (!empId || !dateIso)
        return;
    const hadCheckIn = !!before?.checkIn;
    const hasCheckIn = !!after.checkIn;
    // Accept boolean or string for checkOut
    const hadCheckOut = !!(before?.checkOut === true || (typeof before?.checkOut === "string" && before.checkOut));
    const hasCheckOut = !!(after.checkOut === true || (typeof after.checkOut === "string" && after.checkOut));
    const dayRef = firebase_1.db.collection("tracking").doc(empId).collection("days").doc(dateIso);
    // 1) When check-in first appears -> start tracking (do NOT clear pathMap)
    if (!hadCheckIn && hasCheckIn) {
        await dayRef.set({
            active: true,
            fieldworkEnabled: true,
            startedAt: firestore_2.FieldValue.serverTimestamp(),
        }, { merge: true });
        return;
    }
    // 2) When check-out appears -> stop tracking
    if (!hadCheckOut && hasCheckOut) {
        await dayRef.set({
            active: false,
            endedAt: firestore_2.FieldValue.serverTimestamp(),
        }, { merge: true });
        return;
    }
});
//# sourceMappingURL=attendanceTracking.js.map