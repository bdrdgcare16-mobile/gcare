# SERV HRMS — GPS Tracking Deep Audit & Production Readiness

**Project:** `F:\serv\gcare`
**Environment audited:** DEV Firebase Emulators (`serv-dev-f2557`) + full source inspection
**Scope:** Employee-side + HR/Admin-side GPS tracking, attendance geo-integration, RBAC/tenant isolation, spoofing threat model
**Audit type:** Read-only. No code, rules, data, or configuration were modified. Live verification used synthetic employees (`TRK-*`) and synthetic coordinates only.

---

## 1. Executive Summary

The GPS tracking system is **functional but not production-ready**. Location collection works end-to-end on Android (foreground service + Workmanager + in-app service → REST API → Firestore `tracking` day documents), tenant isolation is correctly enforced server-side, and Firestore rules fully deny direct client access to tracking data. However, the audit found **critical lifecycle failures** (tracking continues after logout; the server never actually closes a tracking session; a repeated check-in wipes the day's recorded path), a **client-trust design** in which all coordinates are supplied by the caller with no replay protection, no device-integrity layer, and only a coarse speed check, and a **major platform gap**: Flutter Web performs exactly one location capture at check-in and nothing thereafter.

Overall verdict: **NOT production-ready** for tamper-evident employee location tracking. Suitable for a supervised pilot where tracking is informational only.

### Severity summary

| Severity | Count | Headlines |
|---|---|---|
| Critical | 2 | Tracking continues after logout (7-day JWT + live background isolate); `/tracking/pos` accepts points after check-out — server never closes the session |
| High | 4 | Re-check-in wipes `pathMap`/`events` (verified live); coordinates fully client-trusted; tracking starts even when the company has no `tracking` entitlement (client doesn't check); `isMocked` is client-asserted and absent from `/pos` entirely |
| Medium | 9 | No tracking restart after app kill/reboot; Web = single point only; forged tracking events self-injectable; no captured-at timestamp (server stamps arrival); `pathMap` silently truncated to 200; no device/integrity metadata; attendance↔tracking not linked; pending-queue stores raw JWT; legacy tenants auto-get tracking |
| Low / Info | 5 | Event dedupe windows, verbose request logging, minor timezone drift, double check-in POST, permission prompt shown once only |

---

## 2. Existing Tracking Architecture

### 2.1 Components

| Layer | File | Role |
|---|---|---|
| In-app tracker | `lib/services/tracking_service.dart` | `TrackingService` — check-in-time capture, connectivity/sync listeners, pending queue. Its periodic timer was **deliberately disabled** (lines 97–111) and delegated to the Android foreground service. |
| Background isolate | `lib/features/users/background_tasks.dart` | Android foreground service (`flutter_background_service`, `isForegroundMode`, `foregroundServiceTypes: [location]`), `Timer.periodic` every **20 min** (line 44), GPS sampling, pending-queue sync, permission/service-state events. |
| Offline event queue | `lib/services/tracking_events.dart` | SharedPreferences-backed queue (cap 100) for `/tracking/event` posts; dedupe by signature and `eventId`. |
| Offline point queue | `tracking_service.dart` lines 464–522 + `background_tasks.dart` lines 366–484 | SharedPreferences queue (cap 200) for `/tracking/pos` payloads. |
| Logout | `lib/utils/logout.dart` | Posts `/tracking/check-out`, clears session keys — **does not stop tracking** (see F-01). |
| App bootstrap | `lib/main_common.dart` | `initializeBackgroundSystems()` (Android only, line 50/101); `startFgTracking`/`stopFgTracking` wrappers. |
| Employee view | `lib/features/users/my_track_page.dart` | `GET /tracking/day` → polyline map + event list. |
| HR/Admin view | `lib/features/admin/employee_detail_page.dart` | `GET /tracking/day?empid=` → map + "View Tracking Event" sheet. |
| Attendance page | `lib/features/users/attendance_page.dart` | Starts tracking on check-in (lines 2222–2238), stops on check-out (lines 2489–2502). |
| API | `functions/src/routes/trackingRoutes.ts` → `controllers/trackingController.ts` | 5 endpoints, day-document model in Firestore `tracking` collection. |
| HR detail API | `functions/src/routes/liveEmployeeDetailsRoutes.ts` → `liveEmployeeDetailsController.ts` | Per-employee attendance detail incl. check-in coordinates + geofence distance. |

### 2.2 API inventory

| Method | Endpoint | Caller | Role required | Entitlement | Payload | Firestore | Isolation |
|---|---|---|---|---|---|---|---|
| POST | `/api/tracking/check-in` | `TrackingService.startAfterCheckIn`, `_trackingCheckInAndSeed` | Any authenticated tenant role (no `roleMiddleware`); employee→self, admin/HR→same-company override | `tracking` (tenant) + `tracking` (HR) | `{empid?}` | `tracking/{companyId}_{empid}_{YYYY-MM-DD}` | JWT `companyId`; `pickEmpId` verifies `employees.companyId` for overrides |
| POST | `/api/tracking/pos` | `TrackingService._postPos`, BG isolate `_pingServer`, pending-sync | Caller must have `empid` in JWT → effectively **employee only** | same | `{lat, lng, accuracy?, source?, ts(ignored)}` | appends `pathMap[]` | token `empid` only (`allowAdminOverride:false`) |
| POST | `/api/tracking/check-out` | `_performCheckOut` success path, `logout()` | same as check-in | same | `{empid?, dateIso?, eventId?}` | sets `endedAt`, appends `account_logged_out` | as above |
| POST | `/api/tracking/event` | `TrackingEvents.report` (mock, gps on/off, poor_gps, logout) | employee-only effectively (`allowAdminOverride:false`) | same | `{type, message?, latitude?, longitude?, accuracy?, eventId?}` | appends `events[]` | token `empid` only |
| GET | `/api/tracking/day?empid=&dateIso=` | `my_track_page`, `employee_detail_page`, `api_service.dart:712` | `admin`, `hr`, `employee` (route-level role gate) | `tracking`; HR may pass with `attendance` approval too | — | reads day doc (namespaced + legacy fallback) | employee→own; admin/HR→same-company verified via `employeeBelongsToCompany` |

### 2.3 Data model — `tracking/{companyId}_{empid}_{YYYY-MM-DD}`

```
id           string   (namespaced; legacy docs used {empid}_{date})
empid        string
companyId    string | absent on legacy docs
dateIso      "YYYY-MM-DD" (Asia/Kolkata, server-derived)
pathMap      TrackPoint[]  — {lat, lng, ts(server), accuracy?, source?}  (cap: last 200)
events       TrackEvent[]  — {type, ts(server), message?, latitude?, longitude?, accuracy?, eventId?}
startedAt    ISO  | endedAt ISO|null  | lastUpdateAt ISO
```

Event types (server whitelist, `trackingController.ts:47–55`): `poor_gps`, `gps_disabled`, `location_disabled`, `location_enabled`, `account_logged_out`, `mock_location_detected`, `impossible_travel`.

**Client-generated:** `lat`, `lng`, `accuracy`, `source`, event `type`/`message`/`eventId`.
**Server-generated:** `ts` (always `new Date().toISOString()` — device time is never trusted), `id`, `dateIso`, `startedAt`/`endedAt`/`lastUpdateAt`, `companyId`/`empid` (from JWT).
**Missing fields** (vs. expected schema): no `userId`, no `capturedAt` (device capture time is discarded — `pointFromBody` ignores body `ts`, line 231), no location provider/source metadata beyond free-text `source`, no device/platform metadata, no session ID, no attendance-record link, no `isMocked` field on `/pos`.

---

## 3. Employee Tracking Flow

### Scenario A — Login

- Location permission is **not** requested at login. `LocationPermissionDialog.showIfNeeded` runs once on the Home screen (`home_screen_page.dart:44–50`), and only when `Permission.location.status.isDenied` and the dialog was never shown (`location_permission_dialog.dart:18–22`). "Not Now" permanently suppresses re-prompting (flag is only set on "Allow").
- **No tracking starts at login.** Tracking starts only on successful attendance check-in (`attendance_page.dart:2222–2238` → `startFgTracking` + `scheduleBackgroundTracking` + `TrackingService.startAfterCheckIn`).
- Trigger chain: `/attendance/check-in` 200 → (a) `_trackingCheckInAndSeed` posts `/tracking/check-in` + `/tracking/pos`; (b) Android foreground service starts; (c) Workmanager 15-min periodic task registered (sync-only); (d) `TrackingService` captures one sampled fix and starts connectivity/GPS-state listeners.

### Scenario B — Check-in

- GPS captured before the attendance POST via `_getHighAccuracyPosition` (geofencing ON) or `_getBestEffortPosition` (geofencing OFF — may return `null`). Payload sends `latitude`, `longitude`, `accuracy`, `isMocked`, `source` (manual/biometric), plus client-computed `distanceFromBranch`/`withinRadius` (never trusted server-side).
- Backend (`attendanceController.ts:443–489`): `isMocked:true` → 422 `LOCATION_UNTRUSTED` + `mock_location_detected` tracking event; geofencing applies → coordinates mandatory, `accuracy > 50m` → 422 `POOR_GPS` + `poor_gps` event.
- **Attendance and tracking records are not linked** — no shared session/attendance ID. The tracking doc is created by an independent `/tracking/check-in` call; the seed point posted by `_trackingCheckInAndSeed` omits `accuracy` (line 2548).

### Scenario C — Active working hours

| Condition | Result |
|---|---|
| Tracking interval | FG service every **20 min**; server throttles `/pos` to one accepted point per **15 min** and ≥10 m movement. Workmanager ticks every ~15 min but is **sync-only** (retries queued points/events). |
| Foreground (app open, Android) | WORKING — FG service timer runs in a separate isolate. |
| App minimized (Android) | WORKING — foreground service persists (persistent notification). |
| App terminated / swiped (Android) | **PARTIAL→NOT WORKING** — FG service may be killed; `autoStart:false` (no boot receiver), and app relaunch does **not** re-call `startFgTracking`/`startAfterCheckIn` — only the UI check-in state is restored (`_restoreCheckInFromPrefs`). Tracking silently stops until next check-in. |
| Device restarted | NOT IMPLEMENTED — no boot receiver; Workmanager resumes (sync-only). |
| Browser tab minimized (Web) | PARTIAL — no FG service/Workmanager on web; `TrackingService` periodic timer is disabled. Only connectivity/sync listeners remain. |
| Browser tab closed / Web reload | **NOT IMPLEMENTED** — after reload, `TrackingService` is a page-local object; nothing restarts it. **On Web, tracking = exactly one point at check-in.** |
| Screen locked (Android) | WORKING (FG service). |
| Internet disconnected | WORKING (queue) — failed posts enqueue to SharedPreferences (cap 200 points/100 events) and sync on connectivity restore, FG tick, or next `startAfterCheckIn`. |
| GPS disabled | PARTIAL — FG tick detects `isLocationServiceEnabled()==false` → `location_disabled` event (deduped via persisted state). Points simply stop. Web: `getServiceStatusStream` is unsupported → no event. |
| Permission revoked | PARTIAL — FG tick detects denied → `gps_disabled` event once (persisted flag), then skips capture. Detection latency up to 20 min. |

### Scenario D — Check-out

`/attendance/check-out` 200 → `stopFgTracking()` + `cancelBackgroundTracking()` + `TrackingService.stopAfterCheckOut()` (cancels all subscriptions/queues flush) + `_trackingCheckOut()` posts `/tracking/check-out` → server sets `endedAt` + `account_logged_out` event (idempotent via `logout_{empid}_{date}`).

**Gap:** the server does not enforce session closure — `/tracking/pos` never checks `endedAt`. Verified live: a point submitted after check-out was **accepted and appended** (`added: {…}`, `throttled:false`). Any client (or stolen token) can keep writing coordinates after check-out.

### Scenario E — Logout

`logout()` (`lib/utils/logout.dart`):

- ✅ Posts `/tracking/check-out` (best-effort; queued with embedded JWT if offline).
- ❌ **Does NOT** call `stopForegroundTracking()`, `stopAfterCheckOut()`, or `cancelBackgroundTracking()`.
- ❌ Clears `token`, `empid`, `role`, etc. — but **not** `bg_token`/`bg_empid` (written by `setTrackingIdentity`, `background_tasks.dart:138–147`).
- ❌ JWTs are stateless with `JWT_EXPIRES_IN = '7d'` (`auth.utils.ts:11`) — no revocation list, no token version.

**Result (Critical):** after logout, the Android foreground-service isolate keeps posting `/tracking/pos` every 20 minutes for up to 7 days (until process death or token expiry), writing real GPS coordinates to the `tracking` doc — a post-session privacy violation invisible to the user.

---

## 4. HR / Admin Tracking Flow

| Capability | Status | Evidence |
|---|---|---|
| View employee check-in coordinates | IMPLEMENTED | `/api/liveEmployeeDetails/:empid` returns `latitude/longitude` + `geofenceMeters` + `expectedRadius` (admin/HR + `attendance` gate) |
| View day's path on map | IMPLEMENTED | `employee_detail_page.dart` "Geolocation" button → `/tracking/day?empid=` → polyline |
| View tracking events (GPS off, mock, impossible travel, logout) | IMPLEMENTED | Event bottom-sheet, `_getTrackingEvents` (lines 320–351) |
| Employee self-view | IMPLEMENTED | `my_track_page.dart` ("My Track" gated by `FeatureAccess.tracking`, `myserv_page.dart:45`) |
| Live/all-employee map or last-known-location board | **MISSING** — `/attendance/live` returns status only, no coordinates; no fleet view |
| Distinguish live vs. stale | PARTIAL — `lastUpdateAt` exists in the doc but is not surfaced in the UI |
| GPS-gap/tracking-stopped detection | PARTIAL — events exist if the device reports them; a silent kill/offline produces only missing points, no alert |
| Suspected-spoofing review workflow | PARTIAL — `mock_location_detected`/`impossible_travel` events are displayed but there is no alert list, severity flag, or resolution workflow |
| Outside-geofence approval | IMPLEMENTED — `/attendance/other-location` list + `/other-location/decision` |
| Filters (employee/dept/branch/date) | PARTIAL — per-employee date picker only; no cross-employee filters |
| Company Admin access | NOT IMPLEMENTED — `roleMiddleware` on `/day` + `pickEmpId` 403s `company_admin` (verified live). CA manages HR users only — consistent with role design but worth confirming as intended |
| HR without `tracking` approval | Reads allowed only if `attendance` approved (`hrFeatureGate(['tracking','attendance'])`, route line 28) — deliberate, but widens tracking visibility to attendance-only HR |

---

## 5. Geofencing Audit (separate mechanism — confirmed)

Continuous tracking and geofencing are **independent**: geofencing is evaluated only inside `attendance/check-in`/`check-out` via `resolveAttendanceGeoPolicy` (tenant `enabledFeatures` → `attendance` + `geofencing`), while tracking is a separate entitlement (`tracking`) with its own routes and day documents.

- **Mode A (geofencing off):** attendance works without GPS; tracking still runs if `tracking` is enabled. Verified (Mode A check-in/out pass with no coords; tracking posts succeed in tracking-enabled companies).
- **Mode B (geofencing on):** server-side Haversine vs office doc; inside → accept; outside → attendance recorded + `Pending` `otherLocation` event (admin/HR approval workflow at `/attendance/other-location*`); missing/invalid office → 422 `GEO_FENCE_NOT_CONFIGURED`; no coords → 422 `LOCATION_REQUIRED`; `accuracy>50m` → 422 `POOR_GPS`; `isMocked` → 422 `LOCATION_UNTRUSTED`. All previously verified (31/31 emulator matrix).
- Legacy tenants (no `enabledFeatures`) → `legacyCompatibilityMode` (implicit office enforcement preserved) and, separately, `companyHasFeature` grants **all** features including `tracking` — verified live (`apitest-co` `/pos` → 200).

---

## 6. Role-Based Security & Multi-Tenancy (live-verified)

| Caller | `/pos` write | `/day` read | Result |
|---|---|---|---|
| Unauthenticated | — | — | 401 ✅ |
| Employee (own) | 200 | 200 | ✅ `empid` from JWT; `?empid=`/`x-empid`/body overrides **ignored** (verified — foreign `x-empid` post still wrote to own doc) |
| Employee (other empid) | 403 | own doc returned | ✅ no impersonation possible |
| Admin (same company) | 403 (no `empid` in admin token) | 200 with `?empid=` | ✅ `employeeBelongsToCompany` enforced |
| Admin (other company) | 403 | **403 verified** (`Employee not found in your company`) | ✅ tenant isolation holds |
| HR + `tracking` approval | 403 (no empid) | **200 verified** | ✅ |
| HR + no approval | 403 | **403 verified** (`Feature not approved`) | ✅ |
| HR + `attendance` only | 403 | 200 (by design) | ⚠️ see F-14 |
| `company_admin` | **403 verified** | **403 verified** | ✅ excluded |
| `platform_admin` / `super_admin` | 403 | **403 verified** (roleMiddleware excludes them before the controller's super_admin branch) | ✅ no tenant GPS access |
| Client-supplied `companyId` | — | — | JWT wins; body/query `companyId` only consulted when the token has none |
| Direct Firestore (client SDK) | — | — | **Denied** — `tracking` has no rules match → default `allow read, write: if false` (rules L85–86) |

No IDOR, mass-assignment, or cross-tenant write path was found. All tracking queries derive `companyId`/`empid` from the verified JWT and re-verify employee↔company membership server-side.

---

## 7. GPS Spoofing & Fake-Location Threat Model

**Fundamental posture:** the backend **trusts client-supplied `lat`/`lng`/`accuracy` on `/tracking/pos`** — the only server checks are bounds (`|lat|≤90`, `|lng|≤180`), a ≥15-min/≥10-m throttle, and a >180 km/h impossible-travel flag between accepted points (audit-only — the point is dropped, an event is recorded). There is **no Firebase App Check, Play Integrity, or device attestation anywhere in the repo** (grep: zero matches). A JWT-authenticated caller can write arbitrary coordinates.

| Vector | Possible? | Existing control | Residual risk |
|---|---|---|---|
| A. Android mock-location app | Yes | `Position.isMocked` checked client-side (attendance + tracking sampling); `mock_location_detected` event | **High** — `isMocked` is unreliable on many devices/Android versions and trivially hidden by modified clients; `/pos` has no mock field at all |
| B. Browser devtools geolocation override | Yes | None — `isMocked` is always false on web; Web can't distinguish | **High** on Web |
| C. Modified frontend | Yes | None (no app attestation) | **High** |
| D. Direct API call with fabricated lat/lng | **Yes — verified live** | None beyond bounds | **High** — curl/Postman with a valid employee JWT writes any coordinate |
| E. Replayed previous payloads | Yes | 15-min throttle only; no nonce/signature | **Medium–High** — replaying a valid in-office fix is undetectable |
| F. Modified device time | Mitigated | Server stamps `ts`; client `ts` ignored | **Low** for server timestamps — but device capture time is discarded entirely (no `capturedAt`), so offline-queued points are re-stamped at arrival |
| G. Rooted/jailbroken | Yes | None (no root detection, no attestation) | **High** |
| H. Emulator/simulated GPS | Yes | None | **High** |
| I. Proxy manipulation | Partially | HTTPS protects transit; a tampered client just emits different coords anyway | Same as C/D |
| J. Compromised client | Yes | None | **High** |

**Honest assessment:** GPS spoofing **cannot be fully prevented** — only detected and deterred. Current detection is minimal: client-side `isMocked` (self-reported), one 180 km/h speed check, and manual HR review of a per-day event list. A motivated employee can produce an undetectable track by (a) calling the API directly, (b) replaying office coordinates, or (c) using a mock provider that doesn't set `isMocked`.

---

## 8. Findings Register

### F-01 — Tracking continues after logout — **Critical**
- **File:** `lib/utils/logout.dart` (whole function); `lib/features/users/background_tasks.dart:138–147`; `functions/src/common/auth.utils.ts:11`
- **Observed:** `logout()` posts `/tracking/check-out` and clears session prefs but never stops the foreground service/Workmanager/in-app service and never clears `bg_token`/`bg_empid`. The BG isolate holds `_token` in memory and keeps posting every 20 min.
- **Expected:** logout stops all tracking and invalidates the credentials the background isolate uses.
- **Evidence:** no `stopForegroundTracking`/`cancelBackgroundTracking`/`stopAfterCheckOut` call anywhere in `logout()`; `bg_*` keys not in the cleared list; JWT TTL `7d`, no revocation.
- **Impact:** employee location recorded after logout (privacy violation, consent boundary breach); points keep landing in the day's doc.
- **Fix:** call `stopFgTracking()` + `cancelBackgroundTracking()` + `TrackingService.stopAfterCheckOut()` inside `logout()` **before** clearing prefs; delete `bg_empid`/`bg_token`/`tracking_pending_*`; add server-side session closure (F-02) as defense-in-depth; consider token versioning.
- **Verify:** check-in → logout → assert no `/pos` accepted >20 min later; assert `bg_*` prefs absent.

### F-02 — Server never closes the tracking session — **Critical**
- **File:** `functions/src/controllers/trackingController.ts` `trackingAppendPos` (298–408)
- **Observed:** `/pos` appends to the day doc regardless of `endedAt`. **Verified live:** `check-in` → `check-out` → `/pos` returned `added:{…}, throttled:false` — a post-checkout point was written.
- **Expected:** after `endedAt`, writes are rejected (except an explicit session re-open on a new check-in).
- **Impact:** check-out and logout do not actually stop server-side recording; any retained/stolen token keeps writing.
- **Fix:** in the transaction, reject when `data.endedAt` is set (409 `SESSION_CLOSED`); re-open explicitly on `/tracking/check-in` only.
- **Verify:** post-checkout `/pos` must 4xx; second check-in reopens.

### F-03 — Repeated `/tracking/check-in` wipes the day's data — **High**
- **File:** `trackingController.ts:269–295`
- **Observed:** `ref.set({pathMap:[], events:[], endedAt:null,…}, {merge:true})` — `merge` replaces array fields. **Verified live:** after a second check-in, `pathMap` was `[]` and `endedAt` reset to `null`. `pickEmpId` allows admin/HR override, so a same-company admin can wipe another employee's day.
- **Expected:** idempotent session-open that preserves `pathMap`/`events`; only reset `endedAt`.
- **Impact:** loss of the day's location history and audit events; accidental wipe is routine — `_trackingCheckInAndSeed` **and** `startAfterCheckIn` both POST `/tracking/check-in` on every check-in (`attendance_page.dart:2225,2238`), so the seeded point is always erased.
- **Fix:** `set` without array fields when doc exists; `FieldValue.delete()`/`arrayUnion` semantics; or no-op when `startedAt` exists.
- **Verify:** check-in → pos → check-in again → `pathMap` retains points.

### F-04 — Coordinates fully client-trusted on `/pos` — **High**
- **File:** `trackingController.ts` `pointFromBody` (222–232), throttle/impossible-travel (348–375)
- **Observed:** any in-bounds `lat/lng` accepted; `accuracy` optional and unverified; `source` free text. **Verified live:** arbitrary coordinate written.
- **Impact:** D/E-class spoofing undetectable; HR may treat fabricated tracks as real.
- **Fix:** require `accuracy` within bounds; per-company plausibility (distance from last point/office, dwell analysis); optional office-proximity scoring; record `provider`/device metadata.
- **Verify:** out-of-band post to `/pos` with absurd accuracy/geometry flagged or rejected.

### F-05 — `isMocked` is client-asserted; no device integrity — **High**
- **File:** `attendanceController.ts:443–460`; `tracking_service.dart:617–632`; `background_tasks.dart:230–243`
- **Observed:** attendance rejects when client sends `isMocked:true`; tracking just skips + self-reports. A spoofed client sends `false` or omits it. No App Check/Play Integrity/SafetyNet anywhere.
- **Impact:** mock-GPS and rooted-device spoofing undetected.
- **Fix:** Firebase App Check on the API + Functions; Play Integrity (Android) / App Attest (iOS); server-side anomaly heuristics (F-04); treat missing integrity token as high-risk.
- **Verify:** requests without App Check token rejected; mocked-position smoke test flags event.

### F-06 — Tracking starts without the `tracking` entitlement — **High**
- **File:** `attendance_page.dart:2222–2238`
- **Observed:** tracking start calls are unconditional — no `FeatureAccess.tracking` check. In a company without `tracking`, every post 403s → payloads queue indefinitely (200 cap) → battery drain + a "Location tracking active" foreground notification for a feature that isn't enabled.
- **Fix:** gate all tracking start on `FeatureAccess.has(FeatureAccess.tracking)`.
- **Verify:** attendance-only company → no FG notification, no `/tracking/*` calls.

### F-07 — Stateless 7-day JWTs; no revocation — **High**
- **File:** `auth.utils.ts:11`, `authMiddleware.ts` (no user-status check per request)
- **Observed:** disabled/deleted users and post-logout sessions keep working until `exp`. Also feeds F-01.
- **Fix:** shorter TTL + refresh, or per-request `users.status` check, or token `version`/`jti` revocation.
- **Verify:** deactivate user → next API call 401/403.

### F-08 — Tracking silently dies on app kill/reboot — **Medium**
- **File:** `main_common.dart` (`autoStart:false`, Android-only init), `attendance_page.dart` (restore path never restarts tracking)
- **Observed:** after process death, nothing restarts the FG service until the next check-in. HR sees unexplained gaps.
- **Fix:** BootReceiver/`onBoot` restart, resume check in `initState` when `isCheckedIn`, heartbeat/dead-man's switch (`expected point every N min`) so gaps are events, not silence.
- **Verify:** kill app mid-shift → reopen → points resume; reboot → resumed or explicit `tracking_interrupted` event.

### F-09 — Flutter Web captures exactly one point — **Medium**
- **File:** `background_tasks.dart` (`_isAndroid` guards), `tracking_service.dart:97–111` (periodic disabled)
- **Observed:** on web, no FG service, no Workmanager, disabled in-app periodic → only the check-in capture exists; no GPS-off events (`getServiceStatusStream` unsupported).
- **Impact:** web employees appear untracked; product behaves differently per platform without the UI disclosing it.
- **Fix:** document web as check-in-snapshot only, or add a web-safe `Timer.periodic` while the tab is open; hide "tracking active" claims on web.
- **Verify:** web check-in → wait 45 min → count points.

### F-10 — No `capturedAt`; offline points stamped at arrival — **Medium**
- **File:** `trackingController.ts:231` (body `ts` ignored)
- **Observed:** queued points get the **sync time**, not the capture time — timeline distortion after offline periods; stale-location concept unimplementable.
- **Fix:** accept client `capturedAt` alongside server `serverReceivedAt`; sanity-check skew; reject absurdly old captures.
- **Verify:** offline point synced later shows correct capture time.

### F-11 — Employees can self-inject whitelisted events — **Medium**
- **File:** `trackingController.ts` `trackingAddEvent` (501–568)
- **Observed:** **verified live** — `gps_disabled` injected into own doc (200). An employee can fabricate "GPS disabled"/"logged out" events to excuse gaps, or plant `mock_location_detected`/`impossible_travel` noise.
- **Fix:** restrict which types clients may emit (e.g., server-derived `impossible_travel` only internally), mark client-reported events `reportedBy:'client'`, treat them as advisory.
- **Verify:** `impossible_travel` POST → 400; `gps_disabled` → stored with client-source flag.

### F-12 — `pathMap` silently truncated to 200 — **Medium**
- **File:** `trackingController.ts:383` (`list.slice(-199)`)
- **Observed:** earliest points discarded with no marker. At 15-min cadence a >50-hour continuous session overflows; combined with F-02's never-closed sessions, truncation is reachable.
- **Fix:** cap is fine but record `droppedCount`/`truncated:true`; prefer subcollections or daily+hourly sharding for history.
- **Verify:** >200 points → flag present.

### F-13 — Legacy tenants auto-get tracking — **Medium**
- **File:** `featureMiddleware.ts`/`entitlementService` (`companyHasFeature` legacy allow-all)
- **Observed:** **verified live** — `apitest-co` (no `enabledFeatures`) `/pos` → 200.
- **Impact:** privacy-sensitive feature enabled by default for legacy tenants.
- **Fix:** treat `tracking` like `geofencing` — exclude sensitive features from legacy allow-all, or require explicit opt-in.
- **Verify:** legacy company `/pos` → 403.

### F-14 — `attendance`-only HR can read tracking days — **Medium/Low**
- **File:** `trackingRoutes.ts:23–30` (`hrFeatureGate(['tracking','attendance'])`)
- **Observed:** deliberate (comment lines 21–22), but gives tracking data to HR approved for attendance only.
- **Fix:** confirm business intent; if not intended, gate `/day` on `tracking` only for HR.
- **Verify:** attendance-only HR → 403 on `/tracking/day` (if fixed).

### F-15 — No replay/idempotency key or signature on `/pos` — **Medium/Low**
- **File:** `/pos` handler; only time+movement throttle.
- **Fix:** add `pointId` dedupe + optional HMAC/device binding once App Check exists.

### F-16 — No session link to attendance; tracking startable without check-in — **Low**
- **Observed:** `POST /tracking/check-in` creates a session with no attendance record (verified — synthetic employee did exactly this). `startedAt` is client-call timing.
- **Fix:** bind tracking session to the attendance doc ID; server-opens session inside `/attendance/check-in`.

### F-17 — Raw JWT + coordinates in plaintext SharedPreferences — **Low/Medium**
- **File:** `tracking_events.dart` (`__token` in queue), `background_tasks.dart` (`bg_token`)
- **Impact:** device-level extraction = 7-day credential + location history.
- **Fix:** `flutter_secure_storage` for tokens; encrypt or expire queued items; delete on logout (F-01).

### F-18 — Verbose request/structure logging — **Low**
- `trackingController.ts` logs every `/pos` decision; `attendanceController.ts` logs large attendance debug blocks; not secret but noisy and leaks internals. No coordinates logged — confirmed.

### F-19 — Misc Low — `liveEmployeeDetails.pickDate` uses UTC while tracking days are IST; check-in seed point lacks `accuracy`; attendance page `dispose()` leaves TrackingService listeners alive until check-out; permission dialog shows once ever.

---

## 9. Functional Gaps (vs. expected product surface)

- No live multi-employee map or last-known-location board.
- No stale-vs-live indicator on the dashboard (`lastUpdateAt` is stored but unused).
- No alert feed for spoofing/GPS-off events — only per-employee drill-down.
- No gap detection (server doesn't know a point was *expected* every 20 min).
- No tracking history beyond the day doc (no range query API).
- No retention/deletion policy for `tracking` docs — they accumulate indefinitely.
- No consent/acknowledgement record tied to tracking (one-time dialog only).

---

## 10. Flutter Web vs. Android/iOS Limitations

| Capability | Android | iOS | Web |
|---|---|---|---|
| Periodic tracking | ✅ FG service (20 min) + Workmanager sync | ⚠️ `IosConfiguration()` is default/unconfigured — unverified, likely non-functional | ❌ single point at check-in |
| Survives minimize | ✅ | ⚠️ | partial (throttled timers while tab open) |
| Survives kill/reboot | partial (no boot receiver) | ❌ | ❌ (tab closed = dead) |
| `isMocked` detection | ✅ (geolocator) | ⚠️ partial | ❌ always false |
| GPS on/off events | ✅ | ⚠️ | ❌ no service-status stream |
| Offline queue | ✅ | ✅ | ✅ (SharedPreferences) |

---

## 11. Production Readiness Assessment

- **Security:** RBAC/tenant isolation strong (verified). Spoofing resistance weak — no attestation, client-trusted coords, no replay protection. Stateless JWTs.
- **Reliability:** Android foreground tracking reasonable while process alive; dies silently on kill/reboot; web effectively non-functional; post-checkout/logout leakage.
- **Performance:** OK — bounded writes (≤1/15 min), 200-point cap; day-doc reads are cheap; no indexes needed (doc-ID lookups). Event array unbounded but deduped.
- **Privacy:** weak — post-logout tracking, 7-day credentials, legacy tenants opted in by default, no retention policy, minimal consent record.

**Verdict: NOT production-ready.** With F-01/F-02/F-03/F-06 fixed, it becomes acceptable as an *informational* tracker. Tamper-evidence requires Phase-2 controls (App Check, attestation, plausibility analytics).

---

## 12. Test Evidence (DEV emulators, synthetic data only)

| Probe | Result |
|---|---|
| Unauthenticated `/pos` | 401 ✅ |
| Employee check-in + valid pos | 200 ✅ (server `ts` stamped) |
| Fabricated far-away coords | accepted-shape (throttled on interval; no coordinate validation) |
| `lat=999` | 400 bounds check ✅ |
| Missing `accuracy` | accepted (optional) ⚠️ |
| Foreign `x-empid`/body empid | ignored — wrote to own doc ✅ |
| Foreign-admin `/day` read | 403 ✅ |
| `company_admin` read/write | 403 ✅ |
| `super_admin`/`platform_admin` read | 403 ✅ (roleMiddleware) |
| HR + `tracking` approval read | 200 ✅ |
| HR no approval | 403 `Feature not approved` ✅ |
| **Post-check-out `/pos`** | **200 — appended after `endedAt`** ❌ (F-02) |
| **Second `/tracking/check-in`** | **`pathMap` wiped to `[]`, `endedAt` reset** ❌ (F-03) |
| Self-injected `gps_disabled` event | 200 — recorded ❌ (F-11) |
| Invalid event type | 400 whitelist ✅ |
| Tracking-disabled company `/pos` | 403 `FEATURE_NOT_ENABLED` ✅ |
| Legacy company (no `enabledFeatures`) `/pos` | 200 — legacy allow-all ⚠️ (F-13) |

Manual/device tests still required: real-device `isMocked` coverage, battery impact of 20-min `bestForNavigation` sampling, FG-service survival across OEM task-killers, iOS behavior end-to-end.

---

## 13. Feature Readiness Matrix

| Feature | Employee Side | HR/Admin Side | Backend | Security | Production Ready |
|---|---|---|---|---|---|
| Check-in → tracking start | ✅ Android / ⚠️ once-only on Web | — | ✅ | ⚠️ no feature check (F-06) | No |
| Periodic location capture | ⚠️ Android only; dies on kill | — | ✅ accepts ≤1/15 min | ❌ client-trusted coords | No |
| Tracking stop on check-out | ✅ UI stops services | — | ❌ session never closes (F-02) | ❌ | No |
| Stop on logout | ❌ not stopped (F-01) | — | ❌ | ❌ 7-day token | No |
| Track view (day map) | ✅ My Track | ✅ employee detail | ✅ | ✅ tenant-scoped | Partial |
| Tracking events (GPS off/mock/logout) | ✅ reported | ✅ displayed | ⚠️ self-injectable (F-11) | ⚠️ | Partial |
| Geofence attendance | ✅ | ✅ approvals | ✅ verified 31/31 | ✅ server-computed | Yes* |
| Spoof detection | ⚠️ `isMocked` self-report | ⚠️ passive display | ⚠️ speed check only | ❌ no attestation | No |
| Offline buffering | ✅ queue+sync | — | ⚠️ arrival-time stamping | ⚠️ plaintext prefs | Partial |
| Tenant isolation | — | ✅ verified | ✅ verified | ✅ | Yes |
| Data retention | — | — | ⚠️ 200-pt cap; no TTL | — | No |

---

## 14. Recommended Remediation Roadmap (not implemented)

### PHASE 1 — Critical auth, authorization & tenant isolation
1. F-01: stop all trackers + clear `bg_*`/pending keys inside `logout()` (before session teardown).
2. F-02: reject `/pos`/`/event` when `endedAt` is set; reopen only via `/tracking/check-in`.
3. F-03: make `/tracking/check-in` idempotent — never overwrite `pathMap`/`events`; single call site.
4. F-06: gate client tracking start on `FeatureAccess.tracking`.
5. F-13: exclude `tracking` (and other sensitive keys) from legacy allow-all; explicit opt-in.
6. F-07: per-request `users.status` check + shorter JWT TTL (or token versioning).

### PHASE 2 — GPS validation, anti-spoofing detection & event integrity
7. F-04/F-15: server plausibility layer — required bounded `accuracy`, `capturedAt` + skew check (F-10), `pointId` dedupe, office/dwell analytics.
8. F-05: Firebase App Check + Play Integrity/App Attest; attestation-absent points flagged.
9. F-11: restrict client-emittable event types; tag client-reported events; keep `impossible_travel` server-derived only.
10. F-16: bind tracking sessions to the attendance record ID.

### PHASE 3 — Lifecycle, GPS-OFF detection, background & reliability
11. F-08: boot-resume (BootReceiver/`onBoot`), resume-on-app-open when checked in, heartbeat expectation + `tracking_interrupted` events.
12. F-09: define Web semantics (snapshot-only, disclosed in UI) or add tab-lifetime timer; stop advertising continuous tracking on web.
13. F-12: surface `truncated`/`droppedCount`; move history to per-hour subdocs or archive.
14. F-17: move tokens to `flutter_secure_storage`; encrypt/TTL the pending queue.
15. iOS `IosConfiguration` + verification.

### PHASE 4 — HR/Admin monitoring, privacy, performance & prod verification
16. Live/stale distinction + last-update time on dashboards; fleet "last known" board.
17. Spoof/GPS-off alert feed with acknowledge workflow.
18. Retention policy (TTL on `tracking` docs), access audit logs, tracking consent record.
19. F-14: confirm HR `attendance`-only read intent.
20. F-18/19: reduce log verbosity; IST-consistency fix; re-run full emulator matrix + device farm smoke tests before production.

---
*End of audit. No code, rules, data, or configuration were modified. No production access. No real employee coordinates were read or recorded.*
