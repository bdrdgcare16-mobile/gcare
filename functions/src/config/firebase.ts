// import { getApps, initializeApp, applicationDefault, cert, AppOptions } from 'firebase-admin/app';
// import { getFirestore } from 'firebase-admin/firestore';
// import { getAuth } from 'firebase-admin/auth';
// import { getStorage } from 'firebase-admin/storage';

// // NOTE:
// // - Do NOT use firebase-functions Params here (no defineString / .value() at module load).
// // - Rely on ADC in production. In local dev, use serviceAccountKey.json if present.

// let appInitialized = false;

// if (!getApps().length) {
//   let options: AppOptions | undefined;

//   // Prefer explicit service account when available locally
//   try {
//     // eslint-disable-next-line @typescript-eslint/no-var-requires
//     const serviceAccount = require('../../serviceAccountKey.json');
//     options = {
//       credential: cert(serviceAccount),
//       storageBucket:
//         process.env.APP_STORAGE_BUCKET ||
//         (process.env.GCLOUD_PROJECT ? `${process.env.GCLOUD_PROJECT}.appspot.com` : undefined),
//     };
//   } catch {
//     // Fall back to Application Default Credentials (Functions/Cloud Run)
//     options = {
//       credential: applicationDefault(),
//       storageBucket:
//         process.env.APP_STORAGE_BUCKET ||
//         (process.env.GCLOUD_PROJECT ? `${process.env.GCLOUD_PROJECT}.appspot.com` : undefined),
//     };
//   }

//   initializeApp(options);
//   appInitialized = true;
// }

// // Expose Admin services
// export const db = getFirestore();
// export const auth = getAuth();
// export const storage = getStorage();

// // Firestore recommended setting to ignore undefined fields
// db.settings({ ignoreUndefinedProperties: true });

// // Helpful log in dev
// if (appInitialized) {
//   // eslint-disable-next-line no-console
//   console.log('[firebase] Admin initialized. Bucket:', storage.bucket().name);
// }

// export default { db, auth, storage };
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

const PROJECT_ID = process.env.APP_FIREBASE_PROJECT_ID || 'serv-dev-f2557';
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
      storageBucket:
        process.env.APP_STORAGE_BUCKET || `${PROJECT_ID}.appspot.com`,
    };
  } catch {
    options = {
      credential: applicationDefault(),
      projectId: PROJECT_ID,
      storageBucket:
        process.env.APP_STORAGE_BUCKET || `${PROJECT_ID}.appspot.com`,
    };
  }

  adminApp = initializeApp(options, APP_NAME);
}

export const db = getFirestore(adminApp);
export const auth = getAuth(adminApp);
export const storage = getStorage(adminApp);

db.settings({ ignoreUndefinedProperties: true });

// eslint-disable-next-line no-console
console.log('[firebase] Admin initialized. Project:', PROJECT_ID);
// eslint-disable-next-line no-console
try {
  console.log('[firebase] Bucket:', storage.bucket().name);
} catch (e) {
  console.log('[firebase] Bucket not configured (safe in local dev)');
}
export default adminApp;