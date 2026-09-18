# SERV Attendance & Workforce Management — Final Security Audit & Production-Readiness Report

**Audit date:** 2026-08-28
**Auditor role:** Senior Application Security Engineer / Flutter & Node.js Engineer / Firebase Security Specialist / QA Lead
**Repository root:** `E:\SERV\gcare`
**Audit mode:** Read-only (no Git state changes, no deploys, no pushes, no code modifications)

---

## 1. Release Candidate Identification

| Item | Value |
|---|---|
| Current branch | `feature/push-notifications` |
| Current commit hash | `6eacf8826b9008ea33beec69f520f7f84f978cdd` |
| Working-tree status | **NOT CLEAN** |
| Modified files | `.flutter-plugins-dependencies` (generated, machine-specific path differences) |
| Staged files | none |
| Untracked files | none |
| Upstream | `origin/feature/push-notifications` (up to date) |

### Security-change branch analysis

A local branch `security/validation-review` exists with one additional commit on top of the current HEAD:

```
634b285  backup: preserve security validation and rate-limiting changes   (security/validation-review)
6eacf88  changed payroll layout and removed debug console log             (HEAD -> feature/push-notifications)
```

`git diff --stat feature/push-notifications...security/validation-review` shows **103 files changed, +7344 / -1307**, including the following files that are **NOT present in the current release candidate**:

- `functions/src/validators/security.validator.ts`
- `functions/src/middlewares/authRateLimiter.ts`
- `functions/src/middlewares/firestoreRateLimit.ts`
- `functions/src/errors/AppError.ts`
- `functions/src/services/auditService.ts`
- `functions/src/config/firebase-test.ts`
- `functions/src/test-app.ts`
- `functions/src/tests/*.test.ts` (12 security test suites)
- `functions/src/tests/test-data.ts`, `functions/src/tests/test-safety.ts`
- `firestore.rules` hardening (+20 lines)
- `firebase.json` emulator config (+13 lines)
- `.firebaserc` demo-project switch

**Conclusion:** The entire body of security work described in the prior report (Firestore-backed rate limiting, centralized security validator, audit service, 195 tests across 12 suites, Firestore/Storage rules tests) lives **only** in `security/validation-review`. It is **not merged** into the current release candidate `feature/push-notifications @ 6eacf88`. The current release candidate does **not** contain those controls.

Because the working tree is not clean and the release commit does not contain the claimed security controls, **production certification is blocked** per the audit rules.

---

## 2. Methodology

- Read-only Git inspection (`branch`, `status`, `log`, `diff`, `ls-files`, `show`).
- Static inspection of Express routes, controllers, middlewares, validators, Firestore rules, Firebase config, Flutter `lib/` and `test/`.
- Safe backend build (`npm run build`) and unit tests (`npm test`) with `NODE_ENV=test`.
- `npm audit --omit=dev`.
- `flutter analyze` (full project).
- No Firebase Emulator suites for auth/firestore/security were run because **the required test suites do not exist on the current branch**; the only backend test file is `payrollService.test.ts`.
- No real Firebase project was contacted. `.firebaserc` on the current branch points to `serv-dev-f2557`; tests were limited to pure unit tests that do not initialise Firebase. The Firestore/Auth emulator was **not** started because no rules/security tests exist on this branch to run against it.

---

## 3. Executive Summary

The current release candidate (`feature/push-notifications @ 6eacf88`) is **NOT READY FOR PRODUCTION**.

Key reasons:

1. **The security controls claimed in the prior report are absent from the release candidate.** They exist only on an unmerged backup branch (`security/validation-review`). The release candidate has no centralized security validator, no Firestore-backed rate limiting, no audit service, and none of the 12 security test suites.
2. **Multiple Critical vulnerabilities are present in the release candidate**, including:
   - Public registration allows choosing an arbitrary `companyId` and the `admin` role.
   - An `admin` can create a `super_admin`.
   - Most payroll routes have **no authentication middleware** (anyone can generate/list/pay payroll).
   - `functions/.env` (containing secrets/keys) is committed to Git despite being in `.gitignore`.
   - No Firebase Storage security rules exist; all uploads are explicitly made public.
3. **Rate limiting is in-memory only** (`express-rate-limit` default store), which is ineffective on Cloud Run multi-instance deployments and provides no per-account brute-force protection.
4. **Test coverage on the release candidate is 1 backend suite / 48 tests** (payroll salary math only) and **0 Flutter tests** — not the reported 195/12.
5. Working tree is not clean.

The prior report's evidence is **not reproducible** from the current release candidate. The highest defensible decision is **CONDITIONALLY READY FOR STAGING** *only after* the `security/validation-review` work is merged, the Critical/High findings below are remediated, and the full emulator test suite is reproduced on the merged candidate. As-is, the decision is **NOT READY FOR PRODUCTION**.

---

## 4. Endpoint Inventory (release candidate `6eacf88`)

Routes are registered in `functions/src/app.ts`. Middleware abbreviations: **Auth** = `authMiddleware` (JWT), **Role** = `roleMiddleware([...])`, **RL** = rate-limit middleware. Company-isolation column reflects whether the controller derives `companyId` from the token vs. request body.

### Authentication (`/api/auth`)

| Method | Endpoint | Controller | Auth | Allowed roles | Company isolation | Validation | Rate limit | Sensitive | Audit | Security gaps |
|---|---|---|---|---|---|---|---|---|---|---|
| POST | `/api/auth/register` | `register` | Public | public → employee/admin | **No — `companyId` from body** | minimal (name/email/password/companyId non-empty; role in `{employee,admin}`) | `authRateLimit` (IP) | Yes | None | **Critical:** arbitrary companyId + admin role from public body |
| POST | `/api/auth/login` | `login` | Public | public | n/a | email/password non-empty | `authRateLimit` (IP only) | Yes | None | No per-account lockout; in-memory RL |
| POST | `/api/auth/firebase-login` | `firebaseLogin` | Public (Firebase ID token) | public | companyId from user doc | `auth.verifyIdToken` | `authRateLimit` (IP) | Yes | None | Accepts token from `Authorization` **or** `body.idToken` (conflicting locations) |
| POST | `/api/auth/forgot-password` | `forgotPassword` | **Public** (before `authMiddleware`) | public | n/a | email/newPassword non-empty | `authRateLimit` (IP) | Yes | None | Legacy direct-reset endpoint exposed publicly; delegates to `changePassword` which requires token userId → effectively broken, but insecure legacy surface |
| POST | `/api/auth/forgot-password/request-link` | `requestPasswordResetLink` | Public | public | n/a | email | `authRateLimit` (IP) | Yes | None | OK-ish; reset link not returned |
| GET | `/api/auth/me` | `getMe` | Auth | any | token | none | `authRateLimit` (already passed) | No | None | — |
| GET/PUT | `/api/auth/profile` | `getProfile`/`updateProfile` | Auth | any | token | `updateProfile` is a stub returning success without writing | `authRateLimit` | No | None | `updateProfile` is a no-op (functional gap) |
| POST | `/api/auth/change-password` | `changePassword` | Auth | any | token userId | newPassword >= 8 | `authRateLimit` | Yes | None | **No current-password verification**; no re-auth |
| POST | `/api/auth/admin/register` | `createPrivilegedUser` | Auth + Role | admin, super_admin | caller companyId must equal body companyId | minimal | `authRateLimit` | Yes | None | **Critical:** admin can create `super_admin`; no password policy on created user |
| POST | `/api/auth/admin/create-employee-login` | `createEmployeeLogin` | Auth + Role | admin | token | minimal | `authRateLimit` | Yes | None | Needs ownership check confirmation |
| POST | `/api/auth/admin/backfill-employee-logins` | `backfillEmployeesToUsers` | Auth + Role | admin | token | none | `authRateLimit` | Yes | None | Bulk mutation, no audit |

### Payroll (`/api/payroll`) — **CRITICAL: most routes unauthenticated**

| Method | Endpoint | Controller | Auth | Roles | Company isolation | Validation | RL | Gaps |
|---|---|---|---|---|---|---|---|---|
| GET | `/my-payroll` | `getMyPayroll` | Auth | any | token | `validatePayrollMonth` | general | OK |
| GET | `/previous-month` | `listPreviousMonthPayroll` | **None** | **public** | none | none | general | **Critical:** unauthenticated |
| GET | `/` | `listMonthlyPayroll` | **None** | **public** | none | `validatePayrollMonth` | general | **Critical:** unauthenticated |
| POST | `/generate` | `generatePayroll` | **None** | **public** | none | `validatePayrollMonth`+`validateSalaryCalculationMethod` | general | **Critical:** unauthenticated payroll generation |
| POST | `/generate/preview` | `previewPayroll` | **None** | **public** | none | validators | general | **Critical:** unauthenticated |
| POST | `/snapshot` | `savePayrollSnapshotController` | **None** | **public** | none | `validateSalaryCalculationMethod` | general | **Critical:** unauthenticated |
| POST | `/generate/previous-month` | `generatePreviousMonthPayroll` | **None** | **public** | none | validator | general | **Critical:** unauthenticated |
| PATCH | `/:payrollId` | `updatePayrollController` | Auth | any | controller-dependent | none | general | No role check |
| PATCH | `/:payrollId/paid` | `confirmPayrollPaid` | **None** | **public** | none | none | general | **Critical:** anyone can mark payroll paid |

### Other modules (summary)

Routes for `/api/company`, `/api/employees`, `/api/attendance`, `/api/leaves`, `/api/leave-types`, `/api/office`, `/api/uploads`, `/api/reports`, `/api/rewards`, `/api/events`, `/api/feedback`, `/api/shifts`, `/api/tasks`, `/api/tracking`, `/api/liveEmployeeDetails`, `/api/reasons`, `/api/overtime`, `/api/admin`, `/api/billing`, `/api/onboarding`, `/api/notifications` are mounted with `generalRateLimit` (and `attendanceRateLimit`/`trackingRateLimit`/`uploadRateLimit` where applicable). Per-route `authMiddleware`/`roleMiddleware` wiring must be inspected per controller; the payroll gap above demonstrates that **route-level auth is not consistently enforced** and must be re-verified for every sensitive route before release. A full per-route table for all 20+ route files is pending — the payroll and auth findings alone are blocking.

---

## 5. Security Controls Verified

| Control | Status | Evidence |
|---|---|---|
| Passwords hashed (bcrypt, cost 10) | Pass | `authController.ts:242,1045` `bcrypt.hash(password, 10)` |
| Passwords stripped from responses | Pass | `sanitizeUser` removes `password/passwordHash/hashedPassword` (`authController.ts:109`) |
| JWT signature/expiration verified | Partial | `authMiddleware.ts:145` `jwt.verify`; **no token-purpose claim** (access/refresh indistinguishable) |
| Firebase ID tokens verified via Admin SDK | Pass | `authController.ts:1105` `auth.verifyIdToken` |
| Malformed/oversized tokens rejected | Partial | `jwt.verify` rejects bad signatures; no explicit size guard |
| Conflicting token locations rejected | **Fail** | `authMiddleware` accepts `Authorization: Bearer` **and** `x-access-token`; `firebaseLogin` accepts `Authorization` **or** `body.idToken` |
| Bearer format documented/enforced | Partial | Bearer accepted; non-Bearer schemes also accepted via `x-access-token` |
| Missing auth → 401 | Pass | `authMiddleware.ts:137` |
| Invalid token → 401 | **Fail** | Invalid (non-expired) token returns **403** (`authMiddleware.ts:155-159`) |
| Unauthorized → 403 | Pass | `roleMiddleware.ts:325` |
| Account existence not leaked (public errors) | Partial | login returns generic `Invalid email or password`; register leaks `Email already in use` (acceptable) |
| Direct reset by email+newPassword disabled | **Fail** | `/forgot-password` public legacy endpoint exists (delegates to token-based `changePassword`, so non-functional, but insecure surface remains) |
| Reset links not returned/logged | Pass | `requestPasswordResetLink` not inspected to return link; no link in responses seen |
| Legacy passwords not rejected by new min-length | Pass | login uses bcrypt compare, no min-length check on incoming login password |
| New-password policy on register/reset/change | Partial | `changePassword` enforces >=8; `register` and `createPrivilegedUser` enforce **no password policy** |
| Employee identity from verified token | Pass | `authMiddleware` sets `req.user` from JWT |
| companyId from token/server record | Partial | `authMiddleware` reads `companyId` from JWT; but `register`/`createPrivilegedUser` accept body `companyId` |
| Employee cannot access other employee's records | Needs verification | No centralized ownership guard; per-controller |
| Admin cannot access other company | Partial | `createPrivilegedUser` checks caller companyId == body companyId; other controllers not verified |
| Admin cannot create Super Admin | **Fail** | `createPrivilegedUser:1036` allows admin to create `super_admin` |
| Public registration cannot choose arbitrary companyId | **Fail** | `register:198,206` accepts body `companyId` |
| Firestore Rules defence in depth | **Fail** | Only 6 collections covered; no `users`, `payroll`, `payslips`, `tasks`, `events`, `rewards`, `notifications`, `auditLogs`, etc. |
| Centralized validation (unknown fields, mass assignment, prototype pollution, etc.) | **Fail** | No `security.validator.ts` on this branch; only `common.validator.ts` (409 bytes), `onboarding.validator.ts`, `payrollValidator.ts` |
| Rate limiting — Firestore-backed, increments once, account+IP independent, login resets account only | **Fail** | `rateLimitMiddleware.ts` uses in-memory `express-rate-limit`; no Firestore store; no per-account counter; no login-reset logic |
| Rate-limited requests blocked before controller | Pass | middleware order is correct |
| 429 on limit violation | Pass | `express-rate-limit` default 429 |
| Retry-After valid | Pass | `standardHeaders: true` emits `RateLimit-Reset` |
| Raw emails/passwords/tokens not stored by RL | Pass | `express-rate-limit` stores only counts (in-memory) |
| Attendance GPS server-calculated distance | Pass | `attendanceController.ts:344` `haversineMeters` server-side |
| Client-calculated distance not trusted | Pass | distance computed from server office coords |
| Lat/lng/accuracy strictly validated | **Fail** | only `typeof === 'number'`; no range check (-90..90/-180..180), no `isFinite`, no accuracy bound |
| Out-of-radius/impossible locations rejected | **Fail** | out-of-radius check-in is **allowed** (recorded as `otherLocation` event) |
| Duplicate check-in prevented | Pass | `attendanceController.ts:392` 409 `ALREADY_CHECKED_IN` |
| Payroll employee own payslip only | Partial | `/my-payroll` uses token; other payroll routes unauthenticated |
| Cross-company payroll 403 | **Fail** | unauthenticated routes have no company check |
| Payroll server-controlled calculations | Pass | `payrollService.ts` server-side |
| Mark-as-paid authorized & idempotent | **Fail** | `/:payrollId/paid` unauthenticated |
| Audit records for payroll generation/update/payment | **Fail** | no `auditService.ts` on this branch |
| Approval counts use identical scope | Needs verification | leave double-count fix commit `e92caca` is present, but **no tests** verify it on this branch |
| CORS only approved origins | Partial | allows any `localhost:`/`127.0.0.1:` port + no-origin; production origins listed |
| trust-proxy | Pass | `app.set('trust proxy', 1)` |
| Security headers (helmet etc.) | **Fail** | no helmet/headers package; no CSP/HSTS/X-Frame-Options |
| Request body size limit | Pass | 10mb (`app.ts:243-244`) |
| Stack traces hidden in production | **Fail** | error handler returns `err.message` and logs full `err` regardless of `NODE_ENV` (`app.ts:314-321`) |
| Secrets not in tracked files | **Fail** | `functions/.env` is tracked (see §11) |
| Dev endpoints/debug logs disabled | **Fail** | verbose `console.log` throughout auth/attendance; `performance_logger.dart` uses `print` |
| Firestore indexes for production queries | Partial | `firestore.indexes.json` exists (7154 bytes); not verified against all query patterns |
| App Check | **Fail** | not configured; not in dependencies |
| Backups/monitoring/rollback documented | **Fail** | no runbook/rollback doc in repo |

---

## 6. Findings

### Critical

**C-1 — Public registration allows arbitrary `companyId` and `admin` role**
- File: `functions/src/controllers/authController.ts:189-291`, route `functions/src/routes/authRoutes.ts:8`
- Evidence: `register` reads `role` (default `employee`) and `companyId` from `req.body`; `okRoles = new Set(["employee","admin"])` (`common/constants.ts:1`) permits `admin`. No authentication, no server-side company assignment.
- Impact: Anyone can self-register as an **admin** into **any** company and receive a valid JWT with that `companyId`.
- Reproduction: `POST /api/auth/register { name, email, password, role:"admin", companyId:"<victim>" }` → 201 + token.
- Remediation: Make registration invite/onboarding-only; derive `companyId` from a server-controlled onboarding token or admin context; never allow public `admin` self-registration. (Requires code change — request approval.)

**C-2 — Admin can create `super_admin`**
- File: `functions/src/controllers/authController.ts:999-1085`, route `authRoutes.ts:36-40`
- Evidence: The guard at line 1036 only blocks super_admin creation when caller is **not** admin/super_admin, but the prior check (1028) already guarantees the caller is admin or super_admin. Therefore an `admin` can pass `role:"super_admin"` and succeed.
- Impact: Company admin can escalate to Super Admin.
- Remediation: Restrict `super_admin` creation to existing `super_admin` only (or a controlled Super Admin onboarding flow).

**C-3 — Payroll routes are unauthenticated**
- File: `functions/src/routes/payrollRoutes.ts:31-84`
- Evidence: Only `/my-payroll` and `PATCH /:payrollId` use `authMiddleware`. `/`, `/previous-month`, `/generate`, `/generate/preview`, `/snapshot`, `/generate/previous-month`, and `PATCH /:payrollId/paid` have **no `authMiddleware`** and no role check.
- Impact: Anyone can list, generate, snapshot, and mark payroll as paid for any company/month.
- Reproduction: `POST /api/payroll/generate { month, year, ... }` with no token → success.
- Remediation: Add `authMiddleware` + `roleMiddleware(['admin'])` (and Super Admin where approved) to every payroll route; enforce `companyId` from token.

**C-4 — `functions/.env` committed to Git**
- File: `functions/.env` (tracked)
- Evidence: `git ls-files` lists `functions/.env`; `git show HEAD:functions/.env` exposes keys including `APP_FIREBASE_WEB_API_KEY`, `APP_STORAGE_BUCKET`, `APP_PROJECT_ID`, `CORS_ORIGIN`, `RESET_CONTINUE_URL`, etc. `.gitignore` (`functions/.gitignore:66`) ignores `.env` but it was committed before being ignored.
- Impact: Secrets (API key, config) are in Git history. Values intentionally not printed here.
- Remediation: Remove from tracking (`git rm --cached functions/.env`), rotate all exposed secrets, purge from history (requires approval — destructive to history).

**C-5 — No Firebase Storage security rules; all uploads made public**
- Files: no `storage.rules` file exists; `firebase.json` has no `storage.rules` config; `functions/src/utils/storage.ts:39,73` calls `blob.makePublic()`.
- Impact: Payslips, task proofs, disciplinary documents, and any uploaded file are world-readable by URL. No ownership/MIME/size enforcement at the storage layer.
- Remediation: Add `storage.rules` enforcing `request.auth` ownership and company isolation; stop making objects public; serve via signed URLs.

### High

**H-1 — Rate limiting is in-memory only (not Firestore-backed)**
- File: `functions/src/middlewares/rateLimitMiddleware.ts`
- Evidence: Uses `express-rate-limit` with default in-memory store. No Firestore store, no per-account counter, no login-success reset. `authRateLimit` = 300 req/15min per IP.
- Impact: On Cloud Run with N instances, effective limit is N×300; brute-force/abuse not meaningfully throttled; no account lockout. The prior report's "Firestore-backed account and IP rate limiting" is **not present**.

**H-2 — No centralized input validation / mass-assignment protection**
- Evidence: `security.validator.ts` does not exist on this branch. Controllers spread `req.body` fields manually with `String(...)` casts. No unknown-field rejection, no prototype-pollution guard, no nested-object validation.
- Impact: Mass assignment, type confusion, and injection of unexpected fields are possible across controllers.

**H-3 — Firestore Rules cover only 6 collections**
- File: `firestore.rules`
- Evidence: Rules exist for `employees`, `attendance`, `leaves`, `officeLocations`, `shifts`, `otherLocation`. Catch-all denies the rest. No rules for `users`, `payroll`, `payslips`, `tasks`, `events`, `rewards`, `notifications`, `feedback`, `reasons`, `overtime`, `employeeDetails`, `disciplinary`, `auditLogs`, etc. Additionally, `employees`/`leaves` allow **update/delete by any same-company user** (no admin restriction) — any employee can mutate any same-company employee/leave document.
- Impact: Defence-in-depth is incomplete; same-company peer mutation is possible via client SDK.

**H-4 — No security headers**
- Evidence: `package.json` has no `helmet`; `app.ts` sets no CSP/HSTS/X-Frame-Options/X-Content-Type-Options.
- Impact: Missing browser hardening for the hosted web surface.

**H-5 — Stack traces / internal errors exposed**
- File: `functions/src/app.ts:314-321`; `authController.ts:1081` returns `error?.message` directly.
- Evidence: Error handler returns `err.message` and logs full `err` with no `NODE_ENV` gating.
- Impact: Internal implementation details may leak to clients.

**H-6 — Dependency vulnerabilities**
- Evidence: `npm audit --omit=dev` → **21 vulnerabilities (2 low, 12 moderate, 6 high, 1 critical)**. Critical: `websocket-driver` (resource limit bypass / message corruption). High transitive issues in `firebase-admin`/`@google-cloud/firestore`/`@google-cloud/storage` via `uuid`/`gaxios`/`google-gax`/`teeny-request`.
- Remediation: `npm audit fix` for safe updates; pinned review for breaking changes. (Do not run `--force` without approval.)

### Medium

**M-1 — Invalid JWT returns 403 instead of 401**
- File: `functions/src/middlewares/authMiddleware.ts:155-159`
- Evidence: Non-expired invalid token → 403; should be 401.

**M-2 — Conflicting token locations accepted**
- File: `authMiddleware.ts:87-113` (`Authorization` + `x-access-token`); `authController.ts:1094-1097` (`Authorization` + `body.idToken`)
- Evidence: No rejection when multiple token sources present; allows non-Bearer schemes.

**M-3 — `changePassword` does not verify current password**
- File: `authController.ts:658-715`
- Evidence: Uses token `userId` only; no `currentPassword` verification. A hijacked session can change the password without re-auth.

**M-4 — No password policy on registration / privileged-user creation**
- Evidence: `register` and `createPrivilegedUser` perform no length/complexity check on `password` (only `changePassword` enforces >=8).

**M-5 — Legacy public `/forgot-password` endpoint remains**
- File: `authRoutes.ts:16`, `authController.ts:972-986`
- Evidence: Public endpoint expecting `{email,newPassword}`; delegates to token-based `changePassword` and is therefore non-functional, but is insecure legacy surface that should be removed.

**M-6 — Attendance coordinates not range/finite validated**
- File: `attendanceController.ts:293-295`
- Evidence: Only `typeof === 'number'`; no `-90..90`/`-180..180`/`isFinite`/accuracy bounds. Out-of-radius check-ins are allowed (recorded, not rejected).

**M-7 — Unsafe filename handling in storage path**
- File: `functions/src/utils/storage.ts:28,62`
- Evidence: Object path uses `${folder}/${uuidv4()}-${file.originalname}` without sanitising path separators or `..`. MIME/extension filtering exists in `uploadMiddleware.ts` but storage path construction is unsafe.

**M-8 — CORS allows any localhost port in production build**
- File: `app.ts:194-234`
- Evidence: `origin.startsWith("http://localhost:")` always allowed regardless of `NODE_ENV`. Acceptable for dev but should be env-gated for production.

### Low

**L-1 — Verbose logging of auth/attendance internals**
- Evidence: `console.log('[verifyToken] ...')`, `FIREBASE LOGIN START`, etc. throughout controllers. `performance_logger.dart` uses `print` in production.

**L-2 — `updateProfile` is a no-op stub**
- File: `authController.ts:994-997`
- Evidence: Returns success without persisting anything (functional gap, not security).

**L-3 — Generated `.flutter-plugins-dependencies` tracked and dirty**
- Evidence: File is in `.gitignore` but tracked; working tree dirty due to machine-specific path differences.

### Informational

**I-1 — Flutter `flutter analyze`: 350 issues, 0 errors** (warnings/info only: deprecated APIs, `avoid_print`, `unused_element`, naming). No blocking analysis errors.
**I-2 — No Flutter test directory** (`test/` absent on this branch); 0 Flutter tests.
**I-3 — Backend tests: 1 suite / 48 tests** (`payrollService.test.ts`), all passing — payroll salary/LOP math only.
**I-4 — `.firebaserc` default project is `serv-dev-f2557`** (real dev project). The `security/validation-review` branch switches to a `demo-` project; the release candidate does not. Emulator safety gating is therefore not satisfied on this branch.
**I-5 — `serviceAccountKey.json` exists locally** (`functions/serviceAccountKey.json`) but is **not tracked** (correctly gitignored). Confirm it is never committed.

---

## 7. Test Commands Executed & Results

| Command | Result |
|---|---|
| `git branch --show-current` | `feature/push-notifications` |
| `git status` | dirty (`.flutter-plugins-dependencies`) |
| `git rev-parse HEAD` | `6eacf8826b9008ea33beec69f520f7f84f978cdd` |
| `npm run build` (functions) | **PASS** (exit 0) |
| `npm test` (functions, `NODE_ENV=test`) | **1 suite, 48 tests passed** (exit 1 from `Select-Object` pipe; jest result = pass) |
| `npm audit --omit=dev` | **21 vulnerabilities** (1 critical, 6 high, 12 moderate, 2 low) |
| `flutter analyze` | **350 issues, 0 errors** (warnings/info only) |
| `flutter test` | **Not run** — no `test/` directory exists on this branch (0 tests) |
| Firestore Rules tests | **MISSING** on this branch (`firestore-rules.test.ts` only in `security/validation-review`) |
| Storage Rules tests | **MISSING** — no `storage.rules` file exists at all |
| Auth validation/authorization/rate-limit suites | **MISSING** on this branch |
| Payroll integration/security suites | **MISSING** on this branch (only `payrollService.test.ts` unit) |
| Attendance/approval isolation suites | **MISSING** on this branch |
| Concurrent rate-limit suite | **MISSING** on this branch |

**Passed/failed/skipped totals (release candidate `6eacf88`):** 48 passed / 0 failed / 0 skipped (backend); 0 Flutter tests. **12 required security suites are missing entirely** (not skipped — absent).

---

## 8. Firestore & Storage Rules Coverage

### Firestore (`firestore.rules`)
Covered collections: `employees`, `attendance`, `leaves`, `officeLocations`, `shifts`, `otherLocation`.
**Collections without dedicated rules (relying on catch-all `false`):** `users`, `payroll`, `payslips`, `tasks`, `events`, `rewards`, `notifications`, `feedback`, `reasonMaster`/`reasons`, `overtime`, `employeeDetails`, `liveEmployeeDetails`, `disciplinary` (if present), `auditLogs`, `companies`, `billing`, `onboarding`, `officeLocations`-adjacent.
**Rules tests:** none on this branch.
**Defects:** `employees` and `leaves` allow same-company update/delete by any employee (no admin guard).

### Storage
**No `storage.rules` file.** `firebase.json` has no `storage` config. All uploads are made public via `makePublic()`. No ownership/MIME/size enforcement at the storage layer. **Storage Rules tests: none (no rules to test).**

---

## 9. Existing Functionality Compatibility

Valid workflows were not regression-tested because there are no Flutter tests and only payroll-math backend tests on this branch. The following remain **unverified by automated tests** on the release candidate:

- Employee: login/logout, check-in/out, attendance history, leave/permission/overtime, tasks, events/rewards, profile, payslip, disciplinary.
- Admin: login, onboarding, attendance reports, leave approvals, office/shift management, payroll generation/payment, tasks/events/rewards, disciplinary submission.
- Super Admin: login, company onboarding, admin approval, disciplinary approval/rejection.

The leave-approval double-count fix (commit `e92caca`) is present in history but **has no automated test on this branch** (`test/leave_approvals_test.dart` exists only in `security/validation-review`). Flutter request fields vs. backend fields were not diffed for deprecations due to the absence of a Flutter test suite.

---

## 10. Remaining Risks

- Unmerged `security/validation-review` work may have diverged from the release candidate; merging could reintroduce conflicts or alter payroll calculations/response formats.
- In-memory rate limiting gives a false sense of protection on Cloud Run.
- Committed `.env` means secrets are in Git history even after removal.
- No App Check, no security headers, no audit logging on the release candidate.
- No emulator safety config (`.firebaserc` still points to `serv-dev-f2557`), so any future test run on this branch risks contacting a real Firebase project unless env is overridden.

---

## 11. Staging Acceptance Checklist

- [ ] Merge `security/validation-review` into the release candidate (or reapply controls) and re-audit.
- [ ] Remediate C-1 through C-5.
- [ ] Add `authMiddleware` + role checks to **every** sensitive route (full per-route inventory).
- [ ] Implement Firestore-backed rate limiting with per-account counters and login-success reset.
- [ ] Add `security.validator.ts` centralized validation across all controllers.
- [ ] Add `storage.rules` and stop public uploads; use signed URLs.
- [ ] Complete Firestore Rules for all collections; add admin-only update/delete where required.
- [ ] Add security headers (helmet) and gate stack-trace leakage by `NODE_ENV`.
- [ ] Rotate secrets; remove `functions/.env` from tracking and history.
- [ ] Switch `.firebaserc`/`firebase.json` to `demo-` project for tests; add Firestore/Auth emulator ports.
- [ ] Reproduce all 12 security suites against the emulator with `GCLOUD_PROJECT=demo-*`.
- [ ] Add Flutter tests and run `flutter test`.
- [ ] Run `npm audit fix` and review transitive upgrades.
- [ ] Staging regression pass for all employee/admin/super-admin workflows.
- [ ] Document monitoring, alerting, backup, and rollback runbooks.

---

## 12. Rollback Requirements

- Tag the current release candidate (`6eacf88`) before any merge so it can be reverted.
- Keep `security/validation-review` (`634b285`) intact as a fallback.
- Document Cloud Functions rollback (`firebase deploy --only functions` to previous version) and Firestore Rules rollback (`firebase deploy --only firestore:rules`).
- Ensure Firebase Auth users and Firestore data are backed up before any migration/onboarding change.
- Rollback must be tested in staging before production cutover.

---

## 13. Final Production Decision

### **NOT READY FOR PRODUCTION**

Rationale:

- Working tree is **not clean**.
- The release commit `6eacf88` does **not** contain the security controls claimed in the prior report (they are unmerged on `security/validation-review`).
- **5 Critical findings** (C-1..C-5) and **6 High findings** (H-1..H-6) remain open.
- Required security test suites are **missing** (not skipped — absent) on the release candidate.
- Backend: 1 suite / 48 tests only; Flutter: 0 tests.
- No Firestore Rules tests, no Storage Rules (no file at all), no auth/rate-limit/approval-isolation tests on this branch.
- `.firebaserc` points to a real Firebase project (`serv-dev-f2557`); emulator safety gating is not satisfied.
- Staging regression has not been performed.
- Production configuration (secrets, headers, App Check, monitoring/rollback) is not review-complete.

The prior report's "195 tests / 12 suites / Firestore-backed rate limiting / Rules tests passed" is **not reproducible** from `feature/push-notifications @ 6eacf88`. Once `security/validation-review` is merged, the Critical/High findings are remediated, and the full emulator test suite is reproduced on a clean working tree, the highest achievable decision without staging regression is **CONDITIONALLY READY FOR STAGING**. Production deployment requires all checklist items in §11 plus a passed staging regression.
