import { db } from '../src/config/firebase';
import { Firestore } from 'firebase-admin/firestore';

/**
 * Dry-run migration script to repair inconsistent payroll payment status.
 * 
 * This script detects records where:
 * - paidAt exists
 * - paidBy exists
 * but:
 * - paymentStatus != "paid" OR isPaid != true
 * 
 * Safety rule: Any record with paidAt AND paidBy present is treated as paid,
 * even if paymentStatus was accidentally reset to pending by old code.
 * 
 * Usage:
 *   npx ts-node scripts/repairPayrollPaymentStatus.ts --dry-run
 *   npx ts-node scripts/repairPayrollPaymentStatus.ts --apply
 */

interface RepairStats {
  totalDocuments: number;
  inconsistentPaidRecords: Array<{
    id: string;
    companyId: string;
    empid: string;
    year: number;
    month: number;
    currentPaymentStatus: string;
    currentIsPaid: boolean;
    hasPaidAt: boolean;
    hasPaidBy: boolean;
  }>;
  alreadyCorrectPaidRecords: number;
  pendingRecords: number;
  recordsMissingPaymentFields: number;
  cannotClassify: number;
}

async function scanPayrollCollection(db: Firestore): Promise<RepairStats> {
  const stats: RepairStats = {
    totalDocuments: 0,
    inconsistentPaidRecords: [],
    alreadyCorrectPaidRecords: 0,
    pendingRecords: 0,
    recordsMissingPaymentFields: 0,
    cannotClassify: 0,
  };

  const snapshot = await db.collection('payrolls').get();

  stats.totalDocuments = snapshot.docs.length;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const hasPaidAt = data.paidAt != null;
    const hasPaidBy = data.paidBy != null;
    const paymentStatus = data.paymentStatus || 'unknown';
    const isPaid = data.isPaid === true;

    // Check for inconsistent records
    if (hasPaidAt && hasPaidBy) {
      if (paymentStatus !== 'paid' || !isPaid) {
        stats.inconsistentPaidRecords.push({
          id: doc.id,
          companyId: data.companyId || 'unknown',
          empid: data.empid || 'unknown',
          year: data.year || 0,
          month: data.month || 0,
          currentPaymentStatus: paymentStatus,
          currentIsPaid: isPaid,
          hasPaidAt,
          hasPaidBy,
        });
      } else {
        stats.alreadyCorrectPaidRecords++;
      }
    } else if (paymentStatus === 'paid' || isPaid) {
      stats.alreadyCorrectPaidRecords++;
    } else if (paymentStatus === 'pending' || !isPaid) {
      stats.pendingRecords++;
    } else {
      stats.cannotClassify++;
    }

    // Check for records missing payment fields
    if (!hasPaidAt && !hasPaidBy && paymentStatus === 'unknown') {
      stats.recordsMissingPaymentFields++;
    }
  }

  return stats;
}

async function repairInconsistentRecords(
  db: Firestore,
  inconsistentRecords: RepairStats['inconsistentPaidRecords'],
  dryRun: boolean,
): Promise<void> {
  console.log(`\n${dryRun ? 'DRY-RUN: Would repair' : 'REPAIRING'} ${inconsistentRecords.length} inconsistent records...\n`);

  for (const record of inconsistentRecords) {
    if (dryRun) {
      console.log(`  [DRY-RUN] Would update ${record.id}:`);
      console.log(`    - companyId: ${record.companyId}`);
      console.log(`    - empid: ${record.empid}`);
      console.log(`    - year: ${record.year}, month: ${record.month}`);
      console.log(`    - Current: paymentStatus="${record.currentPaymentStatus}", isPaid=${record.currentIsPaid}`);
      console.log(`    - Would set: paymentStatus="paid", isPaid=true`);
      console.log(`    - Would preserve: paidAt, paidBy (unchanged)`);
    } else {
      try {
        await db.collection('payrolls').doc(record.id).update({
          paymentStatus: 'paid',
          isPaid: true,
        });
        console.log(`  [REPAIRED] ${record.id}`);
      } catch (error) {
        console.error(`  [ERROR] Failed to repair ${record.id}:`, error);
      }
    }
  }
}

async function main() {
  const args = process.argv.slice(2);
  const dryRun = !args.includes('--apply');
  const apply = args.includes('--apply');

  if (apply && dryRun) {
    console.error('Error: Cannot specify both --dry-run and --apply');
    process.exit(1);
  }

  console.log('='.repeat(80));
  console.log('Payroll Payment Status Repair Script');
  console.log('='.repeat(80));
  console.log(`Mode: ${dryRun ? 'DRY-RUN (no changes will be made)' : 'APPLY (will modify Firestore)'}`);
  console.log('='.repeat(80));

  try {
    console.log('\nScanning payrolls collection...\n');
    const stats = await scanPayrollCollection(db);

    console.log('='.repeat(80));
    console.log('SCAN RESULTS');
    console.log('='.repeat(80));
    console.log(`Total documents scanned: ${stats.totalDocuments}`);
    console.log(`Inconsistent paid records (paidAt+paidBy but not marked paid): ${stats.inconsistentPaidRecords.length}`);
    console.log(`Already correct paid records: ${stats.alreadyCorrectPaidRecords}`);
    console.log(`Pending records: ${stats.pendingRecords}`);
    console.log(`Records missing payment fields: ${stats.recordsMissingPaymentFields}`);
    console.log(`Cannot classify: ${stats.cannotClassify}`);
    console.log('='.repeat(80));

    if (stats.inconsistentPaidRecords.length > 0) {
      console.log('\nINCONSISTENT RECORDS:');
      console.log('='.repeat(80));
      stats.inconsistentPaidRecords.forEach((record, index) => {
        console.log(`\n${index + 1}. ${record.id}`);
        console.log(`   Company: ${record.companyId}, Employee: ${record.empid}`);
        console.log(`   Period: ${record.year}-${record.month}`);
        console.log(`   Current: paymentStatus="${record.currentPaymentStatus}", isPaid=${record.currentIsPaid}`);
        console.log(`   Has paidAt: ${record.hasPaidAt}, Has paidBy: ${record.hasPaidBy}`);
      });
      console.log('='.repeat(80));

      await repairInconsistentRecords(db, stats.inconsistentPaidRecords, dryRun);
    } else {
      console.log('\n✓ No inconsistent records found. No repairs needed.');
    }

    console.log('\n' + '='.repeat(80));
    console.log(dryRun ? 'DRY-RUN COMPLETE. No changes were made to Firestore.' : 'REPAIR COMPLETE.');
    console.log('='.repeat(80));

  } catch (error) {
    console.error('\nError during scan/repair:', error);
    process.exit(1);
  }
}

main();
