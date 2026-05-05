import * as admin from 'firebase-admin';
import * as path from 'path';

const DEFAULT_COMPANY_ID = 'COMP001';

const collections = [
  'attendance',
  'tasks',
  'leaves',
  'events',
  'feedbacks',
  'rewards',
  'tracking',
  'officeLocations',
  'shifts',
  'companyProfile'
];

const serviceAccount = require(path.join(
  __dirname,
  '..',
  '..',
  'serviceAccountKey.json'
));

async function migrateCollection(collectionName: string) {
  const db = admin.firestore();

  console.log(`\nMigrating collection: ${collectionName}`);

  const snapshot = await db.collection(collectionName).get();

  if (snapshot.empty) {
    console.log(`No documents found in ${collectionName}`);
    return;
  }

  let batch = db.batch();
  let updated = 0;
  let skipped = 0;
  let count = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();

    if (data.companyId) {
      skipped++;
      continue;
    }

    batch.update(doc.ref, {
      companyId: DEFAULT_COMPANY_ID,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    updated++;
    count++;

    if (count === 400) {
      await batch.commit();
      batch = db.batch();
      count = 0;
    }
  }

  if (count > 0) {
    await batch.commit();
  }

  console.log(`Updated: ${updated}`);
  console.log(`Skipped: ${skipped}`);
}

async function main() {
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id,
    });
  }

  console.log('Starting combined migration...');

  for (const col of collections) {
    await migrateCollection(col);
  }

  console.log('\nMigration completed successfully.');
}

main().catch((error) => {
  console.error('Migration failed:', error);
  process.exit(1);
});