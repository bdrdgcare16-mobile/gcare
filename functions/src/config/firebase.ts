import {
  getApps,
  initializeApp,
  applicationDefault,
  cert,
  App,
  AppOptions,
} from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import { getStorage } from 'firebase-admin/storage';
import { getMessaging } from 'firebase-admin/messaging';
import {
  resolveProjectId,
  isFunctionsEmulator,
  isJest,
  missingEmulatorHosts,
} from './firebaseEnv';

const IS_FUNCTIONS_EMULATOR = isFunctionsEmulator(process.env);
const IS_JEST = isJest(process.env);

// Project id resolution order (see firebaseEnv.ts): GCLOUD_PROJECT /
// GOOGLE_CLOUD_PROJECT (GCP-injected, trustworthy whenever present) ->
// APP_PROJECT_ID (this repo's .env/.env.example convention) ->
// APP_FIREBASE_PROJECT_ID (legacy alias). There is intentionally NO
// hardcoded project-id fallback: silently defaulting to a literal project id
// (the previous code defaulted to the production project, 'servappbackend')
// is exactly how a DEV run can end up talking to production. If nothing
// resolves, fail closed instead.
const PROJECT_ID = resolveProjectId(process.env);

if (!PROJECT_ID) {
  throw new Error(
    '[FIREBASE] Unable to resolve a Firebase project id (checked ' +
      'GCLOUD_PROJECT, GOOGLE_CLOUD_PROJECT, APP_PROJECT_ID, ' +
      'APP_FIREBASE_PROJECT_ID). Refusing to start rather than silently ' +
      'defaulting to a project.',
  );
}

// DEV/test isolation guard: if the Functions emulator OR Jest is running,
// both the Firestore and Auth emulators must also be attached (their
// *_EMULATOR_HOST env vars are what redirect the Admin SDK away from the
// real backend, independent of PROJECT_ID). Without them, Firestore/Auth
// calls would go over the network to the real project using whatever
// credentials are available (a service account key or ADC) - fail closed
// instead of risking a silent production read/write during local DEV
// testing or from a test that forgot to mock this module. `jest.setup.js`
// sets safe loopback defaults for every Jest run, so this should only ever
// fire for a misconfigured `--only functions` emulator invocation.
const missing = missingEmulatorHosts(process.env);
if (missing.length) {
  const context = IS_JEST ? 'Jest is running' : 'Functions emulator is running';
  throw new Error(
    `[FIREBASE] ${context} but ${missing.join(' and ')} ` +
      'is not set, so Firestore/Auth calls would not be routed to the ' +
      'local emulators. Start the full emulator suite (firestore + auth ' +
      'alongside functions) rather than `--only functions`, or ensure ' +
      'jest.setup.js runs before this module loads. Refusing to start ' +
      'to avoid touching production data.',
  );
}

const STORAGE_BUCKET =
  process.env.APP_STORAGE_BUCKET?.trim() ||
  `${PROJECT_ID}.firebasestorage.app`;
const APP_NAME = 'serv-core';

let adminApp: App;

const existingApp = getApps().find((app) => app.name === APP_NAME);

if (existingApp) {
  adminApp = existingApp;
} else {
  let options: AppOptions;

  try {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const serviceAccount = require('../../serviceAccountKey.json');
    options = {
      credential: cert(serviceAccount),
      projectId: PROJECT_ID,
      storageBucket: STORAGE_BUCKET,
    };
  } catch {
    options = {
      credential: applicationDefault(),
      projectId: PROJECT_ID,
      storageBucket: STORAGE_BUCKET,
    };
  }

  adminApp = initializeApp(options, APP_NAME);
}

export const db = getFirestore(adminApp);
export const auth = getAuth(adminApp);
export const storage = getStorage(adminApp);
export const bucket = storage.bucket(STORAGE_BUCKET);
export const messaging = getMessaging(adminApp);

db.settings({ ignoreUndefinedProperties: true });

// eslint-disable-next-line no-console
console.info(
  '[FIREBASE] Admin initialized. project=%s emulator=%s firestoreHost=%s authHost=%s',
  adminApp.options.projectId,
  IS_FUNCTIONS_EMULATOR,
  process.env.FIRESTORE_EMULATOR_HOST || '(none - real Firestore)',
  process.env.FIREBASE_AUTH_EMULATOR_HOST || '(none - real Auth)',
);
export default adminApp;