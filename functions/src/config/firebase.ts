import * as admin from 'firebase-admin';

const projectId =
  process.env.GCLOUD_PROJECT ||
  process.env.GCP_PROJECT ||
  process.env.FIREBASE_PROJECT_ID ||
  'servappbackend';

if (!admin.apps.length) {
  admin.initializeApp({ projectId });
  // eslint-disable-next-line no-console
  console.log('[firebase] Admin initialized. Project:', projectId);
}

export { admin };
export const db = admin.firestore();

db.settings({ ignoreUndefinedProperties: true });
