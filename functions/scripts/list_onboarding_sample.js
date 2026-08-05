const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function listSample() {
  const snap = await db.collection('employee_onboarding_dev').limit(20).get();
  console.log('docs:', snap.size);
  for (const doc of snap.docs) {
    const data = doc.data();
    console.log('DOC ID:', doc.id);
    console.log('has companyId:', data.hasOwnProperty('companyId'));
    console.log('empid:', data.empid ?? null);
    console.log('companyDetails.employeeId:', data.companyDetails?.employeeId ?? null);
    const bank = data.bankDetails ?? null;
    console.log('bank keys:', bank ? Object.keys(bank) : null);
    console.log('---');
  }
}

listSample().then(() => process.exit(0)).catch(err => { console.error(err); process.exit(1); });
