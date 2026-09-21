/**
 * Organization code migration script.
 *
 * Safely assigns organization codes to existing companyProfile documents that do
 * not already have one.
 *
 * Usage:
 *   DRY RUN (default):
 *     npx ts-node src/scripts/migrateOrganizationCodes.ts
 *
 *   EXECUTE:
 *     npx ts-node src/scripts/migrateOrganizationCodes.ts --execute
 */

import * as admin from 'firebase-admin';
import * as path from 'path';

const COMPANY_COLLECTION = 'companyProfile';
const CODE_PREFIX = 'SERV';
const CODE_PAD_LENGTH = 3;

const execute = process.argv.includes('--execute');
const dryRun = !execute;

const serviceAccountPath = path.join(__dirname, '..', '..', 'serviceAccountKey.json');

function formatCode(index: number): string {
  return `${CODE_PREFIX}${String(index).padStart(CODE_PAD_LENGTH, '0')}`;
}

async function main() {
  if (!admin.apps.length) {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id,
    });
  }

  const db = admin.firestore();
  const snapshot = await db.collection(COMPANY_COLLECTION).get();

  if (snapshot.empty) {
    console.log('No companyProfile documents found.');
    return;
  }

  const docs = snapshot.docs;
  console.log(`Found ${docs.length} companyProfile document(s).`);

  // Existing codes to avoid collisions.
  const existingCodes = new Set<string>();
  const docsNeedingCode: admin.firestore.QueryDocumentSnapshot[] = [];

  for (const doc of docs) {
    const data = doc.data();
    const existingCode = String(data.code || '').trim().toUpperCase();
    if (existingCode) {
      existingCodes.add(existingCode);
    } else {
      docsNeedingCode.push(doc);
    }
  }

  if (docsNeedingCode.length === 0) {
    console.log('All companyProfile documents already have an organization code. Nothing to migrate.');
    return;
  }

  // Build proposed assignments deterministically.
  let counter = 1;
  const assignments: { docId: string; proposedCode: string }[] = [];

  for (const doc of docsNeedingCode) {
    let proposed = formatCode(counter);
    while (existingCodes.has(proposed)) {
      counter++;
      proposed = formatCode(counter);
    }
    existingCodes.add(proposed);
    assignments.push({ docId: doc.id, proposedCode: proposed });
    counter++;
  }

  console.log(`\nProposed assignments (${dryRun ? 'DRY RUN' : 'EXECUTE'}):`);
  for (const a of assignments) {
    // Only log document ID and proposed code. No company names or emails.
    console.log(`  ${a.docId} -> ${a.proposedCode}`);
  }

  if (dryRun) {
    console.log('\nDry run complete. No changes written.');
    console.log('Run with --execute to apply these organization codes.');
    return;
  }

  // Apply in batches.
  let batch = db.batch();
  let count = 0;
  let updated = 0;

  for (const a of assignments) {
    const ref = db.collection(COMPANY_COLLECTION).doc(a.docId);
    const doc = docsNeedingCode.find((d) => d.id === a.docId);
    const currentCode = String(doc?.data().code || '').trim().toUpperCase();

    if (currentCode) {
      console.log(`  Skipping ${a.docId}: already has code ${currentCode}`);
      continue;
    }

    batch.update(ref, {
      code: a.proposedCode,
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

  console.log(`\nMigration complete. Updated ${updated} document(s).`);
}

main().catch((error) => {
  console.error('Migration failed:', error);
  process.exit(1);
});
