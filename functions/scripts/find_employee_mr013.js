const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function find() {
  const empid = 'MR013';
  const snap = await db.collection('employees').where('empid', '==', empid).limit(5).get();
  if (snap.empty) {
    console.log('No employee with empid MR013');
    return;
  }
  for (const doc of snap.docs) {
    console.log('EMP DOC ID:', doc.id);
    console.log(JSON.stringify(doc.data(), null, 2));
  }
}

find().then(() => process.exit(0)).catch(err => { console.error(err); process.exit(1); });
