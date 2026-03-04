"use strict";
// import { Request, Response } from 'express';
// import { db } from '../config/firebase';
Object.defineProperty(exports, "__esModule", { value: true });
exports.trackingCheckIn = trackingCheckIn;
exports.trackingAppendPos = trackingAppendPos;
exports.trackingCheckOut = trackingCheckOut;
exports.trackingGetDay = trackingGetDay;
const firebase_1 = require("../config/firebase");
const COL = 'tracking';
function todayIsoUTC() {
    return new Date().toISOString().slice(0, 10);
}
// Prefer explicit empid (header/query/body) and fall back to token.
// This lets admins view/save for any employee.
function pickEmpId(req) {
    const fromHeader = String(req.headers['x-empid'] || '').trim();
    const fromQuery = String(req.query.empid || '').trim();
    const fromBody = String((req.body || {}).empid || '').trim();
    const fromToken = (req.user?.empid || '').trim();
    const emp = fromHeader || fromQuery || fromBody || fromToken;
    if (!emp)
        throw new Error('empid missing (token/header/query/body)');
    return emp;
}
function dateFromReq(req) {
    const q = req.query.dateIso || req.body?.dateIso || '';
    if (/^\d{4}-\d{2}-\d{2}$/.test(q))
        return q;
    return todayIsoUTC();
}
function docId(empid, dateIso) {
    return `${empid}_${dateIso}`;
}
function pointFromBody(body) {
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
function minutesBetween(aIso, bIso) {
    return Math.abs((new Date(aIso).getTime() - new Date(bIso).getTime()) / 60000);
}
const MIN_TRACK_INTERVAL_MIN = 5;
// very small movement filter so we don't store duplicate same-spot updates
function distanceMeters(a, b) {
    const R = 6371000; // m
    const toRad = (x) => x * Math.PI / 180;
    const dLat = toRad(b.lat - a.lat);
    const dLng = toRad(b.lng - a.lng);
    const s1 = Math.sin(dLat / 2), s2 = Math.sin(dLng / 2);
    const aa = s1 * s1 + Math.cos(toRad(a.lat)) * Math.cos(toRad(b.lat)) * s2 * s2;
    return Math.round(R * (2 * Math.atan2(Math.sqrt(aa), Math.sqrt(1 - aa))));
}
const MIN_MOVE_METERS = 0;
/** POST /api/tracking/check-in */
async function trackingCheckIn(req, res) {
    try {
        const empid = pickEmpId(req);
        const dateIso = dateFromReq(req);
        const id = docId(empid, dateIso);
        const now = new Date().toISOString();
        const ref = firebase_1.db.collection(COL).doc(id);
        const data = {
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
    }
    catch (e) {
        return res.status(400).json({ error: e?.message || String(e) });
    }
}
/** POST /api/tracking/pos  — STRICT: accept at most once every 20 minutes. */
async function trackingAppendPos(req, res) {
    try {
        const empid = pickEmpId(req);
        const dateIso = dateFromReq(req);
        const id = docId(empid, dateIso);
        const pt = pointFromBody(req.body);
        const nowIso = new Date().toISOString();
        const ref = firebase_1.db.collection(COL).doc(id);
        let accepted = false;
        await firebase_1.db.runTransaction(async (tx) => {
            const snap = await tx.get(ref);
            if (!snap.exists) {
                const data = {
                    id,
                    empid,
                    dateIso,
                    pathMap: [pt],
                    startedAt: nowIso,
                    endedAt: null,
                    lastUpdateAt: nowIso,
                };
                tx.set(ref, data);
                accepted = true;
                return;
            }
            const data = snap.data();
            const list = Array.isArray(data.pathMap) ? data.pathMap : [];
            const last = list.length ? list[list.length - 1] : null;
            let allow = false;
            if (!last) {
                allow = true;
            }
            else {
                const sinceMin = minutesBetween(pt.ts, last.ts);
                // STRICT time throttle
                allow = sinceMin >= MIN_TRACK_INTERVAL_MIN;
                // Optional: if last write was long ago BUT device hasn't moved at all, still skip
                if (allow && distanceMeters({ lat: last.lat, lng: last.lng }, { lat: pt.lat, lng: pt.lng }) < MIN_MOVE_METERS) {
                    // treat as duplicate at the same spot — keep lastUpdateAt only
                    allow = false;
                }
            }
            // Debug log
            const lastPoint = last || { lat: 0, lng: 0, ts: '' };
            const distance = last
                ? distanceMeters({ lat: lastPoint.lat, lng: lastPoint.lng }, { lat: pt.lat, lng: pt.lng })
                : 0;
            const timeSinceLast = last ? minutesBetween(pt.ts, lastPoint.ts) : 0;
            console.log(`Tracking update - Allowed: ${allow}, ` +
                `Since last: ${timeSinceLast.toFixed(1)} min, ` +
                `Distance: ${distance.toFixed(1)}m, ` +
                `Accuracy: ${pt.accuracy || 'N/A'}m, ` +
                `Last: ${last ? `(${last.lat}, ${last.lng})` : 'none'}, ` +
                `New: (${pt.lat}, ${pt.lng})`);
            if (allow) {
                tx.update(ref, { pathMap: [...list, pt], lastUpdateAt: nowIso });
                accepted = true;
            }
            else {
                tx.update(ref, { lastUpdateAt: nowIso });
            }
        });
        return res.status(200).json({ ok: true, id, added: accepted ? pt : null, throttled: !accepted });
    }
    catch (e) {
        return res.status(400).json({ error: e?.message || String(e) });
    }
}
/** POST /api/tracking/check-out */
async function trackingCheckOut(req, res) {
    try {
        const empid = pickEmpId(req);
        const dateIso = dateFromReq(req);
        const id = docId(empid, dateIso);
        const ref = firebase_1.db.collection(COL).doc(id);
        const now = new Date().toISOString();
        await ref.set({ endedAt: now, lastUpdateAt: now }, { merge: true });
        return res.status(200).json({ ok: true, id, endedAt: now });
    }
    catch (e) {
        return res.status(400).json({ error: e?.message || String(e) });
    }
}
/** GET /api/tracking/day?dateIso=YYYY-MM-DD */
async function trackingGetDay(req, res) {
    try {
        const empid = pickEmpId(req);
        const dateIso = dateFromReq(req);
        const id = docId(empid, dateIso);
        const snap = await firebase_1.db.collection(COL).doc(id).get();
        if (!snap.exists) {
            const empty = {
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
    }
    catch (e) {
        return res.status(400).json({ error: e?.message || String(e) });
    }
}
//# sourceMappingURL=trackingController.js.map