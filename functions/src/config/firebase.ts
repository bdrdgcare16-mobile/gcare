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

const PROJECT_ID = process.env.APP_FIREBASE_PROJECT_ID || 'servappbackend';
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

db.settings({ ignoreUndefinedProperties: true });

// eslint-disable-next-line no-console
console.log('[firebase] Admin initialized. Project:', PROJECT_ID);
// eslint-disable-next-line no-console
try {
  console.log('[firebase] Bucket:', bucket.name);
} catch (e) {
  console.log('[firebase] Bucket not configured (safe in local dev)');
}
export default adminApp;