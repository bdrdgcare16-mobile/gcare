import * as admin from 'firebase-admin';
import { defineString } from 'firebase-functions/params';

// Define parameters
const projectId = defineString('APP_PROJECT_ID', {
  default: process.env.APP_PROJECT_ID || 'your-project-id'
});

const storageBucket = defineString('APP_STORAGE_BUCKET', {
  default: process.env.APP_STORAGE_BUCKET || 'your-project-id.appspot.com'
});

// Initialize Firebase Admin
const initializeFirebase = () => {
  // In production, these are automatically provided by Firebase
  if (process.env.NODE_ENV === 'production') {
    admin.initializeApp();
    return;
  }

  // For local development, try to use service account if it exists
  try {
    const serviceAccount = require('../../serviceAccountKey.json');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount as admin.ServiceAccount),
      storageBucket: storageBucket.value(),
    });
  } catch (error) {
    console.warn('Using default credentials for local development');
    admin.initializeApp({
      projectId: projectId.value(),
      storageBucket: storageBucket.value(),
    });
  }
};

initializeFirebase();

export const db = admin.firestore();
export const storage = admin.storage();
export const auth = admin.auth();

// Configure Firestore
db.settings({ ignoreUndefinedProperties: true });

export default {
  db,
  storage,
  auth,
};
