const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function find() {
  const empid = 'MR013';
  const baseQuery = db.collection('employee_onboarding_dev').where('companyId', '==', 'servapp');

  const queries = [
    { field: 'empid', q: baseQuery.where('empid', '==', empid).limit(5) },
    { field: 'employeeId', q: baseQuery.where('employeeId', '==', empid).limit(5) },
    { field: 'uid', q: baseQuery.where('uid', '==', empid).limit(5) },
    { field: 'officialEmail', q: baseQuery.where('officialEmail', '==', empid).limit(5) },
    { field: 'companyDetails.employeeId', q: baseQuery.where('companyDetails.employeeId', '==', empid).limit(5) },
    { field: 'companyDetails.officialEmail', q: baseQuery.where('companyDetails.officialEmail', '==', empid).limit(5) },
  ];

  for (const item of queries) {
    try {
      const snap = await item.q.get();
      if (!snap.empty) {
        console.log('MATCH FIELD:', item.field);
        for (const doc of snap.docs) {
          console.log('DOC ID:', doc.id);
          console.log(JSON.stringify(doc.data(), null, 2));
        }
      } else {
        console.log('NO MATCH for', item.field);
      }
    } catch (err) {
      console.error('query error', item.field, err);
    }
  }
}

find().then(() => process.exit(0)).catch(err => { console.error(err); process.exit(1); });
