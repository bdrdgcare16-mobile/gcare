const fs = require('fs');
const path = require('path');
const firebase = require('./lib/config/firebase');
const db = firebase.db;

async function run() {
  const q = await db.collection('employee_onboarding_dev').limit(500).get();
  const matches = [];
  for (const doc of q.docs) {
    const data = doc.data();
    try {
      const s = JSON.stringify(data);
      if (s.includes('MR014') || s.includes('mr014')) {
        matches.push({ id: doc.id, data });
      }
    } catch (e) {
      // ignore
    }
  }

  const outPath = path.join(__dirname, 'latest_onboarding_search_mr014.json');
  fs.writeFileSync(outPath, JSON.stringify({ count: matches.length, matches }, null, 2));
  console.log('Wrote onboarding search to', outPath);
}

run().catch(e => { console.error(e); process.exit(1); });
