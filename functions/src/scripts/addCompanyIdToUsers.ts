import * as admin from 'firebase-admin';
import * as path from 'path';

const DEFAULT_COMPANY_ID = 'COMP001';
const COLLECTION_NAME = 'users';

const serviceAccount = require(path.join(__dirname, '..', '..', 'serviceAccountKey.json'));

async function main(): Promise<void> {
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id,
    });
  }

  const db = admin.firestore();

  console.log(`Starting migration for collection: ${COLLECTION_NAME}`);

  const snapshot = await db.collection(COLLECTION_NAME).get();

  if (snapshot.empty) {
    console.log('No user documents found.');
    return;
  }

  let updatedCount = 0;
  let skippedCount = 0;

  let batch = db.batch();
  let opCount = 0;
  const batchSize = 400;

  for (const doc of snapshot.docs) {
    const data = doc.data();

    if (data.companyId) {
      skippedCount++;
      continue;
    }

    batch.update(doc.ref, {
      companyId: DEFAULT_COMPANY_ID,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    updatedCount++;
    opCount++;

    if (opCount === batchSize) {
      await batch.commit();
      console.log(`Committed ${opCount} updates...`);
      batch = db.batch();
      opCount = 0;
    }
  }

  if (opCount > 0) {
    await batch.commit();
    console.log(`Committed final ${opCount} updates...`);
  }

  console.log('Migration completed.');
  console.log(`Updated: ${updatedCount}`);
  console.log(`Skipped: ${skippedCount}`);
}

main().catch((error) => {
  console.error('Migration failed:', error);
  process.exit(1);
});