// functions/src/scripts/seedDevPlatformAdmin.ts

/**
 * Development-only seed for a Platform Admin (platform_admin) reviewer used
 * by the browser Platform Admin portal (Milestone 3D-B). Targets ONLY the
 * local Firebase emulators — it hard-refuses to run when the emulator hosts
 * are not configured, so it can never touch production.
 *
 * Run (emulators must be up):
 *   npx ts-node src/scripts/seedDevPlatformAdmin.ts
 *
 * The reviewer password comes from DEV_PLATFORM_ADMIN_PASSWORD; if unset, a
 * random one is generated and printed ONCE for the local developer.
 */

import { randomBytes } from 'crypto';

const PROJECT_ID = 'serv-dev-f2557';
const REVIEWER_EMAIL = 'dev.platform.admin@serv-test.local';
const REVIEWER_NAME = 'DEV Platform Admin';
// firebaseLogin requires a non-empty companyId on the users doc; the
// reviewer is platform-scoped, so a sentinel company id is used. No
// companyProfile/companies doc is created for it — provisioning untouched.
const PLATFORM_COMPANY_ID = 'platform';

async function main() {
  // Refuse anything but the local emulators. These must be set before any
  // firebase-admin import.
  process.env.APP_FIREBASE_PROJECT_ID = PROJECT_ID;
  process.env.FUNCTIONS_EMULATOR = 'true';
  process.env.FIRESTORE_EMULATOR_HOST =
    process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
  process.env.FIREBASE_AUTH_EMULATOR_HOST =
    process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';

  if (
    !process.env.FIRESTORE_EMULATOR_HOST.includes('127.0.0.1') &&
    !process.env.FIRESTORE_EMULATOR_HOST.includes('localhost')
  ) {
    throw new Error('Refusing to seed: Firestore emulator host is not local.');
  }
  if (
    !process.env.FIREBASE_AUTH_EMULATOR_HOST.includes('127.0.0.1') &&
    !process.env.FIREBASE_AUTH_EMULATOR_HOST.includes('localhost')
  ) {
    throw new Error('Refusing to seed: Auth emulator host is not local.');
  }

  const generatedPassword = !process.env.DEV_PLATFORM_ADMIN_PASSWORD;
  const password =
    process.env.DEV_PLATFORM_ADMIN_PASSWORD ||
    `Dev-${randomBytes(9).toString('base64url')}!`;

  const { getDb, getAdminAuth } = await import('../config/firebase');
  const db = getDb();
  const auth = getAdminAuth();

  const emailLower = REVIEWER_EMAIL.toLowerCase();

  // Auth emulator account (idempotent).
  let uid: string;
  try {
    const created = await auth.createUser({
      email: REVIEWER_EMAIL,
      password,
      displayName: REVIEWER_NAME,
    });
    uid = created.uid;
    console.log('[SEED] Auth account created:', REVIEWER_EMAIL);
  } catch (err: any) {
    if (err.code === 'auth/email-already-exists') {
      const existing = await auth.getUserByEmail(REVIEWER_EMAIL);
      uid = existing.uid;
      console.log('[SEED] Auth account already exists:', REVIEWER_EMAIL);
    } else {
      throw err;
    }
  }

  // users doc — stable id so re-runs are idempotent. The role is the
  // browser-portal-only platform_admin role (not mobile super_admin).
  await db.collection('users').doc(uid).set(
    {
      email: REVIEWER_EMAIL,
      emailLower,
      name: REVIEWER_NAME,
      fullName: REVIEWER_NAME,
      role: 'platform_admin',
      status: 'active',
      companyId: PLATFORM_COMPANY_ID,
      authSource: 'firebase',
      createdAt: new Date(),
      updatedAt: new Date(),
    },
    { merge: true },
  );
  console.log('[SEED] users doc written: role=platform_admin, uid=' + uid);

  if (generatedPassword) {
    // Printed once for the local developer — never persisted to disk.
    console.log('');
    console.log('  DEV platform admin email:    ' + REVIEWER_EMAIL);
    console.log('  DEV platform admin password: ' + password);
    console.log('');
    console.log(
      '  (Set DEV_PLATFORM_ADMIN_PASSWORD to choose your own; ' +
        'these credentials exist only in the local emulator.)',
    );
  } else {
    console.log(
      '[SEED] Reviewer credentials set from DEV_PLATFORM_ADMIN_PASSWORD',
    );
  }
}

main().catch((err) => {
  console.error('[SEED] Failed:', err);
  process.exit(1);
});
