const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function scan() {
  const snap = await db.collection('employee_onboarding_dev').limit(500).get();
  console.log('docs:', snap.size);
  let found = 0;
  for (const doc of snap.docs) {
    const json = JSON.stringify(doc.data());
    if (json.includes('MR013')) {
      found++;
      console.log('FOUND IN DOC', doc.id);
      console.log(JSON.stringify(doc.data(), null, 2));
    }
  }
  console.log('found total', found);
}

scan().then(() => process.exit(0)).catch(err => { console.error(err); process.exit(1); });
