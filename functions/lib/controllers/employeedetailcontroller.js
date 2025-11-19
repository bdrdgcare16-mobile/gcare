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
exports.getRequestDetails = getRequestDetails;
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
/* ------------------------- small utils ------------------------- */
const toFloat = (v) => {
    if (v === null || v === undefined)
        return undefined;
    const n = Number(v);
    return Number.isFinite(n) ? n : undefined;
};
const pickStr = (o, keys, fallback = '') => {
    for (const k of keys) {
        const v = o?.[k];
        if (v !== undefined && v !== null) {
            const s = String(v).trim();
            if (s)
                return s;
        }
    }
    return fallback;
};
const H_EARTH = 6371000; // meters
const haversine = (a, b) => {
    const dLat = ((b.lat - a.lat) * Math.PI) / 180;
    const dLng = ((b.lng - a.lng) * Math.PI) / 180;
    const la1 = (a.lat * Math.PI) / 180;
    const la2 = (b.lat * Math.PI) / 180;
    const h = Math.sin(dLat / 2) ** 2 +
        Math.cos(la1) * Math.cos(la2) * Math.sin(dLng / 2) ** 2;
    return H_EARTH * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h));
};
/* --------------------- fetch helpers (Firestore) --------------------- */
async function getAttendanceById(id) {
    const snap = await db.collection('attendance').doc(id).get();
    return snap.exists ? { id: snap.id, ...snap.data() } : null;
}
async function getOtherLocById(id) {
    const snap = await db.collection('otherLocation').doc(id).get();
    return snap.exists ? { id: snap.id, ...snap.data() } : null;
}
async function getAttendanceByEmpDate(empid, date) {
    const q = await db
        .collection('attendance')
        .where('empid', '==', empid)
        .where('date', '==', date)
        .limit(1)
        .get();
    if (q.empty)
        return null;
    const d = q.docs[0];
    return { id: d.id, ...d.data() };
}
async function getOtherLocByEmpDate(empid, date) {
    const q = await db
        .collection('otherLocation')
        .where('empid', '==', empid)
        .where('date', '==', date)
        .limit(1)
        .get();
    if (q.empty)
        return null;
    const d = q.docs[0];
    return { id: d.id, ...d.data() };
}
/* --------------------- merge + normalize payload --------------------- */
function normalize(attendance, otherLoc) {
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
    const expectedLatitude = toFloat(srcA.expectedLatitude) ?? toFloat(srcO.expectedLatitude) ??
        toFloat(srcA.branchLatitude) ?? toFloat(srcO.branchLatitude);
    const expectedLongitude = toFloat(srcA.expectedLongitude) ?? toFloat(srcO.expectedLongitude) ??
        toFloat(srcA.branchLongitude) ?? toFloat(srcO.branchLongitude);
    const expectedRadius = toFloat(srcO.expectedRadius) ?? toFloat(srcA.expectedRadius) ?? toFloat(srcO.radius) ?? toFloat(srcA.radius);
    // request location (prefer otherLocation doc if exists)
    const latitude = toFloat(srcO.latitude) ?? toFloat(srcA.latitude) ??
        toFloat(srcA.checkInLatitude) ?? toFloat(srcA.checkOutLatitude);
    const longitude = toFloat(srcO.longitude) ?? toFloat(srcA.longitude) ??
        toFloat(srcA.checkInLongitude) ?? toFloat(srcA.checkOutLongitude);
    // distance/within
    let distanceFromBranch = toFloat(srcO.distanceFromBranch) ?? toFloat(srcA.distanceFromBranch);
    if (distanceFromBranch === undefined &&
        expectedLatitude !== undefined &&
        expectedLongitude !== undefined &&
        latitude !== undefined &&
        longitude !== undefined) {
        distanceFromBranch = haversine({ lat: expectedLatitude, lng: expectedLongitude }, { lat: latitude, lng: longitude });
    }
    let withinRadius = srcO.withinRadius ?? srcA.withinRadius;
    if (withinRadius === undefined && expectedRadius !== undefined && distanceFromBranch !== undefined) {
        withinRadius = distanceFromBranch <= expectedRadius;
    }
    // status
    const status = pickStr({ ...srcA, ...srcO }, ['status', 'approvalStatus']) || 'Pending';
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
async function getRequestDetails(req, res) {
    try {
        const id = String(req.query.id ?? '').trim();
        const src = String(req.query.src ?? '').trim().toLowerCase();
        const emp = String(req.query.empid ?? '').trim();
        const date = String(req.query.date ?? '').trim();
        let attendance = null;
        let otherLoc = null;
        if (id) {
            if (src === 'other_location') {
                otherLoc = await getOtherLocById(id);
                const empid = pickStr(otherLoc, ['empid']);
                const d = pickStr(otherLoc, ['date']).slice(0, 10);
                if (empid && d)
                    attendance = await getAttendanceByEmpDate(empid, d);
            }
            else {
                attendance = await getAttendanceById(id);
                const empid = pickStr(attendance, ['empid']);
                const d = pickStr(attendance, ['date']).slice(0, 10);
                if (empid && d)
                    otherLoc = await getOtherLocByEmpDate(empid, d);
            }
        }
        else if (emp && date) {
            attendance = await getAttendanceByEmpDate(emp, date.slice(0, 10));
            otherLoc = await getOtherLocByEmpDate(emp, date.slice(0, 10));
        }
        else {
            return res.status(400).json({ error: 'Provide (id & src) or (empid & date)' });
        }
        if (!attendance && !otherLoc) {
            return res.status(404).json({ error: 'No records found' });
        }
        const merged = normalize(attendance, otherLoc);
        return res.json(merged);
    }
    catch (err) {
        console.error('getRequestDetails error', err);
        return res.status(500).json({ error: err?.message ?? 'Server error' });
    }
}
//# sourceMappingURL=employeedetailcontroller.js.map