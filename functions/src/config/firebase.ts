import {
  getApps,
  initializeApp,
  applicationDefault,
  cert,
  App,
  ServiceAccount,
} from 'firebase-admin/app';
import { getFirestore, Firestore } from 'firebase-admin/firestore';
import { getAuth, Auth } from 'firebase-admin/auth';
import { getStorage, Storage } from 'firebase-admin/storage';
import { getMessaging, Messaging } from 'firebase-admin/messaging';

let _adminApp: App | undefined;
let _db: Firestore | undefined;
let _auth: Auth | undefined;
let _storage: Storage | undefined;
let _messaging: Messaging | undefined;
let _bucket: ReturnType<Storage['bucket']> | undefined;
let _firestoreChecked = false;
let _credentialSource: string | undefined;

/**
 * Resolves the Firebase Admin credential for the target project.
 *
 * Security policy:
 *   - NEVER load service-account key files from the filesystem at runtime.
 *   - NEVER bundle serviceAccountKey.json with the deployment.
 *   - Use GOOGLE_SERVICE_ACCOUNT_JSON only if explicitly provided via a
 *     secure secret / environment variable (e.g. Firebase Functions
 *     secret or Cloud Run secret mount).
 *   - Otherwise use Application Default Credentials (ADC), which on
 *     Cloud Run / Cloud Functions uses the runtime service account.
 *
 * Returns the credential and sets _credentialSource for diagnostics.
 */
function resolveCredential(
  targetProjectId: string,
): { type: 'serviceAccount'; value: ServiceAccount } | { type: 'adc'; value: ReturnType<typeof applicationDefault> } {
  // 1. Explicit env var with inline JSON (secure secret only)
  const envJson = process.env.GOOGLE_SERVICE_ACCOUNT_JSON;
  if (envJson) {
    try {
      const raw = JSON.parse(envJson) as Record<string, string>;
      const saProjectId = raw.projectId || raw.project_id;
      if (saProjectId === targetProjectId) {
        const clientEmail = raw.clientEmail || raw.client_email || 'N/A';
        console.log(
          `[ADMIN CREDENTIAL] source=GOOGLE_SERVICE_ACCOUNT_JSON, ` +
            `client_email=${clientEmail}`
        );
        _credentialSource = 'GOOGLE_SERVICE_ACCOUNT_JSON';
        return { type: 'serviceAccount', value: raw as unknown as ServiceAccount };
      }
      console.warn(
        `[ADMIN CREDENTIAL] GOOGLE_SERVICE_ACCOUNT_JSON project_id="${saProjectId}" ` +
          `!= target="${targetProjectId}", ignoring and falling back to ADC`
      );
    } catch (e) {
      console.warn(
        '[ADMIN CREDENTIAL] Failed to parse GOOGLE_SERVICE_ACCOUNT_JSON:',
        (e as Error).message
      );
    }
  }

  // 2. Application Default Credentials (Cloud Run / Cloud Functions runtime SA)
  console.log('[ADMIN CREDENTIAL] source=applicationDefault');
  _credentialSource = 'applicationDefault';
  return { type: 'adc', value: applicationDefault() };
}

export function getAdminApp(): App {
  if (_adminApp) return _adminApp;

  const projectId =
    process.env.APP_FIREBASE_PROJECT_ID || process.env.GCLOUD_PROJECT;
  const storageBucket = process.env.APP_STORAGE_BUCKET;

  if (!projectId) {
    throw new Error(
      'APP_FIREBASE_PROJECT_ID or GCLOUD_PROJECT is required. Refusing to initialize Firebase Admin implicitly.'
    );
  }

  if (process.env.FUNCTIONS_EMULATOR === 'true') {
    if (projectId !== 'serv-dev-f2557') {
      throw new Error(`Unsafe emulator project: ${projectId}`);
    }
    if (!process.env.FIRESTORE_EMULATOR_HOST) {
      throw new Error(
        'FIRESTORE_EMULATOR_HOST is required while running the Functions emulator.'
      );
    }
  }

  const existing =
    getApps().find((app) => app.name === 'serv-core') ??
    getApps().find((app) => app.name === '[DEFAULT]');

  if (existing) {
    _adminApp = existing;
    _credentialSource = _credentialSource || 'existing-app';
  } else {
    const credential = resolveCredential(projectId);

    if (credential.type === 'serviceAccount') {
      _adminApp = initializeApp(
        {
          credential: cert(credential.value),
          projectId,
          ...(storageBucket ? { storageBucket } : {}),
        },
        'serv-core'
      );
    } else {
      _adminApp = initializeApp(
        {
          credential: credential.value,
          projectId,
          ...(storageBucket ? { storageBucket } : {}),
        },
        'serv-core'
      );
    }
  }

  // eslint-disable-next-line no-console
  console.log(
    `[FIRESTORE CONFIG] project=${projectId}, ` +
      `credentialSource=${_credentialSource || 'unknown'}`
  );

  // Warn if the configured project ID doesn't match the Cloud Run project.
  const gcloudProject = process.env.GCLOUD_PROJECT;
  if (
    gcloudProject &&
    gcloudProject !== projectId &&
    process.env.FUNCTIONS_EMULATOR !== 'true'
  ) {
    // eslint-disable-next-line no-console
    console.warn(
      `[ADMIN PROJECT MISMATCH] APP_FIREBASE_PROJECT_ID="${projectId}" != GCLOUD_PROJECT="${gcloudProject}". ` +
        'Firebase ID tokens issued by the frontend project will be rejected by verifyIdToken. ' +
        'Fix APP_FIREBASE_PROJECT_ID in the deployed environment .env file.'
    );
  }

  if (process.env.FUNCTIONS_EMULATOR === 'true') {
    // eslint-disable-next-line no-console
    console.log('[FIRESTORE EMULATOR]', process.env.FIRESTORE_EMULATOR_HOST);
  }

  return _adminApp;
}

export function getDb(): Firestore {
  if (!_db) {
    _db = getFirestore(getAdminApp());
    _db.settings({ ignoreUndefinedProperties: true });

    // Log the Firestore project for diagnostics (safe – project ID is not secret)
    const firestoreProjectId =
      (_db as any).projectId || getAdminApp().options.projectId;
    console.log(`[FIRESTORE] Initialized for project=${firestoreProjectId}`);
  }
  return _db;
}

/**
 * Runs a one-time Firestore connectivity check on the first real database
 * access.  Logs the result safely (no document contents).  Subsequent
 * calls are no-ops.
 *
 * Returns true if Firestore is accessible, false otherwise.
 */
export async function checkFirestoreAccess(): Promise<boolean> {
  if (_firestoreChecked) return true;
  _firestoreChecked = true;

  const db = getDb();
  const projectId = getAdminApp().options.projectId;

  try {
    // Attempt a lightweight read against a non-existent document.
    // A successful 404 (doc doesn't exist) still proves we have read
    // permission.  A PERMISSION_DENIED proves we don't.
    const snap = await db.collection('healthcheck_probe').doc('probe').get();
    console.log(
      `[FIRESTORE ACCESS] OK – project=${projectId}, ` +
        `probe exists=${snap.exists}`
    );
    return true;
  } catch (e: any) {
    console.error(
      `[FIRESTORE ACCESS FAILED] project=${projectId}, ` +
        `code=${e.code || 'unknown'}, message=${e.message || 'N/A'}`
    );
    console.error(
      '[FIRESTORE ACCESS] If code=7 (PERMISSION_DENIED), verify:\n' +
        '  1. Firestore is enabled in the Firebase/GCP console for this project\n' +
        '  2. The runtime service account has "Cloud Datastore User" (roles/datastore.user) IAM role\n' +
        '  3. The Cloud Run service uses the intended service account\n' +
        '  4. The Firestore database (default) has been created'
    );
    return false;
  }
}

export function getAdminAuth(): Auth {
  if (!_auth) {
    _auth = getAuth(getAdminApp());
  }
  return _auth;
}

export function getAdminStorage(): Storage {
  if (!_storage) {
    _storage = getStorage(getAdminApp());
  }
  return _storage;
}

export function getAdminMessaging(): Messaging {
  if (!_messaging) {
    _messaging = getMessaging(getAdminApp());
  }
  return _messaging;
}

export function getBucket(): ReturnType<Storage['bucket']> {
  if (!_bucket) {
    _bucket = getAdminStorage().bucket();
  }
  return _bucket;
}
