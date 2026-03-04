"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.getOvertimeHours = void 0;
const admin = __importStar(require("firebase-admin"));
// Firestore reference
const db = admin.firestore();
/**
 * GET /api/overtime?empid=EMP001&date=2025-10-28
 * Returns overtime hours for an employee on the given date
 */
const getOvertimeHours = async (req, res) => {
    try {
        const empid = req.query.empid?.toString().trim();
        const date = req.query.date?.toString().trim();
        if (!empid || !date) {
            res.status(400).json({ ok: false, error: "Missing empid or date" });
            return;
        }
        const snapshot = await db
            .collection("leaves")
            .where("empid", "==", empid)
            .where("leaveType", "==", "Overtime")
            .where("startDate", "==", date)
            .where("endDate", "==", date)
            .limit(1)
            .get();
        if (snapshot.empty) {
            res.json({ ok: true, overtimeHours: 0 });
            return;
        }
        const data = snapshot.docs[0].data();
        const duration = Number(data.duration ?? 0);
        res.json({ ok: true, overtimeHours: duration });
    }
    catch (error) {
        console.error("Error fetching overtime:", error);
        res.status(500).json({ ok: false, error: error.message || "Internal Server Error" });
    }
};
exports.getOvertimeHours = getOvertimeHours;
//# sourceMappingURL=overtimecontroller.js.map