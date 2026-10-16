// Pure Firebase-environment-resolution helpers, extracted out of firebase.ts
// so they can be unit-tested without ever constructing a real Admin SDK app
// (no Firestore/Auth imports here - safe to require from any test).

export type FirebaseEnv = {
  GCLOUD_PROJECT?: string;
  GOOGLE_CLOUD_PROJECT?: string;
  APP_PROJECT_ID?: string;
  APP_FIREBASE_PROJECT_ID?: string;
  FUNCTIONS_EMULATOR?: string;
  JEST_WORKER_ID?: string;
  FIRESTORE_EMULATOR_HOST?: string;
  FIREBASE_AUTH_EMULATOR_HOST?: string;
};

/**
 * Project id resolution order:
 *   1. GCLOUD_PROJECT / GOOGLE_CLOUD_PROJECT - auto-populated by both the
 *      Functions emulator and the real Cloud Functions/Cloud Run runtime.
 *      Always the trustworthy source when present.
 *   2. APP_PROJECT_ID - this repo's actual .env/.env.example convention for
 *      an explicit manual override.
 *   3. APP_FIREBASE_PROJECT_ID - legacy alias, kept for compatibility with
 *      any existing Functions runtime config already using this name.
 * Returns null (never a hardcoded literal) when nothing resolves - the
 * caller must fail closed rather than silently default to a project.
 */
export function resolveProjectId(env: FirebaseEnv): string | null {
  return (
    env.GCLOUD_PROJECT ||
    env.GOOGLE_CLOUD_PROJECT ||
    env.APP_PROJECT_ID ||
    env.APP_FIREBASE_PROJECT_ID ||
    null
  );
}

export function isFunctionsEmulator(env: FirebaseEnv): boolean {
  return env.FUNCTIONS_EMULATOR === 'true';
}

export function isJest(env: FirebaseEnv): boolean {
  return env.JEST_WORKER_ID !== undefined;
}

/**
 * Returns the list of missing emulator-host env vars when running under the
 * Functions emulator or Jest (empty array = safe to proceed). Both
 * FIRESTORE_EMULATOR_HOST and FIREBASE_AUTH_EMULATOR_HOST are required in
 * either context: without them the Admin SDK would reach the real network
 * using whatever credentials happen to be available, which must never
 * happen from a local DEV run or a test that forgot to mock Firebase.
 * Production (neither flag set) always returns [] - it is never required to
 * carry emulator host env vars.
 */
export function missingEmulatorHosts(env: FirebaseEnv): string[] {
  if (!isFunctionsEmulator(env) && !isJest(env)) return [];
  return [
    !env.FIRESTORE_EMULATOR_HOST && 'FIRESTORE_EMULATOR_HOST',
    !env.FIREBASE_AUTH_EMULATOR_HOST && 'FIREBASE_AUTH_EMULATOR_HOST',
  ].filter((v): v is string => Boolean(v));
}
