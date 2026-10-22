# Verification

- Flutter tests: `flutter test --no-pub` from the project root.
- Flutter analysis: `flutter analyze --no-pub` from the project root. The existing project has warnings and info-level diagnostics; inspect changed files separately.
- Backend tests: `npm test -- --runInBand` from `functions`.
- Backend type checking without deleting generated output: `npx tsc --noEmit` from `functions`.
- Attendance dates use Asia/Kolkata. Overnight checkout must update the original check-in-date record, and tracking must retain that session date.
- Attendance expiry is disabled unless `ATTENDANCE_EXPIRY_ENABLED=true`, `ATTENDANCE_EXPIRY_EFFECTIVE_AT` is a valid activation instant, and `ATTENDANCE_EXPIRY_COMPANIES` explicitly lists the enabled company IDs (comma-separated). Configure the API and scheduler consistently. Only newly enrolled sessions carrying `expiryPolicyVersion=1` are eligible; never backfill historical sessions automatically.
- The dedicated `attendanceExpiryMonitor` runs every minute. The existing attendance tracking trigger and payroll scheduler remain unexported.
- Real Firestore concurrency tests are opt-in: start `firebase emulators:start --only firestore --project demo-serv-attendance`, then run `npm test -- --runInBand src/services/attendanceExpiry.emulator.test.ts` from `functions` with `ATTENDANCE_EXPIRY_EMULATOR_TESTS=true`, `GCLOUD_PROJECT=demo-serv-attendance`, `APP_PROJECT_ID=demo-serv-attendance`, `FIRESTORE_EMULATOR_HOST=127.0.0.1:8080`, and `FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099`. The test refuses non-loopback or non-demo targets; only the Firestore emulator is used.
