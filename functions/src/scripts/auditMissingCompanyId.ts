import * as admin from 'firebase-admin';
import * as path from 'path';

/**
 * READ-ONLY audit: counts documents missing a usable `companyId` in every
 * tenant-scoped collection the current backend relies on.
 *
 * Why this exists: the new code hard-requires companyId -
 *   - liveEmployeeDetailsController hides attendance/employee docs without it
 *   - attendanceTracking trigger skips attendance docs without it
 *   - tracking legacy docs without it are only read when the empid exists in
 *     exactly one company (ambiguous ones stay hidden)
 * Run this against production BEFORE deploying to size the backfill.
 *
 * It performs only collection .get() calls - no writes, no deletes, no
 * updates. It does not print document contents; only counts and doc ids of
 * affected docs (ids are needed to plan a targeted backfill).
 *
 * Usage (requires a service account key for the target project):
 *   cd functions
 *   npx ts-node src/scripts/auditMissingCompanyId.ts
 * Place serviceAccountKey.json in functions/ first, or set
 * GOOGLE_APPLICATION_CREDENTIALS to a key file.
 */

// Collections the backend filters by companyId (or relies on it being set).
const COLLECTIONS = [
  'attendance',
  'tracking',
  'employees',
  'users',
  'leaves',
  'leave_types',
  'tasks',
  'task_assignments',
  'notifications',
  'other_location_events',
];

function loadCredentials(): { credential: admin.credential.Credential; projectId?: string } {
  const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (keyPath) {
    return { credential: admin.credential.applicationDefault() };
  }
  const serviceAccount = require(path.join(__dirname, '..', '..', 'serviceAccountKey.json'));
  return {
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id,
  };
}

async function main(): Promise<void> {
  const { credential, projectId } = loadCredentials();
  if (!admin.apps.length) {
    admin.initializeApp({ credential, projectId });
  }
  const db = admin.firestore();
  db.settings({ ignoreUndefinedProperties: true });

  console.log('=== companyId audit (read-only) ===');
  console.log(`project: ${admin.apps[0]?.options.projectId ?? '(from ADC)'}`);

  let grandTotal = 0;
  let grandMissing = 0;

  for (const col of COLLECTIONS) {
    try {
      const snap = await db.collection(col).get();
      const missing: string[] = [];
      const legacyTrackingIds: string[] = [];
      const perCompany = new Map<string, number>();

      for (const doc of snap.docs) {
        const data = doc.data() as any;
        const cid = String(data?.companyId ?? '').trim();
        if (cid) {
          perCompany.set(cid, (perCompany.get(cid) ?? 0) + 1);
        } else {
          missing.push(doc.id);
        }
        // Legacy tracking docs used the `${empid}_${date}` id format (2
        // segments) vs the new `${companyId}_${empid}_${date}` (3 segments).
        if (col === 'tracking' && doc.id.split('_').length === 2) {
          legacyTrackingIds.push(doc.id);
        }
      }

      grandTotal += snap.size;
      grandMissing += missing.length;

      console.log(`\n[${col}] total=${snap.size} missingCompanyId=${missing.length}`);
      if (perCompany.size) {
        console.log('  companyId distribution:', Object.fromEntries(perCompany));
      }
      if (col === 'tracking' && legacyTrackingIds.length) {
        console.log(`  legacy-format ids (empid_date): ${legacyTrackingIds.length}`);
      }
      if (missing.length) {
        console.log(`  missing doc ids: ${missing.slice(0, 50).join(', ')}${missing.length > 50 ? ` ... (+${missing.length - 50} more)` : ''}`);
      }
    } catch (e: any) {
      console.log(`\n[${col}] ERROR (collection may not exist): ${e?.message || e}`);
    }
  }

  console.log(`\n=== SUMMARY: ${grandMissing}/${grandTotal} docs missing companyId ===`);
  console.log('No documents were modified.');
}

main().catch((e) => {
  console.error('audit failed:', e);
  process.exit(1);
});
