import * as admin from 'firebase-admin';

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
      storageBucket: process.env.GOOGLE_CLOUD_PROJECT + '.appspot.com',
    });
  } catch (error) {
    console.warn('Using default credentials for local development');
    admin.initializeApp({
      projectId: process.env.GOOGLE_CLOUD_PROJECT || 'your-project-id',
      storageBucket: process.env.GOOGLE_CLOUD_PROJECT + '.appspot.com',
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
